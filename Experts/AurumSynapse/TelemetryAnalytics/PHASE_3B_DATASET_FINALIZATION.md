# Phase 3B — `AS_JOINED_V1` Dataset Finalization (Canonical Intelligence Layer)

**Project:** Aurum Synapse  
**Status:** **FINAL ARCHITECTURE DECISION** — dataset engineering only (no EA execution changes, no `AS_TELEMETRY_V1` mutation)  
**Prerequisites:** `PHASE_3B_MASTER_DESIGN.md`, `PHASE_3B_PRE_IMPLEMENTATION_CHECKLIST.md`, `Telemetry/TELEMETRY_CONTRACT.md`, tag **`telemetry-v1-stable`**

**Regression anchor (2026-05-10):** **`JOINED_SLIM`** column order and null/`ORPHAN_DEAL` semantics are **byte-tested** via `TelemetryFixtures/Case_001_BasicJoin` and `Case_002_OrphanDeal` + `Tests/TestTelemetryJoinValidation.mq5` (see `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md`). Future column adds remain **additive minor** per frozen versioning rules.

**Scope of this document:** Resolve **`JOINED_SLIM` vs FULL 8-slot signal matrix** for the **canonical** joined export; define **optional research** exports; freeze naming, null, and versioning policy sufficient to start implementation.

---

## 1. Analysis — `JOINED_SLIM` vs FULL 8-Slot Signal Matrix

### 1.1 Definitions

| Mode | Meaning |
|------|---------|
| **JOINED_SLIM** | Joined row carries **bar-level context + pipeline + compact slot summary** — **does not** duplicate all `str{i}_*` five-tuples (40 telemetry columns). |
| **FULL 8-slot matrix** | Joined row **embeds** full per-slot telemetry projection (`sig`, `str`, `act`, `wgt`, `veto` × 8) alongside each deal row. |

### 1.2 Comparative matrix

| Dimension | **JOINED_SLIM** | **FULL 8-slot matrix** |
|-----------|-----------------|------------------------|
| **Storage footprint** | **Low** — avoids repeating 40 slot columns per **deal** (many deals/bar possible). | **High** — multiplies telemetry width × deal rows. |
| **CSV growth rate** | Scales ~linearly with **deal count** + ~constant context width. | Scales with deal count × **wide rows**; dominates archive cost. |
| **Parsing complexity** | **Lower** — fewer columns, simpler validators. | **Higher** — wider rows, more null checks, higher parser fragility. |
| **Backward compatibility risk** | **Lower** — fewer public columns to freeze; additive minor easier. | **Higher** — any slot semantic change ripples “canonical joined” perception. |
| **Schema evolution difficulty** | **Easier** — slim core stable; slot detail delegated to research export or raw telemetry. | **Harder** — every slot addition touches canonical export contract. |
| **ML suitability** | **Strong for production labels** — stable keys + outcomes; join to telemetry or research file for high-dim features. | **Strong for naive single-file training** — self-contained but heavy and redundant. |
| **Analytics usability** | **High** for PF/expectancy/regime/session/consensus/reject/halt narratives. | **High** for per-slot forensic without secondary join. |
| **Determinism** | **Equal** if join rules identical; slim reduces surface for silent column drift. | Deterministic but more fields to validate per release. |
| **Maintainability** | **Better** — one narrow contract; slot logic stays in **telemetry SSOT**. | **Worse** — duplicates telemetry writer semantics in second wide writer. |
| **Coupling risk** | **Lower** to `TelemetryWriter` column order (inherits fewer projections). | **Higher** — joined export must track **every** slot column rename/order from V1. |
| **Observability value** | **Sufficient** for institutional KPIs when combined with **optional** research export. | **Maximum** in one file at cost of weight. |
| **Debugging value** | **Good** with optional `AS_JOINED_RESEARCH_V1`; slim keeps prod logs readable. | **Excellent** in one file — best for deep single-ticket forensics. |
| **Survivability analytics usefulness** | **High** — depends on halt/reject/quality/volatility more than per-slot veto spread. | **Medium-high** — extra detail rarely changes capital stall diagnosis vs halts/rejects. |
| **Toxicity analytics usefulness** | **Medium** in slim alone; **restored to high** via research export or **keyed join** to raw telemetry bar. | **High** standalone. |
| **Long-term scalability** | **Best** — archives and ML pipelines stay lean; wide features on demand. | **Risk** — archive bloat + slower scans over years of deals. |

