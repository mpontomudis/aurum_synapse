# Phase 3B — Master Design Document  
## Read-Only Deal Join Analytics Layer (`AS_JOINED_V1`)

**Project:** Aurum Synapse  
**Document class:** Architecture & implementation planning (no execution mutation)  
**Parent freeze:** `telemetry-v1-stable` — `AS_TELEMETRY_V1` / `TELEMETRY_SCHEMA_VERSION` = **V1** (see `Telemetry/TELEMETRY_CONTRACT.md`)  
**Phase 3A reference:** Stream A — bar-native descriptive analytics (`TelemetryAnalytics/*`, `Tests/TestTelemetryAnalytics.mq5`)  
**Authority:** This document defines **Phase 3B scope only**. It does **not** authorize adaptive AI, live feedback into execution, or schema changes to telemetry V1.

**Implementation status (2026-05-10):** **Validation foundation operational** — golden **`JOINED_SLIM`** rows + `Tests/TestTelemetryJoinValidation.mq5` prove causal backward-only join and **`ORPHAN_DEAL`** under **byte-identical** fixture compare (`TelemetryFixtures/`, `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md`). **Production-scale** `TelemetryDealJoiner` / `HistorySelect` exporter / PF–toxicity reports remain **future work** (see roadmap “AFTER fixture maturity”).

---

## 1. High-Level Objective

### 1.1 Purpose of Phase 3B

Phase 3B introduces a **read-only analytics layer** that **joins** frozen **bar-aligned telemetry** (`AS_TELEMETRY_V1` CSV) with **realized deal history** from MetaTrader 5 (`HistoryDealGet*`), producing a **versioned joined dataset** (`AS_JOINED_V1`) and derived reports (profit factor by regime, toxicity by strategy slot, session loss concentration, etc.).

### 1.2 Difference vs Phase 3A

| Dimension | Phase 3A (Stream A) | Phase 3B (Deal Join) |
|-----------|---------------------|----------------------|
| **Primary grain** | Bar (telemetry row) | Deal (closed execution leg) or position lifecycle |
| **P/L** | None | Yes — deal profit, commission, swap, volume |
| **Join** | N/A (telemetry only) | Deterministic telemetry ↔ deal association |
| **Questions answered** | “What did the *state* look like?” | “What *state* accompanied *outcomes*?” |
| **Data sources** | `FILE_COMMON` telemetry CSV | Telemetry CSV + `HistorySelect` deal set |
| **Runtime coupling** | None (offline script) | None — same pattern: **offline** or **OnTester**/research script, never order routing |

### 1.3 Why deal join matters

Telemetry captures **context** (quality, consensus, session, volatility proxy, risk halt flags). Deal history captures **outcomes**. Without a join, one cannot credibly answer: “Did high consensus bars precede wins?” or “Which REGIME_PROXY bucket funds the drawdown?” Phase 3B makes those questions **empirical** while preserving **institutional comparability** (frozen V1 bars + explicit join version).

### 1.4 Capabilities after the join layer

Non-exhaustive **observability** outcomes:

- Profit / loss attribution by **REGIME_PROXY**, **session bucket**, **quality bin**, **consensus strength decile**.
- **Strategy slot toxicity** (slot-level signal vs outcome correlation under controls).
- **Consensus validation** (e.g., consensus code vs deal direction and net result).
- **Volatility / spread stress** vs MAE/MFE proxies (when trade placeholders mature) and vs realized R.
- **Risk halt & gate behavior** vs subsequent deal streams (did halts precede relief or churn?).
- **Capital survivability** proxies from account snapshots (if/when sourced — see §9).
- **Exposure pressure** from deal volume/time clustering (no live margin API required for baseline).

---

## 2. System Architecture

### 2.1 End-to-end flow

```text
Market data
    → EA execution path (UNCHANGED in Phase 3B)
        → T1/T2 Telemetry (AS_TELEMETRY_V1 CSV, frozen contract)
        → Broker / terminal deal ledger (History* API, read-only)

Offline / research harness (NEW)
    → DealReader (normalizes deals for EA magic + symbol + interval)
    → TelemetryReader (reuse Phase 3A CSV line parser; V1 contract)
    → TelemetryDealJoiner (deterministic join + reconciliation metadata)
    → JoinedDataset (AS_JOINED_V1 rows in memory / optional CSV export)
    → JoinedAnalytics + domain modules (reports only)
```

