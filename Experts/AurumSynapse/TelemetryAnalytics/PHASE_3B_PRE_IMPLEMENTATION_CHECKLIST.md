# Phase 3B — Pre-Implementation Engineering Review & Checklist

**Project:** Aurum Synapse  
**Role:** Design finalization + deterministic intelligence planning **before** large-scale coding  
**Prerequisites:** `PHASE_3B_MASTER_DESIGN.md`, `Telemetry/TELEMETRY_CONTRACT.md`, tag **`telemetry-v1-stable`** (`AS_TELEMETRY_V1` frozen)

**Hard constraints for this session**

- No full Phase 3B implementation.
- No changes to execution, signal, risk, consensus, trade routing.
- No changes to telemetry schema V1.
- No adaptive AI, auto-learning, or mutation engines.

**Document purpose:** Freeze engineering decisions that are expensive to reverse after data is produced.

**Progress (2026-05-10):** Decisions in this checklist (backward-only hybrid join, `ORPHAN_DEAL`, `JOINED_SLIM` null policy) are **exercised in goldens**: `Case_001_BasicJoin` + `Case_002_OrphanDeal` + **`Case_003_DuplicateCandidateJoin`** **PASS** (`Tests/TestTelemetryJoinValidation.mq5`, **exact** string compare). **Full** `TelemetryDealJoiner` + `HistorySelect` pipeline remains **out of scope** for this checklist’s “no large-scale implementation” rule until fixture maturity milestones complete.

---

## 1. Join Key Finalization

### 1.1 Candidate models

| ID | Model | Definition sketch |
|----|--------|-------------------|
| **A** | Timestamp exact join | Match `deal_time_utc` to telemetry row where `deal_time == bar_utc` (exact second equality). |
| **B** | Nearest-bar backward-only | `bar* = max{ bar_utc \| bar_utc ≤ deal_time }` per `(symbol, period)` (causal “as-of”). |
| **C** | Symbol + timeframe + bar_time join | Align using chart `bar_time` (datetime string / open time) with same keys; may use `iBarShift` equivalence. |
| **D** | Hybrid | Primary: `(symbol, period, bar_utc)` index from CSV; validate with bar open convention; fallback: **B** within bounded lookback. |

### 1.2 Comparative analysis

#### A — Timestamp exact join

| Dimension | Assessment |
|-----------|------------|
| **Pros** | Trivial implementation; exact match is easy to audit. |
| **Cons** | **Almost never matches**: deals rarely occur exactly at bar open second; massive orphan rate unless telemetry is sub-second (it is not). |
| **Determinism** | High if match exists; **degenerate** if match set is empty. |
| **MT5 edge cases** | `DEAL_TIME` at second resolution; partial closes at arbitrary seconds inside bar. |
| **Partial close** | Usually **no** exact `bar_utc` equality → orphan. |
| **Multi-deal** | Many deals map to same bar but **none** to exact open → broken. |
| **Latency** | N/A (offline). |
| **ML suitability** | Bad: selection bias toward empty join or ad-hoc fixes. |

#### B — Nearest-bar backward-only join

| Dimension | Assessment |
|-----------|------------|
| **Pros** | **Causal** (no lookahead); standard “features at decision time” framing; one deal maps to one bar cleanly. |
| **Cons** | Need efficient index / scan; ambiguous if telemetry missing for gap. |
| **Determinism** | High if tie-break `(symbol, period, bar_utc, deal_ticket)` fixed. |
| **MT5 edge cases** | First deal after weekend: bar may be Monday 00:00 bar; still valid backward. |
| **Partial close** | Each deal leg attributes to **its own** deal time bar (correct for “when did this leg occur”). |
| **Multi-deal** | Deterministic ordering by `(DEAL_TIME, DEAL_TICKET)`. |
| **Latency** | O(log n) with sorted arrays + binary search per deal. |
| **ML suitability** | Excellent: stable feature vector per join row. |

#### C — Symbol + timeframe + bar_time join

