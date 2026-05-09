# AURUM SYNAPSE - POST-COMPLETION VALIDATION ROADMAP
## From Development Complete → Production Trading

**Version:** 2.0  
**Status:** Phase 1 complete — **Phase 2** — **§2.4 Require sweep ✅** (`2.4.A`–`2.4.D` logged); **FY net-max lock** still **`2.2.D`** (Q**60**, all Require **false**) — **P0:** H2 silence + **`2.4.C`** Inputs verify  
**Last Updated:** May 10, 2026 — **§Test 3.5 SmartMoney** user **Q60** FY isolation **verified** (**1** tr, net **+$96.35**, long-only); post **`SmartMoney.mqh` Phase 3A++ v3** (BOS bar0|1, ×ATR **0.45**, momentum **OR**, **CALM** regime); **§Test 3.4 SupplyDemand** **212** tr; **§Test 3.8 MomentumScalp** **126** tr; **§Test 3.7 GridRecovery** **18** tr

---

## 🎯 OVERVIEW

EA development is **COMPLETE** ✅  
**Phase 1 (Basic Functionality)** is **COMPLETE** ✅ (May 7, 2026)

**Validated:** 1-month XAUUSD M5 backtest (2025-01-01 → 2025-01-31), ultra-permissive inputs, real ticks — **15 total trades**, no Stack overflow / OnTester critical error in final run. SL/TP direction and distances consistent with XAUUSD handling.

**This document provides:**
- ✅ Step-by-step debugging workflow
- ✅ Clear checkpoints with expected results
- ✅ Troubleshooting at each stage
- ✅ Progress tracking system
- ✅ Decision points (GO/NO-GO/FIX)

---

## 📋 VALIDATION PHASES (6 PHASES)

```
Phase 1: BASIC FUNCTIONALITY TEST      → Get ANY trade to execute
Phase 2: FILTER CALIBRATION & PERFORMANCE VALIDATION → Quality ladder; one variable/test; WR target 70–75%
Phase 3: STRATEGY VALIDATION           → Test each strategy individually
Phase 4: RISK SYSTEM VERIFICATION      → Confirm circuit breakers work
Phase 5: PERFORMANCE OPTIMIZATION      → Tune for target metrics
Phase 6: PRODUCTION READINESS          → Final validation before live
```

**Estimated Time:** 2-4 days (2-4 hours per phase)

---

---

# PHASE 1: BASIC FUNCTIONALITY TEST (2-3 hours)
## Goal: Make EA execute AT LEAST ONE TRADE — **ACHIEVED** ✅

### ✅ PHASE 1 OUTCOME (May 7, 2026)

| Item | Result |
|------|--------|
| **Reference backtest** | XAUUSD, M5, 2025-01-01 → 2025-01-31, Every tick based on real ticks |
| **Total trades (MT5 Backtest tab)** | **15** (meets ≥10 for Phase 1) |
| **Stability** | No Stack overflow / no OnTester critical error in successful run |
| **SL/TP** | Valid for XAUUSD (e.g. BUY: SL below entry, TP above; wide min distances as configured) |

**Blockers resolved during May 6–7 validation (for long backtests):**

1. **`Logger::CheckDateChange()` infinite recursion** — `Info()` → `Log()` → `CheckDateChange()` → `Info()` … → **stack overflow** at midnight. Fixed in `UI/Logger.mqh` (rotate file without calling `Log()`/`Info()` from inside `CheckDateChange()`).
2. **`StrategyManager::GetAllSignals()`** — removed unsafe `ArrayResize()` on caller arrays; copy by capacity only (`Engine/StrategyManager.mqh`).
3. **`BaseStrategy` constructor** — removed illegal `ArrayResize()` on fixed `m_activeRegimes[4]` (`Strategies/BaseStrategy.mqh`).
4. Earlier: new-bar `OnTick`, XAUUSD SL/TP minimums, conditional `Sleep()` in tester, `InpMinConsensus` input, etc.

**Note:** Journal line *"Total Trades: 5781"* from EA `OnDeinit` is **not** MT5’s “Total Trades” — it reflects internal bar/counter naming; use the **Strategy Tester → Backtest** summary for official trade count.

---

### ✅ CHECKPOINT 1.1: Verify Compilation

**What to do:**
```
1. Open MetaEditor (F4)
2. Open: Experts/AurumSynapse/AurumSynapse.mq5
3. Press F7 (Compile)
4. Check Toolbox → Errors tab
```

**Expected Result:**
```
✅ 0 errors, 0 warnings
✅ "0 error(s), 0 warning(s)" in status bar
✅ AurumSynapse.ex5 generated
```

**If FAILED:**
- [ ] Check error message
- [ ] Fix compilation errors
- [ ] Re-compile until clean

**Status:** [x] PASS [ ] FAIL

---

### ✅ CHECKPOINT 1.2: Download Historical Data

**What to do:**
```
1. MT5 → View → Symbols (Ctrl+U)
2. Find XAUUSD
3. Right-click → "Ticks" → Download ticks for 2020-2025
4. Wait for download to complete (may take 10-30 min)
5. Close Symbol window
```

**Expected Result:**
```
✅ Data downloaded for full period
✅ Progress bar reaches 100%
✅ No error messages
```

**If FAILED:**
- [ ] Check internet connection
- [ ] Try shorter period (2024 only)
- [ ] Switch data server if available

**Status:** [x] PASS [ ] FAIL

---

### ✅ CHECKPOINT 1.3: Ultra-Permissive Test (CRITICAL!)

**Purpose:** Strip ALL filters to see if EA can trade AT ALL

**Settings for Strategy Tester:**
```
Expert:     AurumSynapse
Symbol:     XAUUSD
Period:     M1
Dates:      Use ANY 1-month period with available tick data
           (Recommended: 2025.01.01 - 2025.01.31 if 2024 data is missing)
Model:      Every tick based on real ticks
Deposit:    10000
Leverage:   1:500
Optimization: Disabled
Visual mode: Unchecked
```

**CRITICAL INPUT SETTINGS (Ultra-Permissive):**
```
=== STRATEGY ACTIVATION ===
InpUseTrendFollowing    = true
InpUseBreakout          = true
InpUseMeanReversion     = true
InpUseSupplyDemand      = true
InpUseSmartMoney        = true
InpUsePriceAction       = true
InpUseGridRecovery      = false   ← Keep OFF (risky)
InpUseMomentumScalp     = true

=== QUALITY FILTER (LOOSEN!) ===
InpMinQualityScore      = 30      ← VERY LOW! (was 70)
InpRequireTrendAlignment= false   ← OFF (note: full name in EA)
InpRequireKeyLevel      = false   ← OFF
InpRequireMomentum      = false   ← OFF

=== CONSENSUS (LOOSEN!) ===
InpMinConsensus         = 1       ← Just 1 strategy needed!

=== LOT SIZING ===
InpLotMethod            = 0       ← Fixed lot
InpFixedLot             = 0.01
InpAutoLotRisk          = 1.0

=== TP/SL (KEEP DEFAULTS) ===
InpTPCoefficient        = 2.0     ← TP distance = SL distance × this coefficient
InpSLPoints             = 100     ← SL distance in *points* (EA derives TP)
InpUseTrailing          = false   ← OFF for Phase 1 stability

=== TIME FILTER (DISABLE ALL!) ===
InpUseTimeFilter        = false   ← OFF
InpTradeMon             = true
InpTradeTue             = true
InpTradeWed             = true
InpTradeThu             = true
InpTradeFri             = true

=== RISK LIMITS (KEEP SAFE) ===
InpMaxDailyLossPct      = 5.0
InpMaxEquityDD          = 12.0
InpMaxConsecutiveLosses = 5       ← Increase from 3
InpMaxOpenPositions     = 5

=== SPREAD FILTER (LOOSEN!) ===
InpMaxSpreadPoints      = 50      ← Was 30

=== UI (CRITICAL FOR BACKTEST!) ===
InpShowPanel            = false   ← MUST BE FALSE!
InpShowStrategySignals  = false
```

**Click START and wait...**

---

### ✅ CHECKPOINT 1.4: Analyze Ultra-Permissive Results

**Expected Result A (IDEAL):**
```
✅ Total Trades: 100+ (in 1 month)
✅ Some wins, some losses (doesn't matter yet)
✅ Graph shows activity
✅ No flat line
```

**Action if Result A:**
```
→ PROCEED to CHECKPOINT 1.5
→ EA is functional, just needs tuning
```

---

**Expected Result B (PARTIAL):**
```
⚠️ Total Trades: 1-20 (very few)
⚠️ Graph mostly flat with tiny movements
```

**Action if Result B:**
```
→ Go to Journal tab
→ Look for messages like:
   - "Quality score too low"
   - "No consensus"
   - "Spread too high"
→ Screenshot Journal
→ PROCEED to TROUBLESHOOTING B
```

---

**Expected Result C (STILL BROKEN):**
```
❌ Total Trades: 0
❌ Completely flat graph
❌ History Quality still 0%
```

**Action if Result C:**
```
→ Go to Journal tab
→ Screenshot ALL messages
→ Look for:
   - Initialization errors
   - Indicator handle failures
   - "Invalid handle"
   - Division by zero
→ PROCEED to TROUBLESHOOTING C
```

---

### 🔧 TROUBLESHOOTING B: Few Trades (1-20)

**Diagnosis Steps:**

1. **Check Journal for rejection reasons**
```
Journal → Look for:
- "Quality score: XX (required: 30)" → Lower InpMinQualityScore to 20
- "Spread XX points > max 50" → Increase InpMaxSpreadPoints to 100
- "No consensus: 0 signals" → Check strategy initialization
```

2. **Try even more permissive:**
```
InpMinQualityScore = 10    ← Almost nothing
InpMinConsensus = 1        ← Just 1 strategy
InpMaxSpreadPoints = 100   ← Very wide
```

3. **Test on different month:**
```
Try: 2024.06.01 - 2024.06.30 (June, more volatile)
```

**If still <10 trades:**
```
→ PROCEED to TROUBLESHOOTING C
```

---

### 🔧 TROUBLESHOOTING C: Zero Trades

**Critical Checks:**

**1. Check Journal for initialization:**
```
Look for:
✅ "StrategyManager initialized with 8 strategies"
✅ "MarketAnalyzer initialized"
✅ "QualityFilter initialized"
✅ "SignalManager initialized"
✅ "TradeManager initialized"

❌ If ANY "FAILED TO INITIALIZE" → Logic bug in EA
```

**2. Check for indicator errors:**
```
Look for:
❌ "Invalid handle for ATR"
❌ "Invalid handle for ADX"
❌ "CopyBuffer failed"

→ If found: Indicator data not available
→ Solution: Use "Every tick" model, not "1 minute OHLC"
```

**3. Check data availability:**
```
Strategy Tester → Settings → "Show Visual Mode"
Re-run test
Watch chart for 5-10 minutes

Do you see:
✅ Price bars moving?
✅ Time advancing?
❌ Frozen chart? → Data issue
```

**4. Emergency diagnostic mode:**
```
Add this to EA inputs:
InpDebugMode = true  (if available)

OR

Edit AurumSynapse.mq5:
In OnTick(), add at very top:

void OnTick() {
    Print("OnTick called at: ", TimeCurrent());
    
    // Rest of code...
}

Recompile, re-run
Check Journal → Should see "OnTick called" messages
If not → EA not being called by MT5
```

**If still broken:**
```
→ Possible MT5 issue
→ Try Strategy Tester on different PC
→ Or send me:
   1. Journal screenshot (full)
   2. Settings screenshot
   3. Graph screenshot
→ I'll debug further
```

**Status:** [x] PASS [ ] FAIL (Result B: 15 trades in 1 month — acceptable for Phase 1 stability goal)

---

### ✅ CHECKPOINT 1.5: Verify Trade Execution Details

**Only do this if you got trades in 1.4!**

**What to check:**
```
1. Click "Backtest" tab
2. Look at first few trades:
   - Entry price
   - Exit price
   - Profit/Loss
   - Duration
   - Comment field (should show strategy name)
```

**Expected:**
```
✅ Trades have different entry/exit prices
✅ Some profitable, some losses
✅ Duration varies (not all identical)
✅ Comment shows which strategy triggered
```

**If weird patterns:**
```
⚠️ All trades identical profit/loss → Possible TP/SL bug
⚠️ All trades <1 minute → Too aggressive
⚠️ No comment field → Logging issue (minor)
```

**Status:** [x] PASS [ ] FAIL [ ] N/A

---

### 📊 PHASE 1 COMPLETION CHECKLIST

Mark each as complete:

- [x] 1.1: EA compiles without errors
- [x] 1.2: Historical data downloaded for test period
- [x] 1.3: Ultra-permissive test configured and run
- [x] 1.4: Result analyzed (A/B/C determined) — **B** (15 trades, stable completion)
- [x] 1.5: Trade execution details verified (if applicable)

**DECISION POINT:**

```
IF Phase 1 PASS (got 100+ trades):
   → PROCEED TO PHASE 2 ✅

IF Phase 1 PARTIAL (got 1-20 trades):
   → If ≥10 trades AND no critical tester errors: treat as Phase 1 PASS for *functionality* ✅ → PROCEED TO PHASE 2
   → If <10 OR crashes: fix before Phase 2 ⚠️

IF Phase 1 FAIL (0 trades):
   → STOP ❌
   → Review troubleshooting
   → Seek additional support
   → DO NOT proceed to Phase 2
```

**Phase 1 Status:** [x] PASS [ ] PARTIAL [ ] FAIL

**Date Completed:** May 7, 2026

**Notes:**
```
- 1-month M5 XAUUSD (Jan 2025): 15 trades, History quality ~96%, no stack overflow in final run.
- Root cause of long-test crash: Logger::CheckDateChange() recursion — fixed in UI/Logger.mqh.
- StrategyManager/BaseStrategy fixes for tester stability (no ArrayResize on caller/static arrays).
- Optional cleanup: rename OnDeinit "Total Trades" log to avoid confusion with MT5 report (internal bar counter).
- Next: Phase 2 — quality threshold sweep (do not expect Phase 1 trade counts in Phase 2).
```

---

# PHASE 2: FILTER CALIBRATION & PERFORMANCE VALIDATION

**Prerequisites:** ✅ Phase 1 PASSED (EA can execute trades)

## Objective

Calibrate filters and validate performance with a **controlled engineering** process — **not** random or multi-parameter optimization.

### Primary goals

- **Stable profitability** — interpret robustness over the test window; avoid single lucky runs.
- **Healthy trade frequency** — enough trades for statistics without meaningless churn.
- **Low drawdown** — acceptable max DD relative to net result and risk appetite.
- **Target win rate 70–75%** — document what the ladder actually achieves; treat 70–75% as a **design target**, not guaranteed.
- **Realistic live behaviour** — same symbol, model, and deposit assumptions as you intend for demo/live.

### Testing methodology (non‑negotiable)

| Rule | Detail |
|------|--------|
| **One variable per test** | Change **exactly one** input vs the locked baseline; keep all other inputs identical. |
| **Same comparison set every run** | Record: **trade count**, **win rate**, **profit factor**, **max drawdown %**, **net profit**. |
| **No simultaneous multi-parameter tuning** | Do not run genetic / multi-input optimization for this phase. Finish the quality ladder first. |

### Constant settings (unless a later checkpoint explicitly overrides)

| Parameter | Value |
|-----------|--------|
| Symbol | **XAUUSD** |
| Model | **Every tick based on real ticks** |
| Deposit | **USD 10,000** |
| Leverage | **1:500** |
| Timeframe | **M5** (unless a written test plan specifies otherwise) |

### Current focus

**Quality ladder calibration** — baseline at `InpMinQualityScore = 30` (Checkpoint **2.1**), then steps **2.2.A–E** changing **only** the quality score between runs. Analyze the pattern in Checkpoint **2.3**.

*Time:* Treat Phase 2 as **multiple tester sessions** (not a single 2–3 hour block).

---

### ✅ CHECKPOINT 2.1: Baseline Test (Quality = 30)

**Purpose:** Establish baseline performance with loose filters