### 2.2 Ownership & dependency

| Layer | Owner | Depends on | Must not depend on |
|-------|-------|------------|---------------------|
| **EA / execution** | Core EA modules | Risk, signals, consensus | Phase 3B modules |
| **Telemetry V1 writer** | `Telemetry/` T2 path | `TelemetryWriter` | Join layer |
| **Telemetry CSV** | Operator disk (`FILE_COMMON`) | T2 rotation policy | Deal APIs |
| **Deal ledger** | MT5 terminal / broker | `HistorySelect` range | Telemetry |
| **DealReader** | `TelemetryAnalytics/` (new) | MT5 history, EA magic filter | Consensus internals |
| **Join engine** | `TelemetryAnalytics/` (new) | Normalized deals + parsed telemetry rows | `CTrade` |
| **Joined export** | `TelemetryAnalytics/` (new) | Joiner output | Live trading |
| **Analytics reports** | `TelemetryAnalytics/` (new) | `AS_JOINED_V1` | Strategy parameter mutation |

**Safety boundary:** Phase 3B code ships as **Scripts** or **Tester-only utilities** (recommended: `Scripts/AurumSynapse/` or `Tests/TestTelemetryDealJoin.mq5` pattern) — **no `#include` from `AurumSynapse.mq5` trading TU** unless explicitly gated by compile flag default **OFF** (not recommended for v1; keep physically separate).

---

## 3. Design Principles

| Principle | Implementation implication |
|-----------|----------------------------|
| **Read-only analytics** | Only `HistoryDealGet*`, `HistoryOrderGet*`, `HistorySelect`; no `OrderSend`, no input mutation. |
| **Deterministic** | Same inputs (CSV bytes + deal ticket set + join config version) → same joined rows + same aggregates. |
| **Reproducible** | Log: schema ids, `ANALYTICS_ENGINE_VERSION`, joiner version, `HistorySelect` from/to, symbol, magic, file list hash (optional). |
| **No mutation** | No writes to `GlobalVariable`, registry, or EA inputs; optional append-only **export** CSV is explicit user action. |
| **No execution-path impact** | Zero change to hot path; join runs in separate program. |
| **Telemetry contract frozen** | Parser continues to treat `TelemetryWriter_CsvHeaderLine()` as SSOT; no V1 column edits. |
| **Backward compatibility** | Joiner accepts all V1 files; unknown trailing columns ignored per V1 policy. |
| **Historical comparability** | `AS_JOINED_V1` version bumps only on **join semantics** change, not on V1 telemetry edits. |

---

## 4. Data Sources

### 4.A Telemetry CSV (`AS_TELEMETRY_V1`)

| Topic | Specification |
|-------|----------------|
| **Schema SSOT** | `Telemetry/TelemetryWriter.mqh` — `TelemetryWriter_CsvHeaderLine()` |
| **Row identity** | `schema` + `bar_utc` + `symbol` + `period` (see `Telemetry/TELEMETRY_CONTRACT.md`) |
| **Keys for join** | **Primary:** `(symbol, period_minutes, bar_time)` after normalizing time to **UTC epoch seconds** (`bar_utc`) and verifying `bar_time` string consistency. |
| **High-value fields for analytics** | `session_code`, `hour_wit`, `quality`, `consensus*`, `reject_code`, `risk_halt`, `cooldown_flag`, `volatility_ratio`, `adx`, `spread_points`, per-slot `str*i*` signals. |
| **Frozen behavior** | Null sentinels per `TelemetryContracts.mqh`; REGIME_PROXY derived in analytics, not rewritten into CSV. |

### 4.B Deal history (`HistoryDealGet*`)

| Topic | Specification |
|-------|----------------|
| **Scope** | `HistorySelect(from, to)` covering backtest or statement export window. |
| **EA filter** | `DEAL_MAGIC == EA_MAGIC_NUMBER` (and optional `DEAL_SYMBOL` filter). |
| **Mandatory fields** | `DEAL_TICKET`, `DEAL_ORDER`, `DEAL_POSITION_ID`, `DEAL_TIME`, `DEAL_TYPE`, `DEAL_ENTRY`, `DEAL_SYMBOL`, `DEAL_VOLUME`, `DEAL_PRICE`, `DEAL_PROFIT`, `DEAL_COMMISSION`, `DEAL_SWAP`, `DEAL_MAGIC`, `DEAL_REASON` |
| **Optional / derived** | `DEAL_SL`, `DEAL_TP`, `DEAL_COMMISSION` (already), `DEAL_FEE` (build-dependent), bid/ask at fill (not always stored — do not assume). |
| **Normalization** | Map `DEAL_TIME` to **UTC epoch seconds** (same basis as `bar_utc`). Aggregate **balance deals** out of join grain unless studying funding. |
| **In/out pairing** | For lifecycle analytics, group by `DEAL_POSITION_ID` (MT5 position model) and order `DEAL_ENTRY` IN/OUT/out_by. |

