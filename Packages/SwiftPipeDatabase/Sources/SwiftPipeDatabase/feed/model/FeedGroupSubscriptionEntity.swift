// Mirrors: app/src/main/java/org/schabi/newpipe/database/feed/model/FeedGroupSubscriptionEntity.kt @ v0.27.x

import GRDB

public struct FeedGroupSubscriptionEntity: FetchableRecord, PersistableRecord, Equatable {
    public static let databaseTableName = "feed_group_subscription_join"

    public var feedGroupId: Int64
    public var subscriptionId: Int64

    public init(feedGroupId: Int64, subscriptionId: Int64) {
        self.feedGroupId = feedGroupId
        self.subscriptionId = subscriptionId
    }

    public init(row: Row) {
        feedGroupId = row["group_id"]
        subscriptionId = row["subscription_id"]
    }

    public func encode(to container: inout PersistenceContainer) {
        container["group_id"] = feedGroupId
        container["subscription_id"] = subscriptionId
    }
}