### 1.3 Synthesis

**FULL matrix** optimizes for **convenience of a single self-contained CSV** at the expense of **redundancy, coupling, and archive scalability**.  
**JOINED_SLIM** optimizes for **canonical stability + operational scale**, while preserving a path to **full-dimensional research** via a **second, explicitly optional** artifact.

---

## 2. Canonical Intelligence Dataset — Philosophy

### 2.1 Definition

**Canonical intelligence dataset** (for Aurum Synapse Phase 3B) means:

> The **minimum complete** join artifact used for **institutional baselines**, **regression**, **compliance-friendly storage**, and **long-horizon comparability** — where **complete** means: sufficient to reproduce **primary** analytics (P/L attribution to regime/session/quality/consensus/reject/halt context) **deterministically**, given the same upstream `AS_TELEMETRY_V1` files and `HistorySelect` window.

It is **not** required to contain every feature usable for exploratory data science in one file.

### 2.2 Why canonical must be **stable**

- Downstream **benchmarks** (PF by regime, toxicity dashboards) must not shift because optional debug columns were renamed.  
- **Migration cost** scales with column count and consumer count.

### 2.3 Why canonical must be **minimal**

- Join grain is **deal** → row multiplication is large; **any duplicated telemetry field** is paid per deal.  
- Minimalism reduces **parser bugs**, **QA time**, and **PII/sensitivity surface** (future).

### 2.4 Why research/debug payload should be **separate**

- **Different retention policy** (short TTL for huge debug dumps).  
- **Different consumers** (quants vs production monitoring).  
- **Prevents “column creep”** into canonical exports under deadline pressure.

### 2.5 Risk of overloading the canonical dataset

| Risk | Consequence |
|------|-------------|
| **Schema churn** | Breaks historical comparability and automated tests. |
| **False completeness** | Teams treat joined file as SSOT for strategy logic — **forbidden** (telemetry writer remains SSOT for bar state). |
| **Operational failure** | Files become too large for routine ingestion on modest hardware. |

---

## 3. FINAL RECOMMENDED ARCHITECTURE

### 3.1 Decision

**RECOMMENDED:** **`AS_JOINED_V1` = `JOINED_SLIM` (canonical)**

**NOT chosen as canonical:** **FULL 8-slot matrix** in `AS_JOINED_V1`.

### 3.2 Rationale summary

| Lens | Rationale |
|------|-----------|
| **Engineering** | Avoids duplicating 40 slot columns per deal; reduces coupling to telemetry column expansion; smaller blast radius on schema evolution. |
| **Analytics** | Primary Phase 3B questions (regime/session/quality/consensus/reject/halt vs outcomes) are answered with pipeline + market summary fields. |
| **ML pipeline** | Best practice: **narrow labels table** (`AS_JOINED_V1`) + **feature store** (`AS_TELEMETRY_V1` and/or `AS_JOINED_RESEARCH_V1`) keyed by `(symbol, period, bar_utc)`. |
| **Maintainability** | Slot semantics evolve in **one place** (`TelemetryWriter` / `TELEMETRY_CONTRACT.md`). |
| **Future governance** | Policy decisions should not require rewriting a **wide canonical** contract; optional research exports can absorb exploratory expansions. |

---

## 4. Field Freeze Proposal — `AS_JOINED_V1` (`JOINED_SLIM`)

### 4.1 Naming convention (frozen)

| Prefix | Meaning |
|--------|---------|
| `j_` | Join metadata / QA |
| `t_` | Telemetry inheritance (**slim subset**; never renames V1 semantics) |
| `d_` | Deal inheritance (MT5 `HistoryDeal*` projection) |
| `x_` | Derived deterministic features computed in joiner export pass |

