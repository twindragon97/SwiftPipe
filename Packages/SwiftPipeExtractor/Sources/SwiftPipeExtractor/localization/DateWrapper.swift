// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/localization/DateWrapper.java @ v0.26.3
//
// java.time.Instant/OffsetDateTime/LocalDateTime collapse into Foundation
// Date (an absolute instant). offsetDateTime()/getInstant() both return the
// wrapped Date; ISO-8601 parsing goes through ISO8601DateFormatter with and
// without fractional seconds.

import Foundation

public final class DateWrapper: CustomStringConvertible {
    private let instant: Date
    private let isApproximationValue: Bool

    public init(_ instant: Date, _ isApproximation: Bool = false) {
        self.instant = instant
        self.isApproximationValue = isApproximation
    }

    /// The wrapped instant.
    public func getInstant() -> Date {
        instant
    }

    /// The wrapped instant (Java returns it as an OffsetDateTime set to UTC).
    public func offsetDateTime() -> Date {
        instant
    }

    /// Whether the date is precise or just an approximation (e.g. service
    /// only returns "2 weeks ago" instead of a precise date).
    public func isApproximation() -> Bool {
        isApproximationValue
    }

    public var description: String {
        "DateWrapper{instant=\(instant), isApproximation=\(isApproximationValue)}"
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let isoFractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static func parseIso(_ date: String) -> Date? {
        isoFormatter.date(from: date) ?? isoFractionalFormatter.date(from: date)
    }

    /// Parses an ISO-8601 OffsetDateTime string, e.g.
    /// "2011-12-03T10:15:30+01:00".
    public static func fromOffsetDateTime(_ date: String?) throws -> DateWrapper? {
        guard let date else { return nil }
        guard let parsed = parseIso(date) else {
            throw ParsingException("Could not parse date: \"\(date)\"")
        }
        return DateWrapper(parsed)
    }

    /// Parses an ISO-8601 Instant string, e.g. "2011-12-03T10:15:30Z".
    public static func fromInstant(_ date: String?) throws -> DateWrapper? {
        guard let date else { return nil }
        guard let parsed = parseIso(date) else {
            throw ParsingException("Could not parse date: \"\(date)\"")
        }
        return DateWrapper(parsed)
    }
}
