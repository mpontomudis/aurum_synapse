# Case_008_PositionRollup

**Policy:** `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md` §A8 — **deal-grain** joined rows with **deterministic lifecycle rollup annotations** (not a collapsed position row).

## Intent

Five deals share **`d_position_id = 800008`** (OPEN → ADD → partial OUT → ADD → final OUT pattern in intent). The harness proves:

- **Grouping:** same lifecycle campaign = same `d_position_id` on every deal row.
- **Ordering:** canonical replay order is **`d_time_utc` ascending, then `d_ticket` ascending** (then physical order is irrelevant once sorted).
- **Output model:** **one joined slim row per deal** — still not a production “position aggregated” export.

## Extra columns (Case_008 only)

Appended after the Case_001-compatible slim tail:

| Column | Meaning |
|--------|---------|
| `x_lifecycle_group_id` | Frozen campaign id — equals **`d_position_id`** (`800008` here). |
| `x_lifecycle_seq` | **0-based** index in the canonical sort above (0 … 4). |

Implemented in `JoinValidation_AppendLifecycleRollupSuffix` after `JoinValidation_BuildJoinedSlimCase001`.

## Distinction vs Case_007

- **Case_007:** partial-close **identity** consistency (3 legs), no extra columns.
- **Case_008:** **full** multi-leg lifecycle **group + sequence** annotations on each deal row (5 legs), still **no row collapse**.

## Fixture

`deals.csv` rows are **intentionally shuffled**; the harness re-sorts before join. Telemetry: three bars `1735689600`, `1735689900`, `1735690200`.

## Pass criteria

- Five joined lines byte-identical to `expected_joined.csv` (extended header).
- Journal: `[JOIN_VALIDATION] STATUS=PASS rows=5 position_rollup_validated=1`.

## Deploy

Copy under `Terminal\Common\Files\AurumSynapse\TelemetryFixtures\` per parent `README.md`.
