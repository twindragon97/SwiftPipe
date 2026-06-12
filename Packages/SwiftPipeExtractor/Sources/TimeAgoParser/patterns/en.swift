// Mirrors: timeago-parser/src/main/java/org/schabi/newpipe/extractor/timeago/patterns/en.java @ v0.26.3
// (Generated upstream from unique_patterns.json — keep in sync.)

public final class en: PatternsHolder {
    private static let WORD_SEPARATOR = " "
    private static let SECONDS = ["second", "seconds", "sec"]
    private static let MINUTES = ["minute", "minutes", "min"]
    private static let HOURS = ["hour", "hours", "h"]
    private static let DAYS = ["day", "days", "d"]
    private static let WEEKS = ["week", "weeks", "w"]
    private static let MONTHS = ["month", "months", "mo"]
    private static let YEARS = ["year", "years", "y"]

    private static let INSTANCE = en()

    public static func getInstance() -> en {
        INSTANCE
    }

    private init() {
        super.init(
            Self.WORD_SEPARATOR, Self.SECONDS, Self.MINUTES, Self.HOURS,
            Self.DAYS, Self.WEEKS, Self.MONTHS, Self.YEARS)
    }
}
