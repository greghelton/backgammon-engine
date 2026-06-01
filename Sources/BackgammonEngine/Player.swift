public enum Player: Int, Sendable, Hashable, CaseIterable {
    case white = 1
    case black = -1

    public var opponent: Player {
        self == .white ? .black : .white
    }

    /// Direction of movement on the points array. White moves from high to low index.
    public var direction: Int {
        self == .white ? -1 : 1
    }
}
