// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/YoutubeParsingHelper.java @ v0.26.3
//
// Deviations:
//  - extractAudioTrackType is stubbed to return nil until swift-protobuf and
//    the Xtags .proto are wired (TODO P3/downloads). It only affects audio
//    track typing of YouTube formats.
//  - getTextFromObject(html:) uses a local jsoup-base HTML escaper instead of
//    jsoup's Entities.escape (escapes & < > "); revisit for byte-exact
//    description HTML when descriptions land (P6).
//  - getClientVersionFromServiceTrackingParam takes the JsonArray (not a Java
//    Stream) and recomputes per call, since the Java code reuses a one-shot
//    Stream twice (a latent upstream bug avoided here).
//  - java.net.URL -> Foundation URL; global statics -> enum static vars
//    (single-threaded use, like the Java statics).

import Foundation
import NanoJSON

public enum YoutubeParsingHelper {
    /// Base URL of WEB-client requests to the InnerTube internal API.
    public static let YOUTUBEI_V1_URL = "https://www.youtube.com/youtubei/v1/"
    /// Base URL of non-web-client requests to the InnerTube internal API.
    public static let YOUTUBEI_V1_GAPIS_URL = "https://youtubei.googleapis.com/youtubei/v1/"

    private static let YOUTUBE_MUSIC_URL = "https://music.youtube.com"

    /// Disables the pretty-printed InnerTube response, to reduce response size.
    public static let DISABLE_PRETTY_PRINT_PARAMETER = "prettyPrint=false"

    public static let CPN = "cpn"
    public static let VIDEO_ID = "videoId"
    public static let CONTENT_CHECK_OK = "contentCheckOk"
    public static let RACY_CHECK_OK = "racyCheckOk"

    private static var clientVersion: String?
    private static var youtubeMusicClientVersion: String?
    private static var clientVersionExtracted = false
    private static var hardcodedClientVersionValid: Bool?

    private static let INNERTUBE_CONTEXT_CLIENT_VERSION_REGEXES = [
        "INNERTUBE_CONTEXT_CLIENT_VERSION\":\"([0-9\\.]+?)\"",
        "innertube_context_client_version\":\"([0-9\\.]+?)\"",
        "client.version=([0-9\\.]+)",
    ]
    private static let INITIAL_DATA_REGEXES = [
        "window\\[\"ytInitialData\"\\]\\s*=\\s*(\\{.*?\\});",
        "var\\s*ytInitialData\\s*=\\s*(\\{.*?\\});",
    ]

    private static let CONTENT_PLAYBACK_NONCE_ALPHABET =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

    private static var numberGenerator: any RandomNumberGenerator = SystemRandomNumberGenerator()

    private static let FEED_BASE_CHANNEL_ID =
        "https://www.youtube.com/feeds/videos.xml?channel_id="
    private static let FEED_BASE_USER = "https://www.youtube.com/feeds/videos.xml?user="
    private static let C_WEB_PATTERN = Pattern.compile("&c=WEB")
    private static let C_WEB_EMBEDDED_PLAYER_PATTERN = Pattern.compile("&c=WEB_EMBEDDED_PLAYER")
    private static let C_ANDROID_PATTERN = Pattern.compile("&c=ANDROID")
    private static let C_IOS_PATTERN = Pattern.compile("&c=IOS")
    private static let C_VISIONOS_PATTERN = Pattern.compile("&c=VISIONOS")

    private static let GOOGLE_URLS: Set<String> = ["google.", "m.google.", "www.google."]
    private static let INVIDIOUS_URLS: Set<String> = [
        "invidio.us", "dev.invidio.us", "www.invidio.us", "redirect.invidious.io",
        "invidious.snopyta.org", "yewtu.be", "tube.connect.cafe", "tubus.eduvid.org",
        "invidious.kavin.rocks", "invidious.site", "invidious-us.kavin.rocks", "piped.kavin.rocks",
        "vid.mint.lgbt", "invidiou.site", "invidious.fdn.fr", "invidious.048596.xyz",
        "invidious.zee.li", "vid.puffyan.us", "ytprivate.com", "invidious.namazso.eu",
        "invidious.silkky.cloud", "ytb.trom.tf", "invidious.exonip.de", "inv.riverside.rocks",
        "invidious.blamefran.net", "y.com.cm", "invidious.moomoo.me", "yt.cyberhost.uk",
    ]
    private static let YOUTUBE_URLS: Set<String> = [
        "youtube.com", "www.youtube.com", "m.youtube.com", "music.youtube.com",
    ]

    private static var consentAccepted = false

    public static func isGoogleURL(_ url: String) -> Bool {
        let cachedUrl = extractCachedUrlIfNeeded(url)
        guard let u = URL(string: cachedUrl), let host = u.host else {
            return false
        }
        return GOOGLE_URLS.contains { host.hasPrefix($0) }
    }

