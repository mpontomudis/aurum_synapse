# TelemetryFixtures — Phase 3B golden join validation

**Policy:** `GOLDEN_CSV_NORMALIZATION_V1` (see `TelemetryAnalytics/PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md`)

- UTF-8 **without BOM**
- **LF** (`\n`) line endings only in committed CSV files
- Comma delimiter
- No locale-dependent formats (use fixed decimal width as per each case README)

## Runtime location (**FILE_COMMON**)

The harness **`Tests/TestTelemetryJoinValidation.mq5`** reads fixtures **only** from:

`Common\Files\AurumSynapse\TelemetryFixtures\<Case>\`

(i.e. `FileOpen(..., FILE_COMMON)` with relative path `AurumSynapse\TelemetryFixtures\Case_001_BasicJoin\telemetry.csv`, and similarly `...\Case_002_OrphanDeal\...`).

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

## Status (Phase 3B join validation — 2026-05-10)

| Case | Harness result |
|------|----------------|
| `Case_001_BasicJoin` | **PASS** |
| `Case_002_OrphanDeal` | **PASS** |

Harness: `Tests/TestTelemetryJoinValidation.mq5`. **Always** redeploy this folder to `Terminal\Common\Files\AurumSynapse\TelemetryFixtures\` before Strategy Tester runs so **`FILE_COMMON`** bytes match the repo (stale Common copies cause `line_mismatch` while join logic is correct).
