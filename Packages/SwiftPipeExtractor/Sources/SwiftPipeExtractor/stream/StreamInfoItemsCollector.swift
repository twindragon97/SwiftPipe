// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/stream/StreamInfoItemsCollector.java @ v0.26.3

public final class StreamInfoItemsCollector:
    InfoItemsCollector<StreamInfoItem, StreamInfoItemExtractor> {

    // Adds no stored properties → inherits InfoItemsCollector's designated
    // init(_ serviceId:_ comparator: = nil), covering Java's two constructors.

    public override func extract(_ extractor: StreamInfoItemExtractor) throws -> StreamInfoItem {
        if try extractor.isAd() {
            throw FoundAdException("Found ad")
        }
        let resultItem = StreamInfoItem(
            getServiceId(),
            try extractor.getUrl(),
            try extractor.getName(),
            try extractor.getStreamType())

        // optional information
        do { resultItem.setDuration(try extractor.getDuration()) } catch { addError(error) }
        do { resultItem.setUploaderName(try extractor.getUploaderName()) } catch { addError(error) }
        do {
            resultItem.setTextualUploadDate(try extractor.getTextualUploadDate())
        } catch { addError(error) }
        do {
            resultItem.setUploadDate(try extractor.getUploadDate())
        } catch let e as ParsingException { addError(e) }
        do { resultItem.setViewCount(try extractor.getViewCount()) } catch { addError(error) }
        do { resultItem.setThumbnails(try extractor.getThumbnails()) } catch { addError(error) }
        do { resultItem.setUploaderUrl(try extractor.getUploaderUrl()) } catch { addError(error) }
        do {
            resultItem.setUploaderAvatars(try extractor.getUploaderAvatars())
        } catch { addError(error) }
        do {
            resultItem.setUploaderVerified(try extractor.isUploaderVerified())
        } catch { addError(error) }
        do {
            resultItem.setShortDescription(try extractor.getShortDescription())
        } catch { addError(error) }
        do {
            resultItem.setShortFormContent(try extractor.isShortFormContent())
        } catch { addError(error) }
        do {
            resultItem.setContentAvailability(try extractor.getContentAvailability())
        } catch { addError(error) }
        return resultItem
    }

    public override func commit(_ extractor: StreamInfoItemExtractor) {
        do {
            addItem(try extract(extractor))
        } catch is FoundAdException {
            // ignored
        } catch {
            addError(error)
        }
    }
}
