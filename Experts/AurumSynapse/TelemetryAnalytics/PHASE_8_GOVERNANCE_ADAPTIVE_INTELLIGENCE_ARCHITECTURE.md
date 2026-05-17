# PHASE 8 — GOVERNANCE & ADAPTIVE INTELLIGENCE — Architecture Formalization (Production-Grade)

**Document type:** Architecture specification (design-only; no implementation mandate in this file)  
**Status:** DRAFT — formalization for engineering sign-off before code  
**Depends on (frozen / stable):** Golden Fixture Suite V1; Production Join Engine; `POSITION_ROLLUP_V1`; `SURVIVABILITY_ANALYTICS_V1`; `TOXICITY_ANALYTICS_V1`; `CAUSAL_VALIDATION_LAYER_V1`  
**Non-goals (this phase charter):** ML / neural scoring; probabilistic policy mutation; autonomous execution without explicit bounds; modification of `AS_JOINED_V1` law without `AS_JOINED_V2` versioned migration path

---

## Executive constraints (binding design rules)

| Rule | Meaning |
|------|--------|
| **Deterministic adaptive governance** | Every adaptive output is a **pure function** of bounded telemetry inputs + explicit governance state + versioned policy tables. Same inputs → same outputs (replay-safe). |
| **No oscillation by construction** | State transitions use **hysteresis bands**, **minimum dwell time**, and **single-writer precedence** so classifiers cannot fight in a loop. |
| **Telemetry-driven only** | No latent “market opinion”; inputs are **observed** lifecycle / analytics / execution quality signals already defined in lower layers. |
| **Governance-safe** | Governance **never** rewrites historical truth; it **emits** policy scalars and permissions for **consumers** (risk, execution adapters) that remain separately testable. |
| **Regression-testable** | Every scalar output and state transition is unit-testable from **fixture replay** (offline, no live dependency). |

---

## 1. Governance architecture formalization

### 1.1 Subsystem hierarchy (top → bottom)

```
┌─────────────────────────────────────────────────────────────────────────┐
│ L8  REGIME INTELLIGENCE LAYER (behavioral inference, deterministic scores) │
└───────────────────────────────────┬───────────────────────────────────┘
                                    │ regime_stability_score, fragility, …
┌───────────────────────────────────▼───────────────────────────────────┐
│ L7  ADAPTIVE LIFECYCLE GOVERNOR (campaign-level policy synthesis)      │
└───────────────────────────────────┬───────────────────────────────────┘
                                    │ lifecycle caps, recovery permission
┌───────────────────────────────────▼───────────────────────────────────┐
│ L6  EXECUTION SURVIVABILITY GOVERNOR (continuous scaling outputs)        │
└───────────────────────────────────┬───────────────────────────────────┘
                                    │ risk_scale, lot_throttle, compression
┌───────────────────────────────────▼───────────────────────────────────┐
│ L5  CONFIDENCE THROTTLING ENGINE (aggregation + decay + stabilization)   │
└───────────────────────────────────┬───────────────────────────────────┘
                                    │ conf_state, throttle factors
┌───────────────────────────────────▼───────────────────────────────────┐
│ L4  TOXIC REGIME QUARANTINE (hysteresis + suppression matrix)          │
└───────────────────────────────────┬───────────────────────────────────┘
                                    │ quarantine_level, suppression flags
┌───────────────────────────────────▼───────────────────────────────────┐
│ L3  STRATEGY DEGRADATION MEMORY (deterministic accumulators / profiles)  │
└───────────────────────────────────┬───────────────────────────────────┘
                                    │ degradation signatures, slopes
┌───────────────────────────────────▼───────────────────────────────────┐
│ L2  ADAPTIVE RISK GOVERNOR (portfolio / session risk envelope)           │
└───────────────────────────────────┬───────────────────────────────────┘
                                    │ envelope multipliers, hard ceilings
┌───────────────────────────────────▼───────────────────────────────────┐
│ L1  GOVERNANCE STATE MACHINE (GS_* canonical precedence)               │
└───────────────────────────────────┬───────────────────────────────────┘
                                    │ GS_* is single source of “mode”
┌───────────────────────────────────▼───────────────────────────────────┐
│ L0  CAUSAL + TOXICITY + SURVIVABILITY + ROLLUP (read-only analytics)     │
└─────────────────────────────────────────────────────────────────────────┘
```

