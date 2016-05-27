//
//  CSV.swift
//  LedgerTools
//
//  Created by Bouke Haarsma on 19-05-16.
//
//

import Foundation
import FootlessParser

public struct Config {
    public let sections: [Section]

    public subscript(key: String) -> Section? {
        return sections.filter { $0.name == key }.first
    }
}

public struct Section {
    public let name: String
    public let settings: [String: String]

    init(name: String, settings: [(String, String)]) {
        self.name = name
        var s = [String: String]()
        for (key, value) in settings { s[key] = value }
        self.settings = s
    }

    public subscript(key: String) -> String? {
        return settings[key]
    }

    public func bool(_ key: String) -> Bool {
        return ["1", "true", "yes"].contains(settings[key] ?? "")
    }
}

internal let parser: Parser<Character, Config> = {
    let setting = tuple <^> oneOrMore(noneOf(" =\n[]")) <* optional(whitespace) <* char("=") <* optional(whitespace) <*> oneOrMore(not("\n")) <* oneOrMore(newline)
    let header = char("[") *> oneOrMore(not("]")) <* char("]") <* oneOrMore(newline)
    let section = curry(Section.init) <^> header <*> zeroOrMore(setting)
    return Config.init <^> (zeroOrMore(newline) *> zeroOrMore(section))
}()

public func parseINI(filename: String) throws -> Config {
    let input = try String(contentsOfFile: filename)
    return try parseINI(string: input)
}

public func parseINI(string: String) throws -> Config {
    do {
        return try parse(parser, string)
    } catch let error as ParseError<Character> {
        print(error: error, in: string)
        throw error
    }
}
