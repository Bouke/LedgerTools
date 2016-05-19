public typealias Date = (String, String, String)

public struct Transaction {
    public let date: Date
    public let settled: Bool
    public let payee: String
    public let notes: [String]
    public let postings: [Posting]

    public init(date: Date, settled: Bool, payee: String, notes: [String], postings: [Posting]) {
        self.date = date
        self.settled = settled
        self.payee = payee
        self.notes = notes
        self.postings = postings
    }

    public struct Posting {
        public let account: String
        public let amount: Amount?
        public let balance: Amount?
        public let notes: [String]

        public init(account: String, amount: Amount?, balance: Amount?, notes: [String]) {
            self.account = account
            self.amount = amount
            self.balance = balance
            self.notes = notes
        }
    }
}

public func == (lhs: Transaction, rhs: Transaction) -> Bool {
    return lhs.date == rhs.date && lhs.settled == rhs.settled && lhs.payee == rhs.payee && lhs.postings == rhs.postings && lhs.notes == rhs.notes
}
extension Transaction: Equatable { }

public func == (lhs: Transaction.Posting, rhs: Transaction.Posting) -> Bool {
    return lhs.account == rhs.account && lhs.amount == rhs.amount && lhs.balance == rhs.balance && lhs.notes == rhs.notes
}
extension Transaction.Posting: Equatable { }
