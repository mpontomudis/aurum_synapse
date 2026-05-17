# PHASE_8 — GOVERNANCE POLICY TABLES V1 (Canonical Deterministic Policy Specification)

**Document type:** Policy tables & numeric semantics (canonical for runtime loaders)  
**Status:** V1 specification — **policy-only**; does not amend `PHASE_8_GOVERNANCE_ADAPTIVE_INTELLIGENCE_ARCHITECTURE.md` (architecture baseline frozen)  
**Scope:** Thresholds, hysteresis, scaling, weights, versioning — **no** execution code, **no** ML, **no** probabilistic mutation  
**Numeric discipline:** Unless noted otherwise, all scores use **integer milliscore** scale **`0..1000`** (`ms`); weights use **integer micro-weights** summing to **`1_000_000`** (`µw`); fixed-point fractions use **numerator/denominator** (`num/den`)

---

## 0. Normative definitions

| Symbol | Meaning |
|--------|--------|
| `ms` | Milliscore in `0..1000` inclusive |
| `µw` | Micro-weight in `0..1_000_000`; **must** satisfy `Σ µw = 1_000_000` per aggregation row |
| `epoch` | Monotone governance evaluation index; policy reads inputs **≤ epoch** only |
| `dwell[k]` | Minimum consecutive epochs a state must persist before transition **out** is legal |

**Monotonicity (normative):** For any stress scalar `s` increasing in `[0,1000]`, throttle outputs **`risk_scale`**, **`lot_throttle`**, **`exposure_compression`**, **`recovery_permission`**, **`entry_permission`** must be **non-increasing** in `s` for fixed `GS` (piecewise flat allowed); **`cooldown_multiplier`** must be **non-decreasing** in `s`.

**Tie-break (normative):** When two rules yield equal priority, the **lower rule_id** wins. When two equal `ms` cutoffs apply, **lower band_id** wins.

---

## 1. Policy architecture structure

### 1.1 Policy hierarchy

| Layer | Artifact | Owner |
|-------|----------|--------|
| **P0** | `POLICY_REGISTRY` (index of bundles) | Release engineering |
| **P1** | `POLICY_BUNDLE` = `{ POLICY_ID, POLICY_SEMVER, tables… }` | Governance architect |
| **P2** | **Cutoff tables** (§2) | Policy |
| **P3** | **Hysteresis tables** (§3) | Policy |
| **P4** | **Aggregation & curves** (§4–§5) | Policy |
| **P5** | **Quarantine / memory / regime** (§6–§8) | Policy |

### 1.2 Policy precedence (within a bundle)

1. **Hard invariants** (external to this bundle; cannot be weakened by tables)  
2. **Lockdown / survival cutoffs** (`GS_LOCKDOWN`, `GS_SURVIVAL`)  
3. **Quarantine severity**  
4. **`GS_*` transition permissions**  
5. **`REGIME_*` classification**  
6. **`CONF_*` publication**  
7. **Continuous scalars** (`risk_scale`, …)

### 1.3 Versioning strategy

| Field | Format | Rule |
|-------|--------|------|
| `POLICY_ID` | `GOV_POLICY_<YYYYMMDD>_<SEQ4>` | Immutable once published |
| `POLICY_SEMVER` | `MAJOR.MINOR.PATCH` | **MAJOR**: breaking table shape; **MINOR**: new rows; **PATCH**: numeric edits with replay note |

### 1.4 Loading & immutability

- **Runtime load:** engine resolves `POLICY_ID` + `POLICY_SEMVER` from **session config**; tables are **read-only** in memory.  
- **Replay load:** replayer **must** inject the **exact** bundle referenced on each ledger row (`policy_id`, `policy_semver`, `policy_checksum`).  
- **Immutability:** published bundles are **append-only** in the policy vault; **never** overwrite files in-place.  
- **Rollback:** switch `active_policy_semver` to prior PATCH/MINOR; replay uses per-row embedded version.

### 1.5 Golden fixture lock

- Golden harness pins **`POLICY_ID_REF`** and **`POLICY_SEMVER_REF`** in fixture manifest.  
- CI fails if bundle checksum ≠ `POLICY_CHECKSUM_REF`.

### 1.6 Policy replay guarantees

| Guarantee | Enforcement |
|-----------|-------------|
| Determinism | Same bundle bytes + same inputs → same outputs |
| Audit | Every output row logs `(policy_id, policy_semver, policy_checksum)` |
| Forward compatibility | New **optional** columns allowed only with `MINOR+`; readers ignore unknown columns |

