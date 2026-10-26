import SwiftUI
import UIKit

// UIKit owns the touch for its full lifetime, even when the finger leaves the tray.
// This avoids SwiftUI parent/child gesture competition and keeps one coordinate space.
private struct PieceTouchSurface: UIViewRepresentable {
    let onTouch: (TouchPhase, CGPoint) -> Void

    enum TouchPhase { case began, moved, ended, cancelled }

    final class Surface: UIView {
        var callback: (TouchPhase, CGPoint) -> Void = { _, _ in }
        private func point(_ touch: UITouch) -> CGPoint {
            // .global SwiftUI frames and UIWindow touch coordinates agree in this scene.
            touch.location(in: window ?? self)
        }
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            if let touch = touches.first { callback(.began, point(touch)) }
        }
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            if let touch = touches.first { callback(.moved, point(touch)) }
        }
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            if let touch = touches.first { callback(.ended, point(touch)) }
        }
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            if let touch = touches.first { callback(.cancelled, point(touch)) }
        }
    }

    func makeUIView(context: Context) -> Surface {
        let surface = Surface(frame: .zero)
        surface.isMultipleTouchEnabled = false
        surface.backgroundColor = .clear
        surface.isUserInteractionEnabled = true
        surface.callback = onTouch
        return surface
    }
    func updateUIView(_ view: Surface, context: Context) { view.callback = onTouch }
}

private struct BoardRectPreference: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct BoardGrid: View {
    let game: BlockGame
    let hovering: GridPoint?
    let hoveringShape: BlockShape?
    let onCellTap: (GridPoint) -> Void
    let clearedRows: Set<Int>
    let clearedColumns: Set<Int>
    let boardBurst: Bool

    private var legalHover: Bool {
        guard let hovering, let hoveringShape else { return false }
        return BoardRules.fits(board: game.board, side: game.side,
                               shape: hoveringShape, x: hovering.x, y: hovering.y)
    }

    private func isHoverCell(x: Int, y: Int) -> Bool {
        guard let hovering, let hoveringShape else { return false }
        return hoveringShape.cells.contains { hovering.x + $0.x == x && hovering.y + $0.y == y }
    }

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 3
            let cellSize = (geometry.size.width - CGFloat(game.side - 1) * spacing) / CGFloat(game.side)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: game.side), spacing: spacing) {
                ForEach(game.board.indices, id: \.self) { index in
                    let col = index % game.side
                    let row = index / game.side
                    let fill = game.board[index]
                    let hoveringHere = isHoverCell(x: col, y: row)
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(GameTheme.recessed)
                        if let fill {
                            GlowTile(color: GameTheme.block(fill))
                        } else if hoveringHere {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(legalHover ? GameTheme.green.opacity(0.65) : GameTheme.coral.opacity(0.65))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 5)
                                        .strokeBorder(legalHover ? GameTheme.green : GameTheme.coral, lineWidth: 1.5)
                                }
                        }
                    }
                    .overlay {
                        if clearedRows.contains(row) || clearedColumns.contains(col) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(GameTheme.cyan.opacity(0.78))
                                .shadow(color: GameTheme.cyan, radius: 12)
                                .transition(.opacity)
                        }
                    }
                    .frame(width: cellSize, height: cellSize)
                    .contentShape(Rectangle())
                    .onTapGesture { onCellTap(GridPoint(x: col, y: row)) }
                }
            }
        }
        .accessibilityLabel("\(game.side) by \(game.side) block puzzle board")
    }
}

// Large, noninteractive copy that follows the finger while a piece is being dragged.
// A raised preview leaves the destination cells visible above the user's thumb.
struct LiftedPiecePreview: View {
    let shape: BlockShape
    let cellSize: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(shape.cells, id: \.self) { cell in
                GlowTile(color: GameTheme.block(shape.color))
                    .frame(width: cellSize - 3, height: cellSize - 3)
                    .offset(x: CGFloat(cell.x) * cellSize, y: CGFloat(cell.y) * cellSize)
            }
        }
        .frame(width: CGFloat(shape.width) * cellSize,
               height: CGFloat(shape.height) * cellSize,
               alignment: .topLeading)
        .shadow(color: GameTheme.cyan.opacity(0.28), radius: 15, y: 7)
        .allowsHitTesting(false)
    }
}

struct PiecePreview: View {
    let shape: BlockShape
    let availableWidth: CGFloat

