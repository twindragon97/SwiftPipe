import SwiftUI
import AVKit
import SwiftPipeExtractor

/// Plays a queue of results: native AVPlayerViewController (PiP + controls),
/// autoplay to the next result, lock-screen / Control Center integration.
struct VideoPlayerView: View {
    let request: PlaybackRequest

    @StateObject private var model = QueuePlayerModel()

    private var qualityBinding: Binding<StreamQuality> {
        Binding(get: { model.quality }, set: { model.setQuality($0) })
    }

    var body: some View {
        Group {
            switch model.state {
            case .error(let message):
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Could not load video").font(.headline)
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            default:
                ZStack {
                    SystemVideoPlayer(player: model.player)
                        .aspectRatio(16.0 / 9.0, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                    if model.state == .loading {
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .navigationTitle(model.currentTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Quality", selection: qualityBinding) {
                        ForEach(StreamQuality.allCases) { quality in
                            Text(quality.label).tag(quality)
                        }
                    }
                } label: {
                    Label("Quality", systemImage: "slider.horizontal.3")
                }
            }
        }
        .onAppear { model.start(request) }
        // No onDisappear teardown: it also fires when AVPlayerViewController
        // covers this view with its fullscreen presentation. Cleanup happens
        // in QueuePlayerModel.deinit (real pop only).
    }
}
