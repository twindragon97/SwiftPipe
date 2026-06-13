// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/extractors/YoutubeStreamExtractor.java @ v0.26.3
//
// Focused port for the playback milestone: onFetchPage (android/iOS/visionOS
// player requests + web metadata + next response), HLS/DASH manifest URLs,
// and metadata (name, uploader, length, thumbnails, view count, dates,
// description, stream type).
//
// Deferred with TODOs (need the JS player manager / not-yet-ported helpers):
//  - getAudioStreams/getVideoStreams/getVideoOnlyStreams: return [] (require
//    signature/throttling deciphering + ItagInfo). HLS playback needs none of
//    these; the iOS client HLS manifest is self-contained.
//  - getRelatedItems: nil (needs the lockup/mix info-item extractors).
//  - getSubtitles/getFrames/getStreamSegments: []; getLikeCount: -1.
//  - attributedDescriptionToHtml: "" (YoutubeDescriptionHelper not ported);
//    getDescription falls back to shortDescription.

import Foundation
import NanoJSON

public final class YoutubeStreamExtractor: StreamExtractor {
    private static let FORMATS = "formats"
    private static let ADAPTIVE_FORMATS = "adaptiveFormats"
    private static let STREAMING_DATA = "streamingData"
    private static let NEXT = "next"
    private static let PLAYER_CAPTIONS_TRACKLIST_RENDERER = "playerCaptionsTracklistRenderer"
    private static let CAPTIONS = "captions"
    private static let PLAYABILITY_STATUS = "playabilityStatus"
    private static let THUMBNAIL = "thumbnail"
    private static let THUMBNAILS = "thumbnails"
    private static let VIDEO_DETAILS = "videoDetails"
    private static let TITLE = "title"
    private static let PREMIERED = "Premiered "
    private static let PREMIERED_ON = "Premiered on "

    private static var poTokenProvider: PoTokenProvider?
    private static var fetchIosClient = false

    public static func setPoTokenProvider(_ provider: PoTokenProvider?) {
        poTokenProvider = provider
    }

    public static func setFetchIosClient(_ value: Bool) {
        fetchIosClient = value
    }

    private var playerResponse = JsonObject()
    private var nextResponse = JsonObject()
    private var visionOsStreamingData: JsonObject?
    private var iosStreamingData: JsonObject?
    private var androidStreamingData: JsonObject?
    private var videoPrimaryInfoRenderer: JsonObject?
    private var videoSecondaryInfoRenderer: JsonObject?
    private var playerMicroFormatRenderer = JsonObject()
    private var playerCaptionsTracklistRenderer = JsonObject()
    private var thumbnailsArray = JsonArray()
    private var ageLimitCached = -1
    private var streamType: StreamType?

    private var visionOsCpn = ""
    private var iosCpn = ""
    private var androidCpn = ""
    private var androidStreamingUrlsPoToken: String?
    private var iosStreamingUrlsPoToken: String?

    public override init(_ service: StreamingService, _ linkHandler: LinkHandler) {
        super.init(service, linkHandler)
    }

    // MARK: Metadata

    public override func getName() throws -> String {
        assertPageFetched()
        var title = playerResponse.getObject(Self.VIDEO_DETAILS).getString(Self.TITLE)
        if Utils.isNullOrEmpty(title) {
            title = YoutubeParsingHelper.getTextFromObject(
                getVideoPrimaryInfoRenderer().getObject(Self.TITLE))
            if Utils.isNullOrEmpty(title) {
                throw ParsingException("Could not get name")
            }
        }
        return title!
    }

    public override func getTextualUploadDate() throws -> String? {
        var timestamp = playerMicroFormatRenderer.getString("uploadDate", "") ?? ""
        if timestamp.isEmpty {
            timestamp = playerMicroFormatRenderer.getString("publishDate", "") ?? ""
        }
        if !timestamp.isEmpty {
            return timestamp
        }

        let liveDetails = playerMicroFormatRenderer.getObject("liveBroadcastDetails")
        timestamp = liveDetails.getString("endTimestamp", "") ?? ""  // an ended live stream
        if timestamp.isEmpty {
            timestamp = liveDetails.getString("startTimestamp", "") ?? ""  // a running live stream
        }
        if !timestamp.isEmpty {
            return timestamp
        } else if getStreamType() == .LIVE_STREAM {
            // a live stream without upload date is valid
            return nil
        }

        let textObject = getVideoPrimaryInfoRenderer().getObject("dateText")
        guard let rendererDateText = YoutubeParsingHelper.getTextFromObject(textObject) else {
            return nil
        }
        if rendererDateText.hasPrefix(Self.PREMIERED_ON) {
            return String(rendererDateText.dropFirst(Self.PREMIERED_ON.count))
        } else if rendererDateText.hasPrefix(Self.PREMIERED) {
            return String(rendererDateText.dropFirst(Self.PREMIERED.count))
        } else {
            return rendererDateText
        }
    }

