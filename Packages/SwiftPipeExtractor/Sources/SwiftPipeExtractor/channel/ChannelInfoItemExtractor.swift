// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/channel/ChannelInfoItemExtractor.java @ v0.26.3

public protocol ChannelInfoItemExtractor: InfoItemExtractor {
    func getDescription() throws -> String?
    func getSubscriberCount() throws -> Int64
    func getStreamCount() throws -> Int64
    func isVerified() throws -> Bool
}
