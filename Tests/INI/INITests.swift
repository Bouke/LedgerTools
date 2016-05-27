import XCTest
import Foundation

import INI

class INITests: XCTestCase {
    func test_simple() {
        let ini = "[Header]\nKey=Value\n"
        guard let config = try? parseINI(string: ini) else { return XCTFail("Could not parse INI") }
        guard let section = config["Header"] else { return XCTFail("No section named 'Header'") }
        XCTAssertEqual(section["Key"], "Value")
    }

    func test_multiple_headers() {
        let ini = "[Section1]\nKey=Foo\n[Section2]\nKey=Bar\n"
        guard let config = try? parseINI(string: ini) else { return XCTFail("Could not parse INI") }
        guard let section1 = config["Section1"] else { return XCTFail("No section named 'Section1'") }
        guard let section2 = config["Section2"] else { return XCTFail("No section named 'Section2'") }
        XCTAssertEqual(section1["Key"], "Foo")
        XCTAssertEqual(section2["Key"], "Bar")
    }

    func test_duplicate_header() {
        let ini = "[Section]\nA=A\nB=B\n[Section]\nA=B\nC=C\n"
        guard let config = try? parseINI(string: ini) else { return XCTFail("Could not parse INI") }
        guard let _ = config["Section"] else { return XCTFail("No section named 'Section'") }
    }

    func test_comment() {
        let ini = "[Header]\nKey=Value\n;Comment\n"
        guard let config = try? parseINI(string: ini) else { return XCTFail("Could not parse INI") }
        guard let section = config["Header"] else { return XCTFail("No section named 'Header'") }
        XCTAssertEqual(section["Key"], "Value")
    }
}
