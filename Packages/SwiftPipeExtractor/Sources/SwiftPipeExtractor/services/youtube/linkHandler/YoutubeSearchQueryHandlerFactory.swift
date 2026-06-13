// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/linkHandler/YoutubeSearchQueryHandlerFactory.java @ v0.26.3

public final class YoutubeSearchQueryHandlerFactory: SearchQueryHandlerFactory {
    private static let INSTANCE = YoutubeSearchQueryHandlerFactory()

    public static let ALL = "all"
    public static let VIDEOS = "videos"
    public static let CHANNELS = "channels"
    public static let PLAYLISTS = "playlists"
    public static let MUSIC_SONGS = "music_songs"
    public static let MUSIC_VIDEOS = "music_videos"
    public static let MUSIC_ALBUMS = "music_albums"
    public static let MUSIC_PLAYLISTS = "music_playlists"
    public static let MUSIC_ARTISTS = "music_artists"

    private static let SEARCH_URL = "https://www.youtube.com/results?search_query="
    private static let MUSIC_SEARCH_URL = "https://music.youtube.com/search?q="

    public static func getInstance() -> YoutubeSearchQueryHandlerFactory {
        INSTANCE
    }

    public override func getUrl(
        _ searchString: String, _ contentFilters: [String], _ sortFilter: String
    ) throws -> String {
        let contentFilter = !contentFilters.isEmpty ? contentFilters[0] : ""
        switch contentFilter {
        case Self.VIDEOS:
            return Self.SEARCH_URL + Utils.encodeUrlUtf8(searchString) + "&sp=EgIQAfABAQ%253D%253D"
        case Self.CHANNELS:
            return Self.SEARCH_URL + Utils.encodeUrlUtf8(searchString) + "&sp=EgIQAvABAQ%253D%253D"
        case Self.PLAYLISTS:
            return Self.SEARCH_URL + Utils.encodeUrlUtf8(searchString) + "&sp=EgIQA_ABAQ%253D%253D"
        case Self.MUSIC_SONGS, Self.MUSIC_VIDEOS, Self.MUSIC_ALBUMS,
             Self.MUSIC_PLAYLISTS, Self.MUSIC_ARTISTS:
            return Self.MUSIC_SEARCH_URL + Utils.encodeUrlUtf8(searchString)
        default:
            return Self.SEARCH_URL + Utils.encodeUrlUtf8(searchString) + "&sp=8AEB"
        }
    }

    public override func getAvailableContentFilter() -> [String] {
        [
            Self.ALL,
            Self.VIDEOS,
            Self.CHANNELS,
            Self.PLAYLISTS,
            Self.MUSIC_SONGS,
            Self.MUSIC_VIDEOS,
            Self.MUSIC_ALBUMS,
            Self.MUSIC_PLAYLISTS,
            // MUSIC_ARTISTS
        ]
    }

    public static func getSearchParameter(_ contentFilter: String?) -> String {
        if Utils.isNullOrEmpty(contentFilter) {
            return "8AEB"
        }
        switch contentFilter! {
        case VIDEOS:
            return "EgIQAfABAQ%3D%3D"
        case CHANNELS:
            return "EgIQAvABAQ%3D%3D"
        case PLAYLISTS:
            return "EgIQA_ABAQ%3D%3D"
        case MUSIC_SONGS, MUSIC_VIDEOS, MUSIC_ALBUMS, MUSIC_PLAYLISTS, MUSIC_ARTISTS:
            return ""
        default:
            return "8AEB"
        }
    }
}
