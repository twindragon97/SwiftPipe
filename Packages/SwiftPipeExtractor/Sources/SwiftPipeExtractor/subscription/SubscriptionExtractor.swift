// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/subscription/SubscriptionExtractor.java @ v0.26.3
//
// Java's UnsupportedOperationException maps to a thrown error so callers can
// handle services that lack a given source. InputStream maps to Data.

import Foundation

open class SubscriptionExtractor {
    public final class InvalidSourceException: ParsingException {
        public convenience init() {
            self.init(nil, nil)
        }

        public convenience init(_ detailMessage: String?) {
            self.init(detailMessage, nil)
        }

        public convenience init(_ cause: Error) {
            self.init(nil, cause)
        }

        public init(_ detailMessage: String?, _ cause: Error?) {
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