---

## 2. Governance cut-off tables

**Convention:** Bands are **left-closed right-open** `[lo, hi)` except `hi = 1000` inclusive top.

### 2.1 Confidence states (`CONF_*`) — publication from `CONF_PUBLISHED_MS`

| `state_id` | State | `lo_ms` | `hi_ms` | Notes |
|------------|-------|---------|---------|-------|
| 4 | `CONF_CRITICAL` | 0 | 250 | Hard throttles |
| 3 | `CONF_LOW` | 250 | 450 | Elevated throttles |
| 2 | `CONF_MEDIUM` | 450 | 700 | Default adaptive band |
| 1 | `CONF_HIGH` | 700 | 1001 | Near-ceiling permissions |

**Escalation (worse confidence):** `CONF` may move **up** one tier if `CONF_RAW_MS ≤ tier_hi - 20` for **`dwell_escalate_conf = 2`** epochs (hysteresis guard).  
**De-escalation:** may move **down** one tier only if `CONF_RAW_MS ≥ next_tier_lo + 40` for **`dwell_deescalate_conf = 4`** epochs.

### 2.2 Regime states (`REGIME_*`) — from composite `REGIME_SCORE_MS` (see §8)

Priority order (max wins): `COLLAPSING(5) > TOXIC(4) > VOLATILE(3) > UNCERTAIN(2) > STABLE(1)`.

| `state_id` | State | `lo_ms` | `hi_ms` |
|------------|-------|---------|---------|
| 5 | `REGIME_COLLAPSING` | 850 | 1001 |
| 4 | `REGIME_TOXIC` | 650 | 850 |
| 3 | `REGIME_VOLATILE` | 450 | 650 |
| 2 | `REGIME_UNCERTAIN` | 250 | 450 |
| 1 | `REGIME_STABLE` | 0 | 250 |

**Hysteresis overlay (regime):** use §3.3 before mapping to final enum for latch.

### 2.3 Governance states (`GS_*`) — driven by `GS_EVIDENCE_MS` + quarantine latch

`GS_EVIDENCE_MS` is **integer** in `0..1000`, monotone non-decreasing function of stress evidence (defined in policy row set §2.3.1 — **normative**: use **max** of scaled inputs below).

#### 2.3.1 Evidence components (each scaled to `0..1000` before max)

| Component | Source | Scale rule (deterministic) |
|-----------|--------|----------------------------|
| `E_tox` | toxicity `toxicity_score` × 10 | clamp 0..1000 |
| `E_surv` | `1000 - survivability_score×10` | clamp 0..1000 |
| `E_causal` | causal class severity rank × 200 | ranks: `TERMINAL_EXHAUSTION=0`, `ORDERLY=1`, `ORDERLY_DETERIORATION=2`, `CASCADING=3`, `FAILED_RECOVERY=4`, `TOXIC_CONTINUATION=4`, `STRUCTURAL_FAILURE=5`, `PANIC_COLLAPSE=5` (tie §0) |
| `E_conf` | `1000 - CONF_PUBLISHED_MS` | clamp |
| `E_q` | quarantine severity × 250 | severity `0..4` |

`GS_EVIDENCE_MS = max(E_tox, E_surv, E_causal, E_conf, E_q)`.

#### 2.3.2 `GS_*` cutoffs (initial ladder)

| `state_id` | State | `lo_ev_ms` | `hi_ev_ms` |
|------------|-------|------------|------------|
| 6 | `GS_LOCKDOWN` | 920 | 1001 |
| 5 | `GS_SURVIVAL` | 780 | 1001 |
| 4 | `GS_DEFENSIVE` | 600 | 920 |
| 3 | `GS_CAUTION` | 420 | 780 |
| 2 | `GS_RECOVERY` | — | — | **not a band**; see §3.5 |
| 1 | `GS_NORMAL` | 0 | 420 |

**Note:** `GS_SURVIVAL` and `GS_LOCKDOWN` overlap by design; **§3.5** latch resolves overlap.

---

## 3. Hysteresis policy tables

### 3.1 Principles (normative)

