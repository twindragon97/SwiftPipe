#!/usr/bin/env python3
"""Track which upstream Java files have Swift mirrors.

Mirrored Swift files declare their upstream counterpart in a header line:

    // Mirrors: extractor/src/main/java/org/schabi/.../Foo.java @ v0.26.3

Usage:
  python3 scripts/port-status.py
      Summary: how many files are mirrored, grouped by pinned ref.

  python3 scripts/port-status.py --changed path/A.java path/B.java
  git diff --name-only vOLD...vNEW | python3 scripts/port-status.py --stdin
      For a set of changed upstream files, report which ones have Swift
      mirrors (port action required) and which are not ported.
"""

import argparse
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MIRROR_RE = re.compile(r"^//\s*Mirrors:\s*(\S+)\s*@\s*(\S+)", re.MULTILINE)


def collect_mirrors():
    """Map upstream path -> {swift, ref} from // Mirrors: headers."""
    mirrors = {}
    for swift_file in (ROOT / "Packages").rglob("*.swift"):
        text = swift_file.read_text(encoding="utf-8", errors="replace")
        match = MIRROR_RE.search(text)
        if match:
            mirrors[match.group(1)] = {
                "swift": swift_file.relative_to(ROOT).as_posix(),
                "ref": match.group(2),
            }
    return mirrors


def print_summary(mirrors):
    print(f"Mirrored files: {len(mirrors)}")
    by_ref = Counter(entry["ref"] for entry in mirrors.values())
    for ref, count in sorted(by_ref.items()):
        print(f"  @ {ref}: {count}")


def print_changed_report(mirrors, changed):
    ported = [(path, mirrors[path]) for path in changed if path in mirrors]
    unported = [path for path in changed if path not in mirrors]

    print(f"== PORT ACTION REQUIRED ({len(ported)}) ==")
    for path, entry in ported:
        print(f"  {path}\n    -> {entry['swift']} (@ {entry['ref']})")

    print(f"\n== no Swift mirror ({len(unported)}) ==")
    for path in unported:
        print(f"  {path}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--changed", nargs="*", help="changed upstream file paths")
    parser.add_argument(
        "--stdin", action="store_true", help="read changed paths from stdin"
    )
    args = parser.parse_args()

    mirrors = collect_mirrors()

    changed = list(args.changed or [])
    if args.stdin:
        changed += [line.strip() for line in sys.stdin if line.strip()]

    if changed:
        print_changed_report(mirrors, changed)
    else:
        print_summary(mirrors)


if __name__ == "__main__":
    main()
