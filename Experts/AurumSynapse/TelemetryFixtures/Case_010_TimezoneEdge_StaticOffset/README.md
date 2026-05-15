# Case_010_TimezoneEdge_StaticOffset

**Policy:** `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md` §A10 — **UTC epoch canonical** deal and bar times, **backward-only** join at a **calendar / M5 boundary**, with **static offset metadata only** (not join input).

## Clock contract

- **`d_time_utc`** and **`bar_utc`** are **Unix UTC seconds** only. Phase 3B join validation **does not** apply `server_utc_offset_sec` to bar selection.
- **`server_utc_offset_sec`** in `expected_validation.json` documents a hypothetical **+7200** server skew for operator awareness; it must **not** influence `j_bar_utc`. **DST is explicitly unsupported** in this V1 harness path — no DST tables, no broker-local conversion layer.

## Scenario

| Artifact | Value |
|----------|--------|
| Bar A `bar_utc` | `1735775700` (`2025-01-01 23:55:00` UTC wall-clock in `bar_time` — display only) |
| Bar B `bar_utc` | `1735776000` (`2025-01-02 00:00:00` UTC) — **strictly after** deal time |
| Deal `d_time_utc` | `1735775850` — between A and B (**midnight-adjacent** M5 edge narrative) |

**Expected join:** `j_bar_utc = max(bar_utc ≤ d_time_utc) = **1735775700**` (bar A), **not** `1735776000` (would be future leak / forward-nearest).

**Latency:** `j_bar_latency_sec = 1735775850 - 1735775700 = 150`.

## Harness

Uses the same causal guard path as Case_004 (`passMode == 6` in `TestTelemetryJoinValidation.mq5`): telemetry file contains a **future** bar relative to the deal; selection still picks the **last legal backward** bar.

## Pass criteria

- Byte match to `expected_joined.csv` (JOINED_SLIM, no lifecycle columns).
- Journal: `[JOIN_VALIDATION] STATUS=PASS rows=1 timezone_edge_validated=1`.

## Deploy

Copy this folder from the repo into `Terminal\Common\Files\AurumSynapse\TelemetryFixtures\` before running the harness (**manual**; not scripted here).
