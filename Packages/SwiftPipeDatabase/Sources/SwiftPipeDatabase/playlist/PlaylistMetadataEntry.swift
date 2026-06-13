// Mirrors: app/src/main/java/org/schabi/newpipe/database/playlist/PlaylistMetadataEntry.kt @ v0.27.x
//
// Query-result type for the local-playlist list: a playlist plus its derived
// thumbnail URL (from the thumbnail stream) and stream count.

import GRDB

public struct PlaylistMetadataEntry: FetchableRecord, Equatable {
    public static let playlistStreamCount = "streamCount"

    public let uid: Int64
    public let orderingName: String?
    public let thumbnailUrl: String?
    public let displayIndex: Int64?
    public let isThumbnailPermanent: Bool?
    public let thumbnailStreamId: Int64?
    public let streamCount: Int64

    public init(row: Row) {
        uid = row["uid"]
        orderingName = row["name"]
        thumbnailUrl = row["thumbnail_url"]
        displayIndex = row["display_index"]
        isThumbnailPermanent = row["is_thumbnail_permanent"]
        thumbnailStreamId = row["thumbnail_stream_id"]
        streamCount = row["streamCount"]
    }
}
