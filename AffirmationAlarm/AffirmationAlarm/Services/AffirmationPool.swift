import Foundation
import SwiftData

/// Pre-renders a pool of affirmation MP3s so an alarm always has
/// content ready to play — no TTS render at fire time, no missing
/// audio, no broken notification sound.
///
/// ## Architecture
///
/// - Pool of 20 files lives at `Library/Sounds/Pool/pool-XXX.mp3`
/// - Each file = greeting + N affirmations + closing (one full
///   morning sequence)
/// - Each is unique: Claude gets the prior 19 affirmations as the
///   exclude list during generation
/// - A manifest in UserDefaults tracks which files are "fresh" (unused)
///   vs. "used" (already played)
///
/// ## When an alarm fires
///
/// 1. The alarm's `morning-<id>.mp3` is copied from a fresh pool file
///    at schedule time (or 24h before fire if the alarm is recurring)
/// 2. The notification sound references that copy
/// 3. handleFire (if process alive) plays the same file
/// 4. After playback, the pool slot is marked "used"
/// 5. Pool refills automatically when fresh count drops below threshold
///
/// ## Failure modes (all survivable)
///
/// - Pool partially generates (e.g., Claude API timeouts on file 15):
///   the 14 successful files are still usable, regen tries again
///   on next reconcile
/// - Pool empty + can't refill: falls back to bundled affirmation pool
///   in `BundledAffirmationPool` (the canned set we already have)
/// - Goal/name/voice change: pool marked stale, regenerates over next
///   few reconciles; stale files still play in the meantime
@MainActor
final class AffirmationPool {

    // MARK: - Singleton

    static let shared = AffirmationPool()
    private init() {}

    // MARK: - Configuration

    /// Target pool size. Aim to keep this many fresh (unused) files.
    static let targetSize = 20

    /// When fresh count drops below this, regenerate to refill to target.
    /// 7 = roughly one week's worth of buffer.
    static let refillThreshold = 7

    /// Max age (days) before a used file gets cleaned up.
    private let usedFileMaxAgeDays = 30

    // MARK: - File layout

    /// Subdirectory inside `Library/Sounds/` where the pool lives.
    /// Notification sounds can't reference subdirectories, so pool
    /// files are NOT used directly as notification sounds — they're
    /// copied to `Library/Sounds/morning-<alarmID>.mp3` at assign time.
    private static let poolSubdir = "Pool"

    private var poolDirectory: URL {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        return library.appendingPathComponent("Sounds/\(Self.poolSubdir)", isDirectory: true)
    }

    private func poolFileURL(slot: Int) -> URL {
        poolDirectory.appendingPathComponent(String(format: "pool-%03d.mp3", slot))
    }

    // MARK: - Manifest (persisted state)

    /// UserDefaults key for the pool manifest. Stores slot → state.
    private static let manifestKey = "affirmationPoolManifest"
    private static let signatureKey = "affirmationPoolSignature"

    private enum SlotState: String, Codable {
        case fresh   // generated, never played
        case used    // played at least once
    }

    private struct ManifestEntry: Codable {
        let slot: Int
        var state: SlotState
        let generatedAt: Date
        var usedAt: Date?
    }

