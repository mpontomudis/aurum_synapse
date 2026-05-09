# AURUM SYNAPSE - BACKTEST REPORT TEMPLATE

**Report ID:** RPT-[PROFILE]-[PERIOD]-[DATE]  
**EA Version:** v2.00  
**Generated:** [DATE]  
**Analyst:** [NAME]

---

## 1. TEST CONFIGURATION

| Parameter | Value |
|-----------|-------|
| Symbol | XAUUSD |
| Timeframe | M1 |
| Period | [START] - [END] |
| Model | Every tick based on real ticks |
| Initial Deposit | $10,000 |
| Leverage | 1:500 |
| Commission | $7.00/lot RT |
| Profile | [Conservative/Balanced/Aggressive] |
| Quality Score Threshold | [50/60/70] |
| Strategies Enabled | [list of ON strategies] |
| Lot Method | [Fixed/Auto/Per Balance] |
| Lot Size / Risk % | [value] |

---

## 2. EXECUTIVE SUMMARY

### Verdict: [PASS / MARGINAL / FAIL]

| Metric | Result | Target | Status |
|--------|--------|--------|--------|
| Net Profit | $ | > $500/yr | [✅/❌] |
| Win Rate | % | > 65% | [✅/❌] |
| Profit Factor | | > 2.0 | [✅/❌] |
| Max Drawdown % | % | < 12% | [✅/❌] |
| Recovery Factor | | > 5.0 | [✅/❌] |
| Sharpe Ratio | | > 1.5 | [✅/❌] |
| Statistical Significance | t= | > 1.96 | [✅/❌] |
| Profitable Months | % | > 70% | [✅/❌] |

### One-Line Summary:  
> [e.g., "Balanced profile achieves 71.2% WR and 2.34 PF over 6 years with 9.1% max DD, beating all benchmarks."]

---

## 3. CORE METRICS

### 3.1 Profitability

| Metric | Value |
|--------|-------|
| Total Trades | |
| Wins / Losses | / |
| Win Rate | % |
| Net Profit | $ |
| Gross Profit | $ |
| Gross Loss | $ |
| Profit Factor | |
| Expected Payoff | $ |
| Avg Win | $ |
| Avg Loss | $ |
| Risk:Reward Ratio | |
| Max Single Win | $ |
| Max Single Loss | $ |
| Total Commission | $ |
| Commission % of Gross | % |

### 3.2 Risk

| Metric | Value |
|--------|-------|
| Max Drawdown $ | $ |
| Max Drawdown % | % |
| Max DD Duration | trades |
| Recovery Factor | |
| Sharpe Ratio | |
| Sortino Ratio | |
| Max Consecutive Wins | |
| Max Consecutive Losses | |
| Calmar Ratio | |

### 3.3 Trade Execution

| Metric | Value |
|--------|-------|
| Avg Trade Duration | min |
| % Trades < 5 min | % |
| % Trades > 2 hours | % |
| Trades per Day (avg) | |
| Avg Spread at Entry | pts |

---

## 4. EQUITY CURVE

[Paste MT5 equity curve screenshot here]

### Equity Curve Assessment:
- **Shape:** [Steady upward / Staircase / Flat periods / Volatile]
- **R-squared:** [value] (target > 0.85)
- **Longest flat period:** [days]
- **Major drawdown events:** [count]

---

## 5. TIME-BASED ANALYSIS

### 5.1 Hourly Performance (Top 5 Hours)

| Hour (WIT) | Trades | WR% | PnL | Notes |
|------------|--------|-----|-----|-------|
| | | | | |
| | | | | |
| | | | | |
| | | | | |
| | | | | |

**Golden Hour Validation:**
- 22-23 WIT Performance: [WR%, PnL]
- 08-09 WIT Performance: [WR%, PnL]
- Are golden hours the best? [YES/NO]

### 5.2 Daily Performance

| Day | Trades | WR% | PnL |
|-----|--------|-----|-----|
| Monday | | | |
| Tuesday | | | |
| Wednesday | | | |
| Thursday | | | |
| Friday | | | |

### 5.3 Monthly Summary

| Month | Trades | WR% | PnL | Status |
|-------|--------|-----|-----|--------|
| Jan | | | | [✅/❌] |
| Feb | | | | [✅/❌] |
| Mar | | | | [✅/❌] |
| Apr | | | | [✅/❌] |
| May | | | | [✅/❌] |
| Jun | | | | [✅/❌] |
| Jul | | | | [✅/❌] |
| Aug | | | | [✅/❌] |
| Sep | | | | [✅/❌] |
| Oct | | | | [✅/❌] |
| Nov | | | | [✅/❌] |
| Dec | | | | [✅/❌] |

**Profitable Months:** [X]/12 ([Y]%)

---

## 6. DURATION ANALYSIS

| Duration | Trades | WR% | PnL | Assessment |
|----------|--------|-----|-----|------------|
| < 1 min | | | | |
| 1-5 min | | | | ⭐ TARGET |
| 5-15 min | | | | |
| 15-30 min | | | | |
| 30-60 min | | | | |
| 1-2 hours | | | | ⚠ WARNING |
| > 2 hours | | | | ❌ DANGER |

