# Phase 3B — Golden Fixture & Deterministic Join Validation Foundation

**Project:** Aurum Synapse  
**Role:** Validation-first architecture — **before** full join engine & analytics implementation  
**Frozen upstream:** `AS_TELEMETRY_V1`, UTC / hybrid backward-only join policy, `AS_JOINED_V1` = **JOINED_SLIM** (`PHASE_3B_DATASET_FINALIZATION.md`)

**Hard constraints**

- No full production join engine in this deliverable.
- No EA execution, signal, risk, consensus, or telemetry V1 schema changes.
- No adaptive / learning / live feedback behavior.

**Purpose:** Define **golden fixtures**, **validation rules**, **determinism contract**, **harness shape**, and **regression philosophy** so implementation cannot proceed without a failing-fast safety net.

**Status (2026-05-10):** **Validation foundation established** — `Case_001_BasicJoin` through **`Case_010_TimezoneEdge_StaticOffset`** **PASS** under strict **byte-identical** line compare; **`PHASE_3B_FIXTURE_DEPLOYMENT_POLICY_V1`** + **`CANONICAL_RUNTIME_SERIALIZATION_POLICY_V1`** frozen. Next: roadmap cases as prioritized in §3.  
**Naming note:** **`Case_003_DuplicateCandidateJoin`** (implemented) refers to **multiple telemetry bars** per deal, not duplicate deals — see §A3. **`Case_006_DuplicateDealTicket`** refers to **duplicate `d_ticket` rows in `deals.csv`** — see §A6. **`Case_007_PartialCloseLifecycle`** is **multiple deal rows** sharing **`d_position_id`** (partial-close identity / partial legs) — see §A7. **`Case_008_PositionRollup`** is the same **deal-grain** join model with **explicit lifecycle rollup annotations** (`x_lifecycle_group_id`, `x_lifecycle_seq`) on every row — see §A8 (not production position analytics). **`Case_009_MultiDealPositionAttribution`** proves **per-deal backward telemetry attribution** across **mixed bar contexts** within one `d_position_id` — see §A9. **`Case_010_TimezoneEdge_StaticOffset`** locks **UTC epoch** join correctness at an **M5 / midnight-adjacent boundary** with **static offset metadata only** — see §A10.

### CURRENT IMPLEMENTATION POSITION

The project has crossed from **paper join architecture** (design docs only) into **deterministic validated infrastructure**: version-controlled **inputs + goldens**, a **reproducible harness**, and **exact** regression detection for serializer and column drift — still **without** wiring a production joiner into the EA or mutating execution.

---

## 1. Golden Fixture Philosophy

### 1.1 What is a golden fixture?

A **golden fixture** is a **minimal, version-controlled, byte-stable** bundle of:

- **Input A:** synthetic or curated `AS_TELEMETRY_V1` CSV fragment(s)  
- **Input B:** synthetic **deal facts** (as structured data or `deals.csv` interchange — not broker-dependent)  
- **Output C:** **expected** joined output (`expected_joined.csv`) and/or checksums + validation summary (`expected_validation.json`)

together with **documented semantics** so a harness can assert **bit-exact** or **canonical-normalized** equality.

### 1.2 Why golden fixtures matter for a join engine

The join engine is a **high-leverage correctness risk**: a subtle off-by-one bar, DST mishandling, or lookahead bias can invalidate **all** downstream analytics and ML while still “running successfully.”

Golden fixtures convert correctness into **objective pass/fail** artifacts that:

- encode **policy** (UTC, backward-only, tie-break) as executable truth  
- catch regressions when join code evolves  
- allow reviewers to audit **without** reading thousands of lines of MQL5

### 1.3 Why deterministic validation precedes “big analytics”

Analytics layers compound errors: PF-by-regime is meaningless if bar attribution is sometimes forward-biased. **Validate the join first**, then treat aggregates as **trusted derivatives**.

### 1.4 Risks without golden fixtures

| Risk | Symptom |
|------|---------|
| **Silent lookahead** | Inflated edge in research; false confidence |
| **Timezone drift** | Seasonal regime shifts that are artifacts |
| **Partial close bugs** | P/L attributed to wrong context bar |
| **Duplicate deals** | Double counting in toxicity |
| **Missing bars** | Random `ORPHAN` rates depending on file boundaries |
| **MT5 history quirks** | Tester vs live mismatch undocumented |

**Link:** All of the above are explicitly targeted by the **minimum golden case set** (§3).

---

## PHASE_3B_FIXTURE_DEPLOYMENT_POLICY_V1

