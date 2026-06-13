// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/StreamingService.java @ v0.26.3
//
// getFeedExtractor returns nil by default (Java). Abstract methods become
// open methods that trap until overridden by a concrete service.

import TimeAgoParser

open class StreamingService: CustomStringConvertible {
    /// Holds meta information about the service implementation.
    public final class ServiceInfo {
        private let name: String
        private let mediaCapabilities: Set<MediaCapability>

        public init(_ name: String, _ mediaCapabilities: Set<MediaCapability>) {
            self.name = name
            self.mediaCapabilities = mediaCapabilities
        }

        public func getName() -> String { name }
        public func getMediaCapabilities() -> Set<MediaCapability> { mediaCapabilities }

        public enum MediaCapability {
            case AUDIO, VIDEO, LIVE, COMMENTS
        }
    }

    /// Determines which type of URL is being handled.
    public enum LinkType {
        case NONE
        case STREAM
        case CHANNEL
        case PLAYLIST
    }

    private let serviceId: Int
    private let serviceInfo: ServiceInfo

    /// Creates a new streaming service. Set the id when putting the service
    /// into ServiceList, not within the implementation.
    public init(_ id: Int, _ name: String, _ capabilities: Set<ServiceInfo.MediaCapability>) {
        self.serviceId = id
        self.serviceInfo = ServiceInfo(name, capabilities)
    }

    public final func getServiceId() -> Int {
        serviceId
    }

    public func getServiceInfo() -> ServiceInfo {
        serviceInfo
    }

    public var description: String {
        "\(serviceId):\(serviceInfo.getName())"
    }

    open func getBaseUrl() -> String {
        preconditionFailure("StreamingService.getBaseUrl must be overridden")
    }

    // MARK: Url Id handler

    open func getStreamLHFactory() -> LinkHandlerFactory {
        preconditionFailure("StreamingService.getStreamLHFactory must be overridden")
    }

    open func getChannelLHFactory() -> ListLinkHandlerFactory? {
        preconditionFailure("StreamingService.getChannelLHFactory must be overridden")
    }

    open func getChannelTabLHFactory() -> ListLinkHandlerFactory? {
        preconditionFailure("StreamingService.getChannelTabLHFactory must be overridden")
    }

    open func getPlaylistLHFactory() -> ListLinkHandlerFactory? {
        preconditionFailure("StreamingService.getPlaylistLHFactory must be overridden")
    }

    open func getSearchQHFactory() -> SearchQueryHandlerFactory {
        preconditionFailure("StreamingService.getSearchQHFactory must be overridden")
    }

    open func getCommentsLHFactory() -> ListLinkHandlerFactory? {
        preconditionFailure("StreamingService.getCommentsLHFactory must be overridden")
    }

    // MARK: Extractors

    open func getSearchExtractor(_ queryHandler: SearchQueryHandler) -> SearchExtractor {
        preconditionFailure("StreamingService.getSearchExtractor must be overridden")
    }

    open func getSuggestionExtractor() -> SuggestionExtractor {
        preconditionFailure("StreamingService.getSuggestionExtractor must be overridden")
    }

    open func getSubscriptionExtractor() -> SubscriptionExtractor? {
        preconditionFailure("StreamingService.getSubscriptionExtractor must be overridden")
    }

    open func getFeedExtractor(_ url: String) throws -> FeedExtractor? {
        nil
    }

    open func getKioskList() throws -> KioskList {
        preconditionFailure("StreamingService.getKioskList must be overridden")
    }

    open func getChannelExtractor(_ linkHandler: ListLinkHandler) throws -> ChannelExtractor {
        preconditionFailure("StreamingService.getChannelExtractor must be overridden")
    }

    open func getChannelTabExtractor(
        _ linkHandler: ListLinkHandler
    ) throws -> ChannelTabExtractor {
        preconditionFailure("StreamingService.getChannelTabExtractor must be overridden")
    }

    open func getPlaylistExtractor(_ linkHandler: ListLinkHandler) throws -> PlaylistExtractor {
        preconditionFailure("StreamingService.getPlaylistExtractor must be overridden")
    }

    open func getStreamExtractor(_ linkHandler: LinkHandler) throws -> StreamExtractor {
        preconditionFailure("StreamingService.getStreamExtractor must be overridden")
    }

    open func getCommentsExtractor(_ linkHandler: ListLinkHandler) throws -> CommentsExtractor {
        preconditionFailure("StreamingService.getCommentsExtractor must be overridden")
    }

    // MARK: Extractors without link handler

    public func getSearchExtractor(
        _ query: String, _ contentFilter: [String], _ sortFilter: String
    ) throws -> SearchExtractor {
        getSearchExtractor(
            try getSearchQHFactory().fromQuery(query, contentFilter, sortFilter))
    }

