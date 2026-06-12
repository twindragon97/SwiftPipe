// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/MediaFormat.java @ v0.26.3
//
// Java enum constants carry (id, name, suffix, mimeType) fields; Swift cases
// expose them via computed properties from a single table. Lookup helpers
// preserve declaration order (e.g. 0x200 resolves to WEBMA, not WEBMA_OPUS).

public enum MediaFormat: CaseIterable {
    // video and audio combined formats
    case MPEG_4
    case v3GPP
    case WEBM
    // audio formats
    case M4A
    case WEBMA
    case MP3
    case MP2
    case OPUS
    case OGG
    case WEBMA_OPUS
    case AIFF
    /// Same as AIFF, just with the shorter suffix/file extension
    case AIF
    case WAV
    case FLAC
    case ALAC
    // subtitles formats
    case VTT
    case TTML
    case TRANSCRIPT1
    case TRANSCRIPT2
    case TRANSCRIPT3
    case SRT

    private var fields: (id: Int, name: String, suffix: String, mimeType: String) {
        switch self {
        case .MPEG_4: return (0x0, "MPEG-4", "mp4", "video/mp4")
        case .v3GPP: return (0x10, "3GPP", "3gp", "video/3gpp")
        case .WEBM: return (0x20, "WebM", "webm", "video/webm")
        case .M4A: return (0x100, "m4a", "m4a", "audio/mp4")
        case .WEBMA: return (0x200, "WebM", "webm", "audio/webm")
        case .MP3: return (0x300, "MP3", "mp3", "audio/mpeg")
        case .MP2: return (0x310, "MP2", "mp2", "audio/mpeg")
        case .OPUS: return (0x400, "opus", "opus", "audio/opus")
        case .OGG: return (0x500, "ogg", "ogg", "audio/ogg")
        case .WEBMA_OPUS: return (0x200, "WebM Opus", "webm", "audio/webm")
        case .AIFF: return (0x600, "AIFF", "aiff", "audio/aiff")
        case .AIF: return (0x600, "AIFF", "aif", "audio/aiff")
        case .WAV: return (0x700, "WAV", "wav", "audio/wav")
        case .FLAC: return (0x800, "FLAC", "flac", "audio/flac")
        case .ALAC: return (0x900, "ALAC", "alac", "audio/alac")
        case .VTT: return (0x1000, "WebVTT", "vtt", "text/vtt")
        case .TTML: return (0x2000, "Timed Text Markup Language", "ttml", "application/ttml+xml")
        case .TRANSCRIPT1: return (0x3000, "TranScript v1", "srv1", "text/xml")
        case .TRANSCRIPT2: return (0x4000, "TranScript v2", "srv2", "text/xml")
        case .TRANSCRIPT3: return (0x5000, "TranScript v3", "srv3", "text/xml")
        case .SRT: return (0x6000, "SubRip file format", "srt", "text/srt")
        }
    }

    public var id: Int { fields.id }
    public var name: String { fields.name }
    public var suffix: String { fields.suffix }
    public var mimeType: String { fields.mimeType }

    /// The friendly name of the media format with the supplied id, or "".
    public static func getNameById(_ id: Int) -> String {
        allCases.first { $0.id == id }?.name ?? ""
    }

    /// The file extension of the media format with the supplied id, or "".
    public static func getSuffixById(_ id: Int) -> String {
        allCases.first { $0.id == id }?.suffix ?? ""
    }

    /// The MIME type of the media format with the supplied id, or nil.
    public static func getMimeById(_ id: Int) -> String? {
        allCases.first { $0.id == id }?.mimeType
    }

    /// The first MediaFormat with the supplied mime type, or nil.
    public static func getFromMimeType(_ mimeType: String) -> MediaFormat? {
        allCases.first { $0.mimeType == mimeType }
    }

    /// All media formats which have the given mime type.
    public static func getAllFromMimeType(_ mimeType: String) -> [MediaFormat] {
        allCases.filter { $0.mimeType == mimeType }
    }

    /// The media format with the given id, or nil.
    public static func getFormatById(_ id: Int) -> MediaFormat? {
        allCases.first { $0.id == id }
    }

    /// The first media format that has the given suffix, or nil.
    public static func getFromSuffix(_ suffix: String) -> MediaFormat? {
        allCases.first { $0.suffix == suffix }
    }

    public func getName() -> String { name }
    public func getSuffix() -> String { suffix }
    public func getMimeType() -> String { mimeType }
}
