# Telemetry validation notes

## Freeze status (2026-05-12)

| Test | Status | Notes |
|------|--------|--------|
| **TEST B — T1** | **PASSED** | OFF vs ON identical metrics; no trade drift; non-invasive |
| **TEST C — T2** | **PASSED** | `FILE_COMMON` CSV, rotation, rows persisted; no EA drift |
| **Phase 3A Stream A** | **PASSED** | `TestTelemetryAnalytics`: sample `rows=15974`, `rejects=0`; path resolution + line reader + parser |

**Schema:** `AS_TELEMETRY_V1` is **STABLE / VERSION-LOCKED** — breaking changes require version bump + migration doc.

## How to run

- **`Tests/TestTelemetryT0.mq5`** — Strategy Tester (any symbol): T0 headers compile.
- **`Tests/TestTelemetryAnalytics.mq5`** — After T2 CSV exists under Terminal **Common** `Files\AurumSynapse\telemetry\`: Journal should report aggregates + `done rows=… rejects=0` for a valid corpus.

## References

- Full certification + root-cause chain: `Tests/POST_COMPLETION_VALIDATION_ROADMAP.md` → section **`### PHASE 3A — COMPLETION FREEZE (official) — 2026-05-12`**
- Column contract: `Telemetry/TelemetrySchema.md`