### 4.2 Nullable / enum policy (frozen)

| Policy | Rule |
|--------|------|
| **Nulls** | Copy telemetry null behavior for `t_*` doubles/ints using same sentinels as V1 where applicable; `d_*` money fields are never null (use 0.0). |
| **Enums** | Store **ints** only; meaning maps to `Core/Constants.mqh` / analytics enums **in documentation**, not embedded as strings in canonical CSV (optional sidecar JSON may add labels). |
| **Derived metrics** | `x_*` must be **pure functions** of `(t_*, d_*, j_*)` with version pinned by `JOIN_SEMANTIC_VERSION` + `joined_minor`. |

### 4.3 Final column groups (v1.0 canonical)

> **Field count target:** ~**35–42** columns (implementation will generate exact header string).  
> **Explicitly excluded from canonical:** per-slot `str{i}_*` five-tuples (40 columns).

#### A) Trade / deal identity

| Column | Type | Notes |
|--------|------|------|
| `joined_schema` | string | constant `AS_JOINED_V1` |
| `joined_major` | int | breaking policy |
| `joined_minor` | int | additive policy |
| `join_semantic_version` | string | e.g. `J1-DEALTIME-BACKWARD-BAR` |
| `d_ticket` | ulong | deal ticket |
| `d_position_id` | ulong | 0 allowed |
| `d_magic` | long | EA magic filter |

#### B) Lifecycle / time

| Column | Type | Notes |
|--------|------|------|
| `d_time_utc` | long | normalized `DEAL_TIME` |
| `j_bar_utc` | long | matched telemetry bar open (backward-only) |
| `j_join_status` | string | `OK`, `MISSING_TELEMETRY`, `ORPHAN_DEAL`, … |
| `j_bar_latency_sec` | long | `d_time_utc - j_bar_utc` when OK |
| `d_entry` | int | deal entry type |

#### C) Telemetry context — market + pipeline (slim)

| Column | Type | Notes |
|--------|------|------|
| `t_symbol` | string | |
| `t_period` | int | minutes |
| `t_bar_utc` | long | duplicate of telemetry bar key for validation joins |
| `t_session_code` | int | |
| `t_hour_wit` | int | |
| `t_spread_points` | double | |
| `t_adx` | double | |
| `t_volatility_ratio` | double | |
| `t_quality` | double | |
| `t_consensus` | int | |
| `t_consensus_strength` | double | |
| `t_agreement_pct` | double | |
| `t_reject_code` | int | |
| `t_risk_halt` | int | |
| `t_cooldown_flag` | int | |

#### D) Compact slot summary (replaces full matrix)

| Column | Type | Notes |
|--------|------|------|
| `t_active_slot_mask` | int | bitmask `bit i = 1` if slot `i` active (telemetry `str{i}_act != 0`, non-null) |
| `t_leader_slot` | int | `0..7` or null sentinel: slot with **max** `str{i}_str` among active; tie-break **lowest slot index** |
| `t_leader_sig` | int | `str{leader}_sig` |
| `t_leader_str` | double | `str{leader}_str` |

> **Deterministic tie-break:** if no active slot → `t_leader_slot = TELEMETRY_NULL_INT`, strengths ignored.

#### E) Regime / quality — derived deterministic

| Column | Type | Notes |
|--------|------|------|
| `x_regime_proxy` | int | same thresholds as Phase 3A `RegimeProxy_Classify` inputs |
| `x_quality_bin` | int | same bins as `QualityAnalytics_ClassifyBin` |

#### F) Outcome metrics

| Column | Type | Notes |
|--------|------|------|
| `d_type` | int | buy/sell |
| `d_volume` | double | |
| `d_price` | double | |
| `d_profit` | double | |
| `d_commission` | double | |
| `d_swap` | double | |
| `d_reason` | int | deal reason |
| `x_net_money` | double | `d_profit + d_commission + d_swap` |

#### G) Attribution / QA (minimal)

