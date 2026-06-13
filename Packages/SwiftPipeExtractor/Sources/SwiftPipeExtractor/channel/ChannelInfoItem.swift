// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/channel/ChannelInfoItem.java @ v0.26.3

public final class ChannelInfoItem: InfoItem {
    // Backing field renamed from Java's `description` to avoid clashing with
    // CustomStringConvertible.description (InfoItem's toString). Public API
    // (getDescription/setDescription) is unchanged.
    private var descriptionValue: String?
    private var subscriberCount: Int64 = -1
    private var streamCount: Int64 = -1
    private var verified = false

    public init(_ serviceId: Int, _ url: String, _ name: String) {
        super.init(.CHANNEL, serviceId, url, name)
    }

    public func getDescription() -> String? { descriptionValue }
    public func setDescription(_ description: String?) { self.descriptionValue = description }

    public func getSubscriberCount() -> Int64 { subscriberCount }
    public func setSubscriberCount(_ subscriberCount: Int64) {
        self.subscriberCount = subscriberCount
    }

    public func getStreamCount() -> Int64 { streamCount }
    public func setStreamCount(_ streamCount: Int64) { self.streamCount = streamCount }

    public func isVerified() -> Bool { verified }
    public func setVerified(_ verified: Bool) { self.verified = verified }
}
