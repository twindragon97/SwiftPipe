// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/InnertubeClientRequestInfo.java @ v0.26.3
//
// Mutable struct-like holders kept as classes (Java public mutable fields)
// so callers that mutate clientInfo.visitorData etc. see shared changes.

public final class InnertubeClientRequestInfo {
    public var clientInfo: ClientInfo
    public var deviceInfo: DeviceInfo

    public final class ClientInfo {
        public var clientName: String
        public var clientVersion: String
        public var clientId: String
        public var clientScreen: String?
        public var visitorData: String?

        init(
            _ clientName: String,
            _ clientVersion: String,
            _ clientId: String,
            _ clientScreen: String?,
            _ visitorData: String?
        ) {
            self.clientName = clientName
            self.clientVersion = clientVersion
            self.clientId = clientId
            self.clientScreen = clientScreen
            self.visitorData = visitorData
        }
    }

    public final class DeviceInfo {
        public var platform: String?
        public var deviceMake: String?
        public var deviceModel: String?
        public var osName: String?
        public var osVersion: String?
        public var androidSdkVersion: Int

        init(
            _ platform: String?,
            _ deviceMake: String?,
            _ deviceModel: String?,
            _ osName: String?,
            _ osVersion: String?,
            _ androidSdkVersion: Int
        ) {
            self.platform = platform
            self.deviceMake = deviceMake
            self.deviceModel = deviceModel
            self.osName = osName
            self.osVersion = osVersion
            self.androidSdkVersion = androidSdkVersion
        }
    }

    private init(_ clientInfo: ClientInfo, _ deviceInfo: DeviceInfo) {
        self.clientInfo = clientInfo
        self.deviceInfo = deviceInfo
    }

    public static func ofWebClient() -> InnertubeClientRequestInfo {
        InnertubeClientRequestInfo(
            ClientInfo(
                ClientsConstants.WEB_CLIENT_NAME,
                ClientsConstants.WEB_HARDCODED_CLIENT_VERSION,
                ClientsConstants.WEB_CLIENT_ID,
                ClientsConstants.WATCH_CLIENT_SCREEN, nil),
            DeviceInfo(ClientsConstants.DESKTOP_CLIENT_PLATFORM, nil, nil, nil, nil, -1))
    }

    public static func ofWebEmbeddedPlayerClient() -> InnertubeClientRequestInfo {
        InnertubeClientRequestInfo(
            ClientInfo(
                ClientsConstants.WEB_EMBEDDED_CLIENT_NAME,
                ClientsConstants.WEB_EMBEDDED_CLIENT_VERSION,
                ClientsConstants.WEB_EMBEDDED_CLIENT_ID,
                ClientsConstants.EMBED_CLIENT_SCREEN, nil),
            DeviceInfo(ClientsConstants.DESKTOP_CLIENT_PLATFORM, nil, nil, nil, nil, -1))
    }

    public static func ofWebMusicAnalyticsChartsClient() -> InnertubeClientRequestInfo {
        InnertubeClientRequestInfo(
            ClientInfo(
                ClientsConstants.WEB_MUSIC_ANALYTICS_CLIENT_NAME,
                ClientsConstants.WEB_MUSIC_ANALYTICS_CLIENT_VERSION,
                ClientsConstants.WEB_MUSIC_ANALYTICS_CLIENT_ID, nil, nil),
            DeviceInfo(nil, nil, nil, nil, nil, -1))
    }

    public static func ofAndroidClient() -> InnertubeClientRequestInfo {
        InnertubeClientRequestInfo(
            ClientInfo(
                ClientsConstants.ANDROID_CLIENT_NAME,
                ClientsConstants.ANDROID_CLIENT_VERSION,
                ClientsConstants.ANDROID_CLIENT_ID,
                ClientsConstants.WATCH_CLIENT_SCREEN, nil),
            DeviceInfo(ClientsConstants.MOBILE_CLIENT_PLATFORM, nil, nil, "Android", "16", 36))
    }

    public static func ofIosClient() -> InnertubeClientRequestInfo {
        InnertubeClientRequestInfo(
            ClientInfo(
                ClientsConstants.IOS_CLIENT_NAME,
                ClientsConstants.IOS_CLIENT_VERSION,
                ClientsConstants.IOS_CLIENT_ID,
                ClientsConstants.WATCH_CLIENT_SCREEN, nil),
            DeviceInfo(
                ClientsConstants.MOBILE_CLIENT_PLATFORM, "Apple",
                ClientsConstants.IOS_DEVICE_MODEL, "iOS", ClientsConstants.IOS_OS_VERSION, -1))
    }

    public static func ofVisionOsClient() -> InnertubeClientRequestInfo {
        InnertubeClientRequestInfo(
            ClientInfo(
                ClientsConstants.VISIONOS_CLIENT_NAME,
                ClientsConstants.VISIONOS_CLIENT_VERSION,
                ClientsConstants.VISIONOS_CLIENT_ID,
                ClientsConstants.WATCH_CLIENT_SCREEN, nil),
            DeviceInfo(
                ClientsConstants.MOBILE_CLIENT_PLATFORM, "Apple",
                ClientsConstants.VISIONOS_DEVICE_MODEL, "visionOS",
                ClientsConstants.VISIONOS_VERSION, -1))
    }
}