| Column | Type | Notes |
|--------|------|------|
| `telemetry_schema` | string | always `AS_TELEMETRY_V1` |
| `joiner_build` | string | optional short build id |

### 4.4 Example realistic CSV row (illustrative; header not shown)

```text
AS_JOINED_V1,1,0,J1-DEALTIME-BACKWARD-BAR,900001,700002,20260505,1735689725,1735689600,OK,125,1,XAUUSD,5,1735689600,2,14,118.4,27.2,1.08,63.0,1,0.74,81.0,0,0,0,3,0,1,0.62,3,2,0,0.10,2650.40,42.00,-1.10,-0.30,4,42.00,AS_TELEMETRY_V1,3B-JOINER-001
```

*(Here `t_active_slot_mask=3` → slots 0 and 1 active; values illustrative.)*

---

## 5. Optional Research Dataset(s)

Because canonical is **SLIM**, full-dimensional work uses **optional** artifacts.

### 5.1 `AS_JOINED_RESEARCH_V1` (recommended name)

| Aspect | Specification |
|--------|----------------|
| **Grain** | Still **per deal** (aligned to `d_ticket`) |
| **Purpose** | Self-contained ML/exploratory datasets **without** bloating canonical |
| **Includes** | **FULL 8-slot five-tuples** (40 fields) + optional extra telemetry columns (`efficiency_ratio`, `bb_width`, …) |
| **Primary users** | Quant researchers, offline notebooks, heavy diagnostics |
| **Mandatory?** | **No** — generated on demand |
| **ML experimentation** | **Yes** — preferred wide table for single-file models |
| **Debugging** | **Yes** |
| **Retention** | Short default (e.g., 14–30 days) in operational environments; long retention only in research archives |
| **Storage** | Compressed storage recommended (zip) + partitioned by symbol/date |

### 5.2 `AS_SLOT_MATRIX_V1` (optional alternative shape)

| Aspect | Specification |
|--------|----------------|
| **Grain** | **Per bar** (not per deal) |
| **Purpose** | Slot tensor features for bars with **zero or many** deals |
| **Users** | ML feature pipelines that want uniform bar sampling |
| **Mandatory?** | **No** |

**Guidance:** Prefer `AS_JOINED_RESEARCH_V1` first (deal-grain matches P/L labels). Use `AS_SLOT_MATRIX_V1` only if modeling requires dense bar tensors.

---

## 6. ML & Future AI Compatibility (No AI Implementation Now)

| Dataset | Role |
|---------|------|
| **`AS_JOINED_V1` (slim)** | **Production intelligence + governance baselines** — stable, small, long retention |
| **`AS_TELEMETRY_V1`** | **Bar feature store SSOT** — join keys: `(symbol, period, bar_utc)` |
| **`AS_JOINED_RESEARCH_V1`** | **High-dimensional experimentation** — wide, optional, shorter retention |

**Compatibility without harming canonical stability**

- Treat **`AS_JOINED_V1` major/minor** as a **slow** contract.  
- Allow **research** exports to bump **`research_minor`** frequently.  
- ML pipelines should default to: **labels/outcomes from slim join** + **features from telemetry** + optional **research overlay**.

---

## 7. Storage & Performance Analysis (Order-of-Magnitude)

Assumptions for estimation: **XAUUSD M5**, ~**250** trading days/year, **~1.3k bars/day** ≈ **325k bars/year**; deal count varies (**50–500 deals/year** rough retail band — document uses **200 deals/year** conservative baseline for sizing).

### 7.1 Row width estimate

| Mode | Approx chars/row (CSV) | Notes |
|------|------------------------|------|
| **JOINED_SLIM** | **450–900 bytes/row** | ~35–42 columns, mostly numeric |
| **FULL matrix** | **1,800–3,500+ bytes/row** | +40 slot columns + separators |

### 7.2 Yearly growth (deals-only scaling)

| Mode | Deals/year | Raw CSV scale (order of mag) |
|------|------------|------------------------------|
| **SLIM** | 200 | ~0.2 MB/yr (trivial) |
| **SLIM** | 20,000 | ~20 MB/yr (still easy) |
| **FULL** | 20,000 | ~70–120 MB/yr+ (painful for routine copies) |

