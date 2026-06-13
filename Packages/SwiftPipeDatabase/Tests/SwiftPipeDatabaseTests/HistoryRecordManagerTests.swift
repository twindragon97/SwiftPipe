import XCTest
import SwiftPipeExtractor
@testable import SwiftPipeDatabase

/// Verifies the watch/search-history and resume-state coordination matches the
/// Android manager's behaviour.
final class HistoryRecordManagerTests: XCTestCase {

    private func stream() -> StreamEntity {
        StreamEntity(
            serviceId: 0, url: "https://youtu.be/x", title: "X",
            streamType: .VIDEO_STREAM, duration: 600, uploader: "U")
    }

    func testOnViewedBumpsRepeatCount() throws {
        let db = try NewPipeDatabase.inMemory()
        let manager = HistoryRecordManager(db)

        let t1 = Date(timeIntervalSince1970: 1_700_000_000)
        let t2 = Date(timeIntervalSince1970: 1_700_000_100)

        let id1 = try manager.onViewed(stream(), at: t1)
        let id2 = try manager.onViewed(stream(), at: t2)
        XCTAssertEqual(id1, id2, "same stream reused")

        let history = try manager.getStreamHistory()
        XCTAssertEqual(history.count, 1, "one consolidated history row per stream")
        XCTAssertEqual(history[0].repeatCount, 2)
        XCTAssertEqual(history[0].accessDate, t2, "latest access date wins")
    }

    func testResumeStateSavedOnlyWhenValid() throws {
        let db = try NewPipeDatabase.inMemory()
        let manager = HistoryRecordManager(db)

        let id = try manager.onViewed(stream())

        // 30s into a 600s video → valid, saved.
        try manager.saveStreamState(stream(), progressMillis: 30_000)
        XCTAssertEqual(try manager.loadStreamState(streamId: id, durationInSeconds: 600)?.progressMillis, 30_000)

        // 2s → below the 5s threshold and below 1/4 → not saved, previous remains.
        try manager.saveStreamState(stream(), progressMillis: 2_000)
        XCTAssertEqual(try manager.loadStreamState(streamId: id, durationInSeconds: 600)?.progressMillis, 30_000)
    }

    func testOnSearchedDeduplicatesConsecutiveQueries() throws {
        let db = try NewPipeDatabase.inMemory()
        let manager = HistoryRecordManager(db)

        try manager.onSearched(serviceId: 0, search: "abc", at: Date(timeIntervalSince1970: 1))
        try manager.onSearched(serviceId: 0, search: "abc", at: Date(timeIntervalSince1970: 2))
        XCTAssertEqual(try db.searchHistoryDAO.getAll().count, 1, "repeated query refreshes, no new row")

        try manager.onSearched(serviceId: 0, search: "xyz", at: Date(timeIntervalSince1970: 3))
        XCTAssertEqual(try db.searchHistoryDAO.getAll().count, 2)

        let related = try manager.getRelatedSearches(query: "", similarQueryLimit: 5, uniqueQueryLimit: 5)
        XCTAssertEqual(related, ["xyz", "abc"], "unique searches, most recent first")
    }
}
