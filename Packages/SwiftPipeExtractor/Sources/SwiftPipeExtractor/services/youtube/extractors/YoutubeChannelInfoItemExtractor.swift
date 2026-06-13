// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/extractors/YoutubeChannelInfoItemExtractor.java @ v0.26.3

import NanoJSON

public final class YoutubeChannelInfoItemExtractor: ChannelInfoItemExtractor {
    private let channelInfoItem: JsonObject
    private let withHandle: Bool

    public init(_ channelInfoItem: JsonObject) {
        self.channelInfoItem = channelInfoItem
        var wHandle = false
        if let subscriberCountText = YoutubeParsingHelper.getTextFromObject(
            channelInfoItem.getObject("subscriberCountText")) {
            wHandle = subscriberCountText.hasPrefix("@")
        }
        self.withHandle = wHandle
    }

    public func getThumbnails() throws -> [Image] {
        do {
            return try YoutubeParsingHelper.getThumbnailsFromInfoItem(channelInfoItem)
        } catch {
            throw ParsingException("Could not get thumbnails", error)
        }
    }

    public func getName() throws -> String {
        guard let name = YoutubeParsingHelper.getTextFromObject(
            channelInfoItem.getObject("title")) else {
            throw ParsingException("Could not get name")
        }
        return name
    }

    public func getUrl() throws -> String {
        do {
            let id = "channel/" + (channelInfoItem.getString("channelId") ?? "")
            return try YoutubeChannelLinkHandlerFactory.getInstance().getUrl(id)
        } catch {
            throw ParsingException("Could not get url", error)
        }
    }

    public func getSubscriberCount() throws -> Int64 {
        do {
            if !channelInfoItem.has("subscriberCountText") {
                // Subscription count is not available for this channel item.
                return -1
            }
            if withHandle {
                if channelInfoItem.has("videoCountText") {
                    return try Utils.mixedNumberWordToLong(
                        YoutubeParsingHelper.getTextFromObject(
                            channelInfoItem.getObject("videoCountText")) ?? "")
                } else {
                    return -1
                }
            }
            return try Utils.mixedNumberWordToLong(
                YoutubeParsingHelper.getTextFromObject(
                    channelInfoItem.getObject("subscriberCountText")) ?? "")
        } catch {
            throw ParsingException("Could not get subscriber count", error)
        }
    }

    public func getStreamCount() throws -> Int64 {
        do {
            if withHandle || !channelInfoItem.has("videoCountText") {
                // Video count is not available (no public uploads, or the
                // channel handle is displayed instead).
                return ListExtractor<StreamInfoItem>.ITEM_COUNT_UNKNOWN
            }
            return Int64(Utils.removeNonDigitCharacters(
                YoutubeParsingHelper.getTextFromObject(
                    channelInfoItem.getObject("videoCountText")) ?? "")) ?? 0
        } catch {
            throw ParsingException("Could not get stream count", error)
        }
    }

    public func isVerified() throws -> Bool {
        YoutubeParsingHelper.isVerified(channelInfoItem.getArray("ownerBadges"))
    }

    public func getDescription() throws -> String? {
        if !channelInfoItem.has("descriptionSnippet") {
            // Channel has no description.
            return nil
        }
        return YoutubeParsingHelper.getTextFromObject(
            channelInfoItem.getObject("descriptionSnippet"))
    }
}
