// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/extractors/YoutubeStreamInfoItemExtractor.java @ v0.26.3
//
// java.time (Instant/LocalDateTime/DateTimeFormatter) maps to Foundation
// Date/DateFormatter. getStreamType is implemented non-throwing (satisfies the
// throwing protocol requirement) since the Java version doesn't throw.

import Foundation
import NanoJSON

public final class YoutubeStreamInfoItemExtractor: StreamInfoItemExtractor {
    private static let ACCESSIBILITY_DATA_VIEW_COUNT_REGEX =
        Pattern.compile("([\\d,]+) views$")
    private static let NO_VIEWS_LOWERCASE = "no views"

    private let videoInfo: JsonObject
    private let timeAgoParser: TimeAgoParser?
    private var cachedStreamType: StreamType?
    private var isPremiereCached: Bool?

    public init(_ videoInfoItem: JsonObject, _ timeAgoParser: TimeAgoParser?) {
        self.videoInfo = videoInfoItem
        self.timeAgoParser = timeAgoParser
    }

    public func getStreamType() -> StreamType {
        if let cachedStreamType {
            return cachedStreamType
        }

        for badge in videoInfo.getArray("badges").streamAsJsonObjects() {
            let badgeRenderer = badge.getObject("metadataBadgeRenderer")
            if badgeRenderer.getString("style", "") == "BADGE_STYLE_TYPE_LIVE_NOW"
                || badgeRenderer.getString("label", "") == "LIVE NOW" {
                cachedStreamType = .LIVE_STREAM
                return .LIVE_STREAM
            }
        }

        for overlay in videoInfo.getArray("thumbnailOverlays").streamAsJsonObjects() {
            let style = overlay.getObject("thumbnailOverlayTimeStatusRenderer")
                .getString("style", "") ?? ""
            if style.caseInsensitiveEquals("LIVE") {
                cachedStreamType = .LIVE_STREAM
                return .LIVE_STREAM
            }
        }

        cachedStreamType = .VIDEO_STREAM
        return .VIDEO_STREAM
    }

    public func isAd() throws -> Bool {
        try isPremium() || getName() == "[Private video]" || getName() == "[Deleted video]"
    }

    public func getUrl() throws -> String {
        do {
            let videoId = videoInfo.getString("videoId") ?? ""
            return try YoutubeStreamLinkHandlerFactory.getInstance().getUrl(videoId)
        } catch {
            throw ParsingException("Could not get url", error)
        }
    }

    public func getName() throws -> String {
        let title = videoInfo.getObject("title")
        let name = YoutubeParsingHelper.getTextFromObject(title)
        if !Utils.isNullOrEmpty(name) {
            return name!
        }
        // Videos can have no title, e.g. watch?v=nc1kN8ZSfGQ
        if !Utils.isNullOrEmpty(title) && !title.has("runs") {
            return ""
        }
        throw ParsingException("Could not get name")
    }

    public func getDuration() throws -> Int64 {
        if getStreamType() == .LIVE_STREAM {
            return -1
        }

        var duration = YoutubeParsingHelper.getTextFromObject(videoInfo.getObject("lengthText"))

        if Utils.isNullOrEmpty(duration) {
            // Available in playlists for videos
            duration = videoInfo.getString("lengthSeconds")

            if Utils.isNullOrEmpty(duration) {
                let timeOverlays = videoInfo.getArray("thumbnailOverlays")
                    .streamAsJsonObjects()
                    .filter { $0.has("thumbnailOverlayTimeStatusRenderer") }
                    .compactMap {
                        YoutubeParsingHelper.getTextFromObject(
                            $0.getObject("thumbnailOverlayTimeStatusRenderer").getObject("text"))
                    }
                    .filter { !Utils.isNullOrEmpty($0) }

                for timeOverlayText in timeOverlays {
                    if let parsed = try? YoutubeParsingHelper.parseDurationString(timeOverlayText) {
                        return Int64(parsed)
                    }
                }
            }

            if Utils.isNullOrEmpty(duration) {
                if isPremiere() {
                    // Premieres can be livestreams, so no duration here
                    return -1
                }
                throw ParsingException("Could not get duration")
            }
        }

        return Int64(try YoutubeParsingHelper.parseDurationString(duration!))
    }

    public func getUploaderName() throws -> String? {
        var name = YoutubeParsingHelper.getTextFromObject(videoInfo.getObject("longBylineText"))
        if Utils.isNullOrEmpty(name) {
            name = YoutubeParsingHelper.getTextFromObject(videoInfo.getObject("ownerText"))
            if Utils.isNullOrEmpty(name) {
                name = YoutubeParsingHelper.getTextFromObject(
                    videoInfo.getObject("shortBylineText"))
                if Utils.isNullOrEmpty(name) {
                    throw ParsingException("Could not get uploader name")
                }
            }
        }
        return name
    }

