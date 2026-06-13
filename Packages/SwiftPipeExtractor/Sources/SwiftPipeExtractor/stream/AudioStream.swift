// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/stream/AudioStream.java @ v0.26.3
//
// java.util.Locale maps to Foundation Locale. IllegalStateException in
// build() maps to preconditionFailure with the same messages.

import Foundation

public final class AudioStream: Stream {
    public static let UNKNOWN_BITRATE = -1

    private let averageBitrate: Int
    // Fields for DASH
    private var itag = Stream.ITAG_NOT_AVAILABLE_OR_NOT_APPLICABLE
    private var bitrate = 0
    private var initStart = 0
    private var initEnd = 0
    private var indexStart = 0
    private var indexEnd = 0
    private var quality: String?
    private var codec: String?
    // Fields about the audio track id/name
    private let audioTrackId: String?
    private let audioTrackName: String?
    private let audioLocale: Locale?
    private let audioTrackType: AudioTrackType?
    private var itagItem: ItagItem?

    /// Class to build AudioStream objects.
    public final class Builder {
        fileprivate var id: String?
        fileprivate var content: String?
        fileprivate var isUrl = false
        fileprivate var deliveryMethod = DeliveryMethod.PROGRESSIVE_HTTP
        fileprivate var mediaFormat: MediaFormat?
        fileprivate var manifestUrl: String?
        fileprivate var averageBitrate = AudioStream.UNKNOWN_BITRATE
        fileprivate var audioTrackId: String?
        fileprivate var audioTrackName: String?
        fileprivate var audioLocale: Locale?
        fileprivate var audioTrackType: AudioTrackType?
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
        public func setAverageBitrate(_ averageBitrate: Int) -> Builder {
            self.averageBitrate = averageBitrate
            return self
        }

        @discardableResult
        public func setAudioTrackId(_ audioTrackId: String?) -> Builder {
            self.audioTrackId = audioTrackId
            return self
        }

        @discardableResult
        public func setAudioTrackName(_ audioTrackName: String?) -> Builder {
            self.audioTrackName = audioTrackName
            return self
        }

        @discardableResult
        public func setAudioTrackType(_ audioTrackType: AudioTrackType?) -> Builder {
            self.audioTrackType = audioTrackType
            return self
        }

        @discardableResult
        public func setAudioLocale(_ audioLocale: Locale?) -> Builder {
            self.audioLocale = audioLocale
            return self
        }

        @discardableResult
        public func setItagItem(_ itagItem: ItagItem?) -> Builder {
            self.itagItem = itagItem
            return self
        }

        public func build() -> AudioStream {
            validateBuild()
            return AudioStream(self)
        }

        func validateBuild() {
            precondition(id != nil,
                "The identifier of the audio stream has been not set or is null. If you "
                + "are not able to get an identifier, use the static constant "
                + "ID_UNKNOWN of the Stream class.")
            precondition(content != nil,
                "The content of the audio stream has been not set "
                + "or is null. Please specify a non-null one with setContent.")
        }
    }

    init(_ builder: Builder) {
        if let itagItem = builder.itagItem {
            self.itagItem = itagItem
            self.itag = itagItem.id
            self.quality = itagItem.getQuality()
            self.bitrate = itagItem.getBitrate()
            self.initStart = itagItem.getInitStart()
            self.initEnd = itagItem.getInitEnd()
            self.indexStart = itagItem.getIndexStart()
            self.indexEnd = itagItem.getIndexEnd()
            self.codec = itagItem.getCodec()
        }
        self.averageBitrate = builder.averageBitrate
        self.audioTrackId = builder.audioTrackId
        self.audioTrackName = builder.audioTrackName
        self.audioLocale = builder.audioLocale
        self.audioTrackType = builder.audioTrackType
        super.init(
            builder.id!,
            builder.content!,
            builder.isUrl,
            builder.mediaFormat,
            builder.deliveryMethod,
            builder.manifestUrl)
    }

    public override func equalStats(_ cmp: Stream?) -> Bool {
        guard super.equalStats(cmp), let cmp = cmp as? AudioStream else { return false }
        return averageBitrate == cmp.averageBitrate
            && audioTrackId == cmp.audioTrackId
            && audioTrackType == cmp.audioTrackType
            && audioLocale == cmp.audioLocale
    }

    /// The average bitrate, or UNKNOWN_BITRATE.
    public func getAverageBitrate() -> Int { averageBitrate }

    /// The itag identifier; ITAG_NOT_AVAILABLE_OR_NOT_APPLICABLE outside YouTube.
    public func getItag() -> Int { itag }

    public func getBitrate() -> Int { bitrate }
    public func getInitStart() -> Int { initStart }
    public func getInitEnd() -> Int { initEnd }
    public func getIndexStart() -> Int { indexStart }
    public func getIndexEnd() -> Int { indexEnd }
    public func getQuality() -> String? { quality }
    public func getCodec() -> String? { codec }

    public func getAudioTrackId() -> String? { audioTrackId }
    public func getAudioTrackName() -> String? { audioTrackName }
    public func getAudioLocale() -> Locale? { audioLocale }
    public func getAudioTrackType() -> AudioTrackType? { audioTrackType }

    public override func getItagItem() -> ItagItem? { itagItem }
}
