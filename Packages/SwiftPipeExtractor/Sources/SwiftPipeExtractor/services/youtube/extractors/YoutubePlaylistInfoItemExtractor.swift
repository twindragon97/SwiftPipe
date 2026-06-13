// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/extractors/YoutubePlaylistInfoItemExtractor.java @ v0.26.3
//
// Deviation: getName/getUploaderName throw if the text is nil (the Swift
// InfoItem model uses a non-optional name), where Java would pass null along.

import NanoJSON

public final class YoutubePlaylistInfoItemExtractor: PlaylistInfoItemExtractor {
    private let playlistInfoItem: JsonObject

    public init(_ playlistInfoItem: JsonObject) {
        self.playlistInfoItem = playlistInfoItem
    }

    public func getThumbnails() throws -> [Image] {
        var thumbnails = playlistInfoItem.getArray("thumbnails")
            .getObject(0)
            .getArray("thumbnails")
        if thumbnails.isEmpty {
            thumbnails = playlistInfoItem.getObject("thumbnail").getArray("thumbnails")
        }
        return YoutubeParsingHelper.getImagesFromThumbnailsArray(thumbnails)
    }

    public func getName() throws -> String {
        guard let name = YoutubeParsingHelper.getTextFromObject(
            playlistInfoItem.getObject("title")) else {
            throw ParsingException("Could not get name")
        }
        return name
    }

    public func getUrl() throws -> String {
        do {
            let id = playlistInfoItem.getString("playlistId") ?? ""
            return try YoutubePlaylistLinkHandlerFactory.getInstance().getUrl(id)
        } catch {
            throw ParsingException("Could not get url", error)
        }
    }

    public func getUploaderName() throws -> String? {
        YoutubeParsingHelper.getTextFromObject(playlistInfoItem.getObject("longBylineText"))
    }

    public func getUploaderUrl() throws -> String? {
        YoutubeParsingHelper.getUrlFromObject(playlistInfoItem.getObject("longBylineText"))
    }

    public func isUploaderVerified() throws -> Bool {
        YoutubeParsingHelper.isVerified(playlistInfoItem.getArray("ownerBadges"))
    }

    public func getStreamCount() throws -> Int64 {
        var videoCountText = playlistInfoItem.getString("videoCount")
        if videoCountText == nil {
            videoCountText = YoutubeParsingHelper.getTextFromObject(
                playlistInfoItem.getObject("videoCountText"))
        }
        if videoCountText == nil {
            videoCountText = YoutubeParsingHelper.getTextFromObject(
                playlistInfoItem.getObject("videoCountShortText"))
        }
        guard let videoCountText else {
            throw ParsingException("Could not get stream count")
        }
        guard let count = Int64(Utils.removeNonDigitCharacters(videoCountText)) else {
            throw ParsingException("Could not get stream count")
        }
        return count
    }
}
