# AURUM SYNAPSE - CONFIGURATION PROFILES

**Version:** 1.0  
**Date:** 2026-05-06  
**Purpose:** Pre-configured settings for different risk profiles

---

## 📦 FILES CREATED

```
Tests/BacktestScripts/
├── Conservative.set    (Low risk, high quality)
├── Balanced.set       (Medium risk, standard quality) ⭐ RECOMMENDED
└── Aggressive.set     (High risk, lower quality)
```

---

## 🎯 PROFILE COMPARISON

| Setting | Conservative | Balanced | Aggressive |
|---------|-------------|----------|------------|
| **Risk per Trade** | 0.5% | 1.0% | 2.0% |
| **Quality Threshold** | 80/100 | 70/100 | 60/100 |
| **Strategies Active** | 6/8 | 7/8 | 8/8 |
| **Max Spread** | 25 pts | 30 pts | 35 pts |
| **Daily Loss Limit** | 2.5% | 5.0% | 7.0% |
| **Equity DD Limit** | 8.0% | 12.0% | 15.0% |
| **Max Positions** | 2 | 5 | 7 |
| **SL Distance** | 120 pts | 100 pts | 100 pts |
| **TP Coefficient** | 2.5× | 2.0× | 2.0× |
| **Trailing Start** | 15 pips | 10 pips | 8 pips |

---

## 1️⃣ CONSERVATIVE PROFILE

### Philosophy
"Quality over quantity. Capital preservation first."

### Strategy Selection
- ✅ TrendFollowing (strong trends only)
- ✅ Breakout (confirmed expansions)
- ❌ MeanReversion (too aggressive for conservative)
- ✅ SupplyDemand (high-probability zones)
- ✅ SmartMoney (institutional flow)
- ✅ PriceAction (confirmation patterns)
- ❌ GridRecovery (too risky)
- ✅ MomentumScalp (primary edge)

**Total: 6/8 strategies active**

### Risk Parameters
```
Risk per Trade:      0.5% (very conservative)
Daily Loss Limit:    2.5% (tight control)
Equity DD Limit:     8.0% (low tolerance)
Max Consecutive:     3 losses
Max Positions:       2 (focused)
```

### Quality Requirements
```
Minimum Score:       80/100 (EXCELLENT only)
Require Trend:       YES (must align with H4+H1)
Require Key Level:   YES (within 50 pips S/R)
Require Momentum:    YES (RSI+MACD confirm)
```

### TP/SL Settings
```
SL Distance:         120 points (wider safety)
TP Coefficient:      2.5× (higher RRR target)
Trailing Start:      15 pips profit
Trailing Distance:   7 pips
```

### Expected Performance
| Metric | Target |
|--------|--------|
| Trades/Year | 500-1,500 |
| Win Rate | 75-80% |
| Profit Factor | 2.5-3.5 |
| Max Drawdown | < 8% |
| Monthly Return | 1-2% |
| Sharpe Ratio | > 2.0 |

### Best For
- Small accounts ($500-$2,000)
- Risk-averse traders
- Beginners
- Capital preservation focus
- Demo-to-live transition

---

## 2️⃣ BALANCED PROFILE ⭐ RECOMMENDED

### Philosophy
"Optimal balance between profit and risk. Production default."

### Strategy Selection
- ✅ TrendFollowing
- ✅ Breakout
- ✅ MeanReversion (adds range-trading edge)
- ✅ SupplyDemand
- ✅ SmartMoney
- ✅ PriceAction
- ❌ GridRecovery (excluded for safety)
- ✅ MomentumScalp

**Total: 7/8 strategies active**

### Risk Parameters
```
Risk per Trade:      1.0% (standard)
Daily Loss Limit:    5.0% (reasonable)
Equity DD Limit:     12.0% (acceptable)
Max Consecutive:     3 losses
Max Positions:       5 (diversified)
```

### Quality Requirements
```
Minimum Score:       70/100 (GOOD+)
Require Trend:       NO (allows counter-trend)
Require Key Level:   NO (more opportunities)
Require Momentum:    NO (flexible entry)
```

### TP/SL Settings
```
SL Distance:         100 points (standard)
TP Coefficient:      2.0× (balanced RRR)
Trailing Start:      10 pips profit
Trailing Distance:   5 pips
```

### Expected Performance
| Metric | Target |
|--------|--------|
| Trades/Year | 2,500-4,000 |
| Win Rate | 70-75% |
| Profit Factor | 2.2-2.8 |
| Max Drawdown | < 12% |
| Monthly Return | 2-4% |
| Sharpe Ratio | > 1.5 |

### Best For
- Medium accounts ($2,000-$10,000)
- Experienced traders
- Long-term growth
- Standard risk tolerance
- Production deployment

---

## 3️⃣ AGGRESSIVE PROFILE ⚠️

### Philosophy
"Maximum frequency, higher risk. For experienced traders only."

