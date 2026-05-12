//+------------------------------------------------------------------+
//|                                              TrendFollowing.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Trend Following Strategy - EMA Cross + ADX + Structure"

#include "BaseStrategy.mqh"

//+------------------------------------------------------------------+
//| Trend Following Strategy                                         |
//|                                                                  |
//| Logic:                                                           |
//|   BUY:  ADX gate (regime-adaptive — Phase 3B), Price > EMA50, EMA21 > EMA50, RSI > 50 |
//|   SELL: same ADX gate, Price < EMA50, EMA21 < EMA50, RSI < 50        |
//|                                                                  |
//| Strength Calculation (0.0 - 1.0):                               |
//|   Base: 0.5 (50%)                                                |
//|   +0.1 if ADX > 30 (strong trend)                                |
//|   +0.1 if ADX > 40 (very strong trend)                           |
//|   +0.1 if EMA200 aligned                                         |
//|   +0.1 if market structure confirms (HH/HL or LL/LH)             |
//|   +0.1 if at key level (support/resistance bounce)               |
//|                                                                  |
//| Activation: TRENDING+VOLATILE+RANGING+CALM (Phase 3B H2). RANGING ADX 18–25; CALM uses atrRatio (ADX<15). |
//+------------------------------------------------------------------+
class TrendFollowing : public BaseStrategy {
private:
    //--- Strategy-specific settings
    double           m_adxThresholdMin;      // Minimum ADX to trigger (25)
    double           m_adxThresholdStrong;   // Strong trend threshold (30)
    double           m_adxThresholdVeryStrong; // Very strong trend (40)
    double           m_rsiMidline;           // RSI midline (50)
    
    //--- Helper methods
    bool             CheckBullishConditions(const MarketState &state);
    bool             CheckBearishConditions(const MarketState &state);
    double           CalculateStrength(const MarketState &state, bool isBullish);
    
protected:
    //--- Pure virtual implementations
    virtual bool     CheckActivation(const MarketState &state);
    virtual void     CalculateSignal(const MarketState &state);
    
public:
    //--- Constructor / Destructor
    TrendFollowing();
    ~TrendFollowing();
    
