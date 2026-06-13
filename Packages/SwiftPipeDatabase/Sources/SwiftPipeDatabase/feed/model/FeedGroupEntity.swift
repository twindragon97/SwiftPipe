// Mirrors: app/src/main/java/org/schabi/newpipe/database/feed/model/FeedGroupEntity.kt @ v0.27.x

import GRDB

public struct FeedGroupEntity: FetchableRecord, MutablePersistableRecord, Equatable {
    public static let databaseTableName = "feed_group"

    /// uid of the synthetic "All" group.
    public static let groupAllId: Int64 = -1

    public var uid: Int64
    public var name: String
    /// Stored as INTEGER `icon_id` (FeedGroupIcon.rawValue).
    public var icon: FeedGroupIcon
    public var sortOrder: Int64

    public init(uid: Int64 = 0, name: String, icon: FeedGroupIcon, sortOrder: Int64 = -1) {
        self.uid = uid
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
    }

    public init(row: Row) {
        uid = row["uid"]
        name = row["name"]
        icon = FeedGroupIcon(rawValue: row["icon_id"]) ?? .all
        sortOrder = row["sort_order"]
    }

    public func encode(to container: inout PersistenceContainer) {
        container["uid"] = uid == 0 ? nil : uid
        container["name"] = name
        container["icon_id"] = icon.id
        container["sort_order"] = sortOrder
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        uid = inserted.rowID
    }
}
