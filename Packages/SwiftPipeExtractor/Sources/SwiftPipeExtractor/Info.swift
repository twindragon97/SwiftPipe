// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/Info.java @ v0.26.3
//
// getService() lands together with ServiceList (NewPipe.getService).

open class Info: CustomStringConvertible {
    private let serviceId: Int
    /// Id of this Info object (e.g. YouTube's video id).
    private let id: String
    /// May be a cleaned url, different from originalUrl.
    private let url: String
    /// The url used to start the extraction of this Info object.
    private var originalUrl: String
    private let name: String

    private var errors: [Error] = []

    public func addError(_ throwable: Error) {
        errors.append(throwable)
    }

    public func addAllErrors(_ throwables: [Error]) {
        errors.append(contentsOf: throwables)
    }

    public init(
        _ serviceId: Int,
        _ id: String,
        _ url: String,
        _ originalUrl: String,
        _ name: String
    ) {
        self.serviceId = serviceId
        self.id = id
        self.url = url
        self.originalUrl = originalUrl
        self.name = name
    }

    // Designated (not convenience) so subclasses can delegate to it via
    // super.init, mirroring Java constructor chaining.
    public init(_ serviceId: Int, _ linkHandler: LinkHandler, _ name: String) {
        self.serviceId = serviceId
        self.id = linkHandler.getId()
        self.url = linkHandler.getUrl()
        self.originalUrl = linkHandler.getOriginalUrl()
        self.name = name
    }

    public var description: String {
        let ifDifferentString = url == originalUrl ? "" : " (originalUrl=\"\(originalUrl)\")"
        return "\(type(of: self))[url=\"\(url)\"\(ifDifferentString), name=\"\(name)\"]"
    }

    // if you use an api and want to handle the website url, overriding
    // original url is essential
    public func setOriginalUrl(_ originalUrl: String) {
        self.originalUrl = originalUrl
    }

    public func getServiceId() -> Int {
        serviceId
    }

    public func getId() -> String {
        id
    }

    public func getUrl() -> String {
        url
    }

    public func getOriginalUrl() -> String {
        originalUrl
    }

    public func getName() -> String {
        name
    }

    public func getErrors() -> [Error] {
        errors
    }
}
