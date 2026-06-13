// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/stream/StreamInfoItem.java @ v0.26.3

public final class StreamInfoItem: InfoItem {
    private let streamType: StreamType
    private var uploaderName: String?
    private var shortDescription: String?
    private var textualUploadDate: String?
    private var uploadDate: DateWrapper?
    private var viewCount: Int64 = -1
    private var duration: Int64 = -1
    private var uploaderUrl: String?
    private var uploaderAvatars: [Image] = []
    private var uploaderVerified = false
    private var shortFormContent = false
    private var contentAvailability: ContentAvailability = .AVAILABLE

    public init(
        _ serviceId: Int,
        _ url: String,
        _ name: String,
        _ streamType: StreamType
    ) {
        self.streamType = streamType
        super.init(.STREAM, serviceId, url, name)
    }

    public func getStreamType() -> StreamType { streamType }

    public func getUploaderName() -> String? { uploaderName }
    public func setUploaderName(_ uploaderName: String?) { self.uploaderName = uploaderName }

    public func getViewCount() -> Int64 { viewCount }
    public func setViewCount(_ viewCount: Int64) { self.viewCount = viewCount }

    public func getDuration() -> Int64 { duration }
    public func setDuration(_ duration: Int64) { self.duration = duration }

    public func getUploaderUrl() -> String? { uploaderUrl }
    public func setUploaderUrl(_ uploaderUrl: String?) { self.uploaderUrl = uploaderUrl }

    public func getUploaderAvatars() -> [Image] { uploaderAvatars }
    public func setUploaderAvatars(_ uploaderAvatars: [Image]) {
        self.uploaderAvatars = uploaderAvatars
    }

    public func getShortDescription() -> String? { shortDescription }
    public func setShortDescription(_ shortDescription: String?) {
        self.shortDescription = shortDescription
    }

    public func getTextualUploadDate() -> String? { textualUploadDate }
    public func setTextualUploadDate(_ textualUploadDate: String?) {
        self.textualUploadDate = textualUploadDate
    }

    public func getUploadDate() -> DateWrapper? { uploadDate }
    public func setUploadDate(_ uploadDate: DateWrapper?) { self.uploadDate = uploadDate }

    public func isUploaderVerified() -> Bool { uploaderVerified }
    public func setUploaderVerified(_ uploaderVerified: Bool) {
        self.uploaderVerified = uploaderVerified
    }

    public func isShortFormContent() -> Bool { shortFormContent }
    public func setShortFormContent(_ shortFormContent: Bool) {
        self.shortFormContent = shortFormContent
    }

    public func getContentAvailability() -> ContentAvailability { contentAvailability }
    public func setContentAvailability(_ availability: ContentAvailability) {
        self.contentAvailability = availability
    }

    public override var description: String {
        "StreamInfoItem{"
            + "streamType=\(streamType)"
            + ", uploaderName='\(uploaderName ?? "null")'"
            + ", textualUploadDate='\(textualUploadDate ?? "null")'"
            + ", viewCount=\(viewCount)"
            + ", duration=\(duration)"
            + ", uploaderUrl='\(uploaderUrl ?? "null")'"
            + ", infoType=\(getInfoType())"
            + ", serviceId=\(getServiceId())"
            + ", url='\(getUrl())'"
            + ", name='\(getName())'"
            + ", thumbnails='\(getThumbnails())'"
            + ", uploaderVerified='\(isUploaderVerified())'"
            + "}"
    }
}