**Kickoff (repo):** ✅ **2026-05-08** — configuration below is the active baseline run. **Next:** execute in MT5 Strategy Tester and replace the placeholders in **Record Results** with values from the **Backtest** tab (then mark **COMPLETE**).

**Settings:**
```
Expert:     AurumSynapse
Symbol:     XAUUSD
Period:     M5
Dates:      2025-01-01 - 2025-12-31 (full year)   ← lock this range for the entire quality ladder
Model:      Every tick based on real ticks
Deposit:    10000
Leverage:   1:500
InpShowPanel = false  ← required

All inputs match Phase 1 ultra-permissive profile EXCEPT:
InpMinQualityScore = 30   ← baseline
InpMinConsensus = 1
InpRequireTrendAlignment = false
InpRequireKeyLevel = false
InpRequireMomentum = false
```

**Run backtest**

**Record Results:** *(source: Strategy Tester → **Backtest** tab; not Journal `Total Trades`)*  
```
Total Trades:     45
Win Rate:         22.22%
Profit Factor:    0.53
Max Drawdown:     12.75%   (equity max; balance max 12.20%)
Net Profit:       $-817.02
Gross profit:     $928.85  |  Gross loss:  -$1,745.87
History quality:  99%
Short / Long:     25 shorts (0% won) | 20 longs (50% won)
```

**Expected (reference only — your sample is far outside):**
```
✅ Trades: 2000-5000 (roadmap guess for loose filters)
⚠️ Win Rate: 55-65% (low quality, high volume)
⚠️ Profit Factor: 1.2-1.8 (marginal)
```

**Post-run notes (2025 FY, Q=30):**
- **No critical tester errors** in Journal snippet (clean shutdown). **Ignore** Journal line `Total Trades: 70875` — same class of misleading counter as Phase 1; official count = **45** (Backtest tab).
- **Activity gap:** entries ~Jan–Mar only; **no trades Apr–Dec** on distribution chart — treat as **P0 investigation** (session/risk/regime/data or logic) before trusting any ladder conclusion.
- **Short side:** 25 shorts, **0%** wins → **validate SELL SL/TP and short signal quality** before scaling quality ladder.
- **Quality vs targets:** WR 22% / PF 0.53 / net negative → **not acceptable** for Phase 2 goals (70–75% WR design target).

**Status:** [x] COMPLETE | **Started:** ✅ 2026-05-08 | **Recorded:** ✅ (2025 FY baseline)

---

### ✅ CHECKPOINT 2.2: Test Quality Thresholds

**Method:** Between tests **2.2.A → 2.2.E**, change **only** `InpMinQualityScore`. Period, symbol, model, deposit, leverage, timeframe, and all other inputs must match Checkpoint **2.1**.

**Naming:** Roadmap **2.2.A = Q40**, **2.2.B = Q50**, **2.2.C = Q60**, **2.2.D = Q70**, **2.2.E = Q80**. Lab IDs can shift (e.g. **`2.2.E`** = **Q=70** / roadmap **2.2.D**; **`2.2.F`** = **Q=80** / roadmap **2.2.E**) — always map by **`InpMinQualityScore`**.

**Record per test:** trades | WR | PF | max DD % | **net profit** ($).

**Run 5 tests with different quality levels:**

**Test 2.2.A: Quality = 40**
```
InpMinQualityScore = 40
Period: 2025-01-01 - 2025-12-31 (same locked range as Checkpoint 2.1)
```
**Results:** *(user notebook **Test ID `2.2.B`** — same as this row)*
```
Trades: 45 | WR: 22.22% | PF: 0.53 | DD: 12.75% | Net: $-817.02
```
**Interpretation:** Backtest metrics are **bit-for-bit identical** to **Q=30** (same 45 trades, WR, PF, net, DD). **Update:** raising to **Q=50** (**user `2.2.C`**, roadmap **Test 2.2.B**) **did** change outcomes — see §2.3 row Q=50 and analysis **Test `2.2.C`**.

---

**Test 2.2.B: Quality = 50**
```
InpMinQualityScore = 50
Period: 2025-01-01 - 2025-12-31 (locked FY — same as 2.1)
```
**Results:** *(user lab Test ID **`2.2.C`** = this roadmap row)*
```
Trades: 59 | WR: 37.29% | PF: 1.08 | DD: 12.22% | Net: $+150.10
```
**Notes:** Backtest tab is source of truth; Journal `Total Trades: 70689` ≠ **59**. Shorts **18 @ 0%** WR; longs **41 @ 53.66%** WR. Monthly entries chart: activity **Jan–Apr** in screenshot — confirm **May–Dec** on your terminal.

---

**Test 2.2.C: Quality = 60**
```
InpMinQualityScore = 60
Period: 2025-01-01 - 2025-12-31 (locked FY — same as 2.1)
```
**Results:** *(user lab Test ID **`2.2.D`** = this roadmap row — roadmap **2.2.D** is Q=**70**, not 60)*
```
Trades: 123 | WR: 41.46% | PF: 1.32 | DD: 13.57% | Net: $+1173.83
```
**Notes:** Backtest tab = truth; Journal `Total Trades: 70753` ≠ **123**. Shorts **35 @ 14.29%** WR (first non-zero short WR in ladder); longs **88 @ 52.27%** WR. Monthly chart in screenshot: entries **Jan–May** — confirm **Jun–Dec** in tester.

---

**Test 2.2.D: Quality = 70**
```
InpMinQualityScore = 70
Period: 2025-01-01 - 2025-12-31 (locked FY — same as 2.1)
```
**Results:** *(user lab Test ID **`2.2.E`** = this row — roadmap **Test 2.2.E** is **Q=80**, not 70)*
```
Trades: 127 | WR: 40.94% | PF: 1.29 | DD: 13.97% | Net: $+1109.17
```
**Notes:** Backtest tab = truth; Journal `Total Trades: 70757` ≠ **127**. Shorts **35 @ 14.29%** WR; longs **92 @ 51.09%** WR. Monthly chart: entries **Jan–Jun**; **Jul–Dec** zero — extend H2 triage vs Q=60 (Jan–May/Jun pattern).

---

**Test 2.2.E: Quality = 80**
```
InpMinQualityScore = 80
Period: 2025-01-01 - 2025-12-31 (locked FY — same as 2.1)
```
**Results:** *(user lab Test ID **`2.2.F`** = this roadmap row)*
```
Trades: 104 | WR: 40.38% | PF: 1.25 | DD: 12.68% | Net: $+810.77
```
**Notes:** Backtest tab = truth; Journal `Total Trades: 70734` ≠ **104**. Shorts **28 @ 17.86%** WR; longs **76 @ 48.68%** WR. **Q80 vs Q70:** fewer trades (**104** vs **127**), **lower** net/PF/WR, **lower** equity DD (**12.68%** vs **13.97%**). Monthly chart in screenshot: entries **Jan–May** only — **Jun–Dec** zero; same **H2 silence** class as prior runs.

**Status:** [x] COMPLETE

---

### ✅ CHECKPOINT 2.3: Analyze Quality vs Performance

**Create comparison table:**

| Quality | Trades | Win Rate | PF   | DD % | Net $   | Notes |
|---------|--------|----------|------|------|---------|-------|
| 30      | 45     | 22.22%   | 0.53 | 12.75 | -817.02 | 2025-01-01—2025-12-31 FY; **entries ~Jan–Mar only**; 25 shorts **0%** WR / 20 longs **50%** WR; History quality **99%**; use **Backtest** trade count (not Journal `Total Trades`) |
| 40      | 45     | 22.22%   | 0.53 | 12.75 | -817.02 | **Identical to Q=30** on Backtest summary; Jan–Mar only; shorts **0%** WR; user Test ID **`2.2.B`** = this Q=40 run — verify filter wiring / input load |
| 50      | 59     | 37.29%   | 1.08 | 12.22 | +150.10 | User Test **`2.2.C`** = roadmap **2.2.B**; **breaks** Q30/40 plateau; shorts **0%** WR (18); longs **53.66%** WR; PF **>1** but thin; confirm H2 months in tester |
| 60      | 123    | 41.46%   | 1.32 | 13.57 | +1173.83 | User Test **`2.2.D`** = roadmap **2.2.C**; vs Q50: more tr, higher WR/PF/net; shorts **14.29%** WR (35 sh); activity **Jan–May** in shot — verify H2 |
| 70      | 127    | 40.94%   | 1.29 | 13.97 | +1109.17 | User Test **`2.2.E`** = roadmap **2.2.D**; vs Q60: **slightly worse** net/PF/WR, **higher** DD, **+4** trades; shorts still **14.29%**; activity **Jan–Jun** in shot — **Jul–Dec** zero |
| 80      | 104    | 40.38%   | 1.25 | 12.68 | +810.77 | User Test **`2.2.F`** = roadmap **2.2.E**; vs Q60: **fewer** tr, **lower** net/PF; vs Q70: **−23** tr, net/PF **down**, DD **improved**; shorts **17.86%**; **Jan–May** in shot — **Jun+** zero |

**Append-only run log (test-ID tracking):**

| Test ID | Period | Q | Trades | WR | PF | DD % | Net $ | Notes |
|---------|--------|---|--------|-----|-----|------|-------|-------|
| 2.1 / user “2.2.A”* | 2025 FY · M5 | 30 | 45 | 22.22% | 0.53 | 12.75 | −817.02 | *Earlier run: user label `2.2.A` with Q=30 = **2.1** baseline.* |
| **2.2.B** (user) | 2025 FY · M5 | **40** | 45 | 22.22% | 0.53 | 12.75 | −817.02 | **Roadmap slot = Test 2.2.A (Q=40).** Backtest **identical** to Q=30 → verify Inputs + quality-gate code path. Journal `Total Trades` **70675** ≠ **45**. |
| **2.2.C** (user) | 2025 FY · M5 | **50** | 59 | 37.29% | 1.08 | 12.22 | +150.10 | **Roadmap slot = Test 2.2.B (Q=50).** First step improving vs Q30/40; shorts **0%** WR; Journal **70689** ≠ **59**. |
| **2.2.D** (user) | 2025 FY · M5 | **60** | 123 | 41.46% | 1.32 | 13.57 | +1173.83 | **Roadmap slot = Test 2.2.C (Q=60).** Strong lift vs Q50; shorts **14.29%** WR; Journal **70753** ≠ **123**. |
| **2.2.E** (user) | 2025 FY · M5 | **70** | 127 | 40.94% | 1.29 | 13.97 | +1109.17 | **Roadmap slot = Test 2.2.D (Q=70).** Net/PF **below Q=60** peak; Journal **70757** ≠ **127**. |
| **2.2.F** (user) | 2025 FY · M5 | **80** | 104 | 40.38% | 1.25 | 12.68 | +810.77 | **Roadmap slot = Test 2.2.E (Q=80).** Ladder top; net/PF **below Q=60**; Journal **70734** ≠ **104**. |

#### Analysis — Test ID **`2.2.F`** (`InpMinQualityScore = 80`, roadmap **Test 2.2.E**)

1. **Summary:** Net **+$810.77**, PF **1.25**, WR **40.38%** (42W / 62L), equity DD **12.68%**, **104** trades — **completes** the quality ladder; **headlines weaker** than **Q=60** and **Q=70** except **DD** vs Q70.
2. **Critical errors:** No crash in Journal. **Functional:** **Jun–Dec** still **zero** monthly entries in screenshot — **H2 silence** (narrower active window than Q70 shot). Journal **`Total Trades: 70734`** ≠ MT5 **104** (internal counter; do **not** infer overtrading from Journal). Shorts **17.86%** WR (**28**) vs longs **48.68%** — short leg still **broken** vs design WR targets.
3. **SL/TP:** Average win (**~$95.08**) **>** average loss (**~$51.33**) — R-shaped edge intact; max consecutive losses **24** vs **18** at Q70 (stricter filter **did not** smooth equity path on this sample).
4. **Extracted:** trades **104**, WR **40.38%**, PF **1.25**, DD **12.68%** (equity max), net **+810.77**.
5. **vs ladder:** **Q=60** still **best** net (**+$1173.83**), PF (**1.32**), WR (**41.46%**). **Q=80** finally shows **fewer** trades than **Q=70** (−23) but **does not** recover net/PF — **not** worth raising quality **above 80** on this path; **no further `InpMinQualityScore` steps** in roadmap **2.2**.
6. **Next step (threshold):** **Stop** raising quality — **preliminary FY lock:** **`InpMinQualityScore = 60`** for **Checkpoint 2.4** baseline (first `InpRequire*` toggles **one at a time** vs **Q=60** + consensus **1**, same FY lock). Revisit **70** only if a later Require-filter run **improves** shorts at cost of frequency you accept.
7. **Judgement — overtrading (MT5)?** **No** (**104** positions/year). **Underfiltering?** **Moderate** for stretch goals (WR ~40%, PF ~1.25); **not** fixed by Q alone. **Acceptable quality?** **Research-only** — ladder **done**; proceed to **structural** filters + **H2** triage before Phase 3 claims.
8. **Table:** Q=**80** row + append log updated.

#### Analysis — Test ID **`2.2.E`** (`InpMinQualityScore = 70`, roadmap **Test 2.2.D**)

1. **Summary:** Net **+$1,109.17**, PF **1.29**, WR **40.94%** (52W / 75L), equity DD **13.97%**, **127** trades — **slightly weaker** than **Q=60** on net, PF, WR, and DD (small **regression** vs prior step).
2. **Critical errors:** No crash in Journal. **Functional:** **Jul–Dec** still **zero** monthly entries in screenshot — **H2 silence** persists (now active window appears **Jan–Jun** only). Shorts stuck at **14.29%** WR (**35** shorts) vs longs **51.09%**.
3. **SL/TP:** Average win **>** average loss; edge still from **R**, not from hitting Phase 2 WR targets.
4. **Extracted:** trades **127**, WR **40.94%**, PF **1.29**, DD **13.97%** (equity max), net **+1109.17**.
5. **vs Q=60 (+1173.83, PF 1.32, WR 41.46%, DD 13.57%, 123 tr):** suggests an **elbow / local optimum around Q=60** for this FY path — do **not** assume “higher Q always better.”
6. **Next threshold:** ~~**`= 80`** (roadmap **Test 2.2.E**)~~ **Done** — see **Test ID `2.2.F`** analysis above; **do not** raise quality further on this ladder — **lock candidate `= 60`** for **2.4** unless you rerun with code/data fixes.
7. **Judgement — overtrading (MT5)?** **No** (**127** trades). **Underfiltering?** **Moderate** — PF ~1.3 band, WR ~41%. **Acceptable quality?** **Research-grade only**; **Q=60** currently **beats Q=70** on headline metrics.
8. **Table:** Q=**70** row + append log updated.

#### Analysis — Test ID **`2.2.D`** (`InpMinQualityScore = 60`, roadmap **Test 2.2.C**)

1. **Summary:** Net **+$1,173.83**, PF **1.32**, WR **41.46%** (51W / 72L), equity DD **13.57%**, **123** trades — clear **monotonic improvement** vs Q=50 on net, PF, WR, and sample size.
2. **Critical errors:** No crash in Journal snippet. **Functional:** **Jun–Dec** still **zero** entries in monthly chart — same **H2 silence** class as lower Q; investigate in parallel (not a “quality ladder only” fix). Shorts **non-zero** WR (**14.29%**) but still **weak** vs longs (**52.27%**).
3. **SL/TP:** Average win **>** average loss; profitability driven by **R multiple +** higher WR vs Q≤50; short side **improving** but still a drag on aggregate WR vs Phase 2 stretch target.
4. **Extracted:** trades **123**, WR **41.46%**, PF **1.32**, DD **13.57%** (equity max), net **+1173.83**.
5. **vs Q=50 (59 tr, +150, WR 37%, PF 1.08):** **Large step forward** — quality **60** is the **FY headline leader** in this ladder through **Q=80**; next validation is **§2.4** Require filters, not higher Q.
6. **Next threshold:** ~~**`= 70`** (roadmap **Test 2.2.D**)~~ **Done** — see **Test ID `2.2.E`** (user) analysis; ~~**`= 80`**~~ **Done** — see **`2.2.F`** / roadmap **Test 2.2.E**; **preliminary lock `= 60`** for **§2.4**.
7. **Judgement — overtrading (MT5)?** **No** (**123** positions over active months, still modest for a year if H2 were active). **Underfiltering?** **Less so** than Q≤50 — PF **1.32**, WR **41%**, but still **far** from 70–75% WR target. **Acceptable quality?** **Improving / promising** for research — **not** final live-grade until shorts + H2 silence resolved.
8. **Table:** Q=**60** row + append log updated.

