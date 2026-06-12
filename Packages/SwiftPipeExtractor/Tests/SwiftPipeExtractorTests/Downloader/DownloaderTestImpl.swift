// Mirrors: extractor/src/test/java/org/schabi/newpipe/downloader/DownloaderTestImpl.java @ v0.26.3
//
// Java uses OkHttp with a rate-limiting wrapper; this port uses URLSession
// with a synchronous wait (the Downloader API is synchronous). The rate
// limiter is not ported yet (deviation; only affects REAL/RECORDING runs).

import Foundation
import SwiftPipeExtractor
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class DownloaderTestImpl: Downloader {
    /// Should be the latest Firefox ESR version.
    private static let USER_AGENT =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0"

    private static var instance: DownloaderTestImpl?

    private let session: URLSession

    private init(session: URLSession) {
        self.session = session
        super.init()
    }

    static func getInstance() -> DownloaderTestImpl {
        if let instance {
            return instance
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        let created = DownloaderTestImpl(session: URLSession(configuration: configuration))
        instance = created
        return created
    }

    override func execute(_ request: Request) throws -> Response {
        guard let url = URL(string: request.url) else {
            throw MockDownloaderError(description: "Invalid URL: \(request.url)")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.httpMethod
        urlRequest.httpBody = request.dataToSend
        urlRequest.setValue(Self.USER_AGENT, forHTTPHeaderField: "User-Agent")
        for (headerName, headerValueList) in request.headers {
            urlRequest.setValue(nil, forHTTPHeaderField: headerName)
            for headerValue in headerValueList {
                urlRequest.addValue(headerValue, forHTTPHeaderField: headerName)
            }
        }

        // The Downloader API is synchronous; block on the data task.
        let semaphore = DispatchSemaphore(value: 0)
        var resultData: Data?
        var resultResponse: URLResponse?
        var resultError: Error?
        session.dataTask(with: urlRequest) { data, response, error in
            resultData = data
            resultResponse = response
            resultError = error
            semaphore.signal()
        }.resume()
        semaphore.wait()

        if let resultError {
            throw resultError
        }
        guard let http = resultResponse as? HTTPURLResponse else {
            throw MockDownloaderError(description: "No HTTP response for \(request.url)")
        }

        if http.statusCode == 429 {
            throw ReCaptchaException("reCaptcha Challenge requested", request.url)
        }

        // Header values that repeat are joined by HTTPURLResponse; split is
        // not attempted (deviation, acceptable for tests).
        var responseHeaders: [String: [String]] = [:]
        for (key, value) in http.allHeaderFields {
            if let name = key as? String {
                responseHeaders[name] = [String(describing: value)]
            }
        }

        let body = resultData.map { String(decoding: $0, as: UTF8.self) }
        return Response(
            http.statusCode,
            "",
            responseHeaders,
            body,
            http.url?.absoluteString ?? request.url)
    }
}