**Dependency flow (strictly acyclic):** L0 → L1 → … → L8. **No layer may read “future” governance outputs** (no feedback into causal inputs for the same replay tick without an explicit **lag-1** buffer and version tag).

### 1.2 Precedence model (conflict resolution)

| Priority (high wins on conflict) | Source | Rationale |
|-----------------------------------|--------|-----------|
| **P0** | **Hard safety invariants** (non-negotiable: max loss halt if configured externally, broker rejections — *out of this doc’s scope but must not be bypassed*) | Legal / operational floor |
| **P1** | **`GS_LOCKDOWN`** | Systemic survival |
| **P2** | **`GS_SURVIVAL`** | Campaign / session survival |
| **P3** | **Quarantine active (structural)** | Containment of toxic regime |
| **P4** | **`GS_DEFENSIVE`** | Proactive degradation response |
| **P5** | **`GS_CAUTION`** | Early warning |
| **P6** | **`GS_NORMAL` / `GS_RECOVERY`** | Baseline / controlled unwind |

**Single-writer rule:** Only **L1 (GS FSM)** may change `GS_*`. L4 (quarantine) may **request** escalation; L1 applies it if precedence allows. **No peer-to-peer** state mutation between L4 and L6.

### 1.3 Deterministic ordering (evaluation tick)

Within one **governance evaluation epoch** (e.g. per bar close, per campaign snapshot commit — **fixed in implementation spec**):

1. Ingest **immutable** L0 snapshot: rollup campaign(s), survivability, toxicity, causal diagnostics, execution quality row(s).  
2. Update **L3 degradation memory** (append-only accumulators; bounded windows).  
3. Evaluate **L8 regime intelligence** (scores only).  
4. Evaluate **L4 quarantine** (with hysteresis; outputs **requests**).  
5. Update **L5 confidence** (aggregate + decay).  
6. Evaluate **L1 GS FSM** transitions (using L4 requests + L5 + L8 + hard thresholds).  
7. Compute **L2 risk governor** envelope inside `GS_*` caps.  
8. Emit **L6 survivability governor** continuous outputs.  
9. Emit **L7 lifecycle governor** permissions.  
10. Serialize **L9 ledger row** (`AS_JOINED_V2` or sidecar; see §7) — **append-only**.

### 1.4 Replay safety strategy

| Mechanism | Guarantee |
|-----------|-----------|
| **Versioned policy** | `POLICY_ID` + `POLICY_SEMVER` in every output row; replay uses same policy file bytes. |
| **Input fingerprint** | `L0_FINGERPRINT = hash(canonical serialized L0 bundle)`; governance outputs store fingerprint. |
| **Monotone epoch counter** | `GOV_EPOCH` strictly increasing per evaluation stream; no back-dated writes. |
| **Hysteresis & dwell** | Prevents flip-flop under measurement noise at replay boundaries. |
| **Lag-1 feedback** | If governance affects next-tick telemetry, only **published** scalars from `epoch-1` are visible to analytics re-entry (explicit bus, not hidden globals). |

### 1.5 Conflict resolution strategy (semantic)

- **Causal vs governance:** Causal layer remains **read-only interpretation** of history. Governance **never** edits causal diagnostics.  
- **Toxicity vs survivability:** If signals disagree, **precedence** follows: **quarantine request** > **GS elevation** > **continuous throttle** (L6) before any **binary** permission flip.  
- **Regime vs GS:** `REGIME_*` informs **confidence** and **transition evidence**; **GS_*** remains the **operational mode**. Regime alone cannot lockdown without GS rules agreeing (prevents “indicator lockdown”).

---

## 2. Governance state machine design

### 2.1 Governance states (`GS_*`)