| Principle | Rule |
|-----------|------|
| **Asymmetry** | `OFF_threshold` is strictly **more permissive** than `ON_threshold` for “bad” signals (toxicity high ON / lower OFF). |
| **Slower de-escalation** | `dwell_deesc ≥ dwell_esc` for every latch; default **`dwell_deesc = dwell_esc × 2`** (integer). |
| **Anti-flapping** | Any transition requires **both** threshold **and** dwell; optional **`cooldown_lock`** blocks reverse transition for `N_lock` epochs. |

### 3.2 Toxicity-driven latch (input: `toxicity_score` `0..100`)

| Field | Value |
|-------|-------|
| `ON` | score ≥ `70` |
| `OFF` | score ≤ `55` |
| `dwell_esc` | `2` epochs |
| `dwell_deesc` | `4` epochs |
| `cooldown_lock` | `1` epoch (no reverse during lock) |

### 3.3 Survivability-driven latch (input: `survivability_score` `0..100`)

| Field | Value |
|-------|-------|
| `ON` | score ≤ `45` |
| `OFF` | score ≥ `58` |
| `dwell_esc` | `2` |
| `dwell_deesc` | `5` |

### 3.4 Confidence latch (on `CONF_RAW_MS`)

| Field | Value |
|-------|-------|
| `escalate` | cross downward through band boundary − `20 ms` buffer |
| `deescalate` | cross upward through band boundary + `40 ms` buffer |
| `dwell_esc` | `2` |
| `dwell_deesc` | `4` |

### 3.5 `GS` escalation / de-escalation hysteresis matrix

**Escalation (toward worse):** allowed if `GS_EVIDENCE_MS ≥ next_lo` for `dwell_gs_esc = 1` epoch (fast danger response).

**De-escalation (toward better):** allowed only if `GS_EVIDENCE_MS < current_lo − HYST_GS_MS` for `dwell_gs_deesc = 3` epochs.

| Parameter | `ms` |
|-----------|------|
| `HYST_GS_MS` | 80 |

**`GS_RECOVERY` entry:** from `GS_SURVIVAL` or `GS_LOCKDOWN` only, when `quarantine_active=0` **and** `REGIME_SCORE_MS < 650` **and** `CONF_PUBLISHED_MS ≥ 450` for **`dwell_recovery_entry=5`**.

**`GS_RECOVERY` exit:** to `GS_DEFENSIVE` when evidence < `600` for `dwell_recovery_exit=3`; **never** skip to `GS_NORMAL`.

### 3.6 Quarantine latch

See §6; hysteresis **severity ±1** requires `dwell_q_on=2`, `dwell_q_off=5`.

---

## 4. Confidence aggregation policy

### 4.1 Components → `CONF_RAW_MS` (integer)

Components are each normalized to `0..1000` **before** weighting.

| Component `i` | Normalization (to `s_i`) | `µw_i` |
|---------------|--------------------------|--------|
| causal consistency | `1000 − hamming_distance×200` (max 5 tokens vs REF token set; cap 0) | `150_000` |
| survivability stability | `survivability_score × 10` | `200_000` |
| regime stability | `REGIME_STABILITY_SCORE_MS` (§8) | `150_000` |
| toxicity pressure | `1000 − toxicity_score×10` | `150_000` |
| execution quality | `EQ_MS` (0 poor → 1000 good; fixture default `500` if absent) | `200_000` |
| recovery quality | `1000 − RF_PENALTY_MS` (`RF_PENALTY_MS` from recovery failure rank ×250, max 1000) | `150_000` |

**Aggregation:**

`CONF_RAW_MS = ( Σ µw_i × s_i ) / 1_000_000` **integer division toward −∞** (floor for negatives; here nonnegative).

### 4.2 EWMA (fixed-point)

Parameters:

| Param | Value |
|-------|-------|
| `alpha_num` | `1` |
| `alpha_den` | `4` | meaning `α = 0.25` |

`CONF_EWMA_MS[t] = floor( (alpha_num × CONF_EWMA_MS[t−1] × den + (den−alpha_num) × CONF_RAW_MS × den) / (den×den) )`  
Initialize `CONF_EWMA_MS[0] = CONF_RAW_MS[0]`.

### 4.3 Stabilization & publication

| Param | Value |
|-------|-------|
| `STAB_DELTA_MS` | `25` |
| `PUBLISH_DWELL` | `1` epoch |

Publish rule: if `|CONF_EWMA_MS − CONF_PUBLISHED_MS| ≥ STAB_DELTA_MS` for `PUBLISH_DWELL` then `CONF_PUBLISHED_MS ← CONF_EWMA_MS`.

