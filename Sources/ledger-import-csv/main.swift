import func LedgerParser.parseLedger
import enum LedgerParser.Token
import struct LedgerParser.Transaction
import Foundation
import func Categorizer.freq
import func Categorizer.train
import typealias Categorizer.History
import func CSV.parse

let settings = parseSettings()

let tokens: [Token]
do {
    tokens = try parseLedger(filename: (settings.trainFile as NSString).expandingTildeInPath)
} catch {
    print("Could not parse ledger file: \(error)")
    exit(1)
}
let transactions = tokens.flatMap { (token: Token) -> Transaction? in
    switch token {
    case .Transaction(let t): return t
    default: return nil
    }
}

let ledgerTokenSeparators = CharacterSet(charactersIn: settings.ledgerTokenSeparators)

let originatingAccount = { (t: [Transaction]) -> String in
    let f = freq(t.map { $0.postings.map { $0.account } }.joined())
    return f.sorted { $0.value >= $1.value }.first?.key ?? "Assets:Banking"
}(transactions)


let descriptionRegex = try! NSRegularExpression(pattern: "Omschrijving: (.+?) IBAN", options: [])
func extractTokens(row: [String]) -> [String] {
    var tokens = row[1].components(separatedBy: " ")
    if let match = descriptionRegex.matches(in: row[8]).first {
        tokens += match.groups.first!.components(separatedBy: " ")
    }
    return tokens
}

//MARK: Read input, from either stdin (pipe) or file argument.
let inputCSV: Data

if !FileHandle.standardInput.isatty {
    inputCSV = FileHandle.standardInput.readDataToEndOfFile()
} else {
    // Expect the transaction file as unparsed argument (not matched by flag);
    // only one transaction file is expected.
    guard cli.unparsedArguments.count == 1 else {
        print("Specify exactly one transaction file argument");
        exit(EX_USAGE)
    }
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: cli.unparsedArguments[0])) else {
        print("Could not read transactions file")
        exit(1)
    }
    inputCSV = data
}

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
    csvNumberFormatter.locale = Locale(identifier: locale)
}

let ledgerNumberFormatter = NumberFormatter()
ledgerNumberFormatter.numberStyle = .currency
if let locale = settings.ledgerLocale {
    ledgerNumberFormatter.locale = Locale(identifier: locale)
}

//MARK: Read history

let (accountHistory, payeeHistory) = { (transactions: [Transaction]) -> (History, History) in
    var a = History()
    var p = History()
    for transaction in transactions {
        guard let note = transaction.notes.first(where: { $0.hasPrefix(" CSV: ") }) else { continue }
        let csv = note.substring(from: note.index(note.startIndex, offsetBy: 6))
        guard let row = (try? CSV.parse(csv.data(using: .utf8)!))?.first else { continue }
        guard row.count >= minimalColumnCount else {
            print(transaction)
            print("Found a transaction with \(row.count) columns, at least \(minimalColumnCount) expected")
            continue
        }
        let tokens = extractTokens(row: row)
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


//MARK: Read input CSV

let rows = try { () throws -> [[String]] in
    var rows = try CSV.parse(inputCSV)
    rows = Array(rows[settings.csvSkipRows..<rows.endIndex])
    if settings.csvReverseRows {
        rows = rows.reversed()
    }
    return rows
}()

for row in rows {
    guard row.count >= minimalColumnCount else {
        print("Found a row with \(row.count) columns, at least \(minimalColumnCount) expected")
        exit(1)
    }
    let tokens = extractTokens(row: row)
    let account = accountCategorizer(tokens).first?.0 ?? settings.defaultAccount
    let payee = payeeCategorizer(tokens).filter({ $0.1 >= 0.2 }).first?.0 ?? row[settings.csvPayeeColumn]

    guard var amount = csvNumberFormatter.number(from: row[settings.csvAmountColumn]).flatMap({ $0.decimalValue }) else {
        print("Could not parse amount \(row[settings.csvAmountColumn])")
        exit(1)
    }
    if let csvAmountDebit = settings.csvAmountDebit, row[csvAmountDebit.column] == csvAmountDebit.text {
        amount = amount * -1
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
