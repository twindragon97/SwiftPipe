// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/linkHandler/YoutubeChannelTabLinkHandlerFactory.java @ v0.26.3

public final class YoutubeChannelTabLinkHandlerFactory: ListLinkHandlerFactory {
    private static let INSTANCE = YoutubeChannelTabLinkHandlerFactory()

    public static func getInstance() -> YoutubeChannelTabLinkHandlerFactory {
        INSTANCE
    }

    public static func getUrlSuffix(_ tab: String) throws -> String {
        switch tab {
        case ChannelTabs.VIDEOS: return "/videos"
        case ChannelTabs.SHORTS: return "/shorts"
        case ChannelTabs.LIVESTREAMS: return "/streams"
        case ChannelTabs.ALBUMS: return "/releases"
        case ChannelTabs.PLAYLISTS: return "/playlists"
        default: throw UnsupportedTabException(tab)
        }
    }

    public override func getUrl(
        _ id: String, _ contentFilter: [String], _ sortFilter: String
    ) throws -> String {
        "https://www.youtube.com/" + id + (try Self.getUrlSuffix(contentFilter[0]))
    }

    public override func getId(_ url: String) throws -> String {
        try YoutubeChannelLinkHandlerFactory.getInstance().getId(url)
    }

    public override func onAcceptUrl(_ url: String) throws -> Bool {
        do {
            _ = try getId(url)
        } catch is ParsingException {
            return false
        }
        return true
    }

    public override func getAvailableContentFilter() -> [String] {
        [
            ChannelTabs.VIDEOS,
            ChannelTabs.SHORTS,
            ChannelTabs.LIVESTREAMS,
            ChannelTabs.ALBUMS,
            ChannelTabs.PLAYLISTS,
        ]
    }
}
