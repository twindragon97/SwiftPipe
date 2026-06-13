// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/subscription/SubscriptionExtractor.java @ v0.26.3
//
// Java's UnsupportedOperationException maps to a thrown error so callers can
// handle services that lack a given source. InputStream maps to Data.

import Foundation

open class SubscriptionExtractor {
    // Deviation: Java's four positional constructors collapse into one
    // labeled initializer with defaults, since `init(_ cause: Error)` /
    // `init(_ detailMessage: String?)` would collide with ExtractionException's
    // `init(_:)` initializers. Call sites use labels:
    // InvalidSourceException(), InvalidSourceException(detailMessage:),
    // InvalidSourceException(cause:), InvalidSourceException(detailMessage:cause:).
    public final class InvalidSourceException: ParsingException {
        public init(detailMessage: String? = nil, cause: Error? = nil) {
            super.init(
                "Not a valid source" + (detailMessage == nil ? "" : " (\(detailMessage!))"),
                cause)
        }
    }

    public enum ContentSource {
        case CHANNEL_URL
        case INPUT_STREAM
    }

    public struct UnsupportedSourceError: Error {
        public let message: String
    }

    private let supportedSources: [ContentSource]
    public let service: StreamingService

    public init(_ service: StreamingService, _ supportedSources: [ContentSource]) {
        self.service = service
        self.supportedSources = supportedSources
    }

    public func getSupportedSources() -> [ContentSource] {
        supportedSources
    }

    open func getRelatedUrl() -> String? {
        preconditionFailure("SubscriptionExtractor.getRelatedUrl must be overridden")
    }

    open func fromChannelUrl(_ channelUrl: String) throws -> [SubscriptionItem] {
        throw UnsupportedSourceError(
            message: "Service \(service.getServiceInfo().getName()) "
            + "doesn't support extracting from a channel url")
    }

    open func fromInputStream(_ contentInputStream: Data) throws -> [SubscriptionItem] {
        throw UnsupportedSourceError(
            message: "Service \(service.getServiceInfo().getName()) "
            + "doesn't support extracting from an InputStream")
    }

    open func fromInputStream(
        _ contentInputStream: Data, _ contentType: String
    ) throws -> [SubscriptionItem] {
        throw UnsupportedSourceError(
            message: "Service \(service.getServiceInfo().getName()) "
            + "doesn't support extracting from an InputStream")
    }
}
