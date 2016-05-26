import PackageDescription

let package = Package(
    name: "LedgerTools",
    dependencies: [
        .Package(url: "https://github.com/Bouke/FootlessParser.git", majorVersion: 3),
        .Package(url: "https://github.com/Bouke/CSV.git", majorVersion: 1),
        .Package(url: "https://github.com/Bouke/Glob.git", majorVersion: 1),
    ],
    targets: [
        Target(name: "CLI", dependencies: ["LedgerParser", "Categorizer", "CommandLine", "INI"]),
        Target(name: "LedgerParser"),
        Target(name: "Categorizer"),
        Target(name: "CommandLine"),
        Target(name: "INI"),
    ]
)
