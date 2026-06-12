// Mirrors: nanojson:src/main/java/com/grack/nanojson/JsonParserException.java @ c7a6c1c

/// Thrown when the JsonParser encounters malformed JSON.
public final class JsonParserException: Error, CustomStringConvertible {
    public let message: String
    /// 1-based line position of the error.
    public let linePosition: Int
    /// 1-based character position of the error.
    public let charPosition: Int
    /// 0-based character offset of the error from the beginning of the string.
    public let charOffset: Int

    init(message: String, linePosition: Int, charPosition: Int, charOffset: Int) {
        self.message = message
        self.linePosition = linePosition
        self.charPosition = charPosition
        self.charOffset = charOffset
    }

    public var description: String { message }
}
