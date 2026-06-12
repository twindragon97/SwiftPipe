// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/downloader/Request.java @ v0.26.3
//
// Java accessor methods (url(), httpMethod(), ...) map to Swift properties
// per the porting conventions. byte[] maps to Data. Equality and hashing
// cover the same five fields as Java's equals/hashCode — the mock test
// harness depends on this (requests are dictionary keys).

import Foundation

/// An object that holds request information used when executing a request.
public final class Request: Hashable {
    /// A http method (i.e. GET, POST, HEAD).
    public let httpMethod: String
    /// The URL that is pointing to the wanted resource.
    public let url: String
    /// A list of headers that will be used in the request.
    /// Any default headers that the implementation may have should be
    /// overridden by these.
    public let headers: [String: [String]]
    /// An optional byte array that will be sent when doing the request, very
    /// commonly used in POST requests.
    public let dataToSend: Data?
    /// A localization object that should be used when executing a request.
    public let localization: Localization?

    public init(
        _ httpMethod: String,
        _ url: String,
        _ headers: [String: [String]]?,
        _ dataToSend: Data?,
        _ localization: Localization?,
        _ automaticLocalizationHeader: Bool
    ) {
        self.httpMethod = httpMethod
        self.url = url
        self.dataToSend = dataToSend
        self.localization = localization

        var actualHeaders = headers ?? [:]
        if automaticLocalizationHeader, let localization {
            actualHeaders.merge(
                Request.getHeadersFromLocalization(localization)
            ) { _, new in new }
        }
        self.headers = actualHeaders
    }

    public static func newBuilder() -> Builder {
        Builder()
    }

    public final class Builder {
        fileprivate var httpMethod: String?
        fileprivate var url: String?
        fileprivate var headers: [String: [String]] = [:]
        fileprivate var dataToSend: Data?
        fileprivate var localization: Localization?
        fileprivate var automaticLocalizationHeader = true

        public init() {}

        @discardableResult
        public func httpMethod(_ httpMethodToSet: String) -> Builder {
            self.httpMethod = httpMethodToSet
            return self
        }

        @discardableResult
        public func url(_ urlToSet: String) -> Builder {
            self.url = urlToSet
            return self
        }

        @discardableResult
        public func headers(_ headersToSet: [String: [String]]?) -> Builder {
            self.headers = headersToSet ?? [:]
            return self
        }

        @discardableResult
        public func dataToSend(_ dataToSendToSet: Data?) -> Builder {
            self.dataToSend = dataToSendToSet
            return self
        }

        @discardableResult
        public func localization(_ localizationToSet: Localization) -> Builder {
            self.localization = localizationToSet
            return self
        }

        /// If localization headers should automatically be included in the request.
        @discardableResult
        public func automaticLocalizationHeader(_ value: Bool) -> Builder {
            self.automaticLocalizationHeader = value
            return self
        }

        public func build() -> Request {
            guard let httpMethod else {
                preconditionFailure("Request's httpMethod is null")
            }
            guard let url else {
                preconditionFailure("Request's url is null")
            }
            return Request(
                httpMethod, url, headers, dataToSend, localization,
                automaticLocalizationHeader)
        }

        // MARK: Http Methods Utils

        @discardableResult
        public func get(_ urlToSet: String) -> Builder {
            self.httpMethod = "GET"
            self.url = urlToSet
            return self
        }

        @discardableResult
        public func head(_ urlToSet: String) -> Builder {
            self.httpMethod = "HEAD"
            self.url = urlToSet
            return self
        }

        @discardableResult
        public func post(_ urlToSet: String, _ dataToSendToSet: Data?) -> Builder {
            self.httpMethod = "POST"
            self.url = urlToSet
            self.dataToSend = dataToSendToSet
            return self
        }

        // MARK: Additional Headers Utils

        @discardableResult
        public func setHeaders(_ headerName: String, _ headerValueList: [String]) -> Builder {
            self.headers[headerName] = headerValueList
            return self
        }

        @discardableResult
        public func addHeaders(_ headerName: String, _ headerValueList: [String]) -> Builder {
            // Mirror of the Java logic (including its quirk of putting the
            // new list instead of the merged one).
            self.headers[headerName] = headerValueList
            return self
        }

        @discardableResult
        public func setHeader(_ headerName: String, _ headerValue: String) -> Builder {
            setHeaders(headerName, [headerValue])
        }

        @discardableResult
        public func addHeader(_ headerName: String, _ headerValue: String) -> Builder {
            addHeaders(headerName, [headerValue])
        }
    }

    // MARK: Utils

    public static func getHeadersFromLocalization(
        _ localization: Localization?
    ) -> [String: [String]] {
        guard let localization else { return [:] }

        let languageCode = localization.getLanguageCode()
        let languageCodeList = [
            localization.getCountryCode().isEmpty
                ? languageCode
                : localization.getLocalizationCode() + ", " + languageCode + ";q=0.9"
        ]
        return ["Accept-Language": languageCodeList]
    }

    // MARK: Generated

    public static func == (lhs: Request, rhs: Request) -> Bool {
        lhs.httpMethod == rhs.httpMethod
            && lhs.url == rhs.url
            && lhs.headers == rhs.headers
            && lhs.dataToSend == rhs.dataToSend
            && lhs.localization == rhs.localization
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(httpMethod)
        hasher.combine(url)
        hasher.combine(headers)
        hasher.combine(dataToSend)
        hasher.combine(localization)
    }
}
