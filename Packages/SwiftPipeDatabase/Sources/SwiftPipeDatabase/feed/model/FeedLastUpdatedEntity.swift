// Mirrors: app/src/main/java/org/schabi/newpipe/database/feed/model/FeedLastUpdatedEntity.kt @ v0.27.x

import Foundation
import GRDB

public struct FeedLastUpdatedEntity: FetchableRecord, MutablePersistableRecord, Equatable {
    public static let databaseTableName = "feed_last_updated"

    public var subscriptionId: Int64
    /// Stored as epoch-millis (UTC). Nullable to match Room.
    public var lastUpdated: Date?

    public init(subscriptionId: Int64, lastUpdated: Date? = nil) {
        self.subscriptionId = subscriptionId
        self.lastUpdated = lastUpdated
    }

    public init(row: Row) {
        subscriptionId = row["subscription_id"]
        lastUpdated = (row["last_updated"] as Int64?).map(Converters.date(fromTimestamp:))
    }

    public func encode(to container: inout PersistenceContainer) {
        container["subscription_id"] = subscriptionId
        container["last_updated"] = lastUpdated.map(Converters.timestamp(from:))
    }
}