    //--- Initialization override
    virtual void     Init(IndicatorCache* cache, double baseWeight, string symbol, ENUM_TIMEFRAMES tf);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
TrendFollowing::TrendFollowing(void) :
    m_adxThresholdMin(25.0),
    m_adxThresholdStrong(30.0),
    m_adxThresholdVeryStrong(40.0),
    m_rsiMidline(50.0)
{
    m_name = "TrendFollowing";
    m_baseWeight = WEIGHT_TREND_FOLLOWING;  // 1.2 from constants
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
TrendFollowing::~TrendFollowing(void) {
    // Nothing to clean up
}

//+------------------------------------------------------------------+
//| Initialize strategy                                              |
//+------------------------------------------------------------------+
void TrendFollowing::Init(IndicatorCache* cache, double baseWeight, string symbol, ENUM_TIMEFRAMES tf) {
    // Call base class init
    BaseStrategy::Init(cache, baseWeight, symbol, tf);
    
    // Phase 3A+: TRENDING + VOLATILE. Phase 3B: +RANGING +CALM (H2 compression / ADX≤25 deadlock).
    ENUM_REGIME regimes[4];
    regimes[0] = REGIME_TRENDING;
    regimes[1] = REGIME_VOLATILE;
    regimes[2] = REGIME_RANGING;
    regimes[3] = REGIME_CALM;
    SetActiveRegimes(regimes, 4);
    
    Print("TrendFollowing initialized - Phase 3B H2: TREND+VOL+RANG+CALM; ADX>=25 T/V, >=18 RANG, CALM atr>=0.78; SELL bar0|1 bearish");
}

//+------------------------------------------------------------------+
//| Check if strategy should be active                               |
//| Returns true if market is in TRENDING regime with ADX > 25       |
//+------------------------------------------------------------------+
bool TrendFollowing::CheckActivation(const MarketState &state) {
    // Phase 3A+: base-class regime check. Phase 3B: +RANGING +CALM.
    if(!IsActiveInCurrentRegime(state))
        return false;
    
    // Phase 3B (H2): MarketAnalyzer RANGING uses ADX 15–25 — prior ADX>=25 made RANGING almost never active.
    // CALM uses ADX<15 — ADX>=25 impossible; use light atr floor instead (compression participation).
    if(state.regime == REGIME_CALM) {
        if(state.atrRatio < 0.78)
            return false;
        return true;
    }
    if(state.regime == REGIME_RANGING) {
        if(state.adx < 18.0)
            return false;
        return true;
    }
    
    if(state.adx < m_adxThresholdMin)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate trading signal                                         |
//| Implements core trend following logic                            |
//+------------------------------------------------------------------+
void TrendFollowing::CalculateSignal(const MarketState &state) {
    // Check bullish setup
    if(CheckBullishConditions(state)) {
        m_signal = SIGNAL_BUY;
        m_strength = CalculateStrength(state, true);
        return;
    }
    
    // Check bearish setup — Phase 3A+: bar-1 bearish. Phase 3B: bar0|bar1 (H2 snap; same family as MomScalp 3B++).
    if(CheckBearishConditions(state)) {
        if(IsBearishCandle(0) || IsBearishCandle(1)) {
            m_signal = SIGNAL_SELL;
            m_strength = CalculateStrength(state, false);
            return;
        }
    }
    
    // No valid setup
    m_signal = SIGNAL_NONE;
    m_strength = 0.0;
}

//+------------------------------------------------------------------+
//| Check bullish trend following conditions                         |
//+------------------------------------------------------------------+
bool TrendFollowing::CheckBullishConditions(const MarketState &state) {
    // 1. ADX — Phase 3B: match CheckActivation (CALM skips; RANGING min 18; else 25)
    double minAdx = m_adxThresholdMin;
    if(state.regime == REGIME_RANGING)
        minAdx = 18.0;
    else if(state.regime == REGIME_CALM)
        minAdx = -1.0;
    if(minAdx >= 0.0 && state.adx < minAdx)
        return false;
    
    // 2. Price above EMA50 (trend filter)
    double ema50 = state.ema50;
    if(ema50 == 0) return false;  // Invalid indicator
    
    double currentPrice = state.bid;
    if(currentPrice <= ema50) {
        return false;
    }
    
    // 3. EMA21 > EMA50 (short-term momentum aligned with trend)
    double ema21 = state.ema21;
    if(ema21 == 0) return false;
    
    if(ema21 <= ema50) {
        return false;
    }
    
    // 4. RSI > 50 (momentum confirmation)
    double rsi = state.rsi14;
    if(rsi == 0) return false;
    
    if(rsi <= m_rsiMidline) {
        return false;
    }
    
    // 5. Optional: Check for bullish structure (HH/HL)
    // This adds conviction but is not mandatory
    bool hasStructure = (state.structure == STRUCTURE_HH_HL);
    
    // All conditions met
    return true;
}

//+------------------------------------------------------------------+
//| Check bearish trend following conditions                         |
//+------------------------------------------------------------------+
bool TrendFollowing::CheckBearishConditions(const MarketState &state) {
    double minAdx = m_adxThresholdMin;
    if(state.regime == REGIME_RANGING)
        minAdx = 18.0;
    else if(state.regime == REGIME_CALM)
        minAdx = -1.0;
    if(minAdx >= 0.0 && state.adx < minAdx)
        return false;
    
    // 2. Price below EMA50 (trend filter)
    double ema50 = state.ema50;
    if(ema50 == 0) return false;
    
    double currentPrice = state.bid;
    if(currentPrice >= ema50) {
        return false;
    }
    
    // 3. EMA21 < EMA50 (short-term momentum aligned with downtrend)
    double ema21 = state.ema21;
    if(ema21 == 0) return false;
    
    if(ema21 >= ema50) {
        return false;
    }
    
    // 4. RSI < 50 (momentum confirmation)
    double rsi = state.rsi14;
    if(rsi == 0) return false;
    
    if(rsi >= m_rsiMidline) {
        return false;
    }
    
    // 5. Optional: Check for bearish structure (LL/LH)
    bool hasStructure = (state.structure == STRUCTURE_LL_LH);
    
    // All conditions met
    return true;
}

//+------------------------------------------------------------------+
//| Calculate signal strength (0.0 - 1.0)                            |
//| Base 0.5 + bonuses for additional confirming factors             |
//+------------------------------------------------------------------+
double TrendFollowing::CalculateStrength(const MarketState &state, bool isBullish) {
    double strength = 0.5;  // Base strength: 50%
    
    //--- Bonus 1: Strong ADX (> 30) adds 0.1
    if(state.adx > m_adxThresholdStrong) {
        strength += 0.1;
    }
    
    //--- Bonus 2: Very strong ADX (> 40) adds another 0.1
    if(state.adx > m_adxThresholdVeryStrong) {
        strength += 0.1;
    }
    
    //--- Bonus 3: EMA200 alignment adds 0.1
    // For bullish: price > EMA200 AND EMA50 > EMA200
    // For bearish: price < EMA200 AND EMA50 < EMA200
    double ema200 = state.ema200;
    double ema50 = state.ema50;
    double price = state.bid;
    
    if(ema200 > 0 && ema50 > 0) {
        if(isBullish) {
            if(price > ema200 && ema50 > ema200) {
                strength += 0.1;
            }
        } else {
            if(price < ema200 && ema50 < ema200) {
                strength += 0.1;
            }
        }
    }
    
    //--- Bonus 4: Market structure confirmation adds 0.1
    if(isBullish) {
        if(state.structure == STRUCTURE_HH_HL) {
            strength += 0.1;
        }
    } else {
        if(state.structure == STRUCTURE_LL_LH) {
            strength += 0.1;
        }
    }
    
    //--- Bonus 5: At key level (support for buy, resistance for sell) adds 0.1
    bool atKeyLevel = IsAtKeyLevel(state, KEY_LEVEL_PROXIMITY_PIPS * 10);
    if(atKeyLevel) {
        // For bullish: should be near support
        // For bearish: should be near resistance
        if(isBullish) {
            if(IsNearSupport(state, KEY_LEVEL_PROXIMITY_PIPS * 10)) {
                strength += 0.1;
            }
        } else {
            if(IsNearResistance(state, KEY_LEVEL_PROXIMITY_PIPS * 10)) {
                strength += 0.1;
            }
        }
    }
    
    //--- Additional bonus: Golden hour adds 0.05
    if(state.isGoldenHour) {
        strength += 0.05;
    }
    
    //--- Penalty: Dead zone reduces strength
    if(IsDeadZone(state)) {
        strength *= 0.7;  // Reduce by 30%
    }
    
    // Normalize to 0.0 - 1.0 range
    return NormalizeStrength(strength);
}

//+------------------------------------------------------------------+
//| END OF TREND FOLLOWING STRATEGY                                  |
//+------------------------------------------------------------------+
