// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/channel/ChannelExtractor.java @ v0.26.3

open class ChannelExtractor: Extractor {
    public static let UNKNOWN_SUBSCRIBER_COUNT: Int64 = -1

    public init(_ service: StreamingService, _ linkHandler: ListLinkHandler) {
        super.init(service, linkHandler)
    }

    open func getAvatars() throws -> [Image] {
        preconditionFailure("ChannelExtractor.getAvatars must be overridden")
    }

    open func getBanners() throws -> [Image] {
        preconditionFailure("ChannelExtractor.getBanners must be overridden")
    }

    open func getFeedUrl() throws -> String {
        preconditionFailure("ChannelExtractor.getFeedUrl must be overridden")
    }

    open func getSubscriberCount() throws -> Int64 {
        preconditionFailure("ChannelExtractor.getSubscriberCount must be overridden")
    }

    open func getDescription() throws -> String {
        preconditionFailure("ChannelExtractor.getDescription must be overridden")
    }

    open func getParentChannelName() throws -> String {
        preconditionFailure("ChannelExtractor.getParentChannelName must be overridden")
    }

    open func getParentChannelUrl() throws -> String {
        preconditionFailure("ChannelExtractor.getParentChannelUrl must be overridden")
    }

    open func getParentChannelAvatars() throws -> [Image] {
        preconditionFailure("ChannelExtractor.getParentChannelAvatars must be overridden")
    }

    open func isVerified() throws -> Bool {
        preconditionFailure("ChannelExtractor.isVerified must be overridden")
    }

    open func getTabs() throws -> [ListLinkHandler] {
        preconditionFailure("ChannelExtractor.getTabs must be overridden")
    }

    open func getTags() throws -> [String] {
        []
    }
}
