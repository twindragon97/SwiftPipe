// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/linkhandler/SearchQueryHandler.java @ v0.26.3

open class SearchQueryHandler: ListLinkHandler {
    public init(
        _ originalUrl: String,
        _ url: String,
        _ searchString: String,
        _ contentFilters: [String],
        _ sortFilter: String
    ) {
        super.init(originalUrl, url, searchString, contentFilters, sortFilter)
    }

    public convenience init(_ handler: ListLinkHandler) {
        self.init(
            handler.originalUrl,
            handler.url,
            handler.id,
            handler.contentFilters,
            handler.sortFilter)
    }

    /// Returns the search string; equivalent to calling getId().
    public func getSearchString() -> String {
        getId()
    }
}
