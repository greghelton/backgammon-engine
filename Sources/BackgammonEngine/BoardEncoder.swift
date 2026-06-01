/// Encodes a GameState into Tesauro's 198-feature vector.
///
/// Layout (per point, 24 points × 8 features = 192):
///   [0] 1 if white has ≥1 checker
///   [1] 1 if white has ≥2 checkers
///   [2] 1 if white has ≥3 checkers
///   [3] (n-3)/2 if white has ≥4 checkers, else 0
///   [4-7] same for black
/// [192] white bar / 2
/// [193] black bar / 2
/// [194] white borne off / 15
/// [195] black borne off / 15
/// [196] 1 if white to move
/// [197] 1 if black to move
public enum BoardEncoder {
    public static let inputSize = 198

    public static func encode(_ state: GameState) -> [Double] {
        var f = [Double](repeating: 0.0, count: inputSize)
        var offset = 0
        for point in 0..<24 {
            let raw = state.points[point]
            encode(count: max(0,  raw), into: &f, at: offset)
            encode(count: max(0, -raw), into: &f, at: offset + 4)
            offset += 8
        }
        f[192] = Double(state.whiteBar)      / 2.0
        f[193] = Double(state.blackBar)      / 2.0
        f[194] = Double(state.whiteBorneOff) / 15.0
        f[195] = Double(state.blackBorneOff) / 15.0
        f[196] = state.currentPlayer == .white ? 1.0 : 0.0
        f[197] = state.currentPlayer == .black ? 1.0 : 0.0
        return f
    }

    private static func encode(count n: Int, into f: inout [Double], at offset: Int) {
        f[offset]     = n >= 1 ? 1.0 : 0.0
        f[offset + 1] = n >= 2 ? 1.0 : 0.0
        f[offset + 2] = n >= 3 ? 1.0 : 0.0
        f[offset + 3] = n >= 4 ? Double(n - 3) / 2.0 : 0.0
    }
}