---

## 5. Join Engine Design

### 5.1 Canonical join key (recommended)

**Hybrid primary key:**  
`(symbol, period_minutes, bar_index)` where `bar_index` is implied by aligning `deal_time_utc` to the **unique bar open** for that symbol/timeframe.

**Practical rule:**  
For each deal (or deal exit event), compute `bar_open_time = iTime(symbol, period, iBarShift(symbol, period, deal_time))` (conceptually — in offline tool, pre-index telemetry bars in a hash map keyed by `bar_utc`).

- **Canonical join key:** `(symbol, period_minutes, bar_utc_open)`  
- **Deal timestamp:** use **`DEAL_TIME`** at the **entry deal** for entry-attribution; optionally attribute **exit P/L** to **exit bar** for separate “exit context” study (document which convention is active in `JOIN_SEMANTIC_VERSION`).

### 5.2 Timestamp handling

| Aspect | Rule |
|--------|------|
| **Timezone** | Normalize all times to **UTC epoch seconds**; telemetry `bar_utc` already numeric string. |
| **Sub-bar fills** | Deal inside bar B always attributes to **bar open** of B (industry-standard for “bar features”). |
| **Weekend / gaps** | If no telemetry row for a bar (file missing), mark join as `MISSING_TELEMETRY` — do not invent rows. |

### 5.3 Nearest-bar logic (fallback only)

If exact `bar_utc` match missing (rotation boundary, partial export):

1. Search **previous** telemetry bar with same `(symbol, period)` and `bar_utc ≤ deal_time` (**as-of** semantics — causal for research).  
2. If none within `MAX_LOOKBACK_BARS` (config, e.g. 96), classify as **orphan** (see §5.6).

**Do not** use forward nearest bar for default attribution (introduces lookahead).

### 5.4 Symbol / timeframe matching

| Rule | Detail |
|------|--------|
| **Symbol** | Match `DEAL_SYMBOL` to telemetry `symbol` with **broker suffix policy** (table-driven remap optional). |
| **Timeframe** | Join runs **per chart period** used for telemetry capture (from CSV `period` column); multi-TF studies = multiple join passes, not mixed in one row. |

### 5.5 Deterministic reconciliation

- Sort deals by `(DEAL_TIME, DEAL_TICKET)` ascending.  
- Sort telemetry by `(bar_utc)` ascending.  
- Join with stable tie-breakers (ticket id) when two deals map to same bar.  
- Emit **multiplicity field** `deals_on_bar` for diagnostics.

### 5.6 Missing row behavior

| Condition | Joined row behavior |
|-----------|---------------------|
| Telemetry missing | `join_status=MISSING_TELEMETRY`; deal facts still in **deal-only appendix** export optional. |
| Deal outside CSV window | Excluded from primary join set; counted in reconciliation report. |

### 5.7 Orphan deals

Deals with magic match but no causal bar within lookback: `join_status=ORPHAN_DEAL`; excluded from regime/session PF unless explicitly included in a separate “unknown context” bucket.

### 5.8 Duplicates

| Case | Handling |
|------|----------|
| **Duplicate telemetry lines** (same `bar_utc`) | Last-write-wins **forbidden**; flag `DUPLICATE_TELEMETRY`; use first occurrence; fail validation if policy is strict QA. |
| **Split deals** (partial fills) | Join each deal row independently; aggregate to position in **analytics** layer, not in joiner. |

### 5.9 Comparison: join strategies

| Strategy | Pros | Cons |
|----------|------|------|
| **Timestamp → bar open** | Causal, aligns with telemetry grain | Needs correct symbol/period |
| **Bar index only** | Fast in tester | Fragile across partial exports |
| **Hybrid (recommended)** | `bar_utc` hash + `iBarShift` validation in tooling | Slightly more code |

**Final recommendation:** **Hybrid causal join** — primary key `(symbol, period, bar_utc)` with **previous-bar fallback** and explicit `join_status` flags. Exit-P/L attribution default = **entry bar** (configurable constant for research builds only).

---

## 6. New Modules to Create (responsibility matrix)

All paths under `Experts/AurumSynapse/TelemetryAnalytics/` (or `Scripts/AurumSynapse/` if terminal policy prefers Scripts for `History*`).

### 6.1 `DealReader.mqh`

| | |
|--|--|
| **Responsibility** | Select history range, enumerate deals, normalize to a flat `DealFact` POD list filtered by magic/symbol. |
| **Inputs** | `datetime from, to`, `long magic`, `string symbol`, optional `ulong exclude_deal_flags`. |
| **Outputs** | `DealFact[]`, reconciliation counters (`n_raw`, `n_filtered`, `n_balance`). |
| **Ownership** | Read-only broker data adapter. |
| **Dependencies** | MT5 `History*` API only. |
| **Safety** | No trading calls; cap max deals loaded (memory guard). |

### 6.2 `TelemetryDealJoiner.mqh`

| | |
|--|--|
| **Responsibility** | Build index `map<bar_utc, TelemetryCsvRow>` per file; attach each `DealFact` to exactly one telemetry row per policy; emit `JoinedTradeRecord`. |
| **Inputs** | Parsed telemetry rows + `DealFact[]` + `JoinConfig` (version, attribution mode). |
| **Outputs** | `JoinedTradeRecord[]`, join QA stats. |
| **Ownership** | Core join semantics — **must be unit-testable** with synthetic CSV + synthetic deals. |
| **Dependencies** | `CsvTelemetryReader.mqh` (parse), new `JoinedTradeRecord.mqh`. |
| **Safety** | Pure function style: no globals mutated except explicit out-params. |

### 6.3 `JoinedTradeRecord.mqh`

| | |
|--|--|
| **Responsibility** | Define `AS_JOINED_V1` row POD: telemetry snapshot fields (subset) + deal fields + join metadata. |
| **Inputs** | N/A (type definitions + serializers). |
| **Outputs** | Structs, column list for CSV export. |
| **Ownership** | Contract for joined layer (versioned separately from V1). |
| **Dependencies** | `TelemetryTypes` subset **by value copy**, not by reference into live EA. |
| **Safety** | No includes from Risk/Trade managers. |

### 6.4 `JoinedAnalytics.mqh`

| | |
|--|--|
| **Responsibility** | Orchestrate aggregate passes: PF, expectancy, win rate, MAE/MFE if available, counts by bucket. |
| **Inputs** | `JoinedTradeRecord[]`. |
| **Outputs** | Text / JSON / markdown report sections; optional aggregate CSV. |
| **Ownership** | “Stream B coordinator” — naming aligned with roadmap telemetry Phase 3B. |
| **Dependencies** | Bucket definitions (reuse REGIME_PROXY, session, quality classifiers from Phase 3A). |
| **Safety** | Read-only; deterministic ordering of buckets in report. |

### 6.5 `StrategyToxicityAnalytics.mqh`

| | |
|--|--|
| **Responsibility** | Per-slot: active %, P/L when active vs flat, signal vs outcome mismatch rate, “toxicity score” (definition: e.g. negative contribution to PF). |
| **Inputs** | Joined rows with slot signals + deal P/L. |
| **Outputs** | Slot-level tables + confidence notes (sample size). |
| **Ownership** | Descriptive strategy diagnostics. |
| **Dependencies** | `JoinedTradeRecord`, slot naming (`StrategyFitness_SlotName`). |
| **Safety** | No feedback to weights; report disclaimers for multi-collinearity. |

### 6.6 `CapitalPressureAnalytics.mqh`

| | |
|--|--|
| **Responsibility** | Proxies: deal rate vs equity curve (if equity series imported), lot vs balance (needs account snapshots — Phase 3B v1 may be **deal-only**; see §9). |
| **Inputs** | Joined rows + optional `EquitySample[]` from tester report parser (future). |
| **Outputs** | Pressure indicators, halt-adjacent loss clusters. |
| **Ownership** | Survivability / stall diagnostics. |
| **Dependencies** | Joined rows; optional non-MT5 CSV equity feed. |
| **Safety** | Clearly label “proxy” vs “measured margin”. |

