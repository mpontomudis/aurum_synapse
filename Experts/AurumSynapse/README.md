# Aurum Synapse

Multi-strategy MetaTrader 5 expert with **passive telemetry** (optional compile flags), **shadow CSV persistence** (T2, `FILE_COMMON`), and an **offline analytics** harness (**Phase 3A Stream A**) that reads telemetry CSVs only — it does not link into the live EA path.

## Folders

| Path | Role |
|------|------|
| `Core/` | Shared types, constants, diagnostics |
| `Engine/` | Signal / strategy orchestration, quality |
| `Execution/` | Orders, money, timers |
| `Intelligence/` | AI / research hooks (non-trading mutation policy per module) |
| `Management/` | Risk and trade management |
| `Strategies/` | Concrete strategies (`BaseStrategy` derivatives) |
| `UI/` | Panel / logger |
| `Telemetry/` | **T0–T2** schema, collector, ring, queue, writer, rotation, persistence |
| `TelemetryAnalytics/` | **Stream A** — CSV scan, regime/session/quality/strategy aggregates |
| `Tests/` | Expert test scripts, **POST_COMPLETION_VALIDATION_ROADMAP.md**, backtest methodology |
| `Docs/` | Scaffold and project notes |

## Compile flags (EA)

Defined in `AurumSynapse.mq5` (see `Telemetry/README.md`):

- **`AURUM_TELEMETRY_T1`** — passive bar snapshot + in-memory ring  
- **`AURUM_TELEMETRY_T2`** — queue + `OnTimer` drain to `FILE_COMMON` CSV under `AurumSynapse\telemetry\`

## Analytics test

After T2 CSV files exist in Terminal **Common** `Files\AurumSynapse\telemetry\`, compile and run **`Tests/TestTelemetryAnalytics.mq5`** in Strategy Tester. Expect `done rows=… rejects=0` for a valid corpus (see roadmap freeze for canonical sample counts).

## Contract

**`AS_TELEMETRY_V1`** CSV header and column order are **STABLE / VERSION-LOCKED** — breaking changes require a new schema id and migration notes (`Telemetry/TelemetrySchema.md` + roadmap freeze section).
