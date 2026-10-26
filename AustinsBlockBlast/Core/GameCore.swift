import Foundation

// Game rules are independent of SwiftUI, networking, purchases, and high scores.
// Piece selection only depends on the board and the saved pseudorandom seed.

struct GridPoint: Hashable, Codable {
    let x: Int
    let y: Int
}

struct BlockShape: Identifiable {
    let id: String
    let cells: [GridPoint]
    let color: Int
    var width: Int { (cells.map(\.x).max() ?? 0) + 1 }
    var height: Int { (cells.map(\.y).max() ?? 0) + 1 }
}

enum ShapeCatalog {
    private static func shape(_ id: String, _ rows: [String], _ color: Int) -> BlockShape {
        var cells: [GridPoint] = []
        for (y, row) in rows.enumerated() {
            for (x, symbol) in row.enumerated() where symbol == "#" {
                cells.append(GridPoint(x: x, y: y))
            }
        }
        return BlockShape(id: id, cells: cells, color: color)
    }

    static let all: [BlockShape] = [
        shape("dot", ["#"], 0),
        shape("bar2h", ["##"], 1), shape("bar2v", ["#", "#"], 1),
        shape("bar3h", ["###"], 2), shape("bar3v", ["#", "#", "#"], 2),
        shape("bar4h", ["####"], 3), shape("bar4v", ["#", "#", "#", "#"], 3),
        shape("bar5h", ["#####"], 5), shape("bar5v", ["#", "#", "#", "#", "#"], 5),
        shape("square2", ["##", "##"], 4),
        shape("square3", ["###", "###", "###"], 4),
        shape("rect2x3", ["###", "###"], 3),
        shape("rect3x2", ["##", "##", "##"], 3),
        shape("l3a", ["#.", "##"], 0), shape("l3b", [".#", "##"], 0),
        shape("l3c", ["##", "#."], 0), shape("l3d", ["##", ".#"], 0),
        shape("l4a", ["#.", "#.", "##"], 1), shape("l4b", [".#", ".#", "##"], 1),
        shape("l4c", ["##", ".#", ".#"], 1), shape("l4d", ["##", "#.", "#."], 1),
        shape("t4a", ["###", ".#."], 5), shape("t4b", [".#.", "###"], 5),
        shape("t4c", ["#.", "##", "#."], 5), shape("t4d", [".#", "##", ".#"], 5),
        shape("zig4h", ["##.", ".##"], 2), shape("zag4h", [".##", "##."], 2),
        shape("zig4v", ["#.", "##", ".#"], 2), shape("zag4v", [".#", "##", "#."], 2),
        shape("plus5", [".#.", "###", ".#."], 5),
        shape("u5", ["#.#", "###"], 4),
        shape("corner5", ["#..", "#..", "###"], 0)
    ]

    static let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
    static func get(_ id: String) -> BlockShape? { byID[id] }
}

struct SeededRNG: Codable {
    private(set) var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func index(_ count: Int) -> Int {
        precondition(count > 0)
        return Int(next() % UInt64(count))
    }

    mutating func shuffle<T>(_ values: inout [T]) {
        guard values.count > 1 else { return }
        for i in stride(from: values.count - 1, through: 1, by: -1) {
            values.swapAt(i, index(i + 1))
        }
    }
}

enum PlayMode: String, Codable, CaseIterable, Identifiable {
    case arcade, daily, lineRush, scoreSprint, pocket

