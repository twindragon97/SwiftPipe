// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/subscription/SubscriptionItem.java @ v0.26.3

public final class SubscriptionItem: CustomStringConvertible {
    private let serviceId: Int
    private let url: String
    private let name: String

    public init(_ serviceId: Int, _ url: String, _ name: String) {
        self.serviceId = serviceId
        self.url = url
        self.name = name
    }

    public func getServiceId() -> Int { serviceId }
    public func getUrl() -> String { url }
    public func getName() -> String { name }

    public var description: String {
        "\(type(of: self))[name=\(name) > \(serviceId):\(url)]"
    }
}