    public override func getUploadDate() throws -> DateWrapper? {
        let dateText = try getTextualUploadDate()
        do {
            return try DateWrapper.fromOffsetDateTime(dateText)
        } catch is ParsingException {
            // Try other patterns first
        }

        if let dateText,
           let parser = TimeAgoPatternsManager.getTimeAgoParserFor(Localization("en")),
           let parsed = try? parser.parse(dateText) {
            return parsed
        }

        if let dateText,
           let date = parseOptionalDate(dateText, "MMM dd, yyyy")
            ?? parseOptionalDate(dateText, "dd MMM yyyy") {
            return DateWrapper(date, true)
        }
        throw ParsingException("Could not parse upload date \"\(dateText ?? "")\"")
    }

    private func parseOptionalDate(_ date: String, _ pattern: String) -> Date? {
        // TODO: parses English-formatted dates only.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = pattern
        formatter.timeZone = TimeZone.current
        return formatter.date(from: date)
    }

    public override func getThumbnails() throws -> [Image] {
        assertPageFetched()
        return YoutubeParsingHelper.getImagesFromThumbnailsArray(thumbnailsArray)
    }

    public override func getDescription() throws -> Description {
        assertPageFetched()
        // Description with more info on links
        let secondaryDescription = YoutubeParsingHelper.getTextFromObject(
            getVideoSecondaryInfoRenderer().getObject("description"), true)
        if !Utils.isNullOrEmpty(secondaryDescription) {
            return Description(secondaryDescription, Description.HTML)
        }

        let attributedDescription = attributedDescriptionToHtml(
            getVideoSecondaryInfoRenderer().getObject("attributedDescription"))
        if !Utils.isNullOrEmpty(attributedDescription) {
            return Description(attributedDescription, Description.HTML)
        }

        var description = playerResponse.getObject(Self.VIDEO_DETAILS)
            .getString("shortDescription")
        if description == nil {
            description = YoutubeParsingHelper.getTextFromObject(
                playerMicroFormatRenderer.getObject("description"))
        }
        return Description(description, Description.PLAIN_TEXT)
    }

    /// TODO(9f): port YoutubeDescriptionHelper.attributedDescriptionToHtml.
    private func attributedDescriptionToHtml(_ attributedDescription: JsonObject) -> String {
        ""
    }

    public override func getAgeLimit() throws -> Int {
        if ageLimitCached != -1 {
            return ageLimitCached
        }
        var ageRestricted = false
        for metadataRow in getVideoSecondaryInfoRenderer()
            .getObject("metadataRowContainer")
            .getObject("metadataRowContainerRenderer")
            .getArray("rows")
            .streamAsJsonObjects() {
            for content in metadataRow.getObject("metadataRowRenderer")
                .getArray("contents").streamAsJsonObjects() {
                for run in content.getArray("runs").streamAsJsonObjects()
                where (run.getString("text", "") ?? "").contains("Age-restricted") {
                    ageRestricted = true
                }
            }
        }
        ageLimitCached = ageRestricted ? 18 : StreamExtractor.NO_AGE_LIMIT
        return ageLimitCached
    }

    public override func getLength() throws -> Int64 {
        assertPageFetched()
        let duration = playerResponse.getObject(Self.VIDEO_DETAILS).getString("lengthSeconds")
        if let duration, let parsed = Int64(duration) {
            return parsed
        }
        return Int64(try getDurationFromFirstAdaptiveFormat(
            [androidStreamingData, iosStreamingData].compactMap { $0 }))
    }

    private func getDurationFromFirstAdaptiveFormat(_ streamingDatas: [JsonObject]) throws -> Int {
        for streamingData in streamingDatas {
            let adaptiveFormats = streamingData.getArray(Self.ADAPTIVE_FORMATS)
            if adaptiveFormats.isEmpty {
                continue
            }
            let durationMs = adaptiveFormats.getObject(0).getString("approxDurationMs") ?? ""
            if let ms = Double(durationMs) {
                return Int((ms / 1000).rounded())
            }
        }
        throw ParsingException("Could not get duration")
    }

