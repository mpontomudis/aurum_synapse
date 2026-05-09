# AURUM SYNAPSE - BACKTEST EXECUTION GUIDE

**Purpose:** Step-by-step instructions for running the complete test matrix  
**Date:** 2026-05-06

---

## PHASE 1: PREPARATION (15 minutes)

### Step 1: Verify Compilation
```
1. Open MetaEditor (F4)
2. Compile AurumSynapse.mq5 → must be 0 errors
3. Compile Tests/BacktestScripts/PerformanceAnalyzer.mq5 → must be 0 errors
```

### Step 2: Download Tick Data
```
1. In MT5: Tools → Options → Charts → Max bars: Unlimited
2. Open XAUUSD M1 chart
3. Scroll left to load history back to 2020.01.01
4. Wait for "Loading history..." to complete
5. In Strategy Tester: Select "Every tick based on real ticks"
6. MT5 will download tick data on first run (can take 10-30 min)
```

### Step 3: Set Up Strategy Tester
```
MT5 → View → Strategy Tester (Ctrl+R)

Settings:
  Expert:     Experts\AurumSynapse\AurumSynapse
  Symbol:     XAUUSD
  Period:     M1
  Modeling:   Every tick based on real ticks
  Deposit:    10000 USD
  Leverage:   1:500
  
  ⚠ IMPORTANT: Set "Show Panel" to FALSE for backtesting
     (Comment() slows down backtest significantly)
```

---

## PHASE 2: CORE TEST MATRIX (3-6 hours)

Run each test in order. After each test, save the report.

### Test T01: Balanced Full-Span (PRIMARY TEST)
```
Period:     2020.01.01 - 2025.12.31
Profile:    Balanced (Quality 60, 7/8 strategies ON, Grid OFF)
Save as:    RPT_balanced_2020-2025_full.html

Settings:
  InpLotMethod = 0 (Fixed)
  InpFixedLot = 0.01
  InpMinQualityScore = 60
  InpUseTrendFollowing = true
  InpUseBreakout = true
  InpUseMeanReversion = true
  InpUseSupplyDemand = true
  InpUseSmartMoney = true
  InpUsePriceAction = true
  InpUseGridRecovery = false
  InpUseMomentumScalp = true
  InpMaxDailyLossPct = 5.0
  InpMaxEquityDD = 12.0
  InpShowPanel = false

Expected: 2500-4000 trades/year, WR 70-75%, PF 2.0-2.8
This is the MOST IMPORTANT test. If this fails, stop.
```

### Test T02: Conservative Full-Span
```
Period:     2020.01.01 - 2025.12.31
Profile:    Conservative (Quality 70, 6/8 ON, Grid/MeanRev OFF)
Save as:    RPT_conservative_2020-2025_full.html

Change from T01:
  InpMinQualityScore = 70
  InpUseMeanReversion = false
  InpRequireTrendAlignment = true
  InpRequireKeyLevel = true
  InpMaxOpenPositions = 3

Expected: 800-2000 trades/year, WR 72-75%, PF 2.0-2.5
```

### Test T03: Aggressive Full-Span
```
Period:     2020.01.01 - 2025.12.31
Profile:    Aggressive (Quality 50, 8/8 ON incl Grid)
Save as:    RPT_aggressive_2020-2025_full.html

Change from T01:
  InpMinQualityScore = 50
  InpUseGridRecovery = true
  InpMaxEquityDD = 15.0

Expected: 4000-6500 trades/year, WR 68-70%, PF 1.8-2.2
⚠ Watch DD closely - GridRecovery adds tail risk
```

### Tests T04-T09: Annual Breakdown (Balanced Profile)

Run the **T01 Balanced settings** for each individual year:

| Test | Period | Save As | Market Character |
|------|--------|---------|-----------------|
| T04 | 2020.01.01 - 2020.12.31 | RPT_balanced_2020.html | COVID volatility |
| T05 | 2021.01.01 - 2021.12.31 | RPT_balanced_2021.html | Consolidation |
| T06 | 2022.01.01 - 2022.12.31 | RPT_balanced_2022.html | Rate hikes |
| T07 | 2023.01.01 - 2023.12.31 | RPT_balanced_2023.html | Recovery |
| T08 | 2024.01.01 - 2024.12.31 | RPT_balanced_2024.html | Bull run |
| T09 | 2025.01.01 - 2025.12.31 | RPT_balanced_2025.html | Recent (OOS) |

