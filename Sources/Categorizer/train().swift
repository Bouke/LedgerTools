import Foundation

public typealias Category = String
public typealias Token = String
public typealias History = [(Category, [Token])]
public typealias Categorizer = ([Token]) -> [(Category, Double)]

public func train(_ history: History) -> Categorizer {
    let fm = history.flatMap { $0.1 }
    let tokens = freq(fm)
    let categories = freq(history.map { $0.0 })
    let tokenInCategory = { () -> [Category: [Token: Int]] in
        var r = [Category: [Token: Int]]()
        for (category, tokens) in history {
            if r[category] == nil { r[category] = [:] }
            for token in tokens {
                r[category]?[token] = (r[category]?[token] ?? 0) + 1
            }
        }
        return r
    }()
    
    let probabilityToken = memo { (token: String) -> Double in
        let p = Double(tokens[token] ?? 0) / Double(tokens.values.reduce(0, combine: +))
        return p.isNaN ? 0 : p
    }

    let probabilityAccount = memo { (account: String) -> Double in
        let p = Double(categories[account] ?? 0) / Double(categories.values.reduce(0, combine: +))
        return p.isNaN ? 0 : p
    }

    let probabilityTokenInAccount = memo { (token: String, account: String) -> Double in
        let p = Double(tokenInCategory[account]?[token] ?? 0) / Double(tokenInCategory[account]?.values.reduce(0, combine: +) ?? 0)
        return p.isNaN ? 0 : p
    }

    func probabilityAccountForToken(account: String, token: String) -> Double {
        let p = probabilityTokenInAccount(token, account) * probabilityAccount(account) / probabilityToken(token)
        return p.isNaN ? 0 : p
    }

    func probabilityAccountForTokens(account: String, tokens: [String]) -> Double {
        return tokens.map { probabilityAccountForToken(account: account, token: $0) }.reduce(0, combine: +) / Double(tokens.count)
    }

    return { (tokens) in
        return categories.keys
            .map { ($0, probabilityAccountForTokens(account: $0, tokens: tokens)) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 >= $1.1 }
    }
}