| State | Intended semantics |
|-------|---------------------|
| `GS_NORMAL` | Full policy set allowed within risk envelope. |
| `GS_CAUTION` | Early defensive scaling; no hard suppression by default. |
| `GS_DEFENSIVE` | Stronger throttles; selective permission tightening. |
| `GS_SURVIVAL` | Severe throttles; recovery / re-entry highly constrained. |
| `GS_LOCKDOWN` | Minimal or zero new risk; only orderly reduction / flat bias. |
| `GS_RECOVERY` | Controlled de-escalation path after survival; **not** “bull mode”—bounded recovery. |

#### 2.1.1 Entry / exit (template — thresholds are policy tables, not magic numbers in code strings)

| Transition | Entry (all must be evaluable deterministically) | Exit / de-escalation |
|------------|--------------------------------------------------|----------------------|
| → `GS_CAUTION` | Confidence ≤ `CONF_MEDIUM` **or** regime `REGIME_VOLATILE` sustained `N_c` epochs **or** toxicity score ≥ `T_c` with dwell | Confidence ≥ `CONF_HIGH` for `D_high` epochs **and** no quarantine request |
| → `GS_DEFENSIVE` | Causal class ∈ {`PANIC_COLLAPSE`, `STRUCTURAL_FAILURE`} **or** survivability score ≤ `S_d` **or** repeated recovery failure pattern in L3 | Causal “clean terminal” + confidence recovery + dwell |
| → `GS_SURVIVAL` | Quarantine **structural** active **or** toxicity state persistent **or** survivability in critical band with dwell | **Only** via `GS_RECOVERY` path with strict checklist (dwell + evidence) |
| → `GS_LOCKDOWN` | Explicit policy tripwire (e.g. session drawdown envelope — *external spec*) **or** broker-level failure storm — **must** be deterministic given inputs | Manual / scheduled unlock **or** automated unlock only with `GS_RECOVERY` gating |
| → `GS_RECOVERY` | From `GS_SURVIVAL` or `GS_LOCKDOWN` when **stability evidence** accumulated | To `GS_DEFENSIVE` then `GS_CAUTION` then `GS_NORMAL` with **mandatory** dwell at each step |

**Escalation ladder (non-skipping by default):**  
`NORMAL → CAUTION → DEFENSIVE → SURVIVAL → LOCKDOWN` may skip **only** if **P0** tripwire fires (documented exception list). Otherwise **no skip** to prevent governance shock oscillation.

**De-escalation ladder (must be slower than escalation):**  
Always `LOCKDOWN → RECOVERY → DEFENSIVE → CAUTION → NORMAL` with **longer dwell** at each downgrade.

### 2.2 Regime states (`REGIME_*`)

| State | Meaning (behavioral, not indicator) |
|-------|-------------------------------------|
| `REGIME_STABLE` | Lifecycle geometry orderly; toxicity low; causal benign / terminal exhaustion. |
| `REGIME_VOLATILE` | Elevated instability without structural failure. |
| `REGIME_TOXIC` | Toxicity analytics in toxic band with persistence rules. |
| `REGIME_COLLAPSING` | Panic / collapse causal classes or quarantine structural triggers. |
| `REGIME_UNCERTAIN` | Insufficient evidence epoch count < minimum; **neutral throttle bias**. |

**Regime FSM precedence:** `REGIME_COLLAPSING` > `REGIME_TOXIC` > `REGIME_VOLATILE` > `REGIME_UNCERTAIN` > `REGIME_STABLE` when multiple signals true — **single output** via ordered max-priority (not voting).

### 2.3 Confidence states (`CONF_*`)

| State | Mapping (illustrative — final cutoffs in policy table) |
|-------|---------------------------------------------------------|
| `CONF_HIGH` | Aggregated confidence score ≥ `H_hi` |
| `CONF_MEDIUM` | `[H_med, H_hi)` |
| `CONF_LOW` | `[H_low, H_med)` |
| `CONF_CRITICAL` | `< H_low` |

**Confidence aggregation (deterministic):** weighted **integer** sum of normalized sub-scores from: causal fingerprint stability, survivability score band, regime stability score, toxicity score, execution quality, recovery quality — **all bounded**, **no** random tie-break; ties broken by **fixed column order** in policy CSV/struct.

### 2.4 Transition safety & replay guarantees

