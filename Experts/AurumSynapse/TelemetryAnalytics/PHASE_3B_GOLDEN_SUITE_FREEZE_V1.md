# PHASE 3B — Golden Fixture Suite V1 — **FREEZE** (canonical regression baseline)

**Document ID:** `PHASE_3B_GOLDEN_SUITE_FREEZE_V1`  
**Freeze effective (canonical):** 2026-05-11  
**Related milestone tag:** `PHASE_3B_GOLDEN_FIXTURE_SUITE_COMPLETE`  
**Suite identifier:** `GOLDEN_FIXTURE_SUITE_V1_FROZEN` (see `TelemetryFixtures/VERSION.txt`)

---

## A. PURPOSE

### Why the suite is frozen

The Golden Fixture Suite V1 (`Case_001` … `Case_010`) is the **first fully deterministic, byte-identical** regression surface for **deal ↔ telemetry join** semantics under **`AS_JOINED_V1` / `JOINED_SLIM`**. Freezing it converts the suite from **temporary validation scaffolding** into **regression law**: the **expected outputs and policies** documented here are the **contract** that any future **production join engine** must honor unless the project performs an **explicit version bump and migration**.

### Regression law (what “frozen” means)

From this freeze forward:

- **Fixture layout**, **CSV bytes** (`expected_joined.csv`), **JSON validation** (`expected_validation.json`), and **documented semantics** are **normative** for Suite V1.
- A **PASS** on `Tests/TestTelemetryJoinValidation.mq5` with **repo-aligned** `FILE_COMMON` mirrors is **necessary** for claiming **non-breaking** join behavior relative to Suite V1.
- **Silent drift** (logic changes that alter joined rows, ordering, lifecycle grouping, or serialization tokens without a documented migration) is **not allowed**.

### Relationship to a future production join engine

The current join path exercised by the harness is a **prototype / validation** implementation (`TelemetryAnalytics/JoinValidationPrototype.mqh`). A **production-grade** join engine (bounded lookback, batch export, scale) is a **separate deliverable** but **not a separate semantics world**: it must remain **compatible** with Suite V1 outputs **or** ship under a **new joined artifact version** (e.g. `AS_JOINED_V2`) with **updated fixtures**, **frozen docs**, and an **auditable migration note**.

---

## B. FROZEN CASE MATRIX

Official frozen behavior (one row per golden case):

| Case | Frozen behavior |
|------|-----------------|
| `Case_001_BasicJoin` | Normal **backward-only** join: eligible telemetry bar is **`MAX(bar_utc ≤ d_time_utc)`**; standard **`JOINED_SLIM`** row shape. |
| `Case_002_OrphanDeal` | **`ORPHAN_DEAL`** semantics when no backward-eligible telemetry exists; **no synthetic** telemetry fabrication. |
| `Case_003_DuplicateCandidateJoin` | **Deterministic multi-candidate resolution**: among bars with **`bar_utc ≤ d_time_utc`**, select **`MAX(bar_utc)`** (tie policy as validated in suite + `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md` §A3). |
| `Case_004_FutureLeakProtection` | **Future-leak prevention**: bars strictly **after** deal time are **ineligible**; no nearest-forward, no interpolation. |
| `Case_005_MissingTelemetryRow` | **Missing telemetry** / gap handling: **no fill-in**; join reflects **honest gap** behavior per frozen harness output. |
| `Case_006_DuplicateDealTicket` | **Duplicate `d_ticket`** in `deals.csv`: **canonical single deal row** selection + **one** join output per frozen policy (§A6 in validation doc). |
| `Case_007_PartialCloseLifecycle` | **Partial-close lifecycle** at **deal grain**: multiple deals for one position; **stable `(d_time_utc, d_ticket)` ordering** before join. |
| `Case_008_PositionRollup` | **Position rollup annotations** (`x_lifecycle_*`): **deterministic grouping + seq** for shared **`d_position_id`** without collapsing to a single aggregate export row. |
| `Case_009_MultiDealPositionAttribution` | **Multi-context / multi-deal attribution**: per-deal **`t_*` / regime / quality** reflect **that deal’s** backward-eligible bar (incl. **two deals, one bar** control). |
| `Case_010_TimezoneEdge_StaticOffset` | **UTC edge + static offset metadata** consistency: proves backward-only policy at a boundary; **`server_utc_offset_sec`** (or equivalent metadata) is **not** used as join input unless explicitly specified elsewhere. |

**Normative detail:** per-case READMEs + `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md` (**§A1–A10**).

---

## C. CANONICAL POLICIES (frozen)

### 1. `BACKWARD_ONLY_JOIN_POLICY_V1`

**Join bar selection:**

\[
j\_\text{bar\_utc} = \max(\text{bar\_utc} \mid \text{bar\_utc} \le d\_\text{time\_utc})
\]

**Hard exclusions:**

- **No nearest-forward** selection from bars with `bar_utc > d_time_utc`.
- **No interpolation** between bars.
- **No** “best guess” telemetry for missing rows beyond what Suite V1 encodes as **expected** output.

