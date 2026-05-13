# Baseline — `Telemetry_V1` / TEST C (2025 corpus anchor)

**Purpose:** Institutional anchor for **historical comparability** and regression trust. Large binary artifacts (full CSV exports, Strategy Tester HTML/PDF) are **not** committed here; store them in your secure archive and record paths below.

## Canonical references (fill in your archive paths)

| Artifact | Description | Default / example location |
|----------|-------------|----------------------------|
| **TEST C Strategy Tester report** | Build **C** (`AURUM_TELEMETRY_T1` + `AURUM_TELEMETRY_T2`) — tab metrics proving OFF vs ON non-interference | *(operator archive)* |
| **Telemetry CSV sample** | At least one `AS_TELEMETRY_V1_*.csv` under Common `Files\AurumSynapse\telemetry\` | Terminal Common Files tree |
| **Stream A analytics report** | Journal + stdout from `Tests/TestTelemetryAnalytics.mq5` after ingest | Journal export |
| **Tester `.set`** | Locked inputs for the run | Repo: `Tests/BacktestScripts/BacktestConfig.set` (adjust copy per your locked profile) |
| **Join-validation golden harness** | Strategy Tester / `OnInit` — `Tests/TestTelemetryJoinValidation.mq5` after copying `Experts/AurumSynapse/TelemetryFixtures/` → Common (`Case_001` / `Case_002` **PASS** as of **2026-05-10**; see `TelemetryAnalytics/PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md`) |
| **Parser validation** | `rejects=0` on validated corpus; see `REGRESSION_FROZEN.md` | This folder |

## Row-count expectation

**Analytics ingested rows** depend on the CSV set present under `FILE_COMMON`. The roadmap freeze recorded **15974** data rows for the **validated lab corpus** (single-file scenario). Re-run `TestTelemetryAnalytics.mq5` after any telemetry change; **`[Analytics] … rejects=0 PASS`** is the primary parser health gate.

## Version lock

See report header lines emitted by `AnalyticsAggregator_Run` for `TELEMETRY_SCHEMA_VERSION`, `ANALYTICS_ENGINE_VERSION`, and `ANALYTICS_STREAM_A_REPORT_VERSION`.
