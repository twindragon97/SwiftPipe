import SwiftUI

/// Hub for the on-device library: subscriptions, local playlists and watch
/// history (mirrors NewPipe's bookmark/subscription/history sections).
struct LibraryView: View {
    var body: some View {
        List {
            NavigationLink {
                SubscriptionsView()
            } label: {
                Label("Subscriptions", systemImage: "person.2")
            }
            NavigationLink {
                PlaylistsView()
            } label: {
                Label("Playlists", systemImage: "music.note.list")
            }
            NavigationLink {
                HistoryView()
            } label: {
                Label("Watch history", systemImage: "clock.arrow.circlepath")
            }
        }
        .navigationTitle("Library")
    }
}
