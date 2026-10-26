# Austins BlockBlast

An original, offline iPhone block-puzzle game, inspired by classic drag-and-drop block puzzles. Built with SwiftUI. **Minimum iOS: 16.0.**

## Play modes

- **Classic:** Endless 8×8 block puzzle. Clear complete rows and columns simultaneously, chain line clears and beat your local high score.
- **Daily Challenge:** A different seeded starting board for each local calendar date. Clear 4 lines in 27 moves. Completion is saved; the last seven challenges remain playable.
- **Line Rush:** Clear 5 lines in 28 moves on an 8×8 board.
- **Score Sprint:** Score 700 points in 26 moves.
- **Pocket Puzzle:** 6×6 board with starter blocks; clear 3 lines in 22 moves.

You can **drag a piece from the bottom tray** to the board (the placement preview floats above your finger). Alternatively, **tap a tray piece and then tap the board cell that will be its top-left anchor**. Place all three pieces to receive a new trio. Use Undo to reverse the last move. A game ends when no offered piece fits, when your moves expire, or when you've met the mode's goal.

## Fair piece generation

The project contains no advertisements, pay-to-win features, or score-based difficulty adjustments. Shapes are selected from a seeded pseudorandom generator, with the CURRENT BOARD's available positions as the only constraint. The generator searches for a trio with at least one playable placement sequence, taking possible clears into account. If it cannot find one in 80 searches, it gives three 1×1 blocks as a fallback (unless the board is completely filled). Your moves can still create a losing position; no board game can guarantee endless play. The source is in `AustinsBlockBlast/Core/GameCore.swift`.

Daily games derive their pseudorandom seed from the local-date key (YYYY-MM-DD). A reset of a daily game reuses that seed and starter board, but changing your placements can change which pieces are possible on later deals. This is NOT an online competitive leaderboard.

## Option 1 — Build and install through Xcode (Mac)

1. Unzip and open **`AustinsBlockBlast.xcodeproj`** in Xcode 16 or newer.
2. Select the **AustinsBlockBlast** app target, open **Signing & Capabilities**, enable **Automatically manage signing**, and select your Apple developer team (a free Apple ID may be sufficient for development installs).
3. Set a unique Bundle Identifier if necessary.
4. Plug in your iPhone, trust the computer, enable Developer Mode if prompted, and select your device in Xcode.
5. Press **Run (▶)** to build, sign, and install.

## Option 2 — Build an unsigned IPA from GitHub Actions (no Mac)

1. Upload the project files to the root of a GitHub repository, preserving the `.github/workflows/ios-build.yml` path.
2. Open **Actions → Build Austins BlockBlast (unsigned IPA) → Run workflow**. A push to `main` can also trigger it.
3. Once the workflow is successful, download the **AustinsBlockBlast-unsigned-IPA** artifact and extract its `AustinsBlockBlast-unsigned.ipa` file.
4. An **unsigned** IPA **cannot be installed directly**. You must sign it for your iPhone with a compatible sideloading tool (such as Sideloadly/AltStore when supported by your signing setup) or an Apple Developer certificate. Installation may require trusting the developer and Developer Mode.

The project here has **not** been built on macOS; Linux can test the platform-independent engine but cannot run Apple's iOS SDK build tools. The GitHub workflow is provided for a real iOS compile and IPA package.

## Local test (macOS or Linux with Swift installed)

```bash
./scripts/test-engine.sh
```

This compiles and exercises deterministic daily generation, row clearing, valid/invalid moves, scoring, and each play mode without requiring UIKit or SwiftUI.

## Technical details

- Swift / SwiftUI, `UserDefaults` JSON save data
- iPhone portrait layout, iOS 16+
- Original interface and icon; no copied Block Blast assets or third-party dependencies
- Offline play, no account required
- Haptics and sound toggles

App display name: **Austins BlockBlast**. Bundle identifier: `dev.austins.blockblast` (editable in Xcode).