    public static func isYoutubeURL(_ url: URL) -> Bool {
        YOUTUBE_URLS.contains((url.host ?? "").lowercased())
    }

    public static func isYoutubeServiceURL(_ url: URL) -> Bool {
        let host = url.host ?? ""
        return host.caseInsensitiveEquals("www.youtube-nocookie.com")
            || host.caseInsensitiveEquals("youtu.be")
    }

    public static func isHooktubeURL(_ url: URL) -> Bool {
        (url.host ?? "").caseInsensitiveEquals("hooktube.com")
    }

    public static func isInvidiousURL(_ url: URL) -> Bool {
        INVIDIOUS_URLS.contains((url.host ?? "").lowercased())
    }

    public static func isY2ubeURL(_ url: URL) -> Bool {
        (url.host ?? "").caseInsensitiveEquals("y2u.be")
    }

    /// Parses the duration string of the video expecting ":" or "." as
    /// separators; returns the duration in seconds.
    public static func parseDurationString(_ input: String) throws -> Int {
        if !Parser.isMatch(".*\\d.*", input) && input.lowercased() != "shorts" {
            throw ParsingException("Error duration string contains no digits: \(input)")
        }

        let splitInput = input.contains(":")
            ? input.components(separatedBy: ":")
            : input.components(separatedBy: ".")

        let units = [24, 60, 60, 1]
        let offset = units.count - splitInput.count
        if offset < 0 {
            throw ParsingException("Error duration string with unknown format: \(input)")
        }
        var duration = 0
        for i in 0..<splitInput.count {
            duration = units[i + offset] * (duration + convertDurationToInt(splitInput[i]))
        }
        return duration
    }

    private static func convertDurationToInt(_ input: String?) -> Int {
        guard let input, !input.isEmpty else { return 0 }
        return Int(Utils.removeNonDigitCharacters(input)) ?? 0
    }

    public static func getFeedUrlFrom(_ channelIdOrUser: String) -> String {
        if channelIdOrUser.hasPrefix("user/") {
            return FEED_BASE_USER + channelIdOrUser.replacingOccurrences(of: "user/", with: "")
        } else if channelIdOrUser.hasPrefix("channel/") {
            return FEED_BASE_CHANNEL_ID
                + channelIdOrUser.replacingOccurrences(of: "channel/", with: "")
        } else {
            return FEED_BASE_CHANNEL_ID + channelIdOrUser
        }
    }

    /// Whether the playlist id is a YouTube Mix (ids start with "RD").
    public static func isYoutubeMixId(_ playlistId: String) -> Bool {
        playlistId.hasPrefix("RD")
    }

    /// Whether the playlist id is a YouTube My Mix (ids start with "RDMM").
    public static func isYoutubeMyMixId(_ playlistId: String) -> Bool {
        playlistId.hasPrefix("RDMM")
    }

    /// Whether the playlist id is a YouTube Music Mix ("RDAMVM"/"RDCLAK").
    public static func isYoutubeMusicMixId(_ playlistId: String) -> Bool {
        playlistId.hasPrefix("RDAMVM") || playlistId.hasPrefix("RDCLAK")
    }

    /// Whether the playlist id is a YouTube Genre Mix (ids start with "RDGMEM").
    public static func isYoutubeGenreMixId(_ playlistId: String) -> Bool {
        playlistId.hasPrefix("RDGMEM")
    }

    public static func extractVideoIdFromMixId(_ playlistId: String) throws -> String {
        if Utils.isNullOrEmpty(playlistId) {
            throw ParsingException("Video id could not be determined from empty playlist id")
        } else if isYoutubeMyMixId(playlistId) {
            return String(playlistId.dropFirst(4))
        } else if isYoutubeMusicMixId(playlistId) {
            return String(playlistId.dropFirst(6))
        } else if isYoutubeGenreMixId(playlistId) {
            throw ParsingException(
                "Video id could not be determined from genre mix id: \(playlistId)")
        } else if isYoutubeMixId(playlistId) {
            if playlistId.count != 13 {
                throw ParsingException(
                    "Video id could not be determined from mix id: \(playlistId)")
            }
            return String(playlistId.dropFirst(2))
        } else {
            throw ParsingException(
                "Video id could not be determined from playlist id: \(playlistId)")
        }
    }

    public static func extractPlaylistTypeFromPlaylistId(
        _ playlistId: String
    ) throws -> PlaylistInfo.PlaylistType {
        if Utils.isNullOrEmpty(playlistId) {
            throw ParsingException("Could not extract playlist type from empty playlist id")
        } else if isYoutubeMusicMixId(playlistId) {
            return .MIX_MUSIC
        } else if isYoutubeGenreMixId(playlistId) {
            return .MIX_GENRE
        } else if isYoutubeMixId(playlistId) {
            return .MIX_STREAM
        } else {
            return .NORMAL
        }
    }

    public static func extractPlaylistTypeFromPlaylistUrl(
        _ playlistUrl: String
    ) throws -> PlaylistInfo.PlaylistType {
        do {
            return try extractPlaylistTypeFromPlaylistId(
                Utils.getQueryValue(try Utils.stringToURL(playlistUrl), "list") ?? "")
        } catch is Utils.MalformedURLException {
            throw ParsingException("Could not extract playlist type from malformed url")
        }
    }

    private static func getInitialData(_ html: String) throws -> JsonObject {
        do {
            return try JsonParser.object().from(
                try Utils.getStringResultFromRegexArray(html, INITIAL_DATA_REGEXES, 1))
        } catch {
            throw ParsingException("Could not get ytInitialData", error)
        }
    }

    public static func isHardcodedClientVersionValid() throws -> Bool {
        if let hardcodedClientVersionValid {
            return hardcodedClientVersionValid
        }
        let body = JsonWriter.string()
            .object()
                .object("context")
                    .object("client")
                        .value("hl", "en-GB")
                        .value("gl", "GB")
                        .value("clientName", ClientsConstants.WEB_CLIENT_NAME)
                        .value("clientVersion", ClientsConstants.WEB_HARDCODED_CLIENT_VERSION)
                        .value("platform", ClientsConstants.DESKTOP_CLIENT_PLATFORM)
                        .value("utcOffsetMinutes", 0)
                    .end()
                    .object("request")
                        .array("internalExperimentFlags")
                        .end()
                        .value("useSsl", true)
                    .end()
                    .object("user")
                        .value("lockedSafetyMode", false)
                    .end()
                .end()
                .value("fetchLiveState", true)
            .end().done().data(using: .utf8)

        let headers = getClientHeaders(
            ClientsConstants.WEB_CLIENT_ID, ClientsConstants.WEB_HARDCODED_CLIENT_VERSION)

        let response = try NewPipe.getDownloader().postWithContentTypeJson(
            YOUTUBEI_V1_URL + "guide?" + DISABLE_PRETTY_PRINT_PARAMETER, headers, body)
        let responseBody = response.responseBody
        let responseCode = response.responseCode

        let valid = responseBody.count > 5000 && responseCode == 200
        hardcodedClientVersionValid = valid
        return valid
    }

    private static func extractClientVersionFromSwJs() throws {
        if clientVersionExtracted {
            return
        }
        let url = "https://www.youtube.com/sw.js"
        let headers = getOriginReferrerHeaders("https://www.youtube.com")
        let response = try NewPipe.getDownloader().get(url, headers).responseBody
        do {
            clientVersion = try Utils.getStringResultFromRegexArray(
                response, INNERTUBE_CONTEXT_CLIENT_VERSION_REGEXES, 1)
        } catch is Parser.RegexException {
            throw ParsingException(
                "Could not extract YouTube WEB InnerTube client version from sw.js")
        }
        clientVersionExtracted = true
    }

    private static func extractClientVersionFromHtmlSearchResultsPage() throws {
        if clientVersionExtracted {
            return
        }
        let url = "https://www.youtube.com/results?search_query=&ucbcb=1"
        let html = try NewPipe.getDownloader().get(url, getCookieHeader()).responseBody
        let initialData = try getInitialData(html)
        let serviceTrackingParams = initialData.getObject("responseContext")
            .getArray("serviceTrackingParams")

        clientVersion = getClientVersionFromServiceTrackingParam(
            serviceTrackingParams, "CSI", "cver")

        if clientVersion == nil {
            clientVersion = try? Utils.getStringResultFromRegexArray(
                html, INNERTUBE_CONTEXT_CLIENT_VERSION_REGEXES, 1)
        }

        if Utils.isNullOrEmpty(clientVersion) {
            clientVersion = getClientVersionFromServiceTrackingParam(
                serviceTrackingParams, "ECATCHER", "client.version")
        }

        if clientVersion == nil {
            throw ParsingException(
                "Could not extract YouTube WEB InnerTube client version from HTML search "
                + "results page")
        }

        clientVersionExtracted = true
    }

    private static func getClientVersionFromServiceTrackingParam(
        _ serviceTrackingParams: JsonArray,
        _ serviceName: String,
        _ clientVersionKey: String
    ) -> String? {
        for serviceTrackingParam in serviceTrackingParams.streamAsJsonObjects()
        where serviceTrackingParam.getString("service", "") == serviceName {
            for param in serviceTrackingParam.getArray("params").streamAsJsonObjects()
            where param.getString("key", "") == clientVersionKey {
                if let value = param.getString("value"), !Utils.isNullOrEmpty(value) {
                    return value
                }
            }
        }
        return nil
    }

    /// The client version used by the YouTube website on InnerTube requests.
    public static func getClientVersion() throws -> String {
        if let clientVersion, !clientVersion.isEmpty {
            return clientVersion
        }

        // Extract the latest client version (sw.js, then HTML fallback) to
        // avoid fingerprinting on a fixed client version.
        do {
            try extractClientVersionFromSwJs()
        } catch {
            try extractClientVersionFromHtmlSearchResultsPage()
        }

        if clientVersionExtracted {
            return clientVersion!
        }

        // Fallback to the hardcoded one if it is valid
        if try isHardcodedClientVersionValid() {
            clientVersion = ClientsConstants.WEB_HARDCODED_CLIENT_VERSION
            return clientVersion!
        }

        throw ExtractionException("Could not get YouTube WEB client version")
    }

    /// Only used in tests: reset global state between test classes.
    public static func resetClientVersion() {
        clientVersion = nil
        clientVersionExtracted = false
    }

    /// Only used in tests.
    public static func setNumberGenerator(_ random: any RandomNumberGenerator) {
        numberGenerator = random
    }

    public static func getUrlFromNavigationEndpoint(
        _ navigationEndpoint: JsonObject
    ) -> String? {
        if navigationEndpoint.has("urlEndpoint") {
            var internUrl = navigationEndpoint.getObject("urlEndpoint").getString("url") ?? ""
            if internUrl.hasPrefix("https://www.youtube.com/redirect?") {
                internUrl = String(internUrl.dropFirst(23))
            }

            if internUrl.hasPrefix("/redirect?") {
                internUrl = String(internUrl.dropFirst(10))
                let params = internUrl.components(separatedBy: "&")
                for param in params where param.components(separatedBy: "=")[0] == "q" {
                    return Utils.decodeUrlUtf8(param.components(separatedBy: "=")[1])
                }
            } else if internUrl.hasPrefix("http") {
                return internUrl
            } else if internUrl.hasPrefix("/channel") || internUrl.hasPrefix("/user")
                || internUrl.hasPrefix("/watch") {
                return "https://www.youtube.com" + internUrl
            }
        }

        if navigationEndpoint.has("browseEndpoint") {
            let browseEndpoint = navigationEndpoint.getObject("browseEndpoint")
            let canonicalBaseUrl = browseEndpoint.getString("canonicalBaseUrl")
            let browseId = browseEndpoint.getString("browseId")

            if let browseId {
                if browseId.hasPrefix("UC") {
                    return "https://www.youtube.com/channel/" + browseId
                } else if browseId.hasPrefix("VL") {
                    return "https://www.youtube.com/playlist?list=" + String(browseId.dropFirst(2))
                }
            }

            if !Utils.isNullOrEmpty(canonicalBaseUrl) {
                return "https://www.youtube.com" + canonicalBaseUrl!
            }
        }

        if navigationEndpoint.has("watchEndpoint") {
            var url = "https://www.youtube.com/watch?v="
            let watchEndpoint = navigationEndpoint.getObject("watchEndpoint")
            url += watchEndpoint.getString(VIDEO_ID) ?? ""
            if watchEndpoint.has("playlistId") {
                url += "&list=" + (watchEndpoint.getString("playlistId") ?? "")
            }
            if watchEndpoint.has("startTimeSeconds") {
                url += "&t=\(watchEndpoint.getInt("startTimeSeconds"))"
            }
            return url
        }

        if navigationEndpoint.has("watchPlaylistEndpoint") {
            return "https://www.youtube.com/playlist?list="
                + (navigationEndpoint.getObject("watchPlaylistEndpoint")
                    .getString("playlistId") ?? "")
        }

        if navigationEndpoint.has("showDialogCommand") {
            if let listItems = try? JsonUtils.getArray(
                navigationEndpoint,
                "showDialogCommand.panelLoadingStrategy.inlineContent.dialogViewModel"
                + ".customContent.listViewModel.listItems"),
               let command = try? JsonUtils.getObject(
                listItems.getObject(0),
                "listItemViewModel.rendererContext.commandContext.onTap.innertubeCommand") {
                return getUrlFromNavigationEndpoint(command)
            }
        }

        if navigationEndpoint.has("commandMetadata") {
            let metadata = navigationEndpoint.getObject("commandMetadata")
                .getObject("webCommandMetadata")
            if metadata.has("url") {
                return "https://www.youtube.com" + (metadata.getString("url") ?? "")
            }
        }

        return nil
    }

    /// Get the text from a JSON object that has either a simpleText or a runs
    /// array.
    public static func getTextFromObject(
        _ textObject: JsonObject?, _ html: Bool
    ) -> String? {
        guard let textObject, !Utils.isNullOrEmpty(textObject) else {
            return nil
        }

        if textObject.has("simpleText") {
            return textObject.getString("simpleText")
        }

        let runs = textObject.getArray("runs")
        if runs.isEmpty {
            return nil
        }

        var textBuilder = ""
        for run in runs.streamAsJsonObjects() {
            var text = run.getString("text") ?? ""

            if html {
                if run.has("navigationEndpoint") {
                    if let url = getUrlFromNavigationEndpoint(
                        run.getObject("navigationEndpoint")), !Utils.isNullOrEmpty(url) {
                        text = "<a href=\"" + htmlEscape(url) + "\">" + htmlEscape(text) + "</a>"
                    }
                }

                let bold = run.has("bold") && run.getBoolean("bold")
                let italic = run.has("italics") && run.getBoolean("italics")
                let strikethrough = run.has("strikethrough") && run.getBoolean("strikethrough")

                if bold { textBuilder += "<b>" }
                if italic { textBuilder += "<i>" }
                if strikethrough { textBuilder += "<s>" }
                textBuilder += text
                if strikethrough { textBuilder += "</s>" }
                if italic { textBuilder += "</i>" }
                if bold { textBuilder += "</b>" }
            } else {
                textBuilder += text
            }
        }

        var text = textBuilder
        if html {
            text = text.replacingOccurrences(of: "\n", with: "<br>")
            text = text.replacingOccurrences(of: "  ", with: " &nbsp;")
        }
        return text
    }

    public static func getTextFromObjectOrThrow(
        _ textObject: JsonObject?, _ error: String
    ) throws -> String {
        guard let result = getTextFromObject(textObject) else {
            throw ParsingException("Could not extract text: \(error)")
        }
        return result
    }

    public static func getTextFromObject(_ textObject: JsonObject?) -> String? {
        getTextFromObject(textObject, false)
    }

    public static func getUrlFromObject(_ textObject: JsonObject?) -> String? {
        guard let textObject, !Utils.isNullOrEmpty(textObject) else {
            return nil
        }
        let runs = textObject.getArray("runs")
        if runs.isEmpty {
            return nil
        }
        for textPart in runs.streamAsJsonObjects() {
            if let url = getUrlFromNavigationEndpoint(textPart.getObject("navigationEndpoint")),
               !Utils.isNullOrEmpty(url) {
                return url
            }
        }
        return nil
    }

    public static func getTextAtKey(_ jsonObject: JsonObject, _ theKey: String) -> String? {
        if jsonObject.isString(theKey) {
            return jsonObject.getString(theKey)
        } else {
            return getTextFromObject(jsonObject.getObject(theKey))
        }
    }

    public static func fixThumbnailUrl(_ thumbnailUrl: String) -> String {
        var result = thumbnailUrl
        if result.hasPrefix("//") {
            result = String(result.dropFirst(2))
        }

        if result.hasPrefix(Utils.HTTP) {
            result = Utils.replaceHttpWithHttps(result)!
        } else if !result.hasPrefix(Utils.HTTPS) {
            result = "https://" + result
        }
        return result
    }

    public static func getThumbnailsFromInfoItem(_ infoItem: JsonObject) throws -> [Image] {
        getImagesFromThumbnailsArray(infoItem.getObject("thumbnail").getArray("thumbnails"))
    }

    public static func getImagesFromThumbnailsArray(_ thumbnails: JsonArray) -> [Image] {
        thumbnails.streamAsJsonObjects()
            .filter { !Utils.isNullOrEmpty($0.getString("url")) }
            .map { thumbnail in
                let height = thumbnail.getInt("height", Image.HEIGHT_UNKNOWN)
                return Image(
                    fixThumbnailUrl(thumbnail.getString("url")!),
                    height,
                    thumbnail.getInt("width", Image.WIDTH_UNKNOWN),
                    Image.ResolutionLevel.fromHeight(height))
            }
    }

    public static func getValidJsonResponseBody(_ response: Response) throws -> String {
        if response.responseCode == 404 {
            throw ContentNotAvailableException(
                "Not found (\"\(response.responseCode) \(response.responseMessage)\")")
        }

        let responseBody = response.responseBody
        if responseBody.count < 50 {
            throw ParsingException("JSON response is too short")
        }

        // Check if the request was redirected to the error page.
        if let latestUrl = URL(string: response.latestUrl),
           (latestUrl.host ?? "").caseInsensitiveEquals("www.youtube.com") {
            let path = latestUrl.path
            if path.caseInsensitiveEquals("/oops") || path.caseInsensitiveEquals("/error") {
                throw ContentNotAvailableException("Content unavailable")
            }
        }

        if let responseContentType = response.getHeader("Content-Type"),
           responseContentType.lowercased().contains("text/html") {
            throw ParsingException(
                "Got HTML document, expected JSON response "
                + "(latest url was: \"\(response.latestUrl)\")")
        }

        return responseBody
    }

    public static func getJsonPostResponse(
        _ endpoint: String, _ body: Data?, _ localization: Localization
    ) throws -> JsonObject {
        let headers = try getYouTubeHeaders()
        return try JsonUtils.toJsonObject(getValidJsonResponseBody(
            try NewPipe.getDownloader().postWithContentTypeJson(
                YOUTUBEI_V1_URL + endpoint + "?" + DISABLE_PRETTY_PRINT_PARAMETER,
                headers, body, localization)))
    }

    public static func getJsonPostResponse(
        _ endpoint: String, _ queryParameters: [String], _ body: Data?,
        _ localization: Localization
    ) throws -> JsonObject {
        let headers = try getYouTubeHeaders()
        let queryParametersString: String
        if queryParameters.isEmpty {
            queryParametersString = "?" + DISABLE_PRETTY_PRINT_PARAMETER
        } else {
            queryParametersString = "?" + queryParameters.joined(separator: "&")
                + "&" + DISABLE_PRETTY_PRINT_PARAMETER
        }
        return try JsonUtils.toJsonObject(getValidJsonResponseBody(
            try NewPipe.getDownloader().postWithContentTypeJson(
                YOUTUBEI_V1_URL + endpoint + queryParametersString, headers, body, localization)))
    }

    public static func prepareDesktopJsonBuilder(
        _ localization: Localization, _ contentCountry: ContentCountry
    ) throws -> JsonBuilder<JsonObject> {
        JsonObject.builder()
            .object("context")
                .object("client")
                    .value("hl", localization.getLocalizationCode())
                    .value("gl", contentCountry.getCountryCode())
                    .value("clientName", ClientsConstants.WEB_CLIENT_NAME)
                    .value("clientVersion", try getClientVersion())
                    .value("originalUrl", "https://www.youtube.com")
                    .value("platform", ClientsConstants.DESKTOP_CLIENT_PLATFORM)
                    .value("utcOffsetMinutes", 0)
                .end()
                .object("request")
                    .array("internalExperimentFlags")
                    .end()
                    .value("useSsl", true)
                .end()
                .object("user")
                    .value("lockedSafetyMode", false)
                .end()
            .end()
    }

    public static func getAndroidUserAgent(_ localization: Localization?) -> String {
        "com.google.android.youtube/" + ClientsConstants.ANDROID_CLIENT_VERSION
            + " (Linux; U; Android 15; "
            + (localization ?? Localization.DEFAULT).getCountryCode() + ") gzip"
    }

    public static func getIosUserAgent(_ localization: Localization?) -> String {
        "com.google.ios.youtube/" + ClientsConstants.IOS_CLIENT_VERSION
            + "(" + ClientsConstants.IOS_DEVICE_MODEL + "; U; CPU iOS "
            + ClientsConstants.IOS_USER_AGENT_VERSION + " like Mac OS X; "
            + (localization ?? Localization.DEFAULT).getCountryCode() + ")"
    }

    public static func getVisionOsUserAgent(_ localization: Localization?) -> String {
        "com.google.visionos.youtube/" + ClientsConstants.VISIONOS_CLIENT_VERSION
            + "(" + ClientsConstants.VISIONOS_DEVICE_MODEL + "; U; CPU visionOS "
            + ClientsConstants.VISIONOS_USER_AGENT_VERSION + " like Mac OS X; "
            + (localization ?? Localization.DEFAULT).getCountryCode() + ")"
    }

    public static func getYoutubeMusicHeaders() -> [String: [String]] {
        var headers = getOriginReferrerHeaders(YOUTUBE_MUSIC_URL)
        headers.merge(
            getClientHeaders(ClientsConstants.WEB_REMIX_CLIENT_ID, youtubeMusicClientVersion ?? "")
        ) { _, new in new }
        return headers
    }

    /// YouTube headers including the CONSENT cookie to prevent redirects to
    /// consent.youtube.com.
    public static func getYouTubeHeaders() throws -> [String: [String]] {
        var headers = try getClientInfoHeaders()
        headers["Cookie"] = [generateConsentCookie()]
        return headers
    }

    public static func getClientInfoHeaders() throws -> [String: [String]] {
        var headers = getOriginReferrerHeaders("https://www.youtube.com")
        headers.merge(
            getClientHeaders(ClientsConstants.WEB_CLIENT_ID, try getClientVersion())
        ) { _, new in new }
        return headers
    }

    public static func getOriginReferrerHeaders(_ url: String) -> [String: [String]] {
        ["Origin": [url], "Referer": [url]]
    }

