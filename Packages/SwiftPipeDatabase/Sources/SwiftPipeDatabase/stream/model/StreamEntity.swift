// Mirrors: app/src/main/java/org/schabi/newpipe/database/stream/model/StreamEntity.kt @ v0.27.x
//
// GRDB conformance is written by hand (not Codable-synthesised) so each column
// maps to its exact Room name and the date column is stored as epoch-millis
// INTEGER — GRDB's Codable support would otherwise serialise Date as a text
// timestamp, breaking byte-compatibility with Android.

import Foundation
import GRDB
import SwiftPipeExtractor

public struct StreamEntity: FetchableRecord, MutablePersistableRecord, Equatable {
    public static let databaseTableName = "streams"

    public var uid: Int64
    public var serviceId: Int
    public var url: String
    public var title: String
    public var streamType: StreamType
    public var duration: Int64
    public var uploader: String
    public var uploaderUrl: String?
    public var thumbnailUrl: String?
    public var viewCount: Int64?
    public var textualUploadDate: String?
    public var uploadDate: Date?
    public var isUploadDateApproximation: Bool?

    public init(
        uid: Int64 = 0,
        serviceId: Int,
        url: String,
        title: String,
        streamType: StreamType,
        duration: Int64,
        uploader: String,
        uploaderUrl: String? = nil,
        thumbnailUrl: String? = nil,
        viewCount: Int64? = nil,
        textualUploadDate: String? = nil,
        uploadDate: Date? = nil,
        isUploadDateApproximation: Bool? = nil
    ) {
        self.uid = uid
        self.serviceId = serviceId
        self.url = url
        self.title = title
        self.streamType = streamType
        self.duration = duration
        self.uploader = uploader
        self.uploaderUrl = uploaderUrl
        self.thumbnailUrl = thumbnailUrl
        self.viewCount = viewCount
        self.textualUploadDate = textualUploadDate
        self.uploadDate = uploadDate
        self.isUploadDateApproximation = isUploadDateApproximation
    }

    /// Builds a row from a search/list item. Mirror of the StreamEntity
    /// secondary constructor that takes a StreamInfoItem.
    ///
    /// Deviation: NewPipe stores `thumbnail_url` via ImageStrategy (a single URL
    /// chosen by the user's preferred image-quality setting). That setting and
    /// strategy are not ported yet, so we store the highest-resolution thumbnail
    /// URL. thumbnail_url is a non-authoritative cached value, so this does not
    /// affect Android's ability to import the database.
    public init(item: StreamInfoItem) {
        self.init(
            serviceId: item.getServiceId(),
            url: item.getUrl(),
            title: item.getName(),
            streamType: item.getStreamType(),
            duration: item.getDuration(),
            uploader: item.getUploaderName() ?? "",
            uploaderUrl: item.getUploaderUrl(),
            thumbnailUrl: Self.bestThumbnailUrl(item.getThumbnails()),
            viewCount: item.getViewCount(),
            textualUploadDate: item.getTextualUploadDate(),
            uploadDate: item.getUploadDate()?.offsetDateTime(),
            isUploadDateApproximation: item.getUploadDate()?.isApproximation())
    }

    /// Highest-resolution thumbnail URL, or nil when there are none.
    static func bestThumbnailUrl(_ images: [Image]) -> String? {
        images.max { $0.getHeight() < $1.getHeight() }?.getUrl()
    }

    public init(row: Row) {
        uid = row["uid"]
        serviceId = row["service_id"]
        url = row["url"]
        title = row["title"]
        streamType = Converters.streamType(of: row["stream_type"])
        duration = row["duration"]
        uploader = row["uploader"]
        uploaderUrl = row["uploader_url"]
        thumbnailUrl = row["thumbnail_url"]
        viewCount = row["view_count"]
        textualUploadDate = row["textual_upload_date"]
        uploadDate = (row["upload_date"] as Int64?).map(Converters.date(fromTimestamp:))
        isUploadDateApproximation = row["is_upload_date_approximation"]
    }

    public func encode(to container: inout PersistenceContainer) {
        container["uid"] = uid == 0 ? nil : uid
        container["service_id"] = serviceId
        container["url"] = url
        container["title"] = title
        container["stream_type"] = Converters.string(of: streamType)
        container["duration"] = duration
        container["uploader"] = uploader
        container["uploader_url"] = uploaderUrl
        container["thumbnail_url"] = thumbnailUrl
        container["view_count"] = viewCount
        container["textual_upload_date"] = textualUploadDate
        container["upload_date"] = uploadDate.map(Converters.timestamp(from:))
        container["is_upload_date_approximation"] = isUploadDateApproximation
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        uid = inserted.rowID
    }
}
