/// Generates all legal moves for the current player given a rolled set of dice.
///
/// Backgammon rules enforced:
///   - Bar checkers must enter before any other move.
///   - Must use both dice if possible; if only one can be used, must use the higher.
///   - Bearing off requires all checkers in the home board; exact or higher die allowed.
///   - Cannot land on a point holding 2+ opponent checkers (a "made point").
public enum MoveGenerator {

    public static func legalMoves(for state: GameState) -> [Move] {
        let dice = state.remainingDice
        guard !dice.isEmpty, state.winner == nil else { return [] }

        let player = state.currentPlayer
        let uniqueDice = uniqueCombinations(of: dice)

        var allMoves: [Move] = []
        for diceSet in uniqueDice {
            let moves = generateMoves(state: state, player: player, dice: diceSet, path: [])
            allMoves.append(contentsOf: moves)
        }

        // Deduplicate by checker move sequence
        let unique = Array(Set(allMoves))

        // Must maximise dice usage: prefer moves that use more dice
        return filterMaximalMoves(unique)
    }

    // MARK: - Recursive move building

    private static func generateMoves(
        state: GameState,
        player: Player,
        dice: [Int],
        path: [CheckerMove]
    ) -> [Move] {
        if dice.isEmpty { return [Move(path)] }

        let bar = player == .white ? state.whiteBar : state.blackBar
        var results: [Move] = []

        if bar > 0 {
            // Must enter from bar
            for (i, die) in dice.enumerated() {
                if let move = enterMove(from: bar > 0, die: die, player: player, state: state) {
                    var nextState = state
                    GameEngine.applyCheckerMove(move, player: player, to: &nextState)
                    var remaining = dice
                    remaining.remove(at: i)
                    let sub = generateMoves(state: nextState, player: player, dice: remaining, path: path + [move])
                    results.append(contentsOf: sub)
                }
            }
            if results.isEmpty { return [Move(path)] }
            return results
        }

        let canBearOff = allCheckersInHomeBoard(state: state, player: player)

        for (i, die) in dice.enumerated() {
            // Skip duplicate dice values already processed at this level
            if i > 0 && dice[i] == dice[i - 1] { continue }

            let sources = sourcesForNormalMove(state: state, player: player, die: die, canBearOff: canBearOff)
            for from in sources {
                let to = destination(from: from, die: die, player: player, canBearOff: canBearOff, state: state)
                let move = CheckerMove(from: from, to: to, die: die)
                var nextState = state
                GameEngine.applyCheckerMove(move, player: player, to: &nextState)
                var remaining = dice
                remaining.remove(at: i)
                let sub = generateMoves(state: nextState, player: player, dice: remaining, path: path + [move])
                results.append(contentsOf: sub)
            }
        }

        if results.isEmpty { return [Move(path)] }
        return results
    }

    // MARK: - Enter from bar

    private static func enterMove(from _: Bool, die: Int, player: Player, state: GameState) -> CheckerMove? {
        let target: Int
        if player == .white {
            // White enters on points 19-24 (indices 18-23), die 1 → index 23, die 6 → index 18
            target = 24 - die  // index
        } else {
            // Black enters on points 1-6 (indices 0-5), die 1 → index 0, die 6 → index 5
            target = die - 1   // index
        }
        guard target >= 0, target < 24 else { return nil }
        guard canLand(at: target, player: player, state: state) else { return nil }
        return CheckerMove(from: CheckerMove.barIndex, to: target, die: die)
    }

    // MARK: - Normal move sources

    private static func sourcesForNormalMove(
        state: GameState,
        player: Player,
        die: Int,
        canBearOff: Bool
    ) -> [Int] {
        var sources: [Int] = []
        for point in 0..<24 {
            let count = state.checkerCount(at: point, for: player)
            guard count > 0 else { continue }

            let rawDest = pointIndex(from: point, die: die, player: player)

            if rawDest >= 0 && rawDest < 24 {
                if canLand(at: rawDest, player: player, state: state) {
                    sources.append(point)
                }
            } else if canBearOff {
                // Bear off: destination is off the board
                if bearOffAllowed(from: point, die: die, player: player, state: state) {
                    sources.append(point)
                }
            }
        }
        return sources
    }

    private static func destination(
        from point: Int,
        die: Int,
        player: Player,
        canBearOff: Bool,
        state: GameState
    ) -> Int {
        let raw = pointIndex(from: point, die: die, player: player)
        if raw >= 0 && raw < 24 { return raw }
        if canBearOff { return CheckerMove.bearOffIndex }
        return raw // shouldn't reach
    }

    // MARK: - Bear off helpers

    private static func allCheckersInHomeBoard(state: GameState, player: Player) -> Bool {
        let bar = player == .white ? state.whiteBar : state.blackBar
        if bar > 0 { return false }

        // White home board: points 1-6 (indices 0-5)
        // Black home board: points 19-24 (indices 18-23)
        let homeRange: Range<Int> = player == .white ? 0..<6 : 18..<24
        for point in 0..<24 {
            guard !homeRange.contains(point) else { continue }
            if state.checkerCount(at: point, for: player) > 0 { return false }
        }
        return true
    }

    private static func bearOffAllowed(from point: Int, die: Int, player: Player, state: GameState) -> Bool {
        let raw = pointIndex(from: point, die: die, player: player)
        if player == .white {
            if raw == -1 { return true } // exact
            if raw < -1 {
                // Die overshoots; only allowed if no checker is on a higher point
                let higherRange = (point + 1)..<6
                return higherRange.allSatisfy { state.checkerCount(at: $0, for: player) == 0 }
            }
        } else {
            if raw == 24 { return true }
            if raw > 24 {
                let lowerRange = 18..<point
                return lowerRange.allSatisfy { state.checkerCount(at: $0, for: player) == 0 }
            }
        }
        return false
    }

    // MARK: - Landing rules

    private static func canLand(at point: Int, player: Player, state: GameState) -> Bool {
        let opponentCount = state.checkerCount(at: point, for: player.opponent)
        return opponentCount <= 1  // 0 = empty/own, 1 = blot (can hit), 2+ = made point
    }

    // MARK: - Geometry

    private static func pointIndex(from point: Int, die: Int, player: Player) -> Int {
        point + player.direction * die
    }

    // MARK: - Maximise dice usage

    private static func filterMaximalMoves(_ moves: [Move]) -> [Move] {
        guard !moves.isEmpty else { return [] }
        let maxUsed = moves.map { $0.checkerMoves.count }.max()!
        let maxMoves = moves.filter { $0.checkerMoves.count == maxUsed }

        // If only one die can be used, must use the higher value
        if maxUsed == 1 {
            let maxDie = maxMoves.map { $0.checkerMoves[0].die }.max()!
            return maxMoves.filter { $0.checkerMoves[0].die == maxDie }
        }
        return maxMoves
    }

    // MARK: - Dice combinations

    private static func uniqueCombinations(of dice: [Int]) -> [[Int]] {
        // For a standard roll of 2 dice (or 4 for doubles), permutations matter for
        // move ordering but not legality — return the sorted unique set.
        guard !dice.isEmpty else { return [[]] }
        return [dice.sorted()]
    }
}
