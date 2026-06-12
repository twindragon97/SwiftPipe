#!/usr/bin/env bash
# Copies upstream extractor test resources (recorded mocks, takeout fixtures)
# into the Swift test bundle. Run after updating the NewPipeExtractor submodule.
set -euo pipefail

cd "$(dirname "$0")/.."

SRC="upstream/NewPipeExtractor/extractor/src/test/resources"
DST="Packages/SwiftPipeExtractor/Tests/SwiftPipeExtractorTests/Resources"

if [ ! -d "$SRC" ]; then
  echo "error: $SRC not found — initialize submodules first:" >&2
  echo "  git submodule update --init upstream/NewPipeExtractor" >&2
  exit 1
fi

rm -rf "$DST/mocks"
mkdir -p "$DST"
cp -R "$SRC/mocks" "$DST/mocks"
# Subscription import fixtures (YouTube takeout, etc.)
find "$SRC" -maxdepth 1 -name 'youtube_takeout_import_test*' -exec cp {} "$DST/" \;

echo "Synced mocks into $DST"