| Property | Enforcement |
|----------|-------------|
| **Determinism** | Same `L0` bundle + same `GOV_EPOCH` policy → same `(GS, REGIME, CONF)` triple. |
| **Non-oscillation** | Hysteresis: enter `REGIME_TOXIC` at `T_on`, exit at `T_off` where `T_off < T_on`. Same for GS dwell. |
| **Replayable** | All transitions logged with `(epoch, from, to, reason_code, input_fingerprint)`. |
| **Governance-safe** | Transitions never delete prior logs; append-only ledger. |

#### Textual governance flow (one evaluation epoch)

```
L0 snapshot ──► L3 memory update ──► L8 regime scores
                    │                      │
                    └──────────┬───────────┘
                               ▼
                         L4 quarantine
                               │
                               ▼
                         L5 confidence
                               │
                               ▼
                    L1 GS FSM (single writer)
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
            L2 risk          L6 surviv.      L7 lifecycle
              │                │                │
              └────────────────┴────────────────┘
                               ▼
                    L9 AS_JOINED_V2 / sidecar row
```

---

## 3. Execution survivability governor (design)

### 3.1 Purpose

Translate **governance mode + regime + confidence + quarantine** into **continuous** execution scalars (not boolean “off” only).

### 3.2 Inputs (minimum set)

| Input domain | Source |
|--------------|--------|
| Toxicity | `SToxicityMetricsV1`, toxicity state, flags |
| Survivability | `SSurvivabilityMetricsV1`, survivability state |
| Campaign decay | Rollup-derived pressure / cumulative pressure / staged intensity |
| Exposure pressure | Rollup exposure path, concentration proxies |
| Recovery instability | Causal `recovery_failure`, deterioration mode |
| Execution degradation | Execution quality series (latency, reject rate, slippage model — *to be wired in implementation*) |

### 3.3 Outputs (all continuous in `[0,1]` or bounded multipliers unless noted)

| Output | Type | Semantics |
|--------|------|-----------|
| `risk_scale` | `[0,1]` | Scales risk budget curve. |
| `lot_throttle` | `[0,1]` | Multiplies lot proposal before floors/ceilings. |
| `exposure_compression` | `[0,1]` | Reduces max concurrent exposure / position depth. |
| `campaign_depth_limit` | `integer ≥ 1` | Max simultaneous campaigns / legs allowed. |
| `recovery_permission` | `[0,1]` | Scales allowed recovery / add-on fraction (0 = no recovery). |
| `entry_permission` | `[0,1]` | Scales new entry rate / probability of veto (**deterministic**: use as threshold multiplier, not RNG). |
| `cooldown_multiplier` | `[1, K_max]` | Multiplies baseline cooldown bars. |

**Composition rule (deterministic):**  
`output = clamp( Π_k f_k(policy_row, subscore_k) * g(GS, REGIME, CONF) , bounds )`  
where each `f_k` is **monotone non-increasing** in stress for throttle outputs.

---

## 4. Confidence throttling model

### 4.1 Sub-scores (integer, bounded)

| Component | Normalized input | Notes |
|-----------|------------------|--------|
| Causal consistency | Distance from “stable” fingerprint family | Hamming-like on token set, not ML |
| Survivability stability | `survivability_score` bands | Monotone |
| Regime stability | `regime_stability_score` | From L8 |
| Toxicity pressure | `toxicity_score` | Monotone |
| Execution quality | Slippage / reject normalized | Bounded |
| Recovery quality | Inverse of recovery failure severity | Monotone |

### 4.2 Aggregation

`CONF_RAW = Σ w_i * s_i` (integer; `w_i` from policy; `Σ w_i = FIXED_SUM`)

### 4.3 Decay & stabilization

- **Decay:** `CONF_EWMA = floor(α * CONF_EWMA_prev + (1-α) * CONF_RAW)` with **rational α** expressed as fixed-point fraction.  
- **Stabilization:** `CONF_PUBLISHED` moves only if `|CONF_EWMA - CONF_PUBLISHED| ≥ Δ_step` **or** dwell timer expired — prevents micro-jitter.

### 4.4 Throttling hierarchy

1. `CONF_CRITICAL` forces **minimum** of all throttle outputs (policy floor row).  
2. `CONF_LOW` applies **intermediate** floor.  
3. `CONF_MEDIUM` default interpolation.  
4. `CONF_HIGH` allows **ceiling** near 1.0 subject to `GS_*` caps.

