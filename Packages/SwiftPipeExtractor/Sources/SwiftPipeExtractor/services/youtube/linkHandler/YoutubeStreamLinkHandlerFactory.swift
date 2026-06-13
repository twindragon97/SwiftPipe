// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/linkHandler/YoutubeStreamLinkHandlerFactory.java @ v0.26.3
//
// java.net.URI's vnd.youtube scheme handling is reproduced with String prefix
// checks (Foundation URL doesn't expose schemeSpecificPart). java.net.URL ->
// Foundation URL.

import Foundation

public final class YoutubeStreamLinkHandlerFactory: LinkHandlerFactory {
    private static let YOUTUBE_VIDEO_ID_REGEX_PATTERN = Pattern.compile("^([a-zA-Z0-9_-]{11})")
    private static let INSTANCE = YoutubeStreamLinkHandlerFactory()
    private static let SUBPATHS = ["embed/", "live/", "shorts/", "watch/", "v/", "w/"]

    public static func getInstance() -> YoutubeStreamLinkHandlerFactory {
        INSTANCE
    }

    private static func extractId(_ id: String?) -> String? {
        guard let id else { return nil }
        let m = YOUTUBE_VIDEO_ID_REGEX_PATTERN.matcher(id)
        return m.find() ? m.group(1) : nil
    }

    private static func assertIsId(_ id: String?) throws -> String {
        guard let extractedId = extractId(id) else {
            throw ParsingException("The given string is not a YouTube video ID")
        }
        return extractedId
    }

    public override func getUrl(_ id: String) throws -> String {
        "https://www.youtube.com/watch?v=" + id
    }

    public override func getId(_ theUrlString: String) throws -> String {
        var urlString = theUrlString

        // vnd.youtube / vnd.youtube.launch scheme handling (Java: java.net.URI)
        for prefix in ["vnd.youtube.launch:", "vnd.youtube:"] where urlString.hasPrefix(prefix) {
            let schemeSpecificPart = String(urlString.dropFirst(prefix.count))
            if schemeSpecificPart.hasPrefix("//") {
                if let extractedId = Self.extractId(String(schemeSpecificPart.dropFirst(2))) {
                    return extractedId
                }
                urlString = "https:" + schemeSpecificPart
            } else {
                return try Self.assertIsId(schemeSpecificPart)
            }
            break
        }

        let url: URL
        do {
            url = try Utils.stringToURL(urlString)
        } catch {
            throw ParsingException("The given URL is not valid")
        }

        let host = url.host ?? ""
        var path = url.path
        // remove leading "/" of URL-path if URL-path is given
        if !path.isEmpty {
            path = String(path.dropFirst())
        }

        if !Utils.isHTTP(url) || !(YoutubeParsingHelper.isYoutubeURL(url)
            || YoutubeParsingHelper.isYoutubeServiceURL(url)
            || YoutubeParsingHelper.isHooktubeURL(url)
            || YoutubeParsingHelper.isInvidiousURL(url)
            || YoutubeParsingHelper.isY2ubeURL(url)) {
            if host.caseInsensitiveEquals("googleads.g.doubleclick.net") {
                throw FoundAdException("Error: found ad: \(urlString)")
            }
            throw ParsingException("The URL is not a YouTube URL")
        }

        if try YoutubePlaylistLinkHandlerFactory.getInstance().acceptUrl(urlString) {
            throw ParsingException("Error: no suitable URL: \(urlString)")
        }

        // Uppercase instead of lowercase to avoid unicode lowercasing quirks
        switch host.uppercased() {
        case "WWW.YOUTUBE-NOCOOKIE.COM":
            if path.hasPrefix("embed/") {
                return try Self.assertIsId(String(path.dropFirst(6)))
            }

        case "YOUTUBE.COM", "WWW.YOUTUBE.COM", "M.YOUTUBE.COM", "MUSIC.YOUTUBE.COM":
            if path == "attribution_link" {
                let uQueryValue = Utils.getQueryValue(url, "u")
                let decodedURL: URL
                do {
                    decodedURL = try Utils.stringToURL(
                        "https://www.youtube.com" + (uQueryValue ?? ""))
                } catch {
                    throw ParsingException("Error: no suitable URL: \(urlString)")
                }
                return try Self.assertIsId(Utils.getQueryValue(decodedURL, "v"))
            }
            if let maybeId = try getIdFromSubpathsInPath(path) {
                return maybeId
            }
            return try Self.assertIsId(Utils.getQueryValue(url, "v"))

        case "Y2U.BE", "YOUTU.BE":
            if let viewQueryValue = Utils.getQueryValue(url, "v") {
                return try Self.assertIsId(viewQueryValue)
            }
            return try Self.assertIsId(path)

        case "HOOKTUBE.COM", "INVIDIO.US", "DEV.INVIDIO.US", "WWW.INVIDIO.US",
             "REDIRECT.INVIDIOUS.IO", "INVIDIOUS.SNOPYTA.ORG", "YEWTU.BE", "TUBE.CONNECT.CAFE",
             "TUBUS.EDUVID.ORG", "INVIDIOUS.KAVIN.ROCKS", "INVIDIOUS-US.KAVIN.ROCKS",
             "PIPED.KAVIN.ROCKS", "INVIDIOUS.SITE", "VID.MINT.LGBT", "INVIDIOU.SITE",
             "INVIDIOUS.FDN.FR", "INVIDIOUS.048596.XYZ", "INVIDIOUS.ZEE.LI", "VID.PUFFYAN.US",
             "YTPRIVATE.COM", "INVIDIOUS.NAMAZSO.EU", "INVIDIOUS.SILKKY.CLOUD",
             "INVIDIOUS.EXONIP.DE", "INV.RIVERSIDE.ROCKS", "INVIDIOUS.BLAMEFRAN.NET",
             "INVIDIOUS.MOOMOO.ME", "YTB.TROM.TF", "YT.CYBERHOST.UK", "Y.COM.CM":
            if path == "watch" {
                if let viewQueryValue = Utils.getQueryValue(url, "v") {
                    return try Self.assertIsId(viewQueryValue)
                }
            }
            if let maybeId = try getIdFromSubpathsInPath(path) {
                return maybeId
            }
            if let viewQueryValue = Utils.getQueryValue(url, "v") {
                return try Self.assertIsId(viewQueryValue)
            }
            return try Self.assertIsId(path)

        default:
            break
        }

        throw ParsingException("Error: no suitable URL: \(urlString)")
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

    private func getIdFromSubpathsInPath(_ path: String) throws -> String? {
        for subpath in Self.SUBPATHS where path.hasPrefix(subpath) {
            let id = String(path.dropFirst(subpath.count))
            return try Self.assertIsId(id)
        }
        return nil
    }
}
