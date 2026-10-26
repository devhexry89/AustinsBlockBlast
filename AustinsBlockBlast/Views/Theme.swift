import SwiftUI
import UIKit

struct ThemePalette: Identifiable, Hashable {
    let id: String
    let name: String
    let tagline: String
    let previewAssetName: String
    let unlockRule: ThemeRule
    let backgroundHex: UInt32
    let panelHex: UInt32
    let recessedHex: UInt32
    let outlineHex: UInt32
    let mutedHex: UInt32
    let blueHex: UInt32
    let cyanHex: UInt32
    let greenHex: UInt32
    let yellowHex: UInt32
    let purpleHex: UInt32
    let coralHex: UInt32
    let blockHexes: [UInt32]

    var background: Color { Color(hex: backgroundHex) }
    var panel: Color { Color(hex: panelHex) }
    var recessed: Color { Color(hex: recessedHex) }
    var outline: Color { Color(hex: outlineHex) }
    var muted: Color { Color(hex: mutedHex) }
    var blue: Color { Color(hex: blueHex) }
    var cyan: Color { Color(hex: cyanHex) }
    var green: Color { Color(hex: greenHex) }
    var yellow: Color { Color(hex: yellowHex) }
    var purple: Color { Color(hex: purpleHex) }
    var coral: Color { Color(hex: coralHex) }

    func block(_ index: Int) -> Color {
        Color(hex: blockHexes[abs(index) % blockHexes.count])
    }
}

enum ThemeRule: Hashable {
    case always
    case classicBest(Int)
    case dailyCompletions(Int)
    case allMiniGames
    case combo(classicBest: Int, dailyCompletions: Int)

    func isUnlocked(progress: ThemeProgress) -> Bool {
        switch self {
        case .always:
            return true
        case .classicBest(let score):
            return progress.classicBest >= score
        case .dailyCompletions(let amount):
            return progress.dailyCompletions >= amount
        case .allMiniGames:
            return progress.lineRushWon && progress.scoreSprintWon && progress.pocketWon
        case .combo(let score, let dailies):
            return progress.classicBest >= score && progress.dailyCompletions >= dailies
        }
    }

    func description(progress: ThemeProgress) -> String {
        switch self {
        case .always:
            return "Default theme"
        case .classicBest(let score):
            return "Reach a Classic best score of \(score.formatted())"
        case .dailyCompletions(let amount):
            return "Complete \(amount) daily challenge\(amount == 1 ? "" : "s")"
        case .allMiniGames:
            return "Beat all 3 mini games"
        case .combo(let score, let dailies):
            return "Reach \(score.formatted()) Classic score and complete \(dailies) dailies"
        }
    }

    func progressLine(progress: ThemeProgress) -> String {
        switch self {
        case .always:
            return "Unlocked"
        case .classicBest(let score):
            return "\(min(progress.classicBest, score).formatted()) / \(score.formatted())"
        case .dailyCompletions(let amount):
            return "\(min(progress.dailyCompletions, amount)) / \(amount)"
        case .allMiniGames:
            let count = [progress.lineRushWon, progress.scoreSprintWon, progress.pocketWon].filter { $0 }.count
            return "\(count) / 3 completed"
        case .combo(let score, let dailies):
            return "Score: \(min(progress.classicBest, score).formatted())/\(score.formatted()) • Dailies: \(min(progress.dailyCompletions, dailies))/\(dailies)"
        }
    }
}

struct ThemeProgress {
    let classicBest: Int
    let dailyCompletions: Int
    let lineRushWon: Bool
    let scoreSprintWon: Bool
    let pocketWon: Bool

    static func current() -> ThemeProgress {
        let defaults = UserDefaults.standard
        let days = Set((defaults.string(forKey: "abb_daily_completed_v1") ?? "")
            .split(separator: ",").map(String.init))
        return ThemeProgress(
            classicBest: defaults.integer(forKey: "abb_best_v2_arcade"),
            dailyCompletions: days.count,
            lineRushWon: defaults.bool(forKey: "abb_mode_win_lineRush"),
            scoreSprintWon: defaults.bool(forKey: "abb_mode_win_scoreSprint"),
            pocketWon: defaults.bool(forKey: "abb_mode_win_pocket")
        )
    }
}

enum ThemeCatalog {
    static let `default` = "classic"

