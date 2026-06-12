// Mirrors: nanojson:src/main/java/com/grack/nanojson/JsonStringWriter.java @ c7a6c1c

/// JSON writer that emits JSON to a String.
///
/// Create this class using JsonWriter.string():
///
///     let json = JsonWriter.string()
///         .object()
///             .array("a").value(1).value(2).end()
///             .value("b", false)
///         .end()
///         .done()
public final class JsonStringWriter: JsonWriterBase {
    override init(indent: String?) {
        super.init(indent: indent)
    }

    /// Completes this JSON writing session and returns the internal
    /// representation as a String.
    public func done() -> String {
        doneInternal()
        return bufferedString()
    }
}