#### Analysis — Test ID **`2.2.C`** (`InpMinQualityScore = 50`, roadmap **Test 2.2.B**)

1. **Summary:** Net **+$150.10**, PF **1.08**, WR **37.29%** (22W / 37L), equity DD **12.22%**, **59** trades — **breaks** the Q=30/40 plateau (more trades, net flips positive, PF above 1).
2. **Critical errors:** No crash in Journal snippet. **Functional:** **18 shorts, 0% WR** — same **SELL / short** anomaly as lower-Q runs; must remain **P0** for any “acceptable quality” claim.
3. **SL/TP:** Average win **>** average loss (favourable R on many trades); longs **53.66%** WR carry results; **short leg** still structurally broken for this sample.
4. **Extracted:** trades **59**, WR **37.29%**, PF **1.08**, DD **12.22%** (equity max), net **+150.10**.
5. **vs Q=30/40:** Strong **improvement** — confirms `InpMinQualityScore` **does** move outcomes once threshold reaches **50** (in this FY configuration).
6. **Next threshold:** ~~**`= 60`** (roadmap **Test 2.2.C**)~~ **Done** — see **Test ID `2.2.D`** analysis above; next **`= 70`** (roadmap **Test 2.2.D**).
7. **Judgement — overtrading (MT5)?** **No** (**59** positions). **Underfiltering?** **Partially** — PF only **1.08**, WR **37%**; quality score helps but **does not** fix shorts. **Acceptable vs Phase 2 stretch targets?** **Marginal / early** — better than Q≤40, not yet 70–75% WR or PF>2.
8. **Distribution:** screenshot shows entries **Jan–Apr**; verify **May–Dec** in Strategy Tester — if zero again, log as recurring **H2 silence** pattern alongside ladder work.

#### Analysis — run **Test ID `2.2.B`** (`InpMinQualityScore = 40`, roadmap **2.2.A**)

1. **Summary:** Same as Q=30: net **−$817.02**, PF **0.53**, WR **22.22%**, equity DD **12.75%**, **45** trades — **no** Phase 2 improvement at this step.
2. **Critical errors:** None in Journal snippet; shutdown clean. **Functional red flag:** quality 30→40 produced **zero** metric delta on official report → **ladder variable may not be affecting** the executed path (or both runs share identical effective settings).
3. **SL/TP:** Unchanged story — avg win **>** avg loss but **WR 22%** and **shorts 0%** WR dominate; SELL path still **P0** before trusting any threshold tuning.
4. **Extracted:** trades **45**, WR **22.22%**, PF **0.53**, DD **12.75%**, net **−817.02**.
5. **vs Q=30:** **No difference** on trades / WR / PF / DD / net at **Q=40** alone → plateau between **30 and 40**; **Q=50** later **broke** this (see **Test `2.2.C`** / roadmap **2.2.B** analysis above).
6. **Next threshold (updated):** **`= 50`** ✅ **`2.2.C`** · **`= 60`** ✅ **`2.2.D`** · **`= 70`** ✅ **`2.2.E`** / roadmap **2.2.D** · **`= 80`** ✅ **`2.2.F`** / roadmap **2.2.E** — ladder **complete**; next = **Require filters** (§2.4) from **`InpMinQualityScore = 60`** baseline.
7. **Judgement — overtrading?** **No** on MT5 (**45** positions/year). **Underfiltering?** **Yes** on edge (WR/PF). **Acceptable quality?** **No.** Journal **~70k** “trades” is **not** MT5 overtrading — internal counter / noise.
8. **Table:** Q=**40** row + append log updated.

#### Analysis — run `2.2.A` (Q=30) / **2.1 baseline** *(historical)*

1. **Backtest summary:** net **−$817.02**, PF **0.53**, WR **22.22%** (10W / 35L), max equity DD **12.75%** — **does not** meet profitability or WR targets.
2. **Critical errors:** none visible in Journal shutdown path; **no** stack/OnTester critical in provided snippet.
3. **SL/TP / direction:** longs **50%** WR vs shorts **0%** WR → **prioritize validating SELL pipeline** (stops, freeze level, signal inversion) before interpreting quality ladder.
4. **Extracted metrics:** trades **45**, WR **22.22%**, PF **0.53**, DD **12.75%** (equity), net **−817.02**.
5. **vs Phase 1 (Jan 2025 only, M5, ultra-permissive):** **15** trades in **1 month** vs **45** in **full year** with **concentration in Q1** → FY run shows **structural silence** in H2.
6. ~~**Next threshold:** set **`InpMinQualityScore = 40`**~~ **Done** — see **Q=40** analysis above (identical outcome).
7. **Judgement:**
   - **Overtrading (MT5 official trades)?** **No** — **45** positions/year is low; Journal `Total Trades` **70875** / **70675** is **not** MT5 trade count.
   - **Underfiltering / signal quality?** **Yes** — WR and PF indicate **poor edge** at Q=30 for this run.
   - **Acceptable quality?** **No** for Phase 2 goals.
8. **Table:** row **Q=30** + append log row updated above.

**Expected Pattern:**
```
Quality ↑ → Trades ↓ (fewer but better)   ← idealised
Quality ↑ → Win Rate ↑ (higher quality)
Quality ↑ → Profit Factor ↑ (better trades)
```

*Empirical FY note:* Q **30→40** was **flat**; **40→50** and **50→60** **increased** trades while improving WR/PF/net; **60→70** **slightly regressed** net/PF/WR with **higher** DD; **70→80** **cut** trades (**127→104**) and **improved** DD vs 70 but **further reduced** net/PF/WR — **Q=60** remains **best FY headline** in this log; ladder **closed** at **80**.

**Find Sweet Spot:**
```
Target: 70-75% WR, PF >2.0, DD <12%; trade count must be **statistically meaningful** (interpret against your FY sample — e.g. Q=30 gave **45** trades)

Ladder result: **Q=60** **beats** **Q=70** and **Q=80** on **net / PF / WR** for this FY sample; **Q=80** wins only on **trade count reduction** vs 70 and **slightly lower** equity DD vs 70.

Recommended: **`InpMinQualityScore = 60`** (FY candidate lock for **Checkpoint 2.4** — revisit after Require-filter passes or H2/short fixes)
```

**Status:** [x] COMPLETE *(preliminary sweet spot logged — formal GO/NO-GO vs Phase 2 stretch targets still **NO-GO** on WR/PF)*

---

### ✅ CHECKPOINT 2.4: Enable Require Filters (One by One)

**Method:** After you lock **InpMinQualityScore** to the sweet spot from **2.3**, enable **at most one** `InpRequire*` change per run vs that baseline (see each sub-test). Record the same metric line as 2.2 (trades | WR | PF | DD | Net).

**Naming:** EA input in code is **`InpRequireTrendAlignment`** (`AurumSynapse.mq5`). Lab **Test ID `2.3.A`** = roadmap **Test 2.4.A** (Trend Align ON) — map by **which flag changed**, not digit alone.

**Locked baseline (FY, M5, for §2.4 deltas):** `InpMinQualityScore=60`, `InpMinConsensus=1`, all `InpRequire*` **false** — user **`2.2.D`** / roadmap **Test 2.2.C**: **123** tr | **41.46%** WR | **1.32** PF | **13.57%** eq DD | **+$1173.83** net | longs **88 @ 52.27%** | shorts **35 @ 14.29%** | Journal `Total Trades` **70753** ≠ **123**.

**Now test with additional filters enabled:**

**Test 2.4.A: Trend Alignment Required**
```
InpMinQualityScore = 60
InpMinConsensus = 1
InpRequireTrendAlignment = true   // EA source name (Tester may show shortened label)
InpRequireKeyLevel = false
InpRequireMomentum = false
```
**Results:** *(user lab **Test ID `2.3.A`** = this row)*
```
Trades: 123 | WR: 41.46% | PF: 1.32 | DD: 13.57% | Net: $+1173.83
Impact: NEUTRAL — bit-for-bit match to locked Q=60 baseline (user `2.2.D`); no trade-frequency, PnL, or DD change in this FY sample
```
**BUY vs SELL:** Longs **88 @ 52.27%** WR · Shorts **35 @ 14.29%** WR — **unchanged** vs baseline; short leg still **P0**.

**Journal:** `Total Trades: 70753` (same as baseline) — **not** MT5 position count (**123**).

**Status:** [x] **Recorded** *(Checkpoint **2.4** sweep **complete** — see **`2.4.D`** and Recommendation block below)*

#### Analysis — Test ID **`2.3.A`** (`InpRequireTrendAlignment = true`, roadmap **Test 2.4.A**)

1. **vs baseline (`2.2.D`, all Require off):** **Δ trades = 0**, **Δ net = 0**, **Δ PF = 0**, **Δ WR = 0**, **Δ eq DD = 0**, long/short **split identical**. Conclusion: in this 2025 FY path, **trend-alignment hard gate did not remove any executed setups** that already passed Q≥60 + consensus.
2. **Code path:** `CheckQualityRequirements()` gates execution after quality (`AurumSynapse.mq5`); BUY requires `state.trendDir == TREND_UP`, SELL requires `TREND_DOWN`. **Neutral backtest** implies every **consensus** trade that reached execution already satisfied alignment (or confirm in Tester **Inputs** tab that **`InpRequireTrendAlignment`** is actually **true** — code name differs from shorthand `InpRequireTrendAlign`).
3. **Overfiltering?** **No observable effect** (no participation drop).
4. **Reduced bad trades / improved signal quality?** **No measurable improvement** on aggregate metrics; shorts still **weak**.
5. **H2 inactivity:** **Unchanged** — entries **Jan–May** only, **Jun–Dec** **zero** in report; **not** caused or fixed by this flag in this run.
6. **Stability:** Journal shows **clean shutdown** (Reason 1); **no** stack overflow / invalid stops in provided snippets.
7. **Recommendation:** **Do not rely on this flag for FY2025 differentiation** — treat as **optional** (keep **false** for simplicity, or **true** as a **no-op** safety envelope here). **Continue** Phase 2 to **Test 2.4.B** (`InpRequireKeyLevel = true` only, others **false**) for the next **single-variable** delta.
8. **Keep / reject / next:** **Reject as a performance lever** for this dataset; **acceptable to leave ON** if you want policy consistency without backtest cost. **Next:** **§2.4.B** Key Level.

---

**§2.4 filter sweep log (append-only)**

| Test ID (user) | Roadmap | Δ vs Q60 baseline | Trades | WR | PF | Eq DD % | Net $ | Notes |
|----------------|---------|-------------------|--------|-----|-----|---------|-------|-------|
| **`2.2.D`** | 2.2.C (Q=60, Require all **false**) | — (baseline) | 123 | 41.46% | 1.32 | 13.57 | +1173.83 | Locked §2.4 reference |
| **`2.3.A`** | **2.4.A** TrendAlign **true** | **0** | 123 | 41.46% | 1.32 | 13.57 | +1173.83 | **Identical** — flag **inactive** as filter on this sample |
| **`2.4.B`** | **2.4.B** Key Level **true** | **−21** tr | 102 | 42.16% | 1.33 | 13.36 | +1011.00 | **Active** filter; net **< baseline**; shorts WR **up**, count **down**; Journal **70732** ≠ **102** |
| **`2.4.C`** | **2.4.C** Momentum **true** | **+4** tr ⚠ | 127 | 40.94% | 1.29 | 13.98 | +1108.63 | **Sanity check:** extra gate **should not** increase trades vs **`2.2.D`** — fingerprint **≈ user `2.2.E` (Q=70)**; **confirm Inputs** (`InpMinQualityScore=60`, only Momentum ON); Journal **70757** ≠ **127** |
| **`2.4.D`** | **2.4.D** all Require **true** | **−21** tr | 102 | 42.16% | 1.33 | 13.32 | +1021.72 | **Same trade count** as **`2.4.B`** — stack **Key-dominant**; net **+~$11** vs **`2.4.B`**; still **< baseline** net; Journal **70732** ≠ **102** |

---

**Test 2.4.B: Key Level Required**
```
InpMinQualityScore = 60
InpMinConsensus = 1
InpRequireTrendAlignment = false
InpRequireKeyLevel = true
InpRequireMomentum = false
```
**Results:** *(user **Test ID `2.4.B`** = this row — matches roadmap naming)*
```
Trades: 102 | WR: 42.16% | PF: 1.33 | DD: 13.36% | Net: $+1011.00
Impact: ACTIVE vs baseline — −21 trades (−17.1%); WR +0.70 pp; PF +0.01; eq DD −0.21 pp; net −$162.83 (−13.9%)
```
**BUY vs SELL:** Longs **79 @ 48.10%** WR (baseline **88 @ 52.27%**) · Shorts **23 @ 21.74%** WR (baseline **35 @ 14.29%**) — **fewer** shorts, **higher** short WR but still **weak**; long **count** and **WR** **down**.

**Distribution / H2:** Entries **Jan–Jun** in report; **Jul–Dec** **zero** — **H2 silence persists** (not introduced by Key Level alone; filter **narrows H1** participation).

**Journal:** `Total Trades: 70732` ≠ MT5 **102** — internal counter; **no** MT5 “overtrading” from this line.

#### Analysis — Test ID **`2.4.B`** (`InpRequireKeyLevel = true`, roadmap **Test 2.4.B**)

1. **vs locked baseline (`2.2.D`):** Meaningful **participation drop** (**102** vs **123** trades) confirms `CheckQualityRequirements()` **key-level branch** is **binding** on this FY path (proximity gate in `AurumSynapse.mq5`: min distance to S/R vs **`500 * _Point`**).
2. **Trade quality (headlines):** **WR** and **PF** **nudge up** marginally; **net profit** and **absolute gross edge** **down** vs baseline — filter **removed** a mix of trades including **net‑contributing** ones on this sample.
3. **Drawdown:** Max **equity** DD **slightly lower** (**13.36%** vs **13.57%**); **max consecutive losses** **worse** in screenshot (**25** vs **18** baseline) — **risk path not clearly smoother** despite fewer trades.
4. **BUY vs SELL:** **Short leg** improves **WR** (**21.74%** vs **14.29%**) but on **fewer** shorts (**23** vs **35**); **long** side **loses** both **volume** and **WR** — aggregate **WR** gain is **not** from “fixing” shorts alone.
5. **Overfiltering?** **Partial yes** for **FY net** — **−17%** trades for **−14%** net and **lower** long WR suggests **too tight** or **misaligned** proximity vs how signals cluster on XAUUSD M5 (or S/R fields in `MarketState` favour only a subset of months).
6. **Stability:** Journal shows **normal** `OnDeinit` (**Reason 1**), clean shutdown; **no** stack overflow / invalid stops in provided snippet.
7. **Keep / reject / next:** **Reject for FY net-max baseline** vs **`2.2.D`** on this log. **Optional** to keep studying with **walk-forward** or **S/R distance tuning** (Phase 5 — **not** Phase 2 single-flag scope). ~~**Next:** **Test 2.4.C**~~ **Done** — see **`2.4.C`** analysis; **Next:** **Test 2.4.D** (all Require ON).

---

**Test 2.4.C: Momentum Required**
```
InpMinQualityScore = 60
InpMinConsensus = 1
InpRequireTrendAlignment = false
InpRequireKeyLevel = false
InpRequireMomentum = true
```
**Results:** *(user **Test ID `2.4.C`** = this row)*
```
Trades: 127 | WR: 40.94% | PF: 1.29 | DD: 13.98% | Net: $+1108.63
Impact vs `2.2.D` baseline: +4 trades; WR −0.52 pp; PF −0.03; eq DD +0.41 pp; net −$65.20
```
**BUY vs SELL:** Longs **92 @ 51.09%** WR (baseline **88 @ 52.27%**) · Shorts **35 @ 14.29%** WR (**=** baseline shorts) — **more** longs, **lower** long WR; shorts **unchanged** count/WR.

