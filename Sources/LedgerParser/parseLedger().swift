import Foundation
import Glob

public enum Token {
    case Transaction(LedgerParser.Transaction)
    case Include(String)
    case Note(String)
}

let dateSet = CharacterSet(charactersIn: "0123456789-/")
let flagSet = CharacterSet(charactersIn: "*")
let noteSet = CharacterSet(charactersIn: ";")
let payee = CharacterSet.alphanumerics

enum ScanError: ErrorProtocol {
    case NoMatch
}
enum ParseError: ErrorProtocol {
    case InvalidSyntax
    case UnsupportedToken
}

public struct Transaction {
    public let date: String
    public let flag: String?
    public let payee: String
    public let notes: [String]
    public let postings: [Posting]
}

public struct Posting {
    public var account: String
    public var unparsed: String?
    public var notes: [String]
}

func scanTransaction(_ scanner: Scanner) throws -> Token {
    scanner.charactersToBeSkipped = .whitespacesAndNewlines
    guard let date = scanner.scanCharacters(from: dateSet) else { throw ScanError.NoMatch }
    guard let flag = scanner.scanCharacters(from: flagSet) else { throw ParseError.InvalidSyntax }
    guard let payee = scanner.scanUpToCharacters(from: .newlines) else { throw ParseError.InvalidSyntax }

    // scan position is at the newline of the header
    scanner.charactersToBeSkipped = .newlines
    var notes = [String]()
    while true {
        scanner.scanCharacters(from: .whitespaces, into: nil)
        if !scanner.scanCharacters(from: noteSet, into: nil) { break }
        notes.append(scanner.scanUpToCharacters(from: .newlines) ?? "")
    }

    // scan position is past the indent of the first posting
    var postings = [Posting]()
    postings: while true {
        scanner.charactersToBeSkipped = nil
        var account = ""
        while let s = scanner.scanUpToCharacters(from: .whitespacesAndNewlines) {
            account += s
            guard let ws = scanner.scanCharacters(from: .whitespaces) else { break }
            if ws.characters.count >= 2 { break }
            account += ws
        }
        let unparsed = scanner.scanUpToCharacters(from: .newlines)

        scanner.charactersToBeSkipped = .newlines
        var notes = [String]()
        notes: while true {
            if !scanner.scanCharacters(from: .whitespaces, into: nil) {
                postings.append(Posting(account: account, unparsed: unparsed, notes: notes))
                break postings
            }
            if !scanner.scanCharacters(from: noteSet, into: nil) {
                break notes
            }
            notes.append(scanner.scanUpToCharacters(from: .newlines) ?? "")
        }

        postings.append(Posting(account: account, unparsed: unparsed, notes: notes))
    }
    return .Transaction(Transaction(date: date, flag: flag, payee: payee, notes: notes, postings: postings))
}

func scanNote(_ scanner: Scanner) throws -> Token {
    scanner.charactersToBeSkipped = .whitespacesAndNewlines
    guard scanner.scanCharacters(from: noteSet, into: nil) else { throw ScanError.NoMatch }
    guard let note = scanner.scanUpToCharacters(from: .newlines) else { throw ParseError.InvalidSyntax }
    return .Note(note)
}

func scanInclude(_ scanner: Scanner) throws -> Token {
    scanner.charactersToBeSkipped = .whitespacesAndNewlines
    guard scanner.scanString("include", into: nil) else { throw ScanError.NoMatch }
    guard let filename = scanner.scanUpToCharacters(from: .newlines) else { throw ParseError.InvalidSyntax }
    return .Include(filename)
}

func scanToken(_ scanner: Scanner) throws -> Token? {
    guard !scanner.isAtEnd else { return nil }

    do { return try scanTransaction(scanner) }
    catch ScanError.NoMatch { }

    do { return try scanNote(scanner) }
    catch ScanError.NoMatch { }

    do { return try scanInclude(scanner) }
    catch ScanError.NoMatch { }

    throw ParseError.UnsupportedToken
}

public func parseLedger(filename: String) throws -> [Token] {
    let input = try String(contentsOfFile: filename)
    var result = [Token]()
    let scanner = Scanner(string: input)
    while let token = try scanToken(scanner) {
        switch token {
        case .Include(let pattern):
            var pattern = pattern
            if pattern.characters.first != "/" {
                pattern = try! NSURL(fileURLWithPath: filename).deletingLastPathComponent!.appendingPathComponent(pattern).path!
            }
            for filename in Glob(pattern: pattern) {
                for token2 in try parseLedger(filename: filename) {
                    result.append(token2)
                }
            }
        default: result.append(token)
        }
    }
    return result
}