### 4.4 Floors / ceilings

| | `ms` |
|--|------|
| Floor | `0` |
| Ceiling | `1000` |

---

## 5. Execution survivability scaling curves

**Inputs to curve evaluator (bounded):**  
`u_gs` = GS severity in `0..1000` linear map: `NORMAL=0`, `CAUTION=200`, `DEFENSIVE=450`, `SURVIVAL=700`, `LOCKDOWN=1000`, `RECOVERY=300`.  
`u_stress = min(1000, max(0, 1000 − CONF_PUBLISHED_MS + GS_EVIDENCE_MS)) / 2` (integer).

**Combined stress:** `S_MS = min(1000, u_gs + u_stress)` (saturation).

### 5.1 Piecewise linear policy (knots)

Knot table `(S_MS, risk_scale_q16, lot_q16, exp_q16, rec_q16, ent_q16, cool_q16)` with `q16 = floor(value × 65536)`:

| `S_MS` | `risk` | `lot` | `exp` | `rec` | `ent` | `cool` |
|--------|--------|-------|-------|-------|-------|--------|
| 0 | `1.000` | `1.000` | `1.000` | `1.000` | `1.000` | `1.000` |
| 200 | `0.95` | `0.92` | `0.92` | `0.90` | `0.92` | `1.05` |
| 450 | `0.78` | `0.70` | `0.65` | `0.55` | `0.60` | `1.25` |
| 700 | `0.50` | `0.38` | `0.35` | `0.20` | `0.25` | `1.70` |
| 1000 | `0.15` | `0.10` | `0.10` | `0.00` | `0.05` | `2.50` |

**Interpolation:** linear in `S_MS` between knots; values **clamped** to row min/max between knots.

**Floor / ceiling (post-interpolation):**

| Output | min | max |
|--------|-----|-----|
| `risk_scale` | `0.10` | `1.000` |
| `lot_throttle` | `0.05` | `1.000` |
| `exposure_compression` | `0.05` | `1.000` |
| `recovery_permission` | `0.00` | `1.000` |
| `entry_permission` | `0.00` | `1.000` |
| `cooldown_multiplier` | `1.000` | `3.000` |

**`GS_LOCKDOWN` override row:** force `rec=0`, `ent=0`, `risk=min(risk,0.25)`, `lot=min(lot,0.25)` after interpolation (deterministic `min`).

**Discontinuity policy:** only **LOCKDOWN** may apply a **hard min** clip; no other cliffs.

---

## 6. Quarantine policy tables

### 6.1 Severity levels

| `severity` | Meaning | `E_q` contribution |
|------------|---------|---------------------|
| 0 | inactive | 0 |
| 1 | watch | `250` |
| 2 | partial | `500` |
| 3 | structural | `750` |
| 4 | lock bias | `1000` |

### 6.2 Activation (OR of deterministic triggers; evaluate in order; first match sets **candidate** severity)

| `rule_id` | Candidate `severity` | Condition (all integer ops) |
|-----------|----------------------|-----------------------------|
| Q1 | 4 | `GS_STATE ∈ {SURVIVAL, LOCKDOWN}` |
| Q2 | 3 | causal class ∈ `{STRUCTURAL_FAILURE, PANIC_COLLAPSE}` **and** `dwell≥2` |
| Q3 | 3 | `deterioration_repetition ≥ 3` **and** `instability_persistence_ms ≥ 480` **and** toxicity ≥ `TOXIC` band |
| Q4 | 2 | toxicity latch ON (§3.2) **and** `survivability_score ≤ 50` |
| Q5 | 1 | `REGIME_VOLATILE` latched |

### 6.3 Release (candidate must fall to **0** through hysteresis)

| Field | Value |
|-------|-------|
| `dwell_q_on` | `2` |
| `dwell_q_off` | `5` |
| `severity_down_step` | at most **1** level per `dwell_q_off` epochs |

### 6.4 Suppression bitmask (`SUPP_MASK` 16-bit)

| Bit | Effect |
|-----|--------|
| 0 | disable recovery opens |
| 1 | disable pyramiding |
| 2 | force `entry_permission` floor `0.10` |
| 3 | extend cooldown +`0.25` on `cool_q16` |

**Application order:** bitmask **after** §5 curves.

### 6.5 Precedence

`severity` from **max** of active rules, then hysteresis filter; **never** below latched severity until off-dwell satisfied.