---

## 5. Strategy degradation memory (deterministic, no ML)

### 5.1 Data structure concept

- **Ring buffer of epoch summaries** (fixed capacity `W`): each slot holds aggregated scalars only (no raw ticks).  
- **Accumulator buckets:** e.g. count of epochs where `TOXIC` ∧ `STRUCTURAL` causal; sum of instability persistence; max consecutive `CONF_LOW`.

### 5.2 Degradation signature (vector of integers)

Example dimensions (versioned):

- `volatility_sensitivity_index` — normalized range of execution slippage / spread proxy.  
- `toxicity_amplification_index` — integral of toxicity score above band.  
- `recovery_collapse_tendency` — count weighted by causal `FAILED_RECOVERY_LOOP`.  
- `survivability_decay_slope` — least-squares slope on last `W` survivability scores (**integer fixed-point**, not floating chaos).  
- `execution_instability_profile` — reject burst counters.

### 5.3 Explainability

Every index must have **`reason_bitmap`** AND **`source_epoch_range`** for audit.

---

## 6. Toxic regime quarantine

### 6.1 Activation logic (example structure)

Activate **structural quarantine** when **(A ∧ B) ∨ C** with:

- **A:** Regime == `REGIME_COLLAPSING` for `N_on` epochs.  
- **B:** Causal class in {`PANIC_COLLAPSE`, `STRUCTURAL_FAILURE`} with persistence.  
- **C:** Degradation memory `recovery_collapse_tendency ≥ R_crit`.

### 6.2 Release logic

Release only if:

- **R1:** Regime ≤ `REGIME_VOLATILE` for `N_off` epochs (`N_off > N_on` hysteresis).  
- **R2:** Causal chain contains no high-priority collapse tokens for `M` epochs.  
- **R3:** Confidence ≥ `CONF_MEDIUM` with dwell.

### 6.3 Hysteresis table

| Signal | ON threshold | OFF threshold |
|--------|--------------|---------------|
| Toxicity score | `T_on` | `T_off` (`T_off < T_on`) |
| Survivability | `S_on` (below) | `S_off` (above, `S_off > S_on`) |

### 6.4 Outputs (examples)

| Output | Effect |
|--------|--------|
| `recovery_disabled` | `recovery_permission := 0` |
| `exposure_compression` | force `exposure_compression` floor |
| `entry_cooldown_mult` | raise `cooldown_multiplier` |
| `governance_escalation` | request `GS_SURVIVAL` |
| `strategy_suppression_mask` | bitfield per strategy slot |

---

## 7. AS_JOINED_V2 architecture (canonical intelligence ledger)

### 7.1 Versioning principle

`AS_JOINED_V1` remains **immutable law** for golden regression. `AS_JOINED_V2` is a **new major schema** with:

- **Backward tool:** ingest V1 rows → compute V2 annotations offline (replay job).  
- **Forward tool:** writers must tag `LEDGER_MAJOR = 2`.

### 7.2 Proposed field groups (additive columns / sidecar JSON with deterministic ordering)

| Group | Example fields |
|-------|----------------|
| **Identity** | `campaign_uuid`, `causal_chain_id`, `regime_memory_tag` |
| **Governance** | `gov_epoch`, `gs_state`, `regime_state`, `conf_state`, `quarantine_level`, `policy_id`, `policy_semver` |
| **Confidence** | `conf_raw`, `conf_ewma`, `conf_published` |
| **Survivability** | snapshot of key metrics + state enum |
| **Toxicity** | snapshot of key metrics + state enum |
| **Causal** | `causal_class`, `causal_confidence`, `explanation_primary`, fingerprint |
| **Adaptive annotations** | `risk_scale`, `lot_throttle`, … (L6 outputs at join epoch) |
| **Degradation** | `degradation_signature[...]` packed or hashed + expansion file |
| **Replay metadata** | `l0_fingerprint`, `input_bundle_hash`, `writer_build_id` |

### 7.3 Safety

