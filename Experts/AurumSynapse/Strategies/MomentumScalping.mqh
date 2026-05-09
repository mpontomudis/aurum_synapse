//+------------------------------------------------------------------+
//|                                            MomentumScalping.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Momentum Scalping Strategy - Ultra-Fast Edge (<5min Target)"

#include "BaseStrategy.mqh"

//+------------------------------------------------------------------+
//| Momentum Scalping Strategy                                       |
//|                                                                  |
//| ⭐ HIGHEST WEIGHT (1.5) - Primary edge based on QQ analysis     |
//|                                                                  |
//| Logic:                                                           |
//|   BUY:  Strong bullish momentum + volatility                     |
//|   SELL: Strong bearish momentum + volatility                     |
//|                                                                  |
//| Core Concept:                                                    |
//|   - Ultra-fast scalping (<5 min target = 94-96% WR per QQ data) |
//|   - Momentum-driven entries (MACD + RSI + Stoch alignment)      |
//|   - Volatility gate (ATR ratio — Phase 3A tester floor relaxed)   |
//|   - Golden hour preference (22-23, 08-09 WIT) — strength only    |
//|   - Volume confirmation (bar0+bar1 max vs avg — tester-safe)     |
//|                                                                  |
//| Entry Conditions:                                                |
//|   BUY:                                                           |
//|     - Strong bullish momentum (MACD > signal, rising)            |
//|     - RSI Phase 3A band ~38–85 BUY / ~15–62 SELL (see CalculateSignal)|
//|     - Stochastic bullish (K > D, K > 20)                         |
//|     - Volume > ~1.05× average (activation + confirm; bar0+bar1)|
//|     - ATR ratio > ~1.06 (Phase 3A tester floor)                  |
//|     - Preferably during golden hours                             |
//|                                                                  |
//|   SELL:                                                          |
//|     - Strong bearish momentum (MACD < signal, falling)           |
//|     - RSI Phase 3A band (see CalculateSignal)                    |
//|     - Stochastic bearish (K < D, K < 80)                         |
//|     - Volume > ~1.05× average                                     |
//|     - ATR ratio > ~1.06                                          |
//|     - Preferably during golden hours                             |
//|                                                                  |
//| Strength Calculation:                                            |
//|   Base: 0.6 (higher than others - proven edge)                   |
//|   +0.20 if during golden hours (22-23, 08-09 WIT)                |
//|   +0.15 if all 3 momentum indicators aligned                     |
//|   +0.10 if volume spike > 1.5× average                           |
//|   +0.10 if ATR ratio > 1.5 (very active)                         |
//|   +0.05 if trend aligned                                         |
//|   -0.30 penalty if NOT in golden hours                           |
//|                                                                  |
//| Activation: VOLATILE + TRENDING; Phase 3A: volume uses            |
//|   max(bar0,bar1) vs avg; atr/volume floors lowered for tester.   |
//| RSI entry bands widened so 2-of-3 momentum is not vetoed.       |
//+------------------------------------------------------------------+
class MomentumScalping : public BaseStrategy {
private:
    //--- Strategy-specific settings
    double           m_volumeMultiplier;       // Phase 3A activation vs avg (~1.05 tester)
    double           m_minATRRatio;            // Phase 3A ATR ratio floor (~1.06 tester)
    double           m_strongVolumeMultiplier; // Strong volume (1.5)
    double           m_strongATRRatio;         // Strong ATR ratio (1.5)
    
    //--- Momentum tracking
    bool             m_macdBullish;
    bool             m_rsiBullish;
    bool             m_stochBullish;
    int              m_momentumScore;
    
    //--- Helper methods
    void             AnalyzeMomentum(const MarketState &state);
    bool             IsBullishMomentum(const MarketState &state);
    bool             IsBearishMomentum(const MarketState &state);
    bool             HasVolumeConfirmation(double multiplier);
    int              CountAlignedIndicators(bool bullish);
    double           CalculateStrength(const MarketState &state, ENUM_SIGNAL direction);
    
protected:
    //--- Pure virtual implementations
    virtual bool     CheckActivation(const MarketState &state);
    virtual void     CalculateSignal(const MarketState &state);
    
public:
    //--- Constructor / Destructor
    MomentumScalping();
    ~MomentumScalping();
    