### 6.7 `RejectionReasonAnalytics.mqh`

| | |
|--|--|
| **Responsibility** | Cross-tab `reject_code` (telemetry) vs subsequent **time-to-next-trade** and vs **P/L of next trade** (lead/lag configurable). |
| **Inputs** | Joined rows ordered by time. |
| **Outputs** | Transition matrix, survival-style stats. |
| **Ownership** | Gate / quality forensics. |
| **Dependencies** | `ENUM_SIGNAL_REJECT_REASON` from `Core/Constants.mqh` (read-only include). |
| **Safety** | Correlation ≠ causation banner in report template. |

---

## 7. Joined Dataset Design — `AS_JOINED_V1`

### 7.1 Versioning

| Constant | Role |
|----------|------|
| `JOINED_SCHEMA_ID_ASCII` | `"AS_JOINED_V1"` — first CSV column |
| `JOINED_SCHEMA_MAJOR` / `MINOR` | Breaking vs additive column policy (mirror telemetry philosophy) |
| `JOIN_SEMANTIC_VERSION` | e.g. `"J1-ENTRY-BAR"` — documents entry-bar vs exit-bar attribution |

### 7.2 Field naming conventions

- Prefix inherited telemetry columns with `t_` **or** keep original names and namespace by file section — **recommended:** `t_*` for telemetry, `d_*` for deal, `j_*` for join meta (explicit, ML-friendly).

### 7.3 Telemetry inheritance (subset)

Minimum viable analytics set (illustrative):

` t_schema, t_bar_utc, t_symbol, t_period, t_session_code, t_hour_wit, t_quality, t_consensus, t_consensus_strength, t_agreement_pct, t_reject_code, t_risk_halt, t_cooldown_flag, t_adx, t_volatility_ratio, t_spread_points, t_str0_sig … t_str7_sig (optional subset) `

### 7.4 Deal inheritance

` d_ticket, d_position_id, d_time_utc, d_type, d_entry, d_volume, d_price, d_profit, d_commission, d_swap, d_magic, d_reason `

### 7.5 Join metadata

` j_join_status, j_join_semantic, j_bar_latency_sec, j_deals_on_bar, j_joiner_build `

### 7.6 ML / downstream compatibility

- Fixed column order; CSV; no embedded commas in string fields; numeric only enums.  
- Include `JOINED_SCHEMA_ID_ASCII` on every row.

### 7.7 CSV export design

- Optional header row = `JoinedTradeRecord_CsvHeaderLine()`.  
- One row per **deal** (v1); position-level rollup = v2 or separate aggregate file.

### 7.8 Example realistic row (illustrative values)

```csv
AS_JOINED_V1,1735128000,XAUUSD,5,1,14,62.5,1,0.72,78.3,0,0,0,28.4,1.05,112.0,1,1735128051,0,0.10,2650.55,42.10,-1.20,-0.35,20260505,4,ENTRY_BAR_ATTRIB,1,51,3A-S2-J1
```

*(Semicolon: first fields = telemetry context at bar open; middle = deal; trailing = join meta + build id.)*

---

## 8. Analytics Targets (deliverable reports)

| Analytics | Definition sketch | Primary segmentation |
|-----------|-------------------|------------------------|
| **PF by regime** | Sum profit winners / abs losers grouped by `REGIME_PROXY` on joined row | REGIME_PROXY |
| **PF by session** | Same, grouped by `session_code` bucket | Session bucket |
| **Volatility toxicity** | PF vs `t_volatility_ratio` deciles | Deciles |
| **Consensus validation** | Win rate & avg R when `t_consensus` matches deal direction vs conflicts | Consensus match flag |
| **Quality validation** | PF by quality bin (reuse Phase 3A bins) | QUAL_* bins |
| **Strategy slot toxicity** | Marginal P/L contribution when `str_i_act` & signal non-flat | Slot index |
| **Capital survivability** | (With equity feed) time-under-water; without — lot clustering + halt proximity | Optional |
| **Equity pressure mapping** | Tester equity CSV parser (future) vs deals | Optional |
| **Drawdown cluster analysis** | Tag deals whose exit time ∈ DD windows from statement | Optional |
| **Exposure saturation** | Rolling sum `d_volume` / time; peak concurrent lots from position reconstruction | Position grouping |
| **Trade lifecycle** | IN→OUT duration, MAE/MFE when placeholders populated | `DEAL_POSITION_ID` |

