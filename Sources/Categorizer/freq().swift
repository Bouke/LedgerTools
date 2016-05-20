public func freq<S: Sequence, T where S.Iterator.Element == T, T: Hashable>(_ seq: S) -> [T: Int] {
    var result = [T: Int]()
    for element in seq {
        result[element] = (result[element] ?? 0) + 1
    }
    return result
}