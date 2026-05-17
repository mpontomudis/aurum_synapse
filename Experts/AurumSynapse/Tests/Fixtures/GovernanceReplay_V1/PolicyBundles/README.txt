PolicyBundles (GovernanceReplay_V1)
====================================

Deploy this directory tree under the terminal `MQL5\Files\` root (preserve paths) when running file-based loader tests from disk. The harness `TestGovernanceStateMachineV1.mq5` primarily uses `GovPolicyLoaderV1_LoadFromUtf8Text` for determinism; `LoadFromFile` roundtrip writes a temp `policy.tab` under the active Files directory.

Subfolders
----------
- `valid_v1/` — minimal passing bundle (SHA-256 over canonical body matches `policy_checksum_sha256`).
- `invalid_semver/` — valid checksum for declared body, semver grammar invalid (`1.x.0`).
- `duplicate_keys/` — duplicate `policy_id` keys (fail-closed).
- `malformed_lines/` — non `key=value` line.
- `checksum_mismatch/` — same semantic body as `valid_v1`, wrong checksum nibble.

Normative format: see `CANONICAL_POLICY_TAB_V1.txt` in this folder.
