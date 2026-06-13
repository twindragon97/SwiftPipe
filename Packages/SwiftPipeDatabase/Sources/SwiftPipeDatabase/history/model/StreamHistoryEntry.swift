// Mirrors: app/src/main/java/org/schabi/newpipe/database/history/model/StreamHistoryEntry.kt @ v0.27.x
//
// Query-result type for `SELECT * FROM streams INNER JOIN stream_history
// ON uid = stream_id`. Room's @Embedded StreamEntity is reproduced by decoding
// the stream columns out of the same row; the join adds no column-name clashes
// (streams.uid vs stream_history.stream_id).

import Foundation
import GRDB

public struct StreamHistoryEntry: FetchableRecord, Equatable {
    public let streamEntity: StreamEntity
    public let streamId: Int64
    public let accessDate: Date
    public let repeatCount: Int64

    public init(row: Row) {
        streamEntity = StreamEntity(row: row)
        streamId = row["stream_id"]
        accessDate = Converters.date(fromTimestamp: row["access_date"])
        repeatCount = row["repeat_count"]
    }

    public func toStreamHistoryEntity() -> StreamHistoryEntity {
        StreamHistoryEntity(streamUid: streamId, accessDate: accessDate, repeatCount: repeatCount)
    }
}
