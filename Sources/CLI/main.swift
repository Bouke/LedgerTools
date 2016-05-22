import func LedgerParser.parse
import enum LedgerParser.Token
import struct LedgerParser.Transaction
import Foundation
import func FootlessParser.parse
import func Categorizer.freq
import func Categorizer.train
import typealias Categorizer.History
import func CSV.parseCSV

let settings = parseSettings()

let tokens = try parse(filename: (settings.trainFile as NSString).expandingTildeInPath)
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

let history = { (transactions: [Transaction]) -> History in
    var r = History()
    for transaction in transactions {
        let tokens = transaction.notes.flatMap { $0.uppercased().components(separatedBy: ledgerTokenSeparators) }.filter { $0 != "" }
        for posting in transaction.postings {
            guard posting.account != originatingAccount else { continue }
            r.append(posting.account, tokens)
        }
    }
    return r
}(transactions)

let categorizer = train(history)

let csvDateFormatter = NSDateFormatter()
csvDateFormatter.dateFormat = settings.csvDateFormat

let ledgerDateFormatter = NSDateFormatter()
ledgerDateFormatter.dateFormat = settings.ledgerDateFormat

let minimalColumnCount = [settings.csvDateColumn, settings.csvPayeeColumn,
    settings.csvAmountColumn, settings.csvDescriptionColumn].max()!

let csvTokenSeparators = NSCharacterSet(charactersIn: settings.csvTokenSeparators)

let rows = try parseCSV(filename: settings.transactionsFile)

// TODO: configure num rows to skip
// TODO: sort transactions
for row in rows[1..<rows.endIndex] {
    guard row.count >= minimalColumnCount else {
        print("Found a row with \(row.count) columns, at least \(minimalColumnCount) expected")
        exit(1)
    }

    let tokens = row.joined(separator: " ").uppercased().components(separatedBy: csvTokenSeparators).filter { $0 != "" }

    // TODO: configure default account
    let account = categorizer(tokens).first?.0 ?? "Expenses:Unknown"

    let payee = row[settings.csvPayeeColumn]

    guard let date = csvDateFormatter.date(from: row[settings.csvDateColumn]) else {
        print("Could not parse date \(row[settings.csvDateColumn])")
        exit(1)
    }

    print()
    print("\(ledgerDateFormatter.string(from: date)) * \(payee)")
    // TODO: write CSV as-is (or escape correctly)
    print("    ; CSV: \""+row.joined(separator: "\",\"")+"\"")
    print("    \(account)")
    // TODO: amount formatting
    print("    \(originatingAccount)    € \(row[settings.csvAmountColumn])")
}
