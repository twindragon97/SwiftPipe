// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/PoTokenProvider.java @ v0.26.3

public protocol PoTokenProvider {
    func getWebClientPoToken(_ videoId: String) -> PoTokenResult?
    func getWebEmbedClientPoToken(_ videoId: String) -> PoTokenResult?
    func getAndroidClientPoToken(_ videoId: String) -> PoTokenResult?
    func getIosClientPoToken(_ videoId: String) -> PoTokenResult?
}