    public static func getClientHeaders(
        _ name: String, _ version: String
    ) -> [String: [String]] {
        [
            "X-YouTube-Client-Name": [name],
            "X-YouTube-Client-Version": [version],
        ]
    }

    public static func getCookieHeader() -> [String: [String]] {
        ["Cookie": [generateConsentCookie()]]
    }

    public static func generateConsentCookie() -> String {
        // CAISAiAD: user configured cookies manually (allows extracting mixes
        // and some YouTube Music playlists); CAE=: rejected non-necessary
        // cookies.
        "SOCS=" + (isConsentAccepted() ? "CAISAiAD" : "CAE=")
    }

    public static func extractCookieValue(_ cookieName: String, _ response: Response) -> String {
        guard let cookies = response.responseHeaders["set-cookie"] else {
            return ""
        }
        var result = ""
        for cookie in cookies {
            guard let nameRange = cookie.range(of: cookieName) else { continue }
            // value begins after "cookieName=" and ends at the next ";" found
            // from the cookie-name position (mirror of Java's indexOf logic).
            let valueStart = cookie.index(
                nameRange.upperBound, offsetBy: 1, limitedBy: cookie.endIndex) ?? cookie.endIndex
            if let semicolon = cookie[nameRange.lowerBound...].firstIndex(of: ";"),
               valueStart <= semicolon {
                result = String(cookie[valueStart..<semicolon])
            }
        }
        return result
    }

    /// Shared alert detection: throws if the object has an alert of type ERROR.
    public static func defaultAlertsCheck(_ initialData: JsonObject) throws {
        let alerts = initialData.getArray("alerts")
        if !Utils.isNullOrEmpty(alerts) {
            let alertRenderer = alerts.getObject(0).getObject("alertRenderer")
            let alertText = getTextFromObject(alertRenderer.getObject("text"))
            let alertType = alertRenderer.getString("type", "") ?? ""
            if alertType.caseInsensitiveEquals("ERROR") {
                if let alertText,
                   alertText.contains("This account has been terminated")
                    || alertText.contains("This channel was removed") {
                    if Parser.isMatch(".*violat(ed|ion|ing).*", alertText)
                        || alertText.contains("infringement") {
                        throw AccountTerminatedException(alertText, .VIOLATION)
                    } else {
                        throw AccountTerminatedException(alertText)
                    }
                }
                throw ContentNotAvailableException("Got error: \"\(alertText ?? "")\"")
            }
        }
    }

    public static func extractCachedUrlIfNeeded(_ url: String?) -> String! {
        guard let url else { return nil }
        if url.contains("webcache.googleusercontent.com") {
            return url.components(separatedBy: "cache:")[1]
        }
        return url
    }

    public static func isVerified(_ badges: JsonArray) -> Bool {
        if Utils.isNullOrEmpty(badges) {
            return false
        }
        for badge in badges.streamAsJsonObjects() {
            let style = badge.getObject("metadataBadgeRenderer").getString("style")
            if let style, style == "BADGE_STYLE_TYPE_VERIFIED"
                || style == "BADGE_STYLE_TYPE_VERIFIED_ARTIST" {
                return true
            }
        }
        return false
    }

    public static func hasArtistOrVerifiedIconBadgeAttachment(
        _ attachmentRuns: JsonArray
    ) -> Bool {
        attachmentRuns.streamAsJsonObjects().contains { attachmentRun in
            attachmentRun.getObject("element")
                .getObject("type")
                .getObject("imageType")
                .getObject("image")
                .getArray("sources")
                .streamAsJsonObjects()
                .contains { source in
                    let imageName = source.getObject("clientResource").getString("imageName")
                    return imageName == "CHECK_CIRCLE_FILLED"
                        || imageName == "AUDIO_BADGE"
                        || imageName == "MUSIC_FILLED"
                }
        }
    }

    /// Generate a content playback nonce (cpn), sent by YouTube clients in
    /// playback requests.
    public static func generateContentPlaybackNonce() -> String {
        RandomStringFromAlphabetGenerator.generate(
            CONTENT_PLAYBACK_NONCE_ALPHABET, 16, &numberGenerator)
    }

    /// Try to generate a `t` parameter, sent by mobile clients as a query of
    /// the player request.
    public static func generateTParameter() -> String {
        RandomStringFromAlphabetGenerator.generate(
            CONTENT_PLAYBACK_NONCE_ALPHABET, 12, &numberGenerator)
    }

    public static func isWebStreamingUrl(_ url: String) -> Bool {
        Parser.isMatch(C_WEB_PATTERN, url)
    }

    public static func isWebEmbeddedPlayerStreamingUrl(_ url: String) -> Bool {
        Parser.isMatch(C_WEB_EMBEDDED_PLAYER_PATTERN, url)
    }

