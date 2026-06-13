// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/YoutubeStreamHelper.java @ v0.26.3
//
// Builds the InnerTube player request bodies for each client (web metadata,
// web embedded, Android, Android reel, iOS, visionOS) and POSTs them. No JS
// engine dependency — purely request building + HTTP.

import Foundation
import NanoJSON

public enum YoutubeStreamHelper {
    private static let PLAYER = "player"
    private static let SERVICE_INTEGRITY_DIMENSIONS = "serviceIntegrityDimensions"
    private static let PO_TOKEN = "poToken"
    private static let BASE_YT_DESKTOP_WATCH_URL = "https://www.youtube.com/watch?v="

    public static func getWebMetadataPlayerResponse(
        _ localization: Localization,
        _ contentCountry: ContentCountry,
        _ videoId: String
    ) throws -> JsonObject {
        let innertubeClientRequestInfo = InnertubeClientRequestInfo.ofWebClient()
        innertubeClientRequestInfo.clientInfo.clientVersion = try YoutubeParsingHelper.getClientVersion()

        let headers = try YoutubeParsingHelper.getYouTubeHeaders()

        // A valid visitorData is required for valid player responses.
        innertubeClientRequestInfo.clientInfo.visitorData =
            try YoutubeParsingHelper.getVisitorDataFromInnertube(
                innertubeClientRequestInfo, localization, contentCountry, headers,
                YoutubeParsingHelper.YOUTUBEI_V1_URL, nil, false)

        let builder = YoutubeParsingHelper.prepareJsonBuilder(
            localization, contentCountry, innertubeClientRequestInfo, nil)
        addVideoIdCpnAndOkChecks(builder, videoId, nil)

        let body = JsonWriter.string(builder.done()).data(using: .utf8)
        let url = YoutubeParsingHelper.YOUTUBEI_V1_URL + PLAYER + "?"
            + YoutubeParsingHelper.DISABLE_PRETTY_PRINT_PARAMETER
            + "&$fields=microformat,videoDetails.thumbnail.thumbnails,videoDetails.videoId"

        return try JsonUtils.toJsonObject(YoutubeParsingHelper.getValidJsonResponseBody(
            try NewPipe.getDownloader().postWithContentTypeJson(
                url, headers, body, localization)))
    }

    public static func getWebEmbeddedPlayerResponse(
        _ localization: Localization,
        _ contentCountry: ContentCountry,
        _ videoId: String,
        _ cpn: String,
        _ webEmbeddedPoTokenResult: PoTokenResult?,
        _ signatureTimestamp: Int
    ) throws -> JsonObject {
        let innertubeClientRequestInfo = InnertubeClientRequestInfo.ofWebEmbeddedPlayerClient()

        var headers = YoutubeParsingHelper.getClientHeaders(
            ClientsConstants.WEB_EMBEDDED_CLIENT_ID, ClientsConstants.WEB_EMBEDDED_CLIENT_VERSION)
        headers.merge(
            YoutubeParsingHelper.getOriginReferrerHeaders("https://www.youtube.com")
        ) { _, new in new }

        let embedUrl = BASE_YT_DESKTOP_WATCH_URL + videoId

        innertubeClientRequestInfo.clientInfo.visitorData = webEmbeddedPoTokenResult == nil
            ? try YoutubeParsingHelper.getVisitorDataFromInnertube(
                innertubeClientRequestInfo, localization, contentCountry, headers,
                YoutubeParsingHelper.YOUTUBEI_V1_URL, embedUrl, false)
            : webEmbeddedPoTokenResult!.visitorData

        let builder = YoutubeParsingHelper.prepareJsonBuilder(
            localization, contentCountry, innertubeClientRequestInfo, embedUrl)
        addVideoIdCpnAndOkChecks(builder, videoId, cpn)
        addPlaybackContext(builder, embedUrl, signatureTimestamp)
        if let webEmbeddedPoTokenResult {
            addPoToken(builder, webEmbeddedPoTokenResult.playerRequestPoToken)
        }

        let body = JsonWriter.string(builder.done()).data(using: .utf8)
        let url = YoutubeParsingHelper.YOUTUBEI_V1_URL + PLAYER + "?"
            + YoutubeParsingHelper.DISABLE_PRETTY_PRINT_PARAMETER

        return try JsonUtils.toJsonObject(YoutubeParsingHelper.getValidJsonResponseBody(
            try NewPipe.getDownloader().postWithContentTypeJson(url, headers, body, localization)))
    }

