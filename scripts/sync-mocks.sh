#!/usr/bin/env bash
# Selectively copies upstream extractor recorded mocks into the Swift test
# bundle, driven by the allowlist in Resources/mocks-manifest.txt. The full
# upstream corpus is ~180 MB, so only directories needed by ported test
# classes are vendored. Run after updating the NewPipeExtractor submodule or
# the manifest.
set -euo pipefail

cd "$(dirname "$0")/.."

SRC="upstream/NewPipeExtractor/extractor/src/test/resources"
DST="Packages/SwiftPipeExtractor/Tests/SwiftPipeExtractorTests/Resources"
MANIFEST="$DST/mocks-manifest.txt"

if [ ! -d "$SRC" ]; then
  echo "error: $SRC not found — initialize submodules first:" >&2
  echo "  git submodule update --init upstream/NewPipeExtractor" >&2
  exit 1
fi

synced=0
while IFS= read -r line; do
  # Skip comments and blank lines
  case "$line" in ''|\#*) continue ;; esac

  src_dir="$SRC/mocks/v1/$line"
  dst_dir="$DST/mocks/v1/$line"
  if [ ! -d "$src_dir" ]; then
    echo "error: manifest entry not found upstream: $line" >&2
    exit 1
  fi
  rm -rf "$dst_dir"
  mkdir -p "$dst_dir"
  cp -R "$src_dir/." "$dst_dir/"
  echo "synced: $line"
  synced=$((synced + 1))
done < "$MANIFEST"

# Subscription import fixtures (YouTube takeout, etc.) are small; copy always
find "$SRC" -maxdepth 1 -name 'youtube_takeout_import_test*' -exec cp {} "$DST/" \;

echo "Done ($synced mock directories)."
