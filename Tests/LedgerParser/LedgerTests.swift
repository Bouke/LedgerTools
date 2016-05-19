import XCTest
import Foundation

import Ledger
import FootlessParser

class LedgerTests: XCTestCase {

    func test_date() throws {
        let cases: [(String, Date?, UInt)] = [
            ("2016-01-01", ("2016", "01", "01"), #line),
            ("2016-12-31", ("2016", "12", "31"), #line),
            ("abcd-ef-gh", nil, #line),
        ]
        try test(parser: date, cases: cases, equal: { $0 == $1 })
    }

    func test_transaction_posting() throws {
        try test(parser: posting, cases: [
            ("    Assets:Cash\n",
                Transaction.Posting(account: "Assets:Cash", amount: nil, balance: nil, notes: []), #line),
            ("    Assets:Cash    € 100.0\n",
                Transaction.Posting(account: "Assets:Cash", amount: Amount(amount: 100, currency: "€"), balance: nil, notes: []), #line),
            ("    Assets:Cash    =€200\n",
                Transaction.Posting(account: "Assets:Cash", amount: nil, balance: Amount(amount: 200, currency: "€"), notes: []), #line),
            ("    Assets:Cash    € 100.0 = € 200.0\n",
                Transaction.Posting(account: "Assets:Cash", amount: Amount(amount: 100, currency: "€"), balance: Amount(amount: 200, currency: "€"), notes: []), #line),
            ("    Assets:Cash    100 €\n",
                Transaction.Posting(account: "Assets:Cash", amount: Amount(amount: 100, currency: "€"), balance: nil, notes: []), #line),
            ("    Assets:Cash  ; hello\n",
                Transaction.Posting(account: "Assets:Cash", amount: nil, balance: nil, notes: ["hello"]), #line),
            ("    Assets:Cash\n  ; hello\n",
                Transaction.Posting(account: "Assets:Cash", amount: nil, balance: nil, notes: ["hello"]), #line),
            ("    Assets:Cash  ; hello\n ;world\n",
                Transaction.Posting(account: "Assets:Cash", amount: nil, balance: nil, notes: ["hello", "world"]), #line),
            ("Assets:Cash\n", nil, #line),  // missing identation
        ])
    }

    func test_include() throws {
        try test(parser: include, cases: [
            ("include bouke.dat\n", "bouke.dat", #line),
            ("include\n", nil, #line),
            ("include \n", nil, #line),
            ("include \"\"\n", "\"\"", #line),
            ("include \"bouke.dat\"\n", "\"bouke.dat\"", #line),
        ])
    }

    func test_transaction() throws {
        try test(parser: transaction, cases: [
            ("2016-01-01 Company\n    Cash  € 1\n    Gas  1 €\n",
             Transaction(
                date: Date("2016", "01", "01"),
                settled: false,
                payee: "Company",
                notes: [],
                postings: [
                    Transaction.Posting(account: "Cash", amount: Amount(amount: 1, currency: "€"), balance: nil, notes: []),
                    Transaction.Posting(account: "Gas", amount: Amount(amount: 1, currency: "€"), balance: nil, notes: []),
                ]), #line),
            ("2016-01-01 * Company\n    ; Note about transaction\n    Cash\n    ;Another note\n    Gas  € 1\n",
             Transaction(
                date: Date("2016", "01", "01"),
                settled: true,
                payee: "Company",
                notes: ["Note about transaction"],
                postings: [
                    Transaction.Posting(account: "Cash", amount: nil, balance: nil, notes: ["Another note"]),
                    Transaction.Posting(account: "Gas", amount: Amount(amount: 1, currency: "€"), balance: nil, notes: []),
                ]), #line),
            ("2016-01-01 * Company\n", nil, #line),
        ])
    }

    func test_double() throws {
        try test(parser: double, cases: [
            ("5", 5, #line),
            ("5.12", 5.12, #line),
        ])
    }

    func test_currency() throws {
        try test(parser: currency, cases: [
            ("EUR", "EUR", #line),
            ("€", "€", #line),
        ])
    }

    func test_amount() throws {
        try test(parser: amountExpression, cases: [
            ("5.12 EUR", Amount(amount: 5.12, currency: "EUR"), #line),
            ("6.99EUR", Amount(amount: 6.99, currency: "EUR"), #line),
            ("€ 1234.00", Amount(amount: 1234.00, currency: "€"), #line),
            ("€9", Amount(amount: 9.0, currency: "€"), #line),
            ("-5.12 EUR", Amount(amount: -5.12, currency: "EUR"), #line),
            ("-6.99EUR", Amount(amount: -6.99, currency: "EUR"), #line),
            ("€ -1234.00", Amount(amount: -1234.00, currency: "€"), #line),
            ("€-9", Amount(amount: -9.0, currency: "€"), #line),
            ("", nil, #line),
            ("9€90", nil, #line),
            ("-123.45", Amount(amount: -123.45, currency: nil), #line),
            ("1+1", nil, #line),
            ("(1+1)", Amount(amount: 2, currency: nil), #line),
            ("(2-1)", Amount(amount: 1, currency: nil), #line),
            ("(€5*5)", Amount(amount: 25, currency: "€"), #line),
            ("(25€/5)", Amount(amount: 5, currency: "€"), #line),
            ("(1 +1)", Amount(amount: 2, currency: nil), #line),
            ("(1 +(1 -1))", Amount(amount: 1, currency: nil), #line),
            ("(2- 1)", Amount(amount: 1, currency: nil), #line),
            ("(€5 * 5)", Amount(amount: 25, currency: "€"), #line),
            ("(25€/ 5)", Amount(amount: 5, currency: "€"), #line),
        ])
    }

    func test_performance() throws {
        let input = try String(contentsOfFile: NSURL(fileURLWithPath: #file).deletingLastPathComponent!.appendingPathComponent("test.dat").path!)
        measure {
            do {
                let result = try parse(tokens, input)
                XCTAssertEqual(result.count, 333)
            } catch let error {
                XCTFail(String(error))
            }
        }
    }
}

extension LedgerTests {
	static var allTests : [(String, (LedgerTests) -> () throws -> Void)] {
		return [
			("test_date", test_date),
		]
	}
}

func test<T where T: Equatable>(parser: Parser<Character, T>, cases: [(String, T?, UInt)], file: StaticString = #file) throws {
    return try test(parser: parser, cases: cases, equal: { $0 == $1 }, file: file)
}

func test<T>(parser: Parser<Character, T>, cases: [(String, T?, UInt)], equal: (T, T) -> Bool, file: StaticString = #file) throws {
    for (input, expected, line) in cases {
        do {
            let actual = try parse(parser, input)
            switch (actual, expected) {
            case let(_, .some(expected)) where !equal(actual, expected):
                XCTFail("\(actual) is not equal to \(expected)", file: file, line: line)
            case (_, .none):
                XCTFail("\(actual) is not equal to nil", file: file, line: line)
            default: break
            }
        } catch let error as ParseError<Character> {
            if let expected = expected {
                XCTFail("Got error: \(error), is not equal to \(expected)", file: file, line: line)
            }
        }
    }
}
