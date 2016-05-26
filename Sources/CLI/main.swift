import func LedgerParser.parseLedger
import enum LedgerParser.Token
import struct LedgerParser.Transaction
import Foundation
import func Categorizer.freq
import func Categorizer.train
import typealias Categorizer.History
import func CSV.parse

let settings = parseSettings()

let tokens = try parseLedger(filename: (settings.trainFile as NSString).expandingTildeInPath)
let transactions = tokens.flatMap { (token: Token) -> Transaction? in
    switch token {
    case .Transaction(let t): return t
    default: return nil
    }
}

let ledgerTokenSeparators = NSCharacterSet(charactersIn: settings.ledgerTokenSeparators)

let originatingAccount = { (t: [Transaction]) -> String in
    let f = freq(t.map { $0.postings.map { $0.account } }.flatten())
    return f.sorted { $0.value >= $1.value }.first?.key ?? "Assets:Banking"
}(transactions)

let (accountHistory, payeeHistory) = { (transactions: [Transaction]) -> (History, History) in
    var a = History()
    var p = History()
    for transaction in transactions {
        let tokens = transaction.notes.flatMap { $0.uppercased().components(separatedBy: ledgerTokenSeparators) }.filter { $0 != "" }
        p.append(transaction.payee, tokens)
        for posting in transaction.postings {
            guard posting.account != originatingAccount else { continue }
            a.append(posting.account, tokens)
        }
    }
    return (a, p)
}(transactions)

let accountCategorizer = train(accountHistory)
let payeeCategorizer = train(payeeHistory)

let rows = try { (filename: String) throws -> [[String]] in
    guard let data = NSData(contentsOfFile: filename) else {
        print("Could not read transactions file")
        exit(1)
    }
    var rows = try CSV.parse(data)
    rows = Array(rows[settings.csvSkipRows..<rows.endIndex])
    if settings.csvReverseRows {
        rows = rows.reversed()
    }
    return rows
}(settings.transactionsFile)

let csvDateFormatter = NSDateFormatter()
csvDateFormatter.dateFormat = settings.csvDateFormat

let ledgerDateFormatter = NSDateFormatter()
ledgerDateFormatter.dateFormat = settings.ledgerDateFormat

let minimalColumnCount = [settings.csvDateColumn, settings.csvPayeeColumn,
    settings.csvAmountColumn, settings.csvDescriptionColumn].max()!

let csvTokenSeparators = NSCharacterSet(charactersIn: settings.csvTokenSeparators)

let csvNumberFormatter = NSNumberFormatter()
csvNumberFormatter.numberStyle = .decimalStyle
csvNumberFormatter.isLenient = true
if let locale = settings.csvLocale {
    csvNumberFormatter.locale = NSLocale(localeIdentifier: locale)
}

let ledgerNumberFormatter = NSNumberFormatter()
ledgerNumberFormatter.numberStyle = .currencyStyle
if let locale = settings.ledgerLocale {
    ledgerNumberFormatter.locale = NSLocale(localeIdentifier: locale)
}

for row in rows {
    guard row.count >= minimalColumnCount else {
        print("Found a row with \(row.count) columns, at least \(minimalColumnCount) expected")
        exit(1)
    }

    let tokens = row.joined(separator: " ").uppercased().components(separatedBy: csvTokenSeparators).filter { $0 != "" }
    let account = accountCategorizer(tokens).first?.0 ?? settings.defaultAccount

    let payee = payeeCategorizer(tokens).first?.0 ?? row[settings.csvPayeeColumn]

    guard var amount = csvNumberFormatter.number(from: row[settings.csvAmountColumn]).flatMap({ NSDecimalNumber(decimal: $0.decimalValue) }) else {
        print("Could not parse amount \(row[settings.csvAmountColumn])")
        exit(1)
    }
    if let csvAmountDebit = settings.csvAmountDebit where row[csvAmountDebit.column] == csvAmountDebit.text {
        amount *= -1
    }

    guard let date = csvDateFormatter.date(from: row[settings.csvDateColumn]) else {
        print("Could not parse date \(row[settings.csvDateColumn])")
        exit(1)
    }

    print()
    print("\(ledgerDateFormatter.string(from: date)) * \(payee)")
    // TODO: write CSV as-is (or escape correctly)
    print("    ; CSV: \""+row.joined(separator: "\",\"")+"\"")
    print("    \(account)")
    print("    \(originatingAccount.pad(65)) \(ledgerNumberFormatter.string(for: amount)!)")
}
