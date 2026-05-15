# Case_007_PartialCloseLifecycle

**Policy:** `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md` §A7 — multiple **deal-level** joins sharing one **lifecycle root** (`d_position_id`), deterministic ordering.

## Intent

Model three **partial close** deals (same `d_position_id`, different `d_ticket` / `d_time_utc`) against a small multi-bar telemetry file. This is **not** a position PnL rollup: each deal still produces **exactly one** `AS_JOINED_V1` slim row with `j_join_status=OK`.

## Lifecycle vs deal row

- **Deal row:** one CSV line in `deals.csv` → one joined output row after backward bar selection.
- **Lifecycle identity (Case_007):** `d_position_id` is the shared root; every joined row in this fixture carries **`d_position_id=800007`**.

## Deterministic ordering

`deals.csv` is intentionally **not** time-sorted. The harness **sorts** data lines by **`(d_time_utc` ascending, `d_ticket` ascending)** before joining, so replay order does not depend on file row order.

## Fixture

| Deal ticket | `d_time_utc` | `d_volume` | Expected `j_bar_utc` |
|-------------|--------------|------------|----------------------|
| 910701 | 1735689725 | 0.30 | 1735689600 |
| 910702 | 1735690010 | 0.40 | 1735689900 |
| 910703 | 1735690250 | 0.30 | 1735690200 |

Telemetry bars: `1735689600`, `1735689900`, `1735690200`.

## Pass criteria

- Three joined lines, byte-identical to `expected_joined.csv` (header + three data lines).
- Journal: `[JOIN_VALIDATION] STATUS=PASS rows=3 partial_close_lifecycle_validated=1`.

## Deploy

Copy under `Terminal\Common\Files\AurumSynapse\TelemetryFixtures\` (see parent `README.md`).
