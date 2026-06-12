// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/Page.java @ v0.26.3

import Foundation

public final class Page {
    private let url: String?
    private let id: String?
    private let ids: [String]?
    private let cookies: [String: String]?
    private let body: Data?

    public init(
        _ url: String?,
        _ id: String?,
        _ ids: [String]?,
        _ cookies: [String: String]?,
        _ body: Data?
    ) {
        self.url = url
        self.id = id
        self.ids = ids
        self.cookies = cookies
        self.body = body
    }

    public convenience init(_ url: String?) {
        self.init(url, nil, nil, nil, nil)
    }

    public convenience init(_ url: String?, _ id: String?) {
        self.init(url, id, nil, nil, nil)
    }

    public convenience init(_ url: String?, _ id: String?, _ body: Data?) {
        self.init(url, id, nil, nil, body)
    }

    public convenience init(_ url: String?, _ body: Data?) {
        self.init(url, nil, nil, nil, body)
    }

    public convenience init(_ url: String?, _ cookies: [String: String]?) {
        self.init(url, nil, nil, cookies, nil)
    }

    public convenience init(_ ids: [String]?) {
        self.init(nil, nil, ids, nil, nil)
    }

    public convenience init(_ ids: [String]?, _ cookies: [String: String]?) {
        self.init(nil, nil, ids, cookies, nil)
    }

    public func getUrl() -> String? {
        url
    }

    public func getId() -> String? {
        id
    }

    public func getIds() -> [String]? {
        ids
    }

    public func getCookies() -> [String: String]? {
        cookies
    }

    public static func isValid(_ page: Page?) -> Bool {
        guard let page else { return false }
        return !Utils.isNullOrEmpty(page.getUrl()) || !Utils.isNullOrEmpty(page.getIds())
    }

    public func getBody() -> Data? {
        body
    }
}
