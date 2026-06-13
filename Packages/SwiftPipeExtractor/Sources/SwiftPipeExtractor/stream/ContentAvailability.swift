// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/stream/ContentAvailability.java @ v0.26.3

public enum ContentAvailability {
    /// Unknown (clients may assume available).
    case UNKNOWN
    /// Available to all users.
    case AVAILABLE
    /// Available to users with a membership.
    case MEMBERSHIP
    /// Behind a paywall.
    case PAID
    /// Only available in the future.
    case UPCOMING
}