    var body: some View {
        let size = min(18.0, min((availableWidth - 12) / CGFloat(shape.width), 65 / CGFloat(shape.height)))
        let gap = 2.0
        ZStack(alignment: .topLeading) {
            ForEach(shape.cells, id: \.self) { cell in
                GlowTile(color: GameTheme.block(shape.color))
                    .frame(width: size - gap, height: size - gap)
                    .offset(x: CGFloat(cell.x) * size, y: CGFloat(cell.y) * size)
            }
        }
        .frame(width: CGFloat(shape.width) * size, height: CGFloat(shape.height) * size,
               alignment: .topLeading)
        .frame(width: availableWidth, height: 68, alignment: .center)
    }
}

struct GameScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store: GameStore
    @State private var selectedSlot: Int?
    @State private var dragSlot: Int?
    @State private var hover: GridPoint?
    @State private var boardRect = CGRect.zero
    @State private var dragPosition: CGPoint?
    @State private var showRestart = false
    @State private var clearingRows: Set<Int> = []
    @State private var clearingColumns: Set<Int> = []
    @State private var boardBurst = false
    @State private var effectGeneration = 0

    // All touch points and measured element frames use the global coordinate system.
    // One parent-level gesture owns the entire drag lifecycle, even beyond the tray.
    private let fingerLift: CGFloat = 74
    private let cellGap: CGFloat = 3

    init(mode: PlayMode, dayKey: String? = nil) {
        _store = StateObject(wrappedValue: GameStore(mode: mode, requestedDay: dayKey))
    }

    private var game: BlockGame { store.game }
    private var activeShape: BlockShape? {
        guard let dragSlot else { return nil }
        return game.shape(in: dragSlot)
    }

    var body: some View {
        GeometryReader { geometry in
            let boardWidth = min(geometry.size.width - 48, geometry.size.height * 0.445, 460)
            ZStack {
                VStack(spacing: 11) {
                    header
                    statsBar
                    if game.mode != .arcade { goalPanel }
                    Spacer(minLength: 0)
                    BoardGrid(game: game, hovering: hover, hoveringShape: activeShape,
                              onCellTap: tappedBoard, clearedRows: clearingRows,
                              clearedColumns: clearingColumns, boardBurst: boardBurst)
                        .frame(width: boardWidth, height: boardWidth)
                        .background(GeometryReader { view in
                            Color.clear.preference(key: BoardRectPreference.self,
                                                   value: view.frame(in: .global))
                        })
                        .padding(7)
                        .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 17))
                        .overlay {
                            RoundedRectangle(cornerRadius: 17)
                                .strokeBorder(GameTheme.outline.opacity(0.7), lineWidth: 1.2)
                        }
                        .onPreferenceChange(BoardRectPreference.self) { boardRect = $0 }
                        .overlay {
                            if boardBurst {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 22)
                                        .strokeBorder(GameTheme.yellow, lineWidth: 6)
                                        .shadow(color: GameTheme.yellow, radius: 25)
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 74, weight: .bold))
                                        .foregroundStyle(GameTheme.yellow)
                                        .shadow(color: GameTheme.cyan, radius: 20)
                                }
                                .allowsHitTesting(false)
                                .transition(.opacity.combined(with: .scale(scale: 0.7)))
                            }
                        }
                    Spacer(minLength: 0)
                    trayView(availableWidth: geometry.size.width - 32)
                    toolbar
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(width: geometry.size.width, height: geometry.size.height)

                // The moving piece is drawn above the entire game view so it cannot
                // get clipped by the three slots or hidden behind the board.
                if let dragPosition, let shape = activeShape, !game.isOver {
                    let gridCell = max(14, (boardWidth - CGFloat(game.side - 1) * cellGap) / CGFloat(game.side))
                    LiftedPiecePreview(shape: shape, cellSize: gridCell + cellGap)
                        .opacity(0.93)
                        .position(
                            hover.map { snapCenter(for: $0, shape: shape) }
                            ?? CGPoint(x: dragPosition.x, y: dragPosition.y - fingerLift)
                        )
                        .offset(x: -geometry.frame(in: .global).minX,
                                y: -geometry.frame(in: .global).minY)
                        .allowsHitTesting(false)
                        .zIndex(5)
                }
                if game.isOver { endOverlay.zIndex(10) }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background { GameBackdrop() }
            .contentShape(Rectangle())
            .clipped()
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .confirmationDialog("Start a new game?", isPresented: $showRestart) {
            Button("Restart game", role: .destructive) { restart() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(game.mode == .daily ? "Today's puzzle will restart with the same seed." : "Your current board will be replaced.")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 43, height: 43)
                    .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 14))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(game.mode.title)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(game.mode == .daily ? (game.dayKey ?? "") : "AUSTINS BLOCKBLAST")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(GameTheme.muted)
            }
            Spacer()
            Image(systemName: game.mode.symbol)
                .font(.system(size: 22))
                .foregroundStyle(GameTheme.cyan)
                .frame(width: 43, height: 43)
                .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var statsBar: some View {
        HStack(spacing: 6) {
            MiniStat(title: "Score", value: game.score.formatted(), accent: GameTheme.cyan)
            MiniStat(title: "Lines", value: "\(game.linesCleared)", accent: GameTheme.green)
            MiniStat(title: game.mode.moveLimit == nil ? "Best" : "Moves left",
                     value: game.remainingMoves.map(String.init) ?? game.best.formatted(), accent: GameTheme.yellow)
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 13)
        .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 19))
    }

    private var goalPanel: some View {
        VStack(spacing: 8) {
            HStack {
                Text("GOAL")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(GameTheme.muted)
                Spacer()
                Text(game.objectiveDescription)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            ProgressView(value: game.objectiveProgress)
                .tint(GameTheme.green)
                .scaleEffect(x: 1, y: 1.8, anchor: .center)
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 12)
        .background(GameTheme.panel.opacity(0.75), in: RoundedRectangle(cornerRadius: 17))
    }

    private func trayView(availableWidth: CGFloat) -> some View {
        let slotWidth = (availableWidth - 20) / 3
        return HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { slot in
                let shape = game.shape(in: slot)
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(selectedSlot == slot ? GameTheme.outline.opacity(0.9) : GameTheme.panel)
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(selectedSlot == slot ? GameTheme.cyan : GameTheme.outline.opacity(0.45),
                                      lineWidth: selectedSlot == slot ? 2 : 1)
                    if let shape {
                        PiecePreview(shape: shape, availableWidth: slotWidth - 10)
                            .opacity(dragSlot == slot ? 0.22 : 1)
                    } else {
                        Image(systemName: "checkmark")
                            .foregroundStyle(GameTheme.green.opacity(0.6))
                            .font(.title3.bold())
                    }
                }
                .frame(width: slotWidth, height: 87)
                .contentShape(RoundedRectangle(cornerRadius: 18))
                .overlay {
                    if shape != nil {
                        PieceTouchSurface { phase, point in
                            handlePieceTouch(slot: slot, phase: phase, location: point)
                        }
                    }
                }
                .accessibilityLabel(shape.map { "Piece \(slot + 1), \($0.cells.count) blocks" } ?? "Empty piece slot")
            }
        }
    }

    private var toolbar: some View {
        Button { showRestart = true } label: {
            Label("RESTART", systemImage: "arrow.clockwise")
                .frame(maxWidth: .infinity)
        }
        .font(.system(size: 12, weight: .heavy, design: .rounded))
        .foregroundStyle(.white)
        .padding(.vertical, 12)
        .background(GameTheme.recessed, in: RoundedRectangle(cornerRadius: 14))
        .buttonStyle(.plain)
    }

    private var endOverlay: some View {
        ZStack {
            GameTheme.background.opacity(0.84).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: game.didWin ? "star.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 57))
                    .foregroundStyle(game.didWin ? GameTheme.yellow : GameTheme.cyan)
                Text(game.didWin ? "CHALLENGE COMPLETE!" : "NO MORE MOVES")
                    .font(.system(size: 23, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(game.didWin ? "Nice moves. You earned your win!" : "A fresh board is one tap away.")
                    .font(.system(size: 13))
                    .foregroundStyle(GameTheme.muted)
                HStack(spacing: 18) {
                    MiniStat(title: "Final score", value: game.score.formatted(), accent: GameTheme.cyan)
                    MiniStat(title: "Lines", value: "\(game.linesCleared)", accent: GameTheme.yellow)
                }
                .padding(13)
                .background(GameTheme.recessed, in: RoundedRectangle(cornerRadius: 15))
                Button { restart() } label: {
                    Text(game.mode == .daily ? "RETRY DAILY PUZZLE" : "PLAY AGAIN")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .foregroundStyle(GameTheme.background)
                        .background(GameTheme.cyan, in: RoundedRectangle(cornerRadius: 15))
                }
                Button { dismiss() } label: {
                    Text("BACK TO MENU")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(GameTheme.muted)
                        .padding(9)
                }
            }
            .padding(25)
            .frame(maxWidth: 345)
            .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 27))
            .overlay {
                RoundedRectangle(cornerRadius: 27)
                    .strokeBorder(GameTheme.outline, lineWidth: 1)
            }
            .padding(.horizontal, 25)
        }
    }

    // Both the visual ghost and final placement use this exact projection.
    // Finger touches and boardRect are both measured in .global coordinates.
    private func proposedOrigin(at finger: CGPoint, shape: BlockShape) -> GridPoint? {
        guard boardRect.width > 1, game.side > 0 else { return nil }
        let pitch = (boardRect.width + cellGap) / CGFloat(game.side)
        let blockCenter = CGPoint(x: finger.x, y: finger.y - fingerLift)
        let x = Int(round((blockCenter.x - boardRect.minX) / pitch - CGFloat(shape.width) / 2))
        let y = Int(round((blockCenter.y - boardRect.minY) / pitch - CGFloat(shape.height) / 2))
        guard x >= 0, y >= 0, x + shape.width <= game.side,
              y + shape.height <= game.side else { return nil }
        return GridPoint(x: x, y: y)
    }

    private func snapCenter(for anchor: GridPoint, shape: BlockShape) -> CGPoint {
        let pitch = (boardRect.width + cellGap) / CGFloat(game.side)
        return CGPoint(
            x: boardRect.minX + (CGFloat(anchor.x) + CGFloat(shape.width) / 2) * pitch - cellGap / 2,
            y: boardRect.minY + (CGFloat(anchor.y) + CGFloat(shape.height) / 2) * pitch - cellGap / 2
        )
    }

    private func handlePieceTouch(slot: Int, phase: PieceTouchSurface.TouchPhase, location: CGPoint) {
        guard !game.isOver, let shape = game.shape(in: slot) else {
            clearDrag()
            return
        }
        switch phase {
        case .began:
            selectedSlot = slot
            dragSlot = slot
            dragPosition = location
            hover = proposedOrigin(at: location, shape: shape)
            store.selectPiece()
        case .moved:
            guard dragSlot == slot else { return }
            dragPosition = location
            hover = proposedOrigin(at: location, shape: shape)
        case .ended:
            guard dragSlot == slot else { return }
            let target = proposedOrigin(at: location, shape: shape)
            clearDrag()
            if let target {
                place(slot: slot, at: target)
            } else {
                // Tapping can still select a piece for accessibility.
                selectedSlot = slot
            }
        case .cancelled:
            clearDrag()
        }
    }

    private func clearDrag() {
        dragSlot = nil
        dragPosition = nil
        hover = nil
    }

    private func tappedBoard(_ cell: GridPoint) {
        guard let selectedSlot else { return }
        place(slot: selectedSlot, at: cell)
    }

    private func place(slot: Int, at point: GridPoint) {
        // Calculate exactly which lines this move completes BEFORE the engine clears them.
        let oldGame = game
        guard let piece = oldGame.shape(in: slot) else { return }
        var occupied = oldGame.board.map { $0 != nil }
        for cell in piece.cells {
            let x = point.x + cell.x
            let y = point.y + cell.y
            guard (0..<oldGame.side).contains(x), (0..<oldGame.side).contains(y) else {
                store.invalidDrop()
                return
            }
            occupied[y * oldGame.side + x] = true
        }
        guard let result = store.place(slot: slot, x: point.x, y: point.y) else {
            store.invalidDrop()
            return
        }
        selectedSlot = nil
        clearDrag()
        if result.lines > 0 {
            let side = oldGame.side
            let rows = Set((0..<side).filter { y in
                (0..<side).allSatisfy { x in occupied[y * side + x] }
            })
            let columns = Set((0..<side).filter { x in
                (0..<side).allSatisfy { y in occupied[y * side + x] }
            })
            effectGeneration += 1
            let generation = effectGeneration
            withAnimation(.easeOut(duration: 0.16)) {
                clearingRows = rows
                clearingColumns = columns
                boardBurst = game.board.allSatisfy { $0 == nil }
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 450_000_000)
                guard generation == effectGeneration else { return }
                withAnimation(.easeOut(duration: 0.22)) {
                    clearingRows = []
                    clearingColumns = []
                    boardBurst = false
                }
            }
        }
    }

    private func restart() {
        effectGeneration += 1
        clearingRows = []
        clearingColumns = []
        boardBurst = false
        store.newGame()
        selectedSlot = nil
        clearDrag()
    }
}