### 7.3 MQL5 / IO implications

| Topic | Guidance |
|-------|----------|
| **Memory** | Joiner should **stream** telemetry index + deals; avoid loading entire multi-year joined output in RAM unless batching. |
| **`FILE_COMMON`** | Canonical slim exports are **safe** for long retention; research exports should be **partitioned** (`symbol/ymd`) to avoid single huge file. |
| **Parsing speed** | SLIM reduces parse CPU materially in Python/R/MQL5 re-read loops. |

---

## 8. Versioning Strategy (Frozen Policy Outline)

| Artifact | ID | Policy |
|----------|-----|--------|
| **Canonical joined** | `AS_JOINED_V1` | **Major**: breaking column reorder / semantic changes. **Minor**: additive trailing columns only. |
| **Research joined** | `AS_JOINED_RESEARCH_V1` | Same semver discipline; can move faster; **must not** be referenced by production dashboards by default |
| **Optional bar tensor** | `AS_SLOT_MATRIX_V1` | Independent major/minor |
| **Additive-only** | Applies to **minor** bumps | Parsers ignore unknown tail fields |
| **Migration** | Document in `PHASE_3B_CHANGELOG.md` (future) + roadmap anchor |
| **Backward compatibility** | Guarantee: **old slim consumers** remain valid on **minor** additions |

---

## 9. Safety Boundary (Re-affirmed)

**Joined datasets and joiner tooling MUST:**

- remain **read-only** toward markets and accounts (no trading APIs)  
- **never** `#include` into `AurumSynapse.mq5` hot path (separate script/tester harness)  
- **never** write EA inputs, global variables, or “governance mutations”  
- **never** auto-disable strategies, auto tune lots, or create live feedback loops

**Joined data may inform humans/offline processes only** until a future explicitly authorized phase.

---

## 10. FINAL ENGINEERING DECISION (Executive)

**RECOMMENDED:** **`JOINED_SLIM` as `AS_JOINED_V1` canonical**

**Reason (one paragraph):**  
A deal-grain export multiplies row count; embedding the **full 8-slot telemetry matrix** duplicates **`AS_TELEMETRY_V1`** at wide width, increasing coupling, parser fragility, and archive cost without improving **primary** institutional metrics as much as it costs. A **slim canonical** plus **optional `AS_JOINED_RESEARCH_V1`** preserves **determinism**, **stability**, and **scalability**, while keeping a deliberate path for **high-dimensional ML** and deep forensics.

---

## 11. Implementation Readiness Checklist (Post-Decision)

| Gate | Status |
|------|--------|
| **Schema ready** | **YES** — `JOINED_SLIM` groups + prefixes defined (§4) |
| **Naming frozen** | **YES** — `j_/t_/d_/x_` + schema ids |
| **Field count acceptable** | **YES** — ~35–42 cols canonical |
| **Storage sustainable** | **YES** for canonical; research export requires policy |
| **Regression manageable** | **YES** — smaller surface; golden vectors focus on join keys + `x_*` derivations |
| **Future migration safe** | **YES** — minor additive; slot details evolve in telemetry/research |

**Remaining pre-code gates (unchanged from global Phase 3B plan):**

- golden join fixtures + reconciliation tests  
- `server_utc_offset_sec` capture discipline  
- optional equity/margin sidecar (separate schema) for definitive survivability claims

---

## 12. Deliverable Control

| File | Role |
|------|------|
| `PHASE_3B_DATASET_FINALIZATION.md` | **This document** — canonical vs research split + field freeze proposal |
| `PHASE_3B_PRE_IMPLEMENTATION_CHECKLIST.md` | Time/join semantics + readiness matrix (update cross-reference) |
| `PHASE_3B_MASTER_DESIGN.md` | Module map / roadmap |
| `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md` | Golden fixtures + harness + regression policy (**before** join engine merge) |

---

*End of Phase 3B Dataset Finalization Review.*
