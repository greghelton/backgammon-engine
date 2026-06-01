/// Represents the complete state of a backgammon game at a single point in time.
///
/// Board layout (from White's perspective):
///   Points 1-24, where White bears off at point 0 and Black bears off at point 25.
///   Positive counts = White checkers, negative counts = Black checkers.
///
/// Bar: whitebar holds White checkers on the bar, blackBar holds Black checkers.
public struct GameState: Sendable, Hashable {

    // MARK: - Board

    /// 24 points. Positive = White checkers, negative = Black checkers.
    public var points: [Int]

    /// White checkers on the bar.
    public var whiteBar: Int

    /// Black checkers on the bar.
    public var blackBar: Int

    /// White checkers already borne off.
    public var whiteBorneOff: Int

    /// Black checkers already borne off.
    public var blackBorneOff: Int

    // MARK: - Turn

    public var currentPlayer: Player

    /// Remaining dice to use this turn. Empty when waiting for a roll.
    public var remainingDice: [Int]

    // MARK: - Init

    public init() {
        points = Array(repeating: 0, count: 24)
        whiteBar = 0
        blackBar = 0
        whiteBorneOff = 0
        blackBorneOff = 0
        currentPlayer = .white
        remainingDice = []
        setupInitialPosition()
    }

    public init(
        points: [Int],
        whiteBar: Int = 0,
        blackBar: Int = 0,
        whiteBorneOff: Int = 0,
        blackBorneOff: Int = 0,
        currentPlayer: Player = .white,
        remainingDice: [Int] = []
    ) {
        self.points = points
        self.whiteBar = whiteBar
        self.blackBar = blackBar
        self.whiteBorneOff = whiteBorneOff
        self.blackBorneOff = blackBorneOff
        self.currentPlayer = currentPlayer
        self.remainingDice = remainingDice
    }

    // MARK: - Derived state

    public var winner: Player? {
        if whiteBorneOff == 15 { return .white }
        if blackBorneOff == 15 { return .black }
        return nil
    }

    public var isGameOver: Bool { winner != nil }

    /// Checker count on a point from the current player's perspective (positive = owned).
    public func checkerCount(at point: Int, for player: Player) -> Int {
        let raw = points[point]
        return player == .white ? raw : -raw
    }

    // MARK: - Private setup

    private mutating func setupInitialPosition() {
        // Standard backgammon starting position (White's perspective, 1-indexed → 0-indexed)
        // White: 2 on point 24, 5 on point 13, 3 on point 8, 5 on point 6
        // Black: mirror image (negative values)
        points[23] =  2   // White: point 24
        points[12] =  5   // White: point 13
        points[ 7] =  3   // White: point 8
        points[ 5] =  5   // White: point 6

        points[ 0] = -2   // Black: point 1  (mirror of White point 24)
        points[11] = -5   // Black: point 12 (mirror of White point 13)
        points[16] = -3   // Black: point 17 (mirror of White point 8)
        points[18] = -5   // Black: point 19 (mirror of White point 6)
    }
}