### Strategy Selection
- ✅ TrendFollowing
- ✅ Breakout
- ✅ MeanReversion
- ✅ SupplyDemand
- ✅ SmartMoney
- ✅ PriceAction
- ✅ GridRecovery (RISKY - max 3 levels)
- ✅ MomentumScalp

**Total: 8/8 strategies active (including grid!)**

### Risk Parameters
```
Risk per Trade:      2.0% (aggressive)
Daily Loss Limit:    7.0% (high tolerance)
Equity DD Limit:     15.0% (higher risk)
Max Consecutive:     4 losses (more tolerance)
Max Positions:       7 (high exposure)
```

### Quality Requirements
```
Minimum Score:       60/100 (ACCEPTABLE+)
Require Trend:       NO
Require Key Level:   NO
Require Momentum:    NO (maximum flexibility)
```

### TP/SL Settings
```
SL Distance:         100 points
TP Coefficient:      2.0×
Trailing Start:      8 pips profit (tighter)
Trailing Distance:   4 pips (tighter)
```

### Expected Performance
| Metric | Target |
|--------|--------|
| Trades/Year | 4,000-6,500 |
| Win Rate | 68-72% |
| Profit Factor | 1.8-2.4 |
| Max Drawdown | < 15% |
| Monthly Return | 3-6% |
| Sharpe Ratio | > 1.2 |

### Best For
- Large accounts ($10,000+)
- Very experienced traders
- High risk tolerance
- Active monitoring capability
- Profit maximization focus

### ⚠️ WARNINGS
1. **GridRecovery is enabled** - Can lead to cascade losses
2. **Higher drawdown potential** - Prepare for 12-15% DD
3. **Requires monitoring** - Not fire-and-forget
4. **Commission sensitive** - High trade count increases costs
5. **Not for beginners** - Complexity requires experience

---

## 🔧 HOW TO USE

### Loading in Strategy Tester (Backtest)

```
1. Open MT5 Strategy Tester (Ctrl+R)
2. Select Expert: AurumSynapse
3. Click "Settings" button (next to Expert dropdown)
4. Click "Load" button
5. Navigate to: MQL5/Experts/AurumSynapse/Tests/BacktestScripts/
6. Select: Balanced.set (or Conservative.set / Aggressive.set)
7. Click "Open"
8. All 40 parameters are now configured
9. Click "Start" to run backtest
```

### Loading for Live Trading

```
1. Attach AurumSynapse to chart
2. In Properties window, click "Load Settings"
3. Navigate to: MQL5/Experts/AurumSynapse/Tests/BacktestScripts/
4. Select desired .set file
5. Click "Open"
6. Verify all settings in tabs
7. Click "OK" to start trading
```

### Switching Profiles

```
To change profile mid-trading:
1. Remove EA from chart
2. Re-attach EA
3. Load different .set file
4. Restart

⚠ Note: This will reset all internal state
       Consider closing positions first
```

---

## 📊 OPTIMIZATION RANGES

Each .set file includes optimization ranges in format:
```
ParameterName=Value||StartValue||Step||StopValue
```

Example:
```
InpMinQualityScore=70||60||5||80
```
Means:
- Default: 70
- Optimize from 60 to 80
- Step size: 5
- Range: 60, 65, 70, 75, 80

### Recommended Optimization Parameters

**Safe to optimize:**
- InpMinQualityScore (affects trade frequency)
- InpSLPoints (affects risk per trade)
- InpTPCoefficient (affects RRR)
- InpTrailStartPips (affects profit taking)
- InpMaxSpreadPoints (affects execution quality)

**Dangerous to optimize:**
- Strategy enable/disable (combinatorial explosion)
- Risk percentages (should be fixed based on risk tolerance)
- Magic number (not a performance parameter)

**Never optimize:**
- InpShowPanel (UI setting)
- InpPanelUpdateSeconds (UI setting)

---

## 🎯 PROFILE SELECTION GUIDE

### Choose CONSERVATIVE if:
- [ ] Account size < $2,000
- [ ] First time using Aurum Synapse
- [ ] Risk tolerance: Low
- [ ] Goal: Capital preservation
- [ ] Willing to accept lower returns for safety
- [ ] Want to test EA with minimal risk

### Choose BALANCED if: ⭐
- [ ] Account size $2,000-$10,000
- [ ] Experienced with EAs
- [ ] Risk tolerance: Medium
- [ ] Goal: Steady growth
- [ ] Comfortable with 10-12% DD
- [ ] Want default "production" settings

### Choose AGGRESSIVE if:
- [ ] Account size > $10,000
- [ ] Very experienced trader
- [ ] Risk tolerance: High
- [ ] Goal: Maximum profit
- [ ] Can tolerate 12-15% DD
- [ ] Have time to monitor daily
- [ ] Understand grid averaging risk

---

## 🧪 TESTING RECOMMENDATIONS

### Test Order:

1. **Start with Conservative** (2-4 weeks demo)
   - Learn EA behavior
   - Understand circuit breakers
   - Low-risk validation

