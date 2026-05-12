//+------------------------------------------------------------------+
//|                                               MeanReversion.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Mean Reversion Strategy - Range Returns in Calm Markets"

#include "BaseStrategy.mqh"

//+------------------------------------------------------------------+
//| Mean Reversion Strategy                                          |
//|                                                                  |
//| Logic:                                                           |
//|   BUY:  Price oversold + expect bounce to mean                   |
//|   SELL: Price overbought + expect pullback to mean               |
//|                                                                  |
//| Entry Conditions:                                                |
//|   BUY:                                                           |
//|     - Price < Lower BB OR within 20% of BB width                 |
//|     - RSI < 30 (oversold)                                        |
//|     - Price below EMA21                                          |
//|                                                                  |
//|   SELL:                                                          |
//|     - Price > Upper BB OR within 20% of BB width                 |
//|     - RSI > overbought (60 Phase 3A+)                            |
//|     - Price above EMA21                                          |
//|                                                                  |
//| Strength Calculation:                                            |
//|   Base: 0.5                                                      |
//|   +0.15 if RSI extreme (<20 or >80)                              |
//|   +0.15 if price beyond BB (not just near)                       |
//|   +0.10 if low volatility (ATR ratio < 0.8)                      |
//|   +0.10 if multiple touches of BB (consolidation)                |
//|   +0.05 if golden hour                                           |
//|   -0.30 penalty if ADX > 25 in TRENDING/VOLATILE only (Phase 3B) |
//|   Dead-zone strength penalty only in TRENDING/VOLATILE (Phase 3B)|
//|                                                                  |
//| Activation: ALL regimes (Phase 3A+); strength gates regime-aware|
//+------------------------------------------------------------------+
class MeanReversion : public BaseStrategy {
private:
    //--- Strategy-specific settings
    double           m_rsiOversold;          // RSI oversold level (30)
    double           m_rsiOverbought;        // RSI overbought level (70)
    double           m_rsiExtreme;           // Extreme RSI level (20/80)
    double           m_bbProximity;          // Proximity to BB (20% of width)
    int              m_bbTouchLookback;      // Bars to check for BB touches (10)
    double           m_lowVolatilityThreshold; // ATR ratio threshold (0.8)
    
    //--- Helper methods
    bool             IsOversold(const MarketState &state);
    bool             IsOverbought(const MarketState &state);
    bool             IsPriceNearLowerBB(const MarketState &state);
    bool             IsPriceNearUpperBB(const MarketState &state);
    bool             IsPriceBeyondLowerBB(const MarketState &state);
    bool             IsPriceBeyondUpperBB(const MarketState &state);
    int              CountBBTouches(bool checkUpper);
    bool             IsLowVolatility(const MarketState &state);
    double           CalculateStrength(const MarketState &state, ENUM_SIGNAL direction);
    //--- Temporary tester-only H2 drought diagnostics (Aug–Sep); remove after investigation
    void             MaybeLogMrAugSepDiag_(const MarketState &state);
    
protected:
    //--- Pure virtual implementations
    virtual bool     CheckActivation(const MarketState &state);
    virtual void     CalculateSignal(const MarketState &state);
    
public:
    //--- Constructor / Destructor
    MeanReversion();
    ~MeanReversion();
    
