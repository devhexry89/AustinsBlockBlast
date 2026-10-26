import Foundation

@main
struct EngineSmoke {
    static func main() {
        let first = BlockGame(mode: .daily, seed: DailyChallenge.seed(for: "2026-10-25"), dayKey: "2026-10-25")
        let second = BlockGame(mode: .daily, seed: DailyChallenge.seed(for: "2026-10-25"), dayKey: "2026-10-25")
        assert(first.board == second.board && first.tray == second.tray)
        assert(first.hasLegalMove && first.board.count == 64)
        assert(first.tray.count == 3)
        assert(DailyChallenge.seed(for: "2026-10-25") != DailyChallenge.seed(for: "2026-10-24"))

        var occupied: [Int?] = Array(repeating: nil, count: 64)
        for col in 0..<7 { occupied[col] = 2 }
        let dot = ShapeCatalog.get("dot")!
        assert(BoardRules.fits(board: occupied, side: 8, shape: dot, x: 7, y: 0))
        let lines = BoardRules.apply(board: &occupied, side: 8, shape: dot, x: 7, y: 0)
        assert(lines == 1 && occupied[0] == nil && occupied[7] == nil)
        assert(!BoardRules.fits(board: occupied, side: 8, shape: dot, x: -1, y: 0))

        for mode in PlayMode.allCases {
            for seed in 1...12 {
                var game = BlockGame(mode: mode, seed: UInt64(seed), dayKey: mode == .daily ? "2026-10-25" : nil)
                assert(game.board.count == mode.side * mode.side)
                assert(game.hasLegalMove)
                var iterations = 0
                while !game.isOver && iterations < 100 {
                    var chosen: (Int, GridPoint)?
                    for slot in 0..<3 {
                        guard let shape = game.shape(in: slot) else { continue }
                        let anchors = BoardRules.anchors(board: game.board, side: game.side, shape: shape)
                        if let position = anchors.first {
                            chosen = (slot, position)
                            break
                        }
                    }
                    guard let (slot, position) = chosen else {
                        fatalError("Game declared playable despite no legal moves")
                    }
                    let previousScore = game.score
                    let previousMoves = game.moves
                    let placement = game.place(slot: slot, x: position.x, y: position.y)
                    assert(placement != nil)
                    assert(game.score > previousScore && game.moves == previousMoves + 1)
                    assert(game.board.count == game.side * game.side && game.tray.count == 3)
                    iterations += 1
                }
            }
        }
        print("PASS: daily reproducibility, clear rules, all game modes, move legality, score & state checks")
    }
}
