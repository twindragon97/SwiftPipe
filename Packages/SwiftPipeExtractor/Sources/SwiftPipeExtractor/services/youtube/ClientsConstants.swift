// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/ClientsConstants.java @ v0.26.3
//
// Package-private in Java; internal (no `public`) in Swift.

enum ClientsConstants {
    // Common client fields
    static let DESKTOP_CLIENT_PLATFORM = "DESKTOP"
    static let MOBILE_CLIENT_PLATFORM = "MOBILE"
    static let WATCH_CLIENT_SCREEN = "WATCH"
    static let EMBED_CLIENT_SCREEN = "EMBED"

    // WEB (YouTube desktop) client fields
    static let WEB_CLIENT_ID = "1"
    static let WEB_CLIENT_NAME = "WEB"
    static let WEB_HARDCODED_CLIENT_VERSION = "2.20260120.01.00"

    // WEB_REMIX (YouTube Music) client fields
    static let WEB_REMIX_CLIENT_ID = "67"
    static let WEB_REMIX_CLIENT_NAME = "WEB_REMIX"
    static let WEB_REMIX_HARDCODED_CLIENT_VERSION = "1.20260121.03.00"

    // WEB_EMBEDDED_PLAYER (YouTube embeds)
    static let WEB_EMBEDDED_CLIENT_ID = "56"
    static let WEB_EMBEDDED_CLIENT_NAME = "WEB_EMBEDDED_PLAYER"
    static let WEB_EMBEDDED_CLIENT_VERSION = "1.20260122.01.00"

    // WEB_MUSIC_ANALYTICS (YouTube charts)
    static let WEB_MUSIC_ANALYTICS_CLIENT_ID = "31"
    static let WEB_MUSIC_ANALYTICS_CLIENT_NAME = "WEB_MUSIC_ANALYTICS"
    static let WEB_MUSIC_ANALYTICS_CLIENT_VERSION = "2.0"

    // IOS (iOS YouTube app) client fields
    static let IOS_CLIENT_ID = "5"
    static let IOS_CLIENT_NAME = "IOS"
    static let IOS_CLIENT_VERSION = "21.03.2"
    static let IOS_DEVICE_MODEL = "iPhone16,2"
    static let IOS_OS_VERSION = "18.7.2.22H124"
    static let IOS_USER_AGENT_VERSION = "18_7_2"

    // ANDROID (Android YouTube app) client fields
    static let ANDROID_CLIENT_ID = "3"
    static let ANDROID_CLIENT_NAME = "ANDROID"
    static let ANDROID_CLIENT_VERSION = "21.03.36"

    // visionOS client fields
    static let VISIONOS_CLIENT_ID = "101"
    static let VISIONOS_CLIENT_NAME = "VISIONOS"
    static let VISIONOS_CLIENT_VERSION = "1.02"
    static let VISIONOS_DEVICE_MODEL = "RealityDevice14,1"
    static let VISIONOS_VERSION = "25.6.0.23O471"
    static let VISIONOS_USER_AGENT_VERSION = "25_6_0"
}
