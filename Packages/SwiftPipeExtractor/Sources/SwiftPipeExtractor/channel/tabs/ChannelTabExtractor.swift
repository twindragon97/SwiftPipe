// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/channel/tabs/ChannelTabExtractor.java @ v0.26.3

open class ChannelTabExtractor: ListExtractor<InfoItem> {
    public override init(_ service: StreamingService, _ linkHandler: ListLinkHandler) {
        super.init(service, linkHandler)
    }

    open override func getName() throws -> String {
        getLinkHandler().getContentFilters()[0]
    }
}