    public func getUploaderUrl() throws -> String? {
        var url = YoutubeParsingHelper.getUrlFromNavigationEndpoint(
            videoInfo.getObject("longBylineText").getArray("runs").getObject(0)
                .getObject("navigationEndpoint"))
        if Utils.isNullOrEmpty(url) {
            url = YoutubeParsingHelper.getUrlFromNavigationEndpoint(
                videoInfo.getObject("ownerText").getArray("runs").getObject(0)
                    .getObject("navigationEndpoint"))
            if Utils.isNullOrEmpty(url) {
                url = YoutubeParsingHelper.getUrlFromNavigationEndpoint(
                    videoInfo.getObject("shortBylineText").getArray("runs").getObject(0)
                        .getObject("navigationEndpoint"))
                if Utils.isNullOrEmpty(url) {
                    throw ParsingException("Could not get uploader url")
                }
            }
        }
        return url
    }

    public func getUploaderAvatars() throws -> [Image] {
        if videoInfo.has("channelThumbnailSupportedRenderers") {
            return YoutubeParsingHelper.getImagesFromThumbnailsArray(
                try JsonUtils.getArray(
                    videoInfo,
                    "channelThumbnailSupportedRenderers.channelThumbnailWithLinkRenderer"
                    + ".thumbnail.thumbnails"))
        }
        if videoInfo.has("channelThumbnail") {
            return YoutubeParsingHelper.getImagesFromThumbnailsArray(
                try JsonUtils.getArray(videoInfo, "channelThumbnail.thumbnails"))
        }
        return []
    }

    public func isUploaderVerified() throws -> Bool {
        YoutubeParsingHelper.isVerified(videoInfo.getArray("ownerBadges"))
    }

    public func getTextualUploadDate() throws -> String? {
        if getStreamType() == .LIVE_STREAM {
            return nil
        }

        if isPremiere() {
            return Self.premiereFormatter.string(from: try getInstantFromPremiere())
        }

        var publishedTimeText = YoutubeParsingHelper.getTextFromObject(
            videoInfo.getObject("publishedTimeText"))

        if Utils.isNullOrEmpty(publishedTimeText) && videoInfo.has("videoInfo") {
            // Returned in playlists: view count separator upload date
            publishedTimeText = videoInfo.getObject("videoInfo")
                .getArray("runs").getObject(2).getString("text")
        }

        return Utils.isNullOrEmpty(publishedTimeText) ? nil : publishedTimeText
    }

    public func getUploadDate() throws -> DateWrapper? {
        if getStreamType() == .LIVE_STREAM {
            return nil
        }

        if isPremiere() {
            return DateWrapper(try getInstantFromPremiere())
        }

        let textualUploadDate = try getTextualUploadDate()
        if let timeAgoParser, !Utils.isNullOrEmpty(textualUploadDate) {
            do {
                return try timeAgoParser.parse(textualUploadDate!)
            } catch {
                throw ParsingException("Could not get upload date", error)
            }
        }
        return nil
    }

    public func getViewCount() throws -> Int64 {
        if isPremium() || isPremiere() {
            return -1
        }

        // The view count can be hidden by creators; ignore all exceptions.
        let viewCountText = YoutubeParsingHelper.getTextFromObject(
            videoInfo.getObject("viewCountText"))
        if !Utils.isNullOrEmpty(viewCountText) {
            if let count = try? getViewCountFromViewCountText(viewCountText!, false) {
                return count
            }
        }

        // Parse the real view count from accessibility data, unless it's a
        // running livestream.
        if getStreamType() != .LIVE_STREAM {
            if let count = try? getViewCountFromAccessibilityData() {
                return count
            }
        }

        // Fallback to a short view count (always used for livestreams).
        if videoInfo.has("videoInfo") {
            if let count = try? getViewCountFromViewCountText(
                videoInfo.getObject("videoInfo").getArray("runs").getObject(0)
                    .getString("text", "") ?? "", true) {
                return count
            }
        }

        if videoInfo.has("shortViewCountText") {
            let shortViewCountText = YoutubeParsingHelper.getTextFromObject(
                videoInfo.getObject("shortViewCountText"))
            if !Utils.isNullOrEmpty(shortViewCountText),
               let count = try? getViewCountFromViewCountText(shortViewCountText!, true) {
                return count
            }
        }

        // No view count extracted (creators can hide it).
        return -1
    }

