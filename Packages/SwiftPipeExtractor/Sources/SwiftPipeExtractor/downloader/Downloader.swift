// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/downloader/Downloader.java @ v0.26.3
//
// Java's abstract class maps to an open class whose execute() must be
// overridden. The Java overload set is preserved positionally so mirrored
// call sites stay identical. byte[] maps to Data.

import Foundation

/// A base for downloader implementations that NewPipe will use to download
/// needed resources during extraction.
open class Downloader {
    public init() {}

    /// Do a GET request to get the resource that the url is pointing to,
    /// with the default preferred localization.
    public func get(_ url: String) throws -> Response {
        try get(url, nil, NewPipe.getPreferredLocalization())
    }

    /// Do a GET request, setting the Accept-Language header to the language
    /// of the localization parameter.
    public func get(_ url: String, _ localization: Localization) throws -> Response {
        try get(url, nil, localization)
    }

    /// Do a GET request with the specified headers.
    public func get(_ url: String, _ headers: [String: [String]]?) throws -> Response {
        try get(url, headers, NewPipe.getPreferredLocalization())
    }

    /// Do a GET request with the specified headers and localization.
    public func get(
        _ url: String,
        _ headers: [String: [String]]?,
        _ localization: Localization
    ) throws -> Response {
        try execute(
            Request.newBuilder()
                .get(url)
                .headers(headers)
                .localization(localization)
                .build())
    }

    /// Do a HEAD request.
    public func head(_ url: String) throws -> Response {
        try head(url, nil)
    }

    /// Do a HEAD request with the specified headers.
    public func head(_ url: String, _ headers: [String: [String]]?) throws -> Response {
        try execute(
            Request.newBuilder()
                .head(url)
                .headers(headers)
                .build())
    }

    /// Do a POST request with the specified headers, sending the data array.
    public func post(
        _ url: String,
        _ headers: [String: [String]]?,
        _ dataToSend: Data?
    ) throws -> Response {
        try post(url, headers, dataToSend, NewPipe.getPreferredLocalization())
    }

    /// Do a POST request with the specified headers, sending the data array,
    /// with the given localization.
    public func post(
        _ url: String,
        _ headers: [String: [String]]?,
        _ dataToSend: Data?,
        _ localization: Localization
    ) throws -> Response {
        try execute(
            Request.newBuilder()
                .post(url, dataToSend)
                .headers(headers)
                .localization(localization)
                .build())
    }

    /// Convenient method to send a POST request using the specified value of
    /// the Content-Type header with a given localization.
    public func postWithContentType(
        _ url: String,
        _ headers: [String: [String]]?,
        _ dataToSend: Data?,
        _ localization: Localization,
        _ contentType: String
    ) throws -> Response {
        var actualHeaders = headers ?? [:]
        actualHeaders["Content-Type"] = [contentType]
        return try post(url, actualHeaders, dataToSend, localization)
    }

    /// Convenient method to send a POST request using the specified value of
    /// the Content-Type header.
    public func postWithContentType(
        _ url: String,
        _ headers: [String: [String]]?,
        _ dataToSend: Data?,
        _ contentType: String
    ) throws -> Response {
        try postWithContentType(
            url, headers, dataToSend, NewPipe.getPreferredLocalization(), contentType)
    }

    /// Convenient method to send a POST request with the JSON mime type as
    /// the value of the Content-Type header, with a given localization.
    public func postWithContentTypeJson(
        _ url: String,
        _ headers: [String: [String]]?,
        _ dataToSend: Data?,
        _ localization: Localization
    ) throws -> Response {
        try postWithContentType(url, headers, dataToSend, localization, "application/json")
    }

    /// Convenient method to send a POST request with the JSON mime type as
    /// the value of the Content-Type header.
    public func postWithContentTypeJson(
        _ url: String,
        _ headers: [String: [String]]?,
        _ dataToSend: Data?
    ) throws -> Response {
        try postWithContentTypeJson(
            url, headers, dataToSend, NewPipe.getPreferredLocalization())
    }

    /// Do a request using the specified Request object. Must be overridden
    /// (Java: abstract method).
    open func execute(_ request: Request) throws -> Response {
        preconditionFailure("Downloader.execute must be overridden")
    }
}
