# PHASE 6 — TOXICITY_ANALYTICS_V1

**Status:** **COMPLETE** — deterministic toxicity diagnostics (lifecycle-centric). **Harness:** `Tests/TestToxicityAnalyticsV1.mq5`. **Roadmap:** `Tests/POST_COMPLETION_VALIDATION_ROADMAP.md` (Phases 4–7).

## 1. Role

Deterministic **observability and diagnostic** layer on top of:

- `POSITION_ROLLUP_V1` (lifecycle / exposure continuity)
- `SURVIVABILITY_ANALYTICS_V1` (read-only; contract unchanged)

**Not** in scope: adaptive governance, execution mutation, ML, probabilistic scoring, join/serialization changes, golden fixtures, or edits to `SurvivabilityAnalyticsV1.mqh`.

## 2. Architecture

```
UTF-8 deals (LF) ──► PositionRollupV1_BuildFromDealsUtf8Lf
                           │
                           ├─► SurvivabilityAnalyticsV1_AnalyzeCampaign (read-only)
                           │
                           └─► ToxicityAnalyticsV1_AnalyzeCampaign
                                    ├─ per-step reductions (reuse Survivability helper)
                                    ├─ instability / local-maxima / relapse geometry
                                    ├─ max step intensity vs mean reduction
                                    └─ rule-based ENUM_TOXICITY_STATE_V1 + toxicity_score
```

Toxicity **never** mutates `steps`, `camp`, or survivability outputs; it only **reads** them and **appends** its own metrics/state.

## 3. Toxicity philosophy

- **Toxicity ≠ loss.** PnL is not an input. Signals come from **structural** behavior of the exposure-reduction path (oscillation, relapse after relief, deepening liquidation waves, disorderly concentration).
- **Lifecycle-centric.** All metrics derive from ordered rollup steps and cumulative exposure semantics, not isolated candles or single deals in isolation from the campaign.
- **Explainable.** Each state maps to a short deterministic `outExplain` tag.

## 4. Toxicity state model

| State | Meaning (deterministic summary) |
|--------|----------------------------------|
| `TOX_V1_INVALID` | Invalid / inconsistent campaign input |
| `TOX_V1_CLEAN` | No material structural risk flags |
| `TOX_V1_WATCHLIST` | Mild elevation (score / survivability tail risk) |
| `TOX_V1_UNSTABLE` | Irregular reduction structure or repeated interior stress peaks |
| `TOX_V1_TOXIC` | Fake recovery relapse, spiral deepening, or high composite toxicity score |
| `TOX_V1_COLLAPSING` | Very short path with extreme concentration **or** few steps with intensity+concentration breach |
| `TOX_V1_TERMINAL` | Flat lifecycle but **panic-style** unwind signature (e.g. high concentration with multi-step tail) |

Priority is **fixed top-down** in `ToxicityAnalyticsV1_ClassifyState` (collapsing → terminal → toxic → unstable → watchlist → clean).

## 5. Metric definitions

| Field | Definition |
|--------|------------|
| `instability_persistence` | Share of adjacent steps where \|Δreduction\| exceeds 0.44× mean reduction (clamped 0..1). |
| `deterioration_repetition` | Count of **strict interior local maxima** in the per-step reduction series (re-surging liquidation waves). |
| `failed_recovery_intensity` | If fake-recovery pattern: normalized `(maxAfterTrough − trough) / sumRed`, else 0. |
| `liquidation_chaos` | Deterministic blend of **max step intensity** (max \|vol\| / mean reduction), `maxConc`, and short-path term. |
| `contamination_depth` | Sum of fixed weights for spiral / fake-recovery / panic flags (+ small spiral depth term), clamped 0..1. |
| `toxicity_score` | Integer 0..100 from fixed linear combination of the above (no randomness). |
| `max step intensity` (internal) | `max_i |d_volume_i| / (mean(reduction)+ε)` — comparable across campaign lengths; **not** the same as survivability’s `av/prevRem` bound. |

Flags: `flag_fake_recovery`, `flag_spiral_deterioration`, `flag_panic_unwind` (rule-based booleans).

## 6. Invariants

- Read-only on `SRollupPositionCampaignV1`, `SRollupDealStepV1[]`, and survivability outputs.
- No writes to rollup buffers, join outputs, or disk fixtures.
- Invalid rollup → `AnalyzeCampaign` returns `false`; state remains `TOX_V1_INVALID` on failure paths as documented in code.

## 7. Deterministic guarantees

Same deals UTF-8 + same rollup build → same toxicity metrics, flags, score, state, and explain tag (replayable; no clocks, no network).

## 8. Future compatibility

- Additional **orthogonal** flags or metrics can be appended to `SToxicityMetricsV1` with defaults without changing existing rules (prefer new fields over changing score weights in-place once frozen).
- Optional wiring to telemetry sinks stays outside this header.

## 9. Non-goals

Autonomous execution, adaptive governance, self-learning, AS_JOINED_V2, join orchestration changes, mutating survivability history.
