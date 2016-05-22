extension String {
    func pad(_ length: Int) -> String {
        return padding(toLength: length, withPad: " ", startingAt: 0)
    }
}
