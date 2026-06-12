# Recorded mocks

Mock directories are synced selectively from the upstream submodule via
`scripts/sync-mocks.sh`, driven by the allowlist in `../mocks-manifest.txt`
(one sub-path per line). The full upstream mock corpus is ~180 MB, so only
the directories needed by ported test classes are vendored.