**Must be profitable in at least 5 of 6 years.**

### Test T10: Scalp Only (Edge Isolation)
```
Period:     2020.01.01 - 2025.12.31
Profile:    MomentumScalp ONLY (all others OFF)
Save as:    RPT_scalponly_2020-2025.html

Settings:
  InpUseTrendFollowing = false
  InpUseBreakout = false
  InpUseMeanReversion = false
  InpUseSupplyDemand = false
  InpUseSmartMoney = false
  InpUsePriceAction = false
  InpUseGridRecovery = false
  InpUseMomentumScalp = true (ONLY this one)
  InpMinQualityScore = 50

Purpose: Isolate the scalping edge from the consensus system.
If this alone is profitable with PF > 1.3, the primary edge exists.
```

### Tests T11-T12: Grid Impact Assessment
```
T11: Same as T01 but with Grid ON
  InpUseGridRecovery = true
  Save as: RPT_balanced_withgrid.html

T12 comparison:
  Compare T01 (no grid) vs T11 (with grid)
  If T11 Max DD > T01 Max DD × 1.5 → Grid is too risky
  If T11 PF > T01 PF × 1.2 → Grid adds value
  If T11 WR artificially inflated (>85%) → Grid is masking losses
```

---

## PHASE 3: POST-TEST ANALYSIS (1-2 hours)

### Step 1: Run Performance Analyzer

After each backtest, while the history is still loaded:

```
1. In Strategy Tester, switch to "Scripts" tab
2. Select: PerformanceAnalyzer
3. Set InpMagicNumber = 20260505
4. Set InpReportName = "T01_balanced_full" (match test ID)
5. Run
6. Check Experts tab for full analysis output
7. CSV exported to MQL5/Files/AurumSynapse/
```

### Step 2: Fill Report Template

```
1. Open Tests/PerformanceReports/ReportTemplate.md
2. Copy to new file: RPT_balanced_full_ANALYSIS.md
3. Fill in all sections from:
   - MT5 Strategy Tester report (Backtest tab → right-click → Save as HTML)
   - PerformanceAnalyzer output (Experts tab)
   - CSV data (for charts in Excel/Google Sheets)
```

### Step 3: Benchmark Comparison

Run these additional tests for benchmarks:

**Simple EMA Baseline:**
```
Create a simple EA (or use manual calculation):
- EMA(20) cross EMA(50) on M1
- Fixed SL 100pts, TP 200pts
- Same period as T01
- Compare PF, WR, DD vs Aurum
```

**Buy & Hold:**
```
Calculate XAUUSD % change for each year:
2020: $1,517 → $1,898 = +25.1%
2021: $1,898 → $1,829 = -3.6%
2022: $1,829 → $1,836 = +0.4%
2023: $1,836 → $2,077 = +13.1%
2024: $2,077 → $2,642 = +27.2%
2025: Check actual data

Aurum annual return must be > 2× buy-and-hold (risk-adjusted)
```

---

## PHASE 4: OPTIMIZATION (OPTIONAL, 4-8 hours)

Only proceed if Phase 2 tests PASS.

### Step 1: Quality Threshold Sweep
```
MT5 Strategy Tester → Optimization mode

Optimize: InpMinQualityScore
Range: 45 to 75, Step 5
Period: 2020.01.01 - 2024.03.31 (IN-SAMPLE ONLY!)
Criterion: Custom max (Profit Factor × Recovery Factor)

Save: OPT_quality_threshold_2020-2024.xml
```

### Step 2: SL/TP Sweep
```
Optimize: InpSLPoints + InpTPCoefficient
  InpSLPoints: 60 to 150, Step 10
  InpTPCoefficient: 1.5 to 3.0, Step 0.5
Period: 2020.01.01 - 2024.03.31 (IN-SAMPLE ONLY!)

Save: OPT_sltp_params_2020-2024.xml
```