**H2:** Monthly chart: activity **Jan–Jun**, **Jul–Dec** **zero** — same **H2 silence** class as **`2.2.D`** / **`2.2.E`**.

**Journal:** `Total Trades: 70757` ≠ MT5 **127** — internal counter (same number as **`2.2.E`** Journal in prior log).

#### Analysis — Test ID **`2.4.C`** (`InpRequireMomentum = true`, roadmap **Test 2.4.C**)

1. **vs locked baseline (`2.2.D`):** Report shows **higher** trade count (**127** vs **123**) with **worse** net/PF and **slightly worse** WR/DD — **not** the expected signature of a **pure additional AND** on the same code path (`CheckQualityRequirements`: BUY needs `rsi14 ≥ 50`, SELL needs `rsi14 ≤ 50`).
2. **Configuration sanity:** This fingerprint is **numerically aligned** with the logged **Q=70** run (**user `2.2.E`**: **127** tr, **~+$1109**, PF **~1.29**, **~13.97%** DD, **92/35** long/short split). **Before drawing conclusions**, **re-verify** Strategy Tester **Inputs** snapshot: **`InpMinQualityScore = 60`**, **`InpRequireMomentum = true`**, other **`InpRequire*`** **false**, **`InpMinConsensus = 1`**. If **Q accidentally = 70**, relabel row and **re-run true 2.4.C**.
3. **If** the run is **validated** as Q=60 + Momentum only: treat as **engineering anomaly** (requires **code audit** — e.g. duplicate evaluation path, preset mismatch, or report from wrong `.htm` tab) because **monotone gating** should yield **≤** baseline trades.
4. **Overfiltering?** **Not observed** vs baseline on trade count (per report); **net down** vs **`2.2.D`** if numbers taken at face value.
5. **Stability:** Journal shows **normal** `OnDeinit` (**Reason 1**); **no** stack overflow / invalid stops in snippet.
6. **Keep / reject / next (conditional):** **Reject vs FY net-max baseline `2.2.D`** on reported metrics. **Do not** mark filter “proven” until **Inputs sanity** passes. ~~**Next:** **Test 2.4.D**~~ **Done** — see **`2.4.D`** analysis; **Next:** **§2.4 Recommendation** + optional **`InpMinConsensus = 3`** single-variable run vs **`2.2.D`**, or **H2** triage before Phase 3.

---

**Test 2.4.D: All Filters ON**
```
InpMinQualityScore = 60
InpMinConsensus = 1
InpRequireTrendAlignment = true
InpRequireKeyLevel = true
InpRequireMomentum = true
```
**Results:** *(user **Test ID `2.4.D`** — **combo** test vs prior **single-flag** rows; intentional per roadmap)*
```
Trades: 102 | WR: 42.16% | PF: 1.33 | DD: 13.32% | Net: $+1021.72
Impact vs `2.2.D` baseline: −21 trades; WR +0.70 pp; PF +0.01; eq DD −0.25 pp; net −$152.11
Impact vs `2.4.B` (Key only): **0** Δ trades; net **+$10.72**; eq DD **−0.04** pp; long/short **mix shifts** (see analysis)
```
**BUY vs SELL:** Longs **74 @ 51.35%** WR · Shorts **28 @ 17.86%** WR — vs **`2.4.B`** (**79** / **23** @ **48.10%** / **21.74%**): **fewer** longs, **more** shorts, **higher** long WR, **lower** short WR; vs baseline **`2.2.D`**: still **short‑weak**.

**H2:** **Jan–Jun** activity, **Jul–Dec** **zero** — unchanged **H2 silence** class.

**Journal:** `Total Trades: 70732` ≠ MT5 **102** (same internal total as **`2.4.B`** log).

#### Analysis — Test ID **`2.4.D`** (all `InpRequire*` **true**, roadmap **Test 2.4.D**)

1. **vs `2.2.D` baseline:** Same **−21** trade reduction as **`2.4.B`** — **Key Level** remains the **dominant** binder when stacked; **TrendAlign** was **neutral alone** (`2.3.A`); adding Trend+Momentum on top **did not** change **fill count** vs Key-only in this FY sample.
2. **vs `2.4.B` (Key only):** **Identical** **102** trades but **different** long/short composition and **slightly better** net (**+$1021.72** vs **+$1011.00**) and **eq DD** — extra gates **reshuffle** which specific setups pass without increasing participation.
3. **vs `2.4.C`:** Treat **`2.4.C`** row as **suspect** until Inputs verified (see **`2.4.C`** analysis); **`2.4.D`** is **internally consistent** with **Key-gated** path (**102** tr).
4. **Overfiltering vs baseline:** **Yes** on **net** (−13% net for −17% trades) — same headline trade-off as **`2.4.B`**.
5. **Stability:** Journal **Reason 1** shutdown; **no** errors in snippet.
6. **Keep / reject:** **Reject “all ON”** as **default FY lock** vs **`2.2.D`** (lower net). **vs Key-only:** **marginal** net/DD improvement — still **not** baseline-beating.

**Recommendation (§2.4 closure):**
```
Use Require Filters for FY net-max (this log): [ ] YES [x] NO [ ] PARTIAL

Summary:
- TrendAlign (`2.3.A`): **no** MT5 metric delta vs baseline → **optional / noop** here.
- KeyLevel (`2.4.B`): **active**; **WR/PF** nudge, **net** **down** vs baseline.
- Momentum (`2.4.C`): **re-verify Inputs** (fingerprint **≈ Q=70**); **do not** lock until clean rerun.
- All ON (`2.4.D`): **102** tr **=** **`2.4.B`** — **not** baseline-beating; **tiny** lift vs Key-only only.

Locked FY recommendation: **`InpMinQualityScore = 60`**, all **`InpRequire*`** **false**, **`InpMinConsensus = 1`** (`2.2.D`) until H2 + shorts triage.
Optional next Phase 2 variable: **`InpMinConsensus = 3`** vs **`2.2.D`** (single-variable), or proceed to **Phase 3** under **DECISION POINT** “REVIEW” band (WR < 65%, PF < 1.8).
```

**Status:** [x] COMPLETE *(Checkpoint **2.4** documented; Phase 2 stretch targets still unmet)*

---

### 📊 PHASE 2 COMPLETION CHECKLIST

- [x] 2.1: Baseline (Q=30) test complete
- [x] 2.2: All 5 quality threshold tests complete *(Q**30–80** ✅; user **`2.2.F`** = roadmap **Test 2.2.E** / **Q=80**)*
- [x] 2.3: Sweet spot identified *(preliminary: **`InpMinQualityScore = 60`** — see §2.3 table + **`2.2.F`** analysis)*
- [x] 2.4: Require filters tested *(**2.4.A** ✅ **`2.3.A`** neutral · **2.4.B** ✅ Key · **2.4.C** ✅ Mom — ⚠ verify · **2.4.D** ✅ all ON — see §2.4 Recommendation)*
- [x] Results documented in comparison table *(Q=30 … Q=80 rows filled)*

**DECISION POINT:**

```
IF Win Rate >70%, PF >2.0, DD <12%:
   → PROCEED TO PHASE 3 ✅
   → Lock in optimal settings

IF Win Rate 65-70%, PF 1.8-2.0:
   → PROCEED TO PHASE 3 with caution ⚠️
   → May need Phase 5 optimization

IF Win Rate <65% or PF <1.8:
   → REVIEW settings ❌
   → Retest with more permissive filters
   → Seek guidance before Phase 3
```

**Optimal Settings Identified:**
```
InpMinQualityScore = 60
InpRequireTrendAlignment = false
InpRequireKeyLevel = false
InpRequireMomentum = false
InpMinConsensus = 1
```
*(FY net-max on logged 2025 XAUUSD M5 — **`2.2.D`**; Require stack **not** baseline-beating; **`2.4.C`** re-verify Inputs.)*

**Phase 2 Status:** [ ] PASS [x] PARTIAL [ ] FAIL

**Date Completed:** _______________

---

---

# PHASE 3: STRATEGY VALIDATION (3-4 hours)
## Goal: Test Each Strategy Individually

**Policy:** After **each** Phase 3 isolation backtest, **update this file** (metrics under Test 3.x, checklist §PHASE 3 COMPLETION, §PROJECT TRACKING Phase 3 row, §Quick Reference).

**Prerequisites:** Phase 2 **PASS** *or* **documented PARTIAL** with explicit **locked** test profile (here: **`2.2.D`**) and known **P0** items (H2, **`2.4.C`** verify)

**Purpose:** Identify which strategies contribute most to performance

---

### ✅ CHECKPOINT 3.1-3.8: Individual Strategy Tests

> **⚠️ Engineering correction (2026-05-08):** **`InpUse*` flags were not applied before `GetConsensusSignal()`** until the consensus mask patch in `AurumSynapse.mq5`. **Tests 3.1–3.8** below include **post-fix** isolation rows where logged.  
> **Update (2026-05-09):** **§Test 3.4 SupplyDemand** — user **Q60** FY isolation **verified** (**212** tr, PF **1.23**, net **+$1,523.98**) post **Phase 3A+ v5/v6** `SupplyDemand.mqh` + `QualityFilter` unanimous-agreement score lift + `AurumSynapse` **`g_totalTrades`** log relabel. *(Some lab sheets call this checkpoint **“Test ID 3.8 (SupplyDemand ONLY)”** — in **this** roadmap **Test 3.4** = **[4] SupplyDemand** isolation; **Test 3.8** = **[8] MomentumScalp**.)*  
> **Update (2026-05-10):** **§Test 3.5 SmartMoney** — user **Q60** FY isolation **verified** (**1** tr, net **+$96.35**) post **`SmartMoney.mqh` Phase 3A++ v3** — **extreme undertrading** vs other modules.  
> **Update (2026-05-07):** **§Test 3.6 PriceAction** — user **Q60** FY isolation **verified** (**190** tr, net **+$111.00**, PF **1.02**) post **`PriceAction.mqh` Phase 3A++ v4** (tester **vol=0** pass, **BB mid** key fallback, soft PA **bar0|1**, wider ATR/dollar proximity) — **supersedes** prior **0**-trade rows.  
> **Earlier (2026-05-08):** **§Test 3.7 GridRecovery** — **Q60** (**18** tr). **§Test 3.8 MomentumScalp** — **Phase 3A** + user **Q60** (**126** tr, PF **1.18**) **logged**.

**Run each test with:**
```
Period: 2024.01.01 - 2024.12.31   (roadmap default)
     OR 2025.01.01 - 2025.12.31   (logged FY — Tests 3.1–3.8 post-fix)
Symbol: XAUUSD | TF: M5 | Model: Every tick based on real ticks
Deposit: $10,000 | Leverage: 1:500
Quality lock (Phase 2 / 2.2.D): Q60, consensus 1, all Require_* = false
Only ONE strategy enabled at a time
```

**Test 3.1: TrendFollowing ONLY**
```
InpUseTrendFollowing = true
All others = false
```
**Post-fix results** *(May 8, 2026 — MT5 Report + Inputs after `InpUse*` consensus mask; FY 2025 XAUUSD M5; Inputs: fixed lot **0.01**, max consec. losses **5**, max open pos **5**, max spread **50**, time filter **off**)*  
```
Trades: 127 | WR: 40.94% | PF: 1.29 | Net: $1,112.58
Gross +$4,982.51 / −$3,869.93 | Recovery factor: 0.82 | Sharpe: 1.23 | Expected payoff: 8.76
Max DD: Balance 10.91% ($1,349.44) | Equity 13.96% ($1,783.10) | History quality: 99% | Deals: 254
Long: 92 @ 51.09% WR | Short: 35 @ 14.29% WR | Max consec. losses: 18 (−$949.83)
Entries by month: peaks Apr/May; **zero trades Jul–Dec** (H2 — triage: risk halt vs gates vs regime)
Z-Score: 8.28 (per Report)
Grade: [ ] A (WR>75%) [ ] B (70-75%) [ ] C (65-70%) [x] D (<65%)
```
**Pre-fix archive (invalid isolation):** 123 tr | +$1,177.78 | PF 1.32 — ensemble-equivalent; superseded by post-fix row.

**Engineering notes:**
- **Journal `Total Trades: ~70,757`:** still **`g_totalTrades`** = bars processed + successful opens — **not** MT5 “Total trades” (**127**). Do not use Journal count for Phase 3 frequency.
- **Isolation verified:** Inputs show **only** TrendFollowing **true**; post-fix trade count **differs** from pre-fix (**127 vs 123**) → mask is taking effect.
- **Recommendation:** **REWORK** — positive PF / net but **Grade D** WR; **SELL** path ~**14% WR** unchanged vs pre-fix → asymmetric / short-side engineering before treating TF as symmetric contributor.

**Status:** [x] **Post-fix** logged

---

**Test 3.2: Breakout ONLY**
```
InpUseBreakout = true
All others = false
```
**Pre–Phase 3A archive (May 8, 2026 — post `InpUse*` mask, pre `Breakout.mqh` rehab):** **0** MT5 trades (silent) — root cause: swing **max/min** bug + new-bar **volume/body** on bar 0 + strict **`atrRatio`**; see Phase 3A engineering notes in repo `Strategies/Breakout.mqh`.

**Post–Phase 3A + Q60 re-isolation** *(MT5 Report + Inputs; FY 2025 XAUUSD M5; only **[2] Breakout = true**; **InpMinQualityScore = 60**, consensus **1**, all **`InpRequire_*` = false**; fixed lot **0.01**, max spread **50**, risk/time per Inputs)*  
```
Trades: 158 | WR: 39.87% | PF: 1.25 | Net: $+1,224.61
Gross +$6,038.07 / −$4,813.46 | Sharpe: 1.22 | Recovery: 0.77 | Deals: 316
Max DD: Balance 10.82% ($1,349.30) | Equity 12.42% ($1,585.01) | History quality: 99%
Long: 93 @ 51.61% WR | Short: 65 @ 23.08% WR
Max consec. wins: 11 (+$1,002.07) | Max consec. losses: 14 (−$696.05)
Avg profit trade ~$95.84 | Avg loss trade ~−$50.62 (per Report)
Entries by month (chart): strong **Apr / May** cluster; verify **Jul–Dec** in History/Trades export (H2 triage vs 3.1)
Grade: [ ] A [ ] B [ ] C [ ] D [x] **D** (WR < 65%)
```
**Journal `Total Trades: ~70,788`:** **`g_totalTrades`** (bars + opens) — **not** MT5 **158**. Use Report for frequency.

**Engineering interpretation:**
- **Revival confirmed:** Breakout is **no longer silent** after targeted **`Breakout.mqh`** fixes (time-nearest swing pivot; **max(bar0,bar1)** volume/body; lower **ATR** activation floor; slightly relaxed internal multipliers).
- **vs §2.2.D ensemble** (**123** tr, **+$1,173.83**, PF **1.32**, WR **41.46%**, eq DD **13.57%**): Breakout-only shows **more** trades (**158**), **higher** net (**+$1,224.61**), **slightly lower** PF (**1.25** vs **1.32**) and WR (**39.87%** vs **41.46%**), **similar** equity DD band (**12.42%** vs **13.57%**) — plausible **standalone contributor** if shorts are fixed.
- **Directional bias:** **Long** path viable (**~52%** WR); **Short** path **weak** (**~23%** WR) — same class of asymmetry as §3.1 TrendFollowing shorts (**~14%** on smaller n) → **REWORK** SELL / bearish breakout confirmation, not **REMOVE**.
- **Overtrading:** **No** at **158** FY M5 (~0.6% of bars) — healthy cadence vs **silent** era.
- **Runtime / execution:** clean shutdown in Journal snippet; no stack/invalid-stop flags from this summary.

**Recommendation:** **REWORK** (short-side / bearish breakout quality); **not REMOVE** — module is **validated active** post-3A. Optional: tighten Apr/May cluster risk if backtest shows calendar concentration.

**Status:** [x] **Post–Phase 3A + Q60** logged *(supersedes May 8 silent row)*

