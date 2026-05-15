# Case_005_MissingTelemetryRow

**Policy:** `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md` §A5 — telemetry **gap** without synthetic fill; same causal rule as §A4.

## Objective

Model production where a **middle** bar never existed in the CSV (write gap, crash, rotation, detach). The join must remain **deterministic**, attribute only to **real** rows, and must **not** interpolate or invent `1735689900`.

## Clocks (UTC epoch seconds)

| Role | Value |
|------|--------|
| Last **present** backward bar | `1735689600` |
| **Missing** bar (documented gap — **not** in `telemetry.csv`) | `1735689900` |
| Deal `d_time_utc` | `1735690000` (after `9600`, in the gap before the next real bar) |
| Next **present** bar (strictly **future** for this deal) | `1735690200` |

**Legal candidate set:** `{ bar_utc | bar_utc ≤ 1735690000 }` ∩ rows in file → `{1735689600}` only.

**Rejected:** `1735690200` (`bar_utc > d_time_utc` — causal filter, not “nearest timestamp” on the whole timeline).

**Golden join:** `j_bar_utc = 1735689600`, `j_join_status = OK`, `j_bar_latency_sec = 400`.

## Missing telemetry vs orphan deal

- **Missing telemetry (this case):** at least one **legal** backward bar exists in the file (`1735689600`), so the join is **`OK`** and attributes to that **last observed** parent — even though an **ideal** closer bar would have been `1735689900` if it had been written.
- **Orphan deal (`Case_002`):** **no** row satisfies `bar_utc ≤ d_time_utc`; output is **`ORPHAN_DEAL`** with null `t_*` policy per harness.

## Forbidden (frozen for this harness)

No interpolation, no inferred CSV rows, no forward fill from `1735690200`, no hidden synthetic regime reconstruction.

## Pass criteria

- `telemetry.csv` has **no** data row with `bar_utc = 1735689900`.
- ≥2 data rows; ≥1 strictly future row for the deal clock.
- Byte-identical `expected_joined.csv`.
- Journal: `[JOIN_VALIDATION] STATUS=PASS rows=1 missing_gap_handled=1`.

## Deploy

Copy this folder under `Terminal\Common\Files\AurumSynapse\TelemetryFixtures\` (see parent `TelemetryFixtures/README.md`).
