// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/comments/CommentsExtractor.java @ v0.26.3

open class CommentsExtractor: ListExtractor<CommentsInfoItem> {
    public override init(_ service: StreamingService, _ uiHandler: ListLinkHandler) {
        super.init(service, uiHandler)
    }

    open func isCommentsDisabled() throws -> Bool {
        false
    }

    open func getCommentsCount() throws -> Int {
        -1
    }

    open override func getName() throws -> String {
        "Comments"
    }
}
