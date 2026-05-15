# Case_003_DuplicateCandidateJoin

## Purpose

**“Duplicate candidate”** means **multiple telemetry bars** are backward-eligible for **one** deal (`bar_utc ≤ d_time_utc`) — **not** a duplicate deal ticket. This case proves the join prototype picks **`MAX(bar_utc)`** among eligible rows **deterministically**, with **no** forward leak, **no** “first row wins” dependence, and **no** random tie.

## Telemetry

Two `AS_TELEMETRY_V1` data rows, same `symbol` / `period`:

| Row | `bar_utc` | Notes |
|-----|-----------|--------|
| A | `1735689600` | Earlier M5 bar open |
| B | `1735689900` | Later M5 bar open (+300 s) |

## Deal

Single deal with `d_time_utc = 1735690000` (strictly **after** both bars). Eligible set = `{1735689600, 1735689900}`.

## Expected join

- `j_join_status = OK`
- `j_bar_utc = t_bar_utc = 1735689900` (**row B** — **latest** eligible backward bar)
- `j_bar_latency_sec = 100` (= `1735690000 - 1735689900`)
- `t_*` fields match **row B** telemetry only (not a blend, not row A).

## Why B wins over A

Frozen policy: **`selected_bar = MAX({ bar_utc | bar_utc ≤ d_time_utc })`**. Both bars are ≤ deal time; **990 > 960**, so **B** is the causal “as-of” state at deal time.

## Determinism / file order

The prototype **scans every data line** and recomputes the maximum eligible `bar_utc`. Permuting the two telemetry rows in the CSV **does not** change the selected bar.

## Failure conditions

- `j_bar_utc` equals `1735689600` (wrong / first-row heuristic).
- `j_bar_utc > d_time_utc` (future leak).
- Different `t_spread_points` (or other `t_*`) than row B’s row.
- `expected_joined` line mismatch vs harness output.

## Deployment (**FILE_COMMON**)

Copy this folder to `Common\Files\AurumSynapse\TelemetryFixtures\Case_003_DuplicateCandidateJoin\` before running `TestTelemetryJoinValidation.mq5`.
