// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/ItagItem.java @ v0.26.3

import Foundation

public final class ItagItem {
    private static let ITAG_LIST: [ItagItem] = [
        // VIDEO         ID  Format          Resolution  (FPS)
        ItagItem(17, .VIDEO, .v3GPP, "144p"),
        ItagItem(36, .VIDEO, .v3GPP, "240p"),
        ItagItem(18, .VIDEO, .MPEG_4, "360p"),
        ItagItem(34, .VIDEO, .MPEG_4, "360p"),
        ItagItem(35, .VIDEO, .MPEG_4, "480p"),
        ItagItem(59, .VIDEO, .MPEG_4, "480p"),
        ItagItem(78, .VIDEO, .MPEG_4, "480p"),
        ItagItem(22, .VIDEO, .MPEG_4, "720p"),
        ItagItem(37, .VIDEO, .MPEG_4, "1080p"),
        ItagItem(38, .VIDEO, .MPEG_4, "1080p"),
        ItagItem(43, .VIDEO, .WEBM, "360p"),
        ItagItem(44, .VIDEO, .WEBM, "480p"),
        ItagItem(45, .VIDEO, .WEBM, "720p"),
        ItagItem(46, .VIDEO, .WEBM, "1080p"),
        // AUDIO         ID   Format        Bitrate
        ItagItem(171, .AUDIO, .WEBMA, 128),
        ItagItem(172, .AUDIO, .WEBMA, 256),
        ItagItem(599, .AUDIO, .M4A, 32),
        ItagItem(139, .AUDIO, .M4A, 48),
        ItagItem(140, .AUDIO, .M4A, 128),
        ItagItem(141, .AUDIO, .M4A, 256),
        ItagItem(600, .AUDIO, .WEBMA_OPUS, 35),
        ItagItem(249, .AUDIO, .WEBMA_OPUS, 50),
        ItagItem(250, .AUDIO, .WEBMA_OPUS, 70),
        ItagItem(251, .AUDIO, .WEBMA_OPUS, 160),
        // VIDEO ONLY    ID        Format   Resolution  (FPS)
        ItagItem(160, .VIDEO_ONLY, .MPEG_4, "144p"),
        ItagItem(394, .VIDEO_ONLY, .MPEG_4, "144p"),
        ItagItem(133, .VIDEO_ONLY, .MPEG_4, "240p"),
        ItagItem(395, .VIDEO_ONLY, .MPEG_4, "240p"),
        ItagItem(134, .VIDEO_ONLY, .MPEG_4, "360p"),
        ItagItem(396, .VIDEO_ONLY, .MPEG_4, "360p"),
        ItagItem(135, .VIDEO_ONLY, .MPEG_4, "480p"),
        ItagItem(212, .VIDEO_ONLY, .MPEG_4, "480p"),
        ItagItem(397, .VIDEO_ONLY, .MPEG_4, "480p"),
        ItagItem(136, .VIDEO_ONLY, .MPEG_4, "720p"),
        ItagItem(398, .VIDEO_ONLY, .MPEG_4, "720p"),
        ItagItem(298, .VIDEO_ONLY, .MPEG_4, "720p60", 60),
        ItagItem(137, .VIDEO_ONLY, .MPEG_4, "1080p"),
        ItagItem(399, .VIDEO_ONLY, .MPEG_4, "1080p"),
        ItagItem(299, .VIDEO_ONLY, .MPEG_4, "1080p60", 60),
        ItagItem(400, .VIDEO_ONLY, .MPEG_4, "1440p"),
        ItagItem(266, .VIDEO_ONLY, .MPEG_4, "2160p"),
        ItagItem(401, .VIDEO_ONLY, .MPEG_4, "2160p"),
        ItagItem(278, .VIDEO_ONLY, .WEBM, "144p"),
        ItagItem(242, .VIDEO_ONLY, .WEBM, "240p"),
        ItagItem(243, .VIDEO_ONLY, .WEBM, "360p"),
        ItagItem(244, .VIDEO_ONLY, .WEBM, "480p"),
        ItagItem(245, .VIDEO_ONLY, .WEBM, "480p"),
        ItagItem(246, .VIDEO_ONLY, .WEBM, "480p"),
        ItagItem(247, .VIDEO_ONLY, .WEBM, "720p"),
        ItagItem(248, .VIDEO_ONLY, .WEBM, "1080p"),
        ItagItem(271, .VIDEO_ONLY, .WEBM, "1440p"),
        // #272 is either 3840x2160 (e.g. RtoitU2A-3E) or 7680x4320 (sLprVF6d7Ug)
        ItagItem(272, .VIDEO_ONLY, .WEBM, "2160p"),
        ItagItem(302, .VIDEO_ONLY, .WEBM, "720p60", 60),
        ItagItem(303, .VIDEO_ONLY, .WEBM, "1080p60", 60),
        ItagItem(308, .VIDEO_ONLY, .WEBM, "1440p60", 60),
        ItagItem(313, .VIDEO_ONLY, .WEBM, "2160p"),
        ItagItem(315, .VIDEO_ONLY, .WEBM, "2160p60", 60),
    ]

