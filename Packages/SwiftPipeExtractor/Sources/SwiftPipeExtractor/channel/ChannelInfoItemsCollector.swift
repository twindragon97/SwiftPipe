// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/channel/ChannelInfoItemsCollector.java @ v0.26.3

public final class ChannelInfoItemsCollector:
    InfoItemsCollector<ChannelInfoItem, ChannelInfoItemExtractor> {

    // Inherits InfoItemsCollector's designated init (no new stored properties).

    public override func extract(_ extractor: ChannelInfoItemExtractor) throws -> ChannelInfoItem {
        let resultItem = ChannelInfoItem(
            getServiceId(), try extractor.getUrl(), try extractor.getName())
        // optional information
        do {
            resultItem.setSubscriberCount(try extractor.getSubscriberCount())
        } catch { addError(error) }
        do { resultItem.setStreamCount(try extractor.getStreamCount()) } catch { addError(error) }
        do { resultItem.setThumbnails(try extractor.getThumbnails()) } catch { addError(error) }
        do { resultItem.setDescription(try extractor.getDescription()) } catch { addError(error) }
        do { resultItem.setVerified(try extractor.isVerified()) } catch { addError(error) }
        return resultItem
    }
}
