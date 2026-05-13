# Case_002_OrphanDeal

## Purpose

**Negative / deterministic** validation: a deal whose `d_time_utc` is **strictly before** the only telemetry `bar_utc` has **no** eligible bar under backward-only policy `max(bar_utc ≤ deal_time)`. The joiner must emit **one** `AS_JOINED_V1` slim row with `j_join_status=ORPHAN_DEAL`, **no** future-bar fallback, and **no** silent skip.

## Design

| Stream | Value |
|--------|--------|
| Telemetry | Single bar; `bar_utc = 1735689600` (same canonical row shape as Case_001) |
| Deal | `d_time_utc = 1735689500` (100 s **before** bar open — no `bar_utc ≤ deal_time`) |
| Join | `j_join_status = ORPHAN_DEAL`, `j_bar_utc = 0`, `j_bar_latency_sec = 0` |
| `t_*` | Empty `t_symbol`; integer/double telemetry slots use `TELEMETRY_NULL_*` per `PHASE_3B_PRE_IMPLEMENTATION_CHECKLIST.md` |
| `x_regime_proxy` / `x_quality_bin` | `REGIME_PROXY_UNKNOWN` / `QUALITY_BIN_NULL` (no parsed telemetry row) |

## Expected behavior

- Exactly **one** output row; `d_*` and `x_net_money` reflect the deal only.
- **Forbidden:** `j_bar_utc > d_time_utc` (future leak), inventing a `j_bar_utc` from the only future bar, or copying telemetry fields from that bar into `t_*`.

## Determinism

- UTC epoch integers only for timestamps.
- `DoubleToString(..., 8)` for money and null doubles (same as harness / `TelemetryWriter_Dstr` policy). For `TELEMETRY_NULL_DOUBLE`, the golden string is the **IEEE-754-rounded** fixed-decimal form (see **`CANONICAL_RUNTIME_SERIALIZATION_POLICY_V1`** in `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md`) — do not substitute a shortened “-1e100” placeholder.
- Single deal row; no ordering ambiguity.

## Failure conditions

- `j_join_status` not `ORPHAN_DEAL` when policy says orphan.
- `j_bar_utc ≠ 0` or fabricated `t_*` from the telemetry file.
- Byte mismatch vs `expected_joined.csv` data line.

## Deployment (**FILE_COMMON**)

Same as Case_001: copy this folder to `Common\Files\AurumSynapse\TelemetryFixtures\Case_002_OrphanDeal\` before running `TestTelemetryJoinValidation.mq5`.
