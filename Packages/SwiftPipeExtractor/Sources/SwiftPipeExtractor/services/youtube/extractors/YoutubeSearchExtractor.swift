// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/extractors/YoutubeSearchExtractor.java @ v0.26.3
//
// Deviations (to be removed in a later YouTube sub-batch):
//  - collectStreamsFrom does not yet handle showRenderer / lockupViewModel
//    items (YoutubeShowRendererInfoItemExtractor /
//    YoutubeMixOrPlaylistLockupInfoItemExtractor /
//    YoutubeStreamInfoItemLockupExtractor not ported). Those item types are
//    skipped; videoRenderer/channelRenderer/playlistRenderer are handled.
//  - getMetaInfo returns [] (YoutubeMetaInfoHelper not ported yet).

import Foundation
import NanoJSON

public final class YoutubeSearchExtractor: SearchExtractor {
    private let searchType: String?
    private let extractVideoResults: Bool
    private let extractChannelResults: Bool
    private let extractPlaylistResults: Bool
    private var initialData = JsonObject()

    public override init(_ service: StreamingService, _ linkHandler: SearchQueryHandler) {
        let contentFilters = linkHandler.getContentFilters()
        let searchType = Utils.isNullOrEmpty(contentFilters) ? nil : contentFilters[0]
        self.searchType = searchType
        // YouTube sometimes returns videos inside channel search results, so
        // extract everything when no type or the ALL filter is requested.
        let all = YoutubeSearchQueryHandlerFactory.ALL
        extractVideoResults = searchType == nil || searchType == all
            || searchType == YoutubeSearchQueryHandlerFactory.VIDEOS
        extractChannelResults = searchType == nil || searchType == all
            || searchType == YoutubeSearchQueryHandlerFactory.CHANNELS
        extractPlaylistResults = searchType == nil || searchType == all
            || searchType == YoutubeSearchQueryHandlerFactory.PLAYLISTS
        super.init(service, linkHandler)
    }

    public override func onFetchPage(_ downloader: Downloader) throws {
        let query = getSearchString()
        let localization = getExtractorLocalization()
        let params = YoutubeSearchQueryHandlerFactory.getSearchParameter(searchType)
        let jsonBody = try YoutubeParsingHelper.prepareDesktopJsonBuilder(
            localization, getExtractorContentCountry())
            .value("query", query)
        if !Utils.isNullOrEmpty(params) {
            jsonBody.value("params", params)
        }
        let body = JsonWriter.string(jsonBody.done()).data(using: .utf8)
        initialData = try YoutubeParsingHelper.getJsonPostResponse("search", body, localization)
    }

    public override func getUrl() throws -> String {
        try super.getUrl() + "&gl=" + getExtractorContentCountry().getCountryCode()
    }

    public override func getSearchSuggestion() throws -> String {
        let itemSectionRenderer = initialData.getObject("contents")
            .getObject("twoColumnSearchResultsRenderer")
            .getObject("primaryContents")
            .getObject("sectionListRenderer")
            .getArray("contents")
            .getObject(0)
            .getObject("itemSectionRenderer")
        let didYouMeanRenderer = itemSectionRenderer.getArray("contents")
            .getObject(0)
            .getObject("didYouMeanRenderer")
        if !didYouMeanRenderer.isEmpty {
            return try JsonUtils.getString(
                didYouMeanRenderer, "correctedQueryEndpoint.searchEndpoint.query")
        }
        return YoutubeParsingHelper.getTextFromObject(
            itemSectionRenderer.getArray("contents")
                .getObject(0)
                .getObject("showingResultsForRenderer")
                .getObject("correctedQuery")) ?? ""
    }

    public override func isCorrectedSearch() throws -> Bool {
        let showingResultsForRenderer = initialData.getObject("contents")
            .getObject("twoColumnSearchResultsRenderer").getObject("primaryContents")
            .getObject("sectionListRenderer").getArray("contents").getObject(0)
            .getObject("itemSectionRenderer").getArray("contents").getObject(0)
            .getObject("showingResultsForRenderer")
        return !showingResultsForRenderer.isEmpty
    }

