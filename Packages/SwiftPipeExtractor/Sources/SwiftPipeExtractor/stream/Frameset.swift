// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/stream/Frameset.java @ v0.26.3

public final class Frameset {
    private let urls: [String]
    private let frameWidth: Int
    private let frameHeight: Int
    private let totalCount: Int
    private let durationPerFrame: Int
    private let framesPerPageX: Int
    private let framesPerPageY: Int

    public init(
        _ urls: [String],
        _ frameWidth: Int,
        _ frameHeight: Int,
        _ totalCount: Int,
        _ durationPerFrame: Int,
        _ framesPerPageX: Int,
        _ framesPerPageY: Int
    ) {
        self.urls = urls
        self.totalCount = totalCount
        self.durationPerFrame = durationPerFrame
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
        self.framesPerPageX = framesPerPageX
        self.framesPerPageY = framesPerPageY
    }

    public func getUrls() -> [String] { urls }
    public func getTotalCount() -> Int { totalCount }
    public func getFramesPerPageX() -> Int { framesPerPageX }
    public func getFramesPerPageY() -> Int { framesPerPageY }
    public func getFrameWidth() -> Int { frameWidth }
    public func getFrameHeight() -> Int { frameHeight }
    public func getDurationPerFrame() -> Int { durationPerFrame }

    /// Returns [storyboardIndex, left, top, right, bottom] for the frame at
    /// the given stream position (milliseconds).
    public func getFrameBoundsAt(_ position: Int64) -> [Int] {
        if position < 0 || position > Int64(totalCount + 1) * Int64(durationPerFrame) {
            // Return the first frame as fallback
            return [0, 0, 0, frameWidth, frameHeight]
        }

        let framesPerStoryboard = framesPerPageX * framesPerPageY
        let absoluteFrameNumber = min(Int(position / Int64(durationPerFrame)), totalCount)
        let relativeFrameNumber = absoluteFrameNumber % framesPerStoryboard
        let rowIndex = relativeFrameNumber / framesPerPageX
        let columnIndex = relativeFrameNumber % framesPerPageY

        return [
            absoluteFrameNumber / framesPerStoryboard,
            columnIndex * frameWidth,
            rowIndex * frameHeight,
            columnIndex * frameWidth + frameWidth,
            rowIndex * frameHeight + frameHeight,
        ]
    }
}
