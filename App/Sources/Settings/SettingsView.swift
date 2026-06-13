import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @State private var shareItem: ShareItem?
    @State private var showImporter = false
    @State private var alertInfo: AlertInfo?
    @State private var isWorking = false

    var body: some View {
        List {
            Section("Backup & restore") {
                Button {
                    exportBackup()
                } label: {
                    Label("Export backup…", systemImage: "square.and.arrow.up")
                }
                Button {
                    showImporter = true
                } label: {
                    Label("Import backup…", systemImage: "square.and.arrow.down")
                }
            }

            Section {
                Text("Backups are NewPipeData .zip files containing your subscriptions, history and playlists — compatible with NewPipe for Android.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .disabled(isWorking)
        .overlay {
            if isWorking {
                ProgressView().controlSize(.large)
            }
        }
        .sheet(item: $shareItem) { item in
            ActivityView(items: [item.url])
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert(item: $alertInfo) { info in
            Alert(
                title: Text(info.title),
                message: Text(info.message),
                dismissButton: .default(Text("OK")))
        }
    }

    private func exportBackup() {
        isWorking = true
        Task {
            let outcome = await Task.detached { () -> Result<URL, String> in
                do {
                    let name = "NewPipeData-\(Int(Date().timeIntervalSince1970)).zip"
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
                    try Library.shared.exportBackup(to: url)
                    return .success(url)
                } catch {
                    return .failure(String(describing: error))
                }
            }.value
            isWorking = false
            switch outcome {
            case .success(let url):
                shareItem = ShareItem(url: url)
            case .failure(let message):
                alertInfo = AlertInfo(title: "Export failed", message: message)
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else {
            if case .failure(let error) = result {
                alertInfo = AlertInfo(title: "Import failed", message: error.localizedDescription)
            }
            return
        }
        isWorking = true
        Task {
            let outcome = await Task.detached { () -> Result<String, String> in
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                do {
                    let imported = try Library.shared.importBackup(from: url)
                    let note = imported.isSchemaV9 ? "" : " (schema v\(imported.userVersion))"
                    return .success("Your library was restored from the backup\(note).")
                } catch {
                    return .failure(String(describing: error))
                }
            }.value
            isWorking = false
            switch outcome {
            case .success(let message):
                alertInfo = AlertInfo(title: "Import complete", message: message)
            case .failure(let message):
                alertInfo = AlertInfo(title: "Import failed", message: message)
            }
        }
    }
}

private struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct AlertInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