### 2. `GOLDEN_CSV_NORMALIZATION_V1`

Committed golden CSV in the repo **must** conform to:

- **UTF-8** encoding  
- **LF only** (`\n`) — **no CRLF** in committed golden CSV  
- **No BOM**  
- **Deterministic newlines** (no trailing ambiguity; each file ends consistently as per repo convention already validated)  
- **Canonical column ordering** = `JOINED_SLIM` / harness contract (see `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md`)

### 3. `CANONICAL_RUNTIME_SERIALIZATION_POLICY_V1`

**Runtime serialization is the source of truth** for numeric string tokens (including `DoubleToString` width, `TELEMETRY_NULL_DOUBLE` representation, and delimiter-stable fields). Golden `expected_joined.csv` **must match** what the MQL5 harness writes **byte-for-byte** under the frozen policy.

### 4. `FILE_COMMON_DEPLOYMENT_POLICY_V1`

- **Repository** (`MQL5/Experts/AurumSynapse/TelemetryFixtures/`): **authoritative source of truth** (version controlled).  
- **`Terminal\Common\Files\AurumSynapse\TelemetryFixtures\`**: **runtime mirror only** — deploy by **copy** from repo; **do not** “hand edit” golden bytes under Common and treat them as canonical.  
- Stale Common copies are a known source of **false failures** (`line_mismatch`) when repo golden bytes advance but Common does not.

---

## D. DETERMINISM REQUIREMENTS

Frozen suite **requires**:

| Requirement | Definition |
|-------------|------------|
| **Deterministic replay** | Same inputs (`telemetry.csv`, `deals.csv`, frozen harness build) ⇒ **identical** joined output bytes. |
| **Stable ordering** | Deal ordering and tie-breaks follow frozen canonical sorts documented in validation spec / case READMEs. |
| **Stable lifecycle grouping** | `x_lifecycle_group_id` / `x_lifecycle_seq` stable for Case_008/009/007 scenarios as per expected CSV. |
| **Stable attribution** | Per-deal attribution fields stable under backward-only bar selection (Case_009). |
| **Byte-identical validation** | Harness compares **entire line strings** (not tolerant float compare) unless a **new suite version** explicitly changes that policy. |

---

## E. NON-GOALS (explicitly out of scope for Suite V1 freeze)

Suite V1 freeze **does not** claim or require:

- **Adaptive AI** or online learning  
- **Governance loops** or auto-orchestration  
- **Survivability analytics** (production)  
- **Toxicity engine** (production)  
- **Production position rollup analytics** beyond the **annotation-level** contracts proven in Case_008  
- **ML training** datasets / labels  
- **Probabilistic matching** or fuzzy time alignment  

Those belong to **later phases** with **separate specs** and **separate baselines**.

---

## F. REGRESSION POLICY (breaking changes)

Any future change that breaks any of:

- `expected_joined.csv` line equality  
- **Canonical serialization** tokens / column layout  
- **Lifecycle ordering / grouping** semantics as encoded by golden CSV  
- **Attribution semantics** (per-deal bar choice and field propagation)  

**MUST**:

1. **Justify** the change in a **migration note** (why prior law was insufficient; what user-visible behavior changes).  
2. **Bump version** (joined artifact version, suite version, and/or harness **semantic version** — pick explicitly in the migration note).  
3. **Update frozen docs**: at minimum this file + `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md` + relevant case READMEs + roadmap addendum.  
4. **Update golden fixtures** (`expected_joined.csv`, `expected_validation.json` as needed) **and** record an **expected content checksum** in the migration note or an optional manifest (recommended: **SHA-256 per `expected_joined.csv`** in release notes or a small `FIXTURE_SHA256_MANIFEST.txt` added alongside a version bump — **optional mechanism**, **mandatory transparency**).

**No silent behavior drift:** CI / human reviewers should treat unexpected golden diffs as **either** a bug **or** an undeclared breaking change.

---

## G. NEXT PHASE (roadmap pointer)

Planned work **after** Suite V1 freeze (indicative ordering):

1. **Production-grade Join Engine** (scale + bounded lookback + exporter) — **compatibility** with Suite V1 unless versioned otherwise.  
2. **`POSITION_ROLLUP_V1` formalization** (distinct artifact from deal-grain join).  
3. **Survivability Analytics**  
4. **Toxicity Analytics**  
5. **Causal Validation Layer** (broader causal checks beyond join harness)  
6. **Governance & Adaptive Intelligence** (explicitly late; **not** implied by Suite V1)

---

## References

- `TelemetryAnalytics/PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md`  
- `Experts/AurumSynapse/TelemetryFixtures/README.md`  
- `Experts/AurumSynapse/Tests/TestTelemetryJoinValidation.mq5`  
- `Experts/AurumSynapse/TelemetryAnalytics/JoinValidationPrototype.mqh` (**prototype**, not production engine)  
- `Experts/AurumSynapse/Tests/POST_COMPLETION_VALIDATION_ROADMAP.md` (program-level status)
