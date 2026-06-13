import XCTest
import GRDB
import SwiftPipeExtractor
@testable import SwiftPipeDatabase

/// Behavioural tests for the DAO layer: dedupe-on-upsert, the history join,
/// resume-state thresholds, foreign-key cascade, and millisecond-exact date
/// round-trips (the property that keeps an exported database readable by
/// NewPipe Android).
final class DAOTests: XCTestCase {

    private func makeStream(
        url: String = "https://www.youtube.com/watch?v=abc",
        title: String = "Title",
        duration: Int64 = 100
    ) -> StreamEntity {
        StreamEntity(
            serviceId: 0, url: url, title: title, streamType: .VIDEO_STREAM,
            duration: duration, uploader: "Uploader")
    }

    func testStreamUpsertDeduplicatesByServiceAndUrl() throws {
        let db = try NewPipeDatabase.inMemory()

        var first = makeStream(title: "First")
        let uid1 = try db.streamDAO.upsert(&first)

        var second = makeStream(title: "Second")
        let uid2 = try db.streamDAO.upsert(&second)

        XCTAssertEqual(uid1, uid2, "same (service_id, url) must reuse the row")

        let count = try db.dbWriter.read { try Int.fetchOne($0, sql: "SELECT COUNT(*) FROM streams") }
        XCTAssertEqual(count, 1)

        let stored = try db.dbWriter.read { try db.streamDAO.getStream($0, serviceId: 0, url: first.url) }
        XCTAssertEqual(stored?.title, "Second", "upsert updates the existing row")
    }

    func testStreamStateRoundTripAndDeleteCascade() throws {
        let db = try NewPipeDatabase.inMemory()

        var stream = makeStream()
        let uid = try db.streamDAO.upsert(&stream)

        try db.streamStateDAO.upsert(StreamStateEntity(streamUid: uid, progressMillis: 42_000))
        XCTAssertEqual(try db.streamStateDAO.getState(streamId: uid)?.progressMillis, 42_000)

        // Upsert replaces (PK = stream_id), not duplicates.
        try db.streamStateDAO.upsert(StreamStateEntity(streamUid: uid, progressMillis: 84_000))
        XCTAssertEqual(try db.streamStateDAO.getState(streamId: uid)?.progressMillis, 84_000)

        // Deleting the stream cascades to stream_state (FK ON DELETE CASCADE).
        _ = try db.dbWriter.write { try $0.execute(sql: "DELETE FROM streams WHERE uid = ?", arguments: [uid]) }
        XCTAssertNil(try db.streamStateDAO.getState(streamId: uid))
    }

    func testStreamStateThresholds() {
        // 5s save threshold; >1/4 of duration also saves.
        XCTAssertFalse(StreamStateEntity(streamUid: 1, progressMillis: 4_000).isValid(durationInSeconds: 600))
        XCTAssertTrue(StreamStateEntity(streamUid: 1, progressMillis: 6_000).isValid(durationInSeconds: 600))
        XCTAssertTrue(StreamStateEntity(streamUid: 1, progressMillis: 3_000).isValid(durationInSeconds: 8)) // >1/4 of 8s

        // finished: <60s left AND >=3/4 through.
        XCTAssertTrue(StreamStateEntity(streamUid: 1, progressMillis: 590_000).isFinished(durationInSeconds: 600))
        XCTAssertFalse(StreamStateEntity(streamUid: 1, progressMillis: 450_000).isFinished(durationInSeconds: 600)) // 150s left
    }

    func testStreamHistoryJoinNewestFirst() throws {
        let db = try NewPipeDatabase.inMemory()

        var a = makeStream(url: "https://youtu.be/a", title: "A")
        let uidA = try db.streamDAO.upsert(&a)
        var b = makeStream(url: "https://youtu.be/b", title: "B")
        let uidB = try db.streamDAO.upsert(&b)

        let older = Date(timeIntervalSince1970: 1_700_000_000)
        let newer = Date(timeIntervalSince1970: 1_700_000_500)
        let historyDAO = db.streamHistoryDAO
        try db.dbWriter.write { conn in
            try historyDAO.insert(conn, StreamHistoryEntity(streamUid: uidA, accessDate: older, repeatCount: 1))
            try historyDAO.insert(conn, StreamHistoryEntity(streamUid: uidB, accessDate: newer, repeatCount: 1))
        }

        let history = try db.streamHistoryDAO.history()
        XCTAssertEqual(history.map(\.streamId), [uidB, uidA], "newest access first")
        XCTAssertEqual(history.first?.streamEntity.title, "B")
        XCTAssertEqual(history.first?.accessDate, newer, "access date round-trips to the millisecond")
    }

    func testSearchHistoryUniqueAndSimilar() throws {
        let db = try NewPipeDatabase.inMemory()

        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let terms: [(String, TimeInterval)] = [
            ("swift", 0), ("swiftui", 10), ("swift", 20), ("kotlin", 30),
        ]
        for (term, offset) in terms {
            _ = try db.searchHistoryDAO.insert(
                SearchHistoryEntry(creationDate: base.addingTimeInterval(offset), serviceId: 0, search: term))
        }

        // Distinct terms, most-recent first: swift(20) > kotlin(30)? kotlin is newest.
        let unique = try db.searchHistoryDAO.getUniqueEntries(limit: 10)
        XCTAssertEqual(unique, ["kotlin", "swift", "swiftui"])

        let similar = try db.searchHistoryDAO.getSimilarEntries(query: "swift", limit: 10)
        XCTAssertEqual(similar, ["swift", "swiftui"])
    }

    func testSubscriptionUpsertAllDeduplicatesAndOrders() throws {
        let db = try NewPipeDatabase.inMemory()

        let zebra = SubscriptionEntity(serviceId: 0, url: "https://yt/zebra", name: "Zebra")
        let apple = SubscriptionEntity(serviceId: 0, url: "https://yt/apple", name: "apple")
        _ = try db.subscriptionDAO.upsertAll([zebra, apple])

        // Re-inserting the same URLs with new names updates, does not duplicate.
        let appleRenamed = SubscriptionEntity(serviceId: 0, url: "https://yt/apple", name: "Apple Renamed")
        let upserted = try db.subscriptionDAO.upsertAll([appleRenamed])
        XCTAssertGreaterThan(upserted[0].uid, 0, "existing uid is adopted")

        let all = try db.subscriptionDAO.getAll()
        XCTAssertEqual(all.count, 2)
        // ORDER BY name COLLATE NOCASE: "Apple Renamed" before "Zebra".
        XCTAssertEqual(all.map(\.name), ["Apple Renamed", "Zebra"])
    }

    func testStreamTypeConverterRoundTrip() {
        for type in [StreamType.NONE, .VIDEO_STREAM, .AUDIO_STREAM, .LIVE_STREAM,
                     .AUDIO_LIVE_STREAM, .POST_LIVE_STREAM, .POST_LIVE_AUDIO_STREAM] {
            XCTAssertEqual(Converters.streamType(of: Converters.string(of: type)), type)
        }
    }
}
