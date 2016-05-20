//
//  CSV.swift
//  LedgerTools
//
//  Created by Bouke Haarsma on 19-05-16.
//
//

import Foundation
import FootlessParser

let delimiter = "," as Character
let quote = "\"" as Character

let cell = char(quote) *> zeroOrMore(not(quote)) <* char(quote)
    <|> zeroOrMore(noneOf(",\n\r"))

let row = extend <^> cell <*> zeroOrMore( char(delimiter) *> cell ) <* oneOf("\r\n")

let csv = oneOrMore(row)

func parseCSV(filename: String) throws -> [[String]] {
    let input = try String(contentsOfFile: filename)
    do {
        return try parse(csv, input)
    } catch let error as ParseError<Character> {
        print(error: error, in: input)
        throw error
    }
}