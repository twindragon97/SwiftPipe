// No direct Java counterpart: Java collections store null directly, Swift's
// cannot. JsonNull is the internal sentinel for JSON null inside JsonObject/
// JsonArray storage. Public APIs translate it back to Swift nil (get returns
// nil, isNull returns true, the writer emits "null").

final class JsonNull {
    static let shared = JsonNull()
    private init() {}
}
