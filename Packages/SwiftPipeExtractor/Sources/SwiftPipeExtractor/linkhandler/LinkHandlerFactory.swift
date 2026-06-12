// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/linkhandler/LinkHandlerFactory.java @ v0.26.3
//
// Java's covariant return-type overrides (ListLinkHandlerFactory re-declares
// fromUrl returning ListLinkHandler) port directly: Swift supports covariant
// overrides for class subtypes.

open class LinkHandlerFactory {
    public init() {}

    ///////////////////////////////////
    // To Override
    ///////////////////////////////////

    open func getId(_ url: String) throws -> String {
        preconditionFailure("LinkHandlerFactory.getId must be overridden")
    }

    open func getUrl(_ id: String) throws -> String {
        preconditionFailure("LinkHandlerFactory.getUrl must be overridden")
    }

    open func onAcceptUrl(_ url: String) throws -> Bool {
        preconditionFailure("LinkHandlerFactory.onAcceptUrl must be overridden")
    }

    open func getUrl(_ id: String, _ baseUrl: String) throws -> String {
        try getUrl(id)
    }

    ///////////////////////////////////
    // Logic
    ///////////////////////////////////

    /// Builds a LinkHandler from a url. Google search redirects are followed
    /// before extraction.
    public func fromUrl(_ url: String) throws -> LinkHandler {
        precondition(!Utils.isNullOrEmpty(url), "The url is null or empty")
        let polishedUrl = Utils.followGoogleRedirectIfNeeded(url)
        let baseUrl = try Utils.getBaseUrl(polishedUrl)
        return try fromUrl(polishedUrl, baseUrl)
    }

    /// Builds a LinkHandler from an URL (already polished from Google search
    /// redirects) and a base URL.
    public func fromUrl(_ url: String, _ baseUrl: String) throws -> LinkHandler {
        if try !acceptUrl(url) {
            throw ParsingException("URL not accepted: \(url)")
        }
        let id = try getId(url)
        return LinkHandler(url, try getUrl(id, baseUrl), id)
    }

    public func fromId(_ id: String) throws -> LinkHandler {
        let url = try getUrl(id)
        return LinkHandler(url, url, id)
    }

    public func fromId(_ id: String, _ baseUrl: String) throws -> LinkHandler {
        let url = try getUrl(id, baseUrl)
        return LinkHandler(url, url, id)
    }

    /// When a VIEW_ACTION is caught this function will test if the url
    /// delivered was meant to be watched with this Service.
    public func acceptUrl(_ url: String) throws -> Bool {
        try onAcceptUrl(url)
    }
}
