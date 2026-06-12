// Mirrors: nanojson:src/main/java/com/grack/nanojson/JsonObject.java @ c7a6c1c
//
// Java extends LinkedHashMap<String, Object>; Swift wraps an ordered key list
// plus a dictionary. Insertion order is preserved exactly like LinkedHashMap:
// re-putting an existing key keeps its original position.

public final class JsonObject {
    private var order: [String] = []
    private var storage: [String: Any] = [:]

    /// Creates an empty JsonObject.
    public init() {}

    /// Creates a JsonObject copying an existing one (Java: JsonObject(Map)).
    public init(_ other: JsonObject) {
        order = other.order
        storage = other.storage
    }

    /// Creates a JsonBuilder for a JsonObject.
    public static func builder() -> JsonBuilder<JsonObject> {
        JsonBuilder(JsonObject())
    }

    // MARK: Map mutation (java.util.Map surface used by the extractor)

    @discardableResult
    public func put(_ key: String, _ value: Any?) -> Any? {
        let old = storage[key]
        if old == nil {
            order.append(key)
        }
        storage[key] = value ?? JsonNull.shared
        return old is JsonNull ? nil : old
    }

    @discardableResult
    public func remove(_ key: String) -> Any? {
        guard let old = storage.removeValue(forKey: key) else { return nil }
        if let idx = order.firstIndex(of: key) {
            order.remove(at: idx)
        }
        return old is JsonNull ? nil : old
    }

    public func get(_ key: String) -> Any? {
        let v = storage[key]
        return v is JsonNull ? nil : v
    }

    public var isEmpty: Bool { order.isEmpty }
    public var count: Int { order.count }
    public func size() -> Int { count }

    /// Keys in insertion order (Java: keySet() of a LinkedHashMap).
    public func keySet() -> [String] { order }

    /// Entries in insertion order (Java: entrySet()). Null values surface as nil.
    public func entrySet() -> [(key: String, value: Any?)] {
        order.map { ($0, get($0)) }
    }

    // MARK: Typed getters

    public func getArray(_ key: String, _ default_: JsonArray = JsonArray()) -> JsonArray {
        (get(key) as? JsonArray) ?? default_
    }

    public func getBoolean(_ key: String, _ default_: Bool = false) -> Bool {
        (get(key) as? Bool) ?? default_
    }

    public func getDouble(_ key: String, _ default_: Double = 0) -> Double {
        guard let o = get(key), let d = JavaNumber.doubleValue(o) else { return default_ }
        return d
    }

    public func getFloat(_ key: String, _ default_: Float = 0) -> Float {
        guard let o = get(key), let f = JavaNumber.floatValue(o) else { return default_ }
        return f
    }

    public func getInt(_ key: String, _ default_: Int = 0) -> Int {
        guard let o = get(key), let i = JavaNumber.intValue(o) else { return default_ }
        return i
    }

    public func getLong(_ key: String, _ default_: Int64 = 0) -> Int64 {
        guard let o = get(key), let l = JavaNumber.longValue(o) else { return default_ }
        return l
    }

    /// Returns the numeric value at the given key, or the default if it does
    /// not exist or is the wrong type (Java returns Number).
    public func getNumber(_ key: String, _ default_: Any? = nil) -> Any? {
        guard let o = get(key), JavaNumber.isNumber(o) else { return default_ }
        return o
    }

    public func getObject(_ key: String, _ default_: JsonObject = JsonObject()) -> JsonObject {
        (get(key) as? JsonObject) ?? default_
    }

    public func getString(_ key: String, _ default_: String? = nil) -> String? {
        (get(key) as? String) ?? default_
    }

    // MARK: Type queries

    /// True if the object has an element at that key (even if that element is null).
    public func has(_ key: String) -> Bool { storage[key] != nil }

    public func isBoolean(_ key: String) -> Bool { get(key) is Bool }

    /// True if the object has a null element at that key.
    public func isNull(_ key: String) -> Bool { storage[key] is JsonNull }

    public func isNumber(_ key: String) -> Bool {
        guard let o = get(key) else { return false }
        return JavaNumber.isNumber(o)
    }

    public func isString(_ key: String) -> Bool { get(key) is String }
}
