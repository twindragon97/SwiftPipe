import Foundation

/// A subscribed channel for display (list-only for now; opening the channel
/// needs the YouTube channel extractor, which isn't ported yet).
struct SubscriptionRow: Identifiable, Sendable, Hashable {
    let id: Int64
    let name: String
    let avatarURL: URL?
}

@MainActor
final class SubscriptionsViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case empty
        case loaded([SubscriptionRow])
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

    private static func fetch() async -> Result<[SubscriptionRow], AppError> {
        await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                do {
                    let entities = try Library.shared.database.subscriptionDAO.getAll()
                    let rows = entities.map { entity in
                        SubscriptionRow(
                            id: entity.uid,
                            name: entity.name ?? "(unnamed)",
                            avatarURL: entity.avatarUrl.flatMap { URL(string: $0) })
                    }
                    continuation.resume(returning: .success(rows))
                } catch {
                    continuation.resume(returning: .failure(AppError(error)))
                }
            }
        }
    }
}
