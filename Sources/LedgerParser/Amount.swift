//
//  Amount.swift
//  Ledger
//
//  Created by Bouke Haarsma on 18-05-16.
//
//

import Foundation
import FootlessParser

public struct Amount {
    let amount: Double
    let currency: String?

    public init(amount: Double, currency: String?) {
        self.amount = amount
        self.currency = currency
    }

    static func create(amount: Double) -> (String) -> Amount {
        return { currency in Amount(amount: amount, currency: currency) }
    }

    static func etaerc(currency: String) -> (Double) -> Amount {
        return { amount in Amount(amount: amount, currency: currency) }
    }
}

func * (lhs: Amount, rhs: Amount) -> Amount {
    precondition((lhs.currency == nil) || (rhs.currency == nil), "Amount expressions must result in a simple amount")
    return Amount(amount: lhs.amount * rhs.amount, currency: lhs.currency ?? rhs.currency)
}

func / (lhs: Amount, rhs: Amount) -> Amount {
    precondition((lhs.currency == nil) || (rhs.currency == nil), "Amount expressions must result in a simple amount")
    return Amount(amount: lhs.amount / rhs.amount, currency: lhs.currency ?? rhs.currency)
}

func + (lhs: Amount, rhs: Amount) -> Amount {
    precondition(lhs.currency == rhs.currency, "Amount expressions must result in a simple amount")
    return Amount(amount: lhs.amount + rhs.amount, currency: lhs.currency)
}

func - (lhs: Amount, rhs: Amount) -> Amount {
    precondition(lhs.currency == rhs.currency, "Amount expressions must result in a simple amount")
    return Amount(amount: lhs.amount - rhs.amount, currency: lhs.currency)
}

public func == (lhs: Amount, rhs: Amount) -> Bool {
    return lhs.amount == rhs.amount && lhs.currency == rhs.currency
}
extension Amount: Equatable { }

let sign = string("-") <|> string("")

public let double = {Double($0)!} <^> (extend <^> (extend <^> sign <*> oneOrMore(digit)) <*> optional(extend <^> char(".") <*> oneOrMore(digit), otherwise: ""))

// note: this should be more restrictive
public let currency = oneOrMore(noneOf("01234567890.,/@- \n=()+".characters.map { String($0) }))

let f = { (a: Double, c: String?) in Amount(amount: a, currency: c) }
let amount = optional(currency) >>- { (c: String?) -> Parser<Character, Amount> in
    if c != nil {
        return curry(f) <^> (optional(whitespace) *> double) <*> pure(c)
    } else {
        return curry(f) <^> double <*> optional(optional(whitespace) *> currency)
    }
}

public let amountExpression: Parser<Character, Amount> = {
    var expression: Parser<Character, Amount>!

    let factor = zeroOrMore(whitespace) *> amount <* zeroOrMore(whitespace) <|> lazy( char("(") *> expression <* char(")") )

    var term: Parser<Character, Amount>!
    term = lazy( curry(*) <^> factor <* char("*") <*> term <|> curry(/) <^> factor <* char("/") <*> term <|> factor )

    expression = lazy( curry(+) <^> term <* char("+") <*> expression <|> curry(-) <^> term <* char("-") <*> expression <|> term )
    return amount <|> char("(") *> expression <* char(")")
}()