    public static func getAndroidPlayerResponse(
        _ contentCountry: ContentCountry,
        _ localization: Localization,
        _ videoId: String,
        _ cpn: String,
        _ androidPoTokenResult: PoTokenResult
    ) throws -> JsonObject {
        let innertubeClientRequestInfo = InnertubeClientRequestInfo.ofAndroidClient()
        innertubeClientRequestInfo.clientInfo.visitorData = androidPoTokenResult.visitorData

        let headers = getMobileClientHeaders(YoutubeParsingHelper.getAndroidUserAgent(localization))

        let builder = YoutubeParsingHelper.prepareJsonBuilder(
            localization, contentCountry, innertubeClientRequestInfo, nil)
        addVideoIdCpnAndOkChecks(builder, videoId, cpn)
        addPoToken(builder, androidPoTokenResult.playerRequestPoToken)

        let body = JsonWriter.string(builder.done()).data(using: .utf8)
        let url = YoutubeParsingHelper.YOUTUBEI_V1_GAPIS_URL + PLAYER + "?"
            + YoutubeParsingHelper.DISABLE_PRETTY_PRINT_PARAMETER
            + "&t=" + YoutubeParsingHelper.generateTParameter() + "&id=" + videoId

        return try JsonUtils.toJsonObject(YoutubeParsingHelper.getValidJsonResponseBody(
            try NewPipe.getDownloader().postWithContentTypeJson(url, headers, body, localization)))
    }

    public static func getAndroidReelPlayerResponse(
        _ contentCountry: ContentCountry,
        _ localization: Localization,
        _ videoId: String,
        _ cpn: String
    ) throws -> JsonObject {
        let innertubeClientRequestInfo = InnertubeClientRequestInfo.ofAndroidClient()

        let headers = getMobileClientHeaders(YoutubeParsingHelper.getAndroidUserAgent(localization))

        innertubeClientRequestInfo.clientInfo.visitorData =
            try YoutubeParsingHelper.getVisitorDataFromInnertube(
                innertubeClientRequestInfo, localization, contentCountry, headers,
                YoutubeParsingHelper.YOUTUBEI_V1_GAPIS_URL, nil, false)

        let builder = YoutubeParsingHelper.prepareJsonBuilder(
            localization, contentCountry, innertubeClientRequestInfo, nil)

        builder.object("playerRequest")
        addVideoIdCpnAndOkChecks(builder, videoId, cpn)
        builder.end().value("disablePlayerResponse", false)

        let body = JsonWriter.string(builder.done()).data(using: .utf8)
        let url = YoutubeParsingHelper.YOUTUBEI_V1_GAPIS_URL + "reel/reel_item_watch" + "?"
            + YoutubeParsingHelper.DISABLE_PRETTY_PRINT_PARAMETER
            + "&t=" + YoutubeParsingHelper.generateTParameter() + "&id=" + videoId
            + "&$fields=playerResponse"

        return try JsonUtils.toJsonObject(YoutubeParsingHelper.getValidJsonResponseBody(
            try NewPipe.getDownloader().postWithContentTypeJson(url, headers, body, localization)))
            .getObject("playerResponse")
    }

