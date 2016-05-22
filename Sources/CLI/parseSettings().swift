import Foundation
import class CommandLine.CommandLine
import class CommandLine.StringOption
import class CommandLine.IntOption
import class CommandLine.BoolOption
import func INI.parseINI
import struct INI.Config

struct Settings {
    var trainFile = "ledger.dat"

    var csvDateFormat = "yyyy-MM-dd"
    var csvDateColumn = 0
    var csvPayeeColumn = 1
    var csvAmountColumn = 2
    var csvDescriptionColumn = 3
    var csvTokenSeparators = ",; \t\"'/:"
    var csvSkipRows = 0
    var csvReverseRows = false

    var ledgerDateFormat = "yyyy-MM-dd"
    var ledgerTokenSeparators = ",; \t\"':"

    var transactionsFile: String!
}

func parseSettings() -> Settings {
    let cli = CommandLine()
    let configFile = StringOption(shortFlag: "c", helpMessage: "Config file [default=.ledger-tools]")
    let sectionName = StringOption(shortFlag: "s", helpMessage: "Config file section name")
    let trainFile = StringOption(shortFlag: "t", longFlag: "train-file",
        helpMessage: "Ledger file to train categorizer [default=ledger.dat]")

    let csvDateFormat = StringOption(shortFlag: "f", longFlag: "csv-date-format",
        helpMessage: "[default=yyyy-MM-dd]")
    let csvDateColumn = IntOption(shortFlag: "d", longFlag: "csv-date-column",
        helpMessage: "[default=0]")
    let csvPayeeColumn = IntOption(shortFlag: "p", longFlag: "csv-payee-column",
        helpMessage: "[default=1]")
    let csvAmountColumn = IntOption(shortFlag: "a", longFlag: "csv-amount-column",
        helpMessage: "[default=2]")
    let csvDescriptionColumn = IntOption(shortFlag: "n", longFlag: "csv-description-column",
        helpMessage: "[default=3]")
    let csvTokenSeparators = StringOption(longFlag: "csv-token-separators",
        helpMessage: "[default=,; \\t\"'")
    let csvSkipRows = IntOption(longFlag: "csv-skip-rows",
        helpMessage: "[default=0]")
    let csvReverseRows = BoolOption(shortFlag: "r", longFlag: "csv-reverse-rows",
        helpMessage: "[default=false]")

    let ledgerDateFormat = StringOption(shortFlag: "g", longFlag: "ledger-date-format",
        helpMessage: "[default=yyyy-MM-dd]")
    let ledgerTokenSeparators = StringOption(longFlag: "ledger-token-separators",
        helpMessage: "[default=,; \\t\"'")

    cli.addOptions(configFile, sectionName, trainFile,
        csvDateFormat, csvDateColumn, csvPayeeColumn, csvAmountColumn,
        csvDescriptionColumn, csvTokenSeparators, csvSkipRows, csvReverseRows,
        ledgerDateFormat, ledgerTokenSeparators)

    do {
        try cli.parse(strict: true)
    } catch {
        cli.printUsage(error)
        exit(EX_USAGE)
    }

    // Expect the transaction file as unparsed argument (not matched by flag);
    // only one transaction file is expected.
    guard cli.unparsedArguments.count == 1 else {
        print("Specify exactly one transaction file argument");
        exit(EX_USAGE)
    }

    // Start with default settings; to be overriden with config file and CLI
    // arguments.
    var settings = Settings()
    settings.transactionsFile = cli.unparsedArguments[0]

    // Use INI configuration file settings, if set.
    if let sectionName = sectionName.value {
        let config: Config
        do {
            config = try parseINI(filename: ((configFile.value ?? ".ledger-tools") as NSString).standardizingPath)
        } catch {
            print("Could not read settings file")
            exit(EX_USAGE)
        }
        guard let section = config[sectionName] else {
            print("Section \(sectionName) not found in config file")
            exit(EX_USAGE)
        }
        // TODO: resolve train file relative to config file path
        if let trainFile = section["train-file"] { settings.trainFile = trainFile }

        if let csvDateFormat = section["csv-date-format"] { settings.csvDateFormat = csvDateFormat }
        if let csvDateColumn = section["csv-date-column"].flatMap({ Int($0) }) { settings.csvDateColumn = csvDateColumn }
        if let csvPayeeColumn = section["csv-payee-column"].flatMap({ Int($0) }) { settings.csvPayeeColumn = csvPayeeColumn }
        if let csvAmountColumn = section["csv-amount-column"].flatMap({ Int($0) }) { settings.csvAmountColumn = csvAmountColumn }
        if let csvDescriptionColumn = section["csv-description-column"].flatMap({ Int($0) }) { settings.csvDescriptionColumn = csvDescriptionColumn }
        if let csvTokenSeparators = section["csv-token-separators"] { settings.csvTokenSeparators = interpretEscapes(csvTokenSeparators) }
        if let csvSkipRows = section["csv-skip-rows"].flatMap({ Int($0) }) { settings.csvSkipRows = csvSkipRows }
        settings.csvReverseRows = section.bool("csv-reverse-rows")

        if let ledgerDateFormat = section["ledger-date-format"] { settings.ledgerDateFormat = ledgerDateFormat }
        if let ledgerTokenSeparators = section["ledger-token-separators"] { settings.ledgerTokenSeparators = interpretEscapes(ledgerTokenSeparators) }
    }

    // Override defaults with CLI arguments.

    // TODO: resolve train file relative to CWD
    if let trainFile = trainFile.value { settings.trainFile = trainFile }

    if let csvDateFormat = csvDateFormat.value { settings.csvDateFormat = csvDateFormat }
    if let csvDateColumn = csvDateColumn.value { settings.csvDateColumn = csvDateColumn }
    if let csvPayeeColumn = csvPayeeColumn.value { settings.csvPayeeColumn = csvPayeeColumn }
    if let csvAmountColumn = csvAmountColumn.value { settings.csvAmountColumn = csvAmountColumn }
    if let csvDescriptionColumn = csvDescriptionColumn.value { settings.csvDescriptionColumn = csvDescriptionColumn }
    if let csvTokenSeparators = csvTokenSeparators.value { settings.csvTokenSeparators = interpretEscapes(csvTokenSeparators) }
    if let csvSkipRows = csvSkipRows.value { settings.csvSkipRows = csvSkipRows }
    if csvReverseRows.wasSet { settings.csvReverseRows = true }

    if let ledgerDateFormat = ledgerDateFormat.value { settings.ledgerDateFormat = ledgerDateFormat }
    if let ledgerTokenSeparators = ledgerTokenSeparators.value { settings.ledgerTokenSeparators = interpretEscapes(ledgerTokenSeparators) }

    return settings
}

private func interpretEscapes(_ s: String) -> String {
    return s
        .replacingOccurrences(of: "\\t", with: "\t")
        .replacingOccurrences(of: "\\n", with: "\n")
        .replacingOccurrences(of: "\\r", with: "\r")
}
