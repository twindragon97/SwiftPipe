// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/stream/Stream.java @ v0.26.3

open class Stream {
    public static let FORMAT_ID_UNKNOWN = -1
    public static let ID_UNKNOWN = " "

    /// The itag ID is not available (YouTube; should never happen) or not
    /// applicable (other services).
    public static let ITAG_NOT_AVAILABLE_OR_NOT_APPLICABLE = -1

    private let id: String
    private let mediaFormat: MediaFormat?
    private let content: String
    private let isUrlValue: Bool
    private let deliveryMethod: DeliveryMethod
    private let manifestUrl: String?

    /// - Parameters:
    ///   - id: identifier which uniquely identifies the file, e.g. for
    ///     YouTube this would be the itag
    ///   - content: the content or URL, depending on whether isUrl is true
    ///   - isUrl: whether content is the URL or the actual content of e.g. a
    ///     DASH manifest
    ///   - format: the MediaFormat, which can be nil
    ///   - deliveryMethod: the delivery method of the stream
    ///   - manifestUrl: the URL of the manifest this stream comes from (if
    ///     applicable, otherwise nil)
    public init(
        _ id: String,
        _ content: String,
        _ isUrl: Bool,
        _ format: MediaFormat?,
        _ deliveryMethod: DeliveryMethod,
        _ manifestUrl: String?
    ) {
        self.id = id
        self.content = content
        self.isUrlValue = isUrl
        self.mediaFormat = format
        self.deliveryMethod = deliveryMethod
        self.manifestUrl = manifestUrl
    }

    /// Checks if the list already contains a stream with the same statistics.
    public static func containSimilarStream(
        _ stream: Stream, _ streamList: [Stream]?
    ) -> Bool {
        guard let streamList, !streamList.isEmpty else { return false }
        return streamList.contains { stream.equalStats($0) }
    }

    /// Whether two streams have the same statistics (media format and
    /// delivery method). Always false if the stream passed is nil.
    public func equalStats(_ other: Stream?) -> Bool {
        guard let other, let mediaFormat, let otherFormat = other.mediaFormat else {
            return false
        }
        return mediaFormat.id == otherFormat.id
            && deliveryMethod == other.deliveryMethod
            && isUrlValue == other.isUrlValue
    }

    /// The identifier of this stream (e.g. the itag for YouTube); may be
    /// ID_UNKNOWN.
    public func getId() -> String {
        id
    }

    /// The URL if the content is a URL, nil otherwise.
    /// - Note: deprecated upstream; use getContent() instead.
    public func getUrl() -> String? {
        isUrlValue ? content : nil
    }

    /// The content or URL.
    public func getContent() -> String {
        content
    }

    /// Whether the content of this stream is a URL (true) or the actual
    /// content (false).
    public func isUrl() -> Bool {
        isUrlValue
    }

    /// The MediaFormat, which can be nil.
    public func getFormat() -> MediaFormat? {
        mediaFormat
    }

    /// The format ID or FORMAT_ID_UNKNOWN.
    public func getFormatId() -> Int {
        mediaFormat?.id ?? Stream.FORMAT_ID_UNKNOWN
    }

    public func getDeliveryMethod() -> DeliveryMethod {
        deliveryMethod
    }

    /// The URL of the manifest this stream comes from (if applicable,
    /// otherwise nil).
    public func getManifestUrl() -> String? {
        manifestUrl
    }

    /// The ItagItem of a stream; always nil for non-YouTube services.
    open func getItagItem() -> ItagItem? {
        preconditionFailure("Stream.getItagItem must be overridden")
    }
}
