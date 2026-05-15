# Case_004_FutureLeakProtection

**Policy:** `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md` §A4 — causal legality is evaluated **before** any nearest-neighbor or quality tie-break among candidates.

## Objective

Lock the invariant: the join prototype **never** selects a telemetry row with `bar_utc > d_time_utc`, even when such a row exists in the same CSV and could tempt a naive “closest timestamp” matcher.

## Frozen clocks (UTC epoch seconds)

| Role | Value |
|------|--------|
| Backward-legal telemetry bar | `1735689600` |
| Deal time | `1735689700` |
| Telemetry bar strictly in the future of the deal | `1735690200` |

**Legal set:** `{ bar_utc | bar_utc ≤ 1735689700 }` → `{1735689600}` only.

**Illegal set:** `{1735690200}` — present in `telemetry.csv`, must contribute **zero** to candidate competition.

**Selected join:** `j_bar_utc = 1735689600`, `j_join_status = OK`, `j_bar_latency_sec = 100`.

## Why “closest” alone is unsafe

A nearest-neighbor on raw epoch timestamps can pick a bar **after** the deal if the filter is forgotten. That leaks future information into attribution, corrupting toxicity, regime labels, and any downstream ML. This fixture proves the harness and prototype apply the **causal filter first**, then `MAX(bar_utc)` among survivors.

## Pass criteria

- At least **two** telemetry data rows; at least **one** with `bar_utc > d_time_utc`.
- Eligible backward count for the deal is exactly **one** (`1735689600`).
- Joined slim line is **byte-identical** to `expected_joined.csv`.
- Journal: `[JOIN_VALIDATION] STATUS=PASS rows=1 future_leak_prevented=1`.

## Deploy

Copy this folder under `Terminal\Common\Files\AurumSynapse\TelemetryFixtures\` (see parent `TelemetryFixtures/README.md`).
