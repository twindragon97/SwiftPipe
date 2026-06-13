// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/feed/FeedExtractor.java @ v0.26.3

open class FeedExtractor: ListExtractor<StreamInfoItem> {
    public override init(_ service: StreamingService, _ listLinkHandler: ListLinkHandler) {
        super.init(service, listLinkHandler)
    }
}