    public static func getIosPlayerResponse(
        _ contentCountry: ContentCountry,
        _ localization: Localization,
        _ videoId: String,
        _ cpn: String,
        _ iosPoTokenResult: PoTokenResult?
    ) throws -> JsonObject {
        let innertubeClientRequestInfo = InnertubeClientRequestInfo.ofIosClient()

        let headers = getMobileClientHeaders(YoutubeParsingHelper.getIosUserAgent(localization))

        innertubeClientRequestInfo.clientInfo.visitorData = iosPoTokenResult == nil
            ? try YoutubeParsingHelper.getVisitorDataFromInnertube(
                innertubeClientRequestInfo, localization, contentCountry, headers,
                YoutubeParsingHelper.YOUTUBEI_V1_URL, nil, false)
            : iosPoTokenResult!.visitorData

        let builder = YoutubeParsingHelper.prepareJsonBuilder(
            localization, contentCountry, innertubeClientRequestInfo, nil)
        addVideoIdCpnAndOkChecks(builder, videoId, cpn)
        if let iosPoTokenResult {
            addPoToken(builder, iosPoTokenResult.playerRequestPoToken)
        }

        let body = JsonWriter.string(builder.done()).data(using: .utf8)
        let url = YoutubeParsingHelper.YOUTUBEI_V1_GAPIS_URL + PLAYER + "?"
            + YoutubeParsingHelper.DISABLE_PRETTY_PRINT_PARAMETER
            + "&t=" + YoutubeParsingHelper.generateTParameter() + "&id=" + videoId

        return try JsonUtils.toJsonObject(YoutubeParsingHelper.getValidJsonResponseBody(
            try NewPipe.getDownloader().postWithContentTypeJson(url, headers, body, localization)))
    }

    public static func getVisionOsPlayerResponse(
        _ contentCountry: ContentCountry,
        _ localization: Localization,
        _ videoId: String,
        _ cpn: String
    ) throws -> JsonObject {
        let innertubeClientRequestInfo = InnertubeClientRequestInfo.ofVisionOsClient()

        let headers = getMobileClientHeaders(
            YoutubeParsingHelper.getVisionOsUserAgent(localization))

        innertubeClientRequestInfo.clientInfo.visitorData =
            try YoutubeParsingHelper.getVisitorDataFromInnertube(
                innertubeClientRequestInfo, localization, contentCountry, headers,
                YoutubeParsingHelper.YOUTUBEI_V1_URL, nil, false)

        let builder = YoutubeParsingHelper.prepareJsonBuilder(
            localization, contentCountry, innertubeClientRequestInfo, nil)
        addVideoIdCpnAndOkChecks(builder, videoId, cpn)

        let body = JsonWriter.string(builder.done()).data(using: .utf8)
        let url = YoutubeParsingHelper.YOUTUBEI_V1_GAPIS_URL + PLAYER + "?"
            + YoutubeParsingHelper.DISABLE_PRETTY_PRINT_PARAMETER
            + "&t=" + YoutubeParsingHelper.generateTParameter() + "&id=" + videoId

        return try JsonUtils.toJsonObject(YoutubeParsingHelper.getValidJsonResponseBody(
            try NewPipe.getDownloader().postWithContentTypeJson(url, headers, body, localization)))
    }

    private static func addVideoIdCpnAndOkChecks(
        _ builder: JsonBuilder<JsonObject>, _ videoId: String, _ cpn: String?
    ) {
        builder.value(YoutubeParsingHelper.VIDEO_ID, videoId)
        if let cpn {
            builder.value(YoutubeParsingHelper.CPN, cpn)
        }
        builder.value(YoutubeParsingHelper.CONTENT_CHECK_OK, true)
            .value(YoutubeParsingHelper.RACY_CHECK_OK, true)
    }

    private static func addPlaybackContext(
        _ builder: JsonBuilder<JsonObject>, _ referer: String, _ signatureTimestamp: Int
    ) {
        builder.object("playbackContext")
            .object("contentPlaybackContext")
            .value("signatureTimestamp", signatureTimestamp)
            .value("referer", referer)
            .end()
            .end()
    }

    private static func addPoToken(_ builder: JsonBuilder<JsonObject>, _ poToken: String) {
        builder.object(SERVICE_INTEGRITY_DIMENSIONS)
            .value(PO_TOKEN, poToken)
            .end()
    }

    private static func getMobileClientHeaders(_ userAgent: String) -> [String: [String]] {
        [
            "User-Agent": [userAgent],
            "X-Goog-Api-Format-Version": ["2"],
        ]
    }
}
