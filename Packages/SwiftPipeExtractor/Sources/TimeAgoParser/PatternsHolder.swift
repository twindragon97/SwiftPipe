// Mirrors: timeago-parser/src/main/java/org/schabi/newpipe/extractor/timeago/PatternsHolder.java @ v0.26.3
//
// specialCases preserves insertion order per unit (Java: LinkedHashMap) and
// asMap() returns unit/phrase pairs in declaration order (Java: EnumMap).

open class PatternsHolder {
    private let wordSeparatorValue: String
    private let secondsValue: [String]
    private let minutesValue: [String]
    private let hoursValue: [String]
    private let daysValue: [String]
    private let weeksValue: [String]
    private let monthsValue: [String]
    private let yearsValue: [String]
    private var specialCasesValue: [ChronoUnit: [(caseText: String, caseAmount: Int)]] = [:]

    public init(
        _ wordSeparator: String,
        _ seconds: [String],
        _ minutes: [String],
        _ hours: [String],
        _ days: [String],
        _ weeks: [String],
        _ months: [String],
        _ years: [String]
    ) {
        wordSeparatorValue = wordSeparator
        secondsValue = seconds
        minutesValue = minutes
        hoursValue = hours
        daysValue = days
        weeksValue = weeks
        monthsValue = months
        yearsValue = years
    }

    public func wordSeparator() -> String { wordSeparatorValue }
    public func seconds() -> [String] { secondsValue }
    public func minutes() -> [String] { minutesValue }
    public func hours() -> [String] { hoursValue }
    public func days() -> [String] { daysValue }
    public func weeks() -> [String] { weeksValue }
    public func months() -> [String] { monthsValue }
    public func years() -> [String] { yearsValue }

    public func specialCases() -> [ChronoUnit: [(caseText: String, caseAmount: Int)]] {
        specialCasesValue
    }

    public func putSpecialCase(_ unit: ChronoUnit, _ caseText: String, _ caseAmount: Int) {
        specialCasesValue[unit, default: []].append((caseText, caseAmount))
    }

    /// Unit/phrases pairs in unit declaration order (Java: EnumMap iteration).
    public func asMap() -> [(unit: ChronoUnit, phrases: [String])] {
        [
            (.SECONDS, seconds()),
            (.MINUTES, minutes()),
            (.HOURS, hours()),
            (.DAYS, days()),
            (.WEEKS, weeks()),
            (.MONTHS, months()),
            (.YEARS, years()),
        ]
    }
}
