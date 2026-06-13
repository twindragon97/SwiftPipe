import Foundation
import SwiftPipeDatabase
import SwiftPipeExtractor

/// App-wide access point to the on-device newpipe.db. Opens the database in
/// Application Support (byte-compatible with NewPipe Android, so it can later be
/// exported and imported there), and vends the history and playlist managers.
/// The small helpers below are fire-and-forget — GRDB serialises writes, so
/// they run safely off the main actor.
final class Library {
    static let shared = Library()

    let database: NewPipeDatabase
    let history: HistoryRecordManager
    let playlists: LocalPlaylistManager

    /// YouTube's NewPipe service id.
    static let youtubeServiceId = 0

    private init() {
        database = Self.openDatabase()
        history = HistoryRecordManager(database)
        playlists = LocalPlaylistManager(database)
    }

    private static func openDatabase() -> NewPipeDatabase {
        do {
            let dir = try FileManager.default.url(
                for: .applicationSupportDirectory, in: .userDomainMask,
                appropriateFor: nil, create: true)
            let url = dir.appendingPathComponent(AppDatabase.databaseFileName)
            return try NewPipeDatabase(path: url.path)
        } catch {
            // Last resort so the app still runs (history just won't persist).
            if let memory = try? NewPipeDatabase.inMemory() { return memory }
            preconditionFailure("Unable to open or create the database: \(error)")
        }
    }

    func recordSearch(_ query: String) {
        Task.detached(priority: .utility) {
            try? Self.shared.history.onSearched(serviceId: Self.youtubeServiceId, search: query)
        }
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
