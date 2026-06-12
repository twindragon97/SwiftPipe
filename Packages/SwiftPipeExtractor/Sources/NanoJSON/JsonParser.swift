// Mirrors: nanojson:src/main/java/com/grack/nanojson/JsonParser.java @ c7a6c1c
//
// Java's JsonParserContext<T> covers object()/array()/any() with a Class<T>
// token; Swift splits any() into JsonParserAnyContext because Any? cannot be
// a generic cast target (documented deviation — call sites are identical).
// withLazyNumbers()/withLazyStrings() are kept as no-ops: this port parses
// eagerly (deviation; observable values are identical).

/// Simple JSON parser.
///
///     let json = try JsonParser.object().from("{\"a\":[true,false], \"b\":1}")
///     let array = try JsonParser.array().from("[1, {\"a\":[true,false]}]")
public enum JsonParser {
    /// Type-safe parser context for JsonObject or JsonArray.
    public struct JsonParserContext<T> {
        let expectedTypeName: String
        let transform: (Any?) -> T?

        public func withLazyNumbers() -> JsonParserContext<T> { self }
        public func withLazyStrings() -> JsonParserContext<T> { self }

        /// Parses the current JSON type from a String.
        public func from(_ s: String) throws -> T {
            let tokener = JsonTokener(s)
            let parsed = try Parser(tokener).parseRoot()
            guard let result = transform(parsed) else {
                throw tokener.createParseException(
                    "JSON did not contain the correct type, expected \(expectedTypeName).",
                    tokenPos: true)
            }
            return result
        }
    }

    /// Parser context for any(): returns String, a number, Bool, JsonObject,
    /// JsonArray, or nil (for the JSON literal 'null').
    public struct JsonParserAnyContext {
        public func withLazyNumbers() -> JsonParserAnyContext { self }
        public func withLazyStrings() -> JsonParserAnyContext { self }

        public func from(_ s: String) throws -> Any? {
            try Parser(JsonTokener(s)).parseRoot()
        }
    }

    /// Parses a JsonObject from a source.
    public static func object() -> JsonParserContext<JsonObject> {
        JsonParserContext(expectedTypeName: "JsonObject") { $0 as? JsonObject }
    }

    /// Parses a JsonArray from a source.
    public static func array() -> JsonParserContext<JsonArray> {
        JsonParserContext(expectedTypeName: "JsonArray") { $0 as? JsonArray }
    }

    /// Parses any object from a source.
    public static func any() -> JsonParserAnyContext {
        JsonParserAnyContext()
    }
}

/// The parsing engine (Java: the JsonParser instance methods).
private final class Parser {
    private var value: Any?
    private var token = 0
    private let tokener: JsonTokener

    init(_ tokener: JsonTokener) {
        self.tokener = tokener
    }

    /// Parse a single JSON value from the string, expecting an EOF at the end.
    func parseRoot() throws -> Any? {
        _ = try advanceToken()
        let parsed = try currentValue()
        if try advanceToken() != JsonTokener.TOKEN_EOF {
            throw tokener.createParseException(
                "Expected end of input, got \(token)", tokenPos: true)
        }
        return parsed
    }

    /// Starts parsing a JSON value at the current token position.
    private func currentValue() throws -> Any? {
        // Only a value start token should appear when we're in the context of
        // parsing a JSON value
        if token >= JsonTokener.TOKEN_VALUE_MIN {
            return value
        }
        throw tokener.createParseException("Expected JSON value, got \(token)", tokenPos: true)
    }

    /// Consumes a token, first eating up any whitespace ahead of it.
    @discardableResult
    private func advanceToken() throws -> Int {
        token = try tokener.advanceToToken()
        switch token {
        case JsonTokener.TOKEN_ARRAY_START: // Inlined function to avoid additional stack
            let list = JsonArray()
            if try advanceToken() != JsonTokener.TOKEN_ARRAY_END {
                while true {
                    list.add(try currentValue())
                    if try advanceToken() == JsonTokener.TOKEN_ARRAY_END {
                        break
                    }
                    if token != JsonTokener.TOKEN_COMMA {
                        throw tokener.createParseException(
                            "Expected a comma or end of the array instead of \(token)",
                            tokenPos: true)
                    }
                    if try advanceToken() == JsonTokener.TOKEN_ARRAY_END {
                        throw tokener.createParseException(
                            "Trailing comma found in array", tokenPos: true)
                    }
                }
            }
            value = list
            token = JsonTokener.TOKEN_ARRAY_START
            return token
        case JsonTokener.TOKEN_OBJECT_START: // Inlined function to avoid additional stack
            let map = JsonObject()
            if try advanceToken() != JsonTokener.TOKEN_OBJECT_END {
                while true {
                    if token != JsonTokener.TOKEN_STRING {
                        throw tokener.createParseException(
                            "Expected STRING, got \(token)", tokenPos: true)
                    }
                    let key = (value as? String) ?? ""
                    if try advanceToken() != JsonTokener.TOKEN_COLON {
                        throw tokener.createParseException(
                            "Expected COLON, got \(token)", tokenPos: true)
                    }
                    try advanceToken()
                    map.put(key, try currentValue())
                    if try advanceToken() == JsonTokener.TOKEN_OBJECT_END {
                        break
                    }
                    if token != JsonTokener.TOKEN_COMMA {
                        throw tokener.createParseException(
                            "Expected a comma or end of the object instead of \(token)",
                            tokenPos: true)
                    }
                    if try advanceToken() == JsonTokener.TOKEN_OBJECT_END {
                        // Java's (sic) message for a trailing comma in an object
                        throw tokener.createParseException(
                            "Trailing object found in array", tokenPos: true)
                    }
                }
            }
            value = map
            token = JsonTokener.TOKEN_OBJECT_START
            return token
        case JsonTokener.TOKEN_TRUE:
            value = true
        case JsonTokener.TOKEN_FALSE:
            value = false
        case JsonTokener.TOKEN_NULL:
            value = nil
        case JsonTokener.TOKEN_STRING:
            value = tokener.takeBufferedString()
        case JsonTokener.TOKEN_NUMBER:
            value = try parseNumber()
        default:
            break
        }

        return token
    }

    private func parseNumber() throws -> Any {
        let chars = tokener.reusableBuffer
        let text = tokener.takeBufferedString()
        let numLength = chars.count

        if tokener.isDouble {
            guard let d = Double(text) else {
                throw tokener.createParseException("Malformed number: \(text)", tokenPos: true)
            }
            return d
        }

        // Quick parse for single-digits
        if numLength == 1 {
            return Int(chars[0]) - 0x30
        } else if numLength == 2 && chars[0] == 0x2D {
            return 0x30 - Int(chars[1])
        }

        // Attempt to parse using the approximate best type for this
        let firstMinus = chars[0] == 0x2D
        let length = firstMinus ? numLength - 1 : numLength
        if length < 10 || (length == 10 && chars[firstMinus ? 1 : 0] < 0x32) { // 2 147 483 647
            guard let i = Int(text) else {
                throw tokener.createParseException("Malformed number: \(text)", tokenPos: true)
            }
            return i
        }
        if length < 19 || (length == 19 && chars[firstMinus ? 1 : 0] < 0x39) { // 9 223 372 036 854 775 807
            guard let l = Int64(text) else {
                throw tokener.createParseException("Malformed number: \(text)", tokenPos: true)
            }
            return Int(l)
        }
        // Deviation: Java falls back to BigInteger; we fall back to Double.
        guard let d = Double(text) else {
            throw tokener.createParseException("Malformed number: \(text)", tokenPos: true)
        }
        return d
    }
}
