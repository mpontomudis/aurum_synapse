# PHASE 8A — GOVERNANCE STATE MACHINE RUNTIME (SHADOW MODE)

**Document type:** Implementation specification (code-facing)  
**Status:** V1 — binds engineering to frozen normative sources  
**Normative references (frozen — do not amend via this document):**

- `PHASE_8_GOVERNANCE_ADAPTIVE_INTELLIGENCE_ARCHITECTURE.md` — hierarchy, precedence, lag-1, single-writer, replay semantics  
- `PHASE_8_GOVERNANCE_POLICY_TABLES_V1.md` — thresholds, hysteresis, scaling, aggregation, quarantine, regime, checksum rules  

**Scope gate (8A):** `GOVERNANCE_SHADOW_MODE = 1` — **compute + append-only telemetry only**. No execution authority, no order/risk/lot/entry/exit mutation, no wiring into `AS_JOINED_V1`, no modification of `CAUSAL_VALIDATION_LAYER_V1`, `SURVIVABILITY_ANALYTICS_V1`, `TOXICITY_ANALYTICS_V1`, `POSITION_ROLLUP_V1` beyond **read-only** consumption of their published structs/rows.

**Non-goals (8A):** L2 risk envelope application, L6 curve application to live proposals, L7 lifecycle permission enforcement, L9 `AS_JOINED_V2` sidecar production merge.

---

## 1. Architecture-aligned implementation plan

### 1.1 Objective

Deliver `GOVERNANCE_STATE_MACHINE_V1`: a **single-writer**, **integer-only**, **replay-safe** L1 runtime that:

- Computes `GS_EVIDENCE_MS` per policy §2.3 (max of scaled integer components).  
- Applies **hysteresis**, **dwell**, **cooldown lock**, and **asymmetric de-escalation** per policy §3.  
- Resolves **GS_SURVIVAL** vs **GS_LOCKDOWN** overlap via policy §3.5 latch (not ad hoc).  
- Implements **GS_RECOVERY** entry/exit exactly per policy §3.5.  
- Evaluates **quarantine severity** per policy §6 (candidate rules in fixed `rule_id` order; max then hysteresis).  
- Evaluates **REGIME_SCORE_MS** and regime hysteresis per policy §8 (lag-1 safe inputs only).  
- Evaluates **CONF_RAW → CONF_EWMA → CONF_PUBLISHED** per policy §4.  
- Emits **one append-only governance telemetry record per `gov_epoch`**.

### 1.2 Sequencing (mandatory build order)

| Step | Module cluster | Rationale |
|------|----------------|-----------|
| S0 | Policy bundle artifact + loader + checksum | All constants and tables are **data**, not scattered literals. |
| S1 | Integer primitives (`clamp`, `floor_div_signed`, `max_chain`) | Shared deterministic kernels; audited once. |
| S2 | `GS_EVIDENCE` engine | Pure function of L0 + CONF published + quarantine; feeds L1. |
| S3 | Latch library (toxicity, survivability, confidence, GS band, quarantine step) | Reusable; tested in isolation. |
| S4 | L8 regime score + band mapper + `dwell_regime` + Δ threshold | Feeds CONF + GS_RECOVERY + quarantine rules. |
| S5 | L4 quarantine evaluator (rules Q1–Q5 order) + severity hysteresis | Precedence: max candidate → dwell filter §6.3. |
| S6 | L5 confidence pipeline | Produces `CONF_PUBLISHED_MS` consumed by evidence + RECOVERY gates. |
| S7 | L1 GS transition engine + precedence matrix | Single writer; reason codes; no float. |
| S8 | Telemetry serializer (canonical field order, stable delimiters) | Byte-stable golden vectors. |
| S9 | Shadow orchestrator (`GovernanceShadowTickV1`) | Composes S1–S8; **no outputs** except telemetry + in-memory debug struct. |
| S10 | Fixtures + harness + CI matrix | Replay locks. |

### 1.3 Invariants (non-negotiable)

| ID | Invariant |
|----|-----------|
| I1 | **Single writer:** only `GovernanceStateMachineV1_Step` mutates `gs_current` and latch memory for L1. |
| I2 | **Integer discipline:** all policy scalars in runtime snapshot are integral; no `double` in hot path. |
| I3 | **No hidden mutation:** all cross-epoch state lives in one `SGovernanceRuntimeStateV1` blob; cleared only via explicit `Init` or replay loader. |
| I4 | **Lag-1:** quarantine/GS/confidence consumers read **prior-epoch published** values where architecture forbids same-epoch feedback (explicit fields `*_prev` in state). |
| I5 | **Append-only telemetry:** `GovernanceTelemetryV1_Append` never seeks, never truncates; one line per epoch. |
| I6 | **Shadow:** `#if GOVERNANCE_SHADOW_MODE` gates all side effects to telemetry; no calls into order send, position modify, or risk application APIs. |

