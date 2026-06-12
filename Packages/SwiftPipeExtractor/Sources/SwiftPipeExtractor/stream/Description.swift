// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/stream/Description.java @ v0.26.3

public final class Description: Hashable {
    public static let HTML = 1
    public static let MARKDOWN = 2
    public static let PLAIN_TEXT = 3

    public static let EMPTY_DESCRIPTION = Description("", PLAIN_TEXT)

    private let content: String
    private let type: Int

    public init(_ content: String?, _ type: Int) {
        self.type = type
        self.content = content ?? ""
    }

    public func getContent() -> String {
        content
    }

    public func getType() -> Int {
        type
    }

    public static func == (lhs: Description, rhs: Description) -> Bool {
        lhs.type == rhs.type && lhs.content == rhs.content
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(content)
        hasher.combine(type)
    }
}
