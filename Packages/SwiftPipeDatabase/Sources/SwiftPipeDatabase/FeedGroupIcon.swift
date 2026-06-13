// Mirrors: app/src/main/java/org/schabi/newpipe/local/subscription/FeedGroupIcon.kt @ v0.27.x
//
// Only the persistent `id` mapping is mirrored here — the Android drawable
// resources are an Android-UI concern and are remapped to SF Symbols in the app
// layer. The rawValue IS the id Room stores in feed_group.icon_id, so a
// FeedGroupIcon round-trips byte-identically through the database.

public enum FeedGroupIcon: Int, CaseIterable, Sendable {
    case all = 0
    case music = 1
    case education = 2
    case fitness = 3
    case space = 4
    case computer = 5
    case gaming = 6
    case sports = 7
    case news = 8
    case favorites = 9
    case car = 10
    case motorcycle = 11
    case trend = 12
    case movie = 13
    case backup = 14
    case art = 15
    case person = 16
    case people = 17
    case money = 18
    case kids = 19
    case food = 20
    case smile = 21
    case explore = 22
    case restaurant = 23
    case mic = 24
    case headset = 25
    case radio = 26
    case shoppingCart = 27
    case watchLater = 28
    case work = 29
    case hot = 30
    case channel = 31
    case bookmark = 32
    case pets = 33
    case world = 34
    case star = 35
    case sun = 36
    case rss = 37
    case whatsNew = 38

    /// The id Room persists (identical to `rawValue`; named to match the Kotlin
    /// `FeedGroupIcon.id` property the Converter reads).
    public var id: Int { rawValue }
}
