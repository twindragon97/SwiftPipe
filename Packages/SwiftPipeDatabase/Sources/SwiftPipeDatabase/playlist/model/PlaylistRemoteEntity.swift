// Mirrors: app/src/main/java/org/schabi/newpipe/database/playlist/model/PlaylistRemoteEntity.kt @ v0.27.x

import GRDB

public struct PlaylistRemoteEntity: FetchableRecord, MutablePersistableRecord, Equatable {
    public static let databaseTableName = "remote_playlists"

    public var uid: Int64
    public var serviceId: Int
    /// Column `name` (Kotlin field `orderingName`).
    public var orderingName: String?
    public var url: String?
    public var thumbnailUrl: String?
    public var uploader: String?
    /// -1 puts a freshly added playlist at the top.
    public var displayIndex: Int64
    public var streamCount: Int64?

    public init(
        uid: Int64 = 0,
        serviceId: Int,
        orderingName: String?,
        url: String?,
        thumbnailUrl: String?,
        uploader: String?,
        displayIndex: Int64 = -1,
        streamCount: Int64?
    ) {
        self.uid = uid
        self.serviceId = serviceId
        self.orderingName = orderingName
        self.url = url
        self.thumbnailUrl = thumbnailUrl
        self.uploader = uploader
        self.displayIndex = displayIndex
        self.streamCount = streamCount
    }

    public init(row: Row) {
        uid = row["uid"]
        serviceId = row["service_id"]
        orderingName = row["name"]
        url = row["url"]
        thumbnailUrl = row["thumbnail_url"]
        uploader = row["uploader"]
        displayIndex = row["display_index"]
        streamCount = row["stream_count"]
    }

    public func encode(to container: inout PersistenceContainer) {
        container["uid"] = uid == 0 ? nil : uid
        container["service_id"] = serviceId
        container["name"] = orderingName
        container["url"] = url
        container["thumbnail_url"] = thumbnailUrl
        container["uploader"] = uploader
        container["display_index"] = displayIndex
        container["stream_count"] = streamCount
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        uid = inserted.rowID
    }
}
