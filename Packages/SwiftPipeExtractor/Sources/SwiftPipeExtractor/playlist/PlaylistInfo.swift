// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/playlist/PlaylistInfo.java @ v0.26.3
//
// getInfo(String) and getMoreItems need NewPipe.getServiceByUrl / getInfo
// orchestration; they are wired here. The PlaylistType enum is the keystone
// pulled in by PlaylistInfoItem / PlaylistExtractor early.

public final class PlaylistInfo: ListInfo<StreamInfoItem> {
    public enum PlaylistType {
        case NORMAL
        case MIX_STREAM
        case MIX_MUSIC
        /// Deprecated upstream: no service implements it (YouTube removed it ~2024-06).
        case MIX_CHANNEL
        case MIX_GENRE
    }

    private override init(_ serviceId: Int, _ linkHandler: ListLinkHandler, _ name: String) {
        super.init(serviceId, linkHandler, name)
    }

    public static func getInfo(_ url: String) throws -> PlaylistInfo {
        try getInfo(NewPipe.getServiceByUrl(url), url)
    }

    public static func getInfo(_ service: StreamingService, _ url: String) throws -> PlaylistInfo {
        let extractor = try service.getPlaylistExtractor(url)
        try extractor.fetchPage()
        return try getInfo(extractor)
    }

    public static func getMoreItems(
        _ service: StreamingService, _ url: String, _ page: Page
    ) throws -> InfoItemsPage<StreamInfoItem> {
        try service.getPlaylistExtractor(url).getPage(page)
    }

    public static func getInfo(_ extractor: PlaylistExtractor) throws -> PlaylistInfo {
        let info = PlaylistInfo(
            extractor.getServiceId(),
            extractor.getLinkHandler(),
            try extractor.getName())

        // collect uploader extraction failures until we are sure this is not
        // just a playlist without an uploader
        var uploaderParsingErrors: [Error] = []

        do { info.setOriginalUrl(try extractor.getOriginalUrl()) } catch { info.addError(error) }
        do { info.setStreamCount(try extractor.getStreamCount()) } catch { info.addError(error) }
        do { info.setDescription(try extractor.getDescription()) } catch { info.addError(error) }
        do { info.setThumbnails(try extractor.getThumbnails()) } catch { info.addError(error) }
        do {
            info.setUploaderUrl(try extractor.getUploaderUrl())
        } catch { uploaderParsingErrors.append(error) }
        do {
            info.setUploaderName(try extractor.getUploaderName())
        } catch { uploaderParsingErrors.append(error) }
        do {
            info.setUploaderAvatars(try extractor.getUploaderAvatars())
        } catch { uploaderParsingErrors.append(error) }
        do {
            info.setSubChannelUrl(try extractor.getSubChannelUrl())
        } catch { uploaderParsingErrors.append(error) }
        do {
            info.setSubChannelName(try extractor.getSubChannelName())
        } catch { uploaderParsingErrors.append(error) }
        do {
            info.setSubChannelAvatars(try extractor.getSubChannelAvatars())
        } catch { uploaderParsingErrors.append(error) }
        do { info.setBanners(try extractor.getBanners()) } catch { info.addError(error) }
        do { info.setPlaylistType(try extractor.getPlaylistType()) } catch { info.addError(error) }

        // do not fail if everything but the uploader infos could be collected
        if !uploaderParsingErrors.isEmpty
            && (!info.getErrors().isEmpty || uploaderParsingErrors.count < 3) {
            info.addAllErrors(uploaderParsingErrors)
        }

        let itemsPage = ExtractorHelper.getItemsPageOrLogError(info, extractor)
        info.setRelatedItems(itemsPage.getItems())
        info.setNextPage(itemsPage.getNextPage())
        return info
    }

    private var uploaderUrl = ""
    private var uploaderName = ""
    private var subChannelUrl: String?
    private var subChannelName: String?
    // Renamed from Java's `description` (see ChannelInfoItem) to avoid the
    // CustomStringConvertible.description clash; getter/setter names unchanged.
    private var descriptionValue: Description?
    private var banners: [Image] = []
    private var subChannelAvatars: [Image] = []
    private var thumbnails: [Image] = []
    private var uploaderAvatars: [Image] = []
    private var streamCount: Int64 = 0
    private var playlistType: PlaylistType?

    public func getThumbnails() -> [Image] { thumbnails }
    public func setThumbnails(_ thumbnails: [Image]) { self.thumbnails = thumbnails }

    public func getBanners() -> [Image] { banners }
    public func setBanners(_ banners: [Image]) { self.banners = banners }

    public func getUploaderUrl() -> String { uploaderUrl }
    public func setUploaderUrl(_ uploaderUrl: String) { self.uploaderUrl = uploaderUrl }

    public func getUploaderName() -> String { uploaderName }
    public func setUploaderName(_ uploaderName: String) { self.uploaderName = uploaderName }

    public func getUploaderAvatars() -> [Image] { uploaderAvatars }
    public func setUploaderAvatars(_ uploaderAvatars: [Image]) {
        self.uploaderAvatars = uploaderAvatars
    }

    public func getSubChannelUrl() -> String? { subChannelUrl }
    public func setSubChannelUrl(_ subChannelUrl: String?) { self.subChannelUrl = subChannelUrl }

    public func getSubChannelName() -> String? { subChannelName }
    public func setSubChannelName(_ subChannelName: String?) {
        self.subChannelName = subChannelName
    }

    public func getSubChannelAvatars() -> [Image] { subChannelAvatars }
    public func setSubChannelAvatars(_ subChannelAvatars: [Image]) {
        self.subChannelAvatars = subChannelAvatars
    }

    public func getStreamCount() -> Int64 { streamCount }
    public func setStreamCount(_ streamCount: Int64) { self.streamCount = streamCount }

    public func getDescription() -> Description? { descriptionValue }
    public func setDescription(_ description: Description?) { self.descriptionValue = description }

    public func getPlaylistType() -> PlaylistType? { playlistType }
    public func setPlaylistType(_ playlistType: PlaylistType?) {
        self.playlistType = playlistType
    }
}
