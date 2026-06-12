// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/MetaInfo.java @ v0.26.3
//
// java.net.URL maps to Foundation URL.

import Foundation

public final class MetaInfo {
    private var title = ""
    private var content: Description?
    private var urls: [URL] = []
    private var urlTexts: [String] = []

    public init(
        _ title: String,
        _ content: Description,
        _ urls: [URL],
        _ urlTexts: [String]
    ) {
        self.title = title
        self.content = content
        self.urls = urls
        self.urlTexts = urlTexts
    }

    public init() {}

    /// Title of the info. Can be empty.
    public func getTitle() -> String {
        title
    }

    public func setTitle(_ title: String) {
        self.title = title
    }

    public func getContent() -> Description {
        content!
    }

    public func setContent(_ content: Description) {
        self.content = content
    }

    public func getUrls() -> [URL] {
        urls
    }

    public func setUrls(_ urls: [URL]) {
        self.urls = urls
    }

    public func addUrl(_ url: URL) {
        urls.append(url)
    }

    public func getUrlTexts() -> [String] {
        urlTexts
    }

    public func setUrlTexts(_ urlTexts: [String]) {
        self.urlTexts = urlTexts
    }

    public func addUrlText(_ urlText: String) {
        urlTexts.append(urlText)
    }
}