---

## 2. Runtime module hierarchy

```
GovernanceShadowTickV1          ← orchestrator (8A only)
├── GovernancePolicyLoaderV1    ← immutable snapshot + semver + SHA-256
├── GovernancePolicyPrimitivesV1 ← clamp, div, min/max chains
├── GovernanceConfidenceV1      ← L5: RAW / EWMA / PUBLISH
├── GovernanceRegimeV1          ← L8: scores + band + hysteresis
├── GovernanceQuarantineV1      ← L4: rules Q1..Q5 + severity hysteresis
├── GovernanceEvidenceV1        ← GS_EVIDENCE_MS = max(E_*)
├── GovernanceHysteresisV1      ← reusable latch + dwell + cooldown
├── GovernanceStateMachineV1    ← L1: escalation / de-escal / RECOVERY
└── GovernanceTelemetryV1       ← canonical serialization
```

**Dependency rule:** downward only (orchestrator → leaves). Leaves **must not** include each other circularly. L0 readers are **const** references into existing analytics outputs.

---

## 3. File structure recommendations

Under `Experts/AurumSynapse/TelemetryAnalytics/`:

| Path | Role |
|------|------|
| `GovernanceStateMachineV1/GovernanceTypesV1.mqh` | Enums: `ENUM_GS_STATE_V1`, `ENUM_GS_TRANSITION_REASON_V1`, `ENUM_REGIME_STATE_V1`, `ENUM_CONF_STATE_V1`; packed state structs. |
| `GovernanceStateMachineV1/GovernancePolicyBundleV1.mqh` | Struct mirror of policy bundle rows; **no** runtime mutation. |
| `GovernanceStateMachineV1/GovernancePolicyLoaderV1.mqh` | Load `policy.tab` / embedded bytes; semver parse; SHA-256 canonical sort; fail closed. |
| `GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh` | Deterministic math helpers. |
| `GovernanceStateMachineV1/GovernanceConfidenceV1.mqh` | Policy §4. |
| `GovernanceStateMachineV1/GovernanceRegimeV1.mqh` | Policy §8. |
| `GovernanceStateMachineV1/GovernanceQuarantineV1.mqh` | Policy §6. |
| `GovernanceStateMachineV1/GovernanceEvidenceV1.mqh` | Policy §2.3. |
| `GovernanceStateMachineV1/GovernanceHysteresisV1.mqh` | Generic dwell latch + cooldown lock. |
| `GovernanceStateMachineV1/GovernanceStateMachineV1.mqh` | L1 transitions + precedence. |
| `GovernanceStateMachineV1/GovernanceTelemetryV1.mqh` | Append-only writer + field order. |
| `GovernanceStateMachineV1/GovernanceShadowTickV1.mqh` | `GOVERNANCE_SHADOW_MODE` orchestration. |

Tests:

| Path | Role |
|------|------|
| `Experts/AurumSynapse/Tests/TestGovernanceStateMachineV1.mq5` | Unit + replay driver. |
| `Experts/AurumSynapse/Tests/Fixtures/GovernanceReplay_V1/` | Frozen inputs + expected telemetry hashes/lines (see §8–9). |

**Policy artifact (published):** `MQL5/Files/AurumSynapse/policy/GOV_POLICY_<YYYYMMDD>_<SEQ4>/<SEMVER>/policy.tab` (UTF-8, sorted keys, checksum line excluded from hash input per policy §9.1).

---

## 4. Deterministic data flow

### 4.1 Per-epoch pipeline (single thread)

1. **Input bind (read-only):** ingest L0 snapshot: `SToxicityMetricsV1`, `SSurvivabilityMetricsV1`, causal published class/rank, rollup-derived integers needed by quarantine rules (e.g. `deterioration_repetition`, `instability_persistence_ms`), optional `EQ_MS`, `RF_PENALTY_MS`, flags for fake recovery indicator.  
2. **Epoch index:** `gov_epoch := gov_epoch_prev + 1` (64-bit; saturates at `LLONG_MAX` with hard assert in test).  
3. **L3 ring (optional in 8A):** if degradation memory is required for quarantine Q3, either (a) read-only stub zeros in 8A fixtures, or (b) implement minimal ring cursor **without** feeding back to L0 — prefer (a) for 8A unless Q3 scenarios are in scope.  
4. **L8 regime:** compute `REGIME_SCORE_MS`, apply `|Δ| ≥ 30` and `dwell_regime = 2`; emit `REGIME_STATE`.  
5. **L4 quarantine:** evaluate Q1–Q5 in ascending `rule_id`; take **max** candidate severity; apply `dwell_q_on`, `dwell_q_off`, one-step downgrade per policy §6.3.  
6. **L5 confidence:** compute `CONF_RAW_MS` (integer division toward −∞ per policy §4.1); update `CONF_EWMA_MS`; update `CONF_PUBLISHED_MS` per §4.3.  
7. **L1 evidence:** `GS_EVIDENCE_MS = max(E_tox, E_surv, E_causal, E_conf, E_q)` with clamping per §2.3.1.  
8. **L1 transitions:** apply toxicity/survivability latches (§3.2–3.3), GS hysteresis matrix (§3.5), overlap resolution for SURVIVAL vs LOCKDOWN, RECOVERY entry/exit, escalation ladder (default no-skip per architecture §2.1.1 except documented P0 — **not in 8A** unless fixture injects P0 flag as read-only input).  
9. **Telemetry:** serialize **after** state commit; include `l0_fingerprint` of canonical L0 bundle bytes.  
10. **Lag-1 publish:** copy `gs_current`, `conf_published`, `quarantine_severity` to `*_prev` slots for next epoch.

### 4.2 Serialization fingerprint

`L0_FINGERPRINT = SHA-256(canonical_L0_key_sorted_UTF8)` — same canonicalization rules as policy bundle (document in code header; frozen in fixture manifest).

---

## 5. Transition flow diagrams (textual)

### 5.1 Escalation ladder (default — architecture §2.1.1)

```
GS_NORMAL ──► GS_CAUTION ──► GS_DEFENSIVE ──► GS_SURVIVAL ──► GS_LOCKDOWN
   │               │                │                 │
   │               │                │                 └── overlap band: policy §3.5 latch picks LOCKDOWN vs SURVIVAL
   │               │                │
   │               │                └── evidence thresholds + dwell_gs_esc
   │               └── evidence / regime / confidence / toxicity latch paths
   └── stable evidence + no latch
```

### 5.2 De-escalation ladder (architecture §2.1.1 + policy §3.5)

```
GS_LOCKDOWN ──┐
GS_SURVIVAL ──┼──► (quarantine_active==0 ∧ REGIME_SCORE_MS<650 ∧ CONF_PUBLISHED_MS≥450 for dwell_recovery_entry=5) ──► GS_RECOVERY
              │
GS_RECOVERY ──► (GS_EVIDENCE_MS<600 for dwell_recovery_exit=3) ──► GS_DEFENSIVE  (never skip to NORMAL)
GS_DEFENSIVE ──► GS_CAUTION ──► GS_NORMAL
              (each step: GS_EVIDENCE_MS < current_lo − HYST_GS_MS for dwell_gs_deesc=3)
```

### 5.3 Precedence decision tree (same epoch, policy §1.2 + architecture §1.2)

```
IF external_hard_invariant_triggered (out-of-scope flag, read-only)
   THEN respect P0 (telemetry only in 8A)
ELSE IF GS_LOCKDOWN latch conditions satisfied
   THEN GS_LOCKDOWN (P1)
ELSE IF GS_SURVIVAL conditions satisfied AND not superseded by LOCKDOWN latch
   THEN GS_SURVIVAL (P2)
ELSE IF quarantine_severity == 4 (lock bias)
   THEN enforce quarantine precedence over lower GS (P3) — telemetry records severity + GS
ELSE
   evaluate DEFENSIVE / CAUTION / NORMAL / RECOVERY per tables
ENDIF
```

### 5.4 Transition matrix (states × allowed moves)

Rows = `from`, columns = `to`. `1` = permitted if policy gate + dwell satisfied; `0` = forbidden.

| from \\ to | N | C | D | Sv | Lk | R |
|------------|---|---|---|----|----|---|
| N | 1 | 1 | 1* | 1* | 1* | 0 |
| C | 1 | 1 | 1 | 1* | 1* | 0 |
| D | 0 | 1 | 1 | 1 | 1 | 0 |
| Sv | 0 | 0 | 0 | 1 | 1 | 1 |
| Lk | 0 | 0 | 0 | 0 | 1 | 1 |
| R | 0 | 0 | 1 | 0 | 0 | 1 |

\*Escalation may only skip rungs where architecture explicitly allows P0 tripwire; **8A default matrix disables skip** unless `FIXTURE_FLAG_ALLOW_SKIP=1` in harness-only builds (not for production).