    //--- Initialization override
    virtual void     Init(IndicatorCache* cache, double baseWeight, string symbol, ENUM_TIMEFRAMES tf);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
MeanReversion::MeanReversion(void) :
    m_rsiOversold(45.0),           // PHASE 1: Relaxed from 30 to 45
    m_rsiOverbought(60.0),         // Phase 3A+: 55 → 60 (need genuine overbought, not breakout zone)
    m_rsiExtreme(20.0),
    m_bbProximity(0.20),
    m_bbTouchLookback(10),
    m_lowVolatilityThreshold(0.8)
{
    m_name = "MeanReversion";
    m_baseWeight = WEIGHT_MEAN_REVERSION;  // 1.0 from constants
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
MeanReversion::~MeanReversion(void) {
    // Nothing to clean up
}

//+------------------------------------------------------------------+
//| Initialize strategy                                              |
//+------------------------------------------------------------------+
void MeanReversion::Init(IndicatorCache* cache, double baseWeight, string symbol, ENUM_TIMEFRAMES tf) {
    // Call base class init
    BaseStrategy::Init(cache, baseWeight, symbol, tf);
    
    // Phase 3A+: all regimes — MR can fire when price overextends in any condition.
    // Phase 3B: strength penalties (ADX, dead zone) scoped to TRENDING/VOLATILE only in CalculateStrength.
    ENUM_REGIME regimes[4];
    regimes[0] = REGIME_RANGING;
    regimes[1] = REGIME_CALM;
    regimes[2] = REGIME_VOLATILE;
    regimes[3] = REGIME_TRENDING;
    SetActiveRegimes(regimes, 4);
    
    Print("MeanReversion initialized - Phase 3B H2: ALL regimes; RSI sell 60; SELL bar0 or bar1 bearish; ADX+deadzone penalties T/V only");
}

//+------------------------------------------------------------------+
//| Check if strategy should be active                               |
//+------------------------------------------------------------------+
bool MeanReversion::CheckActivation(const MarketState &state) {
    // Phase 3A+: use base-class regime check (all 4 regimes registered in Init)
    if(!IsActiveInCurrentRegime(state))
        return false;
    
    // Need visible range (Bollinger Bands should be defined)
    double bbWidth = state.bbUpper - state.bbLower;
    if(bbWidth <= 0 || state.bbMiddle <= 0) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Tester-only: sample closed bar (shift=1) Aug–Sep — max 30 lines   |
//| Compares bar[1] raw MR-BUY geometry vs live path on current state|
//+------------------------------------------------------------------+
void MeanReversion::MaybeLogMrAugSepDiag_(const MarketState &state) {
    if(!MQLInfoInteger(MQL_TESTER))
        return;
    
    datetime barTime = iTime(m_symbol, m_timeframe, 1);
    if(barTime <= 0)
        return;
    
    MqlDateTime dt;
    TimeToStruct(barTime, dt);
    if(dt.mon != 8 && dt.mon != 9)
        return;
    
    static int      s_mrDiagPrinted = 0;
    static datetime s_mrDiagLastPrintedDay = 0;
    
    MqlDateTime dDay = dt;
    dDay.hour = 0;
    dDay.min = 0;
    dDay.sec = 0;
    datetime dayKey = StructToTime(dDay);
    if(dayKey == s_mrDiagLastPrintedDay)
        return;
    if(s_mrDiagPrinted >= 30)
        return;
    
    static int s_bbH = INVALID_HANDLE;
    static int s_rsiH = INVALID_HANDLE;
    static int s_emaH = INVALID_HANDLE;
    if(s_bbH == INVALID_HANDLE) {
        s_bbH = iBands(m_symbol, m_timeframe, BB_PERIOD, 0, BB_DEVIATION, PRICE_CLOSE);
        s_rsiH = iRSI(m_symbol, m_timeframe, RSI_PERIOD, PRICE_CLOSE);
        s_emaH = iMA(m_symbol, m_timeframe, 21, 0, MODE_EMA, PRICE_CLOSE);
    }
    if(s_bbH == INVALID_HANDLE || s_rsiH == INVALID_HANDLE || s_emaH == INVALID_HANDLE)
        return;
    
    double bu[], bl[], rs[], em[];
    ArraySetAsSeries(bu, true);
    ArraySetAsSeries(bl, true);
    ArraySetAsSeries(rs, true);
    ArraySetAsSeries(em, true);
    if(CopyBuffer(s_bbH, 0, 1, 1, bu) < 1) return;
    if(CopyBuffer(s_bbH, 2, 1, 1, bl) < 1) return;
    if(CopyBuffer(s_rsiH, 0, 1, 1, rs) < 1) return;
    if(CopyBuffer(s_emaH, 0, 1, 1, em) < 1) return;
    
    const double upper = bu[0];
    const double lower = bl[0];
    const double rsi1 = rs[0];
    const double ema21_1 = em[0];
    const double close1 = GetClose(1);
    const double bbWidth = upper - lower;
    if(bbWidth <= 0.0 || lower <= 0.0)
        return;
    
    const double bbDist = close1 - lower;
    const double prox = bbWidth * m_bbProximity;
    const bool   nearLower = (close1 <= lower + prox);
    const bool   belowLower = (close1 < lower);
    const bool   rsiOversold = (rsi1 < m_rsiOversold);
    const bool   aboveEma = (close1 > ema21_1);
    const bool   hypoBar1Buy = rsiOversold && (nearLower || belowLower) && (close1 < ema21_1);
    
    const bool liveBuyPath = IsOversold(state) &&
                             (IsPriceNearLowerBB(state) || IsPriceBeyondLowerBB(state)) &&
                             (state.bid < state.ema21);
    
    Print("[MR-DIAG] time=", TimeToString(barTime, TIME_DATE | TIME_MINUTES),
          " close1=", DoubleToString(close1, _Digits),
          " lower1=", DoubleToString(lower, _Digits),
          " bbDist=", DoubleToString(bbDist, _Digits),
          " rsi1=", DoubleToString(rsi1, 1),
          " nearLower=", (nearLower ? "1" : "0"),
          " belowLower=", (belowLower ? "1" : "0"),
          " rsiOS=", (rsiOversold ? "1" : "0"),
          " aboveEMA=", (aboveEma ? "1" : "0"),
          " hypoBar1Buy=", (hypoBar1Buy ? "1" : "0"),
          " live0Buy=", (liveBuyPath ? "1" : "0"),
          " regime=", (int)state.regime);
    
    s_mrDiagLastPrintedDay = dayKey;
    s_mrDiagPrinted++;
}

//+------------------------------------------------------------------+
//| Calculate trading signal                                         |
//+------------------------------------------------------------------+
void MeanReversion::CalculateSignal(const MarketState &state) {
    MaybeLogMrAugSepDiag_(state);
    
    // Check for oversold conditions (BUY signal)
    if(IsOversold(state)) {
        if(IsPriceNearLowerBB(state) || IsPriceBeyondLowerBB(state)) {
            if(state.bid < state.ema21) {  // Price below short-term EMA
                m_signal = SIGNAL_BUY;
                m_strength = CalculateStrength(state, SIGNAL_BUY);
                return;
            }
        }
    }
    
    // Check for overbought conditions (SELL signal)
    if(IsOverbought(state)) {
        if(IsPriceNearUpperBB(state) || IsPriceBeyondUpperBB(state)) {
            if(state.bid > state.ema21) {
                // Phase 3A+: bar-1 bearish. Phase 3B: bar0 or bar1 (H2 snap; same family as TrendFollowing)
                if(IsBearishCandle(0) || IsBearishCandle(1)) {
                    m_signal = SIGNAL_SELL;
                    m_strength = CalculateStrength(state, SIGNAL_SELL);
                    return;
                }
            }
        }
    }
    
    // No mean reversion signal
    m_signal = SIGNAL_NONE;
    m_strength = 0.0;
}

//+------------------------------------------------------------------+
//| Check if RSI is oversold                                         |
//+------------------------------------------------------------------+
bool MeanReversion::IsOversold(const MarketState &state) {
    return (state.rsi14 < m_rsiOversold);
}

//+------------------------------------------------------------------+
//| Check if RSI is overbought                                       |
//+------------------------------------------------------------------+
bool MeanReversion::IsOverbought(const MarketState &state) {
    return (state.rsi14 > m_rsiOverbought);
}

//+------------------------------------------------------------------+
//| Check if price is near lower Bollinger Band                      |
//+------------------------------------------------------------------+
bool MeanReversion::IsPriceNearLowerBB(const MarketState &state) {
    double bbWidth = state.bbUpper - state.bbLower;
    if(bbWidth <= 0) return false;
    
    double proximityDistance = bbWidth * m_bbProximity;
    return (state.bid <= (state.bbLower + proximityDistance));
}

//+------------------------------------------------------------------+
//| Check if price is near upper Bollinger Band                      |
//+------------------------------------------------------------------+
bool MeanReversion::IsPriceNearUpperBB(const MarketState &state) {
    double bbWidth = state.bbUpper - state.bbLower;
    if(bbWidth <= 0) return false;
    
    double proximityDistance = bbWidth * m_bbProximity;
    return (state.bid >= (state.bbUpper - proximityDistance));
}

//+------------------------------------------------------------------+
//| Check if price is beyond (below) lower Bollinger Band            |
//+------------------------------------------------------------------+
bool MeanReversion::IsPriceBeyondLowerBB(const MarketState &state) {
    return (state.bid < state.bbLower);
}

//+------------------------------------------------------------------+
//| Check if price is beyond (above) upper Bollinger Band            |
//+------------------------------------------------------------------+
bool MeanReversion::IsPriceBeyondUpperBB(const MarketState &state) {
    return (state.bid > state.bbUpper);
}

//+------------------------------------------------------------------+
//| Count how many times price touched BB (consolidation indicator)  |
//+------------------------------------------------------------------+
int MeanReversion::CountBBTouches(bool checkUpper) {
    int touches = 0;
    
    // Get BB handle from cache (we'll need to copy buffers directly)
    // Since BaseStrategy::GetBB() doesn't support shift yet,
    // we'll use a simplified check on recent bars
    
    for(int i = 1; i <= m_bbTouchLookback; i++) {
        double high = GetHigh(i);
        double low = GetLow(i);
        double close = GetClose(i);
        
        // Get current BB values (approximation - using shift=0 values as reference)
        double bbUpper = GetBB(0, 0);  // Current upper
        double bbMiddle = GetBB(1, 0); // Current middle
        double bbLower = GetBB(2, 0);  // Current lower
        
        if(bbUpper <= 0 || bbLower <= 0) continue;
        
        double bbWidth = bbUpper - bbLower;
        double proximityThreshold = bbWidth * 0.05;  // 5% of BB width
        
        if(checkUpper) {
            // Check if high came close to upper band
            if(high >= (bbUpper - proximityThreshold)) touches++;
        } else {
            // Check if low came close to lower band
            if(low <= (bbLower + proximityThreshold)) touches++;
        }
    }
    
    return touches;
}

//+------------------------------------------------------------------+
//| Check if volatility is low (ideal for mean reversion)            |
//+------------------------------------------------------------------+
bool MeanReversion::IsLowVolatility(const MarketState &state) {
    return (state.atrRatio < m_lowVolatilityThreshold);
}

//+------------------------------------------------------------------+
//| Calculate signal strength                                        |
//+------------------------------------------------------------------+
double MeanReversion::CalculateStrength(const MarketState &state, ENUM_SIGNAL direction) {
    double strength = 0.5;  // Base strength: 50%
    
    //--- Bonus 1: Extreme RSI (<20 or >80) adds 0.15
    bool extremeRSI = false;
    if(direction == SIGNAL_BUY) {
        extremeRSI = (state.rsi14 < m_rsiExtreme);
    } else {
        extremeRSI = (state.rsi14 > (100 - m_rsiExtreme));  // >80
    }
    
    if(extremeRSI) {
        strength += 0.15;
    }
    
    //--- Bonus 2: Price beyond BB (not just near) adds 0.15
    bool beyondBB = false;
    if(direction == SIGNAL_BUY) {
        beyondBB = IsPriceBeyondLowerBB(state);
    } else {
        beyondBB = IsPriceBeyondUpperBB(state);
    }
    
    if(beyondBB) {
        strength += 0.15;
    }
    
    //--- Bonus 3: Low volatility (ATR ratio < 0.8) adds 0.10
    if(IsLowVolatility(state)) {
        strength += 0.10;
    }
    
    //--- Bonus 4: Multiple BB touches (consolidation) adds 0.10
    bool checkUpper = (direction == SIGNAL_SELL);
    int touches = CountBBTouches(checkUpper);
    
    if(touches >= 2) {  // At least 2 touches in last 10 bars
        strength += 0.10;
    }
    
    //--- Bonus 5: Golden hour adds 0.05
    if(state.isGoldenHour) {
        strength += 0.05;
    }
    
    //--- Bonus 6: Price near key support/resistance adds 0.10
    if(direction == SIGNAL_BUY && IsNearSupport(state, 50)) {
        strength += 0.10;
    } else if(direction == SIGNAL_SELL && IsNearResistance(state, 50)) {
        strength += 0.10;
    }
    
    //--- Penalty 1: ADX > 25 — Phase 3B: only in TRENDING/VOLATILE (MR home RANGING/CALM should not double-penalize vs regime)
    if(state.adx > 25.0 &&
       (state.regime == REGIME_TRENDING || state.regime == REGIME_VOLATILE)) {
        strength *= 0.7;
    }
    
    //--- Penalty 2: Dead zone — Phase 3B: only in TRENDING/VOLATILE (session starvation in RANGING/CALM H2/H1)
    if(IsDeadZone(state) &&
       (state.regime == REGIME_TRENDING || state.regime == REGIME_VOLATILE)) {
        strength *= 0.7;
    }
    
    //--- Penalty 3: Stochastic not confirming reduces strength
    // For BUY: Stochastic should be oversold (K < 20)
    // For SELL: Stochastic should be overbought (K > 80)
    bool stochConfirms = false;
    if(direction == SIGNAL_BUY) {
        stochConfirms = (state.stochK < 20);
    } else {
        stochConfirms = (state.stochK > 80);
    }
    
    if(!stochConfirms) {
        strength *= 0.9;  // 10% penalty
    }
    
    // Normalize to 0.0 - 1.0 range
    return NormalizeStrength(strength);
}

//+------------------------------------------------------------------+
//| END OF MEAN REVERSION STRATEGY                                   |
//+------------------------------------------------------------------+
