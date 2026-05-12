# Aurum Synapse — `Telemetry/` (T0–T2)

**Policy:** Observability is **passive** and **read-only** toward trading decisions. No `CTrade`, no mutation of `MarketState`, strategies, consensus, or execution order. Telemetry **OFF** (default) must leave the EA trading path unchanged aside from compile-time `#ifdef` dead branches.

## Completion freeze (2026-05-12)

| Track | Status |
|-------|--------|
| **T0** | **COMPLETE** |
| **T1** passive telemetry | **COMPLETE + VALIDATED** (TEST B — OFF vs ON non-interference) |
| **T2** shadow persistence | **COMPLETE + VALIDATED** (TEST C — CSV + `FILE_COMMON` + rotation + no EA drift) |
| **Phase 3A Stream A** (offline analytics) | **COMPLETE + VALIDATED** — `Tests/TestTelemetryAnalytics.mq5`; canonical sample Journal: `rows=15974`, `rejects=0`; `[ANALYTICS_FILEOPEN]` `FileIsExist=true`, `GetLastError=0` |

**Schema / CSV (`AS_TELEMETRY_V1`):** **STABLE / VERSION-LOCKED** — no breaking column/header/semantic changes without a new schema version and migration note (`TelemetrySchema.md` + `Tests/POST_COMPLETION_VALIDATION_ROADMAP.md`, section **`### PHASE 3A — COMPLETION FREEZE (official) — 2026-05-12`**).

**Still out of scope:** non-adaptive, read-only analytics vs execution; **no** execution mutation or self-modifying behavior from telemetry or Stream A.

**Planned (not implemented):** *Telemetry* **PHASE 3B** — deal join analytics; *Telemetry* **PHASE 4** — adaptive intelligence. *(Disambiguation: elsewhere in the project roadmap, “Phase 3B” may mean strategy H2 work — different scope.)*

---

=== CURRENT SYSTEM CAPABILITY ===

1. Passive runtime telemetry (**T1**)
2. Persistent telemetry storage (**T2**, `FILE_COMMON` CSV under `AurumSynapse\telemetry\`)
3. Historical telemetry archive (operator workflow — `Telemetry/Archive/README.md`)
4. Offline analytics engine (**Phase 3A Stream A**, `TelemetryAnalytics/` + `Tests/TestTelemetryAnalytics.mq5`)
5. Regime observational intelligence (proxy labels from telemetry fields)
6. Strategy participation analytics (descriptive matrix)
7. Quality-distribution analytics and session bucketing

---

## Stages

| Stage | Role | EA integration |
|-------|------|----------------|
| **T0** | Schema POD (`TelemetryTypes`), contracts, **NO-OP** manager shell, docs | None |
| **T1** | `TelemetryCollector` builds `TelemetryBarRow` from read-only inputs; **`TelemetryRingBuffer`** in-memory cap | `#define AURUM_TELEMETRY_T1` in `AurumSynapse.mq5` |
| **T2** | Same row → bounded queue (drop-oldest) → **`OnTimer`** drain → **`FILE_COMMON`** CSV under `AurumSynapse\telemetry\` | `#define AURUM_TELEMETRY_T2` **and** T1 |

## Key files

| File | Role |
|------|------|
| `TelemetryVersion.mqh` | `AS_TELEMETRY_V1` identity |
| `TelemetryTypes.mqh` | `TelemetryBarRow` + inits |
| `TelemetryCollector.mqh` | T1: `BuildBarRow` + `OnBarPassive` (ring push) |
| `TelemetryRingBuffer.mqh` | T1 fixed ring |
| `TelemetryConfig.mqh` | T2 constants + T2-without-T1 compile guard |
| `TelemetryQueue.mqh` | T2 fixed queue, drop-oldest |
| `TelemetryWriter.mqh` | CSV header + `FormatDataLine` |
| `TelemetryRotation.mqh` | Path / day / size rotation helpers |
| `TelemetryPersistence.mqh` | T2 init / enqueue / timer drain / deinit flush |
| `TelemetrySchema.md` | Column order + T2 storage notes |

## Tests

- `Tests/TestTelemetryT0.mq5` — T0 compile + type smoke  
- `Tests/TestTelemetryT1.mq5` — T1 collector + ring  
- `Tests/TestTelemetryT2.mq5` — T2 persistence + queue + `FILE_COMMON` read-back  
- `Tests/TestTelemetryAnalytics.mq5` — Phase 3A Stream A (after T2 CSV exists under Common `Files\AurumSynapse\telemetry\`)

## Rollback

- **T2 only:** comment `#define AURUM_TELEMETRY_T2`, recompile.  
- **T1+T2:** comment both defines, recompile (default shipping build).  
- Removing the `Telemetry/` folder is possible only after stripping `#include` / `#ifdef` glue from `AurumSynapse.mq5`.

See `Tests/POST_COMPLETION_VALIDATION_ROADMAP.md` — **`### PHASE 3A — COMPLETION FREEZE (official) — 2026-05-12`** — for certification tables, root-cause history (Stream A path resolution), and program discipline.

## Phase 3A — shadow analytics (separate folder)

**Not part of the EA:** `TelemetryAnalytics/` + `Tests/TestTelemetryAnalytics.mq5` read **`FILE_COMMON`** `AurumSynapse\telemetry\AS_TELEMETRY_V1_*.csv` and print a **descriptive** report (proxy regimes, sessions, quality bins, strategy×regime counts). **No** deal join, **no** adaptive execution, **no** changes to `Telemetry/` capture path. Stream B (P/L attribution) remains deferred.
