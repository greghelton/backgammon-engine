import XCTest
@testable import BackgammonEngine

final class BackgammonEngineTests: XCTestCase {

    func testInitialPositionHasLegalMoves() {
        var state = GameState()
        state = GameEngine.applyRoll([1, 2], to: state)
        let moves = MoveGenerator.legalMoves(for: state)
        XCTAssertFalse(moves.isEmpty)
    }

    func testInitialCheckerCount() {
        let state = GameState()
        let whiteTotal = state.points.filter { $0 > 0 }.reduce(0, +)
        let blackTotal = state.points.filter { $0 < 0 }.reduce(0, -)
        XCTAssertEqual(whiteTotal, 15)
        XCTAssertEqual(blackTotal, 15)
    }

    func testDoublesRollProducesFourDice() {
        var allRolls: [[Int]] = []
        for _ in 0..<200 { allRolls.append(GameEngine.roll()) }
        let doubles = allRolls.filter { $0.count == 4 }
        XCTAssertFalse(doubles.isEmpty)
        XCTAssert(doubles.allSatisfy { $0[0] == $0[1] && $0[1] == $0[2] && $0[2] == $0[3] })
    }

    func testWinnerDetected() {
        var state = GameState()
        state.whiteBorneOff = 15
        XCTAssertEqual(state.winner, .white)
        XCTAssertTrue(state.isGameOver)
    }

    func testBarMoveRequiredBeforeOthers() {
        var state = GameState()
        state.whiteBar = 1
        state = GameEngine.applyRoll([2, 3], to: state)
        let moves = MoveGenerator.legalMoves(for: state)
        // Every legal move must start from the bar
        XCTAssert(moves.allSatisfy { $0.checkerMoves.allSatisfy { $0.isFromBar } })
    }
}
