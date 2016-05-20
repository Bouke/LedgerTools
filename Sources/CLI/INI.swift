//
//  CSV.swift
//  LedgerTools
//
//  Created by Bouke Haarsma on 19-05-16.
//
//

import Foundation
import FootlessParser

struct Config {
    let sections: [Section]

    subscript(key: String) -> Section? {
        return sections.filter { $0.name == key }.first
    }
}

struct Section {
    let name: String
    let settings: [String: String]

    init(name: String, settings: [(String, String)]) {
        self.name = name
        var s = [String: String]()
        for (key, value) in settings { s[key] = value }
        self.settings = s
    }

    subscript(key: String) -> String? {
        return settings[key]
    }

    func bool(key: String) -> Bool {
        return ["1", "true", "yes"].contains(settings[key] ?? "")
    }
}

let setting = tuple <^> oneOrMore(noneOf(" =\n[]")) <* optional(whitespace) <* char("=") <* optional(whitespace) <*> oneOrMore(not("\n")) <* oneOrMore(newline)
let header = char("[") *> oneOrMore(not("]")) <* char("]") <* oneOrMore(newline)
let section = curry(Section.init) <^> header <*> zeroOrMore(setting)
let ini = Config.init <^> (zeroOrMore(newline) *> zeroOrMore(section))

func parseINI(filename: String) throws -> Config {
    let input = try String(contentsOfFile: filename)
    do {
        return try parse(ini, input)
    } catch let error as ParseError<Character> {
        print(error: error, in: input)
        throw error
    }
}