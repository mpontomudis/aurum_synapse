# Case_009_MultiDealPositionAttribution

**Policy:** `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md` §A9 — **deal-grain** join with **per-deal backward bar attribution** under one `d_position_id`, **mixed telemetry contexts**, and lifecycle suffix columns.

## Intent

Five deals share **`d_position_id = 900009`** but occur at different `d_time_utc` values so each row must join to its **own** causal telemetry bar (`MAX(bar_utc ≤ d_time_utc)`). Telemetry rows differ in **ADX / volatility_ratio** (hence different `x_regime_proxy`), **quality**, **consensus_strength**, **agreement_pct**, and **strategy leader** (slot / sig / strength). A **future** telemetry row exists in the file and must **never** be selected.

## Mapping (golden)

| Leg (canonical sort) | Deal time → backward bar | Narrative (documentation) |
|----------------------|--------------------------|---------------------------|
| 1 | `1735700050` → bar `1735700000` | Open in **trending** proxy regime |
| 2 | `1735700360` → bar `1735700300` | Add in **high-vol** proxy regime |
| 3 | `1735700450` → bar `1735700300` (`j_bar_latency_sec=150`) | Second add shares **same** bar as leg 2 (same `j_bar_utc` / `t_*`); latency reflects `d_time_utc - j_bar_utc` |
| 4 | `1735700660` → bar `1735700600` | Partial in **ranging** proxy + weaker consensus strength |
| 5 | `1735700960` → bar `1735700900` | Final in **low-vol** proxy |

## Distinction vs other cases

- **Case_007:** partial-close **identity**; fixture telemetry uniform across legs.
- **Case_008:** lifecycle **seq + group** on uniform-ish context bars.
- **Case_009:** proves **attribution** does not collapse to a single bar or “position summary”; context tracks **each deal’s clock**.

## Output model

- **Five** joined slim rows + **`x_lifecycle_group_id`** + **`x_lifecycle_seq`** (same mechanism as Case_008).
- **Not** a production position rollup engine.

## Pass criteria

- Byte match to `expected_joined.csv`.
- Journal: `[JOIN_VALIDATION] STATUS=PASS rows=5 multi_deal_attribution_validated=1`.

## Deploy

Copy under `Terminal\Common\Files\AurumSynapse\TelemetryFixtures\` per parent `README.md`.