| Rule | Specification |
|------|----------------|
| **Runtime read path** | **Only** `FILE_COMMON` — never `TERMINAL_DATA_PATH\MQL5\Experts\...`, never tester-agent sandbox source tree. |
| **Canonical relative root** | `AurumSynapse\TelemetryFixtures\` (under **Common\Files\**) |
| **Absolute diagnostics** | `TerminalInfoString(TERMINAL_COMMONDATA_PATH) + "\\Files\\" + <relative root>` |
| **Harness API** | `JoinValidation_CommonFixtureRoot()`, `JoinValidation_CommonFixtureAbsoluteRoot()`, `JoinValidation_FixtureCase001Root()` … `JoinValidation_FixtureCase010Root()` + `FileOpen(..., FILE_COMMON)` |
| **Git / repo role** | `Experts/AurumSynapse/TelemetryFixtures/` remains the **version-controlled source**; operators **copy/sync** into Common\Files before running tests or CI replay. |
| **Tester agents** | MetaTrader Strategy Tester agents **share** `FILE_COMMON`; fixtures placed once are visible to all agents on that machine. |

**Example (Windows, typical):**  
`%APPDATA%\MetaQuotes\Terminal\Common\Files\AurumSynapse\TelemetryFixtures\Case_001_BasicJoin\telemetry.csv`

**Manual deploy (PowerShell, adjust if your Terminal\Common path differs):**

```powershell
$src = "<path-to-repo>\MQL5\Experts\AurumSynapse\TelemetryFixtures"
$dst = "$env:APPDATA\MetaQuotes\Terminal\Common\Files\AurumSynapse\TelemetryFixtures"
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item -Path (Join-Path $src '*') -Destination $dst -Recurse -Force
```

---

## CANONICAL_RUNTIME_SERIALIZATION_POLICY_V1

| Rule | Specification |
|------|----------------|
| **Source of truth** | For join-validation goldens, **runtime serialization in MQL5** is canonical: whatever `DoubleToString`, `IntegerToString`, and the join prototype emit for a frozen input **is** the expected bytes for `expected_joined.csv` (after `GOLDEN_CSV_NORMALIZATION_V1`: UTF-8, no BOM, **LF only**). |
| **Fixture obligation** | Golden CSV rows **must** be copied from (or provably match) that runtime output — **not** from hand-rounded decimals, spreadsheet export, or “nice” trailing-zero placeholders for extreme magnitudes. |
| **Validator** | The harness **remains exact string equality** on the joined data line vs `expected_joined.csv`. No tolerance, no approximate float compare, no normalized numeric compare. |
| **Why exact compare** | A loosened comparator hides **silent serializer regressions** (compiler / CRT / `DoubleToString` policy drift) that would otherwise corrupt research artifacts while tests still “pass.” |
| **Why anti–float-drift** | Literals like `TELEMETRY_NULL_DOUBLE` (-1.0e100) are **not** representable as a tidy decimal; the stored IEEE-754 value rounds to a long decimal when formatted with fixed 8 fractional digits. Expecting a human-simplified string guarantees **false FAIL** on an otherwise correct join. |
| **Regenerating goldens** | On intentional serializer or column-order changes: re-run the harness (or a one-row probe), capture **`actual=`** from the Journal or a debug print, normalize to LF-only UTF-8, update `expected_joined.csv`, then recompute **`expected_sha256`** over the final file bytes. |

### Troubleshooting: `line_mismatch` with correct join logic

| Symptom | Likely cause | Fix |
|--------|----------------|-----|
| Case_002 `expected=` shows **all-zero** `TELEMETRY_NULL_DOUBLE` decimals; `actual=` shows digits like **`...1590289110975991...`** | **`Common\Files\...` fixture copy is stale** (not updated after repo golden freeze) | Re-copy `Experts/AurumSynapse/TelemetryFixtures/` into `%APPDATA%\MetaQuotes\Terminal\Common\Files\AurumSynapse\TelemetryFixtures\` (see deployment policy). |
| Same **string length**, first diff inside the first `t_spread_points` null token | **Digit serialization** of `DoubleToString(TELEMETRY_NULL_DOUBLE, 8)` — expected file used a hand-rounded token | Replace `expected_joined.csv` data row with **runtime** output (see **`CANONICAL_RUNTIME_SERIALIZATION_POLICY_V1`**); never hand-shorten that token. |

**Byte forensics (example, stale “zeros” vs canonical IEEE rounding):** `expected_len` and `actual_len` may be **identical** (e.g. 1092) while still failing — first differing code unit at **index 151** (0-based) was **`'0'`** (fixture) vs **`'1'`** (runtime) inside the first `TELEMETRY_NULL_DOUBLE` field — **not** CRLF (repo + policy require LF-only).

---

## 2. Fixture Architecture (Official Layout)

**Recommended repository path** (version-controlled **source** — deploy copies to **Common\Files** per **PHASE_3B_FIXTURE_DEPLOYMENT_POLICY_V1**):

```text
Experts/AurumSynapse/TelemetryFixtures/
  README.md                          # how to run harness, versioning, encoding
  Schema/
    fixture_manifest_v1.json         # optional: list cases + hashes
  Case_001_BasicJoin/
    telemetry.csv                    # minimal V1-compliant fragment (+ header)
    deals.csv                        # synthetic deals (interchange format)
    expected_joined.csv              # golden AS_JOINED_V1 slim rows
    expected_validation.json         # counts, statuses, hashes
    README.md                        # intent + pass criteria
  Case_002_OrphanDeal/
    ...                              # negative join: deal before first bar (ORPHAN_DEAL)
  Case_003_DuplicateCandidateJoin/
    ...                              # two backward-eligible bars → MAX(bar_utc)
  Case_004_FutureLeakProtection/
    ...                              # future bar in file → causal filter before MAX(bar_utc)
  Case_002_MultipleDealsSameBar/     # (roadmap — not implemented yet; numbering TBD vs Case_002_OrphanDeal)
    ...
  Case_003_PartialCloseLifecycle/
    ...
  Case_004_ScaleInScaleOut/
    ...
  Case_005_MissingTelemetryRow/
    ...                              # gap: no row for middle bar_utc; OK join to last legal bar; no interpolation
  Case_006_DuplicateDealTicket/
    ...                              # duplicate d_ticket in deals.csv → canonical row → single OK join
  Case_007_PartialCloseLifecycle/
    ...                              # three partial closes same d_position_id → three OK joins; deterministic sort
  Case_008_PositionRollup/
    ...                              # five deals same d_position_id → five OK joins + x_lifecycle_* annotations (deal-grain)
  Case_009_MultiDealPositionAttribution/
    ...                              # same d_position_id; each deal maps to its own backward bar; mixed telemetry contexts
  Case_010_TimezoneEdge_StaticOffset/
    ...                              # UTC epoch boundary; future bar in file; static offset metadata only (not join input)
  Case_006_OrphanDeal/
    ...
  Case_007_DuplicateDealProtection/
    ...
  Case_008_TimezoneEdge_StaticOffset/   # (roadmap label — implemented golden uses folder Case_010_TimezoneEdge_StaticOffset; see §A10)
    ...
  Case_009_CrossSessionBoundary/     # (roadmap — distinct from implemented Case_009_MultiDealPositionAttribution)
    ...
  Case_010_StrategyOverlapMask/      # (roadmap — distinct from implemented Case_010_TimezoneEdge_StaticOffset)
    ...