| Dimension | Assessment |
|-----------|------------|
| **Pros** | Aligns human intuition with chart bars; uses same `symbol`/`period` as telemetry CSV. |
| **Cons** | `bar_time` string can contain commas (V1 reader merges tokens); must normalize to same instant as `bar_utc` **always** or bugs creep in. |
| **Determinism** | High **if** `bar_utc` is authoritative and `bar_time` is checksum only. |
| **MT5 edge cases** | Broker symbol suffix mismatch vs telemetry `symbol`. |
| **Partial close** | Same as B if resolved to `bar_utc_open`. |
| **Multi-deal** | Same as B. |
| **Latency** | Same. |
| **ML suitability** | Good if keyed ultimately on `bar_utc`. |

#### D — Hybrid join architecture

| Dimension | Assessment |
|-----------|------------|
| **Pros** | **Primary key** `(symbol, period, bar_utc)` from telemetry; **deal** maps via **B**; optional validation that computed bar open equals CSV `bar_utc` for integrity QA. |
| **Cons** | Slightly more engineering than pure B. |
| **Determinism** | Highest operational confidence (detect CSV gaps vs MT5 history gaps). |
| **MT5 edge cases** | Same as B/C; plus explicit `join_status` when validation fails. |
| **Partial close** | Best: each deal timestamp → bar; optional secondary row for “position exit attribution” (policy flag, not default). |
| **Multi-deal** | Explicit `deals_on_bar` counter + sorted ingestion. |
| **Latency** | Acceptable. |
| **ML suitability** | Best: features frozen per bar + labels per deal. |

### 1.3 FINAL RECOMMENDED JOIN MODEL

**Select: D — Hybrid join architecture**, with these frozen rules:

1. **Authoritative time key:** `bar_utc` (Unix seconds) from telemetry column **1** per `TELEMETRY_CONTRACT.md`.  
2. **Attribution clock for default join:** `DEAL_TIME` (UTC-normalized) of each **deal** row.  
3. **Map deal → bar** using **backward-only** bar open: largest `bar_utc` such that `bar_utc ≤ deal_time_utc` for matching `(symbol, period)`.  
4. **Integrity check:** optional assert `bar_time` parses consistently with `bar_utc` when strict QA mode enabled.  
5. **Tie-break:** `(DEAL_TIME, DEAL_TICKET)` ascending when multiple deals hit same bar.

**Why not A alone:** exact equality is not a viable join for MT5 deal timestamps vs M5/M15 bar opens.  
**Why D over bare B:** D encodes telemetry SSOT + explicit validation hooks + clearer ML lineage (“features = state at bar open ≤ deal time”).  
**Why causal backward-only:** forward nearest bar introduces **lookahead bias** (fatal for research and any future offline RL dataset).

---

## 2. Time Normalization Policy

### 2.1 Policy table (FREEZE recommendation)

| Topic | Frozen policy |
|-------|----------------|
| **UTC** | All joins use **UTC epoch seconds** internally. Telemetry `bar_utc` is canonical bar open in UTC. |
| **Broker time** | `DEAL_TIME` is interpreted per MT5 contract (server time). Normalize using documented assumption: **convert server → UTC** using **fixed offset from tester report** or `TimeGMT()` delta captured in join run metadata (store `server_utc_offset_sec` in join header). |
| **DST** | Do not hand-roll DST tables. Persist **offset at join run** from environment; for Strategy Tester, offset is typically stable per report — record it. |
| **M5/M15/H1** | Join runs **per `period` column** in telemetry file; never mix timeframes in one `AS_JOINED_V1` run. Multi-TF studies = multiple join outputs. |
| **Bar-open vs bar-close** | **Default P/L attribution unit = deal** mapped to **bar-open ≤ deal time** (state **as-of** bar open). **Bar-close attribution** is **out-of-scope for v1** (lookahead unless only used for exit-time studies with separate schema flag). |
| **Multi-symbol** | One join batch per `(symbol, period)`; magic filter for EA. |

### 2.2 Freeze statement

> **PHASE_3B_TIME_POLICY_V1:** Joiner SHALL normalize `DEAL_TIME` and `bar_utc` to UTC epoch seconds; SHALL use backward-only bar mapping; SHALL NOT use forward bar search for default joins; SHALL record `server_utc_offset_sec` and `JOIN_SEMANTIC_VERSION` in export header.

---

## 3. Trade Outcome Attribution Model

### 3.1 Definitions

| Term | Meaning |
|------|---------|
| **Deal** | Single `HistoryDeal` row (balance deals excluded from P/L joins). |
| **Position** | `DEAL_POSITION_ID` grouping of IN/OUT/out_by legs. |
| **Trade (colloquial)** | Often position lifecycle; in MT5 analytics, must be defined explicitly. |
| **Outcome unit** | Scalar used for PF/expectancy: default **deal profit** (money) including commission+swap unless separate columns kept. |
| **Lifecycle** | IN → partial OUTs → final OUT with aggregated MAE/MFE (needs extra data beyond V1 telemetry). |

### 3.2 Option comparison

#### A — Deal-based analytics

| Dimension | Assessment |
|-----------|------------|
| **Pros** | Matches MT5 ledger; simplest; partial closes natural (each deal is a fact). |
| **Cons** | PF can “double count” narrative psychology unless user understands deal grain. |
| **Survivability** | Good for **event rate** and halt proximity; less natural for “one decision one outcome”. |
| **Toxicity** | Excellent at slot correlation when deal time mapped to bar features. |
| **MT5 compatibility** | **Best**. |

#### B — Position-based analytics

| Dimension | Assessment |
|-----------|------------|
| **Pros** | Aligns with trader mental model; net outcome per decision cluster. |
| **Cons** | Requires robust reconstruction from deals; partials complicate duration and attribution to **which bar’s** telemetry for whole life. |
| **Survivability** | Strong for “account stopped after string of losses”. |
| **Toxicity** | Good but needs rules for attributing multi-bar positions to features (usually **entry bar** or **time-weighted** — extra policy). |
| **MT5 compatibility** | Good if `DEAL_POSITION_ID` reliable (generally yes in MT5 hedging/netting modes — document netting). |

#### C — Full lifecycle analytics

| Dimension | Assessment |
|-----------|------------|
| **Pros** | Richest narrative (MAE/MFE, scaling paths). |
| **Cons** | Needs position state machine + often **tick** or minutely data for precision; far beyond Phase 3B v1 scope. |
| **Survivability** | Best long-term. |
| **Toxicity** | Best long-term. |
| **MT5 compatibility** | Tester OK; live completeness risk. |

### 3.3 RECOMMENDED MODEL (Phase 3B v1)

**Primary: A — Deal-based analytics** as the **`AS_JOINED_V1` row grain** (one row per deal).

**Secondary (derived artifacts, same phase but separate output):** `POSITION_ROLLUP_V1` optional aggregate table keyed by `DEAL_POSITION_ID` for survivability summaries — **not** mixed into primary join rows without explicit column prefixing.

**Rationale:** Maximizes determinism, MT5 fidelity, and partial-close correctness. Position/lifecycle analytics become **deterministic rollups** of deal facts, avoiding ambiguous “single bar” attribution for multi-hour positions unless explicitly chosen.

---

## 4. Partial Close Strategy

### 4.1 Deterministic reconciliation rules (FREEZE)

| Scenario | Rule |
|----------|------|
| **Partial close** | Each closing deal is its own row; **join each deal** to bar per §1.3. |
| **Scale in** | Multiple IN deals same `DEAL_POSITION_ID`: each IN joined to its own `DEAL_TIME` bar. |
| **Scale out** | Multiple OUT deals: same. |
| **Multiple deals same position** | Grouping key = `DEAL_POSITION_ID`; ordering inside group = `(DEAL_TIME, DEAL_TICKET)`. |
| **Hedge** | Filter by **magic + symbol**; hedging across magics is **out of scope** unless user runs separate pass. |
| **Pyramiding** | Same as scale-in; toxicity metrics must not assume one entry per position. |
| **Basket exposure** | Not inferable from single-symbol telemetry join; requires multi-symbol join project (**explicit non-goal** for v1). |

### 4.2 P/L aggregation invariants

- **Net position P/L** = sum of `d_profit + d_commission + d_swap` over deals in position group (definition frozen in rollup spec).  
- **Never** allocate fractional P/L backward onto bars in v1 (avoid invented labels).

---

## 5. `JoinedTradeRecord` / `AS_JOINED_V1` — Final Design Proposal

### 5.1 Naming convention

- Prefix **`t_`** = inherited telemetry (subset).  
- Prefix **`d_`** = deal facts.  
- Prefix **`j_`** = join metadata / QA.  
- **No renaming** of telemetry V1 column meanings—only projection into `t_*`.

### 5.2 Field list (v1 proposal — column order frozen at `AS_JOINED_V1` release)

**Header block (CSV row 0 / JSON sidecar)**

| Field | Example |
|-------|---------|
| `joined_schema` | `AS_JOINED_V1` |
| `joined_major` / `joined_minor` | `1` / `0` |
| `join_semantic_version` | `J1-DEALTIME-BACKWARD-BAR` |
| `telemetry_schema` | `AS_TELEMETRY_V1` |
| `telemetry_files_sha256` | optional |
| `history_from_utc` / `history_to_utc` | ISO or epoch |
| `magic` | `20260505` |
| `server_utc_offset_sec` | signed int |

**Per-deal row (fixed order)**

| # | Column | Type | Source | Nullable / sentinel |
|---|--------|------|--------|------------------------|
| 1 | `joined_schema` | str | const | N |
| 2 | `j_join_semantic` | str | const | N |
| 3 | `j_join_status` | enum str | joiner | `OK`, `MISSING_TELEMETRY`, `ORPHAN_DEAL`, `SYMBOL_MAP`, `DUPLICATE_TELEMETRY_BAR` |
| 4 | `j_bar_utc` | long | derived | if missing → 0 + status ≠ OK |
| 5 | `j_deal_time_utc` | long | `DEAL_TIME` | N |
| 6 | `j_bar_latency_sec` | long | `deal - bar_utc` | if OK |
| 7 | `j_deals_on_bar` | int | counter | default 0 then post-pass fill optional |
| 8 | `t_symbol` | str | telemetry | |
| 9 | `t_period` | int | telemetry | |
| 10 | `t_bar_utc` | long | telemetry | |
| 11 | `t_session_code` | int | telemetry | null → `TELEMETRY_NULL_INT` policy copy |
| 12 | `t_quality` | double | telemetry | |
| 13 | `t_consensus` | int | telemetry | |
| 14 | `t_consensus_strength` | double | telemetry | |
| 15 | `t_agreement_pct` | double | telemetry | |
| 16 | `t_reject_code` | int | telemetry | |
| 17 | `t_risk_halt` | int | telemetry | |
| 18 | `t_cooldown_flag` | int | telemetry | |
| 19 | `t_adx` | double | telemetry | |
| 20 | `t_volatility_ratio` | double | telemetry | |
| 21 | `t_spread_points` | double | telemetry | |
| 22 | *(slot detail)* | — | — | **FINAL:** canonical `AS_JOINED_V1` does **not** embed full 8×5 slot matrix — see **`PHASE_3B_DATASET_FINALIZATION.md`** (`JOINED_SLIM` + `t_active_slot_mask`, `t_leader_*`). Optional full matrix only in **`AS_JOINED_RESEARCH_V1`**. |
| 23 | `d_ticket` | ulong | deal | N |
| 24 | `d_position_id` | ulong | deal | 0 if none |
| 25 | `d_time_utc` | long | deal | N |
| 26 | `d_entry` | int | deal | IN/OUT/out_by |
| 27 | `d_type` | int | deal | buy/sell |
| 28 | `d_volume` | double | deal | |
| 29 | `d_price` | double | deal | |
| 30 | `d_profit` | double | deal | |
| 31 | `d_commission` | double | deal | |
| 32 | `d_swap` | double | deal | |
| 33 | `d_magic` | long | deal | |
| 34 | `d_reason` | int | deal | |
| 35 | **Derived (v1 minimal)** | | | |
| 35a | `x_regime_proxy` | enum int | derived from `t_adx`, `t_volatility_ratio` | same thresholds as Stream A |
| 35b | `x_quality_bin` | enum int | derived | |
| 35c | `x_net_money` | double | `d_profit+d_commission+d_swap` | |

