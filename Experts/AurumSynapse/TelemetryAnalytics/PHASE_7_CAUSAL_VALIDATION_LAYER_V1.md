# PHASE 7 — CAUSAL_VALIDATION_LAYER_V1

**Status:** **COMPLETE** — deterministic causal explanation layer (append-only diagnostics). **Harness:** `Tests/TestCausalValidationLayerV1.mq5`. **Tag:** `PHASE_7_CAUSAL_VALIDATION_LAYER_COMPLETE`. **Roadmap:** `Tests/POST_COMPLETION_VALIDATION_ROADMAP.md` (Phases 4–7).

## 1. Architecture

```
POSITION_ROLLUP_V1 (snapshot)
        │
        ├──► SurvivabilityAnalyticsV1_AnalyzeCampaign   (read-only)
        ├──► ToxicityAnalyticsV1_AnalyzeCampaign        (read-only)
        │
        └──► CausalValidationLayerV1_AnalyzeCampaign
                 ├─ reduction geometry (StepReductions, read-only)
                 ├─ deterioration mode (gradual / accelerating / unstable / spiral)
                 ├─ recovery failure class (from toxicity fake + survivability tail)
                 ├─ panic role (terminal effect vs early vs mid-chain vs ambiguous)
                 ├─ collapse shape (gradual / sudden / mixed)
                 ├─ causal class + ordered causal_chain string
                 ├─ explanation_primary tag
                 └─ causal_confidence (integer 0–100, rule-based)
```

No writes to rollup steps, survivability outputs, or toxicity outputs; the causal struct is a **new** interpretation only.

## 2. Causal philosophy

- **Causal ≠ correlation:** tags encode **ordered mechanisms** allowed by the deterministic sequence (e.g. relief → relapse), not statistical co-movement.
- **Causal ≠ PnL:** no profit/loss inputs; only lifecycle reduction path and upstream observability enums.
- **Panic role:** distinguishes *end-gated* liquidation pressure vs *early* or *mid-chain* acceleration using **share of reductions** in early vs late windows — rule-based, not inferential AI.

## 3. Attribution law (deterministic)

| Sub-model | Inputs |
|-----------|--------|
| `deterioration_mode` | Toxicity spiral flag, instability, interior peak count, cascading half-means |
| `recovery_failure` | Fake-recovery flag + failed intensity + survivability state + instability |
| `collapse_shape` | Step count, toxicity collapsing signal, max step intensity vs mean reduction |
| `panic_causal_role` | `flag_panic_unwind` + early/late reduction mass on `red[]` |
| `causal_class` | Fixed-priority lattice (panic collapse → fake recovery → structural spiral → cascading → orderly stress → toxic continuation → terminal exhaustion) |

## 4. Causal class enum

| Class | Intended reading |
|-------|---------------------|
| `CAUSAL_V1_ORDERLY_DETERIORATION` | Survivability stress with **mild** toxicity band (watchlist/unstable), no fake/spiral/cascade/panic-collapse |
| `CAUSAL_V1_CASCADING_DEGRADATION` | Second-half mean reduction clearly exceeds first half (accelerating closure intensity) |
| `CAUSAL_V1_FAILED_RECOVERY_LOOP` | Toxicity fake-recovery / relapse geometry |
| `CAUSAL_V1_TOXIC_CONTINUATION` | Toxicity `TOXIC` or `TERMINAL` after higher-priority patterns ruled out |
| `CAUSAL_V1_PANIC_COLLAPSE` | Toxicity `COLLAPSING` or short-path panic-collapse signature |
| `CAUSAL_V1_STRUCTURAL_FAILURE` | Spiral deepening or repeated interior peaks + instability without fake loop |
| `CAUSAL_V1_TERMINAL_EXHAUSTION` | Benign or low-stress terminal band |

## 5. Explanation model

- **`causal_chain`:** single canonical `|`‑separated token stream built in fixed order (lifecycle → survivability band → deterioration → recovery failure → contamination → panic role → collapse tempo → termination).
- **`explanation_primary`:** one stable tag (e.g. `RECOVERY_RELAPSE_AFTER_SHORT_RELIEF`, `PANIC_UNWIND_ACCELERATED_FAILURE`, `ORDERLY_TERMINATION`) chosen by causal class + panic role + flags.

## 6. Causal confidence (0–100)

Integer score from: deal count (clarity), toxicity/survivability tension, chain token count, dominant pattern flags (fake/spiral/panic-collapse), benign terminal alignment. **No** randomness, **no** learned weights.

## 7. Deterministic guarantees

Same `camp` + `steps[]` → same `SCausalDiagnosticsV1` and same `CausalValidationLayerV1_DiagnosticFingerprint` string.

## 8. Future compatibility

Add new **trailing** tokens to `causal_chain` or extend `SCausalDiagnosticsV1` with defaulted fields; avoid redefining existing class priority without version bump.

## 9. Non-goals

Governance, execution mutation, ML attribution, changes to join/fixtures/survivability/toxicity headers.