```

### 2.1 Per-case required artifacts

| Artifact | Purpose |
|----------|---------|
| `telemetry.csv` | Bar rows + header; must validate against `TelemetryCsvV1_ExpectedColumns()` |
| `deals.csv` | **Synthetic** deals independent of `HistorySelect` (portable) |
| `expected_joined.csv` | Canonical expected slim join output |
| `expected_validation.json` | Machine-readable expectations: `join_status` histogram, orphan count, duplicate detection flag, etc. |
| `README.md` | Human intent; links to policy sections in this doc |

### 2.2 `deals.csv` interchange (recommended columns)

Minimal deterministic interchange (header required):

| Column | Type | Notes |
|--------|------|------|
| `d_symbol` | string | must match `t_symbol` for VALID join tests |
| `d_ticket` | ulong | unique |
| `d_position_id` | ulong | 0 allowed |
| `d_time_utc` | long | **canonical test clock** |
| `d_entry` | int | IN/OUT/out_by as MT5 ints |
| `d_type` | int | buy/sell |
| `d_volume` | double | |
| `d_price` | double | |
| `d_profit` | double | |
| `d_commission` | double | |
| `d_swap` | double | |
| `d_magic` | long | must match fixture filter |
| `d_reason` | int | |

> **Note:** Harness may also ingest native MT5 history in **separate** “integration smoke” — not part of **golden byte-stable** suite.

---

## 3. Minimum Golden Case Set (Required)

Each case lists: **goal**, **expected behavior**, **expected join result**, **failure conditions**.

### A) `Case_001_BasicJoin` — basic deterministic join

| Item | Specification |
|------|----------------|
| **Goal** | Prove default mapping: one deal inside bar interval maps to **bar open ≤ deal time** with `j_join_status=OK`. |
| **Expected behavior** | `j_bar_utc` equals telemetry bar open for that bar; `j_bar_latency_sec = d_time_utc - j_bar_utc ≥ 0`. |
| **Expected join** | Single joined row; `x_net_money` matches sum fields. |
| **Failure** | `j_bar_utc` > `d_time_utc`; wrong symbol/period row matched. |

### A2) `Case_002_OrphanDeal` — orphan deal (before first telemetry bar)

| Item | Specification |
|------|----------------|
| **Objective** | Prove the **first negative path**: when **no** telemetry bar satisfies `bar_utc ≤ d_time_utc` (here: deal strictly **before** the only `bar_utc`), the joiner still emits **one** deterministic row and marks `j_join_status=ORPHAN_DEAL` — **no** future-bar match, **no** silent skip, **no** fabricated `t_*` from the “next” bar. |
| **Expected behavior** | `j_bar_utc=0`, `j_bar_latency_sec=0`; `t_symbol` empty; numeric telemetry slots use `TELEMETRY_NULL_*`; `x_regime_proxy` / `x_quality_bin` reflect **unknown** context (`REGIME_PROXY_UNKNOWN`, `QUALITY_BIN_NULL`). `d_*` and `x_net_money` remain deal-faithful. |
| **Invalid behavior** | Picking `j_bar_utc=1735689600` while `d_time_utc` is earlier (future leak from the deal’s clock); copying spread/quality/consensus from the telemetry row into `t_*`; dropping the deal row entirely. |
| **Why it matters** | Orphans are **legitimate** in real histories (session start, clock skew recovery, truncated telemetry). If the pipeline hides them or mis-attributes a bar, **all** downstream PF / toxicity / regime stats become silently wrong. Golden `ORPHAN_DEAL` locks the contract before analytics intelligence. |
| **Failure** | Status not `ORPHAN_DEAL`; `j_bar_utc≠0` with only future bars available; `t_*` populated from telemetry; row missing. |

### A3) `Case_003_DuplicateCandidateJoin` — multiple backward-eligible telemetry bars (**not** duplicate deals)

| Item | Specification |
|------|----------------|
| **Objective** | Prove **deterministic** resolution when **>1** telemetry row satisfies `bar_utc ≤ d_time_utc` for a **single** deal: **`j_bar_utc = MAX(eligible bar_utc)`** — the **latest** causal bar, **not** “first CSV row”, **not** random, **not** forward-nearest. |
| **Important** | **“Duplicate candidate”** = **multiple telemetry bars** competing for one deal — **not** duplicate `d_ticket` / duplicate deal rows. |
| **Expected behavior** | Full-file scan of telemetry data lines; eligible count ≥ **2**; selected row is the one with **`bar_utc = 1735689900`** when bars `1735689600` and `1735689900` exist and `d_time_utc` is after both. **`t_*`** match the **selected** row only. |
| **Determinism** | Selection depends only on **`bar_utc` values** and `d_time_utc`, **not** on CSV row order (permutation of the two eligible rows yields the same `MAX`). |
| **Invalid behavior** | Picking **`1735689600`** while **`1735689900`** is eligible; `j_bar_utc > d_time_utc`; blending `t_*` from two bars. |
| **Failure** | Wrong `j_bar_utc`; `line_mismatch` on `expected_joined.csv`; `eligible` count `< 2` when fixture promises two candidates. |

### A4) `Case_004_FutureLeakProtection` — causal filter before any “nearest” heuristic

| Item | Specification |
|------|----------------|
| **Future leak (definition)** | Using any telemetry bar with `bar_utc > d_time_utc` as the attribution source for deal facts — i.e. **non-causal** information enters the joined record. |
| **Objective** | Prove the scanner **sees** a strictly future telemetry row in the same file, but the join still picks **`j_bar_utc = MAX(bar_utc)` among rows with `bar_utc ≤ d_time_utc`** — never the future row, regardless of row order, spread, or quality. |
| **Why nearest-neighbor alone is dangerous** | Minimizing `abs(bar_utc - d_time_utc)` without a legality predicate can select a bar **after** the deal whenever the implementation forgets the backward predicate — producing optimistic toxicity, regime labels, and survivorship-biased research artifacts. |
| **Causal legality rule (frozen)** | **VALID** candidate iff `bar_utc ≤ d_time_utc`. **INVALID** iff `bar_utc > d_time_utc`. Invalid rows are excluded **before** `MAX(bar_utc)` tie-break among valids. |
| **Important note** | The **closest** timestamp in a file is **not** always a **legal** candidate; legality is defined only by the causal inequality on `bar_utc`. |
| **Fixture contract** | At least two telemetry data rows; at least one row has `bar_utc > d_time_utc`; exactly one backward-eligible row supplies `t_*` fields in the golden `expected_joined.csv`. |
| **Failure** | `j_bar_utc > d_time_utc`; `j_bar_utc` equals the future fixture bar; `line_mismatch`; harness cannot observe both “future row exists” and “single eligible backward bar” when the fixture promises that layout. |

### A5) `Case_005_MissingTelemetryRow` — telemetry gap without synthetic fill

| Item | Specification |
|------|----------------|
| **Telemetry gap (semantics)** | A **chronological** bar open (`bar_utc`) that *would* be the natural parent is **absent** from `telemetry.csv` (crash, detach, write loss, rotation race). The file is not padded or repaired by the join prototype. |
| **No-interpolation guarantee** | The engine **never** fabricates CSV rows, does not interpolate metrics for missing `bar_utc`, and does not “peek” at the next bar when it is **causally illegal** (`bar_utc > d_time_utc`). |
| **Objective** | With rows at `1735689600` and `1735690200`, deal at `1735690000`, and **no** row at `1735689900`, prove **`j_bar_utc = MAX(bar_utc ≤ d_time_utc)` over rows that exist** → `1735689600`, **`OK`**, not `ORPHAN_DEAL`, and not `1735690200`. |
| **Missing vs orphan** | **Missing telemetry (gap):** at least one legal backward row exists in-file → **`OK`** to the **last observed** legal parent (possibly large `j_bar_latency_sec`). **Orphan (`Case_002`):** **no** row satisfies `bar_utc ≤ d_time_utc` → **`ORPHAN_DEAL`**. |
| **Why synthetic fill is forbidden** | Invented bars would launder **unknowable** market context into analytics, break reproducibility, and hide data-quality failures — research and governance require explicit gaps, not silent hallucination. |
| **Determinism** | Full-file scan; outcome depends only on **present** `bar_utc` values and `d_time_utc`, not on row order permutations. |
| **Failure** | Any synthetic `1735689900` row appears in `telemetry.csv` while the golden still expects absence; `j_bar_utc = 1735690200`; `ORPHAN_DEAL` when a legal parent exists; `line_mismatch`. |

### A6) `Case_006_DuplicateDealTicket` — duplicate `d_ticket` rows in `deals.csv`

| Item | Specification |
|------|----------------|
| **Objective** | Prove **deterministic** handling when **`deals.csv` contains ≥2 data rows with the same `d_ticket`** (import/export merge, replay duplication). The harness collapses to **one canonical deal** before telemetry join — **no random survivor**, **no double join**, **no nondeterministic replay**. |
| **Canonical selection (frozen)** | Among rows sharing that ticket: **(1)** minimum `d_time_utc`; **(2)** if equal, **lexical** `StringCompare` on the **entire** raw CSV data line; **(3)** if still equal, **earlier physical line** (smaller file line index). Implemented in `JoinValidation_ParseDealCsvCanonicalDuplicateTicketPolicy`. |
| **Join outcome** | Exactly **one** `AS_JOINED_V1` slim row; **`j_join_status=OK`** when a backward bar exists — duplicate resolution is **validator recovery policy**, not a semantic join failure (`ORPHAN_DEAL` / pseudo `DUPLICATE_DEAL` status are **not** emitted here). |
| **Why the suite PASSes** | The golden freezes **replay-stable canonical pick + single join** so research artifacts and CI remain deterministic; a **stricter** production gate could still **FAIL** batches on duplicate tickets — that is an orthogonal policy choice. |
| **Non-goals** | No synthetic deal rows, no ML disambiguation, no broker round-trip — only deterministic CSV rules in the validation prototype. |
| **Failure** | Join uses the later duplicate row; two joined rows; `line_mismatch`; parser accepts mixed tickets for this Case_006 harness path (fixture requires two rows, one ticket). |

### A7) `Case_007_PartialCloseLifecycle` — partial closes, shared `d_position_id`, multi-row golden

| Item | Specification |
|------|----------------|
| **Objective** | Prove **deterministic lifecycle grouping at the harness level**: multiple **deal** rows that belong to the **same position** (`d_position_id` equal) each receive their own **backward-only** `OK` join row — **three** slim rows in `expected_joined.csv` — without collapsing into a synthetic **position rollup** row. |
| **Deal vs lifecycle** | **Deal row** = one `deals.csv` line → one `AS_JOINED_V1` output row. **Lifecycle root (frozen for this case)** = shared **`d_position_id`** carried identically on every joined row (`800007` in the fixture). |
| **Ordering (frozen)** | Before joining, deal data lines are sorted by **`(d_time_utc` ascending, `d_ticket` ascending)** so file row order does not affect replay; `deals.csv` may be intentionally shuffled. |
| **Why this is not position rollup** | No net exposure, no staged PnL aggregation, no survivability curve — only **per-deal** attribution with a **consistent** lifecycle key for downstream intelligence **later**. |
| **Why grouping matters** | Real partial closes generate **many** deal tickets; analytics and governance need a **stable** key (`position_id`) to correlate rows without inventing merged facts in Phase 3B. |
| **Failure** | Row count ≠ 3; `d_position_id` differs across joined rows; `ORPHAN_DEAL` where bars exist; joined order unstable vs sort policy; `line_mismatch` on any row. |

### A8) `Case_008_PositionRollup` — full lifecycle, shared `d_position_id`, deterministic lifecycle sequence (deal-grain)

| Item | Specification |
|------|---------------|
| **Objective** | Prove **one position campaign** expressed as **many** MT5-style deal rows (OPEN → ADD → partial OUT → ADD → final OUT intent in the narrative) still produces **one joined slim row per deal** — **no row collapse** — while every row carries the **same** deterministic **lifecycle group** identity and a **0-based** sequence in canonical order. |
| **Grouping (frozen)** | All deals in the fixture share **`d_position_id = 800008`**. **`x_lifecycle_group_id`** on each joined row equals that **`d_position_id`** (validator-only annotation; not a production rollup engine). |
| **Ordering (frozen)** | Same as §A7: sort deal CSV data lines by **`(d_time_utc` ascending, `d_ticket` ascending)** before join; physical file order is intentionally non-canonical to prove replay stability. **`x_lifecycle_seq`** = row index **0 … N−1** after that sort (here **N = 5**). |
| **Case_007 vs Case_008** | **Case_007** freezes **partial-close identity** consistency (**three** legs, Case_001 slim columns only). **Case_008** freezes **full multi-leg lifecycle** with **extra trailing columns** only on this golden: **`x_lifecycle_group_id`**, **`x_lifecycle_seq`**. |
| **Deal-grain vs future position-grain** | **Phase 3B output remains deal-grain:** `expected_joined.csv` has **five** data lines for five deals. A future **position-aggregated** export (single row per campaign, exposure, staged PnL) is **out of scope** here — this case only validates **annotations + ordering** that downstream position analytics can rely on later. |
| **Implementation hook** | After `JoinValidation_BuildJoinedSlimCase001`, the harness calls **`JoinValidation_AppendLifecycleRollupSuffix`** (`JoinValidationPrototype.mqh`). **`JOIN_VALIDATION_JOINER_BUILD_008`** tags rows as **`CASE008-PROTO-1`**. |
| **Join status** | All rows **`j_join_status=OK`** — not `ORPHAN_DEAL`, not a pseudo `ROLLUP_COMPLETE` / `POSITION_AGGREGATED` status (those would belong to a future production rollup mode). |
| **Pass journal (frozen)** | `[JOIN_VALIDATION] CASE=Case_008_PositionRollup` then `[JOIN_VALIDATION] STATUS=PASS rows=5 position_rollup_validated=1`. |
| **Failure** | Row count ≠ 5; `x_lifecycle_group_id` differs across rows; `x_lifecycle_seq` not **0…4** in sort order; unexpected row collapse; `ORPHAN_DEAL` where bars exist; `line_mismatch`. |

> **Roadmap naming:** §H sketch **`Case_008_TimezoneEdge_StaticOffset`** is **not** a repo folder name; the implemented UTC-edge golden is **`Case_010_TimezoneEdge_StaticOffset`** — **§A10** (distinct from **`Case_008_PositionRollup`** §A8).

### A9) `Case_009_MultiDealPositionAttribution` — one `d_position_id`, multiple backward bars, mixed telemetry context per deal

| Item | Specification |
|------|---------------|
| **Objective** | Prove **per-deal causal attribution** when several deals share **`d_position_id`** but occur at **different `d_time_utc`**: each deal’s joined row must reflect **`MAX(bar_utc ≤ d_time_utc)`** over the telemetry file — **not** the first bar, **not** the last bar, **not** a position-level summary row, and **not** blending `t_*` across legs. |
| **Vs Case_007** | Case_007 stresses **identity** of partial-close legs (three rows, **identical** telemetry template in the fixture). Case_009 stresses **attribution**: **different** `j_bar_utc` / `t_*` / `x_regime_proxy` / `x_quality_bin` / leader fields per leg where the clock demands it. |
| **Vs Case_008** | Case_008 proves **lifecycle sequencing** annotations on top of a single shared telemetry “personality” across bars. Case_009 proves **contextual diversity**: telemetry rows intentionally differ (trending vs high-vol vs ranging vs low-vol, different quality bins, consensus strength, leader slot/sig/str). |
| **Rollup ≠ attribution** | **`x_lifecycle_group_id` / `x_lifecycle_seq`** (same pattern as §A8) group the **campaign**; they do **not** replace **per-deal** `j_bar_utc` selection. Position identity alone cannot pick the bar — only **`d_time_utc`** does. |
| **Fixture mechanics** | Five deals, **`d_position_id = 900009`**, shuffled `deals.csv`. Telemetry includes **five** rows: four causal bars with distinct features plus one **strictly future** bar (`bar_utc` after all deals) to reinforce **Case_004-style** rejection before `MAX` among eligibles. Two deals intentionally share the **same** backward bar (same `j_bar_utc`) with **identical** `t_*` in the golden — proving identity of attribution when times fall in the same interval, while other legs differ. |
| **Implementation hook** | `JoinValidation_BuildJoinedSlimCase001` + **`JoinValidation_AppendLifecycleRollupSuffix`**; **`JOIN_VALIDATION_JOINER_BUILD_009`** → **`CASE009-PROTO-1`**. |
| **Join status** | All **`OK`**; `ORPHAN_DEAL` forbidden for this fixture. |
| **Pass journal (frozen)** | `[JOIN_VALIDATION] CASE=Case_009_MultiDealPositionAttribution` then `[JOIN_VALIDATION] STATUS=PASS rows=5 multi_deal_attribution_validated=1`. |
| **`expected_validation.json` flags** | `multi_deal_attribution_validated=1` (and legacy `attribution_validated=1`), `mixed_contexts=1`, `future_leak_detected=0`, `orphan_count=0` (machine-readable intent; harness asserts bytes + no orphan). |
| **Failure** | Any deal picks the future bar; all deals show identical `j_bar_utc`/`t_adx`/`t_volatility_ratio` when the golden expects divergence; `line_mismatch`; lifecycle columns inconsistent. |

> **Roadmap naming:** §I **`Case_009_CrossSessionBoundary`** remains a **separate** future scenario (session label drift). The implemented **`Case_009_MultiDealPositionAttribution`** folder occupies the **009** golden slot for **multi-context position attribution**.

### A10) `Case_010_TimezoneEdge_StaticOffset` — UTC epoch boundary, static offset metadata, no forward join

| Item | Specification |
|------|---------------|
| **Objective** | Prove **`j_bar_utc = MAX(bar_utc ≤ d_time_utc)`** remains the **only** parent selection rule at a **time boundary** (two consecutive M5 `bar_utc` values; deal `d_time_utc` strictly between them). A **future** bar exists in `telemetry.csv` and must **not** be selected. |
| **UTC canonical** | All join decisions use **integer UTC epoch seconds** for `d_time_utc` and `bar_utc`. **`bar_time`** strings are human-readable decoration only; they **do not** drive join math. |
| **Static offset policy** | `expected_validation.json` may declare **`server_utc_offset_sec`** (e.g. **+7200**) as **documentation / consistency metadata** for “broker display skew” narratives — **not** a join input. Phase 3B harness **must not** shift `d_time_utc` or `bar_utc` by this offset. |
| **DST** | **Explicitly unsupported** in V1 validation fixtures: no DST tables, no automatic local-time conversion framework, no adaptive offset logic. |
| **Offset metadata ≠ join authority** | If metadata and epoch clocks disagree in a real deployment, **the epoch fields used by the joiner win** for this contract; metadata cannot override `MAX(bar_utc ≤ d_time_utc)`. |
| **Fixture values** | Bars **`1735775700`**, **`1735776000`**; deal **`1735775850`** → parent **`1735775700`**, latency **`150`**, `j_join_status=OK`. |
| **Harness** | `JoinVal_RunOneCase(..., passMode=6)` — same causal telemetry scan as Case_004 (`passMode=3`), **different** PASS journal tag. **`JOIN_VALIDATION_JOINER_BUILD_010`** → **`CASE010-PROTO-1`**. |
| **Pass journal (frozen)** | `[JOIN_VALIDATION] CASE=Case_010_TimezoneEdge_StaticOffset` then `[JOIN_VALIDATION] STATUS=PASS rows=1 timezone_edge_validated=1`. |
| **Failure** | `j_bar_utc` equals the future bar; `j_bar_utc > d_time_utc`; `line_mismatch`; local PC timezone or metadata incorrectly wired into join selection. |

### B) `Case_002_MultipleDealsSameBar` — multiple deals same bar

| Item | Specification |
|------|---------------|
| **Goal** | Two deals same bar, different seconds; both map to **same** `j_bar_utc`. |
| **Expected behavior** | Stable sort `(d_time_utc, d_ticket)`; optional `j_deals_on_bar=2` after post-pass or computed in validation JSON. |
| **Expected join** | Two rows; identical `t_bar_utc` / `j_bar_utc`. |
| **Failure** | Different `j_bar_utc` for same-bar deals; unstable ordering across runs. |

### C) `Case_003_PartialCloseLifecycle` — partial close lifecycle

> **Implemented golden (Phase 3B harness):** see **§A7** `Case_007_PartialCloseLifecycle` — three `OK` joined rows, shared `d_position_id`, deterministic `(d_time_utc, d_ticket)` ordering. The table below remains a **roadmap** sketch for broader lifecycle features.

| Item | Specification |
|------|----------------|
| **Goal** | IN deal + two partial OUT deals at different times map to **their respective** backward bars. |
| **Expected behavior** | Three joined rows; position_id identical. |
| **Expected join** | Each OUT attributed to correct `j_bar_utc` per deal time. |
| **Failure** | OUT legs all forced to IN bar incorrectly (unless explicit **non-default** policy — forbidden in v1). |

### D) `Case_004_ScaleInScaleOut` — scale in / scale out

| Item | Specification |
|------|----------------|
| **Goal** | Multiple IN deals then staged OUT deals; each deal row joins independently. |
| **Expected behavior** | Deterministic ordering by `(d_time_utc, d_ticket)`. |
| **Expected join** | Row count equals deal count; no merged phantom rows. |
| **Failure** | Collapsed deals into one joined row without documented rollup mode. |

### E) `Case_005_MissingTelemetryRow` — missing telemetry row (roadmap / alternate status policies)

> **Implemented golden harness:** see **§A5** `Case_005_MissingTelemetryRow` — `j_join_status=OK` with **last legal backward bar** and **no interpolation**. The table below describes **optional** broader production policies (e.g. explicit `MISSING_TELEMETRY` status) that are **not** used by the current Phase 3B byte-stable golden for this folder name.

| Item | Specification |
|------|----------------|
| **Goal** | Deal time falls into gap with **no** telemetry bar rows covering backward lookup beyond max lookback (or gap inside window). |
| **Expected behavior** | `j_join_status=MISSING_TELEMETRY` (or `ORPHAN_DEAL` if policy distinguishes “gap” vs “before first bar” — **pick one** and freeze in JSON). |
| **Expected join** | Row exists with null-safe `t_*` sentinels OR row excluded from primary export — **must be frozen** per implementation; recommended: **emit row with `j_join_status≠OK` + empty `t_*` policy documented**. |
| **Failure** | Silent match to wrong distant bar. |

### F) `Case_006_OrphanDeal` — orphan deal

| Item | Specification |
|------|----------------|
| **Goal** | Deal earlier than first telemetry `bar_utc` in file. |
| **Expected behavior** | `j_join_status=ORPHAN_DEAL` after bounded lookback exhausted. |
| **Expected join** | No valid `j_bar_utc` OR `j_bar_utc=0` with status ORPHAN (freeze). |
| **Failure** | Clamps to first bar forward (lookahead). |

### G) `Case_007_DuplicateDealProtection` — duplicate deal protection

| Item | Specification |
|------|----------------|
| **Goal** | `deals.csv` contains duplicate `d_ticket`. |
| **Expected behavior** | Harness **FAIL** suite (or joiner rejects duplicates) deterministically. |
| **Expected join** | Either zero rows + validation error, or single row + error flag — **choose one** and freeze. |
| **Failure** | Double rows in `expected_joined.csv` without raising validation error. |

### H) `Case_008_TimezoneEdge_StaticOffset` — DST / timezone edge (controlled)

> **Implemented golden:** **`Case_010_TimezoneEdge_StaticOffset`** (**§A10**) — UTC epoch boundary + static offset **metadata** only. The table below is the **original v0 policy sketch** (DST avoidance); **DST remains unsupported** in Phase 3B V1 harness fixtures.

| Item | Specification |
|------|----------------|
| **Goal** | Avoid real-world DST tables in v1: use **explicit `server_utc_offset_sec`** in `expected_validation.json` and fixture README; deals/times already in **UTC epoch**. |
| **Expected behavior** | Join uses epoch only; offset metadata matches fixture declaration. |
| **Expected join** | Identical under Linux/Windows harness reading bytes. |
| **Failure** | Local PC timezone affects results. |

### I) `Case_009_CrossSessionBoundary` — cross-session boundary

> **Implemented golden (Phase 3B harness):** **`Case_009_MultiDealPositionAttribution`** (§A9) uses the **009** fixture slot for **multi-bar / mixed-context** per-deal attribution within one `d_position_id`. The table below remains the **roadmap** sketch for **cross-session** labeling when `t_session_code` changes across bars.

| Item | Specification |
|------|----------------|
| **Goal** | Deals around `session_code` change boundary still map to correct `bar_utc` bars; telemetry includes changing `t_session_code`. |
| **Expected behavior** | Session label in joined output matches telemetry row for `j_bar_utc`. |
| **Expected join** | Two deals map to two different `t_session_code` values correctly. |
| **Failure** | Session taken from deal time rather than **matched bar** (policy drift). |

### J) `Case_010_StrategyOverlapMask` — simultaneous strategy overlap

| Item | Specification |
|------|----------------|
| **Goal** | Telemetry row activates multiple slots; `t_active_slot_mask` and `t_leader_*` deterministic. |
| **Expected behavior** | Leader chosen by max strength among active; tie lowest slot index. |
| **Expected join** | `expected_validation.json` asserts mask + leader fields. |
| **Failure** | Non-deterministic leader when strengths equal and tie-break not lowest slot. |

> **Naming note:** **`Case_010_StrategyOverlapMask`** (§J) is a **future** roadmap folder name — distinct from the implemented **`Case_010_TimezoneEdge_StaticOffset`** golden (**§A10**). Renumber when the overlap-mask harness is added.

---

## 4. Join Validation Rules — “VALID JOIN” Definition

### 4.1 VALID join (canonical)

A joined output row is **VALID** iff all hold:

| Rule | Definition |
|------|------------|
| **V1** | `j_join_status == OK` |
| **Backward-only** | `j_bar_utc ≤ d_time_utc` |
| **Eligible bar** | `j_bar_utc` exists in telemetry index for `(t_symbol, t_period)` |
| **Symbol match** | `d_symbol` (if column present) == `t_symbol` (or mapped via frozen remap table in fixture) |
| **Timeframe match** | `t_period` equals fixture period |
| **No future attribution** | No `j_bar_utc` strictly greater than `d_time_utc` |
| **Deterministic tie-break** | Sorting keys fixed: `(d_time_utc asc, d_ticket asc)` |

### 4.2 INVALID join scenarios (must be flagged, not “fixed silently”)

| Scenario | Classification |
|----------|----------------|
| Forward bar chosen | **FATAL** integrity violation (`FUTURE_LEAK`) |
| Symbol mismatch | `SYMBOL_MAP` / `FAIL` depending on policy |
| Period mismatch | `PERIOD_MISMATCH` |
| Duplicate ticket | `DUPLICATE_INPUT` |
| Telemetry duplicate `bar_utc` | `DUPLICATE_TELEMETRY_BAR` (strict QA) |
| Missing telemetry | `MISSING_TELEMETRY` / `ORPHAN_DEAL` per frozen distinction |

---

## 5. Determinism Requirements

| Area | Requirement |
|------|-------------|
| **Repeatability** | Same fixture bytes + same harness version → **identical** normalized output bytes |
| **Sort ordering** | Deals sorted by `(d_time_utc, d_ticket)` before optional counters (`deals_on_bar`) |
| **Tie-break** | Leader slot: **max strength**, tie → **lowest slot index** |
| **Duplicates** | Input duplicates → deterministic FAIL or deterministic de-dupe (frozen) |
| **UTC** | All comparisons on **long epoch seconds**; no `datetime` without timezone policy |
| **Float normalization** | Serialize with **fixed decimal places** per field in golden CSV (e.g. profits 2dp, ratios 8dp — freeze table) |
| **CSV normalization** | See §9 — golden files must be **byte-stable** |

---

## 6. Golden Expectation Artifacts

| File | Role in regression |
|------|---------------------|
| `expected_joined.csv` | Primary diff target; compared after canonical normalization pass |
| `expected_summary.txt` | Human-readable totals: rows, OK count, orphan count, min/median latency |
| `expected_validation.json` | Machine checks: histogram of `j_join_status`, max `j_bar_latency_sec`, SHA256 of normalized joined CSV |

### 6.1 Regression usage

1. Run harness on `Case_xxx/`.  
2. Emit `out_joined.csv` + `out_validation.json` to temp.  
3. Normalize (§9) both expected and actual.  
4. Compare: **hash equality** or **line-by-line diff** with stable newline.  
5. On mismatch: emit structured mismatch report (§8).

---

## 7. Validation Harness Design (`Tests/TestTelemetryJoinValidation.mq5` or equivalent)

### 7.1 Recommended placement

| Option | Pros |
|--------|------|
| `Experts/AurumSynapse/Tests/TestTelemetryJoinValidation.mq5` | Consistent with `TestTelemetryAnalytics.mq5` |
| `Scripts/AurumSynapse/RunJoinGoldenSuite.mq5` | Clear “not EA” separation |

**Recommendation:** `Tests/TestTelemetryJoinValidation.mq5` for MetaEditor compile parity with other tests.

### 7.2 Harness responsibilities (design-level)

1. **Load** case files from **`FILE_COMMON`** using relative paths under `JoinValidation_CommonFixtureRoot()` (see **PHASE_3B_FIXTURE_DEPLOYMENT_POLICY_V1**).  
2. **Parse** `telemetry.csv` using existing `CsvTelemetryReader` rules (V1).  
3. **Parse** `deals.csv` into `DealFact[]`.  
4. **Run** `JoinOnce_FixtureMode(...)` — minimal join prototype (when implemented).  
5. **Normalize** output per §9.  
6. **Compare** to golden expected artifacts.  
7. **Print** one-line summary:  
   `[JoinValidation] case=Case_001_BasicJoin PASS`  
   or  
   `[JoinValidation] case=Case_001_BasicJoin FAIL reason=FUTURE_LEAK row=3`

### 7.3 PASS / FAIL contract

- **PASS:** all JSON checks + joined CSV hash match.  
- **FAIL:** any rule violation; harness must exit non-zero in CI if supported, else print `FAIL` loudly.

---

## 8. Mismatch Analytics (Fast, Deterministic Debugging)

### 8.1 Mismatch report schema (recommended JSON)

```json
{
  "case": "Case_001_BasicJoin",
  "result": "FAIL",
  "first_mismatch_row": 3,
  "mismatch_class": "FUTURE_LEAK",
  "details": {
    "d_ticket": 900003,
    "d_time_utc": 1735690000,
    "j_bar_utc": 1735690300,
    "delta_sec": -300
  }
}
```

### 8.2 Mismatch classes

| Class | Meaning |
|-------|---------|
| `FUTURE_LEAK` | `j_bar_utc > d_time_utc` |
| `WRONG_BAR` | `j_bar_utc` not equal expected golden |
| `ORPHAN_MISMATCH` | status/count disagrees |
| `DUPLICATE_MISMATCH` | duplicate policy triggered incorrectly |
| `TIMEZONE_MISMATCH` | epoch conversions disagree with fixture metadata |
| `LIFECYCLE_MISMATCH` | partial OUT mapped to wrong bar vs golden |
| `CSV_NORMALIZATION` | byte diff resolved only after normalization — indicates harness drift |

---

## 9. CSV Normalization Policy (Byte-Stable Golden Files)

**Policy name:** `GOLDEN_CSV_NORMALIZATION_V1` (freeze for fixture suite)

| Topic | Rule |
|--------|------|
| **Delimiter** | ASCII comma `,` |
| **Newline** | **LF only** (`\n`) in repo-stored golden files (even on Windows); harness normalizes CRLF→LF on read if needed |
| **Encoding** | UTF-8 **without BOM** |
| **Float precision** | Fixed per column type table in `TelemetryFixtures/README.md` |
| **Datetime** | **No string datetimes inside golden joined** — only `long` epoch fields for join keys |
| **Null sentinels** | Same as telemetry V1 for `t_*` when status not OK — document per field |
| **Sorting** | Joined rows sorted by `(d_time_utc asc, d_ticket asc)` in outputs compared to golden |

**Why byte-stable:** Hash comparison is the fastest regression gate; CRLF churn must not fail CI.

---

## 10. Regression Test Strategy

### 10.1 Philosophy

> **Fixtures are the contract.**  
> Code is correct only when it reproduces golden outputs **exactly** under normalization policy.

### 10.2 On every join-engine change

| Gate | Action |
|------|--------|
| **Mandatory** | Replay **full minimum case set** (§3) locally + CI if available |
| **Output** | Must match golden hash / diff |
| **Additive evolution** | New cases append-only; do not rewrite old golden without migration note |

### 10.3 Failure escalation

| Level | Response |
|-------|----------|
| **L1** | Single case fails → block merge |
| **L2** | Golden file update required → requires **architect approval** + version bump `JOIN_SEMANTIC_VERSION` or `joined_major/minor` |
| **L3** | Policy change (e.g., orphan semantics) → update this doc + dataset finalization + new tag |

### 10.4 Freeze policy

- Golden outputs are frozen per **`JOIN_SEMANTIC_VERSION`**.  
- Changing semantics without bumping version is **forbidden**.

---

## 11. Implementation Sequencing (Safest Order)

| Step | Deliverable | Gate |
|------|-------------|------|
| **1** | Fixture folder schema + `deals.csv` spec + README templates | Review-only |
| **2** | Author **golden expected** outputs for Cases A–J | Human + peer review |
| **3** | Minimal join prototype: **only** Cases A–B | Must pass A–B |
| **4** | `TestTelemetryJoinValidation.mq5` skeleton: load + compare hashes | Must fail loudly on mismatch |
| **5** | Expand join to C–J; iterate golden files once | Full suite green |
| **6** | Only then: real analytics on **non-fixture** integrated smoke | Separate checklist |

---

## 12. Safety Boundary

The fixture suite and validation harness:

- are **read-only** with respect to markets and trading  
- **never** mutate EA inputs or runtime globals for trading  
- **never** call `CTrade` / order APIs  
- **never** implement adaptive behavior or feedback loops  
- may run in Strategy Tester or script context with **FILE_COMMON** read for telemetry **fixtures** only

---

## 13. Final Engineering Recommendation — Risks & Freeze

### 13.1 Biggest implementation risks

| Risk | Mitigation |
|------|------------|
| Accidental lookahead | Cases F + A assert invariants |
| Partial close mis-join | Case C golden strictness |
| “Helpful” auto-remap of symbols | Forbidden unless explicit fixture table |

### 13.2 Biggest determinism risks

| Risk | Mitigation |
|------|------------|
| CRLF / float formatting | §9 normalization |
| Unstable sort | §5 ordering |
| Local timezone leaks | Epoch-only + fixture offset metadata |

### 13.3 Biggest data integrity risks

| Risk | Mitigation |
|------|------------|
| Duplicate tickets | Case G |
| Duplicate telemetry bars | Strict QA case (optional Case_011 extension later) |

### 13.4 MUST remain frozen

- `AS_TELEMETRY_V1` layout & semantics  
- Join policy: **hybrid backward-only** (`PHASE_3B_PRE_IMPLEMENTATION_CHECKLIST.md`)  
- `AS_JOINED_V1` slim schema (`PHASE_3B_DATASET_FINALIZATION.md`)  
- Golden normalization policy (§9) once published

### 13.5 MAY evolve later

- Additional cases (netted accounts, multi-currency profits)  
- Integration harness against live `HistorySelect` (non-byte-stable)  
- Optional `expected_validation.json` schema v2 fields (minor)

---

## 14. Deliverable Control

| Document | Role |
|----------|------|
| **This file** | Golden fixture + validation harness **design** + regression policy |
| `PHASE_3B_DATASET_FINALIZATION.md` | Canonical slim fields |
| `PHASE_3B_PRE_IMPLEMENTATION_CHECKLIST.md` | Time/join semantics |
| `PHASE_3B_MASTER_DESIGN.md` | Module roadmap |

### Baseline implemented (validation foundation v0)

| Path | Status |
|------|--------|
| `Experts/AurumSynapse/TelemetryFixtures/README.md` | Created |
| `Experts/AurumSynapse/TelemetryFixtures/Case_001_BasicJoin/*` | **Source** in repo (UTF-8 **LF**) — **copy** to `Common\Files\AurumSynapse\TelemetryFixtures\Case_001_BasicJoin\` for harness |
| `TelemetryAnalytics/JoinValidationPrototype.mqh` | `FILE_COMMON` paths + `JoinValidation_CommonFixtureRoot()` / `JoinValidation_CommonFixtureAbsoluteRoot()` |
| `Tests/TestTelemetryJoinValidation.mq5` | Harness: existence diagnostics + golden line compare |

**Remaining:** Cases 002–010 fixtures + harness loop + optional SHA256 verify in-terminal.

---

*End of Phase 3B Golden Fixture & Validation Design.*