**Versioning:** bump `joined_minor` for additive trailing columns; bump `joined_major` if reorder or semantic change.

### 5.3 Realistic example row (single line, illustrative)

```text
AS_JOINED_V1,J1-DEALTIME-BACKWARD-BAR,OK,1735689600,1735689725,125,2,XAUUSD,5,1735689600,2,63.0,1,0.74,81.0,0,0,0,27.2,1.08,118.4,1,1,0,0,0,0,0,0,900001,700002,1735689725,1,0,0.10,2650.40,42.00,-1.10,-0.30,20260505,4,3,2,42.00
```

*(Superseded for **canonical** column layout: see **`PHASE_3B_DATASET_FINALIZATION.md`** §4 — `JOINED_SLIM` + `t_active_slot_mask` / `t_leader_*`.)*

---

## 6. Rejection Reason — Engineering Review

### 6.1 Options

| ID | Approach | Description |
|----|----------|-------------|
| **A** | Direct runtime telemetry | Use existing `reject_code` + flags in V1 row (already written at T1/T2). |
| **B** | Post-analysis inferred | Infer rejects from absence of deals + spread spikes — high false positive. |
| **C** | Sidecar lightweight snapshot | Separate small CSV keyed by `bar_utc` with extra codes — **second file to sync**. |

### 6.2 Phase 3B initial recommendation (safest)

**Primary: A** — leverage **`t_reject_code`**, **`t_risk_halt`**, **`t_cooldown_flag`**, **`t_spread_points`** already in frozen telemetry. No execution change.

**Secondary (optional later): C** only for fields that can never be inferred safely from V1 (e.g., margin diagnostics) — **separate schema**, explicit version, never blocks v1 join.

**Avoid as default: B** for rejection classification (good for exploratory notebooks, not frozen pipeline).

---

## 7. Capital Survivability Model

### 7.1 Framework dimensions

| Construct | Meaning | V1 feasibility |
|-----------|---------|----------------|
| **Minimum viable capital** | Lowest starting balance where **halt/reject burst** does not dominate calendar | Proxy-only without equity curve |
| **Survivability duration** | Time until **first sustained no-trade window** with elevated rejects/halts | Good from telemetry + deal gaps |
| **Exposure saturation** | Rolling volume / concurrent lots from deals | Good from deals |
| **Equity breathing room** | Drawdown vs lot / margin | Needs equity samples (**sidecar**) |
| **Margin pressure zones** | Requires margin/free margin | **Not in V1 telemetry** — sidecar or future schema |
| **Risk halt escalation** | Count halts per rolling window | Good from `t_risk_halt` |
| **No-entry collapse** | High `reject_code` diversity + zero deals | Good |

### 7.2 Case study — “$2k stops in February” vs “$10k survives full year”

**Objective explanation requires:**

| Phenomenon | Evidence streams |
|------------|-------------------|
| **Lot sizing hits margin floor** | Deal volume vs account size; reject patterns if `MARGIN` mapped later; **equity + margin sidecar** for definitive proof |
| **DD lock / risk halt** | `t_risk_halt` streak; post-halt deal silence |
| **Spread / session gating** | `SIGNAL_REJECT_SPREAD`, `SIGNAL_REJECT_TIME_FILTER` rates vs session |
| **Loss clustering** | Position rollup: consecutive losing **positions** |
| **Capital exhaustion** | If only deals known: infer **cannot** prove margin stop-out without broker margin snapshot |

**Conclusion:** Phase 3B v1 can **objectively rank hypotheses** (halt-dominant vs spread-dominant vs no-signal) using **A + joined deals**. **Definitive margin narrative** requires **equity/margin sidecar** from tester report CSV or future optional telemetry **not** part of V1 freeze.