- **No in-place mutation** of V1 files.  
- V2 rows are **append-only** per replay job.  
- Schema registry file: `TelemetryAnalytics/AS_JOINED_V2_SCHEMA.md` (future).

---

## 8. Regime intelligence layer

### 8.1 Outputs (all deterministic scores in fixed-point)

| Output | Range | Primary inputs |
|--------|-------|----------------|
| `regime_stability_score` | `0..1000` | survivability + causal terminal share + instability |
| `toxicity_probability` | **Misnomer ban:** rename to `toxicity_pressure_index` `0..1000` | toxicity analytics (no probability — **not** ML) |
| `execution_fragility` | `0..1000` | execution degradation |
| `survivability_pressure` | `0..1000` | inverse survivability score + exposure pressure |
| `recovery_hostility` | `0..1000` | causal recovery failure + fake recovery flags |

### 8.2 Inference rule style

Piecewise **priority-ordered** rules producing scores (like toxicity causal), **not** clustering ML.

---

## 9. Replay & determinism safety (formal)

| Guarantee | Mechanism |
|-----------|-----------|
| **Deterministic replay** | Frozen policy + frozen encoder + integer fixed-point |
| **Governance replay** | Log includes `policy_id` + inputs hash |
| **Adaptive consistency** | `epoch` monotone; outputs at `e` depend only on inputs `≤ e` |
| **Telemetry reproducibility** | Same fixture bytes → same L0 → same governance |
| **State reconstruction** | Replay log can rebuild GS/REGIME/CONF by replaying transition log only |
| **Conflict ordering** | §1.2 precedence — single writer |

---

## 10. Implementation strategy

### 10.1 Phased delivery (recommended)

| Phase | Deliverable | Dependency |
|-------|-------------|--------------|
| **8A** | `GOVERNANCE_STATE_MACHINE` module + unit tests (GS only, mock L0) | None beyond harness |
| **8B** | `CONFIDENCE_THROTTLING` + policy table loader + tests | 8A |
| **8C** | `DEGRADATION_MEMORY` ring + signatures + tests | 8A |
| **8D** | `QUARANTINE` hysteresis + tests | 8A, 8C |
| **8E** | `REGIME_INTELLIGENCE` scores + tests | L0 real fixtures subset |
| **8F** | `EXEC_SURVIVABILITY_GOVERNOR` continuous outputs + tests | 8A–8E |
| **8G** | `AS_JOINED_V2` writer **shadow mode** (no golden mutation) | 8F |
| **8H** | Integration: risk envelope consumer reads scalars only | 8F |

### 10.2 Module order (safest)

1. Policy & schema registry (no runtime).  
2. GS FSM.  
3. Confidence.  
4. Degradation memory.  
5. Quarantine.  
6. Regime intelligence.  
7. Survivability governor outputs.  
8. Ledger V2 shadow.

### 10.3 Rollout strategy

- **Default OFF** compile flag `GOVERNANCE_SHADOW=1` — compute and log, **do not** affect orders.  
- Canary account / tester only.  
- Promotion requires **fixture replay diff == empty** for golden paths.

### 10.4 Regression strategy

- **Golden Suite V1 untouched.**  
- New **`Tests/Fixtures/GovernanceReplay_V1/`** with tiny synthetic L0 bundles.  
- **Byte-stable** expected governance vectors.

### 10.5 Telemetry validation

- Cross-check: governance outputs correlate monotonically with injected stress fixtures.  
- Anti-oscillation test: sinusoidal noise input → bounded state transitions count.

---

## Deterministic guarantees (summary)

- All state machines: **explicit tables**, **hysteresis**, **dwell**, **single writer**.  
- All scalars: **bounded**, **integer fixed-point** preferred.  
- All memory: **ring / capped accumulators** — no unbounded growth.  
- All ledger writes: **append-only**, **versioned schema**.

---

## Document control

| Field | Value |
|-------|--------|
| **Owner** | Principal Governance Systems Architect (role) |
| **Next action** | Engineering review → lock `PHASE_8_GOVERNANCE_POLICY_TABLES_V1` (separate artifact) → implement 8A |

**END OF PHASE 8 ARCHITECTURE FORMALIZATION (DESIGN DOCUMENT)**
