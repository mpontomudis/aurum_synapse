# PHASE 4 — POSITION_ROLLUP_V1 — Formalization (Lifecycle Intelligence Foundation)

**Status:** **COMPLETE** — formal specification + deterministic library surface (`PositionRollupV1.mqh`). **Harness:** `Tests/TestPositionRollupV1.mq5`. **Roadmap:** `Tests/POST_COMPLETION_VALIDATION_ROADMAP.md` (Telemetry intelligence milestones).  
**Depends on (frozen):** Golden Fixture Suite V1, `JoinValidationPrototype.mqh` canonical ordering/parsing  
**Does not modify:** `expected_joined.csv`, fixture bytes, `PHASE_3B_GOLDEN_SUITE_FREEZE_V1.md`, `TelemetryFixtures/VERSION.txt`, AS_JOINED_V1 serialization tokens

---

## 1. Architecture

### 1.1 Layering

| Layer | Role |
|-------|------|
| **AS_JOINED_V1 / JOINED_SLIM** | Deal-grain causal join output (frozen law). |
| **POSITION_ROLLUP_V1** | **Abstraction above deals**: one **lifecycle campaign** per shared `d_position_id`, deterministic **staging order**, **exposure path**, **linear normalized graph**. |

`POSITION_ROLLUP_V1` **reads deal facts** (via canonical CSV helpers). It **does not** emit joined CSV columns and **does not** change join selection or serialization.

### 1.2 Core objects (code)

- **`SRollupDealStepV1`** — one deal row after **canonical sort** `(d_time_utc ASC, d_ticket ASC)`; carries `lifecycle_seq`, cumulative closed volume, `exposure_remaining` after the step.
- **`SRollupPositionCampaignV1`** — immutable summary for one `d_position_id` campaign after a full scan.
- **`SRollupGraphEdgeV1`** — directed edges `(seq → seq+1)`; **linear chain only** (partial closes do not branch into new lifecycles).
- **`SRollupReplayBufferV1`** — optional **append-only** step log for identical replay audits.

**Lifecycle entity fields (formal mapping):** `lifecycle_group_id` / `root_position_id` → `SRollupPositionCampaignV1.lifecycle_group_id` (same as `d_position_id` in V1); `lifecycle_seq` → `SRollupDealStepV1.lifecycle_seq`; `lifecycle_open_time` / `lifecycle_close_time` → `lifecycle_open_time_utc` / `lifecycle_close_time_utc` on the campaign; `lifecycle_state` / `exposure_state` → `lifecycle_state` + per-step `exposure_state_after` + `terminal_exposure_state`.

### 1.3 Position memory (abstraction)

Within one campaign:

- **Total campaign volume** — `sum(|d_volume|)` over ordered deals (deterministic input aggregate).
- **Cumulative closed** — running sum of `|d_volume|` along canonical order.
- **Exposure remaining (V1 model)** — `total_abs_volume − cumulative_closed` after each step (monotone toward zero for full flat campaigns).

This is a **formal exposure path** for survivability-ready consumption later — **not** MT5 net-profit analytics and **not** signed net exposure by direction in V1 (non-goal; future extension).

---

## 2. Invariants (Lifecycle Law)

1. **POSITION_ID first** — `lifecycle_group_id == root_position_id == d_position_id` for all steps in a valid campaign.
2. **Single lifecycle per graph** — all input deals **must** share one `d_position_id`; otherwise `multi_position_id` error (no fuzzy merge).
3. **Canonical order only** — lifecycle sequence derives exclusively from `JoinValidation_SortDealCsvDataLinesByTimeThenTicket` (same as golden harness).
4. **Partial close ≠ new position** — multiple deals, one `d_position_id` → **one** campaign object; no automatic splitting into new lifecycle ids.
5. **Immutable history** — `PositionRollupV1_BuildFromDealsUtf8Lf` returns a **new** snapshot; callers do not rewrite prior snapshots in-library (append-only discipline via `SRollupReplayBufferV1` if used).
6. **No nearest-forward** — rollup consumes **deal CSV facts only**; no telemetry join in this module.
7. **Deterministic replay** — same UTF-8 deals input → identical `SRollupDealStepV1[]`, campaign summary, and fingerprints.

---

## 3. Deterministic guarantees

- Integer `lifecycle_seq` is **0-based index** after canonical sort (aligns with `x_lifecycle_seq` semantics used in joined slim extensions for Case_008-class fixtures, conceptually).
- **Graph normalization:** `n` deals → **max(0, n−1)** edges, strictly `i → i+1`; no duplicated branches, no orphan fragments when validation passes.
- **Floating policy:** fingerprints scale doubles to fixed integer scale for **equality checks in tests**; internal model uses `double` only where deal CSV already uses doubles (same as join layer).

---

## 4. Non-goals (this phase)

- Survivability scores, toxicity, PnL attribution quality, regime labels.
- ML, adaptive governance, probabilistic clustering of lifecycles.
- `AS_JOINED_V2` or joined column layout changes.
- Modifying `ProductionJoinEngine.mqh` join outputs or golden bytes.

---

## 5. Future compatibility

- **Signed exposure / direction-aware staging** — optional V1.1+ extension behind new struct fields (not enabled here).
- **Multi-instrument campaigns** — rejected implicitly (single `d_symbol` per deal set not enforced in V1; callers may pre-filter).
- **Cross-position netting** — explicitly out of scope.

---

## 6. References

- `TelemetryFixtures/Case_007_PartialCloseLifecycle/README.md`  
- `TelemetryFixtures/Case_008_PositionRollup/README.md`  
- `PHASE_3B_GOLDEN_SUITE_FREEZE_V1.md`  
- `JoinValidationPrototype.mqh` — deal sort / parse helpers  

---

**Document ID:** `PHASE_4_POSITION_ROLLUP_V1_FORMALIZATION`  
**Code module:** `PositionRollupV1.mqh`
