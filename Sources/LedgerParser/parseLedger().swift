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

enum ScanError: Error {
    case NoMatch
}
enum ParseError: Error {
    case InvalidSyntax(Scanner.Position)
    case UnsupportedToken(Scanner.Position)
}

enum LedgerError: Error {
    case ParseError(filename: String, error: ParseError)
    case ReferencedFileError(self: String, other: ParseError)
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
    guard let flag = scanner.scanCharacters(from: flagSet) else {
        throw ParseError.InvalidSyntax(scanner.position)
    }
    guard let payee = scanner.scanUpToCharacters(from: .newlines) else {
        throw ParseError.InvalidSyntax(scanner.position)
    }

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
    guard scanner.scanCharacters(from: noteSet, into: nil) else {
        throw ScanError.NoMatch
    }
    guard let note = scanner.scanUpToCharacters(from: .newlines) else {
        throw ParseError.InvalidSyntax(scanner.position)
    }
    return .Note(note)
}

func scanInclude(_ scanner: Scanner) throws -> Token {
    scanner.charactersToBeSkipped = .whitespacesAndNewlines
    guard scanner.scanString("include", into: nil) else {
        throw ScanError.NoMatch
    }
    guard let filename = scanner.scanUpToCharacters(from: .newlines) else {
        throw ParseError.InvalidSyntax(scanner.position)
    }
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

    throw ParseError.UnsupportedToken(scanner.position)
}

public func parseLedger(filename: String) throws -> [Token] {
    let input = try String(contentsOfFile: filename)
    var result = [Token]()
    let scanner = Scanner(string: input)
    do {
        while let token = try scanToken(scanner) {
            switch token {
            case .Include(let pattern):
                var pattern = pattern
                if pattern.characters.first != "/" {
                    pattern = NSURL(fileURLWithPath: filename).deletingLastPathComponent!.appendingPathComponent(pattern).path
                }
                for other in Glob(pattern: pattern) {
                    do {
                        for token2 in try parseLedger(filename: other) {
                            result.append(token2)
                        }
                    } catch let error as ParseError {
                        throw LedgerError.ReferencedFileError(self: filename, other: error)
                    }
                }
            default: result.append(token)
            }
        }
        return result
    } catch let error as ParseError {
        throw LedgerError.ParseError(filename: filename, error: error)
    }
}
