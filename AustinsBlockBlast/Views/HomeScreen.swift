import SwiftUI

struct HomeScreen: View {
    @AppStorage("abb_best_v2_arcade") private var classicBest = 0
    @AppStorage("abb_daily_completed_v1") private var completedDates = ""
    @AppStorage("abb_haptics") private var hapticsEnabled = true
    @AppStorage("abb_sound") private var soundsEnabled = true
    @State private var showSettings = false

    private var dailyFinished: Bool {
        Set(completedDates.split(separator: ",").map(String.init))
            .contains(DailyChallenge.dayKey())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GameBackdrop()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        HStack(spacing: 12) {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(GameTheme.yellow)
                            Text("CLASSIC BEST")
                                .tracking(1.2)
                                .foregroundStyle(GameTheme.muted)
                            Spacer()
                            Text(classicBest.formatted())
                                .foregroundStyle(.white)
                                .fontWeight(.black)
                        }
                        .font(.system(size: 13, design: .rounded))
                        .padding(17)
                        .background(GameTheme.recessed, in: RoundedRectangle(cornerRadius: 17))

                        NavigationLink {
                            GameScreen(mode: .arcade)
                        } label: {
                            HStack(spacing: 15) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 24, weight: .black))
                                    .frame(width: 55, height: 55)
                                    .background(Color.white.opacity(0.17), in: RoundedRectangle(cornerRadius: 17))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("PLAY CLASSIC")
                                        .font(.system(size: 23, weight: .black, design: .rounded))
                                    Text("Drop blocks. Clear lines. Beat your best.")
                                        .font(.system(size: 12, weight: .medium))
                                        .opacity(0.86)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 17, weight: .black))
                            }
                            .foregroundStyle(Color(hex: 0x061C33))
                            .padding(20)
                            .background(
                                LinearGradient(colors: [GameTheme.cyan, GameTheme.blue],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: RoundedRectangle(cornerRadius: 24)
                            )
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 11) {
                            SectionEyebrow(title: "A new challenge every day")
                            NavigationLink {
                                DailyChallengesScreen()
                            } label: {
                                FeatureCard(icon: dailyFinished ? "checkmark.seal.fill" : "calendar",
                                            title: dailyFinished ? "Daily complete!" : "Daily Challenge",
                                            subtitle: dailyFinished ? "Replay today's puzzle or see your week" : "Same date, same seed. Earn your daily star.",
                                            color: GameTheme.yellow, isBig: true)
                            }
                            .buttonStyle(.plain)
                        }

                        VStack(alignment: .leading, spacing: 11) {
                            SectionEyebrow(title: "Mini games")
                            ForEach([PlayMode.lineRush, .scoreSprint, .pocket]) { mode in
                                NavigationLink {
                                    GameScreen(mode: mode)
                                } label: {
                                    FeatureCard(icon: mode.symbol,
                                                title: mode.title,
                                                subtitle: mode.subtitle,
                                                color: accent(for: mode))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(GameTheme.green)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("NO RIGGED DROPS")
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("No ads, no pay-to-win, and no score-based difficulty manipulation. Fair pieces, readable rules.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(GameTheme.muted)
                            }
                        }
                        .padding(16)
                        .background(GameTheme.recessed, in: RoundedRectangle(cornerRadius: 17))
                    }
                    .padding(.horizontal, 21)
                    .padding(.top, 22)
                    .padding(.bottom, 35)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) { settingsSheet }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            BlockMark()
            VStack(alignment: .leading, spacing: -2) {
                Text("AUSTINS")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .tracking(4.3)
                    .foregroundStyle(GameTheme.cyan)
                Text("BLOCKBLAST")
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .tracking(-1.3)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(GameTheme.muted)
                    .frame(width: 40, height: 40)
                    .background(GameTheme.panel, in: Circle())
            }
            .accessibilityLabel("Settings")
        }
    }

    private var settingsSheet: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                    Toggle("Sound effects", isOn: $soundsEnabled)
                }
                Section("Fair play") {
                    Text("Your score is never used to make piece generation harder. New sets are created using a seeded random generator and available board space. The generator looks for a playable three-piece sequence when possible. Bad moves can still end a game.")
                    Text("Daily puzzles use a date-based seed. Scores and completed challenges are saved on your iPhone.")
                    Text("No ads, in-app purchases, tracking, or network connection required.")
                }
                Section("About") {
                    Text("Austins BlockBlast • Version 1.0")
                    Text("Original puzzle game inspired by classic block-fitting games.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(GameTheme.background)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showSettings = false }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func accent(for mode: PlayMode) -> Color {
        switch mode {
        case .lineRush: return GameTheme.green
        case .scoreSprint: return GameTheme.coral
        case .pocket: return GameTheme.purple
        case .daily: return GameTheme.yellow
        case .arcade: return GameTheme.blue
        }
    }
}
