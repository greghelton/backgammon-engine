import Foundation
import BackgammonEngine

private struct ModelData: Codable {
    let w1: [Double]
    let b1: [Double]
    let w2: [Double]
    let b2: [Double]
}

enum ModelStore {
    static func save(_ network: NeuralNetwork, to url: URL) throws {
        let data = ModelData(w1: network.w1, b1: network.b1, w2: network.w2, b2: network.b2)
        try JSONEncoder().encode(data).write(to: url)
    }

    static func load(from url: URL) throws -> NeuralNetwork {
        let m = try JSONDecoder().decode(ModelData.self, from: Data(contentsOf: url))
        return NeuralNetwork(w1: m.w1, b1: m.b1, w2: m.w2, b2: m.b2)
    }
}
