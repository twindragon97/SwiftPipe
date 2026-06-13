import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        content
            .navigationTitle("History")
            .toolbar {
                if case .loaded = viewModel.state {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive) {
                            viewModel.clearAll()
                        } label: {
                            Label("Clear", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationDestination(for: PlaybackRequest.self) { request in
                VideoPlayerView(request: request)
            }
            .onAppear { viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            HistoryPlaceholder(
                title: "No history yet",
                systemImage: "clock.arrow.circlepath",
                description: "Videos you watch show up here.")
        case .error(let message):
            HistoryPlaceholder(
                title: "Couldn't load history",
                systemImage: "exclamationmark.triangle",
                description: message)
        case .loaded(let rows):
            List(Array(rows.enumerated()), id: \.element.id) { offset, row in
                NavigationLink(value: PlaybackRequest(items: viewModel.items, index: offset)) {
                    HistoryRowView(row: row)
                }
            }
            .listStyle(.plain)
            .refreshable { viewModel.load() }
        }
    }
}

private struct HistoryRowView: View {
    let row: HistoryRow

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: row.item.thumbnailURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(.quaternary)
                }
                .frame(width: 160, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if !row.item.durationText.isEmpty {
                    Text(row.item.durationText)
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
                Text(row.item.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                Text(row.item.uploader)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(row.lastWatched, format: .relative(presentation: .named))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

private struct HistoryPlaceholder: View {
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
