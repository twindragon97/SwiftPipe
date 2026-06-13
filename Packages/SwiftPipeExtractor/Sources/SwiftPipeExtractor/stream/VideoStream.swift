// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/stream/VideoStream.java @ v0.26.3

public final class VideoStream: Stream {
    public static let RESOLUTION_UNKNOWN = ""

    /// Deprecated upstream: use getResolution() instead.
    public let resolution: String
    /// Deprecated upstream: use isVideoOnly() instead.
    public let isVideoOnlyValue: Bool

    private var itag = Stream.ITAG_NOT_AVAILABLE_OR_NOT_APPLICABLE
    private var bitrate = 0
    private var initStart = 0
    private var initEnd = 0
    private var indexStart = 0
    private var indexEnd = 0
    private var width = 0
    private var height = 0
    private var fps = 0
    private var quality: String?
    private var codec: String?
    private var itagItem: ItagItem?

    /// Class to build VideoStream objects.
    public final class Builder {
        fileprivate var id: String?
        fileprivate var content: String?
        fileprivate var isUrl = false
        fileprivate var deliveryMethod = DeliveryMethod.PROGRESSIVE_HTTP
        fileprivate var mediaFormat: MediaFormat?
        fileprivate var manifestUrl: String?
        fileprivate var isVideoOnly: Bool?
        fileprivate var resolution: String?
        fileprivate var itagItem: ItagItem?

        public init() {}

        @discardableResult
        public func setId(_ id: String) -> Builder {
            self.id = id
            return self
        }

        @discardableResult
        public func setContent(_ content: String, _ isUrl: Bool) -> Builder {
            self.content = content
            self.isUrl = isUrl
            return self
        }

        @discardableResult
        public func setMediaFormat(_ mediaFormat: MediaFormat?) -> Builder {
            self.mediaFormat = mediaFormat
            return self
        }

        @discardableResult
        public func setDeliveryMethod(_ deliveryMethod: DeliveryMethod) -> Builder {
            self.deliveryMethod = deliveryMethod
            return self
        }

        @discardableResult
        public func setManifestUrl(_ manifestUrl: String?) -> Builder {
            self.manifestUrl = manifestUrl
            return self
        }

        @discardableResult
        public func setIsVideoOnly(_ isVideoOnly: Bool) -> Builder {
            self.isVideoOnly = isVideoOnly
            return self
        }

        @discardableResult
        public func setResolution(_ resolution: String) -> Builder {
            self.resolution = resolution
            return self
        }

        @discardableResult
        public func setItagItem(_ itagItem: ItagItem?) -> Builder {
            self.itagItem = itagItem
            return self
        }

        public func build() -> VideoStream {
            precondition(id != nil,
                "The identifier of the video stream has been not set or is null. If you "
                + "are not able to get an identifier, use the static constant "
                + "ID_UNKNOWN of the Stream class.")
            precondition(content != nil,
                "The content of the video stream has been not set "
                + "or is null. Please specify a non-null one with setContent.")
            precondition(isVideoOnly != nil,
                "The video stream has been not set as a "
                + "video-only stream or as a video stream with embedded audio. Please "
                + "specify this information with setIsVideoOnly.")
            precondition(resolution != nil,
                "The resolution of the video stream has been not set. Please specify it "
                + "with setResolution (use an empty string if you are not able to "
                + "get it).")
            return VideoStream(
                id!, content!, isUrl, mediaFormat, deliveryMethod, resolution!,
                isVideoOnly!, manifestUrl, itagItem)
        }
    }

    private init(
        _ id: String,
        _ content: String,
        _ isUrl: Bool,
        _ format: MediaFormat?,
        _ deliveryMethod: DeliveryMethod,
        _ resolution: String,
        _ isVideoOnly: Bool,
        _ manifestUrl: String?,
        _ itagItem: ItagItem?
    ) {
        if let itagItem {
            self.itagItem = itagItem
            self.itag = itagItem.id
            self.bitrate = itagItem.getBitrate()
            self.initStart = itagItem.getInitStart()
            self.initEnd = itagItem.getInitEnd()
            self.indexStart = itagItem.getIndexStart()
            self.indexEnd = itagItem.getIndexEnd()
            self.codec = itagItem.getCodec()
            self.height = itagItem.getHeight()
            self.width = itagItem.getWidth()
            self.quality = itagItem.getQuality()
            self.fps = itagItem.getFps()
        }
        self.resolution = resolution
        self.isVideoOnlyValue = isVideoOnly
        super.init(id, content, isUrl, format, deliveryMethod, manifestUrl)
    }

    public override func equalStats(_ cmp: Stream?) -> Bool {
        guard super.equalStats(cmp), let cmp = cmp as? VideoStream else { return false }
        return resolution == cmp.resolution && isVideoOnlyValue == cmp.isVideoOnlyValue
    }

    /// The video resolution, or RESOLUTION_UNKNOWN.
    public func getResolution() -> String { resolution }

    /// Whether the stream is video-only (no embedded audio).
    public func isVideoOnly() -> Bool { isVideoOnlyValue }

    public func getItag() -> Int { itag }
    public func getBitrate() -> Int { bitrate }
    public func getInitStart() -> Int { initStart }
    public func getInitEnd() -> Int { initEnd }
    public func getIndexStart() -> Int { indexStart }
    public func getIndexEnd() -> Int { indexEnd }
    public func getWidth() -> Int { width }
    public func getHeight() -> Int { height }
    public func getFps() -> Int { fps }
    public func getQuality() -> String? { quality }
    public func getCodec() -> String? { codec }

    public override func getItagItem() -> ItagItem? { itagItem }
}
