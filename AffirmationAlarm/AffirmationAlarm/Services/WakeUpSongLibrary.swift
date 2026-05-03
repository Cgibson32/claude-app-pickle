import Foundation

/// Discovers and picks bundled wake-up songs for the morning + snooze
/// playback paths.
///
/// ## Adding new songs
///
/// 1. Drop the audio file (`.mp3`, `.m4a`, `.caf`, or `.wav`) into
///    `AffirmationAlarm/Resources/Sounds/WakeUpSongs/` on disk.
/// 2. In Xcode, right-click the `WakeUpSongs` group →
///    **Add Files to "AffirmationAlarm"**, select the new file, and
///    check the **AffirmationAlarm** target.
/// 3. Make sure `WakeUpSongs` is added as a **Folder Reference** (the
///    blue folder icon) — not a Group (yellow icon). Folder references
///    preserve the directory structure inside the `.app` bundle so
///    `Bundle.main.urls(forResourcesWithExtension:subdirectory:)` can
///    find them.
///
/// No code changes required to add or remove songs — the library is
/// auto-discovered at runtime.
///
/// ## Picker semantics
///
/// `pickSong()` returns a random song while avoiding the most recently
/// played ones (tracked in `UserDefaults`). With a library of N songs,
/// the picker excludes the last `N/2` plays. With 5 songs, you'll never
/// hear the same song twice within a 2-snooze window.
enum WakeUpSongLibrary {

    /// Subdirectory inside the app bundle where wake-up songs live.
    /// Must match the folder reference name in Xcode.
    static let bundleSubdirectory = "WakeUpSongs"

    /// File extensions to scan for. Any file with one of these
    /// extensions inside `WakeUpSongs/` is included in the rotation.
    static let supportedExtensions = ["mp3", "m4a", "caf", "wav"]

    /// `UserDefaults` key for the recent-plays history.
    private static let recentPlaysKey = "wakeUpSongRecentPlays"

    /// Maximum number of recent plays we remember. Bounded so the
    /// history doesn't grow forever as the library expands.
    private static let recentPlaysCap = 20

    /// All wake-up songs bundled with the app, sorted by filename for
    /// deterministic iteration.
    static func allSongs() -> [URL] {
        var urls: [URL] = []
        for ext in supportedExtensions {
            if let found = Bundle.main.urls(
                forResourcesWithExtension: ext,
                subdirectory: bundleSubdirectory
            ) {
                urls.append(contentsOf: found)
            }
        }
        return urls.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// Pick a random song from the library, avoiding the most recently
    /// played ones for variety. Updates the recent-plays history.
    ///
    /// Returns `nil` if no songs are bundled — the caller should treat
    /// this as a graceful "no song this morning" and continue without it.
    static func pickSong() -> URL? {
        let songs = allSongs()
        guard !songs.isEmpty else {
            DiagnosticsLog.shared.log("songs", "library empty — no WakeUpSongs found in bundle")
            return nil
        }

        // Avoid the last N/2 plays so consecutive picks vary. With 1
        // song the avoidance set is empty and we always pick that song.
        let avoidCount = songs.count / 2
        let recent = Array(recentPlaysHistory().suffix(avoidCount))

        let candidates = songs.filter { !recent.contains($0.lastPathComponent) }
        let pool = candidates.isEmpty ? songs : candidates

        guard let pick = pool.randomElement() else { return nil }
        recordPlayed(pick)

        DiagnosticsLog.shared.log(
            "songs",
            "picked \(pick.lastPathComponent) (library=\(songs.count), avoided=\(recent.count))"
        )
        return pick
    }

    // MARK: - History

    private static func recentPlaysHistory() -> [String] {
        UserDefaults.standard.stringArray(forKey: recentPlaysKey) ?? []
    }

    private static func recordPlayed(_ url: URL) {
        var history = recentPlaysHistory()
        history.append(url.lastPathComponent)
        if history.count > recentPlaysCap {
            history.removeFirst(history.count - recentPlaysCap)
        }
        UserDefaults.standard.set(history, forKey: recentPlaysKey)
    }
}