    public static func isAndroidStreamingUrl(_ url: String) -> Bool {
        Parser.isMatch(C_ANDROID_PATTERN, url)
    }

    public static func isIosStreamingUrl(_ url: String) -> Bool {
        Parser.isMatch(C_IOS_PATTERN, url)
    }

    public static func isVisionOsStreamingUrl(_ url: String) -> Bool {
        Parser.isMatch(C_VISIONOS_PATTERN, url)
    }

    public static func setConsentAccepted(_ accepted: Bool) {
        consentAccepted = accepted
    }

    public static func isConsentAccepted() -> Bool {
        consentAccepted
    }

    /// Extract the audio track type from the formats XTags.
    /// Deviation: returns nil until swift-protobuf + the Xtags .proto are
    /// wired (TODO). Only affects audio track typing of YouTube formats.
    public static func extractAudioTrackType(_ xtags: String?) -> AudioTrackType? {
        nil
    }

    public static func getVisitorDataFromInnertube(
        _ innertubeClientRequestInfo: InnertubeClientRequestInfo,
        _ localization: Localization,
        _ contentCountry: ContentCountry,
        _ httpHeaders: [String: [String]],
        _ innertubeDomainAndVersionEndpoint: String,
        _ embedUrl: String?,
        _ useGuideEndpoint: Bool
    ) throws -> String {
        let builder = prepareJsonBuilder(
            localization, contentCountry, innertubeClientRequestInfo, embedUrl)
        let body = JsonWriter.string(builder.done()).data(using: .utf8)

        let visitorData = try JsonUtils.toJsonObject(getValidJsonResponseBody(
            try NewPipe.getDownloader().postWithContentTypeJson(
                innertubeDomainAndVersionEndpoint
                    + (useGuideEndpoint ? "guide" : "visitor_id") + "?"
                    + DISABLE_PRETTY_PRINT_PARAMETER,
                httpHeaders, body)))
            .getObject("responseContext")
            .getString("visitorData")

        guard let visitorData, !Utils.isNullOrEmpty(visitorData) else {
            throw ParsingException("Could not get visitorData")
        }
        return visitorData
    }

    public static func prepareJsonBuilder(
        _ localization: Localization,
        _ contentCountry: ContentCountry,
        _ innertubeClientRequestInfo: InnertubeClientRequestInfo,
        _ embedUrl: String?
    ) -> JsonBuilder<JsonObject> {
        let clientInfo = innertubeClientRequestInfo.clientInfo
        let deviceInfo = innertubeClientRequestInfo.deviceInfo

        let builder = JsonObject.builder()
            .object("context")
            .object("client")
            .value("clientName", clientInfo.clientName)
            .value("clientVersion", clientInfo.clientVersion)

        if let clientScreen = clientInfo.clientScreen {
            builder.value("clientScreen", clientScreen)
        }
        if let platform = deviceInfo.platform {
            builder.value("platform", platform)
        }
        if let visitorData = clientInfo.visitorData {
            builder.value("visitorData", visitorData)
        }
        if let deviceMake = deviceInfo.deviceMake {
            builder.value("deviceMake", deviceMake)
        }
        if let deviceModel = deviceInfo.deviceModel {
            builder.value("deviceModel", deviceModel)
        }
        if let osName = deviceInfo.osName {
            builder.value("osName", osName)
        }
        if let osVersion = deviceInfo.osVersion {
            builder.value("osVersion", osVersion)
        }
        if deviceInfo.androidSdkVersion > 0 {
            builder.value("androidSdkVersion", deviceInfo.androidSdkVersion)
        }

        builder.value("hl", localization.getLocalizationCode())
            .value("gl", contentCountry.getCountryCode())
            .value("utcOffsetMinutes", 0)
            .end()

        if let embedUrl {
            builder.object("thirdParty")
                .value("embedUrl", embedUrl)
                .end()
        }

        builder.object("request")
            .array("internalExperimentFlags")
            .end()
            .value("useSsl", true)
            .end()
            .object("user")
            .value("lockedSafetyMode", false)
            .end()
            .end()

        return builder
    }

    /// The first collaborator: the channel that owns the video.
    public static func getFirstCollaborator(_ navigationEndpoint: JsonObject) throws -> JsonObject? {
        if let listItems = try? JsonUtils.getArray(
            navigationEndpoint,
            "showDialogCommand.panelLoadingStrategy.inlineContent.dialogViewModel"
            + ".customContent.listViewModel.listItems") {
            return listItems.getObject(0).getObject("listItemViewModel")
        }
        return nil
    }

    /// Local jsoup-base HTML escaper (see file header). Escapes & < > " ,
    /// matching jsoup's base entities for ASCII content.
    private static func htmlEscape(_ s: String) -> String {
        var result = s.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        return result
    }
}
