// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/linkhandler/LinkHandler.java @ v0.26.3

open class LinkHandler {
    public let originalUrl: String
    public let url: String
    public let id: String

    public init(_ originalUrl: String, _ url: String, _ id: String) {
        self.originalUrl = originalUrl
        self.url = url
        self.id = id
    }

    public convenience init(_ handler: LinkHandler) {
        self.init(handler.originalUrl, handler.url, handler.id)
    }

    public func getOriginalUrl() -> String {
        originalUrl
    }

    public func getUrl() -> String {
        url
    }

    public func getId() -> String {
        id
    }

    public func getBaseUrl() throws -> String {
        try Utils.getBaseUrl(url)
    }
}