    public override func getTimeStamp() throws -> Int64 {
        let timestamp = try getTimestampSeconds("((#|&|\\?)t=\\d*h?\\d*m?\\d+s?)")
        if timestamp == -2 {
            return 0  // Regex for timestamp was not found
        }
        return timestamp
    }

    public override func getViewCount() throws -> Int64 {
        var views = YoutubeParsingHelper.getTextFromObject(
            getVideoPrimaryInfoRenderer().getObject("viewCount")
                .getObject("videoViewCountRenderer").getObject("viewCount"))
        if Utils.isNullOrEmpty(views) {
            views = playerResponse.getObject(Self.VIDEO_DETAILS).getString("viewCount")
            if Utils.isNullOrEmpty(views) {
                throw ParsingException("Could not get view count")
            }
        }
        if views!.lowercased().contains("no views") {
            return 0
        }
        guard let count = Int64(Utils.removeNonDigitCharacters(views!)) else {
            throw ParsingException("Could not get view count")
        }
        return count
    }

    /// TODO(9f): port the topLevelButtons like-count parsing.
    public override func getLikeCount() throws -> Int64 {
        -1
    }

    public override func getUploaderUrl() throws -> String {
        assertPageFetched()
        let uploaderId = playerResponse.getObject(Self.VIDEO_DETAILS).getString("channelId")
        if !Utils.isNullOrEmpty(uploaderId) {
            return try YoutubeChannelLinkHandlerFactory.getInstance().getUrl(
                "channel/" + uploaderId!)
        }
        throw ParsingException("Could not get uploader url")
    }

    public override func getUploaderName() throws -> String {
        assertPageFetched()
        let uploaderName = playerResponse.getObject(Self.VIDEO_DETAILS).getString("author")
        if Utils.isNullOrEmpty(uploaderName) {
            throw ParsingException("Could not get uploader name")
        }
        return uploaderName!
    }

    public override func isUploaderVerified() throws -> Bool {
        let videoOwnerRenderer = getVideoSecondaryInfoRenderer()
            .getObject("owner").getObject("videoOwnerRenderer")
        if videoOwnerRenderer.has("badges") {
            return YoutubeParsingHelper.isVerified(videoOwnerRenderer.getArray("badges"))
        }
        guard let channel = try YoutubeParsingHelper.getFirstCollaborator(
            videoOwnerRenderer.getObject("navigationEndpoint")) else {
            return false
        }
        return YoutubeParsingHelper.hasArtistOrVerifiedIconBadgeAttachment(
            channel.getObject(Self.TITLE).getArray("attachmentRuns"))
    }

    public override func getUploaderAvatars() throws -> [Image] {
        assertPageFetched()
        let owner = getVideoSecondaryInfoRenderer().getObject("owner")
            .getObject("videoOwnerRenderer")
        let imageList: [Image]
        if owner.has("avatarStack") {
            imageList = YoutubeParsingHelper.getImagesFromThumbnailsArray(
                owner.getObject("avatarStack").getObject("avatarStackViewModel")
                    .getArray("avatars")
                    .getObject(0)
                    .getObject("avatarViewModel")
                    .getObject("image")
                    .getArray("sources"))
        } else {
            imageList = YoutubeParsingHelper.getImagesFromThumbnailsArray(
                owner.getObject(Self.THUMBNAIL).getArray(Self.THUMBNAILS))
        }
        if imageList.isEmpty && ageLimitCached == StreamExtractor.NO_AGE_LIMIT {
            throw ParsingException("Could not get uploader avatars")
        }
        return imageList
    }

    public override func getUploaderSubscriberCount() throws -> Int64 {
        let videoOwnerRenderer = try JsonUtils.getObject(
            videoSecondaryInfoRenderer ?? JsonObject(), "owner.videoOwnerRenderer")
        var subscriberCountText: String?
        if videoOwnerRenderer.has("subscriberCountText") {
            subscriberCountText = YoutubeParsingHelper.getTextFromObject(
                videoOwnerRenderer.getObject("subscriberCountText"))
        } else if let collaborator = try YoutubeParsingHelper.getFirstCollaborator(
            videoOwnerRenderer.getObject("navigationEndpoint")) {
            let content = collaborator.getObject("subtitle").getString("content") ?? ""
            let parts = content.components(separatedBy: "•")
            subscriberCountText = parts.count > 1 ? parts[1] : nil
        }

        if Utils.isNullOrEmpty(subscriberCountText) {
            return StreamExtractor.UNKNOWN_SUBSCRIBER_COUNT
        }
        do {
            return try Utils.mixedNumberWordToLong(subscriberCountText!)
        } catch {
            throw ParsingException("Could not get uploader subscriber count", error)
        }
    }

