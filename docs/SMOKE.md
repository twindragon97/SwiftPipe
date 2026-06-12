# Release smoke checklist (~10 min on device)

Run on a real device installed via AltStore before tagging a release.
Items marked with a phase are N/A until that phase lands.

## Core (P2+)
- [ ] Cold launch shows the app without crashing
- [ ] Search "lofi" → results appear, suggestions while typing (P6)
- [ ] Open a video → HLS playback starts, seeking works
- [ ] Quality selection changes resolution (P5)
- [ ] Captions can be enabled (P5)

## Player (P5+)
- [ ] Background the app → audio keeps playing; lock-screen/Control Center controls work
- [ ] PiP enters automatically when swiping home, restores into the app
- [ ] Queue: add-as-next, reorder, repeat-one, shuffle
- [ ] Playback speed change persists across videos
- [ ] Resume: close mid-video, reopen → position restored (5 s / quarter rule)
- [ ] Live stream plays, seek UI hidden

## Library & data (P4+)
- [ ] Subscribe to a channel → appears in Subscriptions; unsubscribe works
- [ ] Watch history records views; search history records queries
- [ ] Local playlist: create, add, reorder, delete
- [ ] Import a real Android `NewPipeData-*.zip` → subscriptions/history/playlists appear (P8)
- [ ] Export → restore on Android NewPipe → Android opens it without errors (P8, release-blocking)
- [ ] Subscriptions-only import: NewPipe JSON, OPML, YouTube takeout (P8)

## Downloads (P7+)
- [ ] Download video (DASH video+audio) → progress, pause, resume
- [ ] Kill the app mid-download → relaunch → mission resumes
- [ ] Finished MP4 is muxed correctly, plays in-app and appears in the Files app
- [ ] Audio-only download (M4A) plays

## Routing (P9+)
- [ ] Share a youtube.com link from Safari → opens in SwiftPipe
- [ ] `swiftpipe://` URL opens the app

## iPad (every release)
- [ ] Sidebar navigation in regular width; tabs in compact
- [ ] Video grid in regular width
- [ ] Video detail shows side panel (related/comments) in landscape
- [ ] Split View next to another app: layout adapts, playback continues
- [ ] All four orientations rotate correctly
- [ ] Keyboard shortcuts: space (play/pause), arrows (seek)