---

**Test 3.3: MeanReversion ONLY**
```
InpUseMeanReversion = true
All others = false
```
**Post-fix results** *(May 8, 2026 — MT5 Report + Inputs; FY 2025 XAUUSD M5; only **[3] MeanReversion = true**; fixed lot **0.01**, max consec. losses **5**, max open **5**, spread **50**, time filter **off**)*  
```
Trades: 43 | WR: 39.53% | PF: 1.15 | Net: $197.14
Gross profit / loss: use MT5 Report lines (PF **1.15**) | Recovery: 0.14 | Sharpe: 0.52
Max equity DD: 12.15% ($1,409.94) | History quality: 99% | Deals: 86
Long: 36 @ 47.22% WR | Short: 7 @ 0.00% WR (all shorts lost)
Max consec. wins: 10 (+$892.46) | Max consec. losses: 22 (−$1,131.96)
Avg win / avg loss: ~$90.33 / ~−$51.48 (per Report)
Entries by month (chart): Jan–May visible; **Jun–Dec** not shown / likely **no or negligible** activity (align with 3.1 H2 silence — confirm in Trades export)
Grade: [ ] A (WR>75%) [ ] B (70-75%) [ ] C (65-70%) [x] D (<65%)
```
**Pre-fix archive (invalid isolation):** 123 tr | +$1,177.78 | PF 1.32 — ensemble-equivalent; superseded.

**Engineering notes:**
- **Journal `Total Trades: ~70,673`:** **`g_totalTrades`** bar + open counter — use Report **43** for frequency.
- **SELL collapse:** **0% WR** on **7** shorts → **REWORK** short-side or disable SELL for MR-only profile until fixed.
- **Risk efficiency:** **~12% equity DD** vs **~2%** net on $10k → **poor** return-on-drawdown; max **22** consecutive losses vs **10** wins streak — **unstable** loss clustering.
- **vs 3.1 post-fix:** MR produces **fewer** trades (**43 vs 127**) and **weaker** PF (**1.15 vs 1.29**) — **lower marginal value** than TrendFollowing under same global gates.
- **Recommendation:** **REWORK** (asymmetric SELL off or MR short logic); **not KEEP** as symmetric module without changes.

**Status:** [x] **Post-fix** logged

---

**Test 3.4: SupplyDemand ONLY**
```
InpUseSupplyDemand = true
All others = false
```

> **Naming:** Some **Phase 3 isolation** lab sheets use **“Test ID 3.8 (SupplyDemand ONLY)”**. In **this** roadmap, **Test 3.4** is the canonical row for **[4] SupplyDemand**; **Test 3.8** is reserved for **[8] MomentumScalp** (see below).

**Archive — pre–Phase 3A+ verified (Report 0 tr):** Earlier FY2025 Q60 rows showed **0** MT5 trades (impulse/zone/rejection + **new-bar bar-0** effects + **quality** wall on counter-trend setups); Journal **`g_totalTrades`** ≈ bars — superseded by verified row below.

**User post–Phase 3A + Phase 3 lock (§Test 3.4 / lab “3.8”, Q60)** *(2026-05-09 — MT5 **Backtest** tab + Inputs + Journal; FY **2025-01-01 → 2025-12-31** XAUUSD **M5**; **every tick based on real ticks**; **$10,000** / **1:500**; **only [4] SupplyDemand = true**; **`InpMinQualityScore = 60`**, **`InpMinConsensus = 1`**, all **`InpRequire_*` = false**; time filter **off**; Mon–Fri **true**; history **99%**; **~61.74M** ticks / **~70,530** bars per Report/Journal context)*  
```
Trades: 212 | Deals: 424 | WR: 39.15% (83 W / 129 L) | PF: 1.23 | Net: +$1,523.98
Gross (per Report summary) | Expected payoff: 7.19 | Sharpe: 1.13 | Recovery factor: 0.87
Max balance DD: 12.35% ($1,607.54) | Max equity DD: 13.30% ($1,750.57)
Long: 127 @ 43.31% WR | Short: 85 @ 35.29% WR  (≈60% / 40% long-short mix)
Avg profit trade ~$97.22 | Avg loss trade ~−$50.69 | Z-score: 9.61 (99.74%)
Max consec. wins: 15 (+$1,386.64) | Max consec. losses: 24 (−$1,223.01)
Entries by hour: peaks **~10** (EU) and **15–18** (US); quieter Asia / mid-day gaps in capture
Entries by weekday: Thu peak; Fri lowest in chart capture
Entries by month: strong **Apr** cluster; **Jul–Aug** thin; **Sep–Dec** empty in screenshot — **confirm H2** in **History** export (possible chart crop vs true silence)
Grade: [ ] A [ ] B [ ] C [ ] D [x] **D** (WR < 65%)
Avg trade duration: use MT5 Report “Average holding time” / **History** *(not in supplied summary)*
```

**Journal:** clean **`OnDeinit`** (reason **1**); **`g_totalTrades`** / engine bar counter **~70,5xx** — **not** MT5 **212**; **Report** is authoritative for fills.

**Code path (repo) enabling this row:** **`SupplyDemand.mqh` Phase 3A+** through **v6** — wick **`GetAtrForZones`**, **Min(bid,Low0,Low1)** / **Max(bid,High0,High1)** zone probe, **rejection OR bar0|bar1**, looser **impulse / min height**; **`QualityFilter.mqh`** — if **`agreementPct ≥ 99`** and raw score **`∈ [15, 32)`**, lift to **32** so **Q60** does not veto lone-module counter-trend votes; **`AurumSynapse.mq5`** — **`OnDeinit`** label clarifies bar counter vs MT5 trades.

**Engineering interpretation (§Test 3.4 / Q60 vs §2.2.D ensemble):**
- **Standalone edge:** **Positive** net, **PF > 1**, **n = 212** — credible FY sample; **WR 39.15%** still **Grade D** vs project WR targets; edge driven by **asymmetric R** (avg win **~1.9×** avg loss in capture).
- **vs `2.2.D`** (**123** tr, **+$1,173.83**, PF **1.32**, WR **41.46%**, eq DD **13.57%**): SupplyDemand-only shows **more** trades (**212** vs **123**), **higher** net (**+$1,524** vs **+$1,174**), **slightly lower** PF (**1.23** vs **1.32**) and WR (**39.15%** vs **41.46%**), **similar** max equity DD band (**13.30%** vs **13.57%**) — **plausible ensemble contributor** on economics; **short** WR (**35%**) still **weaker** than long (**43%**) → same **short-weak** family as §3.1–3.3 / 3.2 / 3.8.
- **BUY vs SELL:** long path **stronger** WR and **higher count** → **directional bias** toward **BUY**; not **REMOVE** on isolation alone.
- **Trade frequency:** **~212** FY M5 — **not** undertrading; **not** overtrading vs **~70k** bars (**~0.3%** of bars).
- **H2:** monthly chart in capture shows **no Sep–Dec** bars — **triage** (screenshot crop vs **true** H2 silence) via **History** export; if real, align with §3.1 **Jul–Dec** class.
- **Runtime:** no stack / invalid-stop narrative in supplied Journal — **stable** completion.

**Phase 3 checklist (3.4) — user Q60 post–3A+ verified:** vs **§2.2.D** — **212** marginal trades / **+$1,523.98** net. **BUY/SELL:** **127** / **85**; short WR **35.29%**. **Overtrading:** **no** (Report). **Undertrading:** **no**. **H2:** **verify** (chart). **Quality class:** **D** (WR). **Ensemble:** **KEEP** as **candidate contributor** with **REWORK** on shorts / H2 confirmation. **Not REMOVE**.

**Recommendation:** **REWORK** (short-side / optional H2 calendar path); **next Phase 3:** **`SmartMoney.mqh`** trade-density **or** **§3.10** subset vs **`2.2.D`** **or** **PriceAction** short/H2 pass (**§3.6** **190** tr post–**3A++ v4** — **§3.5** still **1** tr — both **REWORK**).

**Status:** [x] **Post-fix** logged · [x] **Post–Phase 3A+ SupplyDemand Q60 verified** *(user FY2025 M5 isolation — Report **212** tr, PF **1.23**)* · [x] **Phase 3.4 engineering summary** *(updated 2026-05-09)*

**Test 3.5: SmartMoney ONLY**
```
InpUseSmartMoney = true
All others = false
```
**Post-fix results (pre–Phase 3A code)** *(May 8, 2026 — MT5 Report + Inputs; FY 2025 XAUUSD M5; only **[5] SmartMoney = true**; fixed lot **0.01**, max spread **50**, risk/time per Inputs)*  
```
Trades: 0 | WR: n/a | PF: 0.00 | Net: $0.00 | Deals: 0
Sharpe / Recovery: 0.00 | DD: 0% | History quality: 99% | Bars: ~70,630 (per Report)
Charts: no entries by hour / weekday / month
Grade: [ ] A [ ] B [ ] C [ ] D [x] **N/A — zero sample**
```

**Archive — post–Phase 3A / pre–3A++ (Test 3.5, Q60 ×2)** *(MT5 Report + Inputs; FY 2025 XAUUSD M5; **only [5] SmartMoney = true**; **InpMinQualityScore = 60**, **InpMinConsensus = 1**, all **`InpRequire_*` = false**; fixed lot **0.01**, time filter **off**; history **99%**)*  

*Run A — max spread **30**:*  
```
Trades: 0 | WR: n/a | PF: 0.00 | Net: $0.00 | Deals: 0
Bars: ~70,630 | Ticks: ~61.74M | Charts: empty hour / weekday / month
```

*Run B — max spread **50**, Magic **20250505**:*  
```
Trades: 0 | WR: n/a | PF: 0.00 | Net: $0.00 | Deals: 0
Bars: ~70,680 | Ticks: ~61.74M (per Report) | Charts: empty
Grade: [ ] A [ ] B [ ] C [ ] D [x] **N/A — zero sample**
```

**User post–Phase 3A++ + Phase 3 lock (§Test 3.5, Q60)** *(2026-05-10 — MT5 **Backtest** tab + Inputs + Journal; FY **2025-01-01 → 2025-12-31** XAUUSD **M5**; **every tick based on real ticks**; **$10,000** / **1:500**; **only [5] SmartMoney = true**; **`InpMinQualityScore = 60`**, **`InpMinConsensus = 1`**, all **`InpRequire_*` = false**; fixed lot **0.01**, max spread **50**, time filter **off**; Magic **20260505** per Inputs; history **99%**; **~61.74M** ticks / **~70,630** bars)*  
```
Trades: 1 | Deals: 2 | WR: 100% (1 W / 0 L) | PF: ~3213 (n=1 — not meaningful) | Net: +$96.35
Gross +$96.38 / −$0.03 | Expected payoff: ~$96.35 | Sharpe: n/a (single trade) | Recovery: 2.22
Max balance DD: 0.00% ($0.03) | Max equity DD: 0.43% ($43.39)
Long: 1 @ 100% WR | Short: 0 @ n/a
Entries by hour: **Hour 20** | By weekday: **Monday** | By month: **November**
Grade: [ ] A [ ] B [ ] C [ ] D [x] **n/a** (insufficient sample — not A–D ladder)
Avg trade duration: use MT5 Report / **History** *(not in supplied summary)*
```

**Journal:** clean **`OnDeinit`** (reason **1**); engine bar counter **~70,631** — **not** MT5 **1** trade.

**Code evolution (`SmartMoney.mqh`):**
- **Phase 3A (2026-05-07):** removed **activation deadlock** (`return m_bosDetected` after `UpdateMarketStructure` cleared it); expanded regimes (**TRENDING / VOLATILE / RANGING**); **BOS** threshold **1.0×ATR**; momentum **RSI/MACD AND**.
- **Phase 3A+ (2026-05-08):** removed **`CheckActivation`** gate that skipped **`CalculateSignal`** when **TRENDING** + **`STRUCTURE_NONE`**; **`structOk`** allows **`STRUCTURE_NONE`** with BOS.
- **Phase 3A++ v3 (2026-05-10):** **BOS** uses **`MathMax(High0,High1)`** / **`MathMin(Low0,Low1)`** (new-bar EA); **`m_bosThreshold` → 0.45×ATR**; momentum **OR** gate (RSI **32**/ **68** bands vs MACD); **`REGIME_CALM`** added to active regimes.

**Engineering interpretation (§Test 3.5 / Q60 — post–3A++ verified):**
- **Isolated performance:** **Alive** (**1** MT5 position) but **extreme undertrading** vs FY cohort (**127–212** tr class on other modules) — **not** a production attribution sample; **PF** inflated and **ignored** at **n=1**.
- **vs §2.2.D ensemble** (**123** tr, **+$1,173.83**, PF **1.32**, WR **41.46%**, eq DD **13.57%**): SmartMoney adds **negligible** marginal throughput (**1** vs **123** fills) and **~+$96** net — **hypothesis-only** contributor until **10×+** more fills or explicit **Q30** diagnostic proves gate vs signal starvation.
- **BUY vs SELL:** **Long-only** in sample — **no** SELL path validation.
- **Trade frequency:** **Severe undertrading**; **overtrading:** **none**. **H2:** single **Nov** / **Mon** / **hr 20** point — **no** London/NY overlap cluster in **n=1**; confirm **Jan–Oct / Dec** empty in **History** export.
- **Regime dependency:** still plausible — **BOS + structOk + momentum** stack remains **sparse** even after **3A++**; optional next: **Q30** duplicate, **`Print`** gated BOS hits, or further **threshold** review (**isolated to `SmartMoney.mqh`**).
- **Runtime:** clean tester completion; **no** invalid-stop / stack-overflow narrative in supplied Journal.

**Phase 3 checklist (3.5) — user Q60 post–3A++:** vs **§2.2.D** — **1** marginal trade / **+$96.35** net. **BUY/SELL:** **1** / **0**. **Undertrading:** **yes** (critical). **Overtrading:** **no**. **H2:** **unverified** (single point). **Quality class:** **insufficient sample**. **Ensemble:** **REWORK** before any weight; **not REMOVE** (module **non-silent**). **not KEEP** as-is.

**Recommendation:** **REWORK** — further **`SmartMoney.mqh`** loosening **or** **Q30** isolation to split **quality vs signal** density; then **§3.10** vs **`2.2.D`** **or** **PriceAction** short-side pass (**§3.6** verified **190** tr).

**Status:** [x] **Post-fix** logged · [x] **Post–Phase 3A user Q60 ×2** archived (**0** tr) · [x] **Post–Phase 3A++ SmartMoney Q60 verified** *(user FY2025 M5 — Report **1** tr, net **+$96.35**)*

---

**Test 3.6: PriceAction ONLY**
```
InpUsePriceAction = true
All others = false
```
**Post-fix results (pre–Phase 3A `PriceAction.mqh`)** *(May 8, 2026 — MT5 Report + Inputs; FY 2025 XAUUSD M5; only **[6] PriceAction = true**; fixed lot **0.01**, max spread **50**, risk/time per Inputs)*  
```
Trades: 0 | WR: n/a | PF: 0.00 | Net: $0.00 | Deals: 0
Sharpe / Recovery: 0.00 | DD: 0% | History quality: 99% | Bars: ~70,630 | Ticks: ~61.74M (per Report)
Charts: no entries by hour / weekday / month
Grade: [ ] A [ ] B [ ] C [ ] D [x] **N/A — zero sample**
```

**User post–Phase 3A + Phase 3 lock (Test 3.6, Q60)** *(FY 2025 XAUUSD M5; **only [6] PriceAction = true**; **InpMinQualityScore = 60**, **InpMinConsensus = 1**, all **`InpRequire_*` = false**; fixed lot **0.01**; time filter **off**; history **99%**)*  

*Run A — max spread **50**, Magic **20250505**:*  
```
Trades: 0 | WR: n/a | PF: 0.00 | Net: $0.00 | Deals: 0
Bars: ~70,630 | Ticks: ~61.74M | Charts: empty hour / weekday / month
```

