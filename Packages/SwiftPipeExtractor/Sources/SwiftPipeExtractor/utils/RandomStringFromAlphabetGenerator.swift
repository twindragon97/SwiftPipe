// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/utils/RandomStringFromAlphabetGenerator.java @ v0.26.3
//
// java.util.Random maps to Swift's RandomNumberGenerator, taken as an `any`
// existential so YoutubeParsingHelper.setNumberGenerator can swap it.
//
// Deviation: index selection uses random.next() % alphabet.count rather than
// java.util.Random.nextInt, so a seeded generator does NOT reproduce Java's
// exact sequence. This only affects reproducibility of seeded-test nonces in
// player requests; faithful java.util.Random reproduction is deferred to the
// player-request port.

public enum RandomStringFromAlphabetGenerator {
    /// Generate a random string of the requested length made of only
    /// characters from the provided alphabet.
    public static func generate(
        _ alphabet: String,
        _ length: Int,
        _ random: inout any RandomNumberGenerator
    ) -> String {
        let characters = Array(alphabet)
        var result = ""
        for _ in 0..<length {
            let index = Int(random.next() % UInt64(characters.count))
            result.append(characters[index])
        }
        return result
    }
}
