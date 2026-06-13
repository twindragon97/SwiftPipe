// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/YoutubeService.java @ v0.26.3
//
// Sub-batch 9d-search wires the link-handler factories and the search
// extractor. Extractors not yet ported (stream, channel, channel-tab,
// playlist, comments, suggestion, kiosk trending, subscription, feed) are
// stubbed with preconditionFailure("TODO ...") / empty results, to be filled
// in 9e (stream) and 9f (rest). None are reached by the search path.

public final class YoutubeService: StreamingService {
    public init(_ id: Int) {
        super.init(id, "YouTube", [.AUDIO, .VIDEO, .LIVE, .COMMENTS])
    }

    public override func getBaseUrl() -> String {
        "https://youtube.com"
    }

    public override func getStreamLHFactory() -> LinkHandlerFactory {
        YoutubeStreamLinkHandlerFactory.getInstance()
    }

    public override func getChannelLHFactory() -> ListLinkHandlerFactory? {
        YoutubeChannelLinkHandlerFactory.getInstance()
    }

    public override func getChannelTabLHFactory() -> ListLinkHandlerFactory? {
        YoutubeChannelTabLinkHandlerFactory.getInstance()
    }

    public override func getPlaylistLHFactory() -> ListLinkHandlerFactory? {
        YoutubePlaylistLinkHandlerFactory.getInstance()
    }

    public override func getSearchQHFactory() -> SearchQueryHandlerFactory {
        YoutubeSearchQueryHandlerFactory.getInstance()
    }

    public override func getStreamExtractor(_ linkHandler: LinkHandler) throws -> StreamExtractor {
        // TODO(9e): return YoutubeStreamExtractor(self, linkHandler)
        preconditionFailure("YoutubeStreamExtractor not ported yet (9e)")
    }

    public override func getChannelExtractor(
        _ linkHandler: ListLinkHandler
    ) throws -> ChannelExtractor {
        // TODO(9f): return YoutubeChannelExtractor(self, linkHandler)
        preconditionFailure("YoutubeChannelExtractor not ported yet (9f)")
    }

    public override func getChannelTabExtractor(
        _ linkHandler: ListLinkHandler
    ) throws -> ChannelTabExtractor {
        // TODO(9f): ReadyChannelTabListLinkHandler / YoutubeChannelTabExtractor
        preconditionFailure("YoutubeChannelTabExtractor not ported yet (9f)")
    }

    public override func getPlaylistExtractor(
        _ linkHandler: ListLinkHandler
    ) throws -> PlaylistExtractor {
        // TODO(9f): YoutubeMixPlaylistExtractor / YoutubePlaylistExtractor
        preconditionFailure("YoutubePlaylistExtractor not ported yet (9f)")
    }

    public override func getSearchExtractor(_ query: SearchQueryHandler) -> SearchExtractor {
        // TODO(9f): music_ filters should use YoutubeMusicSearchExtractor
        YoutubeSearchExtractor(self, query)
    }

    public override func getSuggestionExtractor() -> SuggestionExtractor {
        // TODO(9f): return YoutubeSuggestionExtractor(self)
        preconditionFailure("YoutubeSuggestionExtractor not ported yet (9f)")
    }

    public override func getKioskList() throws -> KioskList {
        // TODO(9f): register trending / live kiosks once their extractors are ported
        KioskList(self)
    }

    public override func getSubscriptionExtractor() -> SubscriptionExtractor? {
        // TODO(9f): return YoutubeSubscriptionExtractor(self)
        nil
    }

    public override func getCommentsLHFactory() -> ListLinkHandlerFactory? {
        YoutubeCommentsLinkHandlerFactory.getInstance()
    }

    public override func getCommentsExtractor(
        _ linkHandler: ListLinkHandler
    ) throws -> CommentsExtractor {
        // TODO(9f): return YoutubeCommentsExtractor(self, linkHandler)
        preconditionFailure("YoutubeCommentsExtractor not ported yet (9f)")
    }

    // MARK: Localization

    // https://www.youtube.com/picker_ajax?action_language_json=1
    // The full language list is commented out upstream; only en-GB is active.
    private static let SUPPORTED_LANGUAGES = Localization.listFrom("en-GB")

    // https://www.youtube.com/picker_ajax?action_country_json=1
    private static let SUPPORTED_COUNTRIES = ContentCountry.listFrom(
        "DZ", "AR", "AU", "AT", "AZ", "BH", "BD", "BY", "BE", "BO", "BA", "BR", "BG", "KH",
        "CA", "CL", "CO", "CR", "HR", "CY", "CZ", "DK", "DO", "EC", "EG", "SV", "EE", "FI",
        "FR", "GE", "DE", "GH", "GR", "GT", "HN", "HK", "HU", "IS", "IN", "ID", "IQ", "IE",
        "IL", "IT", "JM", "JP", "JO", "KZ", "KE", "KW", "LA", "LV", "LB", "LY", "LI", "LT",
        "LU", "MY", "MT", "MX", "ME", "MA", "NP", "NL", "NZ", "NI", "NG", "MK", "NO", "OM",
        "PK", "PA", "PG", "PY", "PE", "PH", "PL", "PT", "PR", "QA", "RO", "RU", "SA", "SN",
        "RS", "SG", "SK", "SI", "ZA", "KR", "ES", "LK", "SE", "CH", "TW", "TZ", "TH", "TN",
        "TR", "UG", "UA", "AE", "GB", "US", "UY", "VE", "VN", "YE", "ZW")

    public override func getSupportedLocalizations() -> [Localization] {
        Self.SUPPORTED_LANGUAGES
    }

    public override func getSupportedCountries() -> [ContentCountry] {
        Self.SUPPORTED_COUNTRIES
    }
}