---

## 9. Small Account Failure Analysis

### 9.1 Objective

Explain **“why small accounts stop trading”** using observables: not psychology, but **measurable stalls** (margin, halts, gates, no-entry regimes).

### 9.2 Detections (Phase 3B v1 feasible)

| Signal | Source | Method |
|--------|--------|--------|
| **Risk halt density** | `t_risk_halt`, deals timeline | Bars with halt flag → subsequent **zero-deal** streak length |
| **Reject storms** | `t_reject_code` | Burst of non-zero rejects before flow stops |
| **Spread block** | `t_reject_code == SIGNAL_REJECT_SPREAD` or spread_points high | Count / P/L conditional |
| **Cooldown** | `t_cooldown_flag` | Correlation with opportunity loss (deals missed — proxy only) |
| **Max positions** | `SIGNAL_REJECT_MAX_POSITIONS` | Frequency near flat equity growth |
| **Consecutive loss halt** | `SIGNAL_REJECT_MAX_CONSEC_LOSSES` / risk enums | Transitions |

### 9.3 Detections (requires **additional telemetry** — future T1 minor or V2 only with migration)

| Signal | Gap | Proposed future field (NOT in V1 freeze) |
|--------|-----|---------------------------------------------|
| **Free margin collapse** | Not in V1 row | Optional: `margin_level`, `free_margin`, `equity` snapshot on bar (high sensitivity — privacy/store policy) |
| **No-entry state** | Partially visible via rejects | Explicit `no_entry_reason_top1` aggregate in writer (danger: size/bloat) — prefer **join layer** to infer from rejects + halts first |

**Policy:** Phase 3B **must not** alter `AS_TELEMETRY_V1` layout. Margin/equity analytics require **separate** “account snapshot” CSV or post-processed tester equity — ingest as optional sidecar with own schema version.

---

## 10. Rejection Reason Framework

### 10.1 Design stance

Phase 3B **classifies and analyzes** rejections; it **never** feeds back into execution.

### 10.2 Taxonomy (logical labels → map to existing `ENUM_SIGNAL_REJECT_REASON`)

| Label (analytics) | Typical source in engine | Existing enum / code |
|-------------------|-------------------------|----------------------|
| `CONSENSUS_FAIL` | No consensus | `SIGNAL_REJECT_NO_CONSENSUS` (1) |
| `QUALITY_FAIL` | Score gate | `SIGNAL_REJECT_QUALITY_LOW` (2) |
| `SESSION_FILTER` / time | Session / time filter | `SIGNAL_REJECT_TIME_FILTER` (9) |
| `SPREAD_BLOCK` | Spread gate | `SIGNAL_REJECT_SPREAD` (10) |
| `MAX_POSITION` | Cap | `SIGNAL_REJECT_MAX_POSITIONS` (6) |
| `CONSEC_LOSS_LOCK` | Loss streak gate | `SIGNAL_REJECT_MAX_CONSEC_LOSSES` (7) |
| `RISK_HALT` | Risk manager halt | `SIGNAL_REJECT_RISK_HALT` (8) |
| `MARKET_UPDATE_FAIL` | Data staleness | `SIGNAL_REJECT_MARKET_UPDATE_FAIL` (11) |
| `STRUCTURE_GATE` | Trend / keylevel / momentum | codes 3–5 |
| `MARGIN_FAIL` | *(if engine adds explicit code)* | **Not in current enum** — map to `EXTERNAL_LABEL` until engine exposes code |
| `DD_LOCK` | *(if distinct from risk halt)* | Same — sidecar or future enum extension |
| `COOLDOWN` | Cooldown flag | Use `t_cooldown_flag` + `reject_code` combo |

### 10.3 Recording

- **Today:** `reject_code` column in telemetry (int).  
- **Phase 3B:** copy to `t_reject_code` in joined row; do not reinterpret silently — keep raw int.

### 10.4 Analysis patterns

- **Markov chain** on `reject_code → reject_code` across bars.  
- **Hazard function:** time from reject burst to next deal.  
- **Conditional P/L:** deal profit given previous bar `reject_code`.

### 10.5 Future use

Feeds **adaptive governance** (explicitly out of scope) with audited feature store.

---

## 11. Versioning Strategy

