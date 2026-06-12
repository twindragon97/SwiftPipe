// Mirrors: extractor/src/test/java/org/schabi/newpipe/downloader/DownloaderFactory.java @ v0.26.3
//
// Deviations:
//  - The default downloader is MOCK (upstream: REAL) so test runs are
//    deterministic unless DOWNLOADER is set explicitly.
//  - Java derives the mock path from the test class FQCN; Swift has no
//    packages, so each ported test class passes its mock sub-path explicitly
//    (e.g. "org/schabi/newpipe/extractor/services/youtube/youtubesearchextractor").
//  - Selection comes from the DOWNLOADER environment variable instead of a
//    JVM system property ("REC" shortcut preserved).
//  - In RECORDING mode, files are written into the source tree located via
//    the SWIFTPIPE_MOCKS_DIR environment variable (the test bundle copy is
//    read-only).

import Foundation
import SwiftPipeExtractor

enum DownloaderFactory {
    private static let DEFAULT_DOWNLOADER = DownloaderType.MOCK

    private static func determineDownloaderType() -> DownloaderType {
        guard let propValue = ProcessInfo.processInfo.environment["DOWNLOADER"],
              !propValue.isEmpty else {
            return DEFAULT_DOWNLOADER
        }
        let upper = propValue.uppercased()
        // Use shortcut because RECORDING is quite long
        if upper == "REC" {
            return .RECORDING
        }
        guard let type = DownloaderType(rawValue: upper) else {
            preconditionFailure("Unknown downloader name: \(propValue)")
        }
        return type
    }

    /// Returns an implementation of a Downloader for the given mock sub-path
    /// (relative to mocks/v1, lowercase, slash-separated).
    static func getDownloader(_ mockSubPath: String) throws -> Downloader {
        switch determineDownloaderType() {
        case .REAL:
            return DownloaderTestImpl.getInstance()
        case .MOCK:
            return try MockDownloader(path: bundleMocksDirectory(mockSubPath))
        case .RECORDING:
            return try RecordingDownloader(path: sourceMocksDirectory(mockSubPath))
        }
    }

    /// Mocks shipped as test-bundle resources (read-only, used by MOCK).
    private static func bundleMocksDirectory(_ mockSubPath: String) throws -> URL {
        guard let resourceURL = Bundle.module.resourceURL else {
            throw MockDownloaderError(description: "Test bundle has no resource URL")
        }
        return resourceURL
            .appendingPathComponent("mocks")
            .appendingPathComponent("v1")
            .appendingPathComponent(mockSubPath)
    }

    /// Mocks in the repository source tree (writable, used by RECORDING).
    private static func sourceMocksDirectory(_ mockSubPath: String) throws -> URL {
        guard let mocksDir = ProcessInfo.processInfo.environment["SWIFTPIPE_MOCKS_DIR"],
              !mocksDir.isEmpty else {
            throw MockDownloaderError(description:
                "RECORDING mode requires the SWIFTPIPE_MOCKS_DIR environment variable "
                + "to point at Packages/SwiftPipeExtractor/Tests/SwiftPipeExtractorTests/"
                + "Resources/mocks/v1 in the source tree.")
        }
        return URL(fileURLWithPath: mocksDir).appendingPathComponent(mockSubPath)
    }
}
