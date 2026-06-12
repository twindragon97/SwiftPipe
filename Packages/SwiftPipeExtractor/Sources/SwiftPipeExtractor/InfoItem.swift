// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/InfoItem.java @ v0.26.3

open class InfoItem: CustomStringConvertible {
    private let infoType: InfoType
    private let serviceId: Int
    private let url: String
    private let name: String
    private var thumbnails: [Image] = []

    public init(
        _ infoType: InfoType,
        _ serviceId: Int,
        _ url: String,
        _ name: String
    ) {
        self.infoType = infoType
        self.serviceId = serviceId
        self.url = url
        self.name = name
    }

    public func getInfoType() -> InfoType {
        infoType
    }

    public func getServiceId() -> Int {
        serviceId
    }

    public func getUrl() -> String {
        url
    }

    public func getName() -> String {
        name
    }

    public func setThumbnails(_ thumbnails: [Image]) {
        self.thumbnails = thumbnails
    }

    public func getThumbnails() -> [Image] {
        thumbnails
    }

    public var description: String {
        "\(type(of: self))[url=\"\(url)\", name=\"\(name)\"]"
    }

    public enum InfoType {
        case STREAM
        case PLAYLIST
        case CHANNEL
        case COMMENT
    }
}
