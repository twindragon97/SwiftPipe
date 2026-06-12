// Mirrors: nanojson:src/main/java/com/grack/nanojson/JsonWriterBase.java @ c7a6c1c
//
// Only the String-output path (Java's Appendable mode) is ported; the
// extractor never writes to streams. Escaping rules, state tracking, indent
// behavior and all error messages are mirrored exactly. Java's unchecked
// JsonWriterException maps to preconditionFailure (documented deviation).
// Where Java iterates UTF-16 chars, this port iterates Unicode scalars —
// identical output for all valid strings (the escape ranges are BMP-only).

public class JsonWriterBase {
    private static let HEX: [Character] = [
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f",
    ]

    private var buffer = ""
    private var states: [Bool] = []
    private var stateIndex = 0
    private var first = true
    private var inObject = false
    private var pendingKey: String?

    /// Sequence to use for indenting, nil for compact output.
    private let indentString: String?

    /// Current indent amount.
    private var indent = 0

    init(indent: String?) {
        self.indentString = indent
    }

    /// The accumulated output (Java: appendable.toString()).
    func bufferedString() -> String {
        buffer
    }

    // MARK: Null

    @discardableResult
    public func nul() -> Self {
        preValue()
        raw("null")
        return self
    }

    @discardableResult
    public func nul(_ key: String) -> Self {
        preValue(key)
        raw("null")
        return self
    }

    // MARK: Generic value dispatch (Java: value(Object) / value(String, Object))

    @discardableResult
    public func value(_ o: Any?) -> Self {
        guard let o, !(o is JsonNull) else { return nul() }
        switch o {
        case let s as String:
            return value(s)
        case let b as Bool:
            return value(b)
        case let a as JsonArray:
            return array(a)
        case let m as JsonObject:
            return object(m)
        case let c as [Any?]:
            return array(c)
        case let c as [Any]:
            return array(c.map { Optional($0) })
        default:
            if JavaNumber.isNumber(o) {
                return numberValue(o)
            }
            preconditionFailure("Unable to handle type: \(type(of: o))")
        }
    }

    @discardableResult
    public func value(_ key: String, _ o: Any?) -> Self {
        guard let o, !(o is JsonNull) else { return nul(key) }
        switch o {
        case let s as String:
            return value(key, s)
        case let b as Bool:
            return value(key, b)
        case let a as JsonArray:
            return array(key, a)
        case let m as JsonObject:
            return object(key, m)
        case let c as [Any?]:
            return array(key, c)
        case let c as [Any]:
            return array(key, c.map { Optional($0) })
        default:
            if JavaNumber.isNumber(o) {
                // Java: value(String, Number) — no NaN/Infinity check here
                preValue(key)
                raw(JavaNumber.toJavaString(o)!)
                return self
            }
            preconditionFailure("Unable to handle type: \(type(of: o))")
        }
    }

    /// Java: value(Number) — NaN/Infinity become null per modern JS engines.
    @discardableResult
    private func numberValue(_ n: Any) -> Self {
        preValue()
        if JavaNumber.isNaNOrInfinite(n) {
            raw("null")
        } else {
            raw(JavaNumber.toJavaString(n)!)
        }
        return self
    }

    // MARK: Typed values

    @discardableResult
    public func value(_ s: String?) -> Self {
        guard let s else { return nul() }
        preValue()
        emitStringValue(s)
        return self
    }

    @discardableResult
    public func value(_ i: Int) -> Self {
        preValue()
        raw(String(i))
        return self
    }

    @discardableResult
    public func value(_ l: Int64) -> Self {
        preValue()
        raw(String(l))
        return self
    }

    @discardableResult
    public func value(_ b: Bool) -> Self {
        preValue()
        raw(b ? "true" : "false")
        return self
    }

    @discardableResult
    public func value(_ d: Double) -> Self {
        preValue()
        raw(String(d))
        return self
    }

    @discardableResult
    public func value(_ key: String, _ s: String?) -> Self {
        guard let s else { return nul(key) }
        preValue(key)
        emitStringValue(s)
        return self
    }

    @discardableResult
    public func value(_ key: String, _ i: Int) -> Self {
        preValue(key)
        raw(String(i))
        return self
    }

    @discardableResult
    public func value(_ key: String, _ l: Int64) -> Self {
        preValue(key)
        raw(String(l))
        return self
    }

    @discardableResult
    public func value(_ key: String, _ b: Bool) -> Self {
        preValue(key)
        raw(b ? "true" : "false")
        return self
    }

    @discardableResult
    public func value(_ key: String, _ d: Double) -> Self {
        preValue(key)
        raw(String(d))
        return self
    }

    // MARK: Collections (Java: array(Collection), object(Map))

    @discardableResult
    public func array(_ c: [Any?]) -> Self {
        array(nil as String?, c)
    }

    @discardableResult
    public func array(_ key: String?, _ c: [Any?]) -> Self {
        if let key {
            array(key)
        } else {
            array()
        }
        for o in c {
            value(o)
        }
        return end()
    }

    @discardableResult
    public func array(_ a: JsonArray) -> Self {
        array(nil as String?, a)
    }

    @discardableResult
    public func array(_ key: String?, _ a: JsonArray) -> Self {
        if let key {
            array(key)
        } else {
            array()
        }
        for o in a {
            value(o)
        }
        return end()
    }

