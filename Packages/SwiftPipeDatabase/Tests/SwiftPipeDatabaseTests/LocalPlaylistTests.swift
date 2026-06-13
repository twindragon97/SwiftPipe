import XCTest
import GRDB
import SwiftPipeExtractor
@testable import SwiftPipeDatabase

/// Exercises the local-playlist coordinator end to end: create, append,
/// reorder, rename, the metadata/streams queries, and delete-cascade.
final class LocalPlaylistTests: XCTestCase {

    private func stream(_ n: Int) -> StreamEntity {
        StreamEntity(
            serviceId: 0, url: "https://youtu.be/\(n)", title: "Video \(n)",
            streamType: .VIDEO_STREAM, duration: 100, uploader: "U",
            thumbnailUrl: "https://i/\(n).jpg")
    }

    func testCreateAppendReorderAndQuery() throws {
        let db = try NewPipeDatabase.inMemory()
        let manager = LocalPlaylistManager(db)

        XCTAssertFalse(try manager.hasPlaylists())

        let pid = try XCTUnwrap(try manager.createPlaylist(name: "Watch later", streams: [stream(1), stream(2)]))
        XCTAssertTrue(try manager.hasPlaylists())

        // Append a third stream.
        try manager.appendToPlaylist(playlistId: pid, streams: [stream(3)])

        var streams = try manager.getPlaylistStreams(playlistId: pid)
        XCTAssertEqual(streams.map(\.streamEntity.title), ["Video 1", "Video 2", "Video 3"])
        XCTAssertEqual(streams.map(\.joinIndex), [0, 1, 2])

        // Reorder: reverse the three streams.
        let reversedIds = streams.map(\.streamId).reversed().map { $0 }
        try manager.updateJoin(playlistId: pid, streamIds: reversedIds)
        streams = try manager.getPlaylistStreams(playlistId: pid)
        XCTAssertEqual(streams.map(\.streamEntity.title), ["Video 3", "Video 2", "Video 1"])

        // Metadata: one playlist, count 3, thumbnail from first stream (stream 1).
        let metas = try manager.getPlaylists()
        XCTAssertEqual(metas.count, 1)
        XCTAssertEqual(metas[0].streamCount, 3)
        XCTAssertEqual(metas[0].orderingName, "Watch later")
        XCTAssertEqual(metas[0].thumbnailUrl, "https://i/1.jpg")
    }

    func testCreateEmptyReturnsNil() throws {
        let db = try NewPipeDatabase.inMemory()
        let manager = LocalPlaylistManager(db)
        XCTAssertNil(try manager.createPlaylist(name: "Empty", streams: []))
        XCTAssertFalse(try manager.hasPlaylists())
    }

    func testRenameAndDelete() throws {
        let db = try NewPipeDatabase.inMemory()
        let manager = LocalPlaylistManager(db)
        let pid = try XCTUnwrap(try manager.createPlaylist(name: "Old", streams: [stream(1)]))

        XCTAssertTrue(try manager.renamePlaylist(playlistId: pid, name: "New"))
        XCTAssertEqual(try manager.getPlaylists().first?.orderingName, "New")

        _ = try manager.deletePlaylist(playlistId: pid)
        XCTAssertTrue(try manager.getPlaylists().isEmpty)

        // Deleting the playlist cascades to playlist_stream_join.
        let joinCount = try db.dbWriter.read { try Int.fetchOne($0, sql: "SELECT COUNT(*) FROM playlist_stream_join") }
        XCTAssertEqual(joinCount, 0)
    }
}
