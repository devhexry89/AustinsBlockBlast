import SwiftUI

struct DailyChallengesScreen: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("abb_daily_completed_v1") private var completedDates = ""

    private var completed: Set<String> {
        Set(completedDates.split(separator: ",").map(String.init))
    }

    private var lastSevenDays: [Date] {
        (0..<7).reversed().compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: Date())
        }
    }

    var body: some View {
        ZStack {
            GameBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 21) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 14))
                        }
                        Spacer()
                        Text("DAILY CHALLENGES")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(GameTheme.muted)
                        Spacer()
                        Color.clear.frame(width: 44, height: 44)
                    }
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 40))
                        .foregroundStyle(GameTheme.yellow)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                    Text("A fresh puzzle. Every day.")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Each date has a reproducible starting board and seeded piece generator. Clear 4 lines in 27 moves to earn the daily star. You can retry as often as you like.")
                        .font(.system(size: 14))
                        .foregroundStyle(GameTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    let current = DailyChallenge.dayKey()
                    NavigationLink {
                        GameScreen(mode: .daily, dayKey: current)
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: completed.contains(current) ? "checkmark.seal.fill" : "star.fill")
                                .font(.title)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(completed.contains(current) ? "TODAY COMPLETED" : "PLAY TODAY'S PUZZLE")
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                Text(Date.now.formatted(.dateTime.month(.wide).day()))
                                    .font(.system(size: 12))
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 19, weight: .heavy))
                        }
                        .foregroundStyle(Color(hex: 0x241B11))
                        .padding(20)
                        .background(GameTheme.yellow, in: RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)

                    SectionEyebrow(title: "Last 7 days")
                    HStack(spacing: 7) {
                        ForEach(lastSevenDays, id: \.self) { date in
                            let key = DailyChallenge.dayKey(for: date)
                            let achieved = completed.contains(key)
                            NavigationLink {
                                GameScreen(mode: .daily, dayKey: key)
                            } label: {
                                VStack(spacing: 8) {
                                    Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(GameTheme.muted)
                                    Text(date.formatted(.dateTime.day()))
                                        .font(.system(size: 16, weight: .black, design: .rounded))
                                        .foregroundStyle(.white)
                                    Image(systemName: achieved ? "star.fill" : "circle.dotted")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(achieved ? GameTheme.yellow : GameTheme.muted.opacity(0.4))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 12))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Calendar.current.isDateInToday(date) ? GameTheme.yellow : GameTheme.outline.opacity(0.4))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack(spacing: 14) {
                        Image(systemName: "star.circle.fill")
                            .foregroundStyle(GameTheme.yellow)
                            .font(.title2)
                        Text("\(completed.count) daily challenge\(completed.count == 1 ? "" : "s") completed")
                            .foregroundStyle(.white)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .padding(17)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(GameTheme.recessed, in: RoundedRectangle(cornerRadius: 18))
                }
                .padding(21)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
