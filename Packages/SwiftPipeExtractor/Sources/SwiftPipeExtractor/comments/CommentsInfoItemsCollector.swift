// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/comments/CommentsInfoItemsCollector.java @ v0.26.3

public final class CommentsInfoItemsCollector:
    InfoItemsCollector<CommentsInfoItem, CommentsInfoItemExtractor> {

    // Inherits InfoItemsCollector's designated init (no new stored properties).

    public override func extract(
        _ extractor: CommentsInfoItemExtractor
    ) throws -> CommentsInfoItem {
        let resultItem = CommentsInfoItem(
            getServiceId(), try extractor.getUrl(), try extractor.getName())
        // optional information
        do { resultItem.setCommentId(try extractor.getCommentId()) } catch { addError(error) }
        do { resultItem.setCommentText(try extractor.getCommentText()) } catch { addError(error) }
        do { resultItem.setUploaderName(try extractor.getUploaderName()) } catch { addError(error) }
        do {
            resultItem.setUploaderAvatars(try extractor.getUploaderAvatars())
        } catch { addError(error) }
        do { resultItem.setUploaderUrl(try extractor.getUploaderUrl()) } catch { addError(error) }
        do {
            resultItem.setTextualUploadDate(try extractor.getTextualUploadDate())
        } catch { addError(error) }
        do { resultItem.setUploadDate(try extractor.getUploadDate()) } catch { addError(error) }
        do { resultItem.setLikeCount(try extractor.getLikeCount()) } catch { addError(error) }
        do {
            resultItem.setTextualLikeCount(try extractor.getTextualLikeCount())
        } catch { addError(error) }
        do { resultItem.setThumbnails(try extractor.getThumbnails()) } catch { addError(error) }
        do {
            resultItem.setHeartedByUploader(try extractor.isHeartedByUploader())
        } catch { addError(error) }
        do { resultItem.setPinned(try extractor.isPinned()) } catch { addError(error) }
        do {
            resultItem.setStreamPosition(try extractor.getStreamPosition())
        } catch { addError(error) }
        do { resultItem.setReplyCount(try extractor.getReplyCount()) } catch { addError(error) }
        do { resultItem.setReplies(try extractor.getReplies()) } catch { addError(error) }
        do { resultItem.setChannelOwner(try extractor.isChannelOwner()) } catch { addError(error) }
        do { resultItem.setCreatorReply(try extractor.hasCreatorReply()) } catch { addError(error) }
        return resultItem
    }

    public override func commit(_ extractor: CommentsInfoItemExtractor) {
        do {
            addItem(try extract(extractor))
        } catch {
            addError(error)
        }
    }

    public func getCommentsInfoItemList() -> [CommentsInfoItem] {
        getItems()
    }
}
