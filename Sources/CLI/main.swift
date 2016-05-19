import LedgerParser
import Foundation
import FootlessParser

if Process.arguments.count > 1 {
    do {
        for token in try parse(filename: Process.arguments[1]) {
            print(token)
        }
    } catch let error {
        print(error)
    }
} else {
    print("Enter the line you'd like to parse:")
    while true {
        guard let input = readLine() else { break }
        print("'\(input)'")
        do {
            let output = try count(2..<Int.max, char(" ")).parse(AnyCollection(input.characters))
            print("'\(output.output)'")
            print("'\(String(output.remainder))'")
        } catch let error as ParseError<Character> {
            print(error: error, in: input)
        }
    }
}
