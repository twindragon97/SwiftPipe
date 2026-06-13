import Foundation

/// Navigation value handed to the player: the full queue of results plus the
/// index that was tapped, so the player can autoplay through the list.
struct PlaybackRequest: Hashable {
    let items: [SearchResultItem]
    let index: Int
}