    //--- Initialization override
    virtual void     Init(IndicatorCache* cache, double baseWeight, string symbol, ENUM_TIMEFRAMES tf);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
MomentumScalping::MomentumScalping(void) :
    m_volumeMultiplier(1.05),
    m_minATRRatio(1.06),
    m_strongVolumeMultiplier(1.5),
    m_strongATRRatio(1.5),
    m_macdBullish(false),
    m_rsiBullish(false),
    m_stochBullish(false),
    m_momentumScore(0)
{
    m_name = "MomentumScalping";
    m_baseWeight = WEIGHT_MOMENTUM_SCALP;  // 1.5 (highest weight)
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
MomentumScalping::~MomentumScalping(void) {
    // Nothing to clean up
}

//+------------------------------------------------------------------+
//| Initialize strategy                                              |
//+------------------------------------------------------------------+
void MomentumScalping::Init(IndicatorCache* cache, double baseWeight, string symbol, ENUM_TIMEFRAMES tf) {
    // Call base class init
    BaseStrategy::Init(cache, baseWeight, symbol, tf);
    
    // Set active regimes (VOLATILE preferred, but can work in TRENDING)
    ENUM_REGIME regimes[2];
    regimes[0] = REGIME_VOLATILE;
    regimes[1] = REGIME_TRENDING;
    SetActiveRegimes(regimes, 2);
    
    Print("MomentumScalping initialized - VOLATILE+TRENDING; Phase 3A volume/ATR/RSI gates (tester rehab)");
    Print("HIGHEST WEIGHT (1.5) - Primary scalping edge based on QQ analysis");
}

//+------------------------------------------------------------------+
//| Check if strategy should be active                               |
//+------------------------------------------------------------------+
bool MomentumScalping::CheckActivation(const MarketState &state) {
    if(!IsActiveInCurrentRegime(state)) {
        return false;
    }
    
    if(state.atrRatio < m_minATRRatio) {
        return false;
    }
    
    // Phase 3A: bar-0 tick volume is often near zero at bar open in tester — use max(bar0,bar1)
    double avgVolume = GetAverageVolume(20);
    double currentVolume = MathMax(GetVolume(0), GetVolume(1));
    if(avgVolume == 0 || currentVolume < (avgVolume * m_volumeMultiplier)) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate trading signal                                         |
//+------------------------------------------------------------------+
void MomentumScalping::CalculateSignal(const MarketState &state) {
    // Analyze momentum indicators
    AnalyzeMomentum(state);
    
    // Check for bullish momentum scalp
    if(IsBullishMomentum(state)) {
        if(HasVolumeConfirmation(m_volumeMultiplier)) {
            // Phase 3A: allow RSI 38–85 so MACD+Stoch can vote when RSI<50 (2-of-3 path)
            if(state.rsi14 > 38.0 && state.rsi14 < 85.0) {
                m_signal = SIGNAL_BUY;
                m_strength = CalculateStrength(state, SIGNAL_BUY);
                return;
            }
        }
    }
    
    // Check for bearish momentum scalp
    if(IsBearishMomentum(state)) {
        if(HasVolumeConfirmation(m_volumeMultiplier)) {
            // Phase 3A: allow RSI 15–62 so MACD+Stoch bearish can vote when RSI>50
            if(state.rsi14 > 15.0 && state.rsi14 < 62.0) {
                m_signal = SIGNAL_SELL;
                m_strength = CalculateStrength(state, SIGNAL_SELL);
                return;
            }
        }
    }
    
    // No momentum scalp signal
    m_signal = SIGNAL_NONE;
    m_strength = 0.0;
}

//+------------------------------------------------------------------+
//| Analyze momentum indicators                                      |
//+------------------------------------------------------------------+
void MomentumScalping::AnalyzeMomentum(const MarketState &state) {
    // MACD momentum
    m_macdBullish = (state.macdMain > state.macdSignal);
    
    // RSI momentum (above/below 50)
    m_rsiBullish = (state.rsi14 > 50);
    
    // Stochastic momentum
    m_stochBullish = (state.stochK > state.stochD);
    
    // Calculate momentum score
    m_momentumScore = 0;
    if(m_macdBullish) m_momentumScore++;
    if(m_rsiBullish) m_momentumScore++;
    if(m_stochBullish) m_momentumScore++;
}

//+------------------------------------------------------------------+
//| Check for bullish momentum                                       |
//+------------------------------------------------------------------+
bool MomentumScalping::IsBullishMomentum(const MarketState &state) {
    // Need at least 2 of 3 momentum indicators bullish
    int bullishCount = 0;
    
    if(state.macdMain > state.macdSignal) bullishCount++;
    if(state.rsi14 > 50) bullishCount++;
    if(state.stochK > state.stochD && state.stochK > 20) bullishCount++;
    
    return (bullishCount >= 2);
}

//+------------------------------------------------------------------+
//| Check for bearish momentum                                       |
//+------------------------------------------------------------------+
bool MomentumScalping::IsBearishMomentum(const MarketState &state) {
    // Need at least 2 of 3 momentum indicators bearish
    int bearishCount = 0;
    
    if(state.macdMain < state.macdSignal) bearishCount++;
    if(state.rsi14 < 50) bearishCount++;
    if(state.stochK < state.stochD && state.stochK < 80) bearishCount++;
    
    return (bearishCount >= 2);
}

//+------------------------------------------------------------------+
//| Check volume confirmation                                        |
//+------------------------------------------------------------------+
bool MomentumScalping::HasVolumeConfirmation(double multiplier) {
    double avgVolume = GetAverageVolume(20);
    double currentVolume = MathMax(GetVolume(0), GetVolume(1));
    
    if(avgVolume == 0) return false;
    
    return (currentVolume > (avgVolume * multiplier));
}

//+------------------------------------------------------------------+
//| Count aligned momentum indicators                                |
//+------------------------------------------------------------------+
int MomentumScalping::CountAlignedIndicators(bool bullish) {
    int count = 0;
    
    if(bullish) {
        if(m_macdBullish) count++;
        if(m_rsiBullish) count++;
        if(m_stochBullish) count++;
    } else {
        if(!m_macdBullish) count++;
        if(!m_rsiBullish) count++;
        if(!m_stochBullish) count++;
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Calculate signal strength                                        |
//+------------------------------------------------------------------+
double MomentumScalping::CalculateStrength(const MarketState &state, ENUM_SIGNAL direction) {
    double strength = 0.6;  // Base strength: 60% (higher than others)
    
    //--- Bonus 1: Golden hours (22-23, 08-09 WIT) adds 0.20 ⭐
    if(state.isGoldenHour) {
        strength += 0.20;
    }
    
    //--- Bonus 2: All 3 momentum indicators aligned adds 0.15
    int alignedCount = CountAlignedIndicators(direction == SIGNAL_BUY);
    if(alignedCount == 3) {
        strength += 0.15;
    }
    
    //--- Bonus 3: Strong volume spike (> 1.5×) adds 0.10
    if(HasVolumeConfirmation(m_strongVolumeMultiplier)) {
        strength += 0.10;
    }
    
    //--- Bonus 4: Strong volatility (ATR ratio > 1.5) adds 0.10
    if(state.atrRatio > m_strongATRRatio) {
        strength += 0.10;
    }
    
    //--- Bonus 5: Trend aligned adds 0.05
    bool trendAligned = false;
    if(direction == SIGNAL_BUY) {
        trendAligned = (state.trendDir == TREND_UP);
    } else {
        trendAligned = (state.trendDir == TREND_DOWN);
    }
    
    if(trendAligned) {
        strength += 0.05;
    }
    
    //--- PENALTY 1: NOT in golden hours reduces by 0.30
    if(!state.isGoldenHour) {
        strength -= 0.30;  // Strong penalty outside golden hours
    }
    
    //--- Penalty 2: Dead zone reduces strength
    if(IsDeadZone(state)) {
        strength *= 0.5;  // Scalping in dead zones is very risky
    }
    
    // Normalize to 0.0 - 1.0 range
    return NormalizeStrength(strength);
}

//+------------------------------------------------------------------+
//| END OF MOMENTUM SCALPING STRATEGY                                |
//+------------------------------------------------------------------+