*Run B — max spread **30**, Magic **20260505** (later capture):*  
```
Trades: 0 | WR: n/a | PF: 0.00 | Net: $0.00 | Deals: 0
Bars: ~70,630 | Ticks: ~61.74M | Charts: empty
Grade: [ ] A [ ] B [ ] C [ ] D [x] **N/A — zero sample**
```
**Journal `Total Trades: ~70,630`:** **`g_totalTrades`** ≈ **bars processed** — **not** MT5 deal count. **Report “Total trades”** is authoritative. **Do not** infer fill rate from Journal bar counter. **After Phase 3B compile:** grep **`[PA-DIAG]`** when diagnosing **pattern vs gate** starvation (optional; tester-capped).

**Phase 3A (`PriceAction.mqh` — 2026-05-08):** pattern-only **`CheckActivation`** (removed pattern+key deadlock vs `CalculateSignal`); **ATR-scaled** `IsNearKeyLevel` (**4×ATR** floor); **prox 120** + **vol mult 0.88** + **`max(bar0,bar1)`** volume.

**Phase 3B (`PriceAction.mqh` — 2026-05-08):** **`CheckActivation` → always `true`**; **soft wick** patterns **`m_softBullPA` / `m_softBearPA`** counted in bull/bear tallies; **ATR pad 6×**; **vol mult 0.72**; **tester-only `[PA-DIAG]`** lines (**≤40**) when **`m_patternCount > 0`**.

**Phase 3A++ v4 (`PriceAction.mqh` — 2026-05-07):** **`volOk`** when **`GetAverageVolume(20) ≤ 0`** (tester-safe); **`IsNearKeyLevel`** **BB middle** fallback + **ATR ×10** pad floor (was **×6**); **prox 180**; **vol mult 0.55**; soft PA loop **shifts 0–1**.

**User post–Phase 3A++ v4 + Phase 3 lock (§Test 3.6, Q60)** *(2026-05-07 — MT5 **Backtest** tab + Inputs; FY **2025-01-01 → 2025-12-31** XAUUSD **M5**; **every tick based on real ticks**; **$10,000** / **1:500**; **only [6] PriceAction = true**; **`InpMinQualityScore = 60`**, **`InpMinConsensus = 1`**, all **`InpRequire_*` = false**; time filter **off**; Mon–Fri **true**; history **99%**; **~61.74M** ticks / **~70,820** bars per Journal context)*  
```
Trades: 190 | Deals: 380 | WR: 34.74% (66 W / 124 L) | PF: 1.02 | Net: +$111.00
Gross +$6,382.07 / −$6,271.07 | Expected payoff: ~$0.58 | Sharpe: 0.10 | Recovery factor: 0.07
Max equity DD: 12.92% ($1,500.10) | Max balance DD: (per Report) | History quality: 99%
Long: 112 @ 42.86% WR | Short: 78 @ 23.08% WR
Largest win $103.53 | Largest loss −$60.91 | Avg profit trade ~$96.70 | Avg loss trade ~−$50.53
Max consec. wins: 15 (+$1,386.39) | Max consec. losses: 19 (−$986.39)
Z-score: −8.77 (99.74%) | LR correlation: ~0.04
Entries by hour: peaks **Asia ~04–06** and **US ~17–19** (per chart capture); 24h participation with lulls **22–01**
Entries by weekday: **Tue / Thu** busiest in capture; Mon/Wed lower
Entries by month: **Apr** peak in capture; **Jul** thinner — **scroll full Report** to confirm **Aug–Dec** bars vs **H2 inactivity** hypothesis (monthly panel may crop in UI)
Grade: [ ] A [ ] B [ ] C [ ] D [x] **D** (WR < 65%)
Avg trade duration: record from MT5 Report **Average holding time** / **History** *(not in supplied screenshot)*
```

**Journal:** clean **`OnDeinit`** (reason **1**); **no** stack / invalid-stop / execution-error strings in supplied shutdown log — **MT5 does not echo every fill** to Journal in fast tester runs; **Report** remains authoritative for **n** / PnL. Engine **bars processed ~70,820** — **not** MT5 **190** trades.

**Engineering interpretation (§Test 3.6 / Q60 — post–3A++ v4 verified):**
- **Isolated performance:** **Alive** — **positive** net (**+$111**) and **PF > 1** (**1.02**) on **n = 190** — statistically usable vs **0**-trade era; edge is **very thin** (expected payoff **~$0.58**/trade; gross nearly **balanced**).
- **vs §2.2.D** (**123** tr, **+$1,173.83**, PF **1.32**, WR **41.46%**, eq DD **13.57%**): PriceAction-only runs **+54%** more trades (**190** vs **123**) but **−90%** net dollars, **−23%** PF, **−6.7 pp** WR, **slightly lower** headline max equity DD (**12.92%** vs **13.57%**) — **does not beat** locked ensemble economics as a **standalone sleeve** at **Q60** on this FY sample; plausible **diversification / pattern** module only after **short** and **PF** rework.
- **BUY vs SELL:** **long-dominant count** (**112** vs **78**) and **quality** (**42.9%** vs **23.1%** WR) — **clear directional bias**; **SELL** path **structurally weak** (same family as §3.1–3.3 / 3.2 / 3.8).
- **Risk efficiency:** **Recovery factor 0.07** with **~12.9%** equity DD for **~1.1%** net on **$10k** — **poor** return-on-drawdown vs **SupplyDemand** / **Breakout** cohort; **19** max consecutive losses cluster vs **15** wins — **unstable** feel despite **PF > 1**.
- **Trade frequency:** **not** undertrading (**190** FY); **not** overtrading vs **~71k** bars (**~0.27%** of bars) — **moderate** cadence.
- **H2 / regime:** monthly histogram in capture suggests **H1 > H2** density — **confirm** with full-year **History** export (screenshot may truncate months). If **Aug–Dec** truly thin while **Total trades = 190**, treat as **calendar / regime dependency** for PA stack.
- **Runtime / execution:** tester completed; invalid stops / stack overflow **not** observed in supplied materials.

**Phase 3 checklist (3.6) — user Q60 post–3A++ v4:** vs **§2.2.D** — **190** trades / **+$111** net. **BUY/SELL:** **112** / **78**; short WR **23.08%**. **Avg duration:** from Report/History. **Undertrading:** **no**. **Overtrading (Report):** **no**. **H2:** **verify** (monthly chart / export). **Quality class:** **D** (WR). **Ensemble:** **REWORK** before weight — **not REMOVE** (module **validated**); **not KEEP** as primary edge.

**Recommendation:** **REWORK** — **short-side** / bearish PA confirmation + optional **H2** path review (**isolated** to **`PriceAction.mqh`** + shared candle helpers if needed); optional **Q30** duplicate to separate **global quality** vs **PA** density. **Next Phase 3 test:** **§3.5 SmartMoney** trade-density **or** **§3.10** subset vs **`2.2.D`** **or** **H2** export triage on **MomentumScalp** / **SupplyDemand** per priority.

**Status:** [x] **Post-fix** logged · [x] **User Q60 post–3A ×2** archived (**0** tr) · [x] **Post–Phase 3B + Phase 3A++ v4 PriceAction Q60 verified** *(user FY2025 M5 — Report **190** tr, PF **1.02**, net **+$111.00**)* · [ ] **Optional:** Report **average holding time** line + **full monthly** export appended here

---

**Test 3.7: GridRecovery ONLY** ⚠️ *(roadmap ID; some lab sheets label “Test 3.6” for Grid — use **§3.7** here.)*
```
InpUseGridRecovery = true
All others = false
InpMinQualityScore = 60
InpMinConsensus = 1
InpRequireTrendAlign / KeyLevel / Momentum = false
```
**Post-fix results (pre–Phase 3A `GridRecovery.mqh`)** *(May 8, 2026 — MT5 Report + Inputs; FY 2025 XAUUSD M5; only **[7] GridRecovery = true**; fixed lot **0.01**, max spread **50**, risk/time per Inputs)*  
```
Trades: 0 | WR: n/a | PF: 0.00 | Net: $0.00 | Deals: 0
Sharpe / Recovery: 0.00 | DD: 0% | History quality: 99% | Bars: ~70,630 (per Report)
Charts: no entries by hour / weekday / month
Grade: [ ] A [ ] B [ ] C [ ] D [x] **N/A — zero sample**
```
**Journal `Total Trades: ~70,630`:** equals **bar count** with **0** MT5 fills → **`g_totalTrades`** (see §Test 3.1). **Not** grid overtrading — **Report** is authoritative.

**Phase 3A (`GridRecovery.mqh`):** (1) **P0 first-leg** — first arm now emits **BUY/SELL** + strength + **`return`**. (2) **RSI reset** — neutral **`46–54`**. (3) **Activation** — **`VOLATILE` + `TRENDING`**, **`atrRatio ≥ 1.08`**. (4) **RSI arms** **38 / 62**; **`HasReversalSignal`** aligned. (5) **Volume** — **`MathMax(GetVolume(0), GetVolume(1))`** vs average.

**User post–Phase 3A + Phase 3 lock (§Test 3.7, Q60)** *(May 8, 2026 — MT5 Report + Inputs + Journal; FY **2025-01-01 → 2025-12-31** XAUUSD **M5**; **every tick based on real ticks**; deposit **$10,000**, leverage **1:500**; **only [7] GridRecovery = true**; **`InpMinQualityScore = 60`**, **`InpMinConsensus = 1`**, all **`InpRequire_*` = false**; fixed lot **0.01**, max spread **50** pts, time filter **off**; Magic **20260505** per Inputs capture; history **99%**; **~70,630** bars / **~61.74M** ticks per Report)*  
```
Trades: 18 | Deals: 36 | WR: 38.89% (7 W / 11 L) | PF: 1.18 | Net: +$104.59
Gross +$674.72 / −$570.13 | Expected payoff: ~$5.81 | Sharpe: 0.54 | Recovery: 0.22
Max equity DD: 4.64% ($478.41) | Max balance DD: 3.15% ($321.21) | Z-score: −1.57 (88.12%)
Long: 14 @ 42.86% WR | Short: 4 @ 25.00% WR
Largest win $101.48 | Largest loss −$58.48 | Avg win ~$96.39 | Avg loss ~−$51.78
Max consec. wins: 3 (+$299.10) | Max consec. losses: 6 (−$320.97)
Entries by hour: cluster **14:00–22:00** (US); small cluster **~10:00**; gap **11:00–13:00** in capture
Entries by weekday: Mon 1 · Tue 2 · Wed 5 · Thu 7 · Fri 3
Entries by month: sparse FY — peaks **Apr / Jul / Oct** (**3** each in chart); **Mar / Jun / Sep** **0** trades (confirm in History export)
Grade: [ ] A [ ] B [ ] C [ ] D [x] **D** (WR < 65%)
Avg trade duration: use MT5 Report / **History** “holding time” column *(not in supplied summary row)*
```
**Journal `Total Trades: ~70,848`:** **`g_totalTrades`** (bars + successful opens) — **not** MT5 **18**. Same **artifact class** as §3.2 / §3.4 — **Report `Total Trades`** is authoritative for **frequency** / **overtrading** judgment (**18** FY ≈ **undertrading**, not **70k** fills).

**Engineering interpretation (Phase 3 attribution vs §2.2.D ensemble):**
- **Standalone edge:** **Positive** net and **PF > 1** on **tiny n** (**18**) — **weak statistical power**; treat as **“alive + non-catastrophic”**, not **production-grade** edge.
- **vs `2.2.D`** (**123** tr, **+$1,173.83**, PF **1.32**, WR **41.46%**, eq DD **13.57%**): GridRecovery-only is **~85% fewer** trades, **~91% less** net dollars, **lower** PF/WR, **much lower** isolated equity DD (**4.64%**) — **does not replace** ensemble economics; **optional** niche / risk-off sleeve if ever enabled with **hard caps** (default **`InpUseGridRecovery = false`** remains correct).
- **BUY vs SELL:** **Long-dominant** (**14** vs **4**); shorts **25%** WR on **n=4** — **directional bias** + **underpowered** short sample → same **short-weak** family as §3.1–3.3 / 3.2.
- **Trade frequency:** **Undertrading** vs a **100+ trades/year** “healthy module” heuristic; **not** overtrading (Report). **Regime dependency:** sparse **month** histogram → activation stack (**regime + atrRatio + RSI arms**) still **filters most** of FY.
- **H2 / calendar:** **Zero-trade months** (**Mar, Jun, Sep** in chart) — **H2-style inactivity** in the **“few fills”** sense (distinct from §3.1 **risk halt** narrative); verify **May / Aug / Nov / Dec** in terminal export.
- **Runtime / execution:** clean tester **deinit** in Journal snippet; **no** stack overflow / invalid-stop strings in supplied log — **stable** completion.
- **Risk efficiency:** modest net vs **~4.6%** max equity DD — acceptable **isolation** envelope; **grid tail risk** not fully stressed at **n=18**.

**KEEP / REWORK / REMOVE:** **REWORK** — **do not** default-enable in ensemble; **do not REMOVE** (module **verified trade-producing** post–3A). Optional: **Q30** duplicate only to split **quality vs signal** density; **short-side** / **month clustering** review before any **§3.10** weight > 0.

**Recommendation:** **REWORK** (risk caps, short quality, larger-sample re-run or walk-forward); **next Phase 3 test:** **§3.6 PriceAction** **Phase 3B** **or** **§3.5 SmartMoney 3A+** re-verify per priority.

**Phase 3 checklist (3.7) — user Q60 post–3A:** vs **§2.2.D** — **18** marginal trades / **+$104.59** net. **BUY/SELL:** long **14** / short **4**; short WR **25%**. **Avg duration:** from Report/History. **Undertrading:** **yes** (sparse FY). **Overtrading:** **no** (Report). **H2:** some **zero-month** gaps. **Quality class:** **D** (WR). **Ensemble contribution:** **low throughput** positive PF — **hypothesis-only** for mix until re-ensemble (**§3.10**). **Runtime:** clean.

**Status:** [x] **Post-fix** logged · [x] **Post–Phase 3A GridRecovery verified** *(user FY2025 M5 **Q60** isolation — Report **18** tr)*

---

**Test 3.8: MomentumScalping ONLY**
```
InpUseMomentumScalp = true
All others = false
InpMinQualityScore = 60
InpMinConsensus = 1
InpRequireTrendAlign / KeyLevel / Momentum = false
```
**Post-fix results (pre–Phase 3A `MomentumScalping.mqh`)** *(May 8, 2026 — MT5 Report + Inputs; FY 2025 XAUUSD M5; only **[8] MomentumScalp = true**; fixed lot **0.01**, max spread **50**, risk/time per Inputs; Magic **20250505** per screenshot)*  
```
Trades: 0 | WR: n/a | PF: 0.00 | Net: $0.00 | Deals: 0
Sharpe / Recovery: 0.00 | DD: 0% | History quality: 99% | Bars: ~70,630 | Ticks: ~61.74M (per Report)
Charts: no entries by hour / weekday / month
Grade: [ ] A [ ] B [ ] C [ ] D [x] **N/A — zero sample**
```
**Journal `Total Trades: ~70,630`:** matches **bar count** with **0** MT5 fills → **`g_totalTrades`** (see §Test 3.1). **Not** scalper overtrading — **Report** is authoritative.

**Phase 3A (`MomentumScalping.mqh` — in repo):**
- **Volume vs forming bar:** **`MathMax(GetVolume(0), GetVolume(1))`** in **`CheckActivation`** / **`HasVolumeConfirmation`** (tester bar-0 volume trap).
- **Floors (tester visibility):** volume mult **1.05**, **`atrRatio`** **1.06**; **`IsActiveInCurrentRegime`**.
- **RSI vs 2-of-3:** BUY **(38, 85)** · SELL **(15, 62)** so **`IsBullishMomentum`/`IsBearishMomentum`** paths are not self-vetoed.

