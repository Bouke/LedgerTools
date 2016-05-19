import Foundation
import FootlessParser

public enum Token {
    case Transaction(LedgerParser.Transaction)
    case Include(String)
    case Note(String)
}

public func == (lhs: Token, rhs: Token) -> Bool {
    switch (lhs, rhs) {
    case let(.Transaction(lhs), .Transaction(rhs)): return lhs == rhs
    case let(.Include(lhs), .Include(rhs)): return lhs == rhs
    default: return false
    }
}
extension Token: Equatable { }

// hard separator; either a tab or a space followed by one or more spaces or tabs.
let hs = char("\t") <|> (whitespace <* oneOrMore(whitespace))
let indent = oneOrMore(whitespace)
let eol = oneOrMore(zeroOrMore(whitespace) <* newline)

public let date: Parser<Character, Date> = tuple <^> count(4, digit) <* char("-") <*> count(2, digit) <* char("-") <*> count(2, digit)

public let settled = {$0 == "*"} <^> optional(char("*") <* char(" "), otherwise: Character(" "))

let account = zeroOrMore(noneOf([";", "  ", "\n"]))

public let note = char(";") *> zeroOrMore(whitespace) *> (zeroOrMore(not("\n")))

public let posting = indent *> (
    curry({ (account, amount, balance, note, notes) in
        Transaction.Posting(account: account, amount: amount, balance: balance, notes: (note.map { [$0] } ?? []) + notes)
    }) <^>
    account <*>
    optional(oneOrMore(whitespace) *> amountExpression) <*>
    optional(oneOrMore(whitespace) *> char("=") *> zeroOrMore(whitespace) *> amount) <*>
    optional(oneOrMore(whitespace) *> note) <*
    eol <*>
    zeroOrMore(indent *> note <* eol)
)

public let transaction = curry(Transaction.init) <^>
    date <* whitespace <*>
    settled <*>
    zeroOrMore(not("\n")) <*
    eol <*>
    zeroOrMore(indent *> note <* eol) <*>
    oneOrMore(posting)

public let include = string("include ") *> oneOrMore(not("\n")) <* eol

public let tokens = zeroOrMore(
    Token.Transaction <^> transaction <|>
    Token.Include <^> include <|>
    Token.Note <^> (zeroOrMore(whitespace) *> note <* eol)
)