Legend: N=`GS_NORMAL`, C=`GS_CAUTION`, D=`GS_DEFENSIVE`, Sv=`GS_SURVIVAL`, Lk=`GS_LOCKDOWN`, R=`GS_RECOVERY`.

---

## 6. Telemetry schema

### 6.1 Record type

**One ASCII line per epoch**, UTF-8, `\n` terminated, **no spaces** unless values are string (none in 8A). Delimiter: `|` (pipe).

### 6.2 Field order (canonical — byte-stable)

| # | Field | Type | Notes |
|---|--------|------|-------|
| 1 | `gov_epoch` | `uint64` | Monotone |
| 2 | `gs_previous` | `uint8` | Enum ordinal |
| 3 | `gs_current` | `uint8` | Enum ordinal |
| 4 | `transition_reason` | `uint16` | `ENUM_GS_TRANSITION_REASON_V1` |
| 5 | `evidence_ms` | `uint16` | `0..1000` |
| 6 | `toxicity_ms` | `uint16` | `E_tox` |
| 7 | `survivability_ms` | `uint16` | `E_surv` |
| 8 | `confidence_ms` | `uint16` | `E_conf` component |
| 9 | `quarantine_severity` | `uint8` | `0..4` |
| 10 | `policy_id` | `string` | As policy §1.3 |
| 11 | `policy_semver` | `string` | `MAJOR.MINOR.PATCH` |
| 12 | `policy_checksum` | `hex64` | SHA-256 lowercase |
| 13 | `l0_fingerprint` | `hex64` | SHA-256 lowercase |

**Optional trailing fields (MINOR+ only):** append after 13 with `|key=value` pairs sorted by key for forward compatibility.

### 6.3 Reason code allocation (illustrative — freeze at implementation)

| Code | Meaning |
|------|---------|
| 0 | `TR_NONE` — no transition |
| 1 | `TR_EVIDENCE_ESCALATE` |
| 2 | `TR_EVIDENCE_DEESCALATE` |
| 3 | `TR_QUARANTINE_MAX` |
| 4 | `TR_RECOVERY_ENTRY` |
| 5 | `TR_RECOVERY_EXIT_TO_DEFENSIVE` |
| 6 | `TR_LOCKDOWN_LATCH` |
| 7 | `TR_SURVIVAL_LATCH` |
| 8 | `TR_REGIME_FORCED` |
| 9 | `TR_CONF_FORCED` |
| 10 | `TR_DWELL_BLOCKED` — attempted transition vetoed (still log if `LOG_VETO=1` in harness) |

---

## 7. Replay strategy

| Mechanism | Description |
|-----------|-------------|
| **Frozen policy bytes** | Harness loads `POLICY_CHECKSUM_REF` from fixture manifest; loader refuses mismatch. |
| **Epoch loop** | For `epoch in [0,N)`, apply fixture input row → step FSM → compare full telemetry line **string equality** (byte-stable). |
| **Deterministic tie-break** | All internal sorts use `(key, rule_id)` lexicographic order per policy §0. |
| **Lag-1 replay** | Fixture provides columns for `prev_*` or harness runs two-pass self-check (odd epochs feed prior outputs). |
| **Golden hash** | Optional second check: SHA-256 of concatenated lines must match `EXPECTED_TRANSCRIPT_HASH`. |

---

## 8. Fixture strategy

Root: `Tests/Fixtures/GovernanceReplay_V1/`

Each scenario directory:

```
<SCENARIO>/
  manifest.json        # policy_id, semver, checksum, expected_transcript_hash (optional)
  inputs.csv           # one row per gov_epoch; canonical column order documented in README
  expected.telemetry   # exact line-per-line expected output (optional if hash-only)
```

### 8.1 Scenario catalog (mandatory)

| Scenario | Stress intent | Primary gates |
|----------|---------------|---------------|
| `S01_stable_market` | Low tox, high surv, benign causal | Stay `GS_NORMAL`, no quarantine |
| `S02_volatile_market` | `REGIME_VOLATILE` latched | `GS_CAUTION` path, regime hysteresis |
| `S03_toxicity_escalation` | tox latch ON dwell | Escalate toward DEFENSIVE/SURVIVAL per evidence |
| `S04_survivability_collapse` | surv latch ON | `E_surv` drives evidence max |
| `S05_failed_recovery_loop` | causal `FAILED_RECOVERY` rank | `E_causal`, RF penalty, CONF drop |
| `S06_panic_collapse` | causal `PANIC_COLLAPSE` / `STRUCTURAL_FAILURE` | Quarantine Q2, possible LOCKDOWN path |
| `S07_quarantine_escalation` | severity ramp 0→4 with dwell_q_on/off | Step-down ≤1 level per dwell_q_off |
| `S08_recovery_stabilization` | from SURVIVAL/LOCKDOWN into RECOVERY then DEFENSIVE | Never skip to NORMAL |
| `S09_oscillating_noise` | square-wave tox/surv around thresholds | Assert max transition count + terminal band |

