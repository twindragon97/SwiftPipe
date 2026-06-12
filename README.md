# SwiftPipe

[![Build IPA](../../actions/workflows/build-ipa.yml/badge.svg)](../../actions/workflows/build-ipa.yml)
[![Tests](../../actions/workflows/tests.yml/badge.svg)](../../actions/workflows/tests.yml)

**SwiftPipe is an unofficial native iOS/iPadOS port of [NewPipe](https://github.com/TeamNewPipe/NewPipe)** — the libre, lightweight streaming front-end for Android. Same features, native SwiftUI look and feel, no Google services, no account, no tracking.

> SwiftPipe is not affiliated with TeamNewPipe. It is an independent port that
> mirrors their work. All credit for the extraction logic and the app design
> belongs to the [NewPipe](https://github.com/TeamNewPipe/NewPipe) and
> [NewPipeExtractor](https://github.com/TeamNewPipe/NewPipeExtractor) projects.

## How it works

- **`Packages/SwiftPipeExtractor`** is a 1:1 Swift mirror of NewPipeExtractor:
  same files, same class and method names. When upstream fixes a YouTube
  breakage, the same change is replicated in the mirrored Swift file. See
  [docs/PORTING.md](docs/PORTING.md).
- jsoup → [SwiftSoup](https://github.com/scinfu/SwiftSoup) · Rhino →
  JavaScriptCore · ExoPlayer → AVPlayer (HLS) · Room → GRDB with a
  **byte-compatible `newpipe.db` schema** — you can move your full backup
  (subscriptions, history, playlists) between NewPipe Android and SwiftPipe.
- Built entirely on GitHub Actions (no Mac required). Every build produces an
  **unsigned `.ipa`** for sideloading.

## Installing

SwiftPipe cannot be on the App Store. Install it with
[AltStore](https://altstore.io) (or SideStore):

1. Install AltServer on your PC/Mac and AltStore on your device.
2. Download `SwiftPipe-unsigned.ipa` from the latest
   [Release](../../releases) (or a CI artifact).
3. Open it with AltStore. It re-signs the app with your Apple ID.

With a free Apple ID the signature lasts **7 days** (AltStore refreshes it
automatically when AltServer is reachable) and at most 3 sideloaded apps.

## Status

Early development — Phase 0 (bootstrap). Roadmap: extractor core + YouTube →
player → database/app features → downloads with muxing → full backup
compatibility. Pinned upstream versions live in
[upstream-versions.json](upstream-versions.json).

## License

[GPL-3.0](LICENSE) — same as NewPipe, of which this is a derived work.