**Scalping Ratio (< 5 min):** [X]% (QQ benchmark: 77%)  
**Danger Trades (> 2 hrs):** [X]% (must be < 5%)

---

## 7. BENCHMARK COMPARISON

| Metric | Aurum Result | QQ Actual | Buy & Hold | Simple EMA | Random |
|--------|-------------|-----------|-----------|-----------|--------|
| Win Rate | | 78.7% | N/A | ~50% | ~50% |
| Profit Factor | | 3.87 | N/A | ~1.1 | ~0.95 |
| Max DD % | | ~9% | ~15-25% | ~25% | ~30% |
| Sharpe | | ~1.5 | ~0.5 | ~0.3 | ~0.1 |
| Annual Return | | ~40% | ~12% | ~5% | ~-5% |

**Intelligence Premium:**
- Aurum PF / Random PF = [X]× better → Signal quality confirmed [YES/NO]
- Aurum Sharpe / EMA Sharpe = [X]× better → Consensus adds value [YES/NO]
- Aurum DD < QQ DD? → Risk management improvement [YES/NO]

---

## 8. DRAWDOWN EVENTS

### Major Drawdowns (> 3%)

| # | Start Date | Bottom Date | Recovery Date | Depth % | Duration (days) | Regime | Trigger |
|---|-----------|-------------|---------------|---------|-----------------|--------|---------|
| 1 | | | | | | | |
| 2 | | | | | | | |
| 3 | | | | | | | |

### Circuit Breaker Events:
- Daily loss triggered: [count] times
- Equity DD triggered: [count] times
- Consecutive loss triggered: [count] times

---

## 9. STATISTICAL VALIDATION

| Test | Result | Pass Criteria | Status |
|------|--------|---------------|--------|
| t-statistic | | > 1.96 | [✅/❌] |
| Win Rate 95% CI | [low% - high%] | Does not include 50% | [✅/❌] |
| Walk-Forward Efficiency | % | > 40% | [✅/❌] |
| Monte Carlo P(DD>20%) | % | < 5% | [✅/❌] |
| Monte Carlo P(ruin) | % | < 1% | [✅/❌] |

---

## 10. RED FLAGS CHECK

| Check | Status | Notes |
|-------|--------|-------|
| Any single strategy > 50% of PnL? | [YES/NO] | |
| Commission > 20% of gross profit? | [YES/NO] | |
| > 10% trades longer than 2 hours? | [YES/NO] | |
| Monthly returns have negative skew? | [YES/NO] | |
| Best month > 3× average month? | [YES/NO] | |
| Win rate declining over time? | [YES/NO] | |
| Spread-sensitive (±5pt changes >30%)? | [YES/NO] | |
| Only profitable in 1-2 regimes? | [YES/NO] | |

---

## 11. ANNUAL BREAKDOWN

| Year | Trades | WR% | PF | Net Profit | Max DD% | Sharpe | Status |
|------|--------|-----|----|-----------:|---------|--------|--------|
| 2020 | | | | | | | [✅/❌] |
| 2021 | | | | | | | [✅/❌] |
| 2022 | | | | | | | [✅/❌] |
| 2023 | | | | | | | [✅/❌] |
| 2024 | | | | | | | [✅/❌] |
| 2025 | | | | | | | [✅/❌] |

**Profitable Years:** [X]/6 (must be >= 5)

---

## 12. RECOMMENDATIONS

### Strengths Identified:
1. [e.g., "Strong golden hour performance matching QQ data"]
2. [e.g., "Consistent PF > 2.0 across all years"]
3. [e.g., "Max DD within target across all regimes"]

### Weaknesses Identified:
1. [e.g., "MeanReversion strategy underperforming in trending markets"]
2. [e.g., "Commission ratio higher than target"]
3. [e.g., "Duration creeping above 15 min average"]

### Parameter Adjustments Recommended:
1. [e.g., "Increase quality threshold from 60 to 65"]
2. [e.g., "Disable MeanReversion during strong trends"]
3. [e.g., "Tighten trailing stop to 4 pips"]

### Next Steps:
- [ ] [Action item 1]
- [ ] [Action item 2]
- [ ] [Action item 3]

---

## 13. FINAL VERDICT

```
╔══════════════════════════════════════════════════════╗
║                                                      ║
║   VERDICT:   [PASS / MARGINAL / FAIL]                ║
║                                                      ║
║   Ready for Forward Test:  [YES / NO / CONDITIONAL]  ║
║   Ready for Live Trading:  [YES / NO / NOT YET]      ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
```

**Conditions for Live Deployment (if CONDITIONAL):**
1. [condition]
2. [condition]

---

**Report Generated:** [DATE]  
**EA Version:** v2.00  
**Methodology:** See BacktestMethodology.md  
**Data Quality:** [99%+ / Acceptable / Poor]

---

*This report follows the Aurum Synapse Backtesting Methodology v1.0*  
*© 2026 Aurum Synapse - Institutional-Grade Gold Trading Engine*
