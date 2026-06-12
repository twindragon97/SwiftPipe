// Mirrors: extractor/src/test/java/org/schabi/newpipe/downloader/RecordingDownloader.java @ v0.26.3
//
// Relays requests to DownloaderTestImpl and saves the request/response pair
// into a json file. Those files are used by MockDownloader. Run a test class
// as a whole, not each test separately, and re-record when the requests made
// by a class change.
//
// Deviation: output is JSONEncoder pretty-printed, which escapes fewer
// characters than Gson's HTML-safe mode; MockDownloader parses either form.

import Foundation
import SwiftPipeExtractor

final class RecordingDownloader: Downloader {
    static let FILE_NAME_PREFIX = "generated_mock_"

    // From https://stackoverflow.com/a/15875500/13516981
    private static let IP_V4_PATTERN =
        "(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"

    private var index = 0
    private let path: URL

    /// Creates the folder described by path if it does not exist. Deletes
    /// existing files starting with FILE_NAME_PREFIX.
    init(path: URL) throws {
        self.path = path

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path.path) {
            for entry in try fileManager.contentsOfDirectory(
                at: path, includingPropertiesForKeys: nil)
            where entry.lastPathComponent.hasPrefix(Self.FILE_NAME_PREFIX) {
                try fileManager.removeItem(at: entry)
            }
        } else {
            try fileManager.createDirectory(at: path, withIntermediateDirectories: true)
        }
        super.init()
    }

    override func execute(_ request: Request) throws -> Response {
        let downloader = DownloaderTestImpl.getInstance()
        var response = try downloader.execute(request)

        let anonymizedBody = response.responseBody.replacingOccurrences(
            of: Self.IP_V4_PATTERN,
            with: "127.0.0.1",
            options: .regularExpression)
        response = Response(
            response.responseCode,
            response.responseMessage,
            response.responseHeaders,
            anonymizedBody,
            response.latestUrl)

        let outputPath = path.appendingPathComponent(
            Self.FILE_NAME_PREFIX + String(index) + ".json")
        index += 1

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(TestRequestResponse(request: request, response: response))
        try data.write(to: outputPath)

        return response
    }
}
