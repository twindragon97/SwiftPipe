import SwiftUI

/// Root of the app. Compact width (iPhone) and regular width (iPad) both use a
/// NavigationStack around the search screen for now; the iPad sidebar layout
/// arrives with the full tab set in a later phase.
struct ContentView: View {
    var body: some View {
        NavigationStack {
            SearchView()
        }
    }
}

#Preview {
    ContentView()
}
