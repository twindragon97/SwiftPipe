// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/exceptions/YoutubeMusicPremiumContentException.java @ v0.26.3

public final class YoutubeMusicPremiumContentException: ContentNotAvailableException {
    public init() {
        super.init("This video is a YouTube Music Premium video")
    }

    public init(_ cause: Error) {
        super.init("This video is a YouTube Music Premium video", cause)
    }
}