    // MARK: Manifests / streams

    public override func getDashMpdUrl() throws -> String {
        assertPageFetched()
        // No DASH manifest with the iOS and visionOS clients
        return Self.getManifestUrl(
            "dash",
            [(androidStreamingData, androidStreamingUrlsPoToken)],
            "mpd_version=7")
    }

    public override func getHlsUrl() throws -> String {
        assertPageFetched()
        // Prefer an Apple client's HLS manifest: on livestreams it has separated
        // audio/video streams, and non-Apple clients lack an HLS URL on videos.
        return Self.getManifestUrl(
            "hls",
            [
                (visionOsStreamingData, nil),
                (iosStreamingData, iosStreamingUrlsPoToken),
                (androidStreamingData, androidStreamingUrlsPoToken),
            ],
            "")
    }

    private static func getManifestUrl(
        _ manifestType: String,
        _ streamingDataObjects: [(JsonObject?, String?)],
        _ partToAppendToManifestUrlEnd: String
    ) -> String {
        let manifestKey = manifestType + "ManifestUrl"
        for (streamingData, poToken) in streamingDataObjects {
            if let streamingData {
                let manifestUrl = streamingData.getString(manifestKey)
                if Utils.isNullOrEmpty(manifestUrl) {
                    continue
                }
                if poToken == nil {
                    return manifestUrl! + "?" + partToAppendToManifestUrlEnd
                } else {
                    return manifestUrl! + "?pot=" + poToken! + "&" + partToAppendToManifestUrlEnd
                }
            }
        }
        return ""
    }

    /// TODO(9e-streams): progressive/adaptive stream URLs need JS signature +
    /// throttling deciphering and ItagInfo. HLS playback does not require them.
    public override func getAudioStreams() throws -> [AudioStream] {
        assertPageFetched()
        return []
    }

    public override func getVideoStreams() throws -> [VideoStream] {
        assertPageFetched()
        return []
    }

    public override func getVideoOnlyStreams() throws -> [VideoStream] {
        assertPageFetched()
        return []
    }

    /// TODO(9f): port caption track parsing.
    public override func getSubtitlesDefault() throws -> [SubtitlesStream] {
        []
    }

    public override func getSubtitles(_ format: MediaFormat) throws -> [SubtitlesStream] {
        []
    }

    public override func getStreamType() -> StreamType {
        assertPageFetched()
        return streamType ?? .VIDEO_STREAM
    }

    private func setStreamType() {
        if playerResponse.getObject(Self.PLAYABILITY_STATUS).has("liveStreamability") {
            streamType = .LIVE_STREAM
        } else if playerResponse.getObject(Self.VIDEO_DETAILS).getBoolean("isPostLiveDvr", false) {
            streamType = .POST_LIVE_STREAM
        } else {
            streamType = .VIDEO_STREAM
        }
    }

    /// TODO(9f): related items need the lockup/mix info-item extractors.
    public override func getRelatedItems() throws -> (any AnyInfoItemsCollector)? {
        assertPageFetched()
        return nil
    }

    public override func getErrorMessage() -> String? {
        YoutubeParsingHelper.getTextFromObject(
            playerResponse.getObject(Self.PLAYABILITY_STATUS)
                .getObject("errorScreen").getObject("playerErrorMessageRenderer")
                .getObject("reason"))
    }

    // MARK: Fetch page