    var id: String { rawValue }
    var title: String {
        switch self {
        case .arcade: return "Classic"
        case .daily: return "Daily Challenge"
        case .lineRush: return "Line Rush"
        case .scoreSprint: return "Score Sprint"
        case .pocket: return "Pocket Puzzle"
        }
    }
    var subtitle: String {
        switch self {
        case .arcade: return "Your board. Your strategy. No tricks."
        case .daily: return "A new seeded puzzle every day"
        case .lineRush: return "Clear 5 lines in 28 moves"
        case .scoreSprint: return "Earn 700 points in 26 moves"
        case .pocket: return "A tiny board with a big challenge"
        }
    }
    var symbol: String {
        switch self {
        case .arcade: return "square.grid.3x3.fill"
        case .daily: return "calendar.badge.clock"
        case .lineRush: return "line.3.horizontal.decrease"
        case .scoreSprint: return "bolt.fill"
        case .pocket: return "square.grid.2x2.fill"
        }
    }
    var side: Int { self == .pocket ? 6 : 8 }
    var moveLimit: Int? {
        switch self {
        case .arcade: return nil
        case .daily: return 27
        case .lineRush: return 28
        case .scoreSprint: return 26
        case .pocket: return 22
        }
    }
    var targetLines: Int? {
        switch self {
        case .daily: return 4
        case .lineRush: return 5
        case .pocket: return 3
        default: return nil
        }
    }
    var targetScore: Int? { self == .scoreSprint ? 700 : nil }
    var starterBlocks: Int {
        switch self {
        case .daily: return 11
        case .pocket: return 7
        default: return 0
        }
    }
}

enum DailyChallenge {
    static func dayKey(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // Stable across launches and devices (Swift's Hasher is intentionally not stable).
    static func seed(for dayKey: String) -> UInt64 {
        var value: UInt64 = 14695981039346656037
        for byte in ("AustinsBlockBlast:v1:" + dayKey).utf8 {
            value = (value ^ UInt64(byte)) &* 1099511628211
        }
        return value
    }
}

struct PlacementResult {
    let blocks: Int
    let lines: Int
    let points: Int
    let newTray: Bool
    let gameFinished: Bool
    let won: Bool
}

enum BoardRules {
    static func fits(board: [Int?], side: Int, shape: BlockShape, x: Int, y: Int) -> Bool {
        guard board.count == side * side else { return false }
        for cell in shape.cells {
            let col = x + cell.x
            let row = y + cell.y
            if col < 0 || row < 0 || col >= side || row >= side || board[row * side + col] != nil {
                return false
            }
        }
        return true
    }

    static func anchors(board: [Int?], side: Int, shape: BlockShape) -> [GridPoint] {
        guard shape.width <= side, shape.height <= side else { return [] }
        var result: [GridPoint] = []
        for y in 0...(side - shape.height) {
            for x in 0...(side - shape.width) where fits(board: board, side: side, shape: shape, x: x, y: y) {
                result.append(GridPoint(x: x, y: y))
            }
        }
        return result
    }

    @discardableResult
    static func apply(board: inout [Int?], side: Int, shape: BlockShape, x: Int, y: Int) -> Int {
        for point in shape.cells {
            board[(y + point.y) * side + x + point.x] = shape.color
        }
        var cleared = Set<Int>()
        var lineCount = 0
        for row in 0..<side where (0..<side).allSatisfy({ board[row * side + $0] != nil }) {
            lineCount += 1
            for col in 0..<side { cleared.insert(row * side + col) }
        }
        for col in 0..<side where (0..<side).allSatisfy({ board[$0 * side + col] != nil }) {
            lineCount += 1
            for row in 0..<side { cleared.insert(row * side + col) }
        }
        for index in cleared { board[index] = nil }
        return lineCount
    }
}

struct BlockGame: Codable {
    let mode: PlayMode
    let dayKey: String?
    let seed: UInt64
    var rng: SeededRNG
    var board: [Int?]
    var tray: [String?] = [nil, nil, nil]
    var score = 0
    var best = 0
    var chain = 0
    var moves = 0
    var linesCleared = 0
    var isOver = false
    var didWin = false

    var side: Int { mode.side }
    var remainingMoves: Int? { mode.moveLimit.map { max(0, $0 - moves) } }
    var displaySeed: String { String(seed, radix: 16, uppercase: true).leftPadded(to: 16, with: "0") }
    var objectiveProgress: Double {
        if let target = mode.targetLines { return min(1, Double(linesCleared) / Double(target)) }
        if let target = mode.targetScore { return min(1, Double(score) / Double(target)) }
        return 0
    }
    var objectiveDescription: String {
        if let target = mode.targetLines { return "\(linesCleared) / \(target) lines" }
        if let target = mode.targetScore { return "\(score) / \(target) points" }
        return "Play as long as you can"
    }