---

## 8. Strategy Toxicity Model

### 8.1 Definitions (quantitative)

| Metric | Formula sketch | Notes |
|--------|----------------|-------|
| **Slot activation rate** | `active_bars / total_bars` for slot | From telemetry |
| **Marginal P/L contribution** | Sum `x_net_money` on bars where slot active vs inactive (careful: confounded) | Prefer **stratified** by regime |
| **Toxicity index (v1)** | `E[net \| active, regime=r] - E[net \| inactive, regime=r]` | Requires minimum sample `N_MIN` |
| **Regime interaction term** | Two-way table: slot × `x_regime_proxy` | Detect “works in TRENDING, toxic in HIGH_VOL” |
| **Volatility trap** | Negative `x_net_money` concentrated when `t_volatility_ratio` > high threshold | |
| **DD amplifier** | Positions that increase portfolio DD proxy (needs equity path) | Partial without sidecar |
| **Fake high win-rate** | High WR but **negative skew**: large left tail in `x_net_money` | Report skew/kurtosis |

### 8.2 Confidence scoring

- **Wilson score** or **Agresti–Coull** for win-rate by bucket when sample small.  
- **Bootstrap** optional for toxicity index (offline).  
- **Hard rule:** if `n < N_MIN` (e.g., 30 deals per bucket), emit `LOW_CONFIDENCE` flag — no toxicity verdict.

### 8.3 Sample outputs (illustrative)

```text
Slot=GridRecovery | REGIME_PROXY=HIGH_VOL | n=42 | mean_net=-18.3 | toxicity_index=-52.1 | CONF=LOW
Slot=TrendFollowing | REGIME_PROXY=TRENDING | n=310 | mean_net=+6.1 | toxicity_index=+9.4 | CONF=MED
```

---

## 9. Phase 3B Safety Boundary

### 9.1 ALLOWED (hard separation: separate TU / script)

| Class | Allowed behavior |
|-------|------------------|
| **Read-only analytics** | `HistorySelect`, CSV read, aggregates, reports |
| **Offline intelligence** | Join + toxicity + survivability reports |
| **Historical diagnostics** | Charts/tables for research |

**Architecture separation:** Phase 3B code lives in **`TelemetryAnalytics/`** and/or **`Scripts/AurumSynapse/`** and **`Tests/TestTelemetryDealJoin*.mq5`** — **not** linked from `AurumSynapse.mq5` production TU.

### 9.2 NOT ALLOWED

| Forbidden | Enforcement |
|-----------|-------------|
| Live adaptation | No writes to inputs/GV from 3B |
| Auto disable strategy | No calls into strategy manager |
| Auto lot mutation | No `CTrade` from 3B |
| Self optimization / runtime governance mutation | No feedback edges |

**Hard gate:** code review checklist + CI grep for `CTrade`, `OrderSend`, `#include` from EA to 3B reverse-deps.

---

## 10. Implementation Readiness Checklist — READY / NOT READY

| Item | Status | Notes |
|------|--------|------|
| **Telemetry schema frozen** | **READY** | `telemetry-v1-stable`, `TELEMETRY_CONTRACT.md` |
| **Join key finalized** | **READY** | §1.3 hybrid backward-only |
| **Timezone policy finalized** | **READY** | §2.2 policy statement (implement offset capture) |
| **Lifecycle model finalized** | **READY** | §3.3 deal-primary + optional rollup |
| **Partial close rules finalized** | **READY** | §4.1 |
| **`AS_JOINED_V1` column list frozen** | **READY** | **`JOINED_SLIM`** canonical per **`PHASE_3B_DATASET_FINALIZATION.md`**; full slot matrix → optional **`AS_JOINED_RESEARCH_V1`** |
| **Rejection taxonomy finalized** | **READY** | Map to `ENUM_SIGNAL_REJECT_REASON` + flags; no V1 change |
| **Survivability framework finalized** | **PARTIAL** | Concept READY; **margin/equity definitive layer** NOT READY without sidecar |
| **Rollback strategy** | **READY** | Delete/disable script; no EA impact |
| **Regression validation defined** | **PARTIAL** | Need golden synthetic: small CSV + fabricated deals with expected join hashes — **define before merge** |

