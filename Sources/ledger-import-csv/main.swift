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

let ledgerTokenSeparators = CharacterSet(charactersIn: settings.ledgerTokenSeparators)

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


// Read input, from either stdin (pipe) or file argument.
let inputCSV: NSData

if !FileHandle.withStandardInput.isatty {
    inputCSV = FileHandle.withStandardInput.readDataToEndOfFile()
} else {
    // Expect the transaction file as unparsed argument (not matched by flag);
    // only one transaction file is expected.
    guard cli.unparsedArguments.count == 1 else {
        print("Specify exactly one transaction file argument");
        exit(EX_USAGE)
    }
    guard let data = NSData(contentsOfFile: cli.unparsedArguments[0]) else {
        print("Could not read transactions file")
        exit(1)
    }
    inputCSV = data
}

let rows = try { () throws -> [[String]] in
    var rows = try CSV.parse(inputCSV)
    rows = Array(rows[settings.csvSkipRows..<rows.endIndex])
    if settings.csvReverseRows {
        rows = rows.reversed()
    }
    return rows
}()

let csvDateFormatter = DateFormatter()
csvDateFormatter.dateFormat = settings.csvDateFormat

let ledgerDateFormatter = DateFormatter()
ledgerDateFormatter.dateFormat = settings.ledgerDateFormat

let minimalColumnCount = [settings.csvDateColumn, settings.csvPayeeColumn,
    settings.csvAmountColumn, settings.csvDescriptionColumn].max()!

let csvTokenSeparators = CharacterSet(charactersIn: settings.csvTokenSeparators)

let csvNumberFormatter = NumberFormatter()
csvNumberFormatter.numberStyle = .decimal
csvNumberFormatter.isLenient = true
if let locale = settings.csvLocale {
    csvNumberFormatter.locale = Locale(localeIdentifier: locale)
}

let ledgerNumberFormatter = NumberFormatter()
ledgerNumberFormatter.numberStyle = .currency
if let locale = settings.ledgerLocale {
    ledgerNumberFormatter.locale = Locale(localeIdentifier: locale)
}

for row in rows {
    guard row.count >= minimalColumnCount else {
        print("Found a row with \(row.count) columns, at least \(minimalColumnCount) expected")
        exit(1)
    }

    let tokens = row.joined(separator: " ").uppercased().components(separatedBy: csvTokenSeparators).filter { $0 != "" }
    let account = accountCategorizer(tokens).first?.0 ?? settings.defaultAccount
    let payee = payeeCategorizer(tokens).filter({ $0.1 >= 0.2 }).first?.0 ?? row[settings.csvPayeeColumn]

    guard var amount = csvNumberFormatter.number(from: row[settings.csvAmountColumn]).flatMap({ NSDecimalNumber(decimal: $0.decimalValue) }) else {
        print("Could not parse amount \(row[settings.csvAmountColumn])")
        exit(1)
    }
    if let csvAmountDebit = settings.csvAmountDebit, row[csvAmountDebit.column] == csvAmountDebit.text {
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
