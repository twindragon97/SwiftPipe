import SwiftUI

struct PlaylistsView: View {
    @StateObject private var viewModel = PlaylistsViewModel()

    var body: some View {
        content
            .navigationTitle("Playlists")
            .onAppear { viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            LibraryPlaceholder(
                title: "No playlists",
                systemImage: "music.note.list",
                description: "Local playlists you create or import appear here.")
        case .error(let message):
            LibraryPlaceholder(
                title: "Couldn't load playlists",
                systemImage: "exclamationmark.triangle",
                description: message)
        case .loaded(let rows):
            List(rows) { row in
                NavigationLink {
                    PlaylistDetailView(playlistId: row.id, title: row.name)
                } label: {
                    HStack(spacing: 12) {
                        AsyncImage(url: row.thumbnailURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(.quaternary)
                        }
                        .frame(width: 80, height: 45)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.name)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                            Text(row.streamCount == 1 ? "1 video" : "\(row.streamCount) videos")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(.plain)
            .refreshable { viewModel.load() }
        }
    }
}

struct PlaylistDetailView: View {
    @StateObject private var viewModel: PlaylistDetailViewModel
    let title: String

    init(playlistId: Int64, title: String) {
        _viewModel = StateObject(wrappedValue: PlaylistDetailViewModel(playlistId: playlistId))
        self.title = title
    }

    var body: some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            LibraryPlaceholder(
                title: "Empty playlist",
                systemImage: "music.note.list",
                description: "This playlist has no videos.")
        case .error(let message):
            LibraryPlaceholder(
                title: "Couldn't load playlist",
                systemImage: "exclamationmark.triangle",
                description: message)
        case .loaded(let items):
            List(Array(items.enumerated()), id: \.element.id) { offset, item in
                NavigationLink {
                    VideoPlayerView(request: PlaybackRequest(items: items, index: offset))
                } label: {
                    PlaylistStreamRow(item: item)
                }
            }
            .listStyle(.plain)
        }
    }
}

private struct PlaylistStreamRow: View {
    let item: SearchResultItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: item.thumbnailURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(.quaternary)
                }
                .frame(width: 120, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 6))

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
