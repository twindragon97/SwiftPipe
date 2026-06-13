// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/Extractor.java @ v0.26.3

import TimeAgoParser

open class Extractor {
    /// StreamingService currently related to this extractor.
    private let service: StreamingService
    private let linkHandler: LinkHandler
    private var forcedLocalization: Localization?
    private var forcedContentCountry: ContentCountry?
    private var pageFetched = false
    private let downloader: Downloader

    public init(_ service: StreamingService, _ linkHandler: LinkHandler) {
        self.service = service
        self.linkHandler = linkHandler
        guard let downloader = NewPipe.getDownloader() else {
            preconditionFailure("downloader is null")
        }
        self.downloader = downloader
    }

    /// The LinkHandler of the current extractor object.
    open func getLinkHandler() -> LinkHandler {
        linkHandler
    }

    /// Fetch the current page.
    public func fetchPage() throws {
        if pageFetched {
            return
        }
        try onFetchPage(downloader)
        pageFetched = true
    }

    public func assertPageFetched() {
        precondition(pageFetched, "Page is not fetched. Make sure you call fetchPage()")
    }

    public func isPageFetched() -> Bool {
        pageFetched
    }

    /// Fetch the current page (Java: abstract).
    open func onFetchPage(_ downloader: Downloader) throws {
        preconditionFailure("Extractor.onFetchPage must be overridden")
    }

    open func getId() throws -> String {
        linkHandler.getId()
    }

    /// Get the name (Java: abstract).
    open func getName() throws -> String {
        preconditionFailure("Extractor.getName must be overridden")
    }

    open func getOriginalUrl() throws -> String {
        linkHandler.getOriginalUrl()
    }

    open func getUrl() throws -> String {
        linkHandler.getUrl()
    }

    open func getBaseUrl() throws -> String {
        try linkHandler.getBaseUrl()
    }

    public func getService() -> StreamingService {
        service
    }

    public func getServiceId() -> Int {
        service.getServiceId()
    }

    public func getDownloader() -> Downloader {
        downloader
    }

    // MARK: Localization

    public func forceLocalization(_ localization: Localization) {
        forcedLocalization = localization
    }

    public func forceContentCountry(_ contentCountry: ContentCountry) {
        forcedContentCountry = contentCountry
    }

    public func getExtractorLocalization() -> Localization {
        forcedLocalization ?? getService().getLocalization()
    }

    public func getExtractorContentCountry() -> ContentCountry {
        forcedContentCountry ?? getService().getContentCountry()
    }

    public func getTimeAgoParser() -> TimeAgoParser {
        getService().getTimeAgoParser(getExtractorLocalization())
    }
}
