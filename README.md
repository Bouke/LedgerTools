# LedgerTools
Tools to support my Ledger workflow. Written in Swift 3. Includes a parser
for reading Ledger files, using NSScanner. It can be configured using either CLI arguments or INI file. The INI file is parsed using Parser Combinators, using the FootlessParser library.

The tool provided will read a CSV file and output a Ledger journal. It will match the accounts using machine learning; calculating probabilities based on history of transactions read from a reference journal.

## Goal
Provide a suite of CLI tools to support some Ledger workflows.

## Building

    brew install libcsv
    make build

## Work in Xcode

    You need to set the "Header Search Path" for the "LedgerTools" project, under Build Settings. Add `/usr/local/opt/libcsv/include` there.

## Todo
* [ ] Write input CSV as-is, if possible.
* [ ] Filter tokens that generate too much noise.
* [ ] Documentation
