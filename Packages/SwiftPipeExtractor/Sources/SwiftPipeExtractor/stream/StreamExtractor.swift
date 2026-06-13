// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/stream/StreamExtractor.java @ v0.26.3

import Foundation

open class StreamExtractor: Extractor {
    public static let NO_AGE_LIMIT = 0
    public static let UNKNOWN_SUBSCRIBER_COUNT: Int64 = -1

    public override init(_ service: StreamingService, _ linkHandler: LinkHandler) {
        super.init(service, linkHandler)
    }

    open func getTextualUploadDate() throws -> String? {
        nil
    }

    open func getUploadDate() throws -> DateWrapper? {
        nil
    }

    open func getThumbnails() throws -> [Image] {
        preconditionFailure("StreamExtractor.getThumbnails must be overridden")
    }

    open func getDescription() throws -> Description {
        Description.EMPTY_DESCRIPTION
    }

    open func getAgeLimit() throws -> Int {
        StreamExtractor.NO_AGE_LIMIT
    }

    open func getLength() throws -> Int64 {
        0
    }

    open func getTimeStamp() throws -> Int64 {
        0
    }

    open func getViewCount() throws -> Int64 {
        -1
    }

    open func getLikeCount() throws -> Int64 {
        -1
    }

    open func getDislikeCount() throws -> Int64 {
        -1
    }

    open func getUploaderUrl() throws -> String {
        preconditionFailure("StreamExtractor.getUploaderUrl must be overridden")
    }

    open func getUploaderName() throws -> String {
        preconditionFailure("StreamExtractor.getUploaderName must be overridden")
    }

    open func isUploaderVerified() throws -> Bool {
        false
    }

    open func getUploaderSubscriberCount() throws -> Int64 {
        StreamExtractor.UNKNOWN_SUBSCRIBER_COUNT
    }

    open func getUploaderAvatars() throws -> [Image] {
        []
    }

    open func getSubChannelUrl() throws -> String {
        ""
    }

    open func getSubChannelName() throws -> String {
        ""
    }

    open func getSubChannelAvatars() throws -> [Image] {
        []
    }

    open func getDashMpdUrl() throws -> String {
        ""
    }

    open func getHlsUrl() throws -> String {
        ""
    }

    open func getAudioStreams() throws -> [AudioStream] {
        preconditionFailure("StreamExtractor.getAudioStreams must be overridden")
    }

    open func getVideoStreams() throws -> [VideoStream] {
        preconditionFailure("StreamExtractor.getVideoStreams must be overridden")
    }

    open func getVideoOnlyStreams() throws -> [VideoStream] {
        preconditionFailure("StreamExtractor.getVideoOnlyStreams must be overridden")
    }

    open func getSubtitlesDefault() throws -> [SubtitlesStream] {
        []
    }

    open func getSubtitles(_ format: MediaFormat) throws -> [SubtitlesStream] {
        []
    }

    open func getStreamType() throws -> StreamType {
        preconditionFailure("StreamExtractor.getStreamType must be overridden")
    }

    open func getRelatedItems() throws -> (any AnyInfoItemsCollector)? {
        nil
    }

    /// Deprecated upstream: use getRelatedItems() instead.
    open func getRelatedStreams() throws -> StreamInfoItemsCollector? {
        try getRelatedItems() as? StreamInfoItemsCollector
    }

    open func getFrames() throws -> [Frameset] {
        []
    }

    open func getErrorMessage() -> String? {
        nil
    }

    // MARK: Helper

    public func getTimestampSeconds(_ regexPattern: String) throws -> Int64 {
        let timestamp: String
        do {
            timestamp = try Parser.matchGroup1(regexPattern, try getOriginalUrl())
        } catch is Parser.RegexException {
            // catch this instantly since a url does not necessarily have a timestamp
            // -2 because the testing system will consequently know that the regex failed
            return -2
        }

        if !timestamp.isEmpty {
            do {
                var secondsString = ""
                var minutesString = ""
                var hoursString = ""
                do {
                    secondsString = try Parser.matchGroup1("(\\d+)s", timestamp)
                    minutesString = try Parser.matchGroup1("(\\d+)m", timestamp)
                    hoursString = try Parser.matchGroup1("(\\d+)h", timestamp)
                } catch {
                    // it could be that time is given in another method
                    if secondsString.isEmpty && minutesString.isEmpty {
                        // if nothing was obtained, treat as unlabelled seconds
                        secondsString = try Parser.matchGroup1("t=(\\d+)", timestamp)
                    }
                }
                let seconds = secondsString.isEmpty ? 0 : (Int(secondsString) ?? 0)
                let minutes = minutesString.isEmpty ? 0 : (Int(minutesString) ?? 0)
                let hours = hoursString.isEmpty ? 0 : (Int(hoursString) ?? 0)
                return Int64(seconds) + (60 * Int64(minutes)) + (3600 * Int64(hours))
            } catch let e as ParsingException {
                throw ParsingException("Could not get timestamp.", e)
            }
        } else {
            return 0
        }
    }

    open func getHost() throws -> String {
        ""
    }

    open func getPrivacy() throws -> Privacy {
        .PUBLIC
    }

    open func getCategory() throws -> String {
        ""
    }

    open func getLicence() throws -> String {
        ""
    }

    open func getLanguageInfo() throws -> Locale? {
        nil
    }

    open func getTags() throws -> [String] {
        []
    }

    open func getSupportInfo() throws -> String {
        ""
    }

    open func getStreamSegments() throws -> [StreamSegment] {
        []
    }

    open func getMetaInfo() throws -> [MetaInfo] {
        []
    }

    open func isShortFormContent() throws -> Bool {
        false
    }

    open func getContentAvailability() throws -> ContentAvailability {
        .UNKNOWN
    }

    public enum Privacy {
        case PUBLIC
        case UNLISTED
        case PRIVATE
        case INTERNAL
        case OTHER
    }
}
