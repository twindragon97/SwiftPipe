// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/utils/JsonUtils.java @ v0.26.3
//
// Java's Class<T>-based getInstanceOf collapses into per-type helpers.

import NanoJSON
import SwiftSoup

public enum JsonUtils {
    public static func getValue(
        _ object: JsonObject, _ path: String
    ) throws -> Any {
        let keys = path.components(separatedBy: ".")
        let parentObject = getObject(object, Array(keys.dropLast()))
        guard let result = parentObject.get(keys[keys.count - 1]) else {
            throw ParsingException("Unable to get \(path)")
        }
        return result
    }

    public static func getString(
        _ object: JsonObject, _ path: String
    ) throws -> String {
        guard let value = try getValue(object, path) as? String else {
            throw ParsingException("Wrong data type at path \(path)")
        }
        return value
    }

    public static func getBoolean(
        _ object: JsonObject, _ path: String
    ) throws -> Bool {
        guard let value = try getValue(object, path) as? Bool else {
            throw ParsingException("Wrong data type at path \(path)")
        }
        return value
    }

    /// Returns the numeric value at the path (Java returns Number).
    public static func getNumber(
        _ object: JsonObject, _ path: String
    ) throws -> Any {
        let value = try getValue(object, path)
        switch value {
        case is Int, is Int64, is Int32, is Double, is Float:
            return value
        default:
            throw ParsingException("Wrong data type at path \(path)")
        }
    }

    public static func getObject(
        _ object: JsonObject, _ path: String
    ) throws -> JsonObject {
        guard let value = try getValue(object, path) as? JsonObject else {
            throw ParsingException("Wrong data type at path \(path)")
        }
        return value
    }

    public static func getArray(
        _ object: JsonObject, _ path: String
    ) throws -> JsonArray {
        guard let value = try getValue(object, path) as? JsonArray else {
            throw ParsingException("Wrong data type at path \(path)")
        }
        return value
    }

    public static func getValues(
        _ array: JsonArray, _ path: String
    ) throws -> [Any] {
        var result: [Any] = []
        for i in 0..<array.count {
            result.append(try getValue(array.getObject(i), path))
        }
        return result
    }

    private static func getObject(
        _ object: JsonObject, _ keys: [String]
    ) -> JsonObject {
        var result = object
        for key in keys {
            result = result.getObject(key)
        }
        return result
    }

    public static func toJsonArray(_ responseBody: String) throws -> JsonArray {
        do {
            return try JsonParser.array().from(responseBody)
        } catch let e as JsonParserException {
            throw ParsingException("Could not parse JSON", e)
        }
    }

    public static func toJsonObject(_ responseBody: String) throws -> JsonObject {
        do {
            return try JsonParser.object().from(responseBody)
        } catch let e as JsonParserException {
            throw ParsingException("Could not parse JSON", e)
        }
    }

    /// Get an attribute of a web page as JSON: returns the JsonObject stored
    /// in the HTML attribute with the given name.
    public static func getJsonData(
        _ html: String, _ variable: String
    ) throws -> JsonObject {
        let document = try SwiftSoup.parse(html)
        let json = try document.getElementsByAttribute(variable).attr(variable)
        return try JsonParser.object().from(json)
    }

    public static func getStringListFromJsonArray(_ array: JsonArray) -> [String] {
        array.compactMap { $0 as? String }
    }
}
