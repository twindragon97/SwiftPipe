// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/linkHandler/YoutubeCommentsLinkHandlerFactory.java @ v0.26.3

public final class YoutubeCommentsLinkHandlerFactory: ListLinkHandlerFactory {
    private static let INSTANCE = YoutubeCommentsLinkHandlerFactory()

    public static func getInstance() -> YoutubeCommentsLinkHandlerFactory {
        INSTANCE
    }

    public override func getUrl(_ id: String) throws -> String {
        "https://www.youtube.com/watch?v=" + id
    }

    public override func getId(_ urlString: String) throws -> String {
        // We need the same id, avoids duplicate code
        try YoutubeStreamLinkHandlerFactory.getInstance().getId(urlString)
    }

    public override func onAcceptUrl(_ url: String) throws -> Bool {
        do {
            _ = try getId(url)
            return true
        } catch let fe as FoundAdException {
            throw fe
        } catch is ParsingException {
            return false
        }
    }

    public override func getUrl(
        _ id: String, _ contentFilter: [String], _ sortFilter: String
    ) throws -> String {
        try getUrl(id)
    }
}
