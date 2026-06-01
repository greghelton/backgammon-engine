import BackgammonEngine
import Foundation

// MARK: - Configuration

let totalEpisodes   = 500_000
let reportEvery     = 500
let savePathDefault = "backgammon.json"

// MARK: - Training loop

print("╔══════════════════════════════════════════════════╗")
print("║  Backgammon TD(λ) Trainer                        ║")
print("║  Network: \(NeuralNetwork.inputSize)→\(NeuralNetwork.hiddenSize)→1  |  λ=0.7  |  α=0.001             ║")
print("╚══════════════════════════════════════════════════╝")
print("Episodes: \(totalEpisodes)  |  report every \(reportEvery)\n")

let network   = NeuralNetwork()
let startTime = Date()
var whiteWins = 0

for episode in 1...totalEpisodes {
    // ε decays from 0.30 → 0.05 over training
    let epsilon = max(0.05, 0.30 - 0.25 * Double(episode) / Double(totalEpisodes))
    let winner  = playEpisode(network: network, epsilon: epsilon)
    if winner == .white { whiteWins += 1 }

    if episode % reportEvery == 0 {
        let winRate = Double(whiteWins) / Double(reportEvery) * 100.0
        let elapsed = Date().timeIntervalSince(startTime)
        let speed   = Double(episode) / elapsed
        print(String(format: "Ep %6d/%d  white win: %5.1f%%  ε=%.3f  %.0f ep/s",
                     episode, totalEpisodes, winRate, epsilon, speed))
        whiteWins = 0
    }
}

let elapsed = Date().timeIntervalSince(startTime)
print(String(format: "\nDone. %.0f episodes in %.1fs (%.0f ep/s)",
             Double(totalEpisodes), elapsed, Double(totalEpisodes) / elapsed))

// MARK: - Save

let savePath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : savePathDefault
let saveURL  = URL(fileURLWithPath: savePath)
do {
    try ModelStore.save(network, to: saveURL)
    print("Model saved → \(saveURL.path)")
} catch {
    print("Save failed: \(error)")
}
