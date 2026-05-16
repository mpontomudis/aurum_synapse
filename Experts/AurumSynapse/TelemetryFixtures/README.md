# TelemetryFixtures — Phase 3B golden join validation

**Freeze (Suite V1):** **`TelemetryAnalytics/PHASE_3B_GOLDEN_SUITE_FREEZE_V1.md`** — canonical **regression law** for Cases **001–010**. **Suite marker:** `VERSION.txt`.

**Policy:** `GOLDEN_CSV_NORMALIZATION_V1` (see `TelemetryAnalytics/PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md`)

- UTF-8 **without BOM**
- **LF** (`\n`) line endings only in committed CSV files
- Comma delimiter
- No locale-dependent formats (use fixed decimal width as per each case README)

## Runtime location (**FILE_COMMON**)

The harness **`Tests/TestTelemetryJoinValidation.mq5`** reads fixtures **only** from:

`Common\Files\AurumSynapse\TelemetryFixtures\<Case>\`

(i.e. `FileOpen(..., FILE_COMMON)` with relative path `AurumSynapse\TelemetryFixtures\Case_001_BasicJoin\telemetry.csv`, and similarly `Case_002_OrphanDeal`, … `Case_010_TimezoneEdge_StaticOffset`, …).

## UTC edge + static offset metadata (Case_010)

**`Case_010_TimezoneEdge_StaticOffset`** proves backward-only **`MAX(bar_utc ≤ d_time_utc)`** at a **UTC boundary** with a **future** bar present in-file; `server_utc_offset_sec` in JSON is **not** join input. See `Case_010_TimezoneEdge_StaticOffset/README.md` and `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md` §A10.

## Multi-deal position attribution (Case_009)

**`Case_009_MultiDealPositionAttribution`** extends Case_008’s lifecycle columns with telemetry that **changes per bar**: each deal row must carry the **`t_*` / `x_regime_proxy` / `x_quality_bin` / leader** fields of **its** backward-eligible bar, including a deliberate **two-deals-one-bar** pair to show we do **not** force a single “campaign bar.” See `Case_009_MultiDealPositionAttribution/README.md` and `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md` §A9.

## Position lifecycle rollup annotations (Case_008)

When **multiple deals** share the same **`d_position_id`**, **`Case_008_PositionRollup`** asserts that the harness still emits **one joined row per deal** (deal-grain), but appends **`x_lifecycle_group_id`** (here equal to **`d_position_id`**) and **`x_lifecycle_seq`** (0-based index after canonical **`(d_time_utc, d_ticket)`** sort). This validates deterministic **campaign grouping + ordering** only — it is **not** a collapsed position-level aggregate export. See `Case_008_PositionRollup/README.md` and `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md` §A8.

## Partial close lifecycle (Case_007)

Multiple deals sharing **`d_position_id`** (partial closes on one position) are still emitted as **one joined slim row per deal**, sorted by **`(d_time_utc, d_ticket)`** before join — see `Case_007_PartialCloseLifecycle/README.md` and `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md` §A7. This is **not** a position rollup or aggregated PnL row.

This path is **shared** by the terminal UI and **Strategy Tester agents**, avoiding per-agent sandbox copies under `Tester\...\MQL5\Experts\...`.

## Repository location (source of truth)

This folder under the repo:

`MQL5\Experts\AurumSynapse\TelemetryFixtures\`

is the **version-controlled source**. Before running the harness (or nightly regression), **copy** its contents into:

`MetaQuotes\Terminal\Common\Files\AurumSynapse\TelemetryFixtures\`

(In MT5: **File → Open Data Folder** → go up to `Terminal` → open **`Common`** → **`Files`** → create `AurumSynapse\TelemetryFixtures\` and paste cases.)

**PowerShell example:**

```powershell
$src = "…\MQL5\Experts\AurumSynapse\TelemetryFixtures"
$dst = "$env:APPDATA\MetaQuotes\Terminal\Common\Files\AurumSynapse\TelemetryFixtures"
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item -Path (Join-Path $src '*') -Destination $dst -Recurse -Force
```

## Layout per case

`Case_XXX_*/` contains `telemetry.csv`, `deals.csv`, `expected_joined.csv`, `expected_validation.json`, `README.md`.

## Duplicate deal ticket (Case_006)

When **`deals.csv`** contains multiple rows with the **same** `d_ticket`, the Phase 3B harness applies a **frozen canonical row** policy (earliest `d_time_utc`, then lexical line tie-break, then physical order) and performs **one** join — see `Case_006_DuplicateDealTicket/README.md` and `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md` §A6. This is distinct from **`Case_003_DuplicateCandidateJoin`**, which concerns **multiple telemetry bars** for one deal.

## Status (Phase 3B join validation — 2026-05-10)

| Case | Harness result |
|------|----------------|
| `Case_001_BasicJoin` | **PASS** |
| `Case_002_OrphanDeal` | **PASS** |
| `Case_003_DuplicateCandidateJoin` | **PASS** |
| `Case_004_FutureLeakProtection` | **PASS** |
| `Case_005_MissingTelemetryRow` | **PASS** |
| `Case_006_DuplicateDealTicket` | **PASS** |
| `Case_007_PartialCloseLifecycle` | **PASS** |
| `Case_008_PositionRollup` | **PASS** |
| `Case_009_MultiDealPositionAttribution` | **PASS** |
| `Case_010_TimezoneEdge_StaticOffset` | **PASS** |

Harness: `Tests/TestTelemetryJoinValidation.mq5`. **Always** redeploy this folder to `Terminal\Common\Files\AurumSynapse\TelemetryFixtures\` before Strategy Tester runs so **`FILE_COMMON`** bytes match the repo (stale Common copies cause `line_mismatch` while join logic is correct).
