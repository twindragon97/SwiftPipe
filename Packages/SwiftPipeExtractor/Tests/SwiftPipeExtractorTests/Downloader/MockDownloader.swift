// Mirrors: extractor/src/test/java/org/schabi/newpipe/downloader/MockDownloader.java @ v0.26.3
//
// Deviation: Java throws an unchecked NullPointerException when no mock
// matches; Swift throws MockDownloaderError with the same message so XCTest
// reports it instead of crashing the process.

import Foundation
import SwiftPipeExtractor

struct MockDownloaderError: Error, CustomStringConvertible {
    let description: String
}

/// Mocks requests by using json files created by RecordingDownloader.
final class MockDownloader: Downloader {
    private let path: URL
    private let mocks: [Request: Response]

    init(path: URL) throws {
        self.path = path

        var loaded: [Request: Response] = [:]
        let entries = try FileManager.default.contentsOfDirectory(
            at: path, includingPropertiesForKeys: nil)
        let decoder = JSONDecoder()
        for entry in entries
        where entry.lastPathComponent.hasPrefix(RecordingDownloader.FILE_NAME_PREFIX) {
            let data = try Data(contentsOf: entry)
            let pair = try decoder.decode(TestRequestResponse.self, from: data)
            loaded[pair.request.toRequest()] = pair.response.toResponse()
        }
        self.mocks = loaded
        super.init()
    }

    override func execute(_ request: Request) throws -> Response {
        guard let result = mocks[request] else {
            throw MockDownloaderError(description:
                "No mock response for request with url '\(request.url)' exists in path "
                + "'\(path.path)'.\nPlease make sure to run the tests with the "
                + "RecordingDownloader first after changes.")
        }
        return result
    }
}
