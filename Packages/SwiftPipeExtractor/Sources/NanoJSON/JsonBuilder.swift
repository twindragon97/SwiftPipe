// Mirrors: nanojson:src/main/java/com/grack/nanojson/JsonBuilder.java @ c7a6c1c
//
// Java's typed value(...) overloads collapse into the Any? dispatchers; call
// sites are identical. Misuse errors (JsonWriterException, unchecked in Java)
// map to preconditionFailure with the same messages.

/// Builds a JsonObject or JsonArray.
///
///     let body = JsonObject.builder()
///         .object("context")
///             .object("client")
///                 .value("hl", "en-GB")
///             .end()
///         .end()
///         .done()
public final class JsonBuilder<T> {
    private var json: [Any] = []
    private var pendingKey: String?
    private let root: T

    public init(_ root: T) {
        self.root = root
        json.append(root)
    }

    /// Completes this builder and returns the built object.
    public func done() -> T {
        root
    }

    // MARK: Values

    @discardableResult
    public func nul() -> JsonBuilder<T> {
        value(nil as Any?)
    }

    @discardableResult
    public func nul(_ key: String) -> JsonBuilder<T> {
        value(key, nil as Any?)
    }

    @discardableResult
    public func value(_ o: Any?) -> JsonBuilder<T> {
        if let key = pendingKey {
            obj().put(key, o)
            pendingKey = nil
        } else {
            arr().add(o)
        }
        return self
    }

    @discardableResult
    public func value(_ key: String, _ o: Any?) -> JsonBuilder<T> {
        precondition(
            pendingKey == nil,
            "Invalid call to emit a key value immediately after emitting a key")
        obj().put(key, o)
        return self
    }

    // MARK: Structure

    @discardableResult
    public func array() -> JsonBuilder<T> {
        let a = JsonArray()
        value(a)
        json.append(a)
        return self
    }

    @discardableResult
    public func object() -> JsonBuilder<T> {
        let o = JsonObject()
        value(o)
        json.append(o)
        return self
    }

    @discardableResult
    public func array(_ key: String) -> JsonBuilder<T> {
        let a = JsonArray()
        value(key, a)
        json.append(a)
        return self
    }

    @discardableResult
    public func object(_ key: String) -> JsonBuilder<T> {
        let o = JsonObject()
        value(key, o)
        json.append(o)
        return self
    }

    @discardableResult
    public func end() -> JsonBuilder<T> {
        precondition(json.count > 1, "Cannot end the root object or array")
        json.removeLast()
        return self
    }

    @discardableResult
    public func key(_ key: String) -> JsonBuilder<T> {
        precondition(
            json.last is JsonObject,
            "Invalid call to emit a key value while not writing an object")
        precondition(
            pendingKey == nil,
            "Invalid call to emit a key value immediately after emitting a key")
        pendingKey = key
        return self
    }

    // MARK: Internals

    private func obj() -> JsonObject {
        guard let o = json.last as? JsonObject else {
            preconditionFailure("Attempted to write a keyed value to a JsonArray")
        }
        return o
    }

    private func arr() -> JsonArray {
        guard let a = json.last as? JsonArray else {
            preconditionFailure("Attempted to write a non-keyed value to a JsonObject")
        }
        return a
    }
}
