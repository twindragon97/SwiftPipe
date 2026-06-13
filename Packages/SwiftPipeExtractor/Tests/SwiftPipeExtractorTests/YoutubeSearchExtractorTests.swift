import XCTest
@testable import SwiftPipeExtractor

/// Mirror of YoutubeSearchExtractorTest.All (upstream), reduced to the core
/// assertions. Runs against the recorded `all` mocks via the MOCK downloader,
/// so it validates the full search path deterministically: the sw.js / HTML
/// client-version extraction, the byte-exact InnerTube search POST body, and
/// response parsing into StreamInfoItems. Runs on Linux and macOS (no JS).
final class YoutubeSearchExtractorTests: XCTestCase {
    private static let mockPath =
        "org/schabi/newpipe/extractor/services/youtube/search/youtubesearchextractor/all"
    private static let query = "test"

    override func setUpWithError() throws {
        let downloader = try DownloaderFactory.getDownloader(Self.mockPath)
        NewPipe.initialize(downloader, Localization("en", "GB"), ContentCountry("GB"))
        // Reset cached client version so the recorded sw.js / HTML requests are
        // replayed (mirror of YoutubeTestsUtils.ensureStateless()).
        YoutubeParsingHelper.resetClientVersion()
    }

    func testSearchReturnsStreamResults() throws {
        let extractor = try ServiceList.YouTube.getSearchExtractor(Self.query)
        try extractor.fetchPage()

        XCTAssertEqual(extractor.getSearchString(), Self.query)
        XCTAssertTrue(try extractor.getUrl().contains(
            "youtube.com/results?search_query=\(Self.query)"))

        let page = try extractor.getInitialPage()
        XCTAssertFalse(page.getItems().isEmpty, "search returned no items")

        // The "test" query yields video results -> StreamInfoItems.
        let streams = page.getItems().compactMap { $0 as? StreamInfoItem }
        XCTAssertFalse(streams.isEmpty, "no StreamInfoItem in results")

        let first = streams[0]
        XCTAssertFalse(first.getName().isEmpty)
        XCTAssertTrue(first.getUrl().contains("youtube.com/watch?v="))

        // There should be a next page (continuation token present).
        XCTAssertTrue(page.hasNextPage())
    }
}
