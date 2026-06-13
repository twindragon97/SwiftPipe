// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/linkHandler/YoutubeChannelLinkHandlerFactory.java @ v0.26.3

import Foundation

public final class YoutubeChannelLinkHandlerFactory: ListLinkHandlerFactory {
    private static let INSTANCE = YoutubeChannelLinkHandlerFactory()
    private static let EXCLUDED_SEGMENTS = Pattern.compile(
        "playlist|watch|attribution_link|watch_popup|embed|feed|select_site|account"
        + "|reporthistory|redirect")

    public static func getInstance() -> YoutubeChannelLinkHandlerFactory {
        INSTANCE
    }

    public override func getUrl(
        _ id: String, _ contentFilters: [String], _ searchFilter: String
    ) throws -> String {
        "https://www.youtube.com/" + id
    }

    private func isCustomShortChannelUrl(_ splitPath: [String]) -> Bool {
        splitPath.count == 1 && !splitPath[0].isEmpty
            && !EXCLUDED_SEGMENTS_matches(splitPath[0])
    }

    private func EXCLUDED_SEGMENTS_matches(_ s: String) -> Bool {
        Self.EXCLUDED_SEGMENTS.matcher(s).matches()
    }

    private func isHandle(_ splitPath: [String]) -> Bool {
        !splitPath.isEmpty && splitPath[0].hasPrefix("@")
    }

    public override func getId(_ url: String) throws -> String {
        do {
            let urlObj = try Utils.stringToURL(url)
            var path = urlObj.path
            if !Utils.isHTTP(urlObj) || !(YoutubeParsingHelper.isYoutubeURL(urlObj)
                || YoutubeParsingHelper.isInvidiousURL(urlObj)
                || YoutubeParsingHelper.isHooktubeURL(urlObj)) {
                throw ParsingException("The URL given is not a YouTube URL")
            }
            // Remove leading "/"
            path = String(path.dropFirst())
            let splitPath = path.components(separatedBy: "/")
            if isHandle(splitPath) || isCustomShortChannelUrl(splitPath) {
                // YouTube handle URLs like youtube.com/@yourhandle and custom
                // short channel URLs like youtube.com/yourcustomname
                return splitPath[0]
            }
            if !path.hasPrefix("user/") && !path.hasPrefix("channel/")
                && !path.hasPrefix("c/") {
                throw ParsingException("The given URL is not a channel, a user or a handle URL")
            }
            let id = splitPath.count > 1 ? splitPath[1] : ""
            if Utils.isBlank(id) {
                throw ParsingException("The given ID is not a YouTube channel or user ID")
            }
            return splitPath[0] + "/" + id
        } catch let e as ParsingException {
            throw e
        } catch {
            throw ParsingException("Could not parse URL :\(error)")
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
}