    public override func onFetchPage(_ downloader: Downloader) throws {
        let videoId = try getId()
        let localization = getExtractorLocalization()
        let contentCountry = getExtractorContentCountry()

        let poTokenProviderInstance = Self.poTokenProvider
        let noPoTokenProviderSet = poTokenProviderInstance == nil

        let androidPoTokenResult = noPoTokenProviderSet
            ? nil : poTokenProviderInstance!.getAndroidClientPoToken(videoId)

        try fetchAndroidClient(localization, contentCountry, videoId, androidPoTokenResult)

        setStreamType()

        if Self.fetchIosClient {
            let iosPoTokenResult = noPoTokenProviderSet
                ? nil : poTokenProviderInstance!.getIosClientPoToken(videoId)
            fetchIosClient(localization, contentCountry, videoId, iosPoTokenResult)
        }

        fetchVisionOsClient(localization, contentCountry, videoId)

        fetchWebClientMetadataAndSetThumbnails(localization, contentCountry, videoId)

        let nextBody = JsonWriter.string(
            try YoutubeParsingHelper.prepareDesktopJsonBuilder(localization, contentCountry)
                .value(YoutubeParsingHelper.VIDEO_ID, videoId)
                .value(YoutubeParsingHelper.CONTENT_CHECK_OK, true)
                .value(YoutubeParsingHelper.RACY_CHECK_OK, true)
                .done())
            .data(using: .utf8)
        nextResponse = try YoutubeParsingHelper.getJsonPostResponse(Self.NEXT, nextBody, localization)
    }

    private static func checkPlayabilityStatus(_ playabilityStatus: JsonObject) throws {
        let status = playabilityStatus.getString("status")
        if status == nil || status!.caseInsensitiveEquals("ok") {
            return
        }
        let reason = playabilityStatus.getString("reason")
        if let status, let reason {
            if status.caseInsensitiveEquals("login_required") {
                if reason.contains("inappropriate for some users") {
                    throw AgeRestrictedContentException(
                        "This age-restricted video cannot be watched anonymously")
                }
                if reason.contains("private") {
                    throw PrivateContentException("This video is private")
                }
                if reason.contains("a bot") {
                    throw SignInConfirmNotBotException(
                        "YouTube probably temporarily blocked anonymous watch access with this IP"
                        + " , got error \(status): \"\(reason)\"")
                }
            }
            if status.caseInsensitiveEquals("unplayable") || status.caseInsensitiveEquals("error") {
                if reason.contains("Music Premium") {
                    throw YoutubeMusicPremiumContentException()
                }
                if reason.contains("payment") {
                    throw PaidContentException("This video is a paid video")
                }
                if reason.contains("members") {
                    throw PaidContentException(
                        "This video is only available for members of the channel of this video")
                }
                if reason.contains("country") {
                    throw GeographicRestrictionException(
                        "This video is not available in client's country.")
                }
                if reason.contains("closed") || reason.contains("terminated") {
                    throw AccountTerminatedException(reason)
                }
            }
        }
        throw ContentNotAvailableException("Got error \(status ?? "null"): \"\(reason ?? "null")\"")
    }

    private func fetchAndroidClient(
        _ localization: Localization, _ contentCountry: ContentCountry,
        _ videoId: String, _ androidPoTokenResult: PoTokenResult?
    ) throws {
        androidCpn = YoutubeParsingHelper.generateContentPlaybackNonce()

        if let androidPoTokenResult {
            playerResponse = try YoutubeStreamHelper.getAndroidPlayerResponse(
                contentCountry, localization, videoId, androidCpn, androidPoTokenResult)
        } else {
            playerResponse = try YoutubeStreamHelper.getAndroidReelPlayerResponse(
                contentCountry, localization, videoId, androidCpn)
        }

        try Self.checkPlayabilityStatus(playerResponse.getObject(Self.PLAYABILITY_STATUS))
        if Self.isPlayerResponseNotValid(playerResponse, videoId) {
            throw ExtractionException("ANDROID player response is not valid")
        }

        androidStreamingData = playerResponse.getObject(Self.STREAMING_DATA)
        playerCaptionsTracklistRenderer = playerResponse.getObject(Self.CAPTIONS)
            .getObject(Self.PLAYER_CAPTIONS_TRACKLIST_RENDERER)

        if let androidPoTokenResult {
            androidStreamingUrlsPoToken = androidPoTokenResult.streamingDataPoToken
        }
    }

    private func fetchIosClient(
        _ localization: Localization, _ contentCountry: ContentCountry,
        _ videoId: String, _ iosPoTokenResult: PoTokenResult?
    ) {
        do {
            iosCpn = YoutubeParsingHelper.generateContentPlaybackNonce()
            let iosPlayerResponse = try YoutubeStreamHelper.getIosPlayerResponse(
                contentCountry, localization, videoId, iosCpn, iosPoTokenResult)

            if !Self.isPlayerResponseNotValid(iosPlayerResponse, videoId) {
                iosStreamingData = iosPlayerResponse.getObject(Self.STREAMING_DATA)
                if Utils.isNullOrEmpty(playerCaptionsTracklistRenderer) {
                    playerCaptionsTracklistRenderer = iosPlayerResponse.getObject(Self.CAPTIONS)
                        .getObject(Self.PLAYER_CAPTIONS_TRACKLIST_RENDERER)
                }
                if let iosPoTokenResult {
                    iosStreamingUrlsPoToken = iosPoTokenResult.streamingDataPoToken
                }
            }
        } catch {
            // iOS client fetching/parsing is not compulsory to play contents
        }
    }

