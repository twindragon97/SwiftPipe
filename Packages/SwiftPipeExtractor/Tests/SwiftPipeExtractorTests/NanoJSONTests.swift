import XCTest
import NanoJSON

/// Locks the semantics of the NanoJSON port against the Java implementation:
/// insertion order, escaping, number typing, error messages/positions, and
/// byte-identical writer output for extractor-style request bodies.
final class NanoJSONTests: XCTestCase {

    // MARK: Parsing

    func testParseSimpleObject() throws {
        let json = try JsonParser.object().from(
            #"{"s":"x","i":3,"l":3000000000,"d":1.5,"t":true,"f":false,"n":null}"#)
        XCTAssertEqual(json.getString("s"), "x")
        XCTAssertEqual(json.getInt("i"), 3)
        XCTAssertEqual(json.getLong("l"), 3_000_000_000)
        XCTAssertEqual(json.getDouble("d"), 1.5)
        XCTAssertTrue(json.getBoolean("t"))
        XCTAssertFalse(json.getBoolean("f"))
        XCTAssertTrue(json.isNull("n"))
        XCTAssertTrue(json.has("n"))
        XCTAssertFalse(json.has("missing"))
        XCTAssertEqual(json.count, 7)
    }

    func testInsertionOrderPreservedAndRoundTrips() throws {
        let text = #"{"z":1,"a":{"y":2,"b":3},"m":[1,2.5,"x",null,true]}"#
        let json = try JsonParser.object().from(text)
        XCTAssertEqual(json.keySet(), ["z", "a", "m"])
        XCTAssertEqual(json.getObject("a").keySet(), ["y", "b"])
        // Byte-identical round trip (the property the mock tests depend on)
        XCTAssertEqual(JsonWriter.string(json), text)
    }

    func testDuplicateKeyKeepsPositionTakesLastValue() throws {
        let json = try JsonParser.object().from(#"{"a":1,"b":2,"a":3}"#)
        XCTAssertEqual(json.keySet(), ["a", "b"])
        XCTAssertEqual(json.getInt("a"), 3)
    }

    func testParseStringEscapes() throws {
        let json = try JsonParser.object().from(
            #"{"e":"a\nb\t\"\\\/A😀"}"#)
        XCTAssertEqual(json.getString("e"), "a\nb\t\"\\/A😀")
    }

    func testParseArray() throws {
        let array = try JsonParser.array().from(#"[1, {"a": "b"}, null]"#)
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array.getInt(0), 1)
        XCTAssertEqual(array.getObject(1).getString("a"), "b")
        XCTAssertTrue(array.isNull(2))
        XCTAssertNil(array.get(5))
        XCTAssertEqual(array.streamAsJsonObjects().count, 1)
    }

    func testParseAny() throws {
        XCTAssertEqual(try JsonParser.any().from("123") as? Int, 123)
        XCTAssertEqual(try JsonParser.any().from("123.456e7") as? Double, 123.456e7)
        XCTAssertEqual(try JsonParser.any().from(#""x""#) as? String, "x")
        XCTAssertNil(try JsonParser.any().from("null"))
    }

    func testNumberTyping() throws {
        let json = try JsonParser.object().from(
            #"{"zero":0,"negZero":-0,"big":9223372036854775807,"exp":1e3}"#)
        XCTAssertEqual(json.getInt("zero"), 0)
        // Java: -0 is forced to double
        XCTAssertTrue(json.isNumber("negZero"))
        XCTAssertEqual(json.getDouble("negZero"), 0.0)
        XCTAssertEqual(json.getLong("big"), Int64.max)
        XCTAssertEqual(json.getDouble("exp"), 1000.0)
        // Java Number.intValue() truncates longs to 32 bits
        let truncated = try JsonParser.object().from(#"{"l":5000000000}"#)
        XCTAssertEqual(truncated.getInt("l"), Int(Int32(truncatingIfNeeded: 5_000_000_000)))
    }

    // MARK: Parse errors

    private func assertParseError(
        _ text: String, contains fragment: String,
        line: Int? = nil, file: StaticString = #filePath, lineNo: UInt = #line
    ) {
        XCTAssertThrowsError(
            try JsonParser.any().from(text), file: file, line: lineNo
        ) { error in
            guard let e = error as? JsonParserException else {
                XCTFail("Expected JsonParserException, got \(error)", file: file, line: lineNo)
                return
            }
            XCTAssertTrue(
                e.message.contains(fragment),
                "Message '\(e.message)' should contain '\(fragment)'",
                file: file, line: lineNo)
            if let line {
                XCTAssertEqual(e.linePosition, line, file: file, line: lineNo)
            }
        }
    }

    func testParseErrors() {
        assertParseError("{\"a\":01}", contains: "Malformed number: 01")
        assertParseError("+1", contains: "Numbers may not start with '+'")
        assertParseError("[1,2,]", contains: "Trailing comma found in array")
        assertParseError("\"abc", contains: "String was not terminated before end of input")
        assertParseError("tru", contains: "Did you mean 'true'?")
        assertParseError("[1 2]", contains: "Expected a comma or end of the array")
        assertParseError("{\"a\" 1}", contains: "Expected COLON")
        assertParseError("\"a\nb\"", contains: "Strings may not contain control characters")
        assertParseError("{} {}", contains: "Expected end of input")
        // Error position tracking across lines
        assertParseError("{\n  \"a\": tru}", contains: "Unexpected token 'tru", line: 2)
    }

    func testTypeMismatchError() {
        XCTAssertThrowsError(try JsonParser.object().from("[]")) { error in
            let e = error as? JsonParserException
            XCTAssertTrue(e?.message.contains("expected JsonObject") ?? false)
        }
    }

    // MARK: Writer

    func testWriterEscaping() {
        XCTAssertEqual(JsonWriter.string("abc\n\""), "\"abc\\n\\\"\"")
        XCTAssertEqual(JsonWriter.string("</script>"), "\"<\\/script>\"")
        XCTAssertEqual(JsonWriter.string("a/b"), "\"a/b\"")
        XCTAssertEqual(JsonWriter.string("\u{0080}"), "\"\\u0080\"")
        XCTAssertEqual(JsonWriter.string("\u{2028}"), "\"\\u2028\"")
        XCTAssertEqual(JsonWriter.string("😀ñ"), "\"😀ñ\"")
        XCTAssertEqual(JsonWriter.escape("a\"b"), "a\\\"b")
    }

    func testWriterPrimitives() {
        XCTAssertEqual(JsonWriter.string(nil), "null")
        XCTAssertEqual(JsonWriter.string(123), "123")
        XCTAssertEqual(JsonWriter.string(true), "true")
        XCTAssertEqual(JsonWriter.string(Double.nan), "null")
        XCTAssertEqual(JsonWriter.string(Double.infinity), "null")
    }

    func testFluentChainMatchesJavaOutput() {
        // The exact shape used by BandcampCommentsExtractor upstream
        let body = JsonWriter.string()
            .object()
            .value("tralbum_type", "t")
            .value("tralbum_id", 123)
            .value("token", "tok")
            .value("count", 7)
            .array("exclude_fan_ids").end()
            .end()
            .done()
        XCTAssertEqual(
            body,
            #"{"tralbum_type":"t","tralbum_id":123,"token":"tok","count":7,"exclude_fan_ids":[]}"#)
    }

    func testIndentedOutputMatchesJava() {
        let json = JsonWriter.indent("  ").string()
            .object()
            .value("a", 1)
            .value("b", 2)
            .end()
            .done()
        XCTAssertEqual(json, "{\n  \"a\":1,\n  \"b\":2\n}")
    }

    func testWriterObjectWithNull() throws {
        let obj = JsonObject()
        obj.put("a", "x")
        obj.put("n", nil)
        XCTAssertEqual(JsonWriter.string(obj), #"{"a":"x","n":null}"#)
    }

    func testKeyedWriterViaKeyMethod() {
        let json = JsonWriter.string()
            .object()
            .key("a").value(1)
            .end()
            .done()
        XCTAssertEqual(json, #"{"a":1}"#)
    }

    // MARK: Builder

    func testBuilderInnertubeStyleBody() {
        // The exact shape of YoutubeParsingHelper.prepareDesktopJsonBuilder
        let builder = JsonObject.builder()
            .object("context")
            .object("client")
            .value("hl", "en-GB")
            .value("clientName", "IOS")
            .value("clientVersion", "21.03.2")
            .end()
            .end()
            .value("contentCheckOk", true)
        let body = JsonWriter.string(builder.done())
        XCTAssertEqual(
            body,
            #"{"context":{"client":{"hl":"en-GB","clientName":"IOS","clientVersion":"21.03.2"}},"contentCheckOk":true}"#)
    }

    func testBuilderArrayRoot() {
        let array = JsonArray.builder()
            .value(1)
            .object()
            .value("a", "b")
            .end()
            .nul()
            .done()
        XCTAssertEqual(JsonWriter.string(array), #"[1,{"a":"b"},null]"#)
    }

    // MARK: Unicode escapes

    func testUnicodeEscapeInKeyAndValue() throws {
        let raw = "{\"a\\u0041\":\"\\u00f1\"}" // {"aA":"ñ"}
        let json = try JsonParser.object().from(raw)
        XCTAssertTrue(json.has("aA"))
        XCTAssertEqual(json.getString("aA"), "ñ")
    }

    func testSurrogatePairEscapeParsesToEmoji() throws {
        let raw = "\"\\ud83d\\ude00\"" // "😀"
        XCTAssertEqual(try JsonParser.any().from(raw) as? String, "😀")
    }

    func testInvalidUnicodeEscapeThrows() {
        assertParseError("\"\\u00zz\"", contains: "Expected unicode hex escape character")
        assertParseError("\"\\x\"", contains: "Invalid escape")
    }
}
