// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/localization/TimeAgoParser.java @ v0.26.3
//
// Java LocalDateTime arithmetic maps to Calendar math in the current time
// zone; truncatedTo(DAYS) maps to startOfDay.

import Foundation
import TimeAgoParser

public final class TimeAgoParser {
    private let patternsHolder: PatternsHolder
    private let now: Date
    private let calendar: Calendar

    /// Creates a helper to parse upload dates in the format '2 days ago'.
    /// Instantiate a new TimeAgoParser every time you extract a new batch of
    /// items.
    public init(_ patternsHolder: PatternsHolder, _ now: Date) {
        self.patternsHolder = patternsHolder
        self.now = now
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        self.calendar = calendar
    }

    /// Parses a textual date in the format '2 days ago'. Beginning with days
    /// ago, the date is considered as an approximation.
    public func parse(_ textualDate: String) throws -> DateWrapper {
        for chronoUnit in ChronoUnit.allCases {
            for (caseText, caseAmount) in patternsHolder.specialCases()[chronoUnit] ?? []
            where textualDateMatches(textualDate, caseText) {
                return getResultFor(caseAmount, chronoUnit)
            }
        }

        return getResultFor(
            parseTimeAgoAmount(textualDate), try parseChronoUnit(textualDate))
    }

    private func parseTimeAgoAmount(_ textualDate: String) -> Int {
        // If there is no valid number in the textual date, assume it is 1
        // (as in 'a second ago').
        Int(textualDate.replacingOccurrences(
            of: "\\D+", with: "", options: .regularExpression)) ?? 1
    }

    private func parseChronoUnit(_ textualDate: String) throws -> ChronoUnit {
        for (unit, phrases) in patternsHolder.asMap()
        where phrases.contains(where: { textualDateMatches(textualDate, $0) }) {
            return unit
        }
        throw ParsingException("Unable to parse the date: \(textualDate)")
    }

    private func textualDateMatches(_ textualDate: String, _ agoPhrase: String) -> Bool {
        if textualDate == agoPhrase {
            return true
        }

        if patternsHolder.wordSeparator().isEmpty {
            return textualDate.lowercased().contains(agoPhrase.lowercased())
        }

        let escapedPhrase = Pattern.quote(agoPhrase.lowercased())
        // Treat horizontal spaces as a normal one (non-breaking space, thin
        // space, etc.). Also split the string on numbers to be able to parse
        // strings like "2wk".
        let escapedSeparator = patternsHolder.wordSeparator() == " "
            ? "[ \\t\\xA0\\u1680\\u180e\\u2000-\\u200a\\u202f\\u205f\\u3000\\d]"
            : Pattern.quote(patternsHolder.wordSeparator())

        // Check if the pattern is surrounded by separators or start/end of
        // the string.
        let pattern = "(^|\(escapedSeparator))\(escapedPhrase)($|\(escapedSeparator))"
        return Parser.isMatch(pattern, textualDate.lowercased())
    }

    private func getResultFor(_ timeAgoAmount: Int, _ chronoUnit: ChronoUnit) -> DateWrapper {
        var dateTime = now
        switch chronoUnit {
        case .SECONDS:
            dateTime = calendar.date(byAdding: .second, value: -timeAgoAmount, to: dateTime)!
        case .MINUTES:
            dateTime = calendar.date(byAdding: .minute, value: -timeAgoAmount, to: dateTime)!
        case .HOURS:
            dateTime = calendar.date(byAdding: .hour, value: -timeAgoAmount, to: dateTime)!
        case .DAYS:
            dateTime = calendar.date(byAdding: .day, value: -timeAgoAmount, to: dateTime)!
        case .WEEKS:
            dateTime = calendar.date(byAdding: .day, value: -7 * timeAgoAmount, to: dateTime)!
        case .MONTHS:
            dateTime = calendar.date(byAdding: .month, value: -timeAgoAmount, to: dateTime)!
        case .YEARS:
            dateTime = calendar.date(byAdding: .year, value: -timeAgoAmount, to: dateTime)!
            // minusDays is needed to prevent `PrettyTime` from showing
            // '12 months ago'.
            dateTime = calendar.date(byAdding: .day, value: -1, to: dateTime)!
        }

        let isApproximate = chronoUnit.isDateBased
        let resolvedDateTime = isApproximate ? calendar.startOfDay(for: dateTime) : dateTime
        return DateWrapper(resolvedDateTime, isApproximate)
    }
}
