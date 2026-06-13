// Mirrors: app/src/main/java/org/schabi/newpipe/database/history/model/StreamHistoryEntity.kt @ v0.27.x

import Foundation
import GRDB

public struct StreamHistoryEntity: FetchableRecord, MutablePersistableRecord, Equatable {
    public static let databaseTableName = "stream_history"

    public var streamUid: Int64
    /// Last time the stream was accessed. Stored as epoch-millis (UTC).
    public var accessDate: Date
    /// Total number of views this stream received.
    public var repeatCount: Int64

    public init(streamUid: Int64, accessDate: Date, repeatCount: Int64) {
        self.streamUid = streamUid
        self.accessDate = accessDate
        self.repeatCount = repeatCount
    }

    public init(row: Row) {
        streamUid = row["stream_id"]
        accessDate = Converters.date(fromTimestamp: row["access_date"])
        repeatCount = row["repeat_count"]
    }

    public func encode(to container: inout PersistenceContainer) {
        container["stream_id"] = streamUid
        container["access_date"] = Converters.timestamp(from: accessDate)
        container["repeat_count"] = repeatCount
    }
}
