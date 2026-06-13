import Foundation

/// A watched-video row: the data needed to replay it plus when it was last seen.
struct HistoryRow: Identifiable, Sendable, Hashable {
    let item: SearchResultItem
    let lastWatched: Date
    var id: String { item.id }
}

@MainActor
final class HistoryViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case empty
        case loaded([HistoryRow])
        case error(String)
    }

    @Published private(set) var state: State = .loading

    /// All items as a queue, so tapping a history row plays the rest after it.
    var items: [SearchResultItem] {
        if case .loaded(let rows) = state { return rows.map(\.item) }
        return []
    }

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

    func clearAll() {
        Task { [weak self] in
            await Self.clear()
            self?.load()
        }
    }

    private static func fetch() async -> Result<[HistoryRow], AppError> {
        await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                do {
                    let entries = try Library.shared.history.getStreamHistory()
                    let rows = entries.map { entry -> HistoryRow in
                        let e = entry.streamEntity
                        let item = SearchResultItem(
                            id: e.url,
                            serviceId: e.serviceId,
                            title: e.title,
                            uploader: e.uploader,
                            durationSeconds: e.duration,
                            durationText: DurationFormatter.string(fromSeconds: e.duration),
                            thumbnailURL: e.thumbnailUrl.flatMap { URL(string: $0) },
                            streamType: e.streamType)
                        return HistoryRow(item: item, lastWatched: entry.accessDate)
                    }
                    continuation.resume(returning: .success(rows))
                } catch {
                    continuation.resume(returning: .failure(AppError(error)))
                }
            }
        }
    }

    private static func clear() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task.detached(priority: .utility) {
                _ = try? Library.shared.history.deleteWholeStreamHistory()
                continuation.resume()
            }
        }
    }
}
