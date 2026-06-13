// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/exceptions/AccountTerminatedException.java @ v0.26.3

public final class AccountTerminatedException: ContentNotAvailableException {
    private var reason: Reason = .UNKNOWN

    public override init(_ message: String) {
        super.init(message)
    }

    public init(_ message: String, _ reason: Reason) {
        super.init(message)
        self.reason = reason
    }

    public override init(_ message: String, _ cause: Error?) {
        super.init(message, cause)
    }

    public func getReason() -> Reason {
        reason
    }

    public enum Reason {
        case UNKNOWN
        case VIOLATION
    }
}