| Artifact | Version vehicle | Bump when |
|----------|-----------------|-----------|
| **Telemetry** | `TELEMETRY_SCHEMA_VERSION` = V1 | Never in Phase 3B |
| **Joined CSV** | `AS_JOINED_V1` + `JOINED_SCHEMA_MAJOR/MINOR` | Join column set or semantic change |
| **Analytics engine** | `ANALYTICS_ENGINE_VERSION` (extend to `3B-Sx`) | New modules / report sections |
| **Stream A report** | `ANALYTICS_STREAM_A_REPORT_VERSION` | Unchanged for 3A; Stream B gets `STREAM_B_REPORT_VERSION` |
| **Backward compatibility** | Joiner reads all V1 files; old joined files parsable with tail ignored | Minor bump |
| **Migration** | Document in `PHASE_3B_CHANGELOG.md` (future) | Major bump |
| **Freeze policy** | After 3B validation, tag e.g. `joined-v1-stable` | Same discipline as telemetry |

---

## 12. Implementation Roadmap

| Step | Deliverable | Risk | Validation | Rollback | Success criteria |
|------|-------------|------|------------|----------|------------------|
| **1 — Deal reader** | `DealReader.mqh` + tiny compile test | Wrong magic → empty set | Known backtest: deal count matches tester | Remove include | Filtered deals > 0 for golden case |
| **2 — Join engine** | `TelemetryDealJoiner.mqh` + `JoinedTradeRecord` | Lookahead bias | Synthetic: known bar + deal → expected key | Disable export | 100% match on synthetic |
| **3 — Validation layer** | QA report: orphans, duplicates, time gaps | False PASS on bad CSV | Chaos tests: missing bars | Flag strict mode | Orphan rate < threshold on clean run |
| **4 — Basic analytics** | PF, WR, expectancy by session/regime | Overfitting narrative | Compare to tester summary totals | Toggle sections | PF totals reconcile with tester ε |
| **5 — Strategy toxicity** | Slot tables | Low sample | Bootstrap CIs (optional) | Exclude slot | Monotonic definitions documented |
| **6 — Capital survivability** | Pressure proxies | Misleading without equity | Disclose data gaps | Sidecar optional | Report shows coverage % |
| **7 — Rejection analytics** | Taxonomy tables | Wrong enum map | Unit map tests | Static map file | All enum codes labeled |
| **8 — Advanced reporting** | Markdown/HTML bundle | Scope creep | Freeze report sections | Tag prior version | Stakeholder sign-off checklist |

---

## 13. Safety & Non-Goals

### 13.1 Phase 3B is **not**

- Adaptive AI or ML training loop  
- Auto optimization or parameter search inside EA  
- Self-mutation of strategies, consensus, or risk  
- Live feedback into execution  
- Autonomous strategy governance  

### 13.2 Phase 3B **is**

- Observability and **intelligence extraction**  
- Behavioral and **causal-analytics foundation** (hypothesis-generating)  
- Auditable join between **frozen telemetry** and **broker facts**  

---

## 14. Future Evolution

Phase 3B produces a **clean, versioned feature store** (`AS_JOINED_V1`) suitable for:

| Future phase | How 3B enables it |
|--------------|-------------------|
| **Adaptive governance** | Policies trained/offlined against join features |
| **ML ingestion** | Labeled rows: context → outcome |
| **Strategy orchestration** | Toxicity + regime PF informs weight rules **offline** |
| **Reinforcement systems** | Reward signals from joined outcomes |
| **Autonomous portfolio intelligence** | Multi-symbol join layers (new schema) |

**Explicit boundary:** None of the above ships until a **separate** product/phase decision, new tags, and non-regression proof against `telemetry-v1-stable`.

---

## Document control

| Field | Value |
|-------|-------|
| **Status** | DRAFT for engineering review |
| **Next action** | Approve join semantics (`JOIN_SEMANTIC_VERSION`); implement Step 1–3 under feature branch |
| **Related** | `Telemetry/TELEMETRY_CONTRACT.md`, `Tests/POST_COMPLETION_VALIDATION_ROADMAP.md`, tag `telemetry-v1-stable`, **`PHASE_3B_PRE_IMPLEMENTATION_CHECKLIST.md`**, **`PHASE_3B_DATASET_FINALIZATION.md`**, **`PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md`** |

---

*End of Phase 3B Master Design Document.*
