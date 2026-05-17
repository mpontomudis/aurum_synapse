# GOVERNANCE_EVIDENCE_INTEGRATION_V1

## Purpose

Deterministic bridge from **POSITION_ROLLUP_V1 → SURVIVABILITY → TOXICITY → CAUSAL** into the **existing governance kernel** (`SGovL0SnapshotIntegerV1` + shadow tick) **without** changing FSM semantics, policy hashing, or `GOV_EVT_*` pipe contracts.

## Layout (`TelemetryAnalytics/GovernanceEvidenceIntegrationV1/`)

| File | Role |
|------|------|
| `GovernanceL0RuntimeEvidenceV1.mqh` | Canonical `SGovL0RuntimeEvidenceV1` (integer milli 0..10000 + counters + epoch). |
| `GovernanceEvidenceNormalizerV1.mqh` | Clamp / scale helpers; saturating add. |
| `GovEvidenceFromRollupV1.mqh` | Rollup → lifecycle id, campaign id string, duration, drawdown pressure proxy. |
| `GovEvidenceFromSurvivabilityV1.mqh` | Survivability metrics → survivability / execution-quality milli. |
| `GovEvidenceFromToxicityV1.mqh` | Toxicity metrics → toxicity / volatility / recovery-instability milli. |
| `GovEvidenceFromCausalValidationV1.mqh` | Causal diagnostics → causal / structural / governance-confidence milli. |
| `GovernanceEvidenceFusionV1.mqh` | Single fusion entry: runs analytics once, applies adapters, dominance + fusion bitmask. |
| `GovernanceRegimeClassifierV1.mqh` | `ENUM_GOV_MARKET_REGIME_V1` from fused evidence + simple hysteresis dwell. |
| `GovernanceCampaignMemoryV1.mqh` | Deterministic counters (toxic streaks, structural persistence, EWMA of surv). |
| `GovernanceEvidenceAttribTelemetryV1.mqh` | **New** `GOV_ATTRIB_V1` pipe line (schema 1.0); does **not** alter `GOV_EVT_V1`. |
| `GovernanceEvidenceIntegrationV1.mqh` | `BuildFromDealsUtf8`, `MapRuntimeEvidenceToL0`, `ShadowTickFromDealsUtf8`. |

## Integration API

1. **Offline / replay:** `GovEvidenceIntegrationV1_BuildFromDealsUtf8(dealsUtf8Lf, epoch, …)`  
   - Builds rollup → runs survivability, toxicity, causal once each → fuses → fills `SGovL0RuntimeEvidenceV1`.

2. **Map to kernel L0:** `GovEvidenceIntegrationV1_MapRuntimeEvidenceToL0(evidence, memory, gov_epoch, l0)`  
   - Produces `SGovL0SnapshotIntegerV1` compatible with existing `GovernanceShadowTickV1` / FSM.

3. **One-call shadow:** `GovEvidenceIntegrationV1_ShadowTickFromDealsUtf8(…, SGovShadowTickAuxOutV1 &aux)`  
   - Runs fusion + memory + regime + optional `GOV_ATTRIB_V1` line appended **after** governance event block (newline-separated). Writes fusion `causal_explanation_code` into `l0` before the kernel step; fills `aux` for orchestration consumers.

## Telemetry

- **`GOV_EVT_*`**: unchanged (19 fields, existing readers).
- **`GOV_ATTRIB_V1`**: new prefix, **15** pipe-separated ASCII fields, UTF-8, LF-terminated when appended.  
  Readers should accept **multiple line types** in the governance event buffer.

## Determinism

Same deals UTF-8, same policy snapshot, same memory/regime dwell inputs → same fused evidence, same fingerprint (`FingerprintHex8`), same `GOV_ATTRIB_V1` line, same mapped L0 integers.

## Future work

- Plumb **live** `SRollupDealStepV1[]` from production join path instead of UTF-8 deals string.
- Edge-triggered lockdown counters in `GovernanceCampaignMemoryV1` (requires GS transition callback).
- Optional correlation of `GOV_ATTRIB_V1.regime` with existing `ENUM_REGIME_STATE_V1` shell.
