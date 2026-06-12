// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/downloader/Response.java @ v0.26.3
//
// Java accessor methods map to Swift properties per the porting conventions.

/// A data class used to hold the results from requests made by the Downloader
/// implementation.
public final class Response {
    public let responseCode: Int
    public let responseMessage: String
    public let responseHeaders: [String: [String]]
    public let responseBody: String

    /// Used for detecting a possible redirection, limited to the latest one.
    public let latestUrl: String

    public init(
        _ responseCode: Int,
        _ responseMessage: String,
        _ responseHeaders: [String: [String]]?,
        _ responseBody: String?,
        _ latestUrl: String?
    ) {
        self.responseCode = responseCode
        self.responseMessage = responseMessage
        self.responseHeaders = responseHeaders ?? [:]
        self.responseBody = responseBody ?? ""
        self.latestUrl = latestUrl ?? ""
    }

    // MARK: Utils

    /// For easy access to some header value that (usually) doesn't repeat
    /// itself. For getting all the values associated to the header, use
    /// responseHeaders (e.g. Set-Cookie).
    public func getHeader(_ name: String) -> String? {
        for (key, values) in responseHeaders {
            if key.caseInsensitiveEquals(name) && !values.isEmpty {
                return values[0]
            }
        }
        return nil
    }
}

extension String {
    /// Java String.equalsIgnoreCase.
    func caseInsensitiveEquals(_ other: String) -> Bool {
        self.lowercased() == other.lowercased()
    }
}