    // MARK: Utils

    public static func isSupported(_ itag: Int) -> Bool {
        ITAG_LIST.contains { $0.id == itag }
    }

    public static func getItag(_ itagId: Int) throws -> ItagItem {
        guard let item = ITAG_LIST.first(where: { $0.id == itagId }) else {
            throw ParsingException("itag \(itagId) is not supported")
        }
        return ItagItem(item)
    }

    // MARK: Static constants

    public static let AVERAGE_BITRATE_UNKNOWN = -1
    public static let SAMPLE_RATE_UNKNOWN = -1
    public static let FPS_NOT_APPLICABLE_OR_UNKNOWN = -1
    public static let TARGET_DURATION_SEC_UNKNOWN = -1
    public static let AUDIO_CHANNELS_NOT_APPLICABLE_OR_UNKNOWN = -1
    public static let CONTENT_LENGTH_UNKNOWN: Int64 = -1
    public static let APPROX_DURATION_MS_UNKNOWN: Int64 = -1
    public static let LAST_MODIFIED_UNKOWN: Int64 = -1 // (sic) upstream typo

    public enum ItagType {
        case AUDIO
        case VIDEO
        case VIDEO_ONLY
    }

    // MARK: Constructors

    public init(_ id: Int, _ type: ItagType, _ format: MediaFormat, _ resolution: String) {
        self.id = id
        self.itagType = type
        self.mediaFormat = format
        self.resolutionString = resolution
        self.fps = 30
    }

    public init(
        _ id: Int, _ type: ItagType, _ format: MediaFormat, _ resolution: String, _ fps: Int
    ) {
        self.id = id
        self.itagType = type
        self.mediaFormat = format
        self.resolutionString = resolution
        self.fps = fps
    }

    public init(_ id: Int, _ type: ItagType, _ format: MediaFormat, _ avgBitrate: Int) {
        self.id = id
        self.itagType = type
        self.mediaFormat = format
        self.avgBitrate = avgBitrate
    }

    /// Copy constructor.
    public init(_ itagItem: ItagItem) {
        self.mediaFormat = itagItem.mediaFormat
        self.id = itagItem.id
        self.itagType = itagItem.itagType
        self.avgBitrate = itagItem.avgBitrate
        self.sampleRate = itagItem.sampleRate
        self.audioChannels = itagItem.audioChannels
        self.resolutionString = itagItem.resolutionString
        self.fps = itagItem.fps
        self.bitrate = itagItem.bitrate
        self.width = itagItem.width
        self.height = itagItem.height
        self.initStart = itagItem.initStart
        self.initEnd = itagItem.initEnd
        self.indexStart = itagItem.indexStart
        self.indexEnd = itagItem.indexEnd
        self.quality = itagItem.quality
        self.codec = itagItem.codec
        self.targetDurationSec = itagItem.targetDurationSec
        self.approxDurationMs = itagItem.approxDurationMs
        self.contentLength = itagItem.contentLength
        self.audioTrackId = itagItem.audioTrackId
        self.audioTrackName = itagItem.audioTrackName
        self.audioTrackType = itagItem.audioTrackType
        self.audioLocale = itagItem.audioLocale
    }

    public func getMediaFormat() -> MediaFormat {
        mediaFormat
    }

    private let mediaFormat: MediaFormat
    public let id: Int
    public let itagType: ItagType

    // Audio fields
    /// Deprecated upstream: use getAverageBitrate() instead.
    public var avgBitrate = ItagItem.AVERAGE_BITRATE_UNKNOWN
    private var sampleRate = ItagItem.SAMPLE_RATE_UNKNOWN
    private var audioChannels = ItagItem.AUDIO_CHANNELS_NOT_APPLICABLE_OR_UNKNOWN

    // Video fields
    /// Deprecated upstream: use getResolutionString() instead.
    public var resolutionString: String?
    /// Deprecated upstream: use getFps()/setFps() instead.
    public var fps = ItagItem.FPS_NOT_APPLICABLE_OR_UNKNOWN

