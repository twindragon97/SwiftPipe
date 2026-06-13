// Mirrors: app/src/main/java/org/schabi/newpipe/database/playlist/PlaylistStreamEntry.kt @ v0.27.x
//
// Query-result type for a stream inside a local playlist: the embedded stream
// row plus its resume position and join index.

import GRDB

public struct PlaylistStreamEntry: FetchableRecord, Equatable {
    public let streamEntity: StreamEntity
    public let progressMillis: Int64
    public let streamId: Int64
    public let joinIndex: Int

    public init(row: Row) {
        streamEntity = StreamEntity(row: row)
        progressMillis = (row["progress_time"] as Int64?) ?? 0
        streamId = row["stream_id"]
        joinIndex = row["join_index"]
    }
}
