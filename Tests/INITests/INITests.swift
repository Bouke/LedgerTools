import XCTest
import Foundation

import INI

class INITests: XCTestCase {
    func test_simple() {
        let ini = "[Header]\nKey=Value\n"
        do {
            let config = try parseINI(string: ini)
            guard let section = config["Header"] else { return XCTFail("No section named 'Header'") }
            XCTAssertEqual(section["Key"], "Value")
        } catch {
            XCTFail("Could not parse INI: \(error)")
        }
    }

    func test_multiple_headers() {
        let ini = "[Section1]\nKey=Foo\n[Section2]\nKey=Bar\n"
        do {
            let config = try parseINI(string: ini)
            guard let section1 = config["Section1"] else { return XCTFail("No section named 'Section1'") }
            guard let section2 = config["Section2"] else { return XCTFail("No section named 'Section2'") }
            XCTAssertEqual(section1["Key"], "Foo")
            XCTAssertEqual(section2["Key"], "Bar")
        } catch {
            XCTFail("Could not parse INI: \(error)")
        }
    }

    func test_duplicate_header() {
        let ini = "[Section]\nA=A\nB=B\n[Section]\nA=B\nC=C\n"
        do {
            let config = try parseINI(string: ini)
            guard let _ = config["Section"] else { return XCTFail("No section named 'Section'") }
        } catch {
            XCTFail("Could not parse INI: \(error)")
        }
    }

    func test_comment() {
        let ini = "[Header]\nKey=Value\n;Comment\n"
        do {
            let config = try parseINI(string: ini)
            guard let section = config["Header"] else { return XCTFail("No section named 'Header'") }
            XCTAssertEqual(section["Key"], "Value")
        } catch {
            XCTFail("Could not parse INI: \(error)")
        }
    }

    func test_symbols() {
        let ini = "[Header]\nkey-name=foo\nother_key=bar\n"
        do {
            let config = try parseINI(string: ini)
            guard let section = config["Header"] else { return XCTFail("No section named 'Header'") }
            XCTAssertEqual(section["key-name"], "foo")
            XCTAssertEqual(section["other_key"], "bar")
        } catch {
            XCTFail("Could not parse INI: \(error)")
        }
    }
}
