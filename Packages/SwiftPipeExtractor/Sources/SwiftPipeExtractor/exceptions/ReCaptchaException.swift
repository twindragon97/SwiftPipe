// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/exceptions/ReCaptchaException.java @ v0.26.3

public class ReCaptchaException: ExtractionException {
    public let url: String

    public init(_ message: String, _ url: String) {
        self.url = url
        super.init(message)
    }
}