    private func fetchVisionOsClient(
        _ localization: Localization, _ contentCountry: ContentCountry, _ videoId: String
    ) {
        do {
            visionOsCpn = YoutubeParsingHelper.generateContentPlaybackNonce()
            let visionOsPlayerResponse = try YoutubeStreamHelper.getVisionOsPlayerResponse(
                contentCountry, localization, videoId, visionOsCpn)

            if !Self.isPlayerResponseNotValid(visionOsPlayerResponse, videoId) {
                visionOsStreamingData = visionOsPlayerResponse.getObject(Self.STREAMING_DATA)
                if Utils.isNullOrEmpty(playerCaptionsTracklistRenderer) {
                    playerCaptionsTracklistRenderer =
                        visionOsPlayerResponse.getObject(Self.CAPTIONS)
                        .getObject(Self.PLAYER_CAPTIONS_TRACKLIST_RENDERER)
                }
            }
        } catch {
            // visionOS client fetching/parsing is not compulsory to play contents
        }
    }

    private func fetchWebClientMetadataAndSetThumbnails(
        _ localization: Localization, _ contentCountry: ContentCountry, _ videoId: String
    ) {
        do {
            let webPlayerResponse = try YoutubeStreamHelper.getWebMetadataPlayerResponse(
                localization, contentCountry, videoId)

            // Used exclusively for metadata, so playability status is not checked
            // (metadata may be present even on a playability error).
            if !Self.isPlayerResponseNotValid(webPlayerResponse, videoId) {
                // The microformat is only returned on the WEB client.
                playerMicroFormatRenderer = webPlayerResponse.getObject("microformat")
                    .getObject("playerMicroformatRenderer")

                let thumbnailWebJsonObj = webPlayerResponse.getObject(Self.VIDEO_DETAILS)
                    .getObject(Self.THUMBNAIL)
                if thumbnailWebJsonObj.has(Self.THUMBNAILS) {
                    thumbnailsArray = thumbnailWebJsonObj.getArray(Self.THUMBNAILS)
                } else {
                    thumbnailsArray = playerResponse.getObject(Self.VIDEO_DETAILS)
                        .getObject(Self.THUMBNAIL).getArray(Self.THUMBNAILS)
                }
            }
        } catch {
            // WEB client fetching/parsing is not compulsory; fall back to playerResponse
            playerMicroFormatRenderer = JsonObject()
            thumbnailsArray = playerResponse.getObject(Self.VIDEO_DETAILS)
                .getObject(Self.THUMBNAIL).getArray(Self.THUMBNAILS)
        }
    }

    private static func isPlayerResponseNotValid(
        _ playerResponse: JsonObject, _ videoId: String
    ) -> Bool {
        videoId != playerResponse.getObject(VIDEO_DETAILS).getString("videoId")
    }

    // MARK: Utils

    private func getVideoPrimaryInfoRenderer() -> JsonObject {
        if let videoPrimaryInfoRenderer {
            return videoPrimaryInfoRenderer
        }
        let renderer = getVideoInfoRenderer("videoPrimaryInfoRenderer")
        videoPrimaryInfoRenderer = renderer
        return renderer
    }

    private func getVideoSecondaryInfoRenderer() -> JsonObject {
        if let videoSecondaryInfoRenderer {
            return videoSecondaryInfoRenderer
        }
        let renderer = getVideoInfoRenderer("videoSecondaryInfoRenderer")
        videoSecondaryInfoRenderer = renderer
        return renderer
    }

    private func getVideoInfoRenderer(_ videoRendererName: String) -> JsonObject {
        for content in nextResponse.getObject("contents")
            .getObject("twoColumnWatchNextResults")
            .getObject("results")
            .getObject("results")
            .getArray("contents")
            .streamAsJsonObjects()
        where content.has(videoRendererName) {
            return content.getObject(videoRendererName)
        }
        return JsonObject()
    }
}
