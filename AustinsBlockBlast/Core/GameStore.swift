import Foundation
import SwiftUI
import UIKit
import AudioToolbox

enum GameFeedback {
    private static var soundsEnabled: Bool { UserDefaults.standard.object(forKey: "abb_sound") as? Bool ?? true }
    private static var hapticsEnabled: Bool { UserDefaults.standard.object(forKey: "abb_haptics") as? Bool ?? true }

    private enum Sound: SystemSoundID {
        case menu = 1104
        case select = 1155
        case place = 1105
        case clear = 1111
        case invalid = 1053
        case restart = 1106
        case win = 1025
        case lose = 1073
        case unlock = 1112
        case theme = 1113
    }

    private static func play(_ sound: Sound) {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(sound.rawValue)
    }

    static func menuTap() {
        if hapticsEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        play(.menu)
    }

    static func selectPiece() {
        if hapticsEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.65) }
        play(.select)
    }

    static func validPlacement(clearedLines: Bool, ended: Bool, won: Bool) {
        if ended {
            if hapticsEnabled {
                won ? UINotificationFeedbackGenerator().notificationOccurred(.success)
                    : UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            play(won ? .win : .lose)
        } else if clearedLines {
            if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.success) }
            play(.clear)
        } else {
            if hapticsEnabled { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
            play(.place)
        }
    }

    static func invalidAction() {
        if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
        play(.invalid)
    }

    static func restart() {
        if hapticsEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        play(.restart)
    }

    static func themeSelected() {
        if hapticsEnabled { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
        play(.theme)
    }

    static func unlockedTheme() {
        if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        play(.unlock)
    }
}

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
        let newlyUnlockedThemes = newlyUnlockedThemeIDs(after: updated)
        persist()
        GameFeedback.validPlacement(clearedLines: result.lines > 0,
                                    ended: result.gameFinished,
                                    won: result.won)
        if !newlyUnlockedThemes.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                GameFeedback.unlockedTheme()
            }
        }
        return result
    }

    func selectPiece() {
        GameFeedback.selectPiece()
    }

    func invalidDrop() {
        GameFeedback.invalidAction()
    }

    func undo() {
        guard var restore = previous else { return }
        restore.best = max(restore.best, game.best)
        game = restore
        previous = nil
        canUndo = false
        lastPoints = 0
        persist()
        GameFeedback.restart()
    }

    func newGame() {
        let nextSeed = game.mode == .daily ? game.seed : UInt64.random(in: 1...UInt64.max)
        game = BlockGame(mode: game.mode, seed: nextSeed, dayKey: game.dayKey,
                         previousBest: max(game.best, UserDefaults.standard.integer(forKey: bestKey)))
        previous = nil
        canUndo = false
        lastPoints = 0
        persist()
        GameFeedback.restart()
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
        if game.didWin {
            UserDefaults.standard.set(true, forKey: "abb_mode_win_\(game.mode.rawValue)")
        }
    }

    private func newlyUnlockedThemeIDs(after updated: BlockGame) -> [String] {
        let beforeProgress = ThemeProgress.current()
        let afterDefaults = UserDefaults.standard
        var daySet = Set((afterDefaults.string(forKey: "abb_daily_completed_v1") ?? "")
            .split(separator: ",").map(String.init))
        if updated.mode == .daily, updated.didWin, let day = updated.dayKey {
            daySet.insert(day)
        }
        let afterProgress = ThemeProgress(
            classicBest: max(updated.mode == .arcade ? updated.best : afterDefaults.integer(forKey: "abb_best_v2_arcade"), afterDefaults.integer(forKey: "abb_best_v2_arcade")),
            dailyCompletions: daySet.count,
            lineRushWon: afterDefaults.bool(forKey: "abb_mode_win_lineRush") || (updated.mode == .lineRush && updated.didWin),
            scoreSprintWon: afterDefaults.bool(forKey: "abb_mode_win_scoreSprint") || (updated.mode == .scoreSprint && updated.didWin),
            pocketWon: afterDefaults.bool(forKey: "abb_mode_win_pocket") || (updated.mode == .pocket && updated.didWin)
        )

        return ThemeCatalog.themes.compactMap { theme in
            let wasUnlocked = theme.unlockRule.isUnlocked(progress: beforeProgress)
            let nowUnlocked = theme.unlockRule.isUnlocked(progress: afterProgress)
            return !wasUnlocked && nowUnlocked ? theme.id : nil
        }
    }
}