    private func getViewCountFromViewCountText(
        _ viewCountText: String, _ isMixedNumber: Bool
    ) throws -> Int64 {
        // These approaches are language dependent
        if viewCountText.lowercased().contains(Self.NO_VIEWS_LOWERCASE) {
            return 0
        } else if viewCountText.lowercased().contains("recommended") {
            return -1
        }

        if isMixedNumber {
            return try Utils.mixedNumberWordToLong(viewCountText)
        }
        guard let count = Int64(Utils.removeNonDigitCharacters(viewCountText)) else {
            throw ParsingException("Could not parse view count")
        }
        return count
    }

    private func getViewCountFromAccessibilityData() throws -> Int64 {
        let videoInfoTitleAccessibilityData = videoInfo.getObject("title")
            .getObject("accessibility")
            .getObject("accessibilityData")
            .getString("label", "") ?? ""

        if videoInfoTitleAccessibilityData.lowercased().hasSuffix(Self.NO_VIEWS_LOWERCASE) {
            return 0
        }

        guard let count = Int64(Utils.removeNonDigitCharacters(
            try Parser.matchGroup1(
                Self.ACCESSIBILITY_DATA_VIEW_COUNT_REGEX, videoInfoTitleAccessibilityData))) else {
            throw ParsingException("Could not parse view count from accessibility data")
        }
        return count
    }

    public func getThumbnails() throws -> [Image] {
        try YoutubeParsingHelper.getThumbnailsFromInfoItem(videoInfo)
    }

    private func isPremium() -> Bool {
        for badge in videoInfo.getArray("badges").streamAsJsonObjects()
        where badge.getObject("metadataBadgeRenderer").getString("label", "") == "Premium" {
            return true
        }
        return false
    }

    private func isPremiere() -> Bool {
        if isPremiereCached == nil {
            isPremiereCached = videoInfo.has("upcomingEventData")
        }
        return isPremiereCached!
    }

    private func getInstantFromPremiere() throws -> Date {
        let upcomingEventData = videoInfo.getObject("upcomingEventData")
        let startTime = upcomingEventData.getString("startTime") ?? ""
        guard let seconds = TimeInterval(startTime) else {
            throw ParsingException("Could not parse date from premiere: \"\(startTime)\"")
        }
        return Date(timeIntervalSince1970: seconds)
    }

    public func getShortDescription() throws -> String? {
        if videoInfo.has("detailedMetadataSnippets") {
            return YoutubeParsingHelper.getTextFromObject(
                videoInfo.getArray("detailedMetadataSnippets").getObject(0)
                    .getObject("snippetText"))
        }
        if videoInfo.has("descriptionSnippet") {
            return YoutubeParsingHelper.getTextFromObject(
                videoInfo.getObject("descriptionSnippet"))
        }
        return nil
    }

    public func isShortFormContent() throws -> Bool {
        let webPageType = videoInfo.getObject("navigationEndpoint")
            .getObject("commandMetadata").getObject("webCommandMetadata")
            .getString("webPageType")

        var isShort = !Utils.isNullOrEmpty(webPageType)
            && webPageType == "WEB_PAGE_TYPE_SHORTS"

        if !isShort {
            isShort = videoInfo.getObject("navigationEndpoint").has("reelWatchEndpoint")
        }

        if !isShort && videoInfo.has("thumbnailOverlays") {
            isShort = videoInfo.getArray("thumbnailOverlays")
                .streamAsJsonObjects()
                .filter { $0.has("thumbnailOverlayTimeStatusRenderer") }
                .map { $0.getObject("thumbnailOverlayTimeStatusRenderer") }
                .contains { timeOverlay in
                    (timeOverlay.getString("style", "") ?? "").caseInsensitiveEquals("SHORTS")
                        || (timeOverlay.getObject("icon").getString("iconType", "") ?? "")
                            .lowercased().contains("shorts")
                }
        }

        return isShort
    }

    private func isMembersOnly() -> Bool {
        videoInfo.getArray("badges").streamAsJsonObjects()
            .contains {
                $0.getObject("metadataBadgeRenderer").getString("style")
                    == "BADGE_STYLE_TYPE_MEMBERS_ONLY"
            }
    }

    public func getContentAvailability() throws -> ContentAvailability {
        if isPremiere() {
            return .UPCOMING
        }
        if isMembersOnly() {
            return .MEMBERSHIP
        }
        if isPremium() {
            return .PAID
        }
        return .AVAILABLE
    }

    private static let premiereFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}
