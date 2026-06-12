// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/linkhandler/ListLinkHandlerFactory.java @ v0.26.3
//
// Swift supports Java's covariant return-type overrides (fromUrl returning
// ListLinkHandler here) directly.

open class ListLinkHandlerFactory: LinkHandlerFactory {
    ///////////////////////////////////
    // To Override
    ///////////////////////////////////

    open func getUrl(
        _ id: String, _ contentFilter: [String], _ sortFilter: String
    ) throws -> String {
        preconditionFailure("ListLinkHandlerFactory.getUrl must be overridden")
    }

    open func getUrl(
        _ id: String, _ contentFilter: [String], _ sortFilter: String, _ baseUrl: String
    ) throws -> String {
        try getUrl(id, contentFilter, sortFilter)
    }

    ///////////////////////////////////
    // Logic
    ///////////////////////////////////

    public override func fromUrl(_ url: String) throws -> ListLinkHandler {
        let polishedUrl = Utils.followGoogleRedirectIfNeeded(url)
        let baseUrl = try Utils.getBaseUrl(polishedUrl)
        return try fromUrl(polishedUrl, baseUrl)
    }

    public override func fromUrl(_ url: String, _ baseUrl: String) throws -> ListLinkHandler {
        ListLinkHandler(try super.fromUrl(url, baseUrl))
    }

    public override func fromId(_ id: String) throws -> ListLinkHandler {
        ListLinkHandler(try super.fromId(id))
    }

    public override func fromId(_ id: String, _ baseUrl: String) throws -> ListLinkHandler {
        ListLinkHandler(try super.fromId(id, baseUrl))
    }

    public func fromQuery(
        _ id: String, _ contentFilters: [String], _ sortFilter: String
    ) throws -> ListLinkHandler {
        let url = try getUrl(id, contentFilters, sortFilter)
        return ListLinkHandler(url, url, id, contentFilters, sortFilter)
    }

    public func fromQuery(
        _ id: String, _ contentFilters: [String], _ sortFilter: String, _ baseUrl: String
    ) throws -> ListLinkHandler {
        let url = try getUrl(id, contentFilters, sortFilter, baseUrl)
        return ListLinkHandler(url, url, id, contentFilters, sortFilter)
    }

    /// For making ListLinkHandlerFactory compatible with LinkHandlerFactory;
    /// should not be overridden by the actual implementation.
    open override func getUrl(_ id: String) throws -> String {
        try getUrl(id, [], "")
    }

    open override func getUrl(_ id: String, _ baseUrl: String) throws -> String {
        try getUrl(id, [], "", baseUrl)
    }

    /// Content filters the corresponding extractor can handle, like
    /// "channels", "videos", "music".
    open func getAvailableContentFilter() -> [String] {
        []
    }

    /// Sort filters the corresponding extractor can handle, like "A-Z",
    /// "oldest first", "size".
    open func getAvailableSortFilter() -> [String] {
        []
    }
}
