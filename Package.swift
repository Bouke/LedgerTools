import PackageDescription

let package = Package(
    name: "Ledger",
    dependencies: [
        .Package(url: "https://github.com/Bouke/FootlessParser.git", majorVersion: 3),
        .Package(url: "https://github.com/Bouke/Glob.git", majorVersion: 1),
    ],
    targets: [
        Target(name: "CLI", dependencies: ["LedgerParser"]),
        Target(name: "LedgerParser"),
    ]
)
