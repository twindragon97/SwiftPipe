// Mirrors: nanojson:src/main/java/com/grack/nanojson/JsonWriter.java @ c7a6c1c
//
// Only the String-targeting factories are ported (string(), string(Object),
// indent(), escape()); the Appendable/OutputStream variants are not needed by
// the extractor (documented deviation).

/// Factory for JSON writers that target Strings.
///
///     let json = JsonWriter.string()
///         .object()
///             .array("a").value(1).value(2).end()
///             .value("b", false)
///         .end()
///         .done()
public enum JsonWriter {
    /// Allows for additional configuration of the JsonWriter.
    public struct JsonWriterContext {
        let indentValue: String

        /// Creates a new JsonStringWriter with this context's indent.
        public func string() -> JsonStringWriter {
            JsonStringWriter(indent: indentValue)
        }
    }

    /// Creates a JsonWriter source that will write indented output with the
    /// given indent.
    public static func indent(_ indent: String) -> JsonWriterContext {
        for ch in indent.unicodeScalars {
            precondition(
                ch == " " || ch == "\t",
                "Only tabs and spaces are allowed for indent.")
        }
        return JsonWriterContext(indentValue: indent)
    }

    /// Creates a new JsonStringWriter.
    public static func string() -> JsonStringWriter {
        JsonStringWriter(indent: nil)
    }

    /// Emits a single value (a JSON primitive, a JsonObject or a JsonArray)
    /// as a JSON string.
    ///
    ///     JsonWriter.string("abc\n\"")  // "\"abc\\n\\\"\""
    public static func string(_ value: Any?) -> String {
        JsonStringWriter(indent: nil).value(value).done()
    }

    /// Escape a string value (the quoted form without the surrounding quotes).
    public static func escape(_ value: String) -> String {
        let s = string(value)
        return String(s.dropFirst().dropLast())
    }
}
