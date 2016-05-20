public func memo<A: Hashable, C> (_ f: (A) -> C) -> (A) -> C {
    var cache = [A: C]()
    return { (a) in
        if let value = cache[a] { return value }
        cache[a] = f(a)
        return cache[a]!
    }
}

public func memo<A: Hashable, B: Hashable, C> (_ f: (A, B) -> C) -> (A, B) -> C {
    var cache = [A: [B: C]]()
    return { (a, b) in
        if let value = cache[a]?[b] { return value }
        if cache[a] == nil { cache[a] = [:] }
        cache[a]![b] = f(a, b)
        return cache[a]![b]!
    }
}
