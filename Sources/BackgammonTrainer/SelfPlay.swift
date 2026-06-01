import BackgammonEngine

private let maxMoves = 500

/// Plays one complete self-play game, updating the network via TD(λ).
/// Returns the winner (or .white as a fallback if the game hit maxMoves).
@discardableResult
func playEpisode(network: NeuralNetwork, epsilon: Double) -> Player {
    var state  = GameState()
    var traces = NetworkGradients.zero()

    for _ in 0..<maxMoves {
        if state.isGameOver { break }

        let dice = GameEngine.roll()
        state = GameEngine.applyRoll(dice, to: state)

        let features = BoardEncoder.encode(state)
        let (hidden, vT) = network.forward(features)

        let moves = uniqueByResult(MoveGenerator.legalMoves(for: state), from: state)

        // ε-greedy selection; bestMove returns (chosen move, next state, P(player wins))
        let (next, nextValue): (GameState, Double)
        if Double.random(in: 0..<1) < epsilon {
            let m = moves.randomElement()!
            let s = GameEngine.applyUnchecked(m, to: state)
            let v = s.isGameOver
                ? (s.winner == .white ? 1.0 : 0.0)
                : network.evaluate(s)
            (next, nextValue) = (s, v)
        } else {
            let (_, s, v) = bestMove(from: moves, state: state,
                                     network: network, player: state.currentPlayer)
            (next, nextValue) = (s, v)
        }

        tdUpdate(network: network, traces: &traces,
                 features: features, hidden: hidden, vT: vT, nextValue: nextValue)

        if next.isGameOver { return next.winner! }
        state = next
    }

    // Timeout — do a final update and return current player as proxy
    let features = BoardEncoder.encode(state)
    let (hidden, vT) = network.forward(features)
    tdUpdate(network: network, traces: &traces,
             features: features, hidden: hidden, vT: vT, nextValue: 0.5)
    return state.currentPlayer
}

// MARK: - Helpers

/// Returns (best move, resulting state, network value from player's perspective).
private func bestMove(
    from moves: [Move],
    state: GameState,
    network: NeuralNetwork,
    player: Player
) -> (Move, GameState, Double) {
    var bestM: Move = moves[0]
    var bestS: GameState = GameEngine.applyUnchecked(moves[0], to: state)
    var bestV: Double = bestS.isGameOver
        ? (bestS.winner == player ? 1.0 : 0.0)
        : network.evaluate(bestS, for: player)

    for i in 1..<moves.count {
        let s = GameEngine.applyUnchecked(moves[i], to: state)
        let v: Double = s.isGameOver
            ? (s.winner == player ? 1.0 : 0.0)
            : network.evaluate(s, for: player)
        if v > bestV { bestM = moves[i]; bestS = s; bestV = v }
    }
    // Return raw network output (not player-relative) as the TD target
    let rawV = player == .white ? bestV : 1.0 - bestV
    return (bestM, bestS, rawV)
}

/// Keeps one representative move per unique resulting board state.
/// Mirrors the Clojure `unique-by-result` to avoid evaluating duplicate positions.
private func uniqueByResult(_ moves: [Move], from state: GameState) -> [Move] {
    var seen = [GameState: Move]()
    for move in moves {
        let result = GameEngine.applyUnchecked(move, to: state)
        if seen[result] == nil { seen[result] = move }
    }
    return seen.isEmpty ? [Move([])] : Array(seen.values)
}
