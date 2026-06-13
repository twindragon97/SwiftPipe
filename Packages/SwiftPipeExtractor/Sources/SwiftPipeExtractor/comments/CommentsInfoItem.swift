// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/comments/CommentsInfoItem.java @ v0.26.3

public final class CommentsInfoItem: InfoItem {
    private var commentId: String?
    private var commentText: Description = .EMPTY_DESCRIPTION
    private var uploaderName: String?
    private var uploaderAvatars: [Image] = []
    private var uploaderUrl: String?
    private var uploaderVerified = false
    private var textualUploadDate: String?
    private var uploadDate: DateWrapper?
    private var likeCount = 0
    private var textualLikeCount: String?
    private var heartedByUploader = false
    private var pinned = false
    private var streamPosition = 0
    private var replyCount = 0
    private var replies: Page?
    private var isChannelOwnerValue = false
    private var creatorReply = false

    public static let NO_LIKE_COUNT = -1
    public static let NO_STREAM_POSITION = -1
    public static let UNKNOWN_REPLY_COUNT = -1

    public init(_ serviceId: Int, _ url: String, _ name: String) {
        super.init(.COMMENT, serviceId, url, name)
    }

    public func getCommentId() -> String? { commentId }
    public func setCommentId(_ commentId: String?) { self.commentId = commentId }

    public func getCommentText() -> Description { commentText }
    public func setCommentText(_ commentText: Description) { self.commentText = commentText }

    public func getUploaderName() -> String? { uploaderName }
    public func setUploaderName(_ uploaderName: String?) { self.uploaderName = uploaderName }

    public func getUploaderAvatars() -> [Image] { uploaderAvatars }
    public func setUploaderAvatars(_ uploaderAvatars: [Image]) {
        self.uploaderAvatars = uploaderAvatars
    }

    public func getUploaderUrl() -> String? { uploaderUrl }
    public func setUploaderUrl(_ uploaderUrl: String?) { self.uploaderUrl = uploaderUrl }

    public func getTextualUploadDate() -> String? { textualUploadDate }
    public func setTextualUploadDate(_ textualUploadDate: String?) {
        self.textualUploadDate = textualUploadDate
    }

    public func getUploadDate() -> DateWrapper? { uploadDate }
    public func setUploadDate(_ uploadDate: DateWrapper?) { self.uploadDate = uploadDate }

    public func getLikeCount() -> Int { likeCount }
    public func setLikeCount(_ likeCount: Int) { self.likeCount = likeCount }

    public func getTextualLikeCount() -> String? { textualLikeCount }
    public func setTextualLikeCount(_ textualLikeCount: String?) {
        self.textualLikeCount = textualLikeCount
    }

    public func setHeartedByUploader(_ isHeartedByUploader: Bool) {
        self.heartedByUploader = isHeartedByUploader
    }
    public func isHeartedByUploader() -> Bool { heartedByUploader }

    public func isPinned() -> Bool { pinned }
    public func setPinned(_ pinned: Bool) { self.pinned = pinned }

    public func setUploaderVerified(_ uploaderVerified: Bool) {
        self.uploaderVerified = uploaderVerified
    }
    public func isUploaderVerified() -> Bool { uploaderVerified }

    public func setStreamPosition(_ streamPosition: Int) { self.streamPosition = streamPosition }
    public func getStreamPosition() -> Int { streamPosition }

    public func setReplyCount(_ replyCount: Int) { self.replyCount = replyCount }
    public func getReplyCount() -> Int { replyCount }

    public func setReplies(_ replies: Page?) { self.replies = replies }
    public func getReplies() -> Page? { replies }

    public func setChannelOwner(_ channelOwner: Bool) { self.isChannelOwnerValue = channelOwner }
    public func isChannelOwner() -> Bool { isChannelOwnerValue }

    public func setCreatorReply(_ creatorReply: Bool) { self.creatorReply = creatorReply }
    public func hasCreatorReply() -> Bool { creatorReply }
}
