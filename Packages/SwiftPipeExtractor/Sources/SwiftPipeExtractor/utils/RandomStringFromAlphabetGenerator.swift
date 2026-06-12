// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/utils/RandomStringFromAlphabetGenerator.java @ v0.26.3
//
// java.util.Random maps to Swift's RandomNumberGenerator (inout).

public enum RandomStringFromAlphabetGenerator {
    /// Generate a random string of the requested length made of only
    /// characters from the provided alphabet.
    public static func generate(
        _ alphabet: String,
        _ length: Int,
        _ random: inout some RandomNumberGenerator
    ) -> String {
        let characters = Array(alphabet)
        var result = ""
        for _ in 0..<length {
            result.append(characters[Int.random(in: 0..<characters.count, using: &random)])
        }
        return result
    }
}
