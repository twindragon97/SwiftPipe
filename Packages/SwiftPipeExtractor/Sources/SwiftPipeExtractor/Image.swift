// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/Image.java @ v0.26.3

public final class Image: CustomStringConvertible {
    /// Constant representing that the height of an Image is unknown.
    public static let HEIGHT_UNKNOWN = -1

    /// Constant representing that the width of an Image is unknown.
    public static let WIDTH_UNKNOWN = -1

    private let url: String
    private let height: Int
    private let width: Int
    private let estimatedResolutionLevel: ResolutionLevel

    public init(
        _ url: String,
        _ height: Int,
        _ width: Int,
        _ estimatedResolutionLevel: ResolutionLevel
    ) {
        self.url = url
        self.height = height
        self.width = width
        self.estimatedResolutionLevel = estimatedResolutionLevel
    }

    public func getUrl() -> String {
        url
    }

    /// The Image's height, or HEIGHT_UNKNOWN.
    public func getHeight() -> Int {
        height
    }

    /// The Image's width, or WIDTH_UNKNOWN.
    public func getWidth() -> Int {
        width
    }

    /// The estimated resolution level of this image, never nil.
    public func getEstimatedResolutionLevel() -> ResolutionLevel {
        estimatedResolutionLevel
    }

    public var description: String {
        "Image {url=\(url), height=\(height), width=\(width), "
            + "estimatedResolutionLevel=\(estimatedResolutionLevel)}"
    }

    /// The estimated resolution level of an Image.
    public enum ResolutionLevel {
        /// Height >= 720px.
        case HIGH
        /// Height in [175px, 720px).
        case MEDIUM
        /// Height in [1px, 175px).
        case LOW
        /// The extractor doesn't know the resolution level.
        case UNKNOWN

        public static func fromHeight(_ heightPx: Int) -> ResolutionLevel {
            if heightPx <= 0 {
                return .UNKNOWN
            }
            if heightPx < 175 {
                return .LOW
            }
            if heightPx < 720 {
                return .MEDIUM
            }
            return .HIGH
        }
    }
}
