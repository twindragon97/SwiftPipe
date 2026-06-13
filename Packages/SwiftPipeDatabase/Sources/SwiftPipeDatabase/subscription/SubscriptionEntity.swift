// Mirrors: app/src/main/java/org/schabi/newpipe/database/subscription/SubscriptionEntity.kt @ v0.27.x

import GRDB

public struct SubscriptionEntity: FetchableRecord, MutablePersistableRecord, Equatable {
    public static let databaseTableName = "subscriptions"

    public var uid: Int64
    public var serviceId: Int
    public var url: String?
    public var name: String?
    public var avatarUrl: String?
    public var subscriberCount: Int64?
    public var description: String?
    /// One of `NotificationMode.disabled` / `.enabled`.
    public var notificationMode: Int

    public init(
        uid: Int64 = 0,
        serviceId: Int,
        url: String? = nil,
        name: String? = nil,
        avatarUrl: String? = nil,
        subscriberCount: Int64? = nil,
        description: String? = nil,
        notificationMode: Int = NotificationMode.disabled
    ) {
        self.uid = uid
        self.serviceId = serviceId
        self.url = url
        self.name = name
        self.avatarUrl = avatarUrl
        self.subscriberCount = subscriberCount
        self.description = description
        self.notificationMode = notificationMode
    }

    public init(row: Row) {
        uid = row["uid"]
        serviceId = row["service_id"]
        url = row["url"]
        name = row["name"]
        avatarUrl = row["avatar_url"]
        subscriberCount = row["subscriber_count"]
        description = row["description"]
        notificationMode = row["notification_mode"]
    }

    public func encode(to container: inout PersistenceContainer) {
        container["uid"] = uid == 0 ? nil : uid
        container["service_id"] = serviceId
        container["url"] = url
        container["name"] = name
        container["avatar_url"] = avatarUrl
        container["subscriber_count"] = subscriberCount
        container["description"] = description
        container["notification_mode"] = notificationMode
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        uid = inserted.rowID
    }
}
