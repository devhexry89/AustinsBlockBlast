import SwiftUI

enum GameTheme {
    static let background = Color(hex: 0x0A1026)
    static let panel = Color(hex: 0x182244)
    static let recessed = Color(hex: 0x111933)
    static let outline = Color(hex: 0x34456D)
    static let muted = Color(hex: 0x9BAAC9)
    static let blue = Color(hex: 0x49B7FF)
    static let cyan = Color(hex: 0x57E7F2)
    static let green = Color(hex: 0x6EEDB1)
    static let yellow = Color(hex: 0xFFCD71)
    static let purple = Color(hex: 0xB595FF)
    static let coral = Color(hex: 0xFF8D94)
    static let blockColors: [Color] = [
        Color(hex: 0x4EB8FF), Color(hex: 0xAF8DFF),
        Color(hex: 0xF7BE58), Color(hex: 0xF37F99),
        Color(hex: 0x60DFAA), Color(hex: 0x5FE6DE)
    ]

    static func block(_ colorIndex: Int) -> Color {
        blockColors[abs(colorIndex) % blockColors.count]
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

struct GameBackdrop: View {
    var body: some View {
        ZStack {
            GameTheme.background
            RadialGradient(colors: [Color(hex: 0x224783).opacity(0.42), .clear],
                           center: .topLeading, startRadius: 10, endRadius: 480)
            RadialGradient(colors: [Color(hex: 0x4E286C).opacity(0.27), .clear],
                           center: .bottomTrailing, startRadius: 20, endRadius: 430)
        }
        .ignoresSafeArea()
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
