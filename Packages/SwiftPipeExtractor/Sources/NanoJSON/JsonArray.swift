// Mirrors: nanojson:src/main/java/com/grack/nanojson/JsonArray.java @ c7a6c1c
//
// Java extends ArrayList<Object>; Swift wraps [Any] with a JsonNull sentinel.
// Java's get(int) returns null for out-of-range positive indices; negative
// indices (an IndexOutOfBoundsException in Java) also return nil here.

public final class JsonArray {
    private var storage: [Any] = []

    /// Creates an empty JsonArray.
    public init() {}

    /// Creates a JsonArray from the given collection of objects.
    public init(_ collection: [Any?]) {
        storage = collection.map { $0 ?? JsonNull.shared }
    }

    /// Creates a JsonArray from an array of contents.
    public static func from(_ contents: Any?...) -> JsonArray {
        JsonArray(contents)
    }

    /// Creates a JsonBuilder for a JsonArray.
    public static func builder() -> JsonBuilder<JsonArray> {
        JsonBuilder(JsonArray())
    }

    // MARK: List mutation (java.util.List surface used by the extractor)

    @discardableResult
    public func add(_ o: Any?) -> Bool {
        storage.append(o ?? JsonNull.shared)
        return true
    }

    public var isEmpty: Bool { storage.isEmpty }
    public var count: Int { storage.count }
    public func size() -> Int { count }

    /// Returns the underlying object at the given index, or nil if it does not exist.
    public func get(_ key: Int) -> Any? {
        guard key >= 0 && key < storage.count else { return nil }
        let v = storage[key]
        return v is JsonNull ? nil : v
    }

    // MARK: Typed getters

    public func getArray(_ key: Int, _ default_: JsonArray = JsonArray()) -> JsonArray {
        (get(key) as? JsonArray) ?? default_
    }

    public func getBoolean(_ key: Int, _ default_: Bool = false) -> Bool {
        (get(key) as? Bool) ?? default_
    }

    public func getDouble(_ key: Int, _ default_: Double = 0) -> Double {
        guard let o = get(key), let d = JavaNumber.doubleValue(o) else { return default_ }
        return d
    }

    public func getFloat(_ key: Int, _ default_: Float = 0) -> Float {
        guard let o = get(key), let f = JavaNumber.floatValue(o) else { return default_ }
        return f
    }

    public func getInt(_ key: Int, _ default_: Int = 0) -> Int {
        guard let o = get(key), let i = JavaNumber.intValue(o) else { return default_ }
        return i
    }

    public func getLong(_ key: Int, _ default_: Int64 = 0) -> Int64 {
        guard let o = get(key), let l = JavaNumber.longValue(o) else { return default_ }
        return l
    }

    public func getNumber(_ key: Int, _ default_: Any? = nil) -> Any? {
        guard let o = get(key), JavaNumber.isNumber(o) else { return default_ }
        return o
    }

    public func getObject(_ key: Int, _ default_: JsonObject = JsonObject()) -> JsonObject {
        (get(key) as? JsonObject) ?? default_
    }

    public func getString(_ key: Int, _ default_: String? = nil) -> String? {
        (get(key) as? String) ?? default_
    }

    // MARK: Type queries

    /// True if the array has an element at that index (even if that element is null).
    public func has(_ key: Int) -> Bool { key >= 0 && key < storage.count }

    public func isBoolean(_ key: Int) -> Bool { get(key) is Bool }

    public func isNull(_ key: Int) -> Bool {
        key >= 0 && key < storage.count && storage[key] is JsonNull
    }

    public func isNumber(_ key: Int) -> Bool {
        guard let o = get(key) else { return false }
        return JavaNumber.isNumber(o)
    }

    public func isString(_ key: Int) -> Bool { get(key) is String }

    // MARK: Streams

    /// Java: streamAsJsonObjects() — only the JsonObject elements.
    public func streamAsJsonObjects() -> [JsonObject] {
        storage.compactMap { $0 as? JsonObject }
    }
}

extension JsonArray: Sequence {
    /// Iterates elements as Any?, surfacing JSON nulls as nil (like iterating
    /// the Java ArrayList).
    public func makeIterator() -> AnyIterator<Any?> {
        var index = 0
        return AnyIterator { [storage] in
            guard index < storage.count else { return nil }
            defer { index += 1 }
            let v = storage[index]
            return .some(v is JsonNull ? nil : v)
        }
    }
}
