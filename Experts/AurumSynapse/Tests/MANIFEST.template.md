# Aurum Synapse — Snapshot manifest (TEMPLATE)

**Instructions:** Copy this file to your archive root (e.g. `AurumSynapse_Archive/MANIFEST_<YYYYMMDD_HHMM>.md`) **or** to `Tests/MANIFEST_<run-id>.md` before a risky session. Fill every **REQUIRED** field. Remove optional blocks you do not use.

---

## REQUIRED — Identity

| Field | Value |
|-------|--------|
| **Manifest ID** | `MANIFEST_YYYYMMDD_HHMM` (e.g. `MANIFEST_20260511_1430`) |
| **Created (UTC or local — state which)** | |
| **Operator** | |
| **Purpose of snapshot** | (e.g. pre–STEP 1A telemetry, pre-refactor RiskManager, release candidate) |

---

## REQUIRED — Source control

| Field | Value |
|-------|--------|
| **Repository path** | |
| **Remote URL** (if any) | |
| **Branch** | |
| **Commit SHA (full)** | |
| **Clean working tree?** | `yes` / `no` — if no, list uncommitted files below |
| **Git tag created for this snapshot** | (e.g. `snap-20260511-1430`) |

**Uncommitted / local patches (if any):**

```
(paste git status -sb or file list)
```

---

## REQUIRED — Build / binary

| Field | Value |
|-------|--------|
| **EA file** | `Experts/AurumSynapse/AurumSynapse.mq5` |
| **`#property version`** (from `.mq5`) | |
| **`EA_VERSION` / build string** (from `OnInit` log if printed) | |
| **`AurumSynapse.ex5` path** | (Terminal `MQL5/Experts/...`) |
| **MetaEditor compile** | `0 errors` / `errors: ___` |
| **MT5 build** (Help → About) | |

---

## REQUIRED — Strategy Tester lock (reproducibility)

| Field | Value |
|-------|--------|
| **Symbol** | (e.g. `XAUUSD`) |
| **Period** | (e.g. `M5`) |
| **Model** | (e.g. Every tick based on real ticks) |
| **From — To** | |
| **Deposit** | |
| **Leverage** | |
| **`.set` filename** | (full path or copy stored next to zip) |
| **Magic number** | |
| **`InpMaxSpreadPoints`** | |
| **`InpMinQualityScore` / `InpMinConsensus`** | |
| **`InpLotMethod` + lot-related inputs** | |
| **`InpMaxEquityDD` / `InpMaxDailyLossPct` / `InpMaxConsecutiveLosses`** | |
| **Strategies ON** (list) | |

**Canonical row reference (if applicable):** (e.g. §Test 3.1 / roadmap checkpoint id)

---

## REQUIRED — Artifacts bundled with this snapshot

Check what was copied into the archive zip / folder:

| Artifact | Included? |
|----------|-----------|
| Full `Experts/AurumSynapse/` sources | [ ] |
| `Tests/` (incl. this roadmap) | [ ] |
| Matching `.set` | [ ] |
| `AurumSynapse.ex5` | [ ] |
| Tester **Report** HTML/XML export | [ ] |
| Tester **Journal** excerpt or full `Agent-.../logs/*.log` | [ ] |
| Optimization result XML (if run) | [ ] |
| `git bundle` file name | [ ] |

**Archive zip / bundle filenames:**

```
(list paths, e.g. D:\AurumSynapse_Archive\zip-snapshots\AS2_20260511_1430_src.zip)
```

---

## OPTIONAL — Smoke / regression gate

| Metric | Expected band (from last green) | This snapshot result |
|--------|-----------------------------------|-------------------------|
| **Total trades** (Backtest tab) | | |
| **Profit factor** | | |
| **Max equity DD %** | | |
| **Net profit** | | |
| **Tester wall time** (Journal footer) | | |

**Pass / Fail:**  

**Notes if Fail:**

---

## OPTIONAL — Telemetry (STEP 1A+)

| Field | Value |
|-------|--------|
| **Telemetry enabled?** | `yes` / `no` |
| **Mode** | `off` / `shadow` / `file` |
| **Output path** | |
| **Max rows / rotation** | |
| **Format version** | (e.g. `AS_TELEMETRY_V1`) |

---

## OPTIONAL — Recovery notes

**To restore this snapshot:**

1. `git checkout <tag>` **or** unzip `___`  
2. Restore `.set` to Tester profiles  
3. F7 compile  
4. Run smoke `.set` above and compare **Smoke / regression gate** table  

**Known issues in this snapshot (if any):**

---

**End of manifest**
