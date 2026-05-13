# Case_001_BasicJoin

## Purpose

Minimal **end-to-end** proof of the Phase 3B join validation pipeline: one telemetry bar, one deal, **backward-only** attribution (`j_bar_utc ≤ d_time_utc`), **no** partial closes, **no** duplicates, **no** DST ambiguity (UTC epoch only).

## Expected behavior

| Item | Value |
|------|--------|
| Telemetry | Single data row; `bar_utc = 1735689600` |
| Deal | `d_time_utc = 1735689725` (125 s after bar open, still inside same M5 bar window) |
| Join | `j_join_status = OK`, `j_bar_utc = 1735689600`, `j_bar_latency_sec = 125` |
| Future leak | **Forbidden:** `j_bar_utc` must never exceed `d_time_utc` |

## Determinism

- All times are **UTC epoch seconds** (integers).
- Float formatting in golden files matches harness `DoubleToString` policy (see test source).
- Row ordering: single joined row.

## Failure conditions

- `j_bar_utc` ≠ `1735689600`
- `j_join_status` ≠ `OK`
- Any `j_bar_utc > d_time_utc` (**FUTURE_LEAK**)
- Mismatch vs `expected_joined.csv` data line
- Row count ≠ 1

## Telemetry / deal interchange

- `telemetry.csv` uses canonical **`AS_TELEMETRY_V1`** header from `TelemetryWriter_CsvHeaderLine()`.
- `deals.csv` uses header:  
  `d_ticket,d_symbol,d_magic,d_time_utc,d_volume,d_profit,d_type,d_entry,d_position_id,d_price,d_commission,d_swap,d_reason`  
  (`d_type`: `0` = BUY per `ENUM_DEAL_TYPE`; `d_entry`: `0` = IN per `ENUM_DEAL_ENTRY`)

## Deployment (**FILE_COMMON**)

The harness reads these files **only** from:

`Common\Files\AurumSynapse\TelemetryFixtures\Case_001_BasicJoin\`

Copy this case folder from the repo into that path before running `TestTelemetryJoinValidation.mq5` (see `TelemetryFixtures/README.md` and **`PHASE_3B_FIXTURE_DEPLOYMENT_POLICY_V1`**).