**User post–Phase 3A + Phase 3 lock (§Test 3.8, Q60)** *(May 8, 2026 — MT5 Report + Inputs + Journal; FY **2025-01-01 → 2025-12-31** XAUUSD **M5**; **every tick based on real ticks**; **$10,000** / **1:500**; **only [8] MomentumScalp = true**; **`InpMinQualityScore = 60`**, **`InpMinConsensus = 1`**, all **`InpRequire_*` = false**; fixed lot **0.01**, max spread **30** pts per Inputs capture; Magic **20260505**; history **99%**; **~70,680** bars / **~61.74M** ticks per Report)*  
```
Trades: 126 | Deals: 252 | WR: 38.10% (48 W / 78 L) | PF: 1.18 | Net: +$715.02
Gross +$4,641.73 / −$3,926.71 | Expected payoff: ~$5.67 | Sharpe: 0.72 | Recovery: 0.48
Max balance DD: 12.27% ($1,483.87) | Max equity DD: 13.39% ($1,656.04)
Long: 71 @ 52.11% WR | Short: 55 @ 30.91% WR
Largest win $102.37 | Largest loss −$80.87 | Avg win ~$96.70 | Avg loss ~−$50.34
Max consec. wins: 15 (+$1,479.68) | Max consec. losses: 24 (−$1,242.75)
Z-score: 7.96 (99.74%) — strong streak structure in sample
Entries by month (chart): **Jan–Jun** heavy (**Apr / May** peaks ~**40** each); **Jul–Dec** **0** trades in capture → **H2 inactivity** (regime / activation / data path — confirm in **History** export)
Entries by hour: **US** session dominant (**~16:00** spike in chart); Asia moderate; Europe low
Grade: [ ] A [ ] B [ ] C [ ] D [x] **D** (WR < 65%)
Avg trade duration: use MT5 Report / **History** holding time *(not in supplied summary)*
```
**Journal `Total Trades: ~70,756`:** **`g_totalTrades`** (bars + opens) — **not** MT5 **126**. **Report** is authoritative for **trade frequency** — **~126** FY M5 is **moderate** cadence (**not** “70k fills”).

**Engineering interpretation (Phase 3 attribution vs §2.2.D ensemble):**
- **Standalone edge:** **Positive** net, **PF > 1**, **meaningful n** (**126**) — module **validated active** post–**3A**; **WR 38.1%** still **Grade D** vs project WR targets.
- **vs `2.2.D`** (**123** tr, **+$1,173.83**, PF **1.32**, WR **41.46%**, eq DD **13.57%**): Momentum-only lands **similar** trade count (**126**), **lower** net (**+$715** vs **+$1,174**), **lower** PF (**1.18** vs **1.32**), **WR** slightly **below** baseline, equity DD **~13.4%** **in line** with ensemble band — plausible **contributor** with **short-side rework** (same asymmetry class as §3.1–3.3).
- **BUY vs SELL:** **Long** **52%** WR (**71** tr) vs **Short** **31%** WR (**55** tr) — **directional bias** + **weak short engine** (not **REMOVE** on isolation alone).
- **Trade frequency:** **not** undertrading (**126** FY); **not** MT5 overtrading vs bar count — ignore Journal **`g_totalTrades`** for frequency.
- **H2:** **Jul–Dec** **zero** entries in monthly chart — **severe** calendar / regime gap; triage vs **`CheckActivation`**, **regime** classification mid-year, or **export** confirmation.
- **Runtime:** clean **deinit** in Journal snippet; **no** stack/invalid-stop flags in supplied log.

**KEEP / REWORK / REMOVE:** **REWORK** — **keep** module in attribution set; tighten **H2** + **short** quality before treating as **primary edge** live; **not REMOVE**.

**Recommendation:** **REWORK** (shorts, H2 silence path, optional **cooldown**/re-arm to reduce loss streak clustering); **next:** **`SmartMoney.mqh`** density **or** **§3.10** subset vs **`2.2.D`** **or** **PriceAction** short/H2 (**§3.6** **190** tr logged).

**Phase 3 checklist (3.8) — user Q60 post–3A:** vs **§2.2.D** — **126** marginal trades / **+$715.02** net. **BUY/SELL:** **71** / **55**; short WR **31%**. **Avg duration:** from Report/History. **Undertrading:** **no**. **Overtrading (Report):** **no**. **H2:** **yes** (no fills **Jul–Dec** in chart). **Quality class:** **D**. **Ensemble:** plausible **secondary** contributor until shorts/H2 fixed. **Runtime:** clean.

**Status:** [x] **Post-fix** logged · [x] **Post–Phase 3A MomentumScalp verified** *(user FY2025 M5 **Q60** isolation — Report **126** tr; spread **30** Inputs)*

---

> **Isolate rollup (FY 2025 M5 XAU, Q60, consensus 1, post `InpUse*` mask):** **Trade-producing:** **TrendFollowing** (**127**), **MeanReversion** (**43**), **Breakout** (**158**), **SupplyDemand** (**212**), **GridRecovery** (**18**), **MomentumScalp** (**126**), **PriceAction** (**190** post–**Phase 3A++ v4** `PriceAction.mqh` + user **§3.6 Q60**), **SmartMoney** (**1** ⚠️ post–**Phase 3A++ v3** — **extreme undertrading**, not ensemble-grade **n**). **Zero-trade:** **none** in current FY isolation log set (all eight modules **≥1** MT5 trade). **Attribution caveat:** **SmartMoney** **n=1** and **PriceAction** **PF 1.02** / **REWORK** tier — **§3.10** + density/short rework before live weights.

**Status — CHECKPOINT 3.1–3.8:** [x] **COMPLETE** *(all eight individual strategy isolations logged incl. **§3.6 PriceAction** **190** tr **Q60** post–**3A++ v4** · **§3.5 SmartMoney** **1** tr · **§3.4 SupplyDemand** **212** tr · **§3.7 GridRecovery** **18** tr · **§3.8 MomentumScalp** **126** tr)*

---

### ✅ CHECKPOINT 3.9: Strategy Performance Ranking

**Rank strategies by Profit Factor:**

| Rank | Strategy        | PF   | WR    | Trades | Net $   | Grade | Keep? |
|------|-----------------|------|-------|--------|---------|-------|-------|
| 1    | TrendFollowing  | 1.29 | 40.9% | 127    | +1112.58 | D     | REWORK |
| 2    | Breakout        | 1.25 | 39.87% | 158    | +1224.61 | D     | REWORK |
| 3    | SupplyDemand    | 1.23 | 39.15% | 212    | +1523.98 | D     | REWORK |
| 4    | MomentumScalp   | 1.18 | 38.10% | 126    | +715.02  | D     | REWORK |
| 5    | GridRecovery    | 1.18 | 38.89% | 18     | +104.59  | D     | REWORK |
| 6    | MeanReversion   | 1.15 | 39.5% | 43     | +197.14  | D     | REWORK |
| 7    | PriceAction     | 1.02 | 34.74% | 190    | +111.00  | D     | REWORK |
| 8    | SmartMoney      | n/a† | 100%‡ | 1      | +96.35   | n/a   | REWORK |

**Notes:** †**PF** not used for ranking at **n=1** (Report may show **>3000** — meaningless). ‡**WR** on **1** winning long only. **PriceAction** row **post–Phase 3A++ v4** + user **§3.6 Q60** (**190** tr, PF **1.02**) — **supersedes** **0**-trade / **N/A** placeholder; **lowest** ranked **PF** among modules with **meaningful n**, ahead of **SmartMoney** on **economics** but behind on **sample risk**. **Seven** modules with **PF > 1** + **Grade D** WR — **REWORK** shorts / **H2** before ensemble. **Next:** **`SmartMoney.mqh`** density **or** **§3.10** vs **`2.2.D`** **or** **PriceAction** short/H2 pass.

**Recommended Configuration:**
```
Keep strategies with:
✅ Grade A or B (WR >70%)
✅ Positive Profit Factor
✅ Reasonable trade count (100+ per year)

Disable strategies with:
❌ Grade D (WR <65%)
❌ Negative or very low PF (<1.2)
❌ Causes large drawdowns
```

**Final Strategy Mix:**
```
[ ] TrendFollowing
[ ] Breakout
[ ] MeanReversion
[ ] SupplyDemand
[ ] SmartMoney
[ ] PriceAction
[ ] GridRecovery     (⚠️ Use with extreme caution!)
[ ] MomentumScalping
```

**Status:** [x] **PF table complete** (all **8** strategies, FY2025 post-fix; **SmartMoney** **1** tr **§3.5 Q60** post–**3A++** — **n** flagged; **PriceAction** **190** tr **§3.6 Q60** post–**3A++ v4**) — **mix / enable flags** pending **§3.10** + **SM** density + **H2** triage

### ✅ CHECKPOINT 3.10: Optimized Ensemble Test

**Test with only your selected strategies:**

```
Period: 2024.01.01 - 2024.12.31
Enable only strategies checked above
Quality: [Your optimal]
All other settings: Optimal from Phase 2
```

**Run backtest**

**Results:**
```
Total Trades:     _______
Win Rate:         _______%
Profit Factor:    _______
Max Drawdown:     _______%
Net Profit:       $_______
Sharpe Ratio:     _______
```

**Compare to Phase 2 (all strategies):**
```
[ ] BETTER (higher WR/PF, lower DD)
[ ] SAME (similar performance)
[ ] WORSE (degraded performance)
```

**Status:** [ ] COMPLETE

---

### 📊 PHASE 3 COMPLETION CHECKLIST

- [x] 3.1: TrendFollowing — **post-fix** logged May 8, 2026 (see Test 3.1 block)
- [x] 3.2: Breakout — **post–Phase 3A + Q60** logged (**158** tr, PF **1.25** — see §Test 3.2; supersedes May 8 silent row)
- [x] 3.3: MeanReversion — **post-fix** logged May 8, 2026 (see Test 3.3 block)
- [x] 3.4: SupplyDemand — **post–Phase 3A+ verified** — user **Q60** FY isolation (**212** tr, PF **1.23**, net **+$1,523.98** — see §Test 3.4; lab **“Test ID 3.8”** = same slot)
- [x] 3.5: SmartMoney — **post–Phase 3A++ verified** — user **Q60** FY isolation (**1** tr, net **+$96.35** — see §Test 3.5; archived **0**-trade **×2** rows)
- [x] 3.6: PriceAction — **post–Phase 3A++ v4 verified** — user **Q60** FY isolation (**190** tr, PF **1.02**, net **+$111.00** — see §Test 3.6; archived **0**-trade **×2** rows + superseded **pending 3B** note)
- [x] 3.7: GridRecovery — **post-fix** + **Phase 3A** + user **Q60** FY isolation logged (**18** tr, **+$104.59**, PF **1.18** — see §Test 3.7)
- [x] 3.8: MomentumScalp — **post-fix** + **Phase 3A** + user **Q60** FY isolation logged (**126** tr, **+$715.02**, PF **1.18** — see §Test 3.8)
- [x] 3.9: Strategy PF ranking table — **all 8 rows** filled (FY2025 post-fix); refine weights / decisions with **§3.10** + rework cycle
- [ ] 3.10: Optimized ensemble tested
- [ ] Results documented

**DECISION POINT:**

```
IF Ensemble better than individual:
   → Strategy diversification working ✅
   → PROCEED TO PHASE 4

IF Individual strategy outperforms:
   → Consider using single-strategy mode
   → OR review consensus logic
   → PROCEED TO PHASE 4 with note

IF All strategies weak (<1.5 PF):
   → Fundamental issue with EA logic ❌
   → DO NOT proceed
   → Review code or seek support
```

**Best Performing:**
```
Single Strategy:  _______________
Strategy Ensemble: _______________ (list active ones)
```

**Phase 3 Status:** [ ] PASS [x] PARTIAL [ ] FAIL

**Last updated:** May 7, 2026 — **§Test 3.6 PriceAction** user **Q60** verified (**190** tr, **+$111.00**, PF **1.02**); prior **May 10, 2026** — **§Test 3.5 SmartMoney** (**1** tr); **§Test 3.4 SupplyDemand** **212** tr (May 9); **§Test 3.2** Breakout unchanged.

**Date Completed:** _______________ *(when 3.1–3.10 + checklist done)*

---

---

# PHASE 4: RISK SYSTEM VERIFICATION (1-2 hours)
## Goal: Confirm Circuit Breakers Work

**Prerequisites:** ✅ Phase 3 PASSED (working strategy configuration)

---

### ✅ CHECKPOINT 4.1: Daily Loss Limit Test

**Settings:**
```
Use your optimal config from Phase 3
EXCEPT:
InpMaxDailyLossPct = 2.0  (Very tight for testing!)
```

**Run backtest on volatile month:**
```
Period: 2024.03.01 - 2024.03.31 (March, often volatile)
```

**What to check:**
```
1. Graph → Look for days that stop trading
2. Journal → Look for "Daily loss limit reached"
3. Confirm: No trades after limit hit on same day
4. Confirm: Trading resumes next day
```

**Expected:**
```
✅ Some days show early stop
✅ Journal shows warning messages
✅ No trades after limit
✅ Reset at midnight
```

**Status:** [ ] PASS [ ] FAIL

---

### ✅ CHECKPOINT 4.2: Equity Drawdown Limit Test

**Settings:**
```
InpMaxEquityDD = 5.0  (Very tight for testing!)
```

**Run backtest:**
```
Period: 2024.01.01 - 2024.12.31
```

**What to check:**
```
1. Graph → Look for flat periods after DD spike
2. Check max DD in report
3. Verify DD never exceeds 5%
```

**Expected:**
```
✅ Trading stops when DD approaches 5%
✅ Journal shows "Equity DD limit reached"
✅ No further trades until recovery
```

**Status:** [ ] PASS [ ] FAIL

---

### ✅ CHECKPOINT 4.3: Consecutive Loss Limit Test

**Settings:**
```
InpMaxConsecutiveLoss = 2  (Very tight!)
```

**What to check:**
```
1. Backtest tab → Look for trade sequences
2. Find 2 consecutive losses
3. Verify: No 3rd trade immediately after
4. Check Journal for cooldown message
```

**Expected:**
```
✅ After 2 losses, pause before next trade
✅ Journal shows "Consecutive loss limit"
```

**Status:** [ ] PASS [ ] FAIL

---

### ✅ CHECKPOINT 4.4: Position Limit Test

**Settings:**
```
InpMaxOpenPositions = 2  (Low for testing)
```

**Run with aggressive settings to generate many signals:**
```
InpMinQualityScore = 30
```

**What to check:**
```
1. Open Positions graph in report
2. Verify: Never more than 2 open at once
```

**Expected:**
```
✅ Max 2 positions simultaneously
✅ New trades wait for close
```

**Status:** [ ] PASS [ ] FAIL

---

### 📊 PHASE 4 COMPLETION CHECKLIST

- [ ] 4.1: Daily loss limit verified
- [ ] 4.2: Equity DD limit verified
- [ ] 4.3: Consecutive loss limit verified
- [ ] 4.4: Position limit verified

**DECISION POINT:**

```
IF All 4 limits work correctly:
   → Risk management operational ✅
   → PROCEED TO PHASE 5

IF ANY limit fails:
   → CRITICAL BUG ❌
   → DO NOT proceed to live
   → Fix risk management code
   → Re-test Phase 4
```

**Phase 4 Status:** [ ] PASS [ ] FAIL

**Date Completed:** _______________

---

---

# PHASE 5: PERFORMANCE OPTIMIZATION (2-4 hours)
## Goal: Tune Parameters for Target Metrics

**Prerequisites:** ✅ Phases 1-4 PASSED

**Target Metrics:**
- Win Rate: 70-75%
- Profit Factor: 2.2-2.8
- Max DD: <12%
- Sharpe: >1.5

---

### ✅ CHECKPOINT 5.1: TP/SL Optimization

**Test different TP/SL ratios:**

**Test 5.1.A: Default (2:1)**
```
InpTPCoefficient = 2.0
InpSLCoefficient = 1.0
InpStopLossPoints = 100
InpTakeProfitPoints = 200
```
**Results:** WR: ____% | PF: ____ | Avg Win: $____ | Avg Loss: $____

---

**Test 5.1.B: Conservative (1.5:1)**
```
InpTPCoefficient = 1.5
InpTakeProfitPoints = 150
```
**Results:** WR: ____% | PF: ____ | Avg Win: $____ | Avg Loss: $____

---

