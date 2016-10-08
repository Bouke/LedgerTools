import PackageDescription

let package = Package(
    name: "LedgerTools",
    targets: [
        Target(name: "ledger-import-csv", dependencies: ["LedgerParser", "Categorizer", "CommandLineKit"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/Bouke/CSV.git", versions: Version(1, 1, 0)..<Version(2, 0, 0)),
        .Package(url: "https://github.com/Bouke/Glob.git", versions: Version(1, 0, 3)..<Version(2, 0, 0)),
        .Package(url: "https://github.com/Bouke/INI.git", versions: Version(1, 0, 2)..<Version(2, 0, 0)),
    ]
)
