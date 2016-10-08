func flag(_ flag: String) -> String? {
    guard let index = CommandLine.arguments.index(of: flag) else { return nil }
    guard index + 1 < CommandLine.arguments.endIndex else { return nil }
    return CommandLine.arguments[index + 1]
}
