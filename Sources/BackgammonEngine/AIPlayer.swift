/// Selects the best legal move for the current player using a trained NeuralNetwork.
public enum AIPlayer {

    /// Returns the move that maximises P(currentPlayer wins) according to the network.
    public static func bestMove(for state: GameState, network: NeuralNetwork) -> Move {
        let moves = uniqueByResult(MoveGenerator.legalMoves(for: state), from: state)
        let player = state.currentPlayer
        return moves.max { a, b in
            score(move: a, state: state, network: network, player: player)
            < score(move: b, state: state, network: network, player: player)
        } ?? Move([])
    }

    // MARK: - Private

    private static func score(
        move: Move, state: GameState, network: NeuralNetwork, player: Player
    ) -> Double {
        let result = GameEngine.applyUnchecked(move, to: state)
        if let winner = result.winner { return winner == player ? 1.0 : 0.0 }
        return network.evaluate(result, for: player)
    }

    /// Keeps one representative move per unique resulting board state.
    private static func uniqueByResult(_ moves: [Move], from state: GameState) -> [Move] {
        var seen = [GameState: Move]()
        for move in moves {
            let result = GameEngine.applyUnchecked(move, to: state)
            if seen[result] == nil { seen[result] = move }
        }
        return seen.isEmpty ? [Move([])] : Array(seen.values)
    }
}
