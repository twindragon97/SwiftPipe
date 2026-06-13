import Foundation
import SwiftPipeExtractor

@MainActor
final class SearchViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded([SearchResultItem])
        case empty
        case error(String)
    }

    @Published private(set) var state: State = .idle

    private var currentTask: Task<Void, Never>?

    func search(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        currentTask?.cancel()
        guard !trimmed.isEmpty else {
            state = .idle
            return
        }
        state = .loading

        currentTask = Task { [weak self] in
            let result = await Self.runSearch(trimmed)
            guard let self, !Task.isCancelled else { return }
            switch result {
            case .success(let items):
                self.state = items.isEmpty ? .empty : .loaded(items)
            case .failure(let error):
                self.state = .error(error.message)
            }
        }
    }

    /// Runs the synchronous, blocking extractor off the main thread and maps
    /// the (non-Sendable) StreamInfoItems into Sendable result items.
    private static func runSearch(
        _ query: String
    ) async -> Result<[SearchResultItem], AppError> {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let extractor = try ServiceList.YouTube.getSearchExtractor(query)
                    try extractor.fetchPage()
                    let items = try extractor.getInitialPage().getItems()
                    let mapped = items.compactMap { $0 as? StreamInfoItem }.map(Self.map)
                    continuation.resume(returning: .success(mapped))
                } catch {
                    continuation.resume(returning: .failure(AppError(error)))
                }
            }
        }
    }

    private static func map(_ item: StreamInfoItem) -> SearchResultItem {
        let thumbnailURL = item.getThumbnails().last.flatMap { URL(string: $0.getUrl()) }
        return SearchResultItem(
            id: item.getUrl(),
            title: item.getName(),
            uploader: item.getUploaderName() ?? "",
            durationText: DurationFormatter.string(fromSeconds: item.getDuration()),
            thumbnailURL: thumbnailURL)
    }
}
