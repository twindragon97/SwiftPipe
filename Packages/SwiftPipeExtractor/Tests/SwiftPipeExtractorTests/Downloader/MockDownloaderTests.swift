import XCTest
import SwiftPipeExtractor

/// Validates the mirrored test harness: the recorded-mock JSON format
/// (including Gson's \u escapes and signed bytes for POST bodies), Request
/// equality matching, and the miss error message.
final class MockDownloaderTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftpipe-mocks-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // GET — uses Gson-style = escaping like real recorded files
        let getMock = #"""
        {
          "request": {
            "httpMethod": "GET",
            "url": "https://example.com/page",
            "headers": {
              "Accept-Language": ["en-GB, en;q=0.9"]
            },
            "localization": { "languageCode": "en", "countryCode": "GB" }
          },
          "response": {
            "responseCode": 200,
            "responseMessage": "",
            "responseHeaders": { "content-type": ["text/html"] },
            "responseBody": "hello",
            "latestUrl": "https://example.com/page"
          }
        }
        """#

        // POST — dataToSend as SIGNED bytes (Gson byte[]): {"ñ"} in UTF-8
        let postMock = #"""
        {
          "request": {
            "httpMethod": "POST",
            "url": "https://example.com/api",
            "headers": {
              "Content-Type": ["application/json"],
              "Accept-Language": ["en-GB, en;q=0.9"]
            },
            "dataToSend": [123, 34, -61, -79, 34, 125],
            "localization": { "languageCode": "en", "countryCode": "GB" }
          },
          "response": {
            "responseCode": 200,
            "responseMessage": "",
            "responseHeaders": {},
            "responseBody": "ok",
            "latestUrl": "https://example.com/api"
          }
        }
        """#

        try getMock.write(
            to: tempDir.appendingPathComponent("generated_mock_0.json"),
            atomically: true, encoding: .utf8)
        try postMock.write(
            to: tempDir.appendingPathComponent("generated_mock_1.json"),
            atomically: true, encoding: .utf8)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testMatchesRecordedGetRequest() throws {
        let downloader = try MockDownloader(path: tempDir)
        let request = Request.newBuilder()
            .get("https://example.com/page")
            .localization(Localization("en", "GB"))
            .build()

        let response = try downloader.execute(request)
        XCTAssertEqual(response.responseCode, 200)
        XCTAssertEqual(response.responseBody, "hello")
        // getHeader is case-insensitive, like Java
        XCTAssertEqual(response.getHeader("Content-Type"), "text/html")
    }

    func testMatchesRecordedPostRequestWithBody() throws {
        let downloader = try MockDownloader(path: tempDir)
        let body = "{\"ñ\"}".data(using: .utf8)
        let request = Request.newBuilder()
            .post("https://example.com/api", body)
            .headers(["Content-Type": ["application/json"]])
            .localization(Localization("en", "GB"))
            .build()

        let response = try downloader.execute(request)
        XCTAssertEqual(response.responseBody, "ok")
    }

    func testMissThrowsWithUpstreamMessage() throws {
        let downloader = try MockDownloader(path: tempDir)
        let request = Request.newBuilder()
            .get("https://example.com/other")
            .localization(Localization("en", "GB"))
            .build()

        XCTAssertThrowsError(try downloader.execute(request)) { error in
            let message = String(describing: error)
            XCTAssertTrue(message.contains("No mock response for request with url"))
            XCTAssertTrue(message.contains("https://example.com/other"))
        }
    }

    func testAutomaticLocalizationHeaderMatchesRecordedFormat() {
        // The exact Accept-Language format seen in recorded mocks
        let headers = Request.getHeadersFromLocalization(Localization("en", "GB"))
        XCTAssertEqual(headers, ["Accept-Language": ["en-GB, en;q=0.9"]])
        // Country-less localization: just the language code
        let bare = Request.getHeadersFromLocalization(Localization("es"))
        XCTAssertEqual(bare, ["Accept-Language": ["es"]])
    }

    func testRequestEqualityAndHashing() {
        let a = Request.newBuilder()
            .get("https://example.com")
            .localization(Localization("en", "GB"))
            .build()
        let b = Request.newBuilder()
            .get("https://example.com")
            .localization(Localization("en", "GB"))
            .build()
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)

        let c = Request.newBuilder()
            .get("https://example.com")
            .localization(Localization("en", "US"))
            .build()
        XCTAssertNotEqual(a, c)
    }
}