    // Fields for DASH
    private var bitrate = 0
    private var width = 0
    private var height = 0
    private var initStart = 0
    private var initEnd = 0
    private var indexStart = 0
    private var indexEnd = 0
    private var quality: String?
    private var codec: String?
    private var targetDurationSec = ItagItem.TARGET_DURATION_SEC_UNKNOWN
    private var approxDurationMs = ItagItem.APPROX_DURATION_MS_UNKNOWN
    private var contentLength = ItagItem.CONTENT_LENGTH_UNKNOWN
    private var audioTrackId: String?
    private var audioTrackName: String?
    private var audioTrackType: AudioTrackType?
    private var audioLocale: Locale?
    private var isDrcValue = false
    private var lastModified: Int64 = 0
    private var xtags: String?

    public func getBitrate() -> Int { bitrate }
    public func setBitrate(_ bitrate: Int) { self.bitrate = bitrate }

    public func getWidth() -> Int { width }
    public func setWidth(_ width: Int) { self.width = width }

    public func getHeight() -> Int { height }
    public func setHeight(_ height: Int) { self.height = height }

    public func getFps() -> Int { fps }
    public func setFps(_ fps: Int) {
        self.fps = fps > 0 ? fps : ItagItem.FPS_NOT_APPLICABLE_OR_UNKNOWN
    }

    public func getInitStart() -> Int { initStart }
    public func setInitStart(_ initStart: Int) { self.initStart = initStart }

    public func getInitEnd() -> Int { initEnd }
    public func setInitEnd(_ initEnd: Int) { self.initEnd = initEnd }

    public func getIndexStart() -> Int { indexStart }
    public func setIndexStart(_ indexStart: Int) { self.indexStart = indexStart }

    public func getIndexEnd() -> Int { indexEnd }
    public func setIndexEnd(_ indexEnd: Int) { self.indexEnd = indexEnd }

    public func getQuality() -> String? { quality }
    public func setQuality(_ quality: String?) { self.quality = quality }

    public func getResolutionString() -> String? { resolutionString }

    public func getCodec() -> String? { codec }
    public func setCodec(_ codec: String?) { self.codec = codec }

    public func getAverageBitrate() -> Int { avgBitrate }

    public func getSampleRate() -> Int { sampleRate }
    public func setSampleRate(_ sampleRate: Int) {
        self.sampleRate = sampleRate > 0 ? sampleRate : ItagItem.SAMPLE_RATE_UNKNOWN
    }

    public func getAudioChannels() -> Int { audioChannels }
    public func setAudioChannels(_ audioChannels: Int) {
        self.audioChannels = audioChannels > 0
            ? audioChannels
            : ItagItem.AUDIO_CHANNELS_NOT_APPLICABLE_OR_UNKNOWN
    }

    public func getTargetDurationSec() -> Int { targetDurationSec }
    public func setTargetDurationSec(_ targetDurationSec: Int) {
        self.targetDurationSec = targetDurationSec > 0
            ? targetDurationSec
            : ItagItem.TARGET_DURATION_SEC_UNKNOWN
    }

    public func getApproxDurationMs() -> Int64 { approxDurationMs }
    public func setApproxDurationMs(_ approxDurationMs: Int64) {
        self.approxDurationMs = approxDurationMs > 0
            ? approxDurationMs
            : ItagItem.APPROX_DURATION_MS_UNKNOWN
    }

    public func getContentLength() -> Int64 { contentLength }
    public func setContentLength(_ contentLength: Int64) {
        self.contentLength = contentLength > 0
            ? contentLength
            : ItagItem.CONTENT_LENGTH_UNKNOWN
    }

    public func getAudioTrackId() -> String? { audioTrackId }
    public func setAudioTrackId(_ audioTrackId: String?) {
        self.audioTrackId = audioTrackId
    }

    public func getAudioTrackName() -> String? { audioTrackName }
    public func setAudioTrackName(_ audioTrackName: String?) {
        self.audioTrackName = audioTrackName
    }

    public func getAudioTrackType() -> AudioTrackType? { audioTrackType }
    public func setAudioTrackType(_ audioTrackType: AudioTrackType?) {
        self.audioTrackType = audioTrackType
    }

    public func getAudioLocale() -> Locale? { audioLocale }
    public func setAudioLocale(_ audioLocale: Locale?) {
        self.audioLocale = audioLocale
    }

    public func isDrc() -> Bool { isDrcValue }
    public func setIsDrc(_ isDrc: Bool) { self.isDrcValue = isDrc }

    public func getLastModified() -> Int64 { lastModified }
    public func setLastModified(_ lastModified: Int64) { self.lastModified = lastModified }

    public func getXtags() -> String? { xtags }
    public func setXtags(_ xtags: String?) { self.xtags = xtags }
}
