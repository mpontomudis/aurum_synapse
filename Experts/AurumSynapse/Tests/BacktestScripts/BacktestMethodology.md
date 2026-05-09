# AURUM SYNAPSE v2.0 - BACKTESTING METHODOLOGY

**Version:** 1.0  
**Date:** 2026-05-06  
**Purpose:** Systematic validation framework for Aurum Synapse EA  
**Scope:** Backtest design, metrics, analysis, benchmarks, decisions

---

## TABLE OF CONTENTS

1. [Testing Philosophy](#1-testing-philosophy)
2. [Backtest Configuration](#2-backtest-configuration)
3. [Test Matrix](#3-test-matrix)
4. [Metrics Framework](#4-metrics-framework)
5. [Analysis Framework](#5-analysis-framework)
6. [Benchmark Comparisons](#6-benchmark-comparisons)
7. [Statistical Validation](#7-statistical-validation)
8. [Red Flags & Kill Criteria](#8-red-flags--kill-criteria)
9. [Optimization Protocol](#9-optimization-protocol)
10. [Forward Test Protocol](#10-forward-test-protocol)
11. [Decision Framework](#11-decision-framework)

---

## 1. TESTING PHILOSOPHY

### Core Principles

**Principle 1: Distrust Backtests by Default**  
Every backtest result is guilty until proven innocent. The default assumption is that positive results are artifacts of overfitting, data snooping, or modeling errors. The burden of proof is on the EA to demonstrate real edge through multiple independent tests.

**Principle 2: Out-of-Sample is the Only Truth**  
In-sample performance is noise. Only out-of-sample (OOS) results and live forward tests validate a strategy. Every test period must reserve unseen data for OOS validation.

**Principle 3: Robustness Over Optimality**  
The best parameter set is not the one with the highest profit - it is the one surrounded by other profitable parameter sets. An isolated peak is a red flag, not a feature.

**Principle 4: Realistic Execution Modeling**  
Every tick mode with real spread data. Anything less is fantasy. Commission, slippage, and swap must be modeled accurately.

**Principle 5: Multiple Time Horizons**  
A strategy that only works in trending markets or only in 2024 is not a strategy - it is a coincidence. Validate across multiple regimes, years, and volatility environments.

---

## 2. BACKTEST CONFIGURATION

### 2.1 MT5 Strategy Tester Settings

#### Model Selection

| Setting | Required Value | Rationale |
|---------|---------------|-----------|
| **Mode** | Every tick based on real ticks | Gold is tick-sensitive; M1 OHLC misses intra-bar dynamics |
| **Fallback** | Every tick (if real ticks unavailable) | Second-best accuracy for entry/exit timing |
| **Never Use** | Open prices only, 1 minute OHLC | Produces fantasy results for scalping strategies |

#### Execution Modeling

| Parameter | Value | Source |
|-----------|-------|--------|
| Commission | $7.00/lot round-trip | ICMarkets RAW (standard ECN) |
| Initial Deposit | $10,000 | Standard benchmark |
| Leverage | 1:500 | Typical for XAUUSD accounts |
| Currency | USD | Base currency |
| Lot Size | 0.01 fixed | Isolates strategy edge from position sizing |

> **Why 0.01 Fixed Lot?** Using fixed lot size during initial testing isolates the strategy's raw edge from money management effects. Once the raw edge is validated, switch to auto lot sizing for compounding tests.

#### Spread Modeling

| Source | Priority | Notes |
|--------|----------|-------|
| Real tick data (broker) | Best | Contains actual spread fluctuations |
| Current spread | Acceptable | If testing during market hours |
| Fixed spread | Last resort | Set to **25 points** (typical XAUUSD ECN) |

> **WARNING:** Fixed spread backtests significantly overstate performance for scalping strategies. The EA's spread filter (30 points max) must interact with realistic spread variability to be meaningful.

### 2.2 Symbol Requirements

| Requirement | Specification |
|-------------|---------------|
| Symbol | XAUUSD (or GOLD, depending on broker) |
| Digits | 2 (prices like 2650.25) |
| Tick Size | 0.01 |
| Min Lot | 0.01 |
| Contract Size | 100 oz |
| Margin Mode | Hedging (preferred) or Netting |

### 2.3 Data Quality Checklist

Before running any test, verify:

- [ ] Tick data downloaded for full test period
- [ ] No gaps > 5 minutes during market hours (Mon 00:00 - Fri 23:59 UTC)
- [ ] Spread data included (not zero-spread synthetic)
- [ ] Data source: Broker server (not third-party)
- [ ] Swap rates loaded (affects overnight positions)
- [ ] Holiday/maintenance gaps documented
- [ ] Quality indicator in MT5 shows > 99%

---

## 3. TEST MATRIX

### 3.1 Primary Test Periods

The test periods are designed to capture different market regimes gold has experienced.

| Period | Dates | Duration | XAUUSD Character | Purpose |
|--------|-------|----------|-------------------|---------|
| **COVID Crash** | 2020.01.01 - 2020.12.31 | 12 months | Extreme volatility, V-recovery, ATH | Stress test |
| **Consolidation** | 2021.01.01 - 2021.12.31 | 12 months | Range-bound 1700-1900, choppy | Mean reversion validation |
| **Rate Hike** | 2022.01.01 - 2022.12.31 | 12 months | Strong downtrend, then reversal | Trend following validation |
| **Recovery** | 2023.01.01 - 2023.12.31 | 12 months | Gradual uptrend, new ATH attempts | Balanced market test |
| **Bull Run** | 2024.01.01 - 2024.12.31 | 12 months | Strong bull, ATH breakouts | Breakout/trend validation |
| **Recent** | 2025.01.01 - 2025.12.31 | 12 months | Most recent data | Near-OOS validation |
| **Full Span** | 2020.01.01 - 2025.12.31 | 6 years | All regimes combined | Aggregate robustness |

### 3.2 In-Sample / Out-of-Sample Split

```
FULL DATA: 2020.01.01 - 2025.12.31 (6 years)

┌──────────────────────────────────────────────────────────────┐
│  IN-SAMPLE (70%)          │  OUT-OF-SAMPLE (30%)            │
│  2020.01 - 2024.03        │  2024.04 - 2025.12             │
│  (4 years 3 months)       │  (1 year 9 months)              │
│  Training & Optimization  │  Validation ONLY                │
└──────────────────────────────────────────────────────────────┘

WALK-FORWARD WINDOWS (rolling 6-month validation):
Window 1: Train 2020.01-2022.06 → Test 2022.07-2022.12
Window 2: Train 2020.07-2023.06 → Test 2023.07-2023.12
Window 3: Train 2021.01-2023.06 → Test 2023.07-2024.06
Window 4: Train 2021.07-2024.06 → Test 2024.07-2024.12
Window 5: Train 2022.01-2024.06 → Test 2024.07-2025.06
Window 6: Train 2022.07-2025.06 → Test 2025.07-2025.12
```

### 3.3 Profile Test Matrix

Each profile must be tested across ALL primary periods:

| Test ID | Profile | Period | Quality | Strategies | Expected Trades |
|---------|---------|--------|---------|------------|----------------|
| T01 | Conservative | Full Span | 70 | 6/8 ON | 800-2000/yr |
| T02 | Balanced | Full Span | 60 | 7/8 ON | 2500-4000/yr |
| T03 | Aggressive | Full Span | 50 | 8/8 ON | 4000-6500/yr |
| T04 | Balanced | COVID 2020 | 60 | 7/8 ON | Stress test |
| T05 | Balanced | Consolidation 2021 | 60 | 7/8 ON | Range test |
| T06 | Balanced | Rate Hike 2022 | 60 | 7/8 ON | Trend test |
| T07 | Balanced | Recovery 2023 | 60 | 7/8 ON | Mixed test |
| T08 | Balanced | Bull Run 2024 | 60 | 7/8 ON | Breakout test |
| T09 | Balanced | Recent 2025 | 60 | 7/8 ON | Near-OOS |
| T10 | Scalp Only | Full Span | 50 | MomentumScalp only | Edge isolation |
| T11 | No Grid | Full Span | 60 | 7/8 (no grid) | Safety check |
| T12 | Grid Impact | Full Span | 60 | 8/8 (with grid) | Grid risk assessment |

---

## 4. METRICS FRAMEWORK

### 4.1 Profitability Metrics (Tier 1 - Required)

| Metric | Formula | Target (Balanced) | Minimum Acceptable |
|--------|---------|-------------------|--------------------|
| **Net Profit** | Gross Profit - Gross Loss | > $500/yr per 0.01 lot | > $0 (must be profitable) |
| **Profit Factor** | Gross Profit / Gross Loss | 2.2 - 2.8 | > 1.5 |
| **Win Rate** | Wins / Total Trades | 70% - 75% | > 60% |
| **Expected Payoff** | Net Profit / Total Trades | > $0.50 per trade | > $0.20 |
| **Avg Win / Avg Loss** | (Mean win $) / (Mean loss $) | > 0.8 | > 0.5 |
| **Risk:Reward Ratio** | Avg Win / Avg Loss (pips) | > 1.5 | > 1.0 |
| **Monthly Return** | Net Profit / Initial Deposit / Months | > 2% | > 0.5% |

### 4.2 Risk Metrics (Tier 1 - Required)

| Metric | Formula | Target | Maximum Allowed |
|--------|---------|--------|-----------------|
| **Max Drawdown $** | Largest peak-to-trough decline | < $800 | < $1,200 |
| **Max Drawdown %** | Max DD $ / Peak Equity | < 8% | < 12% |
| **Recovery Factor** | Net Profit / Max DD | > 5.0 | > 2.0 |
| **Sharpe Ratio** | (Avg Return - Rf) / StdDev | > 1.5 | > 0.8 |
| **Sortino Ratio** | (Avg Return - Rf) / Downside Dev | > 2.0 | > 1.0 |
| **Max Consecutive Losses** | Longest losing streak | < 5 | < 8 |
| **Max DD Duration** | Longest underwater period | < 20 days | < 45 days |
| **Calmar Ratio** | Annual Return / Max DD | > 3.0 | > 1.5 |

### 4.3 Execution Metrics (Tier 2 - Important)

| Metric | Formula | Target | Warning |
|--------|---------|--------|---------|
| **Total Trades** | Count of all trades | 2500-4000/yr | < 500 or > 8000 |
| **Avg Trade Duration** | Mean open-to-close time | < 15 min | > 60 min |
| **% Trades < 5 min** | Short trades / Total | > 50% | < 30% |
| **% Trades > 2 hrs** | Long trades / Total | < 5% | > 15% |
| **Avg Spread at Entry** | Mean spread when opening | < 20 pts | > 30 pts |
| **Slippage Impact** | (Expected - Actual) per trade | < 1 pip | > 3 pips |
| **Commission Ratio** | Total Commission / Gross Profit | < 15% | > 25% |

### 4.4 Time-Based Performance (Tier 2 - Important)

| Metric | Method | What to Look For |
|--------|--------|------------------|
| **Hourly Performance** | Group PnL by hour (WIT) | 22-23, 08-09 should be strongest |
| **Daily Performance** | Group PnL by day of week | Tuesday-Thursday typically best |
| **Monthly Performance** | % of profitable months | Target > 75% |
| **Quarterly Performance** | % of profitable quarters | Must be > 80% |
| **Regime Performance** | PnL per market regime | Should be profitable in at least 3/4 regimes |
| **Session Performance** | PnL per trading session | London/NY overlap should dominate |

### 4.5 Strategy-Level Metrics (Tier 3 - Diagnostic)

For each of the 8 strategies, track independently:

| Metric | Purpose |
|--------|---------|
| Signal count (total generated) | Is the strategy producing signals? |
| Signal acceptance rate | What % pass quality filter? |
| Win rate (when accepted) | Does the strategy have real edge? |
| Avg contribution to PnL | Net positive or dragging? |
| False signal rate | How often is it wrong? |
| Best/worst regime | Where does it shine/fail? |
| Correlation with other strategies | Redundant or complementary? |

---

## 5. ANALYSIS FRAMEWORK

### 5.1 Three-Pass Analysis Protocol

**Pass 1: Sanity Check (5 minutes)**

Before analyzing any number, answer these questions:
1. Total trades > 1000? (If not, statistically meaningless)
2. Is the equity curve smooth or jagged? (Jagged = unstable)
3. Are there any trades with suspicious profits? (Data error?)
4. Does Max DD occur once or repeatedly? (One-time vs systemic)
5. Is commission accounted for? (Fantasy if not)

**Pass 2: Core Analysis (30 minutes)**

Evaluate in this exact order:
1. **Risk first** - Max DD, recovery factor, consecutive losses
2. **Consistency second** - Monthly returns, % profitable months
3. **Profitability third** - PF, win rate, expected payoff
4. **Efficiency fourth** - Trade count, duration, commission ratio

> **Why risk first?** A strategy that returns 100% but has 40% DD will blow up in live trading. Risk determines if you survive long enough for the edge to play out.

**Pass 3: Deep Diagnostic (1-2 hours)**

1. Equity curve shape analysis (see 5.2)
2. Time-based breakdown (hourly, daily, monthly)
3. Strategy contribution analysis
4. Drawdown event decomposition
5. Regime-conditional performance
6. Parameter sensitivity (see Section 9)

### 5.2 Equity Curve Analysis

The equity curve tells you more than any single metric.

**Healthy Patterns:**
```
Good: Steady upward slope with small, regular pullbacks
  ╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲  (choppy but upward)
       ╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱   (smooth upward = suspicious, check for overfitting)
```

**Unhealthy Patterns:**
```
Bad: Flat periods followed by spikes (regime-dependent)
  ─────╱╲──────╱╲────────

Bad: Staircase with cliff (grid/martingale blowup risk)  
  ╱╱╱╱╱│
       │╱╱╱╱╱│
              │

Bad: Only profitable in one segment (overfitted to that regime)
  ────╲╲╲╲╱╱╱╱╱╱╱╲╲╲────
```

**What to measure:**
- R-squared of linear regression on equity curve (target > 0.85)
- Standard deviation of monthly returns (lower is better)
- Longest flat period (if > 60 days, the strategy may be dead in those conditions)

### 5.3 Drawdown Decomposition

For every drawdown > 3%, document:

| Field | Content |
|-------|---------|
| DD Start Date | When the peak occurred |
| DD Bottom Date | When the trough was hit |
| DD Recovery Date | When peak was surpassed again |
| DD Depth (%) | Max drawdown percentage |
| DD Duration (days) | Peak to recovery |
| Market Regime | What was the market doing? |
| Trigger | What caused the loss streak? |
| Trades in DD | How many trades during this period? |
| Strategy Breakdown | Which strategies were losing? |
| Circuit Breaker Fired? | Did risk management help? |

### 5.4 Interpreting Results by Profile

#### Conservative Profile (Quality 70)
```
PASS if:
  WR > 68% AND PF > 1.8 AND Max DD < 10% AND Recovery Factor > 4
  AND > 75% months profitable AND no DD > 30 days

MARGINAL if:
  WR 60-68% OR PF 1.5-1.8 OR Max DD 10-12%

FAIL if:
  WR < 60% OR PF < 1.5 OR Max DD > 12% OR < 50% months profitable
```

#### Balanced Profile (Quality 60)
```
PASS if:
  WR > 65% AND PF > 2.0 AND Max DD < 12% AND Recovery Factor > 5
  AND > 70% months profitable AND trade count 2500-4000/yr

MARGINAL if:
  WR 58-65% OR PF 1.5-2.0 OR Max DD 12-15%

FAIL if:
  WR < 58% OR PF < 1.5 OR Max DD > 15% OR < 50% months profitable
```

#### Aggressive Profile (Quality 50)
```
PASS if:
  WR > 62% AND PF > 1.8 AND Max DD < 15% AND Recovery Factor > 3
  AND > 65% months profitable AND trade count 4000-6500/yr

MARGINAL if:
  WR 55-62% OR PF 1.3-1.8 OR Max DD 15-20%

FAIL if:
  WR < 55% OR PF < 1.3 OR Max DD > 20% OR < 40% months profitable
```

---

## 6. BENCHMARK COMPARISONS

### 6.1 Benchmark 1: Quantum Queen (Live Data Reference)

Source: 1,371 analyzed live trades from Quantum Queen MT5.

| Metric | QQ Actual | Aurum Target | Interpretation |
|--------|-----------|-------------|----------------|
| Win Rate | 78.7% | 70-75% | Aurum is safer (no 6-level grid) |
| Profit Factor | 3.87 | 2.2-2.8 | QQ inflated by grid recovery |
| Max DD | ~8-10% | < 12% | Comparable but Aurum safer grid |
| Avg Duration | 5-10 min | < 15 min | Both scalping-focused |
| Best Session | 22-23 WIT | 22-23 WIT | Aligned |
| Grid Levels | Up to 6 | Max 3 | Aurum significantly safer |
| Trades/Day | ~8-12 | 10-15 | Comparable |

**How to compare:**
- If Aurum WR > 70% and PF > 2.0 → **competitive**
- If Aurum WR > 65% with Max DD < 8% → **safer and acceptable**
- If Aurum WR < 60% → **investigate, likely execution or logic issue**

**What QQ inflates that Aurum shouldn't:**
- Grid recovery makes WR artificially high (winning 1 trade out of 6 grid levels still counts as 6 wins)
- Aurum's max 3 grid levels means lower WR but much lower tail risk

### 6.2 Benchmark 2: Buy & Hold Gold

Simple test: buy 0.01 lot XAUUSD on day 1, hold for entire test period.

| Period | Gold Performance | Aurum Must Beat |
|--------|-----------------|-----------------|
| 2020 | +25% ($1,517 → $1,898) | Must be > +25% annually |
| 2021 | -3.6% ($1,898 → $1,829) | Must be profitable |
| 2022 | +0.4% ($1,829 → $1,836) | Must be > +5% |
| 2023 | +13.1% ($1,836 → $2,077) | Must be > +13% |
| 2024 | +27.2% ($2,077 → $2,642) | Must be > +27% |
| Avg/yr | ~12.4% | Target > 25% annually |

> **Rule:** If Aurum cannot beat buy-and-hold gold by at least 2x on an annualized basis (risk-adjusted), the complexity of the EA is not justified.

### 6.3 Benchmark 3: Simple EMA Crossover

Create a baseline EA using:
- EMA(20) crosses above EMA(50) → BUY
- EMA(20) crosses below EMA(50) → SELL
- Fixed SL: 100 points, TP: 200 points
- No quality filter, no consensus, no risk management

This establishes the "intelligence premium" of Aurum Synapse.

| Metric | Simple EMA | Aurum Must Achieve |
|--------|-----------|-------------------|
| Win Rate | ~45-55% | +15-20% higher |
| Profit Factor | ~1.0-1.3 | +1.0 higher minimum |
| Max DD | ~20-30% | Half or less |
| Sharpe | ~0.3-0.5 | 3x higher minimum |

### 6.4 Benchmark 4: Random Entry

Generate random BUY/SELL signals with the same frequency as Aurum. Apply the same SL/TP/trailing logic.

**Purpose:** Prove that Aurum's edge comes from signal quality, not trade management alone.

**Expected:** Random entry should produce PF near 1.0 (break-even minus commission). If Aurum PF is only marginally better than random, the signal generation has no edge.

---

## 7. STATISTICAL VALIDATION

### 7.1 Minimum Trade Count

Statistical significance requires sufficient sample size.

| Confidence Level | Required Trades | Application |
|-----------------|-----------------|-------------|
| Low (exploratory) | > 200 | Single-year tests |
| Medium (indicative) | > 500 | Annual performance |
| High (reliable) | > 1,000 | Multi-year validation |
| Publication-grade | > 2,000 | Final system validation |

**Formula for minimum trades at 95% confidence:**

```
N = (Z² × p × (1-p)) / E²

Where:
  Z = 1.96 (95% confidence)
  p = observed win rate (e.g., 0.70)
  E = margin of error (e.g., 0.03 = ±3%)

N = (1.96² × 0.70 × 0.30) / 0.03²
N = (3.84 × 0.21) / 0.0009
N = 896 trades minimum
```

> **Rule:** Never make any decision based on fewer than 200 trades. Any test with fewer than 500 trades is exploratory only.

### 7.2 Confidence Intervals

For each key metric, calculate the 95% confidence interval:

**Win Rate CI:**
```
CI = p ± Z × sqrt(p(1-p)/n)

Example: WR=70%, n=2000
CI = 0.70 ± 1.96 × sqrt(0.70×0.30/2000)
CI = 0.70 ± 0.020
CI = [68.0%, 72.0%]
```

**Profit Factor CI (bootstrap method):**
1. Resample trades with replacement (10,000 iterations)
2. Calculate PF for each resample
3. Take 2.5th and 97.5th percentiles

### 7.3 t-Test for Performance

Test whether the mean trade profit is significantly different from zero:

```
t = (mean_profit - 0) / (stdev / sqrt(n))

If t > 1.96 (at 95% confidence) → Strategy has statistically significant edge
If t < 1.96 → Cannot reject null hypothesis (no proven edge)
```

### 7.4 Walk-Forward Efficiency (WFE)

The single most important robustness metric:

```
WFE = (OOS Annual Return) / (IS Annual Return) × 100%

Interpretation:
  WFE > 60%  → Robust (excellent)
  WFE 40-60% → Acceptable (good)
  WFE 20-40% → Weak (likely some overfitting)
  WFE < 20%  → Failed (severe overfitting)
```

Run this for each walk-forward window and average. If average WFE < 40%, the system is overfit.

### 7.5 Monte Carlo Simulation

Simulate 10,000 possible equity curve paths by randomly reordering the actual trade sequence.

**Report:**
- 5th percentile Max DD (worst-case realistic DD)
- 95th percentile Final Equity (best-case)
- Probability of drawdown > 15%
- Probability of ruin (equity reaching $0 or < 50% of initial)

**Pass criteria:**
- P(DD > 20%) < 5%
- P(ruin) < 1%
- Median final equity > 1.5× initial deposit per year

---

## 8. RED FLAGS & KILL CRITERIA

### 8.1 Immediate Kill (Stop Testing, Fix Code)

| Red Flag | Symptom | Likely Cause |
|----------|---------|-------------|
| Zero trades | No trades generated in 6+ months | Signal/filter logic broken |
| Negative PF < 0.8 | Consistent heavy losses | Strategy logic inverted or broken |
| Max DD > 30% | Single catastrophic loss event | Risk management not functioning |
| Avg trade > 4 hours | Positions held too long | Time exit guard not working |
| 100% win rate | Every trade is a winner | Grid/averaging masking losses, or data error |
| Trades only on 1 day | All trades cluster on one date | Data quality issue |

### 8.2 Serious Concerns (Investigate Before Proceeding)

| Red Flag | Symptom | Investigation |
|----------|---------|---------------|
| PF drops > 40% in OOS | 3.0 IS → 1.7 OOS | Overfitting - widen parameters |
| Single strategy dominates > 60% PnL | One strategy carries the team | Test without it - is the rest viable? |
| Monthly returns have negative skew | Few big months, many small losers | Strategy may be picking up pennies in front of a steamroller |
| Commission > 20% of gross profit | Overtrading | Increase quality threshold |
| Spread-sensitive | Results change > 30% with +5pt spread | Edge is too thin for live trading |
| Weekend gap sensitivity | Large losses on Monday opens | Add pre-weekend close logic |

### 8.3 Yellow Warnings (Monitor Closely)

| Warning | Symptom | Action |
|---------|---------|--------|
| WR declining over time | 75% in 2020 → 65% in 2025 | Market may be changing - check regime breakdown |
| Best month > 3× average month | One outlier inflating results | Remove best month and recheck PF |
| Recovery factor < 3 | Slow recovery from drawdowns | Increase quality threshold or reduce exposure |
| Consecutive losses > 6 | Strategy correlation issue | Ensure strategies are sufficiently independent |
| > 40% of trades on one session | Session dependency | Test with that session removed |

---

## 9. OPTIMIZATION PROTOCOL

### 9.1 What to Optimize (and What NOT to)

**Safe to Optimize (robust parameters):**
- Quality score threshold (50, 55, 60, 65, 70) - step 5
- SL distance (80, 100, 120, 150 points) - step 20
- TP coefficient (1.5, 2.0, 2.5, 3.0) - step 0.5
- Trailing start (5, 10, 15, 20 pips) - step 5
- Max positions (3, 4, 5) - step 1

**Dangerous to Optimize (overfitting risk):**
- Strategy weights (too many combinations)
- Indicator periods (e.g., RSI period 12 vs 14 vs 16)
- Exact hour filters (fitting to historical patterns)
- Any parameter with > 100 combinations

**Never Optimize:**
- Magic number
- Commission settings
- Risk management limits (these are safety nets, not profit drivers)

### 9.2 Optimization Methodology

**Step 1: Coarse Grid (In-Sample)**
- Use wide parameter steps
- Total combinations < 500
- Identify "profit plateau" regions (not peaks)
- Use genetic algorithm for > 500 combinations

**Step 2: Robustness Check**
- For each top-10 parameter set, test ±1 step in each direction
- If changing one parameter by one step drops PF > 30%, the set is fragile
- Select the parameter set in the CENTER of the profitable region

**Step 3: Out-of-Sample Validation**
- Run the selected set on OOS data (never seen before)
- Calculate Walk-Forward Efficiency (WFE)
- Only proceed if WFE > 40%

**Step 4: Multi-Year Confirmation**
- Run the final set on each individual year
- Must be profitable in at least 5 of 6 years
- No single year with DD > 15%

### 9.3 Optimization Output Format

Save results in `Tests/OptimizationResults/` with naming convention:

```
OPT_[profile]_[daterange]_[timestamp].xml   (MT5 optimization report)
OPT_[profile]_[daterange]_[timestamp].csv   (parameter-metric table)
```

---

## 10. FORWARD TEST PROTOCOL

### 10.1 Demo Forward Test (Minimum 2 Weeks)

After backtesting passes all criteria, forward test on demo:

| Parameter | Requirement |
|-----------|-------------|
| Duration | Minimum 14 calendar days (10 trading days) |
| Account | Demo with realistic conditions |
| Settings | Exact same as best backtest configuration |
| Monitoring | Daily equity snapshot at same time |
| Comparison | Track live metrics vs backtest expectations |

### 10.2 Forward Test Pass Criteria

| Metric | Backtest Baseline | Forward Tolerance |
|--------|------------------|-------------------|
| Win Rate | Backtest WR | Within -5% |
| Profit Factor | Backtest PF | Within -20% |
| Avg Trade | Backtest avg | Within -30% |
| Max DD | Backtest DD | Within +50% (higher DD acceptable) |
| Trade Frequency | Backtest count/day | Within ±40% |

> **Why wider tolerance?** Live execution has slippage, wider spreads, and different liquidity than backtests. Some degradation is expected and healthy.

### 10.3 Forward Test Kill Criteria

Stop the forward test immediately if:
1. Drawdown exceeds 1.5× the backtest maximum
2. Win rate drops below 50% after 50+ trades
3. Three consecutive days of losses > 2% each
4. Any single trade loss > 5% of equity

### 10.4 Live Deployment Graduation

Graduate from demo to live only when ALL conditions are met:

- [ ] Forward test duration > 2 weeks
- [ ] Forward WR within tolerance of backtest
- [ ] Forward PF within tolerance of backtest
- [ ] No kill criteria triggered
- [ ] At least 100 forward trades completed
- [ ] Operator has reviewed all metrics
- [ ] Starting live capital confirmed
- [ ] Risk parameters confirmed for live account

---

## 11. DECISION FRAMEWORK

### 11.1 Test Result Classification

After completing the full test matrix, classify the result:

```
                    ┌─────────────────────────────────┐
                    │       RUN ALL BACKTESTS          │
                    │    (12 test configurations)      │
                    └───────────────┬─────────────────┘
                                    │
                    ┌───────────────▼─────────────────┐
                    │     PASS SANITY CHECK?           │
                    │  (>1000 trades, no data errors)  │
                    └──┬───────────────────────────┬──┘
                     NO│                           │YES
                    ┌──▼──┐                ┌───────▼───────┐
                    │STOP │                │ CORE METRICS   │
                    │Fix  │                │ PASS?          │
                    │Code │                │ (PF>1.5,DD<15%)│
                    └─────┘                └──┬─────────┬──┘
                                            NO│         │YES
                                   ┌──────────▼──┐  ┌──▼──────────────┐
                                   │ INVESTIGATE  │  │ STATISTICAL     │
                                   │ Which metric │  │ VALIDATION      │
                                   │ fails? Why?  │  │ (CI, t-test,    │
                                   └──────────────┘  │  WFE, Monte     │
                                                     │  Carlo)          │
                                                     └──┬─────────┬──┘
                                                       NO│         │YES
                                              ┌─────────▼──┐  ┌──▼───────────┐
                                              │ PARAMETER   │  │ BENCHMARK    │
                                              │ SENSITIVITY │  │ COMPARISON   │
                                              │ Too fragile │  │ (vs QQ, B&H, │
                                              └─────────────┘  │  EMA, random) │
                                                               └──┬──────┬───┘
                                                                NO│      │YES
                                                       ┌─────────▼┐  ┌─▼──────────┐
                                                       │ RETHINK   │  │ FORWARD    │
                                                       │ STRATEGY  │  │ TEST       │
                                                       │ SELECTION │  │ (2+ weeks) │
                                                       └──────────┘  └──┬─────┬──┘
                                                                       NO│     │YES
                                                              ┌────────▼┐ ┌─▼────────┐
                                                              │ROLLBACK│ │ DEPLOY   │
                                                              │Diagnose│ │ LIVE     │
                                                              └────────┘ │ (small)  │
                                                                         └──────────┘
```

### 11.2 Final Go/No-Go Checklist

Before deploying to live trading, every box must be checked:

**Backtest Validation:**
- [ ] Full-span test PASS (PF > 1.5, WR > 60%, DD < 15%)
- [ ] At least 5/6 individual years profitable
- [ ] OOS performance within 60% of IS performance (WFE > 40%)
- [ ] Monte Carlo: P(DD>20%) < 5%, P(ruin) < 1%
- [ ] Beats buy-and-hold by > 2x (risk-adjusted)
- [ ] Beats simple EMA baseline by > 50% (Sharpe)
- [ ] Beats random entry by > 100% (PF)

**Robustness:**
- [ ] Parameter sensitivity: no single parameter change breaks profitability
- [ ] Profitable in at least 3/4 market regimes
- [ ] No single strategy contributes > 50% of total PnL
- [ ] Commission sensitivity: still profitable at 1.5× commission

**Forward Test:**
- [ ] Demo test > 2 weeks completed
- [ ] Forward metrics within tolerance of backtest
- [ ] > 100 live trades executed
- [ ] No kill criteria triggered

**Operational:**
- [ ] VPS or dedicated machine configured
- [ ] Broker account verified (ECN/STP)
- [ ] Spread < 30 points during test
- [ ] Starting capital matches tested deposit
- [ ] Emergency procedures documented

---

## APPENDIX A: GLOSSARY

| Term | Definition |
|------|-----------|
| IS | In-Sample: data used for training/optimization |
| OOS | Out-of-Sample: data reserved for validation only |
| WFE | Walk-Forward Efficiency: OOS return / IS return |
| PF | Profit Factor: gross profit / gross loss |
| WR | Win Rate: winning trades / total trades |
| DD | Drawdown: peak-to-trough equity decline |
| RF | Recovery Factor: net profit / max drawdown |
| RRR | Risk-Reward Ratio: avg win / avg loss |
| CI | Confidence Interval: statistical range of a metric |
| ECN | Electronic Communication Network broker |
| STP | Straight Through Processing broker |
| ATH | All-Time High |
| BOS | Break of Structure |
| WIT | Western Indonesian Time (UTC+7) |

## APPENDIX B: MT5 STRATEGY TESTER SETTINGS QUICK REFERENCE

```
Expert:          AurumSynapse
Symbol:          XAUUSD
Period:          M1
Date From:       [per test matrix]
Date To:         [per test matrix]
Forward:         No (we do our own OOS)
Delays:          No delay (backtest) / Current (forward)
Modeling:        Every tick based on real ticks
Profit:          In USD
Deposit:         10000.00 USD
Leverage:        1:500
Optimization:    Disabled (for single runs) / Slow complete (for optimization)
```

## APPENDIX C: FILE NAMING CONVENTIONS

```
Tests/
├── BacktestScripts/
│   ├── BacktestConfig.set              (MT5 tester presets)
│   └── BacktestMethodology.md          (this document)
│
├── PerformanceReports/
│   ├── RPT_balanced_2020-2025_full.html     (MT5 full report)
│   ├── RPT_conservative_2020-2025_full.html
│   ├── RPT_aggressive_2020-2025_full.html
│   ├── RPT_balanced_2020_annual.html
│   ├── RPT_balanced_2021_annual.html
│   ├── RPT_balanced_2022_annual.html
│   ├── RPT_balanced_2023_annual.html
│   ├── RPT_balanced_2024_annual.html
│   ├── RPT_balanced_2025_annual.html
│   ├── ANALYSIS_[date]_[profile].md         (analysis notes)
│   └── COMPARISON_[date].md                 (benchmark comparison)
│
└── OptimizationResults/
    ├── OPT_quality_threshold_2020-2024.xml  (MT5 optimization)
    ├── OPT_sltp_params_2020-2024.xml
    └── OPT_summary_[date].md                (optimization notes)
```

---

**Document Version:** 1.0  
**Author:** Aurum Synapse Architecture Team  
**Status:** Ready for Implementation  
**Next Step:** Create PerformanceAnalyzer.mq5 for automated metrics collection
