import Foundation
import SwiftUI
import UIKit
import AudioToolbox

@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var game: BlockGame
    @Published private(set) var canUndo = false
    @Published private(set) var lastPoints = 0

    @AppStorage("abb_haptics") var hapticsEnabled = true
    @AppStorage("abb_sound") var soundsEnabled = true

    private var previous: BlockGame?
    private let saveKey: String
    private let bestKey: String

    init(mode: PlayMode, requestedDay: String? = nil) {
        let day = mode == .daily ? (requestedDay ?? DailyChallenge.dayKey()) : nil
        let suffix = mode.rawValue + (day.map { "_" + $0 } ?? "")
        saveKey = "abb_saved_v2_" + suffix
        bestKey = "abb_best_v2_" + mode.rawValue
        let storedBest = UserDefaults.standard.integer(forKey: bestKey)
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let saved = try? JSONDecoder().decode(BlockGame.self, from: data),
           saved.mode == mode, saved.dayKey == day,
           saved.board.count == mode.side * mode.side, saved.tray.count == 3 {
            game = saved
        } else {
            let seed = day.map(DailyChallenge.seed(for:)) ?? UInt64.random(in: 1...UInt64.max)
            game = BlockGame(mode: mode, seed: seed, dayKey: day, previousBest: storedBest)
        }
    }

    @discardableResult
    func place(slot: Int, x: Int, y: Int) -> PlacementResult? {
        var updated = game
        guard let result = updated.place(slot: slot, x: x, y: y) else { return nil }
        previous = game
        canUndo = true
        game = updated
        lastPoints = result.points
        persist()
        if hapticsEnabled {
            if result.lines > 0 { UINotificationFeedbackGenerator().notificationOccurred(.success) }
            else { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        }
        if soundsEnabled { AudioServicesPlaySystemSound(result.lines > 0 ? 1104 : 1105) }
        return result
    }

    func invalidDrop() {
        if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    }

    func undo() {
        guard var restore = previous else { return }
        restore.best = max(restore.best, game.best)
        game = restore
        previous = nil
        canUndo = false
        lastPoints = 0
        persist()
        if hapticsEnabled { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    }

    func newGame() {
        let nextSeed = game.mode == .daily ? game.seed : UInt64.random(in: 1...UInt64.max)
        game = BlockGame(mode: game.mode, seed: nextSeed, dayKey: game.dayKey,
                         previousBest: max(game.best, UserDefaults.standard.integer(forKey: bestKey)))
        previous = nil
        canUndo = false
        lastPoints = 0
        persist()
        if hapticsEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    }

    private func persist() {
        UserDefaults.standard.set(try? JSONEncoder().encode(game), forKey: saveKey)
        UserDefaults.standard.set(game.best, forKey: bestKey)
        if game.mode == .daily, game.didWin, let day = game.dayKey {
            var days = Set((UserDefaults.standard.string(forKey: "abb_daily_completed_v1") ?? "")
                .split(separator: ",").map(String.init))
            days.insert(day)
            UserDefaults.standard.set(days.sorted().joined(separator: ","), forKey: "abb_daily_completed_v1")
        }
    }
}