### Step 3: Trailing Stop Sweep
```
Optimize: InpTrailStartPips + InpTrailDistPips
  InpTrailStartPips: 5 to 20, Step 5
  InpTrailDistPips: 3 to 10, Step 1
Period: 2020.01.01 - 2024.03.31 (IN-SAMPLE ONLY!)

Save: OPT_trailing_params_2020-2024.xml
```

### Step 4: Validate on OOS
```
Take best parameter set from each optimization
Run on OOS period: 2024.04.01 - 2025.12.31

Calculate Walk-Forward Efficiency:
  WFE = (OOS Annual Return) / (IS Annual Return) × 100%
  
  WFE > 60% → Use optimized parameters
  WFE 40-60% → Use with caution
  WFE < 40% → Reject, use default parameters
```

---

## PHASE 5: DECISION (30 minutes)

### Fill the Go/No-Go Checklist

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Full-span PF > 1.5 | [✅/❌] |
| 2 | Full-span WR > 60% | [✅/❌] |
| 3 | Full-span DD < 15% | [✅/❌] |
| 4 | At least 5/6 years profitable | [✅/❌] |
| 5 | t-statistic > 1.96 | [✅/❌] |
| 6 | Scalp-only test profitable | [✅/❌] |
| 7 | Beats buy-and-hold by 2× | [✅/❌] |
| 8 | Beats simple EMA by 50% | [✅/❌] |
| 9 | No red flags triggered | [✅/❌] |
| 10 | WFE > 40% (if optimized) | [✅/❌] |

### Decision Matrix

```
All 10 PASS      → Proceed to FORWARD TEST (demo, 2 weeks)
8-9 PASS         → Investigate failures, fix, retest
6-7 PASS         → MARGINAL - significant rework needed
< 6 PASS         → FAIL - major strategy revision required
```

---

## TIMELINE SUMMARY

```
Day 1 (4-6 hrs):
  ✓ Preparation (15 min)
  ✓ Core tests T01-T03 (2-3 hrs)
  ✓ Annual tests T04-T09 (2-3 hrs)

Day 2 (3-4 hrs):
  ✓ Special tests T10-T12 (1-2 hrs)
  ✓ Run PerformanceAnalyzer on all (1 hr)
  ✓ Fill report templates (1 hr)

Day 3 (4-8 hrs) - OPTIONAL:
  ✓ Optimization Phase 4 (4-8 hrs)
  ✓ OOS validation

Day 4 (1-2 hrs):
  ✓ Benchmark comparisons
  ✓ Final analysis and decision
  ✓ Go/No-Go determination
```

**Total estimated time: 8-20 hours (depending on optimization)**

---

## FILE OUTPUTS

After completing all phases:

```
Tests/
├── BacktestScripts/
│   ├── BacktestConfig.set
│   ├── BacktestMethodology.md
│   ├── PerformanceAnalyzer.mq5
│   └── RunAllBacktests.md (this file)
│
├── PerformanceReports/
│   ├── ReportTemplate.md
│   ├── RPT_balanced_2020-2025_full.html
│   ├── RPT_conservative_2020-2025_full.html
│   ├── RPT_aggressive_2020-2025_full.html
│   ├── RPT_balanced_2020.html
│   ├── RPT_balanced_2021.html
│   ├── RPT_balanced_2022.html
│   ├── RPT_balanced_2023.html
│   ├── RPT_balanced_2024.html
│   ├── RPT_balanced_2025.html
│   ├── RPT_scalponly_2020-2025.html
│   ├── RPT_balanced_withgrid.html
│   └── ANALYSIS_[date]_balanced.md
│
└── OptimizationResults/
    ├── OPT_quality_threshold_2020-2024.xml
    ├── OPT_sltp_params_2020-2024.xml
    ├── OPT_trailing_params_2020-2024.xml
    └── OPT_summary_[date].md
```

---

**Status:** Ready for Execution  
**Prerequisite:** AurumSynapse.mq5 compiles with 0 errors  
**Estimated Time:** 8-20 hours total

---

*© 2026 Aurum Synapse - Institutional-Grade Gold Trading Engine*
