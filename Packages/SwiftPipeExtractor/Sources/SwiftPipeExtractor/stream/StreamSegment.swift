// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/stream/StreamSegment.java @ v0.26.3

public final class StreamSegment {
    private var title: String
    private var channelName: String?
    private var startTimeSeconds: Int
    public var url: String?
    private var previewUrl: String?

    public init(_ title: String, _ startTimeSeconds: Int) {
        self.title = title
        self.startTimeSeconds = startTimeSeconds
    }

    public func getTitle() -> String { title }
    public func setTitle(_ title: String) { self.title = title }

    public func getStartTimeSeconds() -> Int { startTimeSeconds }
    public func setStartTimeSeconds(_ value: Int) { startTimeSeconds = value }

    public func getChannelName() -> String? { channelName }
    public func setChannelName(_ channelName: String?) { self.channelName = channelName }

    public func getUrl() -> String? { url }
    public func setUrl(_ url: String?) { self.url = url }

    public func getPreviewUrl() -> String? { previewUrl }
    public func setPreviewUrl(_ previewUrl: String?) { self.previewUrl = previewUrl }
}
