// Mirrors: app/src/main/java/org/schabi/newpipe/database/playlist/model/PlaylistEntity.kt @ v0.27.x

import GRDB

public struct PlaylistEntity: FetchableRecord, PersistableRecord, Equatable {
    public static let databaseTableName = "playlists"

    public static let defaultThumbnailId: Int64 = -1

    public var uid: Int64
    public var name: String?
    public var isThumbnailPermanent: Bool
    public var thumbnailStreamId: Int64
    public var displayIndex: Int64

    public init(
        uid: Int64 = 0,
        name: String?,
        isThumbnailPermanent: Bool,
        thumbnailStreamId: Int64,
        displayIndex: Int64
    ) {
        self.uid = uid
        self.name = name
        self.isThumbnailPermanent = isThumbnailPermanent
        self.thumbnailStreamId = thumbnailStreamId
        self.displayIndex = displayIndex
    }

    public init(row: Row) {
        uid = row["uid"]
        name = row["name"]
        isThumbnailPermanent = row["is_thumbnail_permanent"]
        thumbnailStreamId = row["thumbnail_stream_id"]
        displayIndex = row["display_index"]
    }

    public func encode(to container: inout PersistenceContainer) {
        container["uid"] = uid == 0 ? nil : uid
        container["name"] = name
        container["is_thumbnail_permanent"] = isThumbnailPermanent
        container["thumbnail_stream_id"] = thumbnailStreamId
        container["display_index"] = displayIndex
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        uid = inserted.rowID
    }
}
