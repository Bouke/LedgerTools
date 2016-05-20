import func LedgerParser.parse
import enum LedgerParser.Token
import struct LedgerParser.Transaction
import Foundation
import func FootlessParser.parse
import func Categorizer.freq
import func Categorizer.train
import typealias Categorizer.History

guard Process.arguments.count >= 2 else { print("Specify transaction file as first argument"); exit(1) }

let transactionsFile = Process.arguments[1]
guard let account = flag("-s") else { print("Specify the config section [name] with -s flag"); exit(1) }
let config = try parseINI(filename: ".ledger-tools")
guard let trainFile = config[account]?["train"] else { print("Specify the train file in the config"); exit(1) }
guard let csvDateFormat = config[account]?["csv-date-format"] else { print("Specify the csv date format in the config"); exit(1) }
guard let ledgerDateFormat = config[account]?["ledger-date-format"] else { print("Specify the ledger date format in the config"); exit(1) }
guard let dateCol = config[account]?["date"].flatMap({ Int($0) }) else { print("Specify the date column in the config"); exit(1) }
guard let payeeCol = config[account]?["payee"].flatMap({ Int($0) }) else { print("Specify the payee column in the config"); exit(1) }
guard let amountCol = config[account]?["amount"].flatMap({ Int($0) }) else { print("Specify the amount column in the config"); exit(1) }
guard let descriptionCol = config[account]?["description"].flatMap({ Int($0) }) else { print("Specify the description column in the config"); exit(1) }

let tokens = try parse(filename: (trainFile as NSString).expandingTildeInPath)
let transactions = tokens.flatMap { (token: Token) -> Transaction? in
    switch token {
    case .Transaction(let t): return t
    default: return nil
    }
}

let defaultSeparators = { () -> NSCharacterSet in
    let sep = NSMutableCharacterSet(charactersIn: ",;/")
    sep.formUnion(with: NSCharacterSet.whitespaces())
    return sep
}()

let originatingAccount = { (t: [Transaction]) -> String in
    let f = freq(t.map { $0.postings.map { $0.account } }.flatten())
    return f.sorted { $0.value >= $1.value }.first?.key ?? "Assets:Banking"
}(transactions)

let history = { (transactions: [Transaction]) -> History in
    var r = History()
    for transaction in transactions {
        let tokens = transaction.notes.flatMap { $0.uppercased().components(separatedBy: defaultSeparators) }.filter { $0 != "" }
        for posting in transaction.postings {
            guard posting.account != originatingAccount else { continue }
            r.append(posting.account, tokens)
        }
    }
    return r
}(transactions)

let csvDateFormatter = NSDateFormatter()
csvDateFormatter.dateFormat = csvDateFormat

let ledgerDateFormatter = NSDateFormatter()
ledgerDateFormatter.dateFormat = ledgerDateFormat

let categorizer = train(history)

let rows = try parseCSV(filename: transactionsFile)
for row in rows[1..<rows.endIndex] {
    let tokens = row.joined(separator: " ").uppercased().components(separatedBy: defaultSeparators).filter { $0 != "" }
    let account = categorizer(tokens).first?.0 ?? "Expenses:Unknown"
    print()

    guard let date = csvDateFormatter.date(from: row[dateCol]) else { print("Could not parse date"); exit(1) }
    let dates = ledgerDateFormatter.string(from: date)
    print("\(dates) * \(row[payeeCol])")
    print("    ; \""+row.joined(separator: "\",\"")+"\"")
    print("    \(account)")
    print("    \(originatingAccount)    € \(row[amountCol])")
}