**Test 5.1.C: Aggressive (3:1)**
```
InpTPCoefficient = 3.0
InpTakeProfitPoints = 300
```
**Results:** WR: ____% | PF: ____ | Avg Win: $____ | Avg Loss: $____

---

**Test 5.1.D: Tight SL (50 pts)**
```
InpStopLossPoints = 50
InpTakeProfitPoints = 100
```
**Results:** WR: ____% | PF: ____ | Avg Win: $____ | Avg Loss: $____

---

**Best TP/SL Configuration:**
```
InpTPCoefficient = _______
InpSLCoefficient = _______
InpStopLossPoints = _______
InpTakeProfitPoints = _______
```

**Status:** [ ] COMPLETE

---

### ✅ CHECKPOINT 5.2: Trailing Stop Optimization

**Test different trailing configurations:**

**Test 5.2.A: Trailing OFF**
```
InpUseTrailing = false
```
**Results:** WR: ____% | PF: ____ | Avg Win: $____

---

**Test 5.2.B: Trailing ON (default)**
```
InpUseTrailing = true
InpTrailStartPips = 20
InpTrailDistancePips = 10
```
**Results:** WR: ____% | PF: ____ | Avg Win: $____

---

**Test 5.2.C: Tight Trailing**
```
InpTrailStartPips = 10
InpTrailDistancePips = 5
```
**Results:** WR: ____% | PF: ____ | Avg Win: $____

---

**Best Trailing Configuration:**
```
InpUseTrailing = _______
InpTrailStartPips = _______
InpTrailDistancePips = _______
```

**Status:** [ ] COMPLETE

---

### ✅ CHECKPOINT 5.3: Time Filter Optimization

**Test session restrictions:**

**Test 5.3.A: 24/7 Trading**
```
InpUseTimeFilter = false
All days = true
```
**Results:** Trades: ____ | WR: ____% | PF: ____

---

**Test 5.3.B: Weekdays Only**
```
InpUseTimeFilter = true
InpAllowSaturday = false
InpAllowSunday = false
```
**Results:** Trades: ____ | WR: ____% | PF: ____

---

**Test 5.3.C: Best Days Only**
```
Based on Phase 3 data, enable only best-performing days
Example: Tue + Wed + Thu
```
**Results:** Trades: ____ | WR: ____% | PF: ____

---

**Best Time Filter:**
```
Days Enabled: ___________________________
InpHourFrom = _______ (if time-of-day filter used)
InpHourTo = _______
```

**Status:** [ ] COMPLETE

---

### ✅ CHECKPOINT 5.4: Final Validation Test

**Run complete test with ALL optimal settings:**

```
Period: 2020.01.01 - 2024.12.31 (5 years!)
Settings: All optimized parameters from 5.1-5.3
```

**Results:**
```
Total Trades:     _______
Win Rate:         _______%
Profit Factor:    _______
Max Drawdown:     _______%
Net Profit:       $_______
Sharpe Ratio:     _______
Sortino Ratio:    _______
```

**Compare to Targets:**
```
Win Rate:     ____% (Target: 70-75%)     [ ] MET [ ] NOT MET
Profit Factor: ____ (Target: 2.2-2.8)    [ ] MET [ ] NOT MET
Max DD:       ____% (Target: <12%)       [ ] MET [ ] NOT MET
Sharpe:       ____ (Target: >1.5)        [ ] MET [ ] NOT MET
```

**Status:** [ ] COMPLETE

---

### 📊 PHASE 5 COMPLETION CHECKLIST

- [ ] 5.1: TP/SL optimized
- [ ] 5.2: Trailing stop optimized
- [ ] 5.3: Time filters optimized
- [ ] 5.4: Final 5-year validation complete

**DECISION POINT:**

```
IF 3/4 targets met:
   → Performance acceptable ✅
   → PROCEED TO PHASE 6

IF 2/4 targets met:
   → Marginal performance ⚠️
   → Consider further optimization
   → Or PROCEED with caution

IF <2/4 targets met:
   → Performance inadequate ❌
   → Review strategy logic
   → May need code changes
   → DO NOT proceed to live
```

**Phase 5 Status:** [ ] PASS [ ] PARTIAL [ ] FAIL

**Date Completed:** _______________

---

---

# PHASE 6: PRODUCTION READINESS (1 day)
## Goal: Final Checks Before Live Deployment

**Prerequisites:** ✅ Phases 1-5 PASSED

---

### ✅ CHECKPOINT 6.1: Walk-Forward Analysis

**Purpose:** Verify robustness across different periods

**Test 6.1.A: 2023 In-Sample**
```
Period: 2023.01.01 - 2023.12.31
Settings: Your final optimized config
```
**Results:**
```
WR: ____% | PF: ____ | DD: ____% | Net: $_____
```

---

**Test 6.1.B: 2024 Out-of-Sample**
```
Period: 2024.01.01 - 2024.12.31
Settings: SAME as 6.1.A (no changes!)
```
**Results:**
```
WR: ____% | PF: ____ | DD: ____% | Net: $_____
```

---

**Walk-Forward Efficiency:**
```
WFE = (OOS Net Profit) / (IS Net Profit) × 100%
WFE = (______) / (______) × 100% = ______%

✅ WFE >50%: Excellent robustness
⚠️ WFE 30-50%: Acceptable
❌ WFE <30%: Overfitted to in-sample
```

**Status:** [ ] PASS [ ] FAIL

---

### ✅ CHECKPOINT 6.2: Multi-Broker Test

**Test on different broker data if available:**

**Broker A:**
```
Results: WR: ____% | PF: ____ | DD: ____%
```

**Broker B:**
```
Results: WR: ____% | PF: ____ | DD: ____%
```

**Consistency Check:**
```
[ ] Results within 5% of each other
[ ] No extreme outliers
```

**Status:** [ ] PASS [ ] FAIL [ ] N/A

---

### ✅ CHECKPOINT 6.3: Demo Account Test (Critical!)

**Deploy to demo account:**

```
1. Open demo account (IC Markets, FP Markets, or VT Markets recommended)
2. Attach EA with CONSERVATIVE settings:
   - InpFixedLot = 0.01
   - InpMinQualityScore = 65 (slightly higher than optimal)
   - InpMaxDailyLossPct = 3.0 (tighter than backtest)
   - InpMaxEquityDD = 10.0 (tighter)
3. Monitor for 2 weeks MINIMUM
```

**Daily Monitoring Checklist:**
```
Day 1:  [ ] Trades executed [ ] No errors [ ] Panel displays correctly
Day 2:  [ ] Circuit breakers tested [ ] Logging functional
Day 3:  [ ] Win/loss pattern reasonable
Day 4:  [ ] Drawdown within limits
Day 5:  [ ] End of week review: ___________________________
Day 6:  [ ] Continued monitoring
Day 7:  [ ] Continued monitoring
...
Day 14: [ ] Two-week review complete
```

**2-Week Demo Results:**
```
Total Trades:     _______
Win Rate:         _______%
Profit Factor:    _______
Max Drawdown:     _______%
Daily Avg Trades: _______
```

**Compare to Backtest:**
```
[ ] Similar performance (within 10%)
[ ] Acceptable degradation (10-20% lower)
[ ] Significant degradation (>20% lower) - INVESTIGATE!
```

**Status:** [ ] PASS [ ] FAIL

---

### ✅ CHECKPOINT 6.4: Final Documentation

**Complete before live deployment:**

- [ ] Optimal settings documented in `.set` file
- [ ] Strategy configuration documented
- [ ] Risk limits documented
- [ ] Expected performance documented
- [ ] Broker account details documented
- [ ] VPS setup documented (if applicable)
- [ ] Emergency contact info noted

**Create Final Settings File:**
```
File: AurumSynapse_Production_YYYYMMDD.set

Save with all optimized parameters
Keep backup copy
```

**Status:** [ ] COMPLETE

---

### 📊 PHASE 6 COMPLETION CHECKLIST

- [ ] 6.1: Walk-forward analysis passed
- [ ] 6.2: Multi-broker test passed (or N/A)
- [ ] 6.3: 2-week demo test passed
- [ ] 6.4: Final documentation complete

**DECISION POINT:**

```
IF All checks PASSED:
   → READY FOR LIVE DEPLOYMENT ✅
   → Proceed with extreme caution
   → Start with minimum lot size

IF Demo test FAILED:
   → NOT READY ❌
   → Investigate differences
   → Extend demo testing
   → DO NOT go live

IF Walk-forward FAILED:
   → Overfitted to historical data ❌
   - Review optimization approach
   → May need code changes
```

**Phase 6 Status:** [ ] PASS [ ] FAIL

**Date Completed:** _______________

---

---

# 🚀 LIVE DEPLOYMENT PROTOCOL

**⚠️ ONLY proceed if ALL 6 phases PASSED**

### Live Deployment Checklist

**Account Setup:**
- [ ] Live account opened (minimum $1000 recommended)
- [ ] VPS configured (if 24/7 operation desired)
- [ ] EA installed on VPS/local MT5
- [ ] Production settings loaded

**Initial Configuration:**
```
Start Conservative:
InpFixedLot = 0.01 (MINIMUM)
InpMaxDailyLossPct = 2.0 (VERY TIGHT)
InpMaxEquityDD = 8.0 (VERY TIGHT)
InpMinQualityScore = [Your optimal + 5]
```

**Monitoring Schedule:**
```
Week 1:  Daily checks (2x per day)
Week 2:  Daily checks (1x per day)
Week 3-4: Every 2 days
Month 2+: Weekly reviews
```

**Scaling Plan:**
```
IF profitable after 2 weeks:
   → Increase lot to 0.02 (100% increase)
   
IF profitable after 1 month:
   → Increase lot to 0.03 (50% increase)
   
IF profitable after 2 months:
   → Relax risk limits slightly
   → InpMaxDailyLossPct = 3.0
   → InpMaxEquityDD = 10.0
```

**Emergency Procedures:**
```
STOP trading immediately if:
❌ Drawdown >15% (beyond tested limits)
❌ 5 consecutive losses (beyond normal)
❌ Any technical errors or crashes
❌ Unexpected behavior vs backtest
```

---

# 📊 PROJECT TRACKING

## Overall Progress

| Phase | Name | Status | Date | Result |
|-------|------|--------|------|--------|
| 0 | Development | ✅ COMPLETE | May 6, 2026 | - |
| 1 | Basic Functionality | ✅ COMPLETE | May 7, 2026 | 15 trades / 1 mo M5 / stable |
| 2 | Filter Calibration | 🟡 PARTIAL | May 8, 2026 | §**2.4** sweep ✅ — **lock** `2.2.D`; **P0** H2 + **`2.4.C`** verify → optional **consensus=3** or **Phase 3** (caution) |
| 3 | Strategy Validation | 🟡 IN PROGRESS | May 10, 2026 | **Breakout** ✅ **158** tr; **MomentumScalp** ✅ **126** tr; **GridRecovery** **18** tr; **SupplyDemand** ✅ **212** tr; **SmartMoney** ⚠️ **1** tr **§3.5 Q60**; **§3.6 PriceAction** ✅ **190** tr **§3.6 Q60** post–**3A++ v4** |
| 4 | Risk Verification | [ ] | _____ | _____ |
| 5 | Optimization | [ ] | _____ | _____ |
| 6 | Production Readiness | [ ] | _____ | _____ |
| 7 | Live Deployment | [ ] | _____ | _____ |

## Quick Reference

**Current Phase:** Phase 3 — **CHECKPOINT 3.1–3.8** complete; **§3.6 PriceAction** **Q60** (**190** tr, post–**3A++ v4**); **§3.5 SmartMoney** **Q60** (**1** tr, post–**3A++**); **§3.4 SupplyDemand** **212** tr; **§3.7** / **§3.8** logged; **Next:** **`SmartMoney.mqh`** trade-density **or** **§3.10** vs **`2.2.D`** **or** **PriceAction** short/H2 rework.

**Optimal Settings (fill as discovered):**
```
InpMinQualityScore = 60
InpMinConsensus = 1   // optional test: 3 vs 2.2.D before raising live risk
InpRequireTrendAlignment = false
InpRequireKeyLevel = false
InpRequireMomentum = false
InpTPCoefficient = 2.0 (default; tune in Phase 5 if needed)
InpSLPoints = 100 (default; XAUUSD min distances enforced in EA as applicable)
```

**Active Strategies:**
```
[ ] TrendFollowing
[ ] Breakout
[ ] MeanReversion
[ ] SupplyDemand
[ ] SmartMoney
[ ] PriceAction
[ ] GridRecovery
[ ] MomentumScalping
```

**Performance Achieved:** *(Phase 3 post-fix FY2025 XAU M5 — isolations 3.1–3.8)*  
**TrendFollowing:** WR 40.94%, PF 1.29, max equity DD 13.96%, net +$1,112.58  
**MeanReversion:** WR 39.53%, PF 1.15, max equity DD 12.15%, net +$197.14  
**Breakout:** WR **39.87%**, PF **1.25**, max equity DD **12.42%**, net **+$1,224.61**, **158** tr (**post–Phase 3A** `Breakout.mqh` + Q60 re-isolate — §Test 3.2)  
**SupplyDemand:** WR **39.15%**, PF **1.23**, max equity DD **13.30%**, net **+$1,523.98**, **212** tr (**post–Phase 3A+ v5/v6** `SupplyDemand.mqh` + `QualityFilter` isolation floor + §**3.4** Q60 user verify — Journal bar counter ≠ MT5 fills)  
**SmartMoney:** **1** trade user **§3.5 Q60** (spread **50**); net **+$96.35**; long-only; **Phase 3A++ v3** `SmartMoney.mqh` — **extreme undertrading** vs ensemble (**n** insufficient for PF/WR claims)  
**PriceAction:** WR **34.74%**, PF **1.02**, max equity DD **12.92%**, net **+$111.00**, **190** tr (**post–Phase 3A++ v4** `PriceAction.mqh` + §**3.6** Q60 user verify — Journal bar counter ≠ MT5 fills); **short** WR **23.08%** vs long **42.86%** — **REWORK** tier  
**GridRecovery:** WR **38.89%**, PF **1.18**, max equity DD **4.64%**, net **+$104.59**, **18** tr (**post–Phase 3A** `GridRecovery.mqh` + §**3.7** Q60 isolation — **⚠️ grid / low n**)  
**MomentumScalp:** WR **38.10%**, PF **1.18**, max equity DD **13.39%**, net **+$715.02**, **126** tr (**post–Phase 3A** `MomentumScalping.mqh` + §**3.8** Q60 — **H2** gap **Jul–Dec** in chart)

**Next Action:** **`SmartMoney.mqh`** further **trade-density** rehab **or** **Q30** diagnostic → **§3.5** re-run; **§3.10** vs **`2.2.D`**; **PriceAction** **short-side** / **H2** confirmation pass; optional **SM**/**Momentum**/**SupplyDemand** **H2** + short **rework** branch.

**Blocked On:** Product choice — **§3.10** vs continued **3A** silents

---

# 🆘 TROUBLESHOOTING QUICK GUIDE

**Problem:** 0 trades in backtest
**Solution:** Go to Phase 1 Troubleshooting C

**Problem:** Low win rate (<60%)
**Solution:** Increase quality threshold (Phase 2)

**Problem:** Circuit breakers not working
**Solution:** Review Phase 4, check Journal for errors

**Problem:** Backtest vs Demo mismatch
**Solution:** Check spread differences, server latency, data quality

**Problem:** All strategies grade D
**Solution:** Logic issue - review strategy code or contact support

---

**END OF VALIDATION ROADMAP**

**Next Step:** **`SmartMoney.mqh`** density **or** **§3.10** vs **`2.2.D`**. **§Test 3.5 SmartMoney** — **✅ Q60 logged** (**1** tr); optional **density** pass + re-verify. **§Test 3.4 SupplyDemand** — **✅** (**212** tr). **§Test 3.6 PriceAction** — **✅ Q60 logged** (**190** tr, PF **1.02**). **§Test 3.8 MomentumScalp** / **§Test 3.7 GridRecovery** — **done**; Journal **`g_totalTrades`** ≠ Report fills.

**Remember:** Take it slow, document everything, and NEVER skip to live without completing all phases!

**Good luck! 🚀**
