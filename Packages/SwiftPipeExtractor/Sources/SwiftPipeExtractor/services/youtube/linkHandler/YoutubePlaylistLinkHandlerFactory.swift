// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/linkHandler/YoutubePlaylistLinkHandlerFactory.java @ v0.26.3

import Foundation

public final class YoutubePlaylistLinkHandlerFactory: ListLinkHandlerFactory {
    private static let INSTANCE = YoutubePlaylistLinkHandlerFactory()
    private static let LIST_ID_PATTERN = Pattern.compile("[a-zA-Z0-9_-]{10,}")

    public static func getInstance() -> YoutubePlaylistLinkHandlerFactory {
        INSTANCE
    }

    public override func getUrl(
        _ id: String, _ contentFilters: [String], _ sortFilter: String
    ) throws -> String {
        "https://www.youtube.com/playlist?list=" + id
    }

    public override func getId(_ url: String) throws -> String {
        do {
            let urlObj = try Utils.stringToURL(url)
            if !Utils.isHTTP(urlObj) || !(YoutubeParsingHelper.isYoutubeURL(urlObj)
                || YoutubeParsingHelper.isInvidiousURL(urlObj)) {
                throw ParsingException("the url given is not a YouTube-URL")
            }
            let path = urlObj.path
            if path != "/watch" && path != "/playlist" {
                throw ParsingException("the url given is neither a video nor a playlist URL")
            }
            guard let listID = Utils.getQueryValue(urlObj, "list") else {
                throw ParsingException("the URL given does not include a playlist")
            }
            if !Self.LIST_ID_PATTERN.matcher(listID).matches() {
                throw ParsingException(
                    "the list-ID given in the URL does not match the list pattern")
            }
            return listID
        } catch let e as ParsingException {
            throw e
        } catch {
            throw ParsingException("Error could not parse URL: \(error)")
        }
    }

    public override func onAcceptUrl(_ url: String) throws -> Bool {
        do {
            _ = try getId(url)
        } catch is ParsingException {
            return false
        }
        return true
    }

    public override func fromUrl(_ url: String) throws -> ListLinkHandler {
        do {
            let urlObj = try Utils.stringToURL(url)
            if let listID = Utils.getQueryValue(urlObj, "list"),
               YoutubeParsingHelper.isYoutubeMixId(listID) {
                var videoID = Utils.getQueryValue(urlObj, "v")
                if videoID == nil {
                    videoID = try YoutubeParsingHelper.extractVideoIdFromMixId(listID)
                }
                let newUrl = "https://www.youtube.com/watch?v=" + (videoID ?? "")
                    + "&list=" + listID
                return ListLinkHandler(LinkHandler(url, newUrl, listID))
            }
        } catch is Utils.MalformedURLException {
            throw ParsingException("Error could not parse URL")
        }
        return try super.fromUrl(url)
    }
}