    public override func getMetaInfo() throws -> [MetaInfo] {
        // TODO(9f): port YoutubeMetaInfoHelper.getMetaInfo
        []
    }

    public override func getInitialPage() throws -> InfoItemsPage<InfoItem> {
        let collector = MultiInfoItemsCollector(getServiceId())
        let sections = initialData.getObject("contents")
            .getObject("twoColumnSearchResultsRenderer")
            .getObject("primaryContents")
            .getObject("sectionListRenderer")
            .getArray("contents")

        var nextPage: Page?
        for sectionJsonObject in sections.streamAsJsonObjects() {
            if sectionJsonObject.has("itemSectionRenderer") {
                let itemSectionRenderer = sectionJsonObject.getObject("itemSectionRenderer")
                try collectStreamsFrom(collector, itemSectionRenderer.getArray("contents"))
            } else if sectionJsonObject.has("continuationItemRenderer") {
                nextPage = getNextPageFrom(
                    sectionJsonObject.getObject("continuationItemRenderer"))
            }
        }

        return InfoItemsPage(collector, nextPage)
    }

    public override func getPage(_ page: Page?) throws -> InfoItemsPage<InfoItem> {
        guard let page, !Utils.isNullOrEmpty(page.getUrl()) else {
            preconditionFailure("Page doesn't contain an URL")
        }

        let localization = getExtractorLocalization()
        let collector = MultiInfoItemsCollector(getServiceId())

        let json = JsonWriter.string(
            try YoutubeParsingHelper.prepareDesktopJsonBuilder(
                localization, getExtractorContentCountry())
                .value("continuation", page.getId())
                .done())
            .data(using: .utf8)

        let ajaxJson = try YoutubeParsingHelper.getJsonPostResponse("search", json, localization)
        let continuationItems = ajaxJson.getArray("onResponseReceivedCommands")
            .getObject(0)
            .getObject("appendContinuationItemsAction")
            .getArray("continuationItems")
        let contents = continuationItems.getObject(0)
            .getObject("itemSectionRenderer")
            .getArray("contents")
        try collectStreamsFrom(collector, contents)

        return InfoItemsPage(
            collector,
            getNextPageFrom(continuationItems.getObject(1).getObject("continuationItemRenderer")))
    }

    private func collectStreamsFrom(
        _ collector: MultiInfoItemsCollector, _ contents: JsonArray
    ) throws {
        let timeAgoParser = getTimeAgoParser()

        for item in contents.streamAsJsonObjects() {
            if item.has("backgroundPromoRenderer") {
                throw NothingFoundException(
                    YoutubeParsingHelper.getTextFromObject(
                        item.getObject("backgroundPromoRenderer").getObject("bodyText")) ?? "")
            } else if item.has("videoRenderer") && extractVideoResults {
                collector.commit(YoutubeStreamInfoItemExtractor(
                    item.getObject("videoRenderer"), timeAgoParser))
            } else if item.has("channelRenderer") && extractChannelResults {
                collector.commit(YoutubeChannelInfoItemExtractor(
                    item.getObject("channelRenderer")))
            } else if item.has("playlistRenderer") && extractPlaylistResults {
                collector.commit(YoutubePlaylistInfoItemExtractor(
                    item.getObject("playlistRenderer")))
            }
            // TODO(9f): showRenderer / lockupViewModel (playlist/podcast/video)
        }
    }

    private func getNextPageFrom(_ continuationItemRenderer: JsonObject) -> Page? {
        if Utils.isNullOrEmpty(continuationItemRenderer) {
            return nil
        }
        let token = continuationItemRenderer.getObject("continuationEndpoint")
            .getObject("continuationCommand")
            .getString("token")
        let url = YoutubeParsingHelper.YOUTUBEI_V1_URL + "search?"
            + YoutubeParsingHelper.DISABLE_PRETTY_PRINT_PARAMETER
        return Page(url, token)
    }
}
