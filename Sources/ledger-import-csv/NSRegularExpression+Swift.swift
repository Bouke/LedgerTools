import Foundation

struct MatchResult {
    var string: String
    var result: NSTextCheckingResult
    var match: String {
        let start = String.UTF16Index(result.range.location)
        let end = String.UTF16Index(result.range.location + result.range.length)
        return String(string.utf16[start..<end])!
    }
    var groups: [String] {
        return (1..<result.numberOfRanges).map { rangeIndex in
            let range = result.rangeAt(rangeIndex)
            let start = String.UTF16Index(range.location)
            let end = String.UTF16Index(range.location + range.length)
            return String(string.utf16[start..<end])!
        }
    }
}

extension NSRegularExpression {
    func matches(`in` string: String, options: NSRegularExpression.MatchingOptions = []) -> [MatchResult] {
        let range = NSRange(location: 0, length: string.utf16.count)
        return self.matches(in: string, options: options, range: range).map { MatchResult(string: string, result: $0) }
    }
}
