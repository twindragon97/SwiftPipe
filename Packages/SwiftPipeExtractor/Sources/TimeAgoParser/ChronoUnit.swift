// No direct Java counterpart: minimal shim of java.time.temporal.ChronoUnit
// covering the units the timeago patterns use. CaseIterable order matches
// the EnumMap iteration order upstream relies on.

public enum ChronoUnit: CaseIterable, Hashable {
    case SECONDS
    case MINUTES
    case HOURS
    case DAYS
    case WEEKS
    case MONTHS
    case YEARS

    /// java.time: date-based units (days and coarser).
    public var isDateBased: Bool {
        switch self {
        case .DAYS, .WEEKS, .MONTHS, .YEARS:
            return true
        case .SECONDS, .MINUTES, .HOURS:
            return false
        }
    }
}
