import XCTest
import Foundation

import LedgerParser
import FootlessParser

class LedgerTests: XCTestCase {
    func test_performance() throws {
        let input = NSURL(fileURLWithPath: #file).deletingLastPathComponent!.appendingPathComponent("test.dat").path!
        measure {
            do {
                let result = try parseLedger(filename: input)
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
			("test_performance", test_performance),
		]
	}
}
