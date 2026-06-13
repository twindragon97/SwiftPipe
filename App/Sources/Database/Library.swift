import Foundation
import SwiftPipeDatabase
import SwiftPipeExtractor

/// App-wide access point to the on-device newpipe.db. Opens the database in
/// Application Support (byte-compatible with NewPipe Android, so it can be
/// exported and imported there), and vends the history and playlist managers.
/// The small helpers below are fire-and-forget — GRDB serialises writes, so
/// they run safely off the main actor.
final class Library {
    static let shared = Library()

    /// On-disk location of newpipe.db (used by import/export).
    let databaseURL: URL

    private(set) var database: NewPipeDatabase
    private(set) var history: HistoryRecordManager
    private(set) var playlists: LocalPlaylistManager

    /// YouTube's NewPipe service id.
    static let youtubeServiceId = 0

    /// UserDefaults key under which the imported preferences.json blob is kept,
    /// so a later export round-trips the original Android settings unchanged.
    private static let importedPrefsKey = "importedPreferencesJSON"

    private init() {
        databaseURL = Self.makeDatabaseURL()
        database = Self.open(databaseURL)
        history = HistoryRecordManager(database)
        playlists = LocalPlaylistManager(database)
    }

    private static func makeDatabaseURL() -> URL {
        let fm = FileManager.default
        let dir = (try? fm.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true)) ?? fm.temporaryDirectory
        return dir.appendingPathComponent(AppDatabase.databaseFileName)
    }

    private static func open(_ url: URL) -> NewPipeDatabase {
        if let db = try? NewPipeDatabase(path: url.path) { return db }
        if let memory = try? NewPipeDatabase.inMemory() { return memory }
        preconditionFailure("Unable to open or create the database")
    }

    /// Re-opens the database from disk (after an import replaced the file) and
    /// rebuilds the managers. Call on the main actor while the app is idle.
    func reopen() {
        database = Self.open(databaseURL)
        history = HistoryRecordManager(database)
        playlists = LocalPlaylistManager(database)
    }

    func recordSearch(_ query: String) {
        Task.detached(priority: .utility) {
            try? Self.shared.history.onSearched(serviceId: Self.youtubeServiceId, search: query)
        }
    }

    // MARK: Backup

    /// Writes a NewPipeData-style backup zip to `url`, re-emitting any previously
    /// imported preferences.json so Android settings round-trip losslessly.
    func exportBackup(to url: URL) throws {
        let prefs = UserDefaults.standard.data(forKey: Self.importedPrefsKey)
        try BackupManager.exportDatabase(from: database, preferencesJSON: prefs, to: url)
    }

    /// Replaces the database with the one in the backup zip, keeps its
    /// preferences.json for re-export, and re-opens the database.
    @discardableResult
    func importBackup(from url: URL) throws -> BackupManager.ImportResult {
        let result = try BackupManager.importDatabase(from: url, toDatabaseAt: databaseURL)
        if let prefs = result.preferencesJSON {
            UserDefaults.standard.set(prefs, forKey: Self.importedPrefsKey)
        }
        reopen()
        return result
    }
}

extension StreamEntity {
    /// Builds a database row from a search/queue item for history recording.
    init(item: SearchResultItem) {
        self.init(
            serviceId: item.serviceId,
            url: item.url,
            title: item.title,
            streamType: item.streamType,
            duration: item.durationSeconds,
            uploader: item.uploader,
            thumbnailUrl: item.thumbnailURL?.absoluteString)
    }
}