### 8.2 Column order for `inputs.csv` (normative for harness)

`epoch,toxicity_score,survivability_score,causal_rank,quarantine_active_seed,conf_raw_override_flag,conf_raw_ms,eq_ms,rf_penalty_ms,fake_recovery_flag,deterioration_repetition,instability_persistence_ms,gs_tripwire_lockdown_flag`

Unused fields zero; `conf_raw_override_flag=1` allows direct injection for isolated CONF tests (documented only in test harness, not production).

---

## 9. Test matrix

| ID | Test | Pass criterion |
|----|------|----------------|
| T1 | Policy loader semver invalid | Deterministic failure, no partial state |
| T2 | Policy loader checksum mismatch | Refuse load |
| T3 | Evidence max semantics | Hand-computed `max(E_*)` for 10 vectors |
| T4 | Overflow clamp | Inputs at 10_000 map to 1000 without wrap |
| T5 | Toxicity latch hysteresis | ON≥70, OFF≤55, dwell 2/4, cooldown 1 |
| T6 | Survivability latch | ON≤45, OFF≥58, dwell 2/5 |
| T7 | GS de-esc hysteresis | `< lo − 80` for 3 epochs |
| T8 | RECOVERY entry | Only from Sv/Lk; quarantine 0; regime<650; conf≥450; 5 epochs |
| T9 | RECOVERY exit | evidence<600 for 3 epochs → DEFENSIVE only |
| T10 | Quarantine Q-rule order | Lower `rule_id` does not steal max from higher when both fire |
| T11 | Regime Δ guard | `|Δ|<30` does not change band |
| T12 | CONF publish dwell | `PUBLISH_DWELL=1` + `STAB_DELTA_MS=25` |
| T13 | Oscillation stress | transitions ≤ `B_cap` for `S09` |
| T14 | Byte-stable telemetry | string-compare golden file |
| T15 | Lag-1 self-consistency | epoch `t` does not read `GS[t]` as input |

---

## 10. Shadow rollout plan

| Phase | Environment | Behavior |
|-------|-------------|----------|
| R0 | Local + Strategy Tester | `GOVERNANCE_SHADOW_MODE=1`; telemetry file under `MQL5/Files/.../governance_shadow/` |
| R1 | Internal forward test | Same; compare transcript hash to golden nightly |
| R2 | Pilot accounts | Shadow only; **no** bridge to order/risk modules |
| R3 | Sign-off gate | Architecture + policy owners approve transcript diffs on version bump |
| R4 | Pre-8B | Introduce read-only dashboard consumer; still no execution |

**Exit criteria for 8A complete:** T1–T15 green on reference bundle `GOV_POLICY_*` / `1.0.0` with published checksum; fixture suite `S01–S09` green; `S10` bounded oscillation.

---

## Appendix A — Policy constant excerpt (reference only; authoritative source is policy MD)

Values below are **copied** from `PHASE_8_GOVERNANCE_POLICY_TABLES_V1.md` for engineering convenience; **loader** remains authoritative at runtime.

- `GS_EVIDENCE` components: `E_tox = clamp(toxicity_score×10)`, `E_surv = clamp(1000−surv×10)`, `E_causal` rank map per §2.3.1, `E_conf = clamp(1000−CONF_PUBLISHED_MS)`, `E_q = quarantine_severity×250`.  
- `HYST_GS_MS = 80`, `dwell_gs_esc = 1`, `dwell_gs_deesc = 3`.  
- `dwell_recovery_entry = 5`, `dwell_recovery_exit = 3`, `REGIME_SCORE_MS < 650`, `CONF_PUBLISHED_MS ≥ 450`, `quarantine_active = 0` for RECOVERY entry.  
- Toxicity latch: ON≥70, OFF≤55, esc 2, deesc 4, cooldown_lock 1.  
- Survivability latch: ON≤45, OFF≥58, esc 2, deesc 5.  
- Quarantine dwell: `dwell_q_on=2`, `dwell_q_off=5`.  
- Regime hysteresis: `|Δ|≥30`, `dwell_regime=2`.  
- CONF: `STAB_DELTA_MS=25`, `PUBLISH_DWELL=1`, EWMA `α=1/4`.

---

**END OF PHASE_8A_GOVERNANCE_STATE_MACHINE_IMPLEMENTATION_SPEC**
