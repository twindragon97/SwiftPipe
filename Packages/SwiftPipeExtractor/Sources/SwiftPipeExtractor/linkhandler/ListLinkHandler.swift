// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/linkhandler/ListLinkHandler.java @ v0.26.3

open class ListLinkHandler: LinkHandler {
    public let contentFilters: [String]
    public let sortFilter: String

    public init(
        _ originalUrl: String,
        _ url: String,
        _ id: String,
        _ contentFilters: [String],
        _ sortFilter: String
    ) {
        self.contentFilters = contentFilters
        self.sortFilter = sortFilter
        super.init(originalUrl, url, id)
    }

    public convenience init(_ handler: ListLinkHandler) {
        self.init(
            handler.originalUrl,
            handler.url,
            handler.id,
            handler.contentFilters,
            handler.sortFilter)
    }

    public convenience init(_ handler: LinkHandler) {
        self.init(handler.originalUrl, handler.url, handler.id, [], "")
    }

    public func getContentFilters() -> [String] {
        contentFilters
    }

    public func getSortFilter() -> String {
        sortFilter
    }
}
