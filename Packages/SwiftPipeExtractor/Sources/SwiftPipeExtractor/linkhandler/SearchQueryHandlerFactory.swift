// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/linkhandler/SearchQueryHandlerFactory.java @ v0.26.3
//
// See LinkHandlerFactory.swift for the covariant-return deviation.

open class SearchQueryHandlerFactory: ListLinkHandlerFactory {
    ///////////////////////////////////
    // To Override
    ///////////////////////////////////

    open func getSearchString(_ url: String) -> String {
        ""
    }

    ///////////////////////////////////
    // Logic
    ///////////////////////////////////

    open override func getId(_ url: String) throws -> String {
        getSearchString(url)
    }

    public func fromQuery(
        _ query: String, _ contentFilter: [String], _ sortFilter: String
    ) throws -> SearchQueryHandler {
        SearchQueryHandler(try super.fromQuery(query, contentFilter, sortFilter) as ListLinkHandler)
    }

    public func fromQuery(_ query: String) throws -> SearchQueryHandler {
        try fromQuery(query, [], "")
    }

    /// It's not mandatory for NewPipe to handle the Url.
    open override func onAcceptUrl(_ url: String) throws -> Bool {
        false
    }
}
