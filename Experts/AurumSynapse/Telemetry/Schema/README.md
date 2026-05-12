# `Telemetry/Schema/` (T0)

Machine-readable schema artifacts may live here later (JSON schema, etc.).  
**Canonical human spec:** `../TelemetrySchema.md` at repo root of `Telemetry/`.

## Version lock (2026-05-12)

**`AS_TELEMETRY_V1`** header line, column order, and field semantics are **STABLE / VERSION-LOCKED** with the telemetry completion freeze. Any incompatible change requires a **new schema id** (and migration notes in `TelemetrySchema.md` + `Tests/POST_COMPLETION_VALIDATION_ROADMAP.md` — **`### PHASE 3A — COMPLETION FREEZE (official) — 2026-05-12`**).
