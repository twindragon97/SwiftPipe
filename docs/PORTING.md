# Porting conventions (the mirror rules)

SwiftPipe's maintenance strategy is to **replicate upstream fixes mechanically**.
Everything in this document exists to keep that replication cheap.

## Pinned upstream versions

The authoritative pins live in [`upstream-versions.json`](../upstream-versions.json)
and as git submodules under `upstream/`. The `upstream-watch` workflow opens an
issue whenever TeamNewPipe publishes a new release.

## Mirror rules

1. **One Java file = one Swift file.** Same file name, same folder hierarchy,
   same type name, same method and constant names.
   `services/youtube/extractors/YoutubeStreamExtractor.java` →
   `services/youtube/extractors/YoutubeStreamExtractor.swift`.
2. **Every mirrored Swift file declares its origin** in a header line:

   ```swift
   // Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/services/youtube/YoutubeParsingHelper.java @ v0.26.3
   ```

   `scripts/port-status.py` parses these headers to report what is ported and
   which upstream changes require action.
3. **Library seams keep call sites identical:**
   - jsoup → SwiftSoup (API-compatible port; selectors and calls copy over).
   - nanojson → `NanoJSON` target: a faithful port, **not** a wrapper over
     `JSONSerialization`. JsonObject preserves key insertion order and
     JsonWriter output is byte-identical to Java — mock tests match recorded
     requests by exact POST body.
   - Rhino → `JavaScriptRunner` protocol (core) + `JavaScriptCoreRunner`
     (Apple-only target), injected at app startup.
   - `Downloader`/`Request`/`Response` → mirrored protocol; the app provides a
     URLSession implementation (mirror of Android's `DownloaderImpl`).
4. Checked exceptions → `throws` with mirrored error enums under `exceptions/`.
   `@Nullable` → optionals. Regex stays behind the mirrored `Parser.swift` so
   call sites look like the Java.
5. **Deviations must be documented** in the file header below the `Mirrors:`
   line with `// Deviation:` and one-line justification. Keep them rare.

## Tests

Mirrors of upstream's test classes run against the recorded mocks in
`Packages/SwiftPipeExtractor/Tests/SwiftPipeExtractorTests/Resources/mocks/v1`
(copied verbatim from upstream via `scripts/sync-mocks.sh`).

- `DOWNLOADER=MOCK` (CI default): deterministic, uses recorded responses.
- `DOWNLOADER=REAL`: live network (use locally to diagnose breakage).
- `DOWNLOADER=RECORDING`: wraps the real downloader and rewrites the mock
  files (run via the manual re-record workflow job, review the diff in a PR).

JS-dependent suites are guarded by `#if canImport(JavaScriptCore)` and only run
on Apple platforms; the Linux CI job skips them automatically.

## Handling an upstream release

1. The `upstream-watch` issue gives you the compare link.
2. In the submodule: `git fetch && git diff --name-only <old>...<new>` piped to
   `python3 scripts/port-status.py --stdin` → lists which changed files have
   Swift mirrors (action required) and which are not ported (usually fine).
3. Apply the same changes to the mirrored Swift files; bump their
   `// Mirrors:` headers to the new tag.
4. Refresh mocks if request/response shapes changed.
5. Update the submodule pin and `upstream-versions.json`; close the issue.
