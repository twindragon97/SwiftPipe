// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/playlist/PlaylistInfoItemsCollector.java @ v0.26.3

public final class PlaylistInfoItemsCollector:
    InfoItemsCollector<PlaylistInfoItem, PlaylistInfoItemExtractor> {

    // Inherits InfoItemsCollector's designated init (no new stored properties).

    public override func extract(
        _ extractor: PlaylistInfoItemExtractor
    ) throws -> PlaylistInfoItem {
        let resultItem = PlaylistInfoItem(
            getServiceId(), try extractor.getUrl(), try extractor.getName())
        do { resultItem.setUploaderName(try extractor.getUploaderName()) } catch { addError(error) }
        do { resultItem.setUploaderUrl(try extractor.getUploaderUrl()) } catch { addError(error) }
        do {
            resultItem.setUploaderVerified(try extractor.isUploaderVerified())
        } catch { addError(error) }
        do { resultItem.setThumbnails(try extractor.getThumbnails()) } catch { addError(error) }
        do { resultItem.setStreamCount(try extractor.getStreamCount()) } catch { addError(error) }
        do { resultItem.setDescription(try extractor.getDescription()) } catch { addError(error) }
        do { resultItem.setPlaylistType(try extractor.getPlaylistType()) } catch { addError(error) }
        return resultItem
    }
}