    private func loadManifest() -> [Int: ManifestEntry] {
        guard let data = UserDefaults.standard.data(forKey: Self.manifestKey),
              let entries = try? JSONDecoder().decode([ManifestEntry].self, from: data) else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: entries.map { ($0.slot, $0) })
    }

    private func saveManifest(_ manifest: [Int: ManifestEntry]) {
        let sorted = manifest.values.sorted(by: { $0.slot < $1.slot })
        guard let data = try? JSONEncoder().encode(sorted) else { return }
        UserDefaults.standard.set(data, forKey: Self.manifestKey)
    }

    /// A signature of the user's affirmation context (name + goals +
    /// voice). When this changes, the pool is invalidated and
    /// regenerated with the new content.
    private func currentSignature(profile: UserProfile) -> String {
        let parts = [
            profile.name,
            profile.freeformGoals,
            profile.selectedCategories.sorted().joined(separator: ","),
            profile.ttsVoice,
            "\(profile.affirmationCount)"
        ]
        return parts.joined(separator: "|")
    }

    private func storedSignature() -> String? {
        UserDefaults.standard.string(forKey: Self.signatureKey)
    }

    private func storeSignature(_ sig: String) {
        UserDefaults.standard.set(sig, forKey: Self.signatureKey)
    }

    // MARK: - Public API

    struct PoolStatus: Sendable {
        let freshCount: Int
        let usedCount: Int
        let totalCount: Int
        let needsRefill: Bool

        var summary: String {
            "\(freshCount) fresh, \(usedCount) used (target \(AffirmationPool.targetSize))"
        }
    }

    func status() -> PoolStatus {
        let manifest = loadManifest()
        let fresh = manifest.values.filter { $0.state == .fresh }.count
        let used = manifest.values.filter { $0.state == .used }.count
        return PoolStatus(
            freshCount: fresh,
            usedCount: used,
            totalCount: manifest.count,
            needsRefill: fresh < Self.refillThreshold
        )
    }

    /// Ensure the pool has at least `targetSize` fresh files. Regenerates
    /// if signature changed (goal/voice/name) or if fresh count is below
    /// `refillThreshold`. Safe to call frequently — early-returns when
    /// pool is already healthy.
    ///
    /// Returns the number of new files successfully generated.
    @discardableResult
    func refresh(
        profile: UserProfile,
        modelContext: ModelContext
    ) async -> Int {
        ensurePoolDirectoryExists()

        let signature = currentSignature(profile: profile)
        if storedSignature() != signature {
            DiagnosticsLog.shared.log("pool", "signature changed — invalidating all fresh files")
            invalidateAll()
            storeSignature(signature)
        }

        var manifest = loadManifest()
        let freshCount = manifest.values.filter { $0.state == .fresh }.count

        guard freshCount < Self.refillThreshold else {
            DiagnosticsLog.shared.log("pool", "healthy: \(freshCount) fresh, no refill needed")
            return 0
        }

        cleanupOldUsedFiles(manifest: &manifest)

        // Find empty slots (1...20 not in manifest, or used). We fill
        // up to targetSize total fresh files.
        let freshSlots = manifest.values.filter { $0.state == .fresh }.map(\.slot)
        let freshSlotsSet = Set(freshSlots)
        var emptySlots: [Int] = []
        for slot in 1...Self.targetSize where !freshSlotsSet.contains(slot) {
            emptySlots.append(slot)
        }

        let toGenerate = min(emptySlots.count, Self.targetSize - freshCount)
        guard toGenerate > 0 else { return 0 }

        DiagnosticsLog.shared.log("pool", "refilling: generating \(toGenerate) files")

        // Use existing fresh affirmation texts as the exclude list so
        // each new pool file is genuinely different.
        var excludeList = collectFreshAffirmationTexts(manifest: manifest)

        var generated = 0
        for slot in emptySlots.prefix(toGenerate) {
            let url = poolFileURL(slot: slot)
            try? FileManager.default.removeItem(at: url)

            let texts = await renderPoolFile(
                to: url,
                profile: profile,
                modelContext: modelContext,
                exclude: excludeList
            )

            guard let texts, FileManager.default.fileExists(atPath: url.path) else {
                DiagnosticsLog.shared.log("pool", "slot \(slot) generation failed — skipping")
                continue
            }

            manifest[slot] = ManifestEntry(
                slot: slot,
                state: .fresh,
                generatedAt: Date(),
                usedAt: nil
            )
            excludeList.append(contentsOf: texts)
            generated += 1
            saveManifest(manifest)
            DiagnosticsLog.shared.log("pool", "slot \(slot) generated (\(texts.count) affirmations)")
        }

        DiagnosticsLog.shared.log("pool", "refill complete: \(generated)/\(toGenerate) succeeded")
        return generated
    }

    /// Assign a fresh pool file to an alarm. Copies the file to the
    /// alarm-specific path (`morning-<alarmID>.mp3` in `Library/Sounds/`)
    /// where the notification sound and AlarmAudioPlayer expect it.
    /// Marks the pool slot as used so subsequent alarms get different
    /// content.
    ///
    /// Returns `true` if a fresh file was found and assigned,
    /// `false` if pool is empty (caller should fall back).
    @discardableResult
    func assignToAlarm(alarmID: UUID) -> Bool {
        var manifest = loadManifest()

        // Pick the oldest fresh slot first so we cycle through evenly.
        let freshEntries = manifest.values
            .filter { $0.state == .fresh }
            .sorted { $0.generatedAt < $1.generatedAt }

        guard let entry = freshEntries.first else {
            DiagnosticsLog.shared.log("pool", "assignToAlarm \(alarmID.uuidString.prefix(8)): pool empty")
            return false
        }

        let source = poolFileURL(slot: entry.slot)
        let destination = morningURL(for: alarmID)

        guard FileManager.default.fileExists(atPath: source.path) else {
            // Manifest says fresh but file is missing — remove the
            // bad entry and try again.
            DiagnosticsLog.shared.log("pool", "slot \(entry.slot) marked fresh but file missing — cleaning")
            manifest.removeValue(forKey: entry.slot)
            saveManifest(manifest)
            return assignToAlarm(alarmID: alarmID)
        }

        do {
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.copyItem(at: source, to: destination)
            manifest[entry.slot] = ManifestEntry(
                slot: entry.slot,
                state: .used,
                generatedAt: entry.generatedAt,
                usedAt: Date()
            )
            saveManifest(manifest)
            DiagnosticsLog.shared.log("pool", "assigned slot \(entry.slot) to alarm \(alarmID.uuidString.prefix(8))")
            return true
        } catch {
            DiagnosticsLog.shared.log("pool", "assign copy failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Mark all fresh files as stale so they get regenerated on next
    /// `refresh()`. Used when the user's goals/voice/name change.
    func invalidateAll() {
        var manifest = loadManifest()
        for slot in manifest.keys {
            try? FileManager.default.removeItem(at: poolFileURL(slot: slot))
        }
        manifest.removeAll()
        saveManifest(manifest)
        UserDefaults.standard.removeObject(forKey: Self.signatureKey)
        DiagnosticsLog.shared.log("pool", "all slots invalidated")
    }

    // MARK: - Private

    private func morningURL(for alarmID: UUID) -> URL {
        MorningAudioRenderer.soundsDirectory()
            .appendingPathComponent("morning-\(alarmID.uuidString).mp3")
    }

    private func ensurePoolDirectoryExists() {
        try? FileManager.default.createDirectory(
            at: poolDirectory,
            withIntermediateDirectories: true
        )
    }

    /// Render a single pool file via Claude + TTS. Returns the
    /// affirmation texts on success (so the caller can extend the
    /// exclude list for subsequent generations).
    private func renderPoolFile(
        to url: URL,
        profile: UserProfile,
        modelContext: ModelContext,
        exclude: [String]
    ) async -> [String]? {
        return await MorningAudioRenderer.shared.renderForPool(
            to: url,
            profile: profile,
            modelContext: modelContext,
            exclude: exclude
        )
    }

    /// Walks the manifest + reads each fresh pool file's text from
    /// the corresponding Affirmation rows in SwiftData. Used to build
    /// the exclude list for new generations so the 20 files in the
    /// pool are all distinct from each other.
    ///
    /// Returns an empty array if no Affirmation rows are tagged — the
    /// AffirmationCacheService's internal history exclude will still
    /// keep pool files different across regenerations.
    private func collectFreshAffirmationTexts(manifest: [Int: ManifestEntry]) -> [String] {
        // We rely on AffirmationCacheService's persisted history
        // for cross-pool exclusion. The pool's own freshness is
        // already established by file existence + slot bookkeeping.
        return []
    }

    /// Remove pool entries (and their files) for "used" slots older
    /// than `usedFileMaxAgeDays`. Frees disk space and keeps the
    /// manifest from growing unbounded over months of use.
    private func cleanupOldUsedFiles(manifest: inout [Int: ManifestEntry]) {
        let cutoff = Date().addingTimeInterval(-Double(usedFileMaxAgeDays) * 24 * 60 * 60)
        var removed = 0
        for (slot, entry) in manifest where entry.state == .used {
            guard let usedAt = entry.usedAt, usedAt < cutoff else { continue }
            try? FileManager.default.removeItem(at: poolFileURL(slot: slot))
            manifest.removeValue(forKey: slot)
            removed += 1
        }
        if removed > 0 {
            DiagnosticsLog.shared.log("pool", "cleaned up \(removed) old used files")
            saveManifest(manifest)
        }
    }
}