    static let themes: [ThemePalette] = [
        ThemePalette(
            id: "classic",
            name: "Classic Glow",
            tagline: "The original cool neon board",
            previewAssetName: "ThemePreviewClassic",
            unlockRule: .always,
            backgroundHex: 0x0A1026,
            panelHex: 0x182244,
            recessedHex: 0x111933,
            outlineHex: 0x34456D,
            mutedHex: 0x9BAAC9,
            blueHex: 0x49B7FF,
            cyanHex: 0x57E7F2,
            greenHex: 0x6EEDB1,
            yellowHex: 0xFFCD71,
            purpleHex: 0xB595FF,
            coralHex: 0xFF8D94,
            blockHexes: [0x4EB8FF, 0xAF8DFF, 0xF7BE58, 0xF37F99, 0x60DFAA, 0x5FE6DE]
        ),
        ThemePalette(
            id: "sunset",
            name: "Sunset Pop",
            tagline: "Warm dusk colors with a bright glow",
            previewAssetName: "ThemePreviewSunset",
            unlockRule: .classicBest(1200),
            backgroundHex: 0x261128,
            panelHex: 0x4A2241,
            recessedHex: 0x391834,
            outlineHex: 0x86426B,
            mutedHex: 0xF2B9C4,
            blueHex: 0xFFA55F,
            cyanHex: 0xFFBE74,
            greenHex: 0xFFD166,
            yellowHex: 0xFFE08A,
            purpleHex: 0xFF7EB6,
            coralHex: 0xFF6E6E,
            blockHexes: [0xFF8B5D, 0xFFA552, 0xFFCF6B, 0xFF7096, 0xFF82C8, 0xFFC86C]
        ),
        ThemePalette(
            id: "forest",
            name: "Emerald Night",
            tagline: "Deep green panels and punchy mint blocks",
            previewAssetName: "ThemePreviewForest",
            unlockRule: .classicBest(2500),
            backgroundHex: 0x091B17,
            panelHex: 0x16342D,
            recessedHex: 0x112823,
            outlineHex: 0x2E6659,
            mutedHex: 0x99C5B6,
            blueHex: 0x4FC4A4,
            cyanHex: 0x63E6BF,
            greenHex: 0x95F19B,
            yellowHex: 0xD8F171,
            purpleHex: 0x79D9C4,
            coralHex: 0xF0B56B,
            blockHexes: [0x5AC8A8, 0x82E6B8, 0xD5EF72, 0x4EC7DE, 0x5BF0C4, 0xA0E36A]
        ),
        ThemePalette(
            id: "aurora",
            name: "Aurora Sky",
            tagline: "Northern-light gradients and icy panels",
            previewAssetName: "ThemePreviewAurora",
            unlockRule: .dailyCompletions(3),
            backgroundHex: 0x081329,
            panelHex: 0x132C4B,
            recessedHex: 0x10213A,
            outlineHex: 0x315C87,
            mutedHex: 0xA9C8E9,
            blueHex: 0x6ABFFF,
            cyanHex: 0x80FFF7,
            greenHex: 0x83F5C6,
            yellowHex: 0xFFE58E,
            purpleHex: 0xB3A0FF,
            coralHex: 0xFF9AC0,
            blockHexes: [0x66C7FF, 0x80F7F1, 0x95F5C6, 0xB09CFF, 0xFFB6CE, 0xFFE28C]
        ),
        ThemePalette(
            id: "candy",
            name: "Candy Spark",
            tagline: "Sweet pastel blocks with arcade energy",
            previewAssetName: "ThemePreviewCandy",
            unlockRule: .allMiniGames,
            backgroundHex: 0x24132D,
            panelHex: 0x432152,
            recessedHex: 0x331940,
            outlineHex: 0x8556A4,
            mutedHex: 0xEDC9F8,
            blueHex: 0x8EDCFF,
            cyanHex: 0x8FF5EF,
            greenHex: 0xADF2A0,
            yellowHex: 0xFFE48E,
            purpleHex: 0xD6A7FF,
            coralHex: 0xFF9CC3,
            blockHexes: [0x8FD9FF, 0xD4A2FF, 0xFFB3D1, 0xFFE08A, 0xB5F4A8, 0x9AF5F0]
        ),
        ThemePalette(
            id: "midnight",
            name: "Midnight Gold",
            tagline: "Premium dark slate with gold energy",
            previewAssetName: "ThemePreviewMidnight",
            unlockRule: .combo(classicBest: 5000, dailyCompletions: 7),
            backgroundHex: 0x07090F,
            panelHex: 0x171B24,
            recessedHex: 0x10141C,
            outlineHex: 0x5D4D2A,
            mutedHex: 0xD4C6A0,
            blueHex: 0x6D87A8,
            cyanHex: 0xA2C4D9,
            greenHex: 0xC1E39E,
            yellowHex: 0xF7C96D,
            purpleHex: 0xB6A3D2,
            coralHex: 0xE4A48B,
            blockHexes: [0xE0BF72, 0xA9C5E0, 0xC2E2A3, 0xB89FD8, 0xE8A58F, 0x7E9CC4]
        )
    ]

    static func theme(named id: String) -> ThemePalette {
        themes.first(where: { $0.id == id }) ?? themes[0]
    }

    static func current() -> ThemePalette {
        theme(named: UserDefaults.standard.string(forKey: "abb_selected_theme") ?? `default`)
    }
}

enum GameTheme {
    private static var palette: ThemePalette { ThemeCatalog.current() }
    static let backgroundAssetOpacity = 0.22

