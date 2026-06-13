// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/search/SearchExtractor.java @ v0.26.3

open class SearchExtractor: ListExtractor<InfoItem> {
    public final class NothingFoundException: ExtractionException {}

    public init(_ service: StreamingService, _ linkHandler: SearchQueryHandler) {
        super.init(service, linkHandler)
    }

    public func getSearchString() -> String {
        getLinkHandler().getSearchString()
    }

    open func getSearchSuggestion() throws -> String {
        preconditionFailure("SearchExtractor.getSearchSuggestion must be overridden")
    }

    open override func getLinkHandler() -> SearchQueryHandler {
        super.getLinkHandler() as! SearchQueryHandler
    }

    open override func getName() throws -> String {
        getLinkHandler().getSearchString()
    }

    open func isCorrectedSearch() throws -> Bool {
        preconditionFailure("SearchExtractor.isCorrectedSearch must be overridden")
    }

    open func getMetaInfo() throws -> [MetaInfo] {
        preconditionFailure("SearchExtractor.getMetaInfo must be overridden")
    }
}
