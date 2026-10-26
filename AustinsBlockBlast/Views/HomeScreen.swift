
                    Toggle("Sound effects", isOn: $soundsEnabled)
                }
                Section("Theme progress") {
                    Text("Current theme: \(ThemeCatalog.theme(named: selectedTheme).name)")
                    Text("Daily challenges completed: \(progress.dailyCompletions)")
                    Text("Mini games beaten: \([progress.lineRushWon, progress.scoreSprintWon, progress.pocketWon].filter { $0 }.count) / 3")
                }
                Section("Fair play") {
                    Text("Your score is never used to make piece generation harder. New sets are created using a seeded random generator and available board space. The generator looks for a playable three-piece sequence when possible. Bad moves can still end a game.")
                    Text("Daily puzzles use a date-based seed. Scores and completed challenges are saved on your iPhone.")
                    Text("No ads, in-app purchases, tracking, or network connection required.")
                }
                Section("About") {
                    Text("Austins BlockBlast • Version 1.2")
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

