import SwiftUI

struct SubscriptionsView: View {
    @StateObject private var viewModel = SubscriptionsViewModel()

    var body: some View {
        content
            .navigationTitle("Subscriptions")
            .onAppear { viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            LibraryPlaceholder(
                title: "No subscriptions",
                systemImage: "person.2",
                description: "Import a NewPipe backup to bring your subscriptions over.")
        case .error(let message):
            LibraryPlaceholder(
                title: "Couldn't load subscriptions",
                systemImage: "exclamationmark.triangle",
                description: message)
        case .loaded(let rows):
            List(rows) { row in
                HStack(spacing: 12) {
                    AsyncImage(url: row.avatarURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundStyle(.quaternary)
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())

                    Text(row.name)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 2)
            }
            .listStyle(.plain)
            .refreshable { viewModel.load() }
        }
    }
}

/// Shared empty/error placeholder for the library screens.
struct LibraryPlaceholder: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
