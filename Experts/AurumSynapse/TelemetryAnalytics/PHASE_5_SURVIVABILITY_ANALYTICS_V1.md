# PHASE 5 — SURVIVABILITY_ANALYTICS_V1 — Foundation Observability

**Status:** **COMPLETE** — deterministic observability layer (no execution mutation, no ML). **Harness:** `Tests/TestSurvivabilityAnalyticsV1.mq5`. **Roadmap:** `Tests/POST_COMPLETION_VALIDATION_ROADMAP.md` (Phases 4–7).  
**Builds on:** `POSITION_ROLLUP_V1` (`PositionRollupV1.mqh`) — lifecycle + exposure path  
**Does not modify:** Golden Suite V1, `JoinValidationPrototype.mqh`, `ProductionJoinEngine.mqh`, fixtures, freeze docs, `AS_JOINED_V1`

---

## 1. Architecture

```
deals.csv (UTF-8) ──► PositionRollupV1_BuildFromDealsUtf8Lf
                              │
                              ▼
              SRollupPositionCampaignV1 + SRollupDealStepV1[]
                              │
                              ▼
              SurvivabilityAnalyticsV1_AnalyzeCampaign
                              │
                              ▼
        SSurvivabilityMetricsV1 + ENUM_SURVIVABILITY_STATE_V1 + explain tag
```

**Philosophy:** answer “how did this lifecycle **live**, **stress**, **ease**, or **terminate**?” using **only** deterministic geometry of staged reductions (volumes, remaining exposure ladder, concentration, liquidation spikes, third-wise pacing).

---

## 2. Survivability state model (rule-based)

| State | Meaning (V1) |
|-------|----------------|
| `INVALID` | Rollup campaign invalid / empty steps. |
| `STABLE` | Single-shot terminal flat, low spike. |
| `PRESSURED` | Rollup reports active non-flat tail (reserved for future partial-campaign inputs). |
| `DEGRADED` | High concentration of reduction in few steps (`max step / total`). |
| `CRITICAL` | Extreme liquidation spike (`|vol| / remaining_before` cap breach). |
| `RECOVERING` | Terminal flat with **orderly deceleration** — last third mean reduction < 75% of first third (easing into flat). |
| `TERMINATED` | Multi-step orderly terminal flat without special easing/degradation flags. |

Transitions are **not** a hidden Markov model: **one pass** classification with a **fixed priority ladder** (critical > degraded > recovering > stable/terminated).

---

## 3. Metric definitions

| Metric | Definition |
|--------|------------|
| `current_exposure_load` | `exposure_remaining` after final step (rollup). |
| `cumulative_exposure_pressure` | Sum of per-step reductions in `exposure_remaining`. |
| `exposure_decay_rate` | Mean reduction per step (`pressure / n`). |
| `exposure_concentration` | `max(|d_volume|) / total_abs_volume`. |
| `staged_liquidation_intensity` | Fraction of steps with non-trivial reduction. |
| `max_liquidation_spike_ratio` | `max_i |vol_i| / (remaining_before_i + ε)`. |
| `first_third_mean_reduction` / `last_third_mean_reduction` | Mean reductions in first / last index third (requires `n ≥ 3`). |
| `survivability_score` | Integer **0–100** from fixed rule table (concentration/spike/stage count/terminal shape). **Not** a learned weight. |

---

## 4. Invariants

1. **Deterministic** — same campaign + steps → identical metrics, score, state, explain tag.  
2. **Read-only** — `AnalyzeCampaign` does not mutate input structs.  
3. **Lifecycle-centric** — requires valid `POSITION_ROLLUP_V1` campaign; no candle-only analytics.  
4. **Append-only discipline** — analytics outputs are new structs/strings; upstream rollup snapshots stay immutable in caller space.  
5. **No join / serialization drift** — module never includes joined CSV serialization.

---

## 5. Non-goals (V1)

- Adaptive governance, execution hooks, auto position changes.  
- ML / Bayesian / neural survivability.  
- Toxicity scoring (separate future layer).  
- Rewriting lifecycle history inside `PositionRollupV1`.

---

## 6. Future compatibility

- Feed **signed** or **profit-conditioned** stress channels beside volume ladder (V1.1+).  
- Map states to **risk bands** for dashboards while keeping rule ladder versioned (`SURVIVABILITY_ANALYTICS_V1` tag in explain string optional later).

---

## 7. References

- `PHASE_4_POSITION_ROLLUP_V1_FORMALIZATION.md`  
- `PositionRollupV1.mqh`  
- `PHASE_3B_GOLDEN_SUITE_FREEZE_V1.md`  

**Document ID:** `PHASE_5_SURVIVABILITY_ANALYTICS_V1`  
**Code module:** `SurvivabilityAnalyticsV1.mqh`
