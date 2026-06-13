import Foundation
import SwiftPipeExtractor
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// The app's Downloader implementation, mirroring NewPipe Android's
/// DownloaderImpl semantics (a desktop Firefox User-Agent, per-request header
/// overrides, 429 -> ReCaptchaException). The extractor's Downloader API is
/// synchronous, so each request blocks on a background thread via a semaphore.
final class DownloaderImpl: Downloader {
    /// Latest Firefox ESR User-Agent (matches the extractor's test downloader,
    /// which the recorded mocks were captured with).
    private static let userAgent =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0"

    static let shared = DownloaderImpl()

    private let session: URLSession

    private override init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.httpCookieStorage = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: configuration)
        super.init()
    }

    override func execute(_ request: Request) throws -> Response {
        guard let url = URL(string: request.url) else {
            throw ReCaptchaException("Invalid URL: \(request.url)", request.url)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.httpMethod
        urlRequest.httpBody = request.dataToSend
        urlRequest.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        for (headerName, headerValueList) in request.headers {
            urlRequest.setValue(nil, forHTTPHeaderField: headerName)
            for headerValue in headerValueList {
                urlRequest.addValue(headerValue, forHTTPHeaderField: headerName)
            }
        }

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
            throw ReCaptchaException("No HTTP response for \(request.url)", request.url)
        }

        if http.statusCode == 429 {
            throw ReCaptchaException("reCaptcha Challenge requested", request.url)
        }

        var responseHeaders: [String: [String]] = [:]
        for (key, value) in http.allHeaderFields {
            if let name = key as? String {
                responseHeaders[name, default: []].append(String(describing: value))
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
