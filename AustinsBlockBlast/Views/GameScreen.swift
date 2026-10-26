import SwiftUI

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
                    .frame(width: cellSize, height: cellSize)
                    .contentShape(Rectangle())
                    .onTapGesture { onCellTap(GridPoint(x: col, y: row)) }
                }
            }
        }
        .accessibilityLabel("\(game.side) by \(game.side) block puzzle board")
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
    @State private var showRestart = false

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
                GameBackdrop()
                VStack(spacing: 11) {
                    header
                    statsBar
                    if game.mode != .arcade { goalPanel }
                    Spacer(minLength: 0)
                    BoardGrid(game: game, hovering: hover, hoveringShape: activeShape, onCellTap: tappedBoard)
                        .frame(width: boardWidth, height: boardWidth)
                        .background(GeometryReader { view in
                            Color.clear.preference(key: BoardRectPreference.self,
                                                   value: view.frame(in: .named("gameArea")))
                        })
                        .padding(7)
                        .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 17))
                        .overlay {
                            RoundedRectangle(cornerRadius: 17)
                                .strokeBorder(GameTheme.outline.opacity(0.7), lineWidth: 1.2)
                        }
                        .onPreferenceChange(BoardRectPreference.self) { boardRect = $0 }
                    Spacer(minLength: 0)
                    Text(selectedSlot == nil ? "DRAG A SHAPE ONTO THE BOARD" : "DRAG OR TAP THE TOP-LEFT CELL")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.3)
                        .foregroundStyle(GameTheme.muted)
                        .padding(.top, 2)
                    trayView(availableWidth: geometry.size.width - 32)
                    toolbar
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if game.isOver { endOverlay }
            }
            .coordinateSpace(name: "gameArea")
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
                    } else {
                        Image(systemName: "checkmark")
                            .foregroundStyle(GameTheme.green.opacity(0.6))
                            .font(.title3.bold())
                    }
                }
                .frame(width: slotWidth, height: 87)
                .contentShape(RoundedRectangle(cornerRadius: 18))
                .onTapGesture { if shape != nil { selectedSlot = slot } }
                .gesture(
                    DragGesture(minimumDistance: 6, coordinateSpace: .named("gameArea"))
                        .onChanged { value in
                            guard let shape else { return }
                            selectedSlot = slot
                            dragSlot = slot
                            hover = proposedOrigin(at: value.location, shape: shape)
                        }
                        .onEnded { value in
                            guard let shape else { return }
                            let origin = proposedOrigin(at: value.location, shape: shape)
                            dragSlot = nil
                            hover = nil
                            if let origin { place(slot: slot, at: origin) }
                            else { store.invalidDrop() }
                        }
                )
                .accessibilityLabel(shape.map { "Piece \(slot + 1), \($0.cells.count) blocks" } ?? "Empty piece slot")
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button { store.undo(); selectedSlot = nil; dragSlot = nil; hover = nil } label: {
                Label("UNDO", systemImage: "arrow.uturn.backward")
                    .frame(maxWidth: .infinity)
            }
            .disabled(!store.canUndo)
            Button { showRestart = true } label: {
                Label("RESTART", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
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

    private func proposedOrigin(at location: CGPoint, shape: BlockShape) -> GridPoint? {
        guard boardRect.width > 1 else { return nil }
        // The lifted piece sits above the player's thumb while dragging.
        let lifted = CGPoint(x: location.x, y: location.y - 52)
        guard boardRect.insetBy(dx: -4, dy: -4).contains(lifted) else { return nil }
        let strideSize = boardRect.width / CGFloat(game.side)
        let col = Int(floor((lifted.x - boardRect.minX) / strideSize))
        let row = Int(floor((lifted.y - boardRect.minY) / strideSize))
        return GridPoint(x: col - shape.width / 2, y: row - shape.height / 2)
    }

    private func tappedBoard(_ cell: GridPoint) {
        guard let selectedSlot else { return }
        place(slot: selectedSlot, at: cell)
    }

    private func place(slot: Int, at point: GridPoint) {
        guard store.place(slot: slot, x: point.x, y: point.y) != nil else {
            store.invalidDrop()
            return
        }
        selectedSlot = nil
        dragSlot = nil
        hover = nil
    }

    private func restart() {
        store.newGame()
        selectedSlot = nil
        dragSlot = nil
        hover = nil
    }
}