**Overall:** **`AS_JOINED_V1` column architecture READY** (slim canonical). **NOT READY for large-scale implementation** until **golden join fixtures** + **`TestTelemetryJoinValidation` harness** (see **`PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md`**) pass **Cases 001–010**. **READY** for **Step 1–2 spike** (deal reader + joiner prototype behind branch) under strict scope.

---

## 11. Edge Case Review

| Edge case | Expected handling |
|-----------|---------------------|
| **Missing telemetry rows** | `MISSING_TELEMETRY`; deal excluded from primary PF-by-regime or counted in orphan bucket |
| **Orphan deals** | `ORPHAN_DEAL`; report count; do not fabricate features |
| **Duplicate tickets** | Impossible if keyed by ticket; if duplicate rows in export, fail QA strict mode |
| **History gaps** | Document `HistorySelect` window mismatch vs CSV; reconciliation section |
| **Tester vs live** | Different fills, spread, commission; never mix datasets in one join header |
| **Broker DST** | Store offset snapshot per run |
| **Partial fills** | Each deal row joins independently |
| **Simultaneous strategy overlap** | Telemetry already encodes multi-slot; toxicity uses slot columns — confounding acknowledged |
| **Restart/recovery** | Telemetry may gap; deals continuous — orphans increase after crash unless flush |
| **Corrupted CSV** | Reader rejects row (`rejects++`); join aborts with fatal QA if reject rate > threshold |

---

## 12. Final Engineering Recommendation

### 12.1 Architecture direction

- Ship **offline joiner** first: **DealReader** + **TelemetryDealJoiner** + **`AS_JOINED_V1` CSV export** with header metadata (§2.2, §5.2).  
- Keep **Stream A** untouched; add **Stream B** naming in docs only when first export ships.

### 12.2 Implementation sequencing

1. ~~Freeze **`JOINED_COL_SPEC_V1`** (resolve slim vs full `t_str*`).~~ **DONE** — see **`PHASE_3B_DATASET_FINALIZATION.md`**.  
2. Golden tests (synthetic).  
3. DealReader + joiner + export.  
4. Basic aggregates (reconcile totals).  
5. Toxicity + rejection analytics modules.  
6. Sidecar design for equity/margin (parallel track).

### 12.3 Biggest technical risks

| Risk | Mitigation |
|------|------------|
| Timezone / server offset errors | Persist offset; cross-check first/last deal vs CSV window |
| Symbol suffix mismatch | Configurable remap table |
| Netting mode differences | Document account mode; assert in header |

### 12.4 Biggest analytical risks

| Risk | Mitigation |
|------|------------|
| Confounding (slot vs regime) | Stratify; require `N_MIN`; show confidences |
| Survivorship / selection bias | Explicit windows; no forward bar joins |

### 12.5 MUST remain frozen

- **`AS_TELEMETRY_V1`** column order & semantics  
- **EA execution / risk / consensus / signals**  
- **Phase 3A Stream A** behavior (unless bugfix)

### 12.6 MAY evolve later

- `AS_JOINED_V1` minor columns (additive)  
- Position rollup schema `POSITION_ROLLUP_V1`  
- Equity/margin sidecar schema  
- Multi-symbol basket join (new major project)

---

## Cross-reference

| Document | Role |
|----------|------|
| `PHASE_3B_MASTER_DESIGN.md` | Module map + roadmap |
| `Telemetry/TELEMETRY_CONTRACT.md` | Telemetry V1 SSOT |
| `PHASE_3B_DATASET_FINALIZATION.md` | `AS_JOINED_V1` slim + optional research datasets |
| `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md` | Golden fixtures + validation harness design (**gate before join merge**) |
| This file | **Pre-implementation freeze decisions + readiness gate** |

---

*End of Phase 3B Pre-Implementation Engineering Review.*
