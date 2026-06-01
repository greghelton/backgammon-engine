/// A single checker movement using one die.
public struct CheckerMove: Sendable, Hashable {
    /// Source point (0-23), or 24 meaning "from the bar".
    public let from: Int
    /// Destination point (0-23), or -1 meaning "bear off".
    public let to: Int
    /// The die value used.
    public let die: Int

    public static let barIndex = 24
    public static let bearOffIndex = -1

    public var isFromBar: Bool { from == CheckerMove.barIndex }
    public var isBearOff: Bool { to == CheckerMove.bearOffIndex }

    public init(from: Int, to: Int, die: Int) {
        self.from = from
        self.to = to
        self.die = die
    }
}

/// A full turn: an ordered sequence of checker moves that consumes some or all remaining dice.
public struct Move: Sendable, Hashable {
    public let checkerMoves: [CheckerMove]

    public init(_ checkerMoves: [CheckerMove]) {
        self.checkerMoves = checkerMoves
    }

    public var isEmpty: Bool { checkerMoves.isEmpty }
}
