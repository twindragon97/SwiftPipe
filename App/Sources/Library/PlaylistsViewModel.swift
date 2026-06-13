import Foundation

/// A local playlist for the list screen.
struct PlaylistRow: Identifiable, Sendable, Hashable {
    let id: Int64
    let name: String
    let thumbnailURL: URL?
    let streamCount: Int64
}

@MainActor
final class PlaylistsViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case empty
        case loaded([PlaylistRow])
        case error(String)
    }

    @Published private(set) var state: State = .loading

    func load() {
        Task { [weak self] in
            let result = await Self.fetch()
            guard let self else { return }
            switch result {
            case .success(let rows):
                self.state = rows.isEmpty ? .empty : .loaded(rows)
            case .failure(let error):
                self.state = .error(error.message)
            }
        }
    }

    private static func fetch() async -> Result<[PlaylistRow], AppError> {
        await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                do {
                    let metas = try Library.shared.playlists.getPlaylists()
                    let rows = metas.map { meta in
                        PlaylistRow(
                            id: meta.uid,
                            name: meta.orderingName ?? "(unnamed)",
                            thumbnailURL: meta.thumbnailUrl.flatMap { URL(string: $0) },
                            streamCount: meta.streamCount)
                    }
                    continuation.resume(returning: .success(rows))
                } catch {
                    continuation.resume(returning: .failure(AppError(error)))
                }
            }
        }
    }
}

@MainActor
final class PlaylistDetailViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case empty
        case loaded([SearchResultItem])
        case error(String)
    }

    @Published private(set) var state: State = .loading

    let playlistId: Int64

    init(playlistId: Int64) {
        self.playlistId = playlistId
    }

    var items: [SearchResultItem] {
        if case .loaded(let items) = state { return items }
        return []
    }

    func load() {
        Task { [weak self] in
            guard let self else { return }
            let result = await Self.fetch(playlistId: self.playlistId)
            switch result {
            case .success(let items):
                self.state = items.isEmpty ? .empty : .loaded(items)
            case .failure(let error):
                self.state = .error(error.message)
            }
        }
    }

    private static func fetch(playlistId: Int64) async -> Result<[SearchResultItem], AppError> {
        await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                do {
                    let entries = try Library.shared.playlists.getPlaylistStreams(playlistId: playlistId)
                    let items = entries.map { entry -> SearchResultItem in
                        let e = entry.streamEntity
                        return SearchResultItem(
                            id: e.url,
                            serviceId: e.serviceId,
                            title: e.title,
                            uploader: e.uploader,
                            durationSeconds: e.duration,
                            durationText: DurationFormatter.string(fromSeconds: e.duration),
                            thumbnailURL: e.thumbnailUrl.flatMap { URL(string: $0) },
                            streamType: e.streamType)
                    }
                    continuation.resume(returning: .success(items))
                } catch {
                    continuation.resume(returning: .failure(AppError(error)))
                }
            }
        }
    }
}
