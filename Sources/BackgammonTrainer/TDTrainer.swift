import BackgammonEngine

private let alpha  = 0.001   // learning rate
private let lambda = 0.7     // trace decay

/// One TD(λ) weight update step.
///
/// Accepts pre-computed forward activations to avoid a redundant forward pass
/// (the caller already ran forward() when computing nextValue for move selection).
///
/// - hidden:    hidden-layer activations at time t
/// - vT:        output value at time t
/// - nextValue: V(s_{t+1}) from network, or terminal reward (0 or 1)
func tdUpdate(
    network:    NeuralNetwork,
    traces:     inout NetworkGradients,
    features:   [Double],
    hidden:     [Double],
    vT:         Double,
    nextValue:  Double
) {
    let tdError = nextValue - vT
    let grads   = network.gradients(input: features, hidden: hidden, output: vT)

    // traces = λ * traces + grads
    for i in 0..<traces.w1.count { traces.w1[i] = lambda * traces.w1[i] + grads.w1[i] }
    for i in 0..<traces.b1.count { traces.b1[i] = lambda * traces.b1[i] + grads.b1[i] }
    for i in 0..<traces.w2.count { traces.w2[i] = lambda * traces.w2[i] + grads.w2[i] }
    traces.b2[0] = lambda * traces.b2[0] + grads.b2[0]

    // weights += α * δ * traces
    let scale = alpha * tdError
    for i in 0..<network.w1.count { network.w1[i] += scale * traces.w1[i] }
    for i in 0..<network.b1.count { network.b1[i] += scale * traces.b1[i] }
    for i in 0..<network.w2.count { network.w2[i] += scale * traces.w2[i] }
    network.b2[0] += scale * traces.b2[0]
}
