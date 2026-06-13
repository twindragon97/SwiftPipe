// Mirrors: app/src/main/java/org/schabi/newpipe/database/feed/model/FeedEntity.kt @ v0.27.x

import GRDB

public struct FeedEntity: FetchableRecord, PersistableRecord, Equatable {
    public static let databaseTableName = "feed"

    public var streamId: Int64
    public var subscriptionId: Int64

    public init(streamId: Int64, subscriptionId: Int64) {
        self.streamId = streamId
        self.subscriptionId = subscriptionId
    }

    public init(row: Row) {
        streamId = row["stream_id"]
        subscriptionId = row["subscription_id"]
    }

    public func encode(to container: inout PersistenceContainer) {
        container["stream_id"] = streamId
        container["subscription_id"] = subscriptionId
    }
}
