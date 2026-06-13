import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var query = ""

    var body: some View {
        content
            .navigationTitle("SwiftPipe")
            .searchable(text: $query, prompt: "Search YouTube")
            .onSubmit(of: .search) {
                viewModel.search(query)
            }
            .onChange(of: query) { newValue in
                if newValue.isEmpty {
                    viewModel.search("")
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableCompat(
                title: "Search YouTube",
                systemImage: "magnifyingglass",
                description: "Type a query and press Search.")
        case .loading:
            ProgressView("Searching…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            ContentUnavailableCompat(
                title: "No results",
                systemImage: "questionmark.circle",
                description: "Try a different query.")
        case .error(let message):
            ContentUnavailableCompat(
                title: "Something went wrong",
                systemImage: "exclamationmark.triangle",
                description: message)
        case .loaded(let items):
            List(Array(items.enumerated()), id: \.element.id) { offset, item in
                NavigationLink(value: PlaybackRequest(items: items, index: offset)) {
                    SearchResultRow(item: item)
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: PlaybackRequest.self) { request in
                VideoPlayerView(request: request)
            }
        }
    }
}

private struct SearchResultRow: View {
    let item: SearchResultItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: item.thumbnailURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(.quaternary)
                }
                .frame(width: 160, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if !item.durationText.isEmpty {
                    Text(item.durationText)
                        .font(.caption2.monospacedDigit())
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.black.opacity(0.75))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                Text(item.uploader)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

/// A small backport of ContentUnavailableView for iOS 16.
private struct ContentUnavailableCompat: View {
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
