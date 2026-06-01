import Foundation

/// Feedforward network: 198 → sigmoid(40) → sigmoid(1).
/// Output is P(White wins) from any board position.
///
/// Weight layout (row-major):
///   w1[i * hiddenSize + j]  — input i to hidden j
///   w2[j]                   — hidden j to output
public final class NeuralNetwork: @unchecked Sendable {
    public static let inputSize  = 198
    public static let hiddenSize =  40

    public var w1: [Double]   // inputSize × hiddenSize
    public var b1: [Double]   // hiddenSize
    public var w2: [Double]   // hiddenSize
    public var b2: [Double]   // 1

    public init() {
        w1 = Self.rand(count: Self.inputSize * Self.hiddenSize)
        b1 = [Double](repeating: 0.0, count: Self.hiddenSize)
        w2 = Self.rand(count: Self.hiddenSize)
        b2 = [0.0]
    }

    public init(w1: [Double], b1: [Double], w2: [Double], b2: [Double]) {
        self.w1 = w1; self.b1 = b1; self.w2 = w2; self.b2 = b2
    }

    // MARK: - Inference

    /// Returns P(White wins) ∈ (0,1).
    public func evaluate(_ state: GameState) -> Double {
        forward(BoardEncoder.encode(state)).output
    }

    /// Returns P(player wins) ∈ (0,1).
    public func evaluate(_ state: GameState, for player: Player) -> Double {
        let v = evaluate(state)
        return player == .white ? v : 1.0 - v
    }

    // MARK: - Forward pass (cache-friendly row-major accumulation)

    public func forward(_ input: [Double]) -> (hidden: [Double], output: Double) {
        let H = Self.hiddenSize
        var hidden = b1                           // start with biases
        for i in 0..<Self.inputSize {
            let xi = input[i]
            guard xi != 0 else { continue }       // ~60% of features are 0 at start
            let base = i * H
            for j in 0..<H { hidden[j] += xi * w1[base + j] }
        }
        for j in 0..<H { hidden[j] = sigmoid(hidden[j]) }

        var out = b2[0]
        for j in 0..<H { out += hidden[j] * w2[j] }
        return (hidden, sigmoid(out))
    }

    // MARK: - Gradients + forward in one pass (avoids double forward in TD update)

    /// Computes ∂output/∂weights given pre-computed forward activations.
    /// Call `forward` once, pass results here to avoid a second forward pass.
    public func gradients(input: [Double], hidden: [Double], output: Double) -> NetworkGradients {
        let H   = Self.hiddenSize
        let dOut = sigmoidDeriv(output)

        var gW2 = [Double](repeating: 0.0, count: H)
        let gB2 = [dOut]
        for j in 0..<H { gW2[j] = hidden[j] * dOut }

        var dH  = [Double](repeating: 0.0, count: H)
        var gB1 = [Double](repeating: 0.0, count: H)
        for j in 0..<H {
            let d = sigmoidDeriv(hidden[j]) * w2[j] * dOut
            dH[j]  = d
            gB1[j] = d
        }

        var gW1 = [Double](repeating: 0.0, count: Self.inputSize * H)
        for i in 0..<Self.inputSize {
            let xi   = input[i]
            let base = i * H
            for j in 0..<H { gW1[base + j] = xi * dH[j] }
        }
        return NetworkGradients(w1: gW1, b1: gB1, w2: gW2, b2: gB2)
    }

    // MARK: - Private

    private func sigmoid(_ x: Double) -> Double { 1.0 / (1.0 + exp(-x)) }
    private func sigmoidDeriv(_ y: Double) -> Double { y * (1.0 - y) }

    private static func rand(count: Int) -> [Double] {
        (0..<count).map { _ in Double.random(in: -0.1...0.1) }
    }
}

// MARK: - Gradient / eligibility-trace arrays (same shape as network weights)

public struct NetworkGradients {
    public var w1: [Double]
    public var b1: [Double]
    public var w2: [Double]
    public var b2: [Double]

    public static func zero() -> NetworkGradients {
        NetworkGradients(
            w1: [Double](repeating: 0.0, count: NeuralNetwork.inputSize * NeuralNetwork.hiddenSize),
            b1: [Double](repeating: 0.0, count: NeuralNetwork.hiddenSize),
            w2: [Double](repeating: 0.0, count: NeuralNetwork.hiddenSize),
            b2: [0.0]
        )
    }
}
