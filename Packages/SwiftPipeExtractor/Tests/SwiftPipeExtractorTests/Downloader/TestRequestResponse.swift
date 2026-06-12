// Mirrors: extractor/src/test/java/org/schabi/newpipe/downloader/TestRequestResponse.java @ v0.26.3
//
// Java serializes Request/Response directly with Gson (reflection over
// private fields). Swift bridges through Codable DTOs that match the recorded
// JSON exactly: Gson writes byte[] as an array of SIGNED bytes, and Gson's
// reflective deserialization bypasses the Request constructor — so the DTO
// rebuilds the Request with automaticLocalizationHeader=false to keep the
// recorded headers exactly as they were captured.

import Foundation
import SwiftPipeExtractor

struct TestRequestResponse: Codable {
    let request: RequestDTO
    let response: ResponseDTO

    struct LocalizationDTO: Codable {
        let languageCode: String
        let countryCode: String?

        init(_ localization: Localization) {
            languageCode = localization.getLanguageCode()
            let country = localization.getCountryCode()
            countryCode = country.isEmpty ? nil : country
        }

        func toLocalization() -> Localization {
            Localization(languageCode, countryCode)
        }
    }

    struct RequestDTO: Codable {
        let httpMethod: String
        let url: String
        let headers: [String: [String]]?
        let dataToSend: [Int8]?
        let localization: LocalizationDTO?

        init(_ request: Request) {
            httpMethod = request.httpMethod
            url = request.url
            headers = request.headers
            dataToSend = request.dataToSend.map { data in
                data.map { Int8(bitPattern: $0) }
            }
            localization = request.localization.map(LocalizationDTO.init)
        }

        func toRequest() -> Request {
            Request(
                httpMethod,
                url,
                headers,
                dataToSend.map { bytes in Data(bytes.map { UInt8(bitPattern: $0) }) },
                localization?.toLocalization(),
                false  // headers were recorded post-construction; do not re-add
            )
        }
    }

    struct ResponseDTO: Codable {
        let responseCode: Int
        let responseMessage: String?
        let responseHeaders: [String: [String]]?
        let responseBody: String?
        let latestUrl: String?

        init(_ response: Response) {
            responseCode = response.responseCode
            responseMessage = response.responseMessage
            responseHeaders = response.responseHeaders
            responseBody = response.responseBody
            latestUrl = response.latestUrl
        }

        func toResponse() -> Response {
            Response(
                responseCode,
                responseMessage ?? "",
                responseHeaders,
                responseBody,
                latestUrl)
        }
    }

    init(request: Request, response: Response) {
        self.request = RequestDTO(request)
        self.response = ResponseDTO(response)
    }
}
