// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/exceptions/ExtractionException.java @ v0.26.3
//
// Java's checked-exception hierarchy maps to a Swift class hierarchy so that
// mirrored code can catch by type, including subclasses
// (`catch let e as ExtractionException` matches ParsingException too).

public class ExtractionException: Error, CustomStringConvertible {
    public let message: String?
    public let cause: Error?

    public init(_ message: String) {
        self.message = message
        self.cause = nil
    }

    public init(_ cause: Error) {
        // Java: Exception(Throwable) uses cause.toString() as the message
        self.message = String(describing: cause)
        self.cause = cause
    }

    public init(_ message: String, _ cause: Error?) {
        self.message = message
        self.cause = cause
    }

    public var description: String {
        "\(type(of: self)): \(message ?? "")"
    }
}
