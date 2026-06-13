import Foundation
import SwiftPipeExtractor

/// A Sendable snapshot of a YouTube video search result, mapped off the
/// extractor's (non-Sendable) StreamInfoItem on a background thread before
/// being handed to the main actor. Carries enough to rebuild a database
/// StreamEntity for watch-history recording.
struct SearchResultItem: Identifiable, Sendable, Hashable {
    let id: String          // the watch URL, unique per result
    let serviceId: Int
    let title: String
    let uploader: String
    let durationSeconds: Int64
    let durationText: String
    let thumbnailURL: URL?
    let streamType: StreamType

    var url: String { id }
}

enum DurationFormatter {
    /// Formats a duration in seconds as "M:SS" or "H:MM:SS"; empty for
    /// unknown/live (negative).
    static func string(fromSeconds seconds: Int64) -> String {
        guard seconds > 0 else { return "" }
        let s = Int(seconds % 60)
        let m = Int((seconds / 60) % 60)
        let h = Int(seconds / 3600)
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}
