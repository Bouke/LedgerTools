func flag(_ flag: String) -> String? {
    guard let index = Process.arguments.index(of: flag) else { return nil }
    guard index + 1 < Process.arguments.endIndex else { return nil }
    return Process.arguments[index + 1]
}
