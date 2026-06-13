// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/PoTokenResult.java @ v0.26.3

public final class PoTokenResult {
    public let visitorData: String
    public let playerRequestPoToken: String
    public let streamingDataPoToken: String?

    public init(
        _ visitorData: String,
        _ playerRequestPoToken: String,
        _ streamingDataPoToken: String?
    ) {
        self.visitorData = visitorData
        self.playerRequestPoToken = playerRequestPoToken
        self.streamingDataPoToken = streamingDataPoToken
    }
}