    static var background: Color { palette.background }
    static var panel: Color { palette.panel }
    static var recessed: Color { palette.recessed }
    static var outline: Color { palette.outline }
    static var muted: Color { palette.muted }
    static var blue: Color { palette.blue }
    static var cyan: Color { palette.cyan }
    static var green: Color { palette.green }
    static var yellow: Color { palette.yellow }
    static var purple: Color { palette.purple }
    static var coral: Color { palette.coral }
    static func block(_ colorIndex: Int) -> Color { palette.block(colorIndex) }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

struct GameBackdrop: View {
    private var theme: ThemePalette { ThemeCatalog.current() }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                theme.background
                Image(theme.previewAssetName)
                    .resizable()
                    .scaledToFill()
                    // The image must not determine the width of the parent view.
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .opacity(GameTheme.backgroundAssetOpacity)
                    .blur(radius: 18)
                    .clipped()
                RadialGradient(colors: [theme.blue.opacity(0.22), .clear],
                               center: .topLeading, startRadius: 10, endRadius: 520)
                RadialGradient(colors: [theme.purple.opacity(0.18), .clear],
                               center: .bottomTrailing, startRadius: 25, endRadius: 480)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct GlowTile: View {
    let color: Color
    var body: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(LinearGradient(colors: [color.opacity(1), color.opacity(0.75)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.24))
                    .frame(height: 3)
                    .padding(.horizontal, 2)
                    .padding(.top, 2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8)
            }
    }
}

struct BlockMark: View {
    var body: some View {
        let pixels: [(Int, Int, Int)] = [
            (0, 0, 0), (1, 0, 1), (2, 0, 2),
            (0, 1, 0), (1, 1, 1),
            (0, 2, 3), (1, 2, 3), (2, 2, 4)
        ]
        ZStack(alignment: .topLeading) {
            ForEach(pixels.indices, id: \.self) { index in
                let item = pixels[index]
                GlowTile(color: GameTheme.block(item.2))
                    .frame(width: 19, height: 19)
                    .offset(x: CGFloat(item.0) * 22, y: CGFloat(item.1) * 22)
            }
        }
        .frame(width: 63, height: 63, alignment: .topLeading)
        .accessibilityLabel("Colorful block puzzle logo")
    }
}

struct SectionEyebrow: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .tracking(2)
            .foregroundStyle(GameTheme.muted)
    }
}

struct MiniStat: View {
    let title: String
    let value: String
    let accent: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(GameTheme.muted)
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(accent)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var isBig = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: isBig ? 28 : 23, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: isBig ? 58 : 48, height: isBig ? 58 : 48)
                .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: isBig ? 23 : 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(GameTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 3)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color.opacity(0.8))
        }
        .padding(isBig ? 18 : 15)
        .background(GameTheme.panel.opacity(0.92), in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(color.opacity(isBig ? 0.48 : 0.15), lineWidth: 1)
        }
    }
}

struct ThemeCard: View {
    let theme: ThemePalette
    let unlocked: Bool
    let selected: Bool
    let progress: ThemeProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .bottomLeading) {
                    Image(theme.previewAssetName)
                        .resizable()
                        .scaledToFill()
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient(colors: [.clear, Color.black.opacity(0.4)],
                                             startPoint: .top, endPoint: .bottom))
                    miniBoard
                        .padding(12)
                }
                .frame(width: 178, height: 118)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                if selected {
                    Label("Active", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(theme.background)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(theme.cyan, in: Capsule())
                        .padding(10)
                } else if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.45), in: Circle())
                        .padding(10)
                }
            }
            Text(theme.name)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(unlocked ? theme.tagline : theme.unlockRule.description(progress: progress))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(GameTheme.muted)
                .lineLimit(2)
            Text(unlocked ? (selected ? "Selected" : "Tap to use") : theme.unlockRule.progressLine(progress: progress))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(unlocked ? theme.yellow : GameTheme.muted)
        }
        .padding(11)
        .frame(width: 200)
        .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 21))
        .overlay {
            RoundedRectangle(cornerRadius: 21)
                .strokeBorder(selected ? theme.cyan : theme.outline.opacity(0.45), lineWidth: selected ? 2 : 1)
        }
    }

    private var miniBoard: some View {
        HStack(spacing: 3) {
            VStack(spacing: 3) {
                miniTile(theme.block(0))
                miniTile(theme.block(1))
            }
            VStack(spacing: 3) {
                miniTile(theme.block(2))
                miniTile(theme.block(3))
                miniTile(theme.block(4))
            }
            VStack(spacing: 3) {
                miniTile(theme.block(5))
                miniTile(theme.block(0))
            }
        }
        .padding(7)
        .background(theme.recessed.opacity(0.85), in: RoundedRectangle(cornerRadius: 12))
    }

    private func miniTile(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(width: 18, height: 18)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.7)
            }
    }
}
