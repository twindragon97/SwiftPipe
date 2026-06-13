import SwiftUI

/// Root of the app: a native tab bar (iPhone and iPad both show tabs for now;
/// the iPad sidebar layout arrives in a later phase). Each tab owns its own
/// NavigationStack so navigation state is independent.
struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
        }
    }
}

#Preview {
    ContentView()
}
