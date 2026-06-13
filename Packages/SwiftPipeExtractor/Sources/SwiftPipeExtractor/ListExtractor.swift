// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/ListExtractor.java @ v0.26.3
//
// Deviations: the ITEM_COUNT_* constants are computed properties (Swift
// forbids static stored properties in generic types) and Java's static
// nested InfoItemsPage is a top-level generic class. emptyPage() returns a
// fresh immutable instance instead of a shared one.

open class ListExtractor<R: InfoItem>: Extractor {
    /// Constant that should be returned whenever a list has an unknown
    /// number of items.
    public static var ITEM_COUNT_UNKNOWN: Int64 { -1 }
    /// Constant that should be returned whenever a list has an infinite
    /// number of items, for example a YouTube mix.
    public static var ITEM_COUNT_INFINITE: Int64 { -2 }
    /// Constant that should be returned whenever a list has an unknown
    /// number of items bigger than 100.
    public static var ITEM_COUNT_MORE_THAN_100: Int64 { -3 }

    public init(_ service: StreamingService, _ linkHandler: ListLinkHandler) {
        super.init(service, linkHandler)
    }

    /// The initial page of items (Java: abstract).
    open func getInitialPage() throws -> InfoItemsPage<R> {
        preconditionFailure("ListExtractor.getInitialPage must be overridden")
    }

    /// The items corresponding to a specific requested page (Java: abstract).
    open func getPage(_ page: Page?) throws -> InfoItemsPage<R> {
        preconditionFailure("ListExtractor.getPage must be overridden")
    }

    open override func getLinkHandler() -> ListLinkHandler {
        super.getLinkHandler() as! ListLinkHandler
    }
}

/// A list of gathered items and eventual errors, with a pointer to the next
/// available page (Java: ListExtractor.InfoItemsPage).
public final class InfoItemsPage<T: InfoItem> {
    /// A representation of an empty page.
    public static func emptyPage() -> InfoItemsPage<T> {
        InfoItemsPage([], nil, [])
    }

    /// The current list of items of this page.
    private let itemsList: [T]
    /// Page pointing to the next page relative to this one.
    private let nextPage: Page?
    /// Errors that happened during the extraction.
    private let errors: [Error]

    public convenience init<E>(
        _ collector: InfoItemsCollector<T, E>, _ nextPage: Page?
    ) {
        self.init(collector.getItems(), nextPage, collector.getErrors())
    }

    public init(_ itemsList: [T], _ nextPage: Page?, _ errors: [Error]) {
        self.itemsList = itemsList
        self.nextPage = nextPage
        self.errors = errors
    }

    public func hasNextPage() -> Bool {
        Page.isValid(nextPage)
    }

    public func getItems() -> [T] {
        itemsList
    }

    /// The next page if available, or nil otherwise.
    public func getNextPage() -> Page? {
        nextPage
    }

    public func getErrors() -> [Error] {
        errors
    }
}