2. **Move to Balanced** (2-4 weeks demo)
   - Standard production settings
   - Higher trade frequency
   - Realistic performance expectations

3. **Try Aggressive** (2-4 weeks demo, optional)
   - Only if Balanced is profitable
   - Monitor closely for DD events
   - Assess if increased risk is worth reward

### Never Skip:
- [ ] Demo test for at least 2 weeks per profile
- [ ] Backtest validation (see BacktestMethodology.md)
- [ ] Forward test before live
- [ ] Start with small lot size (0.01) on live

---

## 📈 EXPECTED TRADE COUNT

| Profile | Daily | Weekly | Monthly | Yearly |
|---------|-------|--------|---------|--------|
| Conservative | 2-4 | 10-20 | 40-120 | 500-1,500 |
| Balanced | 7-11 | 35-55 | 210-330 | 2,500-4,000 |
| Aggressive | 11-18 | 55-90 | 330-540 | 4,000-6,500 |

> If actual trade count deviates by >40% from expected, check:
> - Spread conditions (too wide = fewer trades)
> - Market volatility (too low = fewer trades)
> - Time filters (blocking trading hours?)
> - Quality threshold (too high = fewer trades)

---

## 🔄 UPGRADING BETWEEN PROFILES

### Conservative → Balanced
```
Safe transition. Expect:
- 2-3× more trades
- Slightly lower WR (-3-5%)
- Higher returns (+50-100%)
- Moderate DD increase (+2-4%)
```

### Balanced → Aggressive
```
Higher risk transition. Expect:
- 1.5-2× more trades
- Lower WR (-2-4%)
- Higher returns (+30-50%)
- Significant DD increase (+3-5%)
- Grid risk introduction
```

### Aggressive → Balanced (Downgrade)
```
Risk reduction. Expect:
- Fewer trades (-35-50%)
- Higher WR (+2-4%)
- Lower returns (-25-35%)
- Safer equity curve
- No grid risk
```

---

## ⚙️ CUSTOMIZATION TIPS

### To Make Profile More Conservative:
1. Increase InpMinQualityScore (+5-10)
2. Enable InpRequireTrendAlignment
3. Enable InpRequireKeyLevel
4. Reduce InpMaxOpenPositions
5. Decrease InpMaxDailyLossPct
6. Increase InpSLPoints (wider stop)

### To Make Profile More Aggressive:
1. Decrease InpMinQualityScore (-5-10)
2. Disable Require* filters
3. Increase InpMaxOpenPositions
4. Increase InpMaxDailyLossPct
5. Enable InpUseGridRecovery (if not already)
6. Reduce InpMaxSpreadPoints (accept more spreads)

### To Increase Trade Frequency:
1. Lower InpMinQualityScore
2. Disable Require* filters
3. Increase InpMaxSpreadPoints
4. Disable InpUseTimeFilter
5. Enable more strategies

### To Reduce Trade Frequency:
1. Raise InpMinQualityScore
2. Enable Require* filters
3. Decrease InpMaxSpreadPoints
4. Enable InpUseTimeFilter with golden hours only
5. Disable some strategies

---

## 📝 NOTES

1. **Panel Display**: All .set files have `InpShowPanel=0` for backtesting
   - Set to `1` for live trading to see dashboard
   
2. **Magic Number**: All profiles use 20260505
   - Change if running multiple instances
   
3. **Lot Method**: All profiles use Fixed (0) with 0.01 lot
   - For auto-sizing, change InpLotMethod to 1 (AUTO)
   - Set InpRiskPercent to desired % per trade
   
4. **Time Filters**: Disabled by default
   - Enable InpUseTimeFilter to restrict trading hours
   - Set InpHourFrom/To for golden hours (8-9, 22-23 WIT)
   
5. **Optimization**: Each parameter has optimization range
   - Use MT5 genetic algorithm for >100 combinations
   - Always validate on OOS data after optimization

---

## 🏁 QUICK START

**For first-time users:**

```
1. Load Balanced.set in Strategy Tester
2. Set period: 2024.01.01 - 2024.12.31
3. Run backtest
4. Check if PF > 2.0 and WR > 65%
5. If PASS → Demo test for 2 weeks
6. If PASS → Live with 0.01 lot
7. Scale up gradually
```

**For experienced users:**

```
1. Backtest all 3 profiles (2020-2025)
2. Compare risk-adjusted returns (Sharpe)
3. Select profile matching risk tolerance
4. Optimize key parameters (quality, SL/TP)
5. Validate on OOS data
6. Forward test 2+ weeks
7. Deploy to live
```

---

**Files Created:**
- Conservative.set (80pt quality, 0.5% risk, 6 strategies)
- Balanced.set (70pt quality, 1.0% risk, 7 strategies) ⭐
- Aggressive.set (60pt quality, 2.0% risk, 8 strategies)

**Status:** Ready to Load in MT5  
**Date:** 2026-05-06  
**Compatibility:** AurumSynapse v2.0

---

*© 2026 Aurum Synapse - Institutional-Grade Gold Trading Engine*
