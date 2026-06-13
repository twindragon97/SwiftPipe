// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/comments/CommentsInfoItemExtractor.java @ v0.26.3

public protocol CommentsInfoItemExtractor: InfoItemExtractor {
    func getLikeCount() throws -> Int
    func getTextualLikeCount() throws -> String?
    func getCommentText() throws -> Description
    func getTextualUploadDate() throws -> String?
    func getUploadDate() throws -> DateWrapper?
    func getCommentId() throws -> String?
    func getUploaderUrl() throws -> String?
    func getUploaderName() throws -> String?
    func getUploaderAvatars() throws -> [Image]
    func isHeartedByUploader() throws -> Bool
    func isPinned() throws -> Bool
    func isUploaderVerified() throws -> Bool
    func getStreamPosition() throws -> Int
    func getReplyCount() throws -> Int
    func getReplies() throws -> Page?
    func isChannelOwner() throws -> Bool
    func hasCreatorReply() throws -> Bool
}

public extension CommentsInfoItemExtractor {
    func getLikeCount() throws -> Int { CommentsInfoItem.NO_LIKE_COUNT }
    func getTextualLikeCount() throws -> String? { "" }
    func getCommentText() throws -> Description { Description.EMPTY_DESCRIPTION }
    func getTextualUploadDate() throws -> String? { "" }
    func getUploadDate() throws -> DateWrapper? { nil }
    func getCommentId() throws -> String? { "" }
    func getUploaderUrl() throws -> String? { "" }
    func getUploaderName() throws -> String? { "" }
    func getUploaderAvatars() throws -> [Image] { [] }
    func isHeartedByUploader() throws -> Bool { false }
    func isPinned() throws -> Bool { false }
    func isUploaderVerified() throws -> Bool { false }
    func getStreamPosition() throws -> Int { CommentsInfoItem.NO_STREAM_POSITION }
    func getReplyCount() throws -> Int { CommentsInfoItem.UNKNOWN_REPLY_COUNT }
    func getReplies() throws -> Page? { nil }
    func isChannelOwner() throws -> Bool { false }
    func hasCreatorReply() throws -> Bool { false }
}