    public func getChannelExtractor(
        _ id: String, _ contentFilter: [String], _ sortFilter: String
    ) throws -> ChannelExtractor {
        try getChannelExtractor(
            try getChannelLHFactory()!.fromQuery(id, contentFilter, sortFilter))
    }

    public func getPlaylistExtractor(
        _ id: String, _ contentFilter: [String], _ sortFilter: String
    ) throws -> PlaylistExtractor {
        try getPlaylistExtractor(
            try getPlaylistLHFactory()!.fromQuery(id, contentFilter, sortFilter))
    }

    // MARK: Short extractors overloads

    public func getSearchExtractor(_ query: String) throws -> SearchExtractor {
        getSearchExtractor(try getSearchQHFactory().fromQuery(query))
    }

    public func getChannelExtractor(_ url: String) throws -> ChannelExtractor {
        try getChannelExtractor(try getChannelLHFactory()!.fromUrl(url))
    }

    public func getChannelTabExtractorFromId(
        _ id: String, _ tab: String
    ) throws -> ChannelTabExtractor {
        try getChannelTabExtractor(try getChannelTabLHFactory()!.fromQuery(id, [tab], ""))
    }

    public func getChannelTabExtractorFromIdAndBaseUrl(
        _ id: String, _ tab: String, _ baseUrl: String
    ) throws -> ChannelTabExtractor {
        try getChannelTabExtractor(
            try getChannelTabLHFactory()!.fromQuery(id, [tab], "", baseUrl))
    }

    public func getPlaylistExtractor(_ url: String) throws -> PlaylistExtractor {
        try getPlaylistExtractor(try getPlaylistLHFactory()!.fromUrl(url))
    }

    public func getStreamExtractor(_ url: String) throws -> StreamExtractor {
        try getStreamExtractor(try getStreamLHFactory().fromUrl(url))
    }

    public func getCommentsExtractor(_ url: String) throws -> CommentsExtractor? {
        guard let listLinkHandlerFactory = getCommentsLHFactory() else {
            return nil
        }
        return try getCommentsExtractor(try listLinkHandlerFactory.fromUrl(url))
    }

    // MARK: Utils

    /// Figures out where the link is pointing to (a channel, a video, a
    /// playlist, etc.).
    public final func getLinkTypeByUrl(_ url: String) throws -> LinkType {
        let polishedUrl = Utils.followGoogleRedirectIfNeeded(url)
        let sH = getStreamLHFactory()
        let cH = getChannelLHFactory()
        let pH = getPlaylistLHFactory()

        if try sH.acceptUrl(polishedUrl) {
            return .STREAM
        } else if let cH, try cH.acceptUrl(polishedUrl) {
            return .CHANNEL
        } else if let pH, try pH.acceptUrl(polishedUrl) {
            return .PLAYLIST
        } else {
            return .NONE
        }
    }

    // MARK: Localization

    open func getSupportedLocalizations() -> [Localization] {
        [Localization.DEFAULT]
    }

    open func getSupportedCountries() -> [ContentCountry] {
        [ContentCountry.DEFAULT]
    }

    /// The localization that should be used in this service, falling back to
    /// a language-only match and finally Localization.DEFAULT.
    public func getLocalization() -> Localization {
        let preferredLocalization = NewPipe.getPreferredLocalization()
        // Check the localization's language and country
        if getSupportedLocalizations().contains(preferredLocalization) {
            return preferredLocalization
        }
        // Fallback to the first supported language that matches the preferred language
        for supportedLanguage in getSupportedLocalizations()
        where supportedLanguage.getLanguageCode() == preferredLocalization.getLanguageCode() {
            return supportedLanguage
        }
        return Localization.DEFAULT
    }

    /// The country that should be used to fetch content, falling back to
    /// ContentCountry.DEFAULT.
    public func getContentCountry() -> ContentCountry {
        let preferredContentCountry = NewPipe.getPreferredContentCountry()
        if getSupportedCountries().contains(preferredContentCountry) {
            return preferredContentCountry
        }
        return ContentCountry.DEFAULT
    }

    /// A time-ago parser using the patterns for the given localization, with
    /// a fallback to a less specific localization.
    public func getTimeAgoParser(_ localization: Localization) -> TimeAgoParser {
        if let targetParser = TimeAgoPatternsManager.getTimeAgoParserFor(localization) {
            return targetParser
        }
        if !localization.getCountryCode().isEmpty {
            let lessSpecificLocalization = Localization(localization.getLanguageCode())
            if let lessSpecificParser =
                TimeAgoPatternsManager.getTimeAgoParserFor(lessSpecificLocalization) {
                return lessSpecificParser
            }
        }
        preconditionFailure("Localization is not supported (\"\(localization)\")")
    }
}
