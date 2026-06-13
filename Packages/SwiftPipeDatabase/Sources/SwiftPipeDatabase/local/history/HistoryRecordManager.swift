// Mirrors: app/src/main/java/org/schabi/newpipe/local/history/HistoryRecordManager.java @ v0.27.x
//
// Coordinates the stream/history/state DAOs the way Android's manager does.
// Two deliberate differences:
//   - RxJava (Maybe/Single/Completable, Schedulers.io) becomes synchronous
//     throwing methods; the app calls these off the main actor.
//   - The watch/search-history enabled toggles (SharedPreferences) are NOT
//     gated here — the app decides whether to record. NewPipe defaults both to
//     off; SwiftPipe records by default and exposes a setting later.
//
// onViewed takes a prebuilt StreamEntity + duration instead of a StreamInfo,
// because the full StreamInfo type isn't ported (the player resolves only the
// HLS manifest). The semantics — upsert stream, bump the latest history row's
// repeat count, save state only when valid — are identical.

import Foundation
import GRDB

public final class HistoryRecordManager {
    private let dbWriter: DatabaseWriter
    private let streamTable: StreamDAO
    private let streamHistoryTable: StreamHistoryDAO
    private let searchHistoryTable: SearchHistoryDAO
    private let streamStateTable: StreamStateDAO

    public init(_ database: NewPipeDatabase) {
        dbWriter = database.dbWriter
        streamTable = database.streamDAO
        streamHistoryTable = database.streamHistoryDAO
        searchHistoryTable = database.searchHistoryDAO
        streamStateTable = database.streamStateDAO
    }

    // MARK: Watch history

    /// Records a view: upserts the stream, then either bumps the latest history
    /// row (new access date, repeatCount + 1) or inserts the first view. Returns
    /// the stream's uid. Mirror of onViewed.
    @discardableResult
    public func onViewed(_ stream: StreamEntity, at currentTime: Date = Date()) throws -> Int64 {
        try dbWriter.write { db in
            var stream = stream
            let streamId = try streamTable.upsert(db, &stream)
            if let latest = try streamHistoryTable.getLatestEntry(db, streamId: streamId) {
                // Delete-by-entity uses the composite PK (stream_id, access_date),
                // mirroring BasicDAO.delete(latestEntry).
                _ = try latest.delete(db)
                let bumped = StreamHistoryEntity(
                    streamUid: streamId, accessDate: currentTime, repeatCount: latest.repeatCount + 1)
                try streamHistoryTable.insert(db, bumped)
            } else {
                try streamHistoryTable.insert(
                    db, StreamHistoryEntity(streamUid: streamId, accessDate: currentTime, repeatCount: 1))
            }
            return streamId
        }
    }

    public func deleteStreamHistoryAndState(streamId: Int64) throws {
        try dbWriter.write { db in
            _ = try streamStateTable.deleteState(db, streamId: streamId)
            _ = try streamHistoryTable.deleteStreamHistory(db, streamId: streamId)
        }
    }

    @discardableResult
    public func deleteWholeStreamHistory() throws -> Int {
        try streamHistoryTable.deleteAll()
    }

    public func getStreamStatistics() throws -> [StreamStatisticsEntry] {
        try streamHistoryTable.statistics()
    }

    public func getStreamHistory() throws -> [StreamHistoryEntry] {
        try streamHistoryTable.history()
    }

    // MARK: Search history

    /// Records a search: refreshes the latest entry's date if it repeats the
    /// last query, otherwise inserts a new entry. Mirror of onSearched.
    public func onSearched(serviceId: Int, search: String, at currentTime: Date = Date()) throws {
        let newEntry = SearchHistoryEntry(creationDate: currentTime, serviceId: serviceId, search: search)
        try dbWriter.write { db in
            if var latest = try searchHistoryTable.latestEntry(db), latest.hasEqualValues(newEntry) {
                latest.creationDate = currentTime
                try latest.update(db)
            } else {
                _ = try searchHistoryTable.insert(db, newEntry)
            }
        }
    }

    @discardableResult
    public func deleteSearchHistory(_ search: String) throws -> Int {
        try searchHistoryTable.deleteAllWhereQuery(search)
    }

    @discardableResult
    public func deleteCompleteSearchHistory() throws -> Int {
        try searchHistoryTable.deleteAll()
    }

    /// Autocomplete source: similar entries when there's a query, otherwise the
    /// most recent unique searches. Mirror of getRelatedSearches.
    public func getRelatedSearches(
        query: String, similarQueryLimit: Int, uniqueQueryLimit: Int
    ) throws -> [String] {
        query.isEmpty
            ? try searchHistoryTable.getUniqueEntries(limit: uniqueQueryLimit)
            : try searchHistoryTable.getSimilarEntries(query: query, limit: similarQueryLimit)
    }

    // MARK: Stream state (resume position)

    /// Saves the resume position, upserting the stream first; only persists when
    /// the state is valid (>5s or >1/4 through). Mirror of saveStreamState.
    public func saveStreamState(_ stream: StreamEntity, progressMillis: Int64) throws {
        try dbWriter.write { db in
            var stream = stream
            let streamId = try streamTable.upsert(db, &stream)
            let state = StreamStateEntity(streamUid: streamId, progressMillis: progressMillis)
            if state.isValid(durationInSeconds: stream.duration) {
                try streamStateTable.upsert(db, state)
            }
        }
    }

    /// Loads the resume position for a stream by id, but only if it is still
    /// valid for the given duration (mirror of the isValid filter in
    /// loadStreamState).
    public func loadStreamState(streamId: Int64, durationInSeconds: Int64) throws -> StreamStateEntity? {
        guard let state = try streamStateTable.getState(streamId: streamId) else { return nil }
        return state.isValid(durationInSeconds: durationInSeconds) ? state : nil
    }
}