    @discardableResult
    public func object(_ map: JsonObject) -> Self {
        object(nil as String?, map)
    }

    @discardableResult
    public func object(_ key: String?, _ map: JsonObject) -> Self {
        if let key {
            object(key)
        } else {
            object()
        }
        for k in map.keySet() {
            value(k, map.get(k))
        }
        return end()
    }

    // MARK: Structure

    @discardableResult
    public func array() -> Self {
        preValue()
        pushState()
        inObject = false
        first = true
        raw("[")
        return self
    }

    @discardableResult
    public func object() -> Self {
        preValue()
        pushState()
        inObject = true
        first = true
        raw("{")
        if indentString != nil {
            indent += 1
            appendNewLine()
        }
        return self
    }

    @discardableResult
    public func array(_ key: String) -> Self {
        preValue(key)
        pushState()
        inObject = false
        first = true
        raw("[")
        return self
    }

    @discardableResult
    public func object(_ key: String) -> Self {
        preValue(key)
        pushState()
        inObject = true
        first = true
        raw("{")
        if indentString != nil {
            indent += 1
            appendNewLine()
        }
        return self
    }

    @discardableResult
    public func end() -> Self {
        precondition(stateIndex > 0, "Invalid call to end()")

        if inObject {
            if indentString != nil {
                indent -= 1
                appendNewLine()
                appendIndent()
            }
            raw("}")
        } else {
            raw("]")
        }

        first = false
        stateIndex -= 1
        inObject = states[stateIndex]
        return self
    }

    @discardableResult
    public func key(_ key: String) -> Self {
        precondition(
            pendingKey == nil,
            "Invalid call to emit a key immediately after emitting a key")
        pendingKey = key
        return self
    }

    /// Ensures that the object is in the finished state.
    func doneInternal() {
        precondition(
            stateIndex == 0,
            "Unclosed JSON objects and/or arrays when closing writer")
        precondition(!first, "Nothing was written to the JSON writer")
    }

    // MARK: Internals

    private func pushState() {
        if stateIndex == states.count {
            states.append(inObject)
        } else {
            states[stateIndex] = inObject
        }
        stateIndex += 1
    }

    private func appendIndent() {
        guard let indentString else { return }
        for _ in 0..<indent {
            raw(indentString)
        }
    }

    private func appendNewLine() {
        raw("\n")
    }

    private func raw(_ s: String) {
        buffer += s
    }

    private func raw(_ c: Character) {
        buffer.append(c)
    }

    private func pre() {
        if first {
            first = false
        } else {
            precondition(
                stateIndex > 0,
                "Invalid call to emit a value in a finished JSON writer")
            raw(",")
            if indentString != nil && inObject {
                appendNewLine()
            }
        }
    }

    private func preValue() {
        if let key = pendingKey {
            pendingKey = nil
            preValue(key)
            return
        }
        precondition(
            !inObject,
            "Invalid call to emit a keyless value while writing an object")

        pre()
    }

    private func preValue(_ key: String) {
        precondition(
            inObject,
            "Invalid call to emit a key value while not writing an object")
        precondition(
            pendingKey == nil,
            "Invalid call to emit a key value immediately after emitting a key")

        pre()

        if indentString != nil {
            appendIndent()
        }
        emitStringValue(key)
        raw(":")
    }

    /// Emits a quoted string value, escaping characters that are required to
    /// be escaped.
    private func emitStringValue(_ s: String) {
        raw("\"")
        var b: Unicode.Scalar = Unicode.Scalar(UInt8(0))
        var c: Unicode.Scalar = Unicode.Scalar(UInt8(0))
        for scalar in s.unicodeScalars {
            b = c
            c = scalar

            switch c {
            case "\\", "\"":
                raw("\\")
                raw(Character(c))
            case "/":
                // Special case to ensure that </script> doesn't appear in JSON output
                if b == "<" {
                    raw("\\")
                }
                raw(Character(c))
            case Unicode.Scalar(UInt8(0x08)):
                raw("\\b")
            case "\t":
                raw("\\t")
            case "\n":
                raw("\\n")
            case Unicode.Scalar(UInt8(0x0C)):
                raw("\\f")
            case "\r":
                raw("\\r")
            default:
                if shouldBeEscaped(c) {
                    let v = Int(c.value)
                    if v < 0x100 {
                        raw("\\u00")
                        raw(Self.HEX[(v >> 4) & 0xf])
                        raw(Self.HEX[v & 0xf])
                    } else {
                        raw("\\u")
                        raw(Self.HEX[(v >> 12) & 0xf])
                        raw(Self.HEX[(v >> 8) & 0xf])
                        raw(Self.HEX[(v >> 4) & 0xf])
                        raw(Self.HEX[v & 0xf])
                    }
                } else {
                    buffer.unicodeScalars.append(c)
                }
            }
        }

        raw("\"")
    }

    /// json.org spec says that all control characters must be escaped.
    private func shouldBeEscaped(_ c: Unicode.Scalar) -> Bool {
        let v = c.value
        return v < 0x20 || (v >= 0x80 && v < 0xA0) || (v >= 0x2000 && v < 0x2100)
    }
}
