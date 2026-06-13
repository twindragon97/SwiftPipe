// Mirrors: app/src/main/java/org/schabi/newpipe/database/Converters.kt @ v0.27.x
//
// Room stores OffsetDateTime as epoch milliseconds (UTC), StreamType as its enum
// name, and FeedGroupIcon as its integer id. These helpers reproduce exactly
// those mappings so values written by SwiftPipe are read back identically by
// NewPipe Android (and vice-versa).

import Foundation
import SwiftPipeExtractor

enum Converters {
    // MARK: OffsetDateTime <-> epoch millis (UTC)

    /// `offsetDateTimeToTimestamp`: an instant's epoch milliseconds. Date is an
    /// absolute instant (like java.time.Instant), so the UTC offset Android
    /// applies does not change the value.
    static func timestamp(from date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000).rounded())
    }

    /// `offsetDateTimeFromTimestamp`.
    static func date(fromTimestamp millis: Int64) -> Date {
        Date(timeIntervalSince1970: Double(millis) / 1000.0)
    }

    // MARK: StreamType <-> name

    /// `stringOf(StreamType)` — the enum constant name, matching Java's
    /// `Enum.name()`.
    static func string(of streamType: StreamType) -> String {
        switch streamType {
        case .NONE: return "NONE"
        case .VIDEO_STREAM: return "VIDEO_STREAM"
        case .AUDIO_STREAM: return "AUDIO_STREAM"
        case .LIVE_STREAM: return "LIVE_STREAM"
        case .AUDIO_LIVE_STREAM: return "AUDIO_LIVE_STREAM"
        case .POST_LIVE_STREAM: return "POST_LIVE_STREAM"
        case .POST_LIVE_AUDIO_STREAM: return "POST_LIVE_AUDIO_STREAM"
        }
    }

    /// `streamTypeOf(String)` — mirror of `StreamType.valueOf(name)`. Unknown
    /// names fall back to `.NONE` (a foreign DB row with a future stream type
    /// degrades to "unchecked" rather than crashing a read).
    static func streamType(of name: String) -> StreamType {
        switch name {
        case "VIDEO_STREAM": return .VIDEO_STREAM
        case "AUDIO_STREAM": return .AUDIO_STREAM
        case "LIVE_STREAM": return .LIVE_STREAM
        case "AUDIO_LIVE_STREAM": return .AUDIO_LIVE_STREAM
        case "POST_LIVE_STREAM": return .POST_LIVE_STREAM
        case "POST_LIVE_AUDIO_STREAM": return .POST_LIVE_AUDIO_STREAM
        default: return .NONE
        }
    }
}