---

## 7. Strategy degradation memory policy

| Parameter | Value |
|-----------|-------|
| `RING_W` | `64` epochs max |
| `ACC_CAP_MS` | `1_000_000` per accumulator (saturation) |
| `DECAY_NUM/DEN` | `1/1024` per epoch on positive accumulators |
| `SLOPE_WINDOW` | `16` |
| `SLOPE_SENS_MS` | `5` ms change triggers annotation bit |

**Accumulation:** `ACC_i += contrib_i` with `contrib_i` bounded by table §7.1.

### 7.1 Contribution caps (per epoch)

| Accumulator | `contrib_max` |
|-------------|---------------|
| toxicity spikes | `toxicity_score` |
| instability | `floor(instability_persistence×1000)` |
| recovery failures | `300` if causal `FAILED_RECOVERY_LOOP` else `0` |
| survivability drops | `max(0, prev−curr)×10` |

**Replay reconstruction:** ring + `epoch_cursor` + checksum `CRC32(ring_bytes)` logged.

---

## 8. Regime intelligence policy

### 8.1 Scores (all `0..1000`)

| Score | Formula (integer) |
|-------|-------------------|
| `REGIME_STABILITY_SCORE_MS` | `1000 − min(1000, tox×10 + (100−surv)×10 + causal_rank×100)` |
| `TOXICITY_PRESSURE_INDEX_MS` | `min(1000, toxicity_score×10 + quarantine_severity×125)` |
| `EXECUTION_FRAGILITY_MS` | `1000 − EQ_MS` |
| `SURVIVABILITY_PRESSURE_MS` | `1000 − survivability_score×10` |
| `RECOVERY_HOSTILITY_MS` | `RF_PENALTY_MS + 200×I(fake_recovery)` |

**`REGIME_SCORE_MS` for §2.2:**  
`REGIME_SCORE_MS = min(1000, max(TOXICITY_PRESSURE_INDEX_MS, RECOVERY_HOSTILITY_MS, EXECUTION_FRAGILITY_MS, SURVIVABILITY_PRESSURE_MS))`  
then apply **regime hysteresis**: require `|Δ| ≥ 30 ms` to change mapped band, with `dwell_regime=2` epochs.

---

## 9. Policy replay & versioning

### 9.1 `POLICY_ID` & `POLICY_SEMVER`

- Embedded in every governance output row and fixture manifest.  
- **`POLICY_CHECKSUM`:** `SHA-256` over **canonical UTF-8** of sorted key=value rows of bundle (excluding checksum line).

### 9.2 Compatibility

| Change | Semver | Replay rule |
|--------|--------|-------------|
| Numeric only | PATCH | Old replays **must** embed old checksum |
| New optional row | MINOR | Readers ignore unknown keys |
| Removed / renamed key | MAJOR | Old rows incompatible; require migration tool |

### 9.3 Immutability

Published bundles stored as `POLICY_ID/SEMVER/policy.tab` **read-only**; updates = **new** `SEMVER`.

---

## 10. Implementation safety strategy

| Gate | Test |
|------|------|
| **Shadow** | Compare governance outputs vs no-op; assert file diff only |
| **Canary** | subset symbols; assert monotonicity suite |
| **Regression** | golden governance vectors for 10 frozen L0 bundles |
| **Oscillation stress** | square-wave inputs; assert max transitions ≤ bound |
| **Bounded output** | property test all scalars in §5 min/max |
| **Monotonicity** | stress sweep monotone checks |

---

## Precedence matrix (cross-layer, summary)

|  | Overridden by |
|--|---------------|
| `GS_LOCKDOWN` clip | nothing (except external kill-switch) |
| Quarantine severity 4 | all scalars except LOCKDOWN clip |
| `GS_SURVIVAL` | quarantine <4 curves |
| `CONF_CRITICAL` floors | baseline curves |

---

## Document control

| Field | Value |
|-------|--------|
| **Policy bundle** | `GOV_POLICY_20260510_0001` + `POLICY_SEMVER = 1.0.0` (example; replace on first publication) |
| **Checksum** | *(compute on first publication)* |
| **Architecture ref** | `PHASE_8_GOVERNANCE_ADAPTIVE_INTELLIGENCE_ARCHITECTURE.md` (frozen) |

**END OF PHASE_8_GOVERNANCE_POLICY_TABLES_V1**
