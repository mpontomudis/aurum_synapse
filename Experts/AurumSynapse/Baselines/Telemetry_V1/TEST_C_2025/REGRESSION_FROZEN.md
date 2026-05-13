# Regression baseline — frozen expectations (Phase S)

**Frozen date:** 2026-05-10  
**Scope:** Telemetry + Phase 3A Stream A only. EA **TEST C** tab metrics (PF, DD, trades) remain governed by the roadmap **TEST C matrix** — **OFF vs ON identical**; numbers are **instrument- and corpus-specific**, not re-stated here as fake constants.

## Stream A (analytics script)

| Metric | Expected (validated lab corpus) | Notes |
|--------|-----------------------------------|--------|
| **Schema** | `AS_TELEMETRY_V1` | First column of each data row |
| **Logical columns** | **68** | From `TelemetryWriter_CsvHeaderLine()` / `TelemetryCsvV1_ExpectedColumns()` |
| **Parser rejects** | **0** | `Parse/filter rejects` in report + Journal `rejects=` |
| **Ingested rows** | **15974** | Single canonical CSV set used in roadmap sign-off; **varies** with your files |
| **Files matched** | ≥ 1 when CSV present | Journal `[Analytics] … files=N …` |
| **Journal PASS** | `PASS` when `rejects=0` | `FAIL` ⇒ investigate CSV or parser drift immediately |

## EA / TEST C (behavioral — unchanged from prior freeze)

| Metric | Expected |
|--------|----------|
| **TEST C vs A/B** | **Identical** Strategy Tester tab metrics (trades, profit, PF, DD, etc.) | T2 is passive I/O on timer drain |
| **Telemetry behavior** | CSV appears under Common `AurumSynapse\telemetry\`; rotation per `TelemetrySchema.md` | No trade-path mutation |

## Operational regression command

1. Place telemetry CSV under Common `Files\AurumSynapse\telemetry\`.  
2. Compile and run **`Tests/TestTelemetryAnalytics.mq5`** in Strategy Tester.  
3. Confirm Journal: **`[Analytics] AS_TELEMETRY_V1 files=… rows=… rejects=0 PASS`** and **`[TestTelemetryAnalytics] done rows=… rejects=0`**.
