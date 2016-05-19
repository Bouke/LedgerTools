//
//  Parser.swift
//  Ledger
//
//  Created by Bouke Haarsma on 18-05-16.
//
//

import Foundation
import FootlessParser
import Glob

public func parse(filename: String) throws -> [Token] {
    let input = try String(contentsOfFile: filename)
    var result = [Token]()
    let parsed: [Token]
    do {
        parsed = try parse(tokens, input)
    } catch let error as ParseError<Character> {
        print(error: error, in: input)
        throw error
    }
    for token in parsed {
        switch token {
        case .Include(let pattern):
            var pattern = pattern
            if pattern.characters.first != "/" {
                pattern = NSURL(fileURLWithPath: filename).deletingLastPathComponent!.appendingPathComponent(pattern).path!
            }
            for filename in Glob(pattern: pattern) {
                for token2 in try parse(filename: filename) {
                    result.append(token2)
                }
            }
        default: result.append(token)
        }
    }
    return result
}
