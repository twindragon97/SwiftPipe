// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/ListInfo.java @ v0.26.3

open class ListInfo<T: InfoItem>: Info {
    private var relatedItems: [T] = []
    private var nextPage: Page?
    private let contentFilters: [String]
    private let sortFilter: String

    public init(
        _ serviceId: Int,
        _ id: String,
        _ url: String,
        _ originalUrl: String,
        _ name: String,
        _ contentFilter: [String],
        _ sortFilter: String
    ) {
        self.contentFilters = contentFilter
        self.sortFilter = sortFilter
        super.init(serviceId, id, url, originalUrl, name)
    }

    public init(
        _ serviceId: Int,
        _ listUrlIdHandler: ListLinkHandler,
        _ name: String
    ) {
        self.contentFilters = listUrlIdHandler.getContentFilters()
        self.sortFilter = listUrlIdHandler.getSortFilter()
        super.init(serviceId, listUrlIdHandler, name)
    }

    public func getRelatedItems() -> [T] {
        relatedItems
    }

    public func setRelatedItems(_ relatedItems: [T]) {
        self.relatedItems = relatedItems
    }

    public func hasNextPage() -> Bool {
        Page.isValid(nextPage)
    }

    public func getNextPage() -> Page? {
        nextPage
    }

    public func setNextPage(_ page: Page?) {
        self.nextPage = page
    }

    public func getContentFilters() -> [String] {
        contentFilters
    }

    public func getSortFilter() -> String {
        sortFilter
    }
}
