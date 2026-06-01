import Foundation

/// Applies moves to game state and manages turn flow.
public enum GameEngine {

    // MARK: - Dice

    public static func roll() -> [Int] {
        let d1 = Int.random(in: 1...6)
        let d2 = Int.random(in: 1...6)
        return d1 == d2 ? [d1, d1, d1, d1] : [d1, d2]
    }

    // MARK: - Turn management

    /// Returns a new state with dice set, ready for move selection.
    public static func applyRoll(_ dice: [Int], to state: GameState) -> GameState {
        var next = state
        next.remainingDice = dice
        return next
    }

    /// Applies a full move (sequence of checker moves) and advances the turn.
    /// Returns nil if the move is not in the legal move list.
    public static func apply(_ move: Move, to state: GameState) -> GameState? {
        let legal = MoveGenerator.legalMoves(for: state)
        guard legal.contains(move) else { return nil }
        var next = state
        for cm in move.checkerMoves {
            applyCheckerMove(cm, player: state.currentPlayer, to: &next)
        }
        if next.winner == nil {
            next.currentPlayer = state.currentPlayer.opponent
            next.remainingDice = []
        }
        return next
    }

    /// Applies a move without legality checking (used internally by MoveGenerator and trainer).
    public static func applyUnchecked(_ move: Move, to state: GameState) -> GameState {
        var next = state
        for cm in move.checkerMoves {
            applyCheckerMove(cm, player: state.currentPlayer, to: &next)
        }
        if next.winner == nil {
            next.currentPlayer = state.currentPlayer.opponent
            next.remainingDice = []
        }
        return next
    }

    // MARK: - Internals

    public static func applyCheckerMove(_ cm: CheckerMove, player: Player, to state: inout GameState) {
        // Remove from source
        if cm.isFromBar {
            if player == .white { state.whiteBar -= 1 } else { state.blackBar -= 1 }
        } else {
            if player == .white { state.points[cm.from] -= 1 } else { state.points[cm.from] += 1 }
        }

        if cm.isBearOff {
            if player == .white { state.whiteBorneOff += 1 } else { state.blackBorneOff += 1 }
            return
        }

        // Hit opponent blot?
        let opponentCount = state.checkerCount(at: cm.to, for: player.opponent)
        if opponentCount == 1 {
            if player == .white { state.points[cm.to] = 0; state.blackBar += 1 }
            else                { state.points[cm.to] = 0; state.whiteBar += 1 }
        }

        // Place on destination
        if player == .white { state.points[cm.to] += 1 } else { state.points[cm.to] -= 1 }
    }
}
