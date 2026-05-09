# Aurum Synapse v2 — System Architecture

**Version:** 2.0  
**Date:** May 5, 2026  
**Status:** Pre-Development — Canonical Design Reference

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Component Interaction Diagram](#2-component-interaction-diagram)
3. [Data Flow: Tick to Trade Execution](#3-data-flow-tick-to-trade-execution)
4. [Strategy Pattern Implementation](#4-strategy-pattern-implementation)
5. [Performance Optimization Approach](#5-performance-optimization-approach)
6. [Error Handling Strategy](#6-error-handling-strategy)
7. [State Management Approach](#7-state-management-approach)
8. [File & Module Map](#8-file--module-map)
9. [Architectural Decisions Record](#9-architectural-decisions-record)
10. [Risk Register](#10-risk-register)

---

## 1. Executive Summary

Aurum Synapse is an institutional-grade gold (XAUUSD) Expert Advisor for MetaTrader 5 built around an **8-strategy weighted consensus engine** with adaptive regime memory. The system is designed as a layered pipeline: raw market ticks flow through signal generation, quality scoring, consensus arbitration, frequency gating, execution timing, and active trade management — each layer able to reject or defer a signal before capital is committed.

**Core design tenets:**

- **Pipeline of vetoes** — every layer can block a trade; no single layer can force one.
- **Weighted intelligence** — strategy votes carry unequal weight, tuned by live regime memory.
- **Time-aware scalping bias** — the architecture privileges sub-5-minute trades (94-96% WR edge from Quantum Queen data).
- **Fail-safe defaults** — on any ambiguity, the system does nothing; capital preservation trumps opportunity.

---

## 2. Component Interaction Diagram

### 2.1 High-Level Layer Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      AurumSynapse.mq5                           │
│                     (Main EA Entry Point)                       │
│         OnInit · OnTick · OnDeinit · OnTimer · OnTrade          │
└────────────────────────────┬────────────────────────────────────┘
                             │
          ┌──────────────────┼──────────────────────┐
          ▼                  ▼                       ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────────────────┐
│  MarketAnalyzer  │ │  InfoPanel   │ │     Logger / Telemetry   │
│  (Market State)  │ │  (UI / HUD)  │ │  (Diagnostics & Audit)   │
└────────┬─────────┘ └──────────────┘ └──────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────────┐
│                     StrategyManager                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐   │
│  │  Trend   │ │ Breakout │ │  Mean    │ │  Supply/Demand   │   │
│  │ Following│ │          │ │ Reversion│ │                  │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────────┘   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐   │
│  │  Smart   │ │  Price   │ │   Grid   │ │    Momentum      │   │
│  │  Money   │ │  Action  │ │ Recovery │ │    Scalping ⭐    │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────────┘   │
└────────────────────────────┬─────────────────────────────────────┘
                             │  SignalArray[8]
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                      SignalManager                               │
│              (Weighted Consensus + Quality Gate)                  │
│                                                                  │
│  ┌─────────────────┐  ┌───────────────────┐                     │
│  │  QualityFilter  │  │  ConsensusEngine  │                     │
│  │  (11 components │  │  (weighted vote + │                     │
│  │   / 100 pts)    │  │   5% margin)      │                     │
│  └─────────────────┘  └───────────────────┘                     │
└────────────────────────────┬─────────────────────────────────────┘
                             │  ConsensusSignal {BUY|SELL|NONE}
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                   FrequencyController                            │
│          (Daily/Hourly limits, gap, throttle, pause)             │
└────────────────────────────┬─────────────────────────────────────┘
                             │  Approved / Rejected
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                     ExecutionTimer                               │
│       (Spread, volatility, micro-pullback, volume checks)        │
└────────────────────────────┬─────────────────────────────────────┘
                             │  Optimal entry confirmed
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                      MoneyManager                                │
│        (Lot sizing, risk %, account equity checks)               │
└────────────────────────────┬─────────────────────────────────────┘
                             │  Lot size + TP/SL levels
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                      TradeManager                                │
│          (OrderSend, retry, slippage control, logging)           │
└────────────────────────────┬─────────────────────────────────────┘
                             │  Position opened
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                   TradeManagementAI                               │
│  (BE moves, partial close, TP extend, trailing, time tighten)    │
└────────────────────────────┬─────────────────────────────────────┘
                             │  Position closed / modified
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                      RiskManager                                 │
│  (DD protection, daily loss cap, consecutive-loss pause)         │
└────────────────────────────┬─────────────────────────────────────┘
                             │  Trade result
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                     RegimeMemory                                 │
│        (Per-regime × per-strategy stats, weight adaptation)      │
│        (File-persistent learning across restarts)                │
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Component Dependency Matrix

| Component            | Depends On                                       | Depended On By                          |
|----------------------|--------------------------------------------------|-----------------------------------------|
| MarketAnalyzer       | MT5 API (rates, tick)                            | All strategies, QualityFilter           |
| StrategyManager      | BaseStrategy (abstract), MarketAnalyzer          | SignalManager                           |
| SignalManager        | StrategyManager, QualityFilter, RegimeMemory     | FrequencyController                     |
| QualityFilter        | MarketAnalyzer, Constants                        | SignalManager                           |
| FrequencyController  | RiskManager, Constants                           | ExecutionTimer                          |
| ExecutionTimer       | MarketAnalyzer, Constants                        | MoneyManager                           |
| MoneyManager         | RiskManager, Constants                           | TradeManager                           |
| TradeManager         | MT5 Trade API                                    | TradeManagementAI                      |
| TradeManagementAI    | MarketAnalyzer, TradeManager                     | RiskManager (on close)                 |
| RiskManager          | Account state, Constants                         | FrequencyController, MoneyManager      |
| RegimeMemory         | File I/O, MarketAnalyzer                         | SignalManager (weight adaptation)      |
| Logger               | File I/O                                         | All components                         |
| InfoPanel            | All components (read-only)                       | None (pure display)                    |

---

## 3. Data Flow: Tick to Trade Execution

### 3.1 Primary Pipeline (OnTick)

```
 MARKET TICK
     │
     ▼
 ┌───────────────────────────────┐
 │ 1. MARKET STATE SNAPSHOT      │
 │    MarketAnalyzer.Update()    │
 │    ─ Regime detection         │  Cache: ~50ms validity
 │      (TRENDING/RANGING/       │  Throttle: skip if last
 │       VOLATILE/CALM)          │  full analysis < 1 sec
 │    ─ Structure (HH/HL/LL/LH) │
 │    ─ Key levels (S/R zones)   │
 │    ─ Session classification   │
 │    ─ ATR / spread / volume    │
 └───────────────┬───────────────┘
                 │ MarketState struct
                 ▼
 ┌───────────────────────────────┐
 │ 2. SIGNAL GENERATION          │
 │    StrategyManager            │
 │    .EvaluateAll(state)        │
 │    ─ Each of 8 strategies     │  Only strategies whose
 │      checks activation cond.  │  activation matches
 │    ─ Produces signal + str.   │  current regime run
 │    ─ Skips inactive regimes   │
 └───────────────┬───────────────┘
                 │ Signal[8] {direction, strength}
                 ▼
 ┌───────────────────────────────┐
 │ 3. QUALITY SCORING            │
 │    QualityFilter              │
 │    .Score(state, signals)     │
 │    ─ 11 components / 100 pts │  Threshold: 60 pts
 │    ─ Session quality (15 pts) │  (balanced mode)
 │    ─ Trend alignment (12 pts)│
 │    ─ Key level prox. (12 pts)│
 │    Gate: score < threshold    │
 │          → REJECT, return     │
 └───────────────┬───────────────┘
                 │ QualityScore + pass/fail
                 ▼
 ┌───────────────────────────────┐
 │ 4. CONSENSUS ENGINE           │
 │    SignalManager               │
 │    .GetConsensus(signals,     │
 │                  weights)     │
 │    ─ Weighted vote tally      │  Weights from
 │    ─ min voters = max(3,      │  RegimeMemory
 │      active×0.4)              │  (adaptive)
 │    ─ 5% margin filter         │
 │    Result: BUY / SELL / NONE  │
 └───────────────┬───────────────┘
                 │ ConsensusSignal
                 ▼
 ┌───────────────────────────────┐
 │ 5. FREQUENCY GATE             │
 │    FrequencyController        │
 │    .CanTakeNewTrade()         │
 │    ─ Daily: ≤25 trades        │  Hard limits;
 │    ─ Hourly: ≤5 trades        │  no override
 │    ─ Gap: ≥2 min since last   │
 │    ─ WR <50% → halve freq     │
 │    ─ Daily loss >$50 → pause  │
 │    ─ Dead-zone check          │
 │    FAIL → buffer signal,      │
 │            re-evaluate next    │
 └───────────────┬───────────────┘
                 │ Approved
                 ▼
 ┌───────────────────────────────┐
 │ 6. EXECUTION TIMING           │
 │    ExecutionTimer              │
 │    .IsOptimalEntry(signal)    │
 │    ─ Spread ≤20 pts (ideal)   │  May DEFER (not reject):
 │    ─ ATR < 2× average         │  re-check next tick up
 │    ─ Micro-pullback detected  │  to N ticks, then expire
 │    ─ Volume ≥0.7× average     │
 │    ─ Candle < 0.8× ATR        │
 └───────────────┬───────────────┘
                 │ Entry confirmed
                 ▼
 ┌───────────────────────────────┐
 │ 7. POSITION SIZING            │
 │    MoneyManager               │
 │    .CalculateLot(signal)      │
 │    ─ Risk % of equity         │  0.01–0.03 base lots
 │    ─ ATR-based SL distance    │  scaled by risk %
 │    ─ Commission awareness     │
 │    ─ TP/SL levels computed    │
 └───────────────┬───────────────┘
                 │ Lot + TP + SL
                 ▼
 ┌───────────────────────────────┐
 │ 8. ORDER EXECUTION            │
 │    TradeManager               │
 │    .OpenPosition(request)     │
 │    ─ OrderSend with retry     │  Max 3 retries
 │    ─ Slippage guard (≤2 pip)  │  with backoff
 │    ─ Fill-or-kill semantics   │
 │    ─ Log ticket + fill price  │
 └───────────────┬───────────────┘
                 │ Position opened (ticket)
                 ▼
        ┌────────┴────────┐
        ▼                 ▼
 ┌─────────────┐  ┌──────────────┐
 │ MANAGE LOOP │  │  TIME EXIT   │
 │ (every tick │  │  GUARD       │
 │  on open    │  │  (OnTimer    │
 │  positions) │  │   every 30s) │
 └──────┬──────┘  └──────┬───────┘
        │                │
        ▼                ▼
 ┌───────────────────────────────┐
 │ 9. TRADE MANAGEMENT AI        │
 │    TradeManagementAI          │
 │    .ManageOpenTrades()        │
 │    ─ BE at 70% to TP          │
 │    ─ Partial close (50%)      │
 │      at 90% to TP             │
 │    ─ Extend TP if momentum    │
 │      strong (1.5×)            │
 │    ─ Close early on momentum  │
 │      fade                     │
 │    ─ Trailing stop after      │
 │      1.5× TP distance         │
 │    ─ Time-based tightening    │
 │      (>30 min)                │
 │    ─ Time exit: >120 min →    │
 │      EMERGENCY CLOSE           │
 └───────────────┬───────────────┘
                 │ Position closed or modified
                 ▼
 ┌───────────────────────────────┐
 │ 10. POST-TRADE FEEDBACK       │
 │     RiskManager.OnClose()     │
 │     RegimeMemory.Record()     │
 │     ─ Update per-regime stats │  File-persisted
 │     ─ Recalc WR, PF           │  every N trades
 │     ─ Adapt strategy weights  │
 │     ─ Log + telemetry         │
 └───────────────────────────────┘
```

### 3.2 Timing Budget per Tick

| Stage                | Budget   | Notes                                    |
|----------------------|----------|------------------------------------------|
| MarketAnalyzer       | ≤ 5 ms   | Cached; full recalc throttled to 1/sec   |
| 8 × Strategy eval    | ≤ 8 ms   | Each ≤ 1 ms; skip inactive regimes       |
| QualityFilter        | ≤ 2 ms   | Simple arithmetic                        |
| Consensus            | ≤ 0.5 ms | Array walk                               |
| Frequency gate       | ≤ 0.2 ms | Counter checks                           |
| ExecutionTimer       | ≤ 1 ms   | Spread/vol lookups                       |
| MoneyManager         | ≤ 0.5 ms | Arithmetic                               |
| OrderSend            | Network  | 50–300 ms (broker dependent)             |
| **Total (to send)**  | **< 18 ms** | Excluding network round-trip         |

---

## 4. Strategy Pattern Implementation

### 4.1 Class Hierarchy

```
                     ┌──────────────────┐
                     │   IStrategy      │  (interface / pure virtual)
                     │                  │
                     │ + Init()         │
                     │ + Evaluate()     │
                     │ + GetSignal()    │
                     │ + GetWeight()    │
                     │ + GetName()      │
                     │ + IsActive()     │
                     └────────┬─────────┘
                              │
                     ┌────────┴─────────┐
                     │   BaseStrategy   │  (shared indicator cache,
                     │                  │   logging, market state ref)
                     │ # m_state        │
                     │ # m_weight       │
                     │ # m_signal       │
                     │ # m_strength     │
                     │ # m_name         │
                     │ # CacheIndicator │
                     └────────┬─────────┘
                              │
          ┌───────────┬───────┼───────┬──────────────┐
          ▼           ▼       ▼       ▼              ▼
   TrendFollowing  Breakout  ...  GridRecovery  MomentumScalping
```

### 4.2 BaseStrategy Interface Contract

```cpp
class BaseStrategy {
protected:
    string          m_name;
    double          m_baseWeight;       // Static config weight
    double          m_adaptiveWeight;   // Regime-adjusted weight
    ENUM_SIGNAL     m_signal;           // BUY / SELL / NONE
    double          m_strength;         // 0.0 – 1.0 confidence
    ENUM_REGIME     m_activeRegimes[];  // Which regimes activate this

    // Shared indicator cache (prevents duplicate iMA/iRSI calls)
    IndicatorCache* m_cache;

    virtual bool    CheckActivation(const MarketState &state);
    virtual void    CalculateSignal(const MarketState &state) = 0;

public:
    void            Init(IndicatorCache *cache, double baseWeight);
    void            Evaluate(const MarketState &state);
    ENUM_SIGNAL     GetSignal()    const { return m_signal;   }
    double          GetStrength()  const { return m_strength; }
    double          GetWeight()    const { return m_adaptiveWeight; }
    string          GetName()      const { return m_name;     }
    bool            IsActive()     const { return m_signal != SIGNAL_NONE; }
    void            SetAdaptiveWeight(double w);
};
```

### 4.3 Strategy Activation Rules

| Strategy           | Base Weight | Active Regimes          | Key Indicators              |
|--------------------|-------------|-------------------------|-----------------------------|
| TrendFollowing     | 1.2         | TRENDING                | EMA(21,50,200), ADX, HH/HL |
| Breakout           | 1.1         | TRENDING, VOLATILE      | Bollinger, volume spike     |
| MeanReversion      | 1.0         | RANGING, CALM           | RSI extremes, BB bands      |
| SupplyDemand       | 1.2         | ANY (fresh zones)       | Zone database, wick tests   |
| SmartMoney         | 1.3         | TRENDING + BOS          | Order blocks, FVG, BOS/CHoCH|
| PriceAction        | 1.0         | ANY (key levels)        | Pin bar, engulfing, doji    |
| GridRecovery       | 0.7         | VOLATILE (RESTRICTED)   | Max 3 levels, zone-based    |
| MomentumScalping   | 1.5         | VOLATILE, <5 min target | RSI/Stoch cross, momentum   |

### 4.4 StrategyManager Orchestration

```cpp
class StrategyManager {
    BaseStrategy*    m_strategies[8];
    IndicatorCache   m_cache;
    RegimeMemory*    m_memory;

public:
    void Init(RegimeMemory *memory);

    // Called once per evaluation cycle
    void EvaluateAll(const MarketState &state) {
        m_cache.Refresh(state);  // One pass for all indicators
        for (int i = 0; i < 8; i++) {
            double w = m_memory.GetAdaptiveWeight(state.regime, i);
            m_strategies[i].SetAdaptiveWeight(w);
            m_strategies[i].Evaluate(state);
        }
    }

    int GetSignals(SignalResult &results[]);
};
```

**Design decisions:**

- `IndicatorCache` ensures iMA(21), iRSI(14), etc. are only called once per bar, shared across all strategies.
- Strategies that are inactive for the current regime short-circuit in `CheckActivation()` and return `SIGNAL_NONE` in < 0.01 ms.
- `RegimeMemory` supplies adapted weights so the manager does not need to understand per-regime history.

### 4.5 Consensus Engine Detail

```
Input:  Signal[8] × {direction, strength, adaptiveWeight}
        QualityScore (0–100)

Step 1: Quality gate
        if qualityScore < THRESHOLD → return NONE

Step 2: Count active voters and weighted scores
        for each strategy with signal != NONE:
            if signal == BUY:  buyScore  += strength × adaptiveWeight
            if signal == SELL: sellScore += strength × adaptiveWeight
            increment buyCount or sellCount

Step 3: Quorum check
        required = max(3, activeCount × 0.4)
        if buyCount < required AND sellCount < required → NONE

Step 4: Margin check (anti flip-flop)
        if buyScore > sellScore × 1.05 AND buyCount >= required → BUY
        if sellScore > buyScore × 1.05 AND sellCount >= required → SELL
        else → NONE (too ambiguous)

Output: {BUY | SELL | NONE}
```

---

## 5. Performance Optimization Approach

### 5.1 Tick Processing Optimization

| Technique                          | Impact                        | Implementation                                               |
|------------------------------------|-------------------------------|--------------------------------------------------------------|
| **Indicator caching**              | Eliminates 70%+ iXxx calls   | `IndicatorCache` refreshes once per bar, not per tick        |
| **Regime-based strategy skip**     | Saves 50% of eval on average  | `CheckActivation()` short-circuits in < 0.01 ms             |
| **Analysis throttle**              | Caps CPU per second           | Full `MarketAnalyzer` recalc max once per second             |
| **New-bar gating**                 | Bulk of logic runs on M1 bar  | Only TradeManagementAI and spread check run every tick       |
| **Pre-allocated arrays**           | Zero heap churn               | All signal/result arrays sized at `OnInit`, never resized    |
| **Handle-based indicators**        | MT5-native caching            | `iMA`, `iRSI` etc. created once in `OnInit`, handles reused |

### 5.2 Memory Management

```
Allocation strategy: RAII at OnInit, no dynamic allocation during OnTick.

┌──────────────────────────────────────────────────┐
│  OnInit                                          │
│  ─ Create all 8 strategy objects                 │
│  ─ Create IndicatorCache (all handles)           │
│  ─ Pre-size SignalResult[8], QualityComponent[11]│
│  ─ Load RegimeMemory from file                   │
│  ─ Initialize InfoPanel objects                  │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│  OnTick                                          │
│  ─ ZERO heap allocations                         │
│  ─ All work on stack or pre-allocated members    │
│  ─ String formatting only for Logger (buffered)  │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│  OnDeinit                                        │
│  ─ Flush RegimeMemory to file                    │
│  ─ Release indicator handles                     │
│  ─ Destroy objects                               │
└──────────────────────────────────────────────────┘
```

### 5.3 Indicator Handle Strategy

Create all indicator handles once in `OnInit` and store them in `IndicatorCache`:

| Indicator       | Handle(s)            | Used By                              |
|-----------------|----------------------|--------------------------------------|
| EMA 21/50/200   | 3 handles            | TrendFollowing, QualityFilter        |
| RSI 14          | 1 handle             | MeanReversion, MomentumScalping, QF  |
| MACD 12,26,9    | 1 handle             | QualityFilter, MomentumScalping      |
| Bollinger 20,2  | 1 handle             | Breakout, MeanReversion              |
| ATR 14          | 1 handle             | All (volatility reference)           |
| ADX 14          | 1 handle             | TrendFollowing, MarketAnalyzer       |
| Stochastic 5,3,3| 1 handle             | MomentumScalping                     |
| Volume (ticks)  | Custom counter       | QualityFilter, ExecutionTimer        |
| **Total**       | **~10 handles**      | Shared, never duplicated             |

---

## 6. Error Handling Strategy

### 6.1 Error Classification

```
┌─────────────────────────────────────────────────────────────────┐
│                     ERROR SEVERITY LEVELS                        │
├──────────┬──────────────────────────┬───────────────────────────┤
│  Level   │  Examples                │  Response                 │
├──────────┼──────────────────────────┼───────────────────────────┤
│ FATAL    │ Account margin call,     │ Close all positions,      │
│          │ license failure,         │ disable EA, alert user,   │
│          │ corrupt memory file      │ log dump                  │
├──────────┼──────────────────────────┼───────────────────────────┤
│ CRITICAL │ OrderSend failure after  │ Abort current trade,      │
│          │ 3 retries, disconnection,│ activate cooldown (5 min),│
│          │ DD threshold breached    │ log, retry on reconnect   │
├──────────┼──────────────────────────┼───────────────────────────┤
│ WARNING  │ Spread spike, partial    │ Log, defer signal, do not │
│          │ fill, regime ambiguity,  │ halt pipeline             │
│          │ indicator stale data     │                           │
├──────────┼──────────────────────────┼───────────────────────────┤
│ INFO     │ Trade opened/closed,     │ Log only                  │
│          │ regime change, weight    │                           │
│          │ adaptation               │                           │
└──────────┴──────────────────────────┴───────────────────────────┘
```

### 6.2 Trade Execution Error Handling

```
OrderSend attempt
    │
    ├─ Success → log ticket, proceed
    │
    ├─ TRADE_RETCODE_REQUOTE
    │   └─ Re-fetch price, retry (max 3) with 100ms backoff
    │
    ├─ TRADE_RETCODE_REJECT / TRADE_RETCODE_ERROR
    │   └─ Log reason, increment failCounter
    │       if failCounter >= 3 in 5 min → cooldown 5 min
    │
    ├─ TRADE_RETCODE_INVALID_STOPS
    │   └─ Recalculate SL/TP with broker's STOPS_LEVEL, retry once
    │
    ├─ TRADE_RETCODE_NO_MONEY
    │   └─ CRITICAL: halt new trades, alert, wait for manual reset
    │
    └─ TRADE_RETCODE_CONNECTION_LOST
        └─ Buffer intent, reconnect handler retries on OnTimer
```

### 6.3 Indicator Data Validation

Every indicator read is wrapped in a validation guard:

```cpp
bool SafeCopyBuffer(int handle, int bufIdx, int start, int count, double &buf[]) {
    if (handle == INVALID_HANDLE) return false;
    int copied = CopyBuffer(handle, bufIdx, start, count, buf);
    if (copied != count) {
        Logger::Warn("CopyBuffer incomplete", handle, copied, count);
        return false;
    }
    for (int i = 0; i < count; i++) {
        if (!MathIsValidNumber(buf[i])) {
            Logger::Warn("NaN/Inf in buffer", handle, i);
            return false;
        }
    }
    return true;
}
```

Strategies that receive `false` from indicator reads emit `SIGNAL_NONE` — the pipeline degrades gracefully rather than producing garbage signals.

### 6.4 File I/O Safety (RegimeMemory Persistence)

```
Write strategy:
  1. Write to temp file (RegimeMemory.tmp)
  2. Validate temp file (read back and checksum)
  3. Rename old file → .bak
  4. Rename temp → RegimeMemory.bin
  5. On read failure at startup → fall back to .bak → fall back to defaults

Never leave the system without a valid memory file.
```

### 6.5 Circuit Breakers

| Breaker                | Trigger                     | Action                        | Reset                   |
|------------------------|-----------------------------|-------------------------------|-------------------------|
| Equity drawdown        | DD > 12% from peak          | Close all, halt trading       | Manual or next day      |
| Daily loss             | Realized loss > 5% equity   | Halt new trades               | Next trading day        |
| Consecutive losses     | 3 losses in a row           | Pause 30 min, halve lot       | Win or timeout          |
| Spread blowout         | Spread > 50 pts for > 1 min | Halt entries                  | Spread normalizes       |
| Execution failures     | 3 OrderSend fails in 5 min  | Cooldown 5 min                | Timer expiry            |
| Connection loss        | No tick for > 60 sec        | Tighten all SLs               | Tick resumes            |

---

## 7. State Management Approach

### 7.1 State Categories

```
┌─────────────────────────────────────────────────────────────────┐
│                     STATE LAYERS                                │
├──────────────────┬──────────────────────────────────────────────┤
│  TRANSIENT       │  Per-tick: current prices, spread, last      │
│  (rebuilt each   │  candle data, indicator values, signal array. │
│  tick)           │  Never persisted. Cheap to rebuild.           │
├──────────────────┼──────────────────────────────────────────────┤
│  SESSION         │  Per-session: trade counters, daily P&L,     │
│  (reset daily    │  hourly trade count, consecutive loss count,  │
│  or on restart)  │  frequency controller state, cooldown timers. │
│                  │  Held in memory. Rebuilt on restart from       │
│                  │  trade history query.                         │
├──────────────────┼──────────────────────────────────────────────┤
│  PERSISTENT      │  Across restarts: RegimeMemory (WR, PF per   │
│  (file-backed)   │  regime×strategy, adaptive weights), config   │
│                  │  overrides, cumulative telemetry counters.    │
│                  │  Saved to MQL5/Files/ with .bak rotation.     │
├──────────────────┼──────────────────────────────────────────────┤
│  CONFIGURATION   │  Input parameters (EA properties dialog).     │
│  (input params)  │  Immutable during runtime. Changed only by    │
│                  │  removing and re-attaching the EA.            │
└──────────────────┴──────────────────────────────────────────────┘
```

### 7.2 MarketState Struct (Transient Core)

```cpp
struct MarketState {
    // Regime
    ENUM_REGIME      regime;          // TRENDING / RANGING / VOLATILE / CALM
    ENUM_TREND_DIR   trendDir;        // UP / DOWN / FLAT
    ENUM_STRUCTURE   structure;       // HH_HL / LL_LH / NONE

    // Price context
    double           bid, ask, spread;
    double           atr14;
    double           atrRatio;        // current ATR / 20-bar avg ATR

    // Key levels
    double           nearestSupport;
    double           nearestResistance;
    double           supplyZones[];    // Nearest N
    double           demandZones[];

    // Session
    ENUM_SESSION     session;          // ASIAN / LONDON / NEWYORK / OVERLAP
    int              hourWIT;          // 0–23 in WIT (UTC+7)
    bool             isGoldenHour;     // 22-23 or 08-09 WIT

    // Indicators (from cache)
    double           ema21, ema50, ema200;
    double           rsi14;
    double           macdMain, macdSignal;
    double           bbUpper, bbMiddle, bbLower;
    double           adx;
    double           stochK, stochD;

    // Volume / activity
    double           tickVolume;
    double           avgTickVolume;
    double           volumeRatio;      // current / average

    // Metadata
    datetime         timestamp;
    bool             isNewBar;         // M1 new bar flag
};
```

### 7.3 Session State (Rebuilt on Restart)

```cpp
struct SessionState {
    int              tradesToday;
    int              tradesThisHour;
    datetime         lastTradeTime;
    double           dailyPnL;
    double           peakEquity;
    int              consecutiveLosses;
    bool             isCoolingDown;
    datetime         cooldownUntil;

    // Rebuilt on OnInit by scanning HistoryDeals for today
    void Rebuild();
};
```

### 7.4 RegimeMemory Structure (Persistent)

```
File: MQL5/Files/AurumSynapse/RegimeMemory.bin

Layout per cell [regime × strategy]:
┌───────────────┬────────┐
│ Field         │ Type   │
├───────────────┼────────┤
│ totalTrades   │ int    │
│ wins          │ int    │
│ totalProfit   │ double │
│ totalLoss     │ double │
│ winRate       │ double │  (cached, = wins/totalTrades)
│ profitFactor  │ double │  (cached, = totalProfit/|totalLoss|)
│ adaptWeight   │ double │  (clamped 0.3–2.0)
└───────────────┴────────┘

Matrix size: 4 regimes × 8 strategies = 32 cells
Rolling window: last 50 trades per cell (oldest evicted)

Weight adaptation formula:
    base = strategy.baseWeight
    if WR > 80%: boost = +20%
    if WR < 50%: penalty = -30%
    if PF > 3.0: boost += 15%
    if PF < 1.5: penalty += 20%
    adaptiveWeight = clamp(base × (1 + boost - penalty), 0.3, 2.0)
```

### 7.5 State Transition Diagram (EA Lifecycle)

```
             ┌──────────┐
             │  LOADED   │  EA attached to chart
             └─────┬─────┘
                   │ OnInit()
                   ▼
             ┌──────────┐
     ┌──────►│  READY    │  Indicators created, memory loaded,
     │       │           │  session state rebuilt
     │       └─────┬─────┘
     │             │ First tick
     │             ▼
     │       ┌──────────┐
     │  ┌───►│ SCANNING  │◄────────────────────────┐
     │  │    │           │  Evaluate market, run    │
     │  │    └─────┬─────┘  pipeline per tick       │
     │  │          │                                │
     │  │          ├─ Pipeline produces NONE ────────┘
     │  │          │
     │  │          ├─ Pipeline produces BUY/SELL
     │  │          ▼
     │  │    ┌──────────┐
     │  │    │ EXECUTING │  OrderSend in progress
     │  │    └─────┬─────┘
     │  │          │
     │  │          ├─ Success → open position
     │  │          │            enter MANAGING
     │  │          │
     │  │          └─ Fail → log, re-enter SCANNING
     │  │
     │  │    ┌──────────┐
     │  │    │ MANAGING  │  TradeManagementAI active
     │  │    │           │  (runs alongside SCANNING
     │  │    │           │   for new signals)
     │  │    └─────┬─────┘
     │  │          │ Position closed
     │  │          ▼
     │  │    ┌──────────┐
     │  │    │ FEEDBACK  │  Record result → RegimeMemory
     │  └────│           │  Update session counters
     │       └──────────┘
     │
     │  Circuit breaker triggered
     │       ┌──────────┐
     └───────│  HALTED   │  No new trades; manage existing only
             │           │  Reset: manual, timer, or new day
             └──────────┘

             ┌──────────┐
             │ SHUTDOWN  │  OnDeinit() — flush memory, release handles
             └──────────┘
```

---

## 8. File & Module Map

```
AurumSynapse/
├── AurumSynapse.mq5              # Main EA: OnInit/OnTick/OnDeinit/OnTimer
├── REFERENCE_SPECS.md            # Canonical feature spec
│
├── Core/
│   ├── Constants.mqh             # Enums, magic numbers, thresholds, input params
│   ├── Structures.mqh            # MarketState, SignalResult, SessionState, etc.
│   └── IndicatorCache.mqh        # Shared indicator handle pool + buffer reads
│
├── Strategies/
│   ├── BaseStrategy.mqh          # Abstract base + shared logic
│   ├── TrendFollowing.mqh        # EMA cross + ADX + structure
│   ├── Breakout.mqh              # Bollinger squeeze + volume
│   ├── MeanReversion.mqh         # RSI/BB extremes
│   ├── SupplyDemand.mqh          # Zone database + wick tests
│   ├── SmartMoney.mqh            # BOS/CHoCH + order blocks + FVG
│   ├── PriceAction.mqh           # Candlestick patterns at levels
│   ├── GridRecovery.mqh          # Zone-based grid (max 3 levels)
│   └── MomentumScalping.mqh      # RSI/Stoch cross + momentum burst
│
├── Engine/
│   ├── StrategyManager.mqh       # Owns all 8 strategies, runs evaluation
│   ├── SignalManager.mqh         # Consensus engine + quality gate
│   ├── QualityFilter.mqh         # 11-component quality scorer (100 pts)
│   └── MarketAnalyzer.mqh        # Regime detect, structure, levels, session
│
├── Execution/
│   ├── FrequencyController.mqh   # Rate limiting, cooldowns, dead-zone check
│   ├── ExecutionTimer.mqh        # Micro-timing: spread, pullback, volume
│   ├── MoneyManager.mqh          # Lot sizing, TP/SL computation
│   └── TradeManager.mqh          # OrderSend wrapper, retry, slippage guard
│
├── Management/
│   ├── TradeManagementAI.mqh     # Active position management (BE, partial, trail)
│   └── RiskManager.mqh           # DD protection, circuit breakers, daily caps
│
├── Intelligence/
│   └── RegimeMemory.mqh          # Per-regime×strategy stats, file persistence
│
├── UI/
│   ├── InfoPanel.mqh             # On-chart HUD (equity, regime, signals, PnL)
│   ├── Logger.mqh                # Structured logging to file + journal
│   └── Telemetry.mqh             # Aggregate stats for analysis
│
└── Docs/
    └── Architecture.md           # (this document)
```

---

## 9. Architectural Decisions Record

### ADR-001: Weighted Consensus over Democratic Voting

**Context:** Initial design used equal-weight majority voting. Quantum Queen analysis showed MomentumScalping has a 94-96% WR in <5 min while GridRecovery introduces significant risk.

**Decision:** Each strategy carries an adaptive weight (0.3–2.0). Votes are multiplied by `strength × adaptiveWeight`. A 5% margin prevents flip-flopping.

**Consequences:** Higher-performing strategies dominate in their favored regimes. Requires RegimeMemory to prevent weight drift from noise. Adds ~0.5 ms per consensus cycle.

---

### ADR-002: Pipeline of Vetoes (No Single Layer Forces a Trade)

**Context:** Monolithic signal-to-trade systems make it difficult to isolate why a bad trade was taken.

**Decision:** The pipeline is a chain of independent filters. Each layer can only PASS or REJECT/DEFER. No layer can override a rejection from an earlier layer. Order: Quality → Consensus → Frequency → Timing → Risk → Execution.

**Consequences:** Conservative by design (may miss some opportunities). Every rejection is logged with the rejecting layer, enabling post-hoc analysis. Layers can be tested independently.

---

### ADR-003: Indicator Cache with Handle Reuse

**Context:** Calling `iMA()` or `iRSI()` per strategy per tick would create redundant calculations. MT5's handle system already caches, but buffer copies still cost time.

**Decision:** A single `IndicatorCache` object creates all handles in `OnInit`, copies buffers once per bar (or once per second for tick-level data), and exposes values via struct fields.

**Consequences:** All strategies share identical indicator values (no drift from timing). ~10 handles total. Slight code coupling (strategies depend on cache struct), mitigated by clear interface.

---

### ADR-004: Time-Based Exit as Separate Guard

**Context:** Quantum Queen data shows WR drops from 94% (<5 min) to 44% (>120 min). Time is the strongest single predictor of trade failure.

**Decision:** Time exit runs on `OnTimer` (30-second interval), independent of the main `OnTick` pipeline. It progressively tightens SL and forcibly closes positions past 120 minutes.

**Consequences:** Eliminates "death trades" that drag down PF. Timer resolution (30s) is sufficient since minute-level precision is adequate for hour-scale exits. Adds negligible CPU cost.

---

### ADR-005: RegimeMemory as File-Persisted Rolling Window

**Context:** The system needs to learn from live performance without unbounded memory growth.

**Decision:** A 50-trade rolling window per (regime, strategy) cell. Stats are recalculated on each trade close. File is written with temp-rename-backup pattern for crash safety.

**Consequences:** Weight adaptation converges after ~50 trades per cell (~400 total for full matrix). Cold start uses base weights. Crash during write cannot corrupt the active file. File size is small (~2 KB for 32 cells).

---

### ADR-006: Grid Recovery Capped at 3 Levels

**Context:** Quantum Queen used up to 6 grid levels successfully but with elevated risk. Uncapped grids are the primary source of catastrophic loss in retail EAs.

**Decision:** Hard cap of 3 grid levels, enforced in both `GridRecovery.mqh` and `RiskManager.mqh`. Grid is only activated in VOLATILE regime with SupplyDemand zone confirmation.

**Consequences:** Reduces theoretical max loss per grid sequence from 6× to 3× base risk. May leave money on table in extended ranges. Dual enforcement (strategy + risk manager) prevents bypass through bugs.

---

### ADR-007: Session State Rebuilt from Trade History on Restart

**Context:** If the EA restarts mid-day (crash, terminal update, VPS reboot), session counters (daily trades, P&L, consecutive losses) must be accurate to prevent over-trading.

**Decision:** `SessionState.Rebuild()` queries `HistoryDealsTotal` / `HistoryDealGetTicket` for today's trades on every `OnInit`, reconstructing all session counters.

**Consequences:** Restart-safe. Adds ~50-200 ms to `OnInit` (acceptable, one-time cost). Depends on broker's history availability (typically reliable for same-day data).

---

## 10. Risk Register

| ID    | Risk                                     | Likelihood | Impact   | Mitigation                                                       |
|-------|------------------------------------------|------------|----------|------------------------------------------------------------------|
| R-01  | Overfitting RegimeMemory to recent market| High       | Medium   | 50-trade rolling window; weight clamp 0.3–2.0; decay toward base |
| R-02  | Spread spikes during news bypass filter  | Medium     | High     | Spread check in ExecutionTimer; session blackout around NFP/FOMC  |
| R-03  | Grid recovery exceeds risk despite cap   | Low        | Critical | Dual enforcement (strategy + RiskManager); DD circuit breaker     |
| R-04  | Indicator handle exhaustion              | Low        | High     | Fixed set of ~10 handles; validation in OnInit; no dynamic creation|
| R-05  | File corruption of RegimeMemory          | Low        | Medium   | Temp-rename-backup write pattern; .bak fallback; default fallback |
| R-06  | Strategy weight oscillation (flip-flop)  | Medium     | Medium   | 5% margin in consensus; weight change clamped per update cycle    |
| R-07  | Execution latency on slow broker/VPS     | Medium     | Medium   | Timing budget allows 300 ms network; SL set pre-send; retry logic |
| R-08  | Terminal restart loses session state      | Medium     | Medium   | Session rebuilt from HistoryDeals on OnInit (ADR-007)             |
| R-09  | Scalping edge disappears in regime shift | Medium     | High     | RegimeMemory auto-reduces MomentumScalping weight; multi-strategy hedge |
| R-10  | Backtesting gives false confidence       | High       | High     | Forward-test on demo for 2+ weeks; multi-broker validation        |
| R-11  | Concurrent modification if multiple charts| Low       | High     | Magic number per instance; file lock or unique filenames           |
| R-12  | Broker changes commission/spread model   | Low        | Medium   | Commission as input param; spread monitored in real-time          |

---

*This document is the canonical architectural reference for Aurum Synapse v2. All implementation should conform to the structures, flows, and decisions described here. Deviations require updating this document first.*
