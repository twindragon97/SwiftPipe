// Mirrors: app/src/main/java/org/schabi/newpipe/database/stream/StreamStatisticsEntry.kt @ v0.27.x
//
// Query-result type for the statistics query (history grouped by stream, joined
// with the resume position). progress_time comes from a LEFT JOIN so it may be
// absent — defaults to 0, matching Room's @ColumnInfo(defaultValue = "0").

import Foundation
import GRDB

public struct StreamStatisticsEntry: FetchableRecord, Equatable {
    public static let streamLatestDate = "latestAccess"
    public static let streamWatchCount = "watchCount"

    public let streamEntity: StreamEntity
    public let progressMillis: Int64
    public let streamId: Int64
    public let latestAccessDate: Date
    public let watchCount: Int64

    public init(row: Row) {
        streamEntity = StreamEntity(row: row)
        progressMillis = (row["progress_time"] as Int64?) ?? 0
        streamId = row["stream_id"]
        latestAccessDate = Converters.date(fromTimestamp: row["latestAccess"])
        watchCount = row["watchCount"]
    }
}