    init(mode: PlayMode, seed: UInt64, dayKey: String? = nil, previousBest: Int = 0) {
        self.mode = mode
        self.dayKey = dayKey
        self.seed = seed
        self.rng = SeededRNG(seed: seed)
        self.best = previousBest
        self.board = Array(repeating: nil, count: mode.side * mode.side)
        if mode.starterBlocks > 0 {
            for _ in 0..<mode.starterBlocks {
                let candidates = board.indices.filter { board[$0] == nil }
                guard !candidates.isEmpty else { break }
                let index = candidates[rng.index(candidates.count)]
                board[index] = rng.index(6)
            }
            // Starter squares may never begin with a completed line.
            for row in 0..<mode.side {
                if (0..<mode.side).allSatisfy({ board[row * mode.side + $0] != nil }) {
                    board[row * mode.side + rng.index(mode.side)] = nil
                }
            }
        }
        generateFairTray()
    }

    func shape(in slot: Int) -> BlockShape? {
        guard tray.indices.contains(slot), let id = tray[slot] else { return nil }
        return ShapeCatalog.get(id)
    }

    func canPlace(slot: Int, x: Int, y: Int) -> Bool {
        guard !isOver, let shape = shape(in: slot) else { return false }
        return BoardRules.fits(board: board, side: side, shape: shape, x: x, y: y)
    }

    var hasLegalMove: Bool {
        tray.compactMap { $0 }.contains { id in
            guard let shape = ShapeCatalog.get(id) else { return false }
            return !BoardRules.anchors(board: board, side: side, shape: shape).isEmpty
        }
    }

    mutating func place(slot: Int, x: Int, y: Int) -> PlacementResult? {
        guard canPlace(slot: slot, x: x, y: y), let shape = shape(in: slot) else { return nil }
        let lines = BoardRules.apply(board: &board, side: side, shape: shape, x: x, y: y)
        chain = lines > 0 ? chain + 1 : 0
        let points = shape.cells.count * 10 + lines * 100 + (lines > 0 ? max(0, chain - 1) * 30 : 0)
        score += points
        best = max(best, score)
        moves += 1
        linesCleared += lines
        tray[slot] = nil

        if let target = mode.targetLines, linesCleared >= target { didWin = true }
        if let target = mode.targetScore, score >= target { didWin = true }
        let reachedLimit = mode.moveLimit.map { moves >= $0 } ?? false
        let needsTray = tray.allSatisfy { $0 == nil }
        if !didWin && !reachedLimit && needsTray { generateFairTray() }
        isOver = didWin || reachedLimit || !hasLegalMove
        return PlacementResult(blocks: shape.cells.count, lines: lines, points: points,
                               newTray: needsTray, gameFinished: isOver, won: didWin)
    }

    private mutating func generateFairTray() {
        // We attempt to deal 3 shapes for which at least ONE possible placement
        // order fits, including line clears, on the board at deal time. The
        // pseudorandom generator is seeded. Score is NEVER part of the selection.
        for _ in 0..<80 {
            var simulated = board
            var chosen: [String] = []
            for _ in 0..<3 {
                let candidates = ShapeCatalog.all.filter {
                    !BoardRules.anchors(board: simulated, side: side, shape: $0).isEmpty
                }
                if candidates.isEmpty { break }
                let shape = candidates[rng.index(candidates.count)]
                let spots = BoardRules.anchors(board: simulated, side: side, shape: shape)
                let position = spots[rng.index(spots.count)]
                BoardRules.apply(board: &simulated, side: side, shape: shape, x: position.x, y: position.y)
                chosen.append(shape.id)
            }
            if chosen.count == 3 {
                rng.shuffle(&chosen)
                tray = chosen.map { Optional($0) }
                return
            }
        }
        // On a crowded board, small pieces are more useful than an impossible
        // trio. Even a single block cannot fit once every cell is occupied.
        tray = board.contains(where: { $0 == nil }) ? ["dot", "dot", "dot"] : [nil, nil, nil]
    }
}

private extension String {
    func leftPadded(to length: Int, with character: Character) -> String {
        String(repeating: String(character), count: max(0, length - count)) + self
    }
}
