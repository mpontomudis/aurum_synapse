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
//|   - Volatility gate (ATR ratio — Phase 3B+ T/V ~1.04; RANG ~1.00; CALM ~0.82) |
//|   - Golden hour preference (22-23, 08-09 WIT) — milder off-hour   |
//|   - Volume confirmation (bar0+bar1 max vs avg — Phase 3B+ ~1.03×; >= avg×mult)|
//|                                                                  |
//| Entry Conditions:                                                |
//|   BUY:                                                           |
//|     - Strong bullish momentum (MACD > signal, rising)            |
//|     - RSI Phase 3B++ band ~38–92 BUY / ~15–75 SELL (see CalculateSignal)|
//|     - Stochastic bullish (K > D, K > 20)                         |
//|     - Volume > ~1.03× average (activation + confirm; bar0+bar1)    |
//|     - ATR ratio > ~1.04 T/V or ~1.00 RANGING or ~0.82 CALM (3B+)    |
//|     - Preferably during golden hours                             |
//|                                                                  |
//|   SELL:                                                          |
//|     - Strong bearish momentum (MACD < signal, falling)           |
//|     - RSI Phase 3B++ band (see CalculateSignal)                    |
//|     - Stochastic bearish (K < D, K < 80)                         |
//|     - Volume > ~1.03× average                                     |
//|     - ATR ratio > ~1.04 T/V or ~1.00 RANGING or ~0.82 CALM; bar0|1 bearish |
//|     - Preferably during golden hours                             |
//|                                                                  |
//| Strength Calculation:                                            |
//|   Base: 0.6 (higher than others - proven edge)                   |
//|   +0.20 if during golden hours (22-23, 08-09 WIT)                |
//|   +0.15 if all 3 momentum indicators aligned                     |
//|   +0.10 if volume spike > 1.5× average                           |
//|   +0.10 if ATR ratio > 1.5 (very active)                         |
//|   +0.05 if trend aligned                                         |
//|   -0.18 penalty if NOT in golden hours (3A+ — H2 / off-hour Q60) |
//|                                                                  |
//| Activation: VOL+TREND+RANGING+CALM (3B). Phase 3B+: softer T/V+RANG+CALM |
//| atr/vol floors after 3B FY verify still showed Aug–Dec monthly zero.   |
//| Phase 3B++: BUY RSI ceiling 92 (H2 melt-up veto); SELL bar0|1 bearish;|
//| vol confirm >= threshold (parity with CheckActivation).           |
//+------------------------------------------------------------------+
class MomentumScalping : public BaseStrategy {
private:
    //--- Strategy-specific settings
    double           m_volumeMultiplier;       // Phase 3B+ activation vs avg (~1.03)
    double           m_minATRRatio;            // Phase 3B+ T/V ATR floor (~1.04)
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
    bool             HasVolumeConfirmation(const MarketState &state, double multiplier);
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
    m_volumeMultiplier(1.03),
    m_minATRRatio(1.04),
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
    
    // Phase 3A+: RANGING. Phase 3B: CALM — MarketAnalyzer returns CALM before VOL/RANG when ADX<15 & narrow BB (H2 compression).
    ENUM_REGIME regimes[4];
    regimes[0] = REGIME_VOLATILE;
    regimes[1] = REGIME_TRENDING;
    regimes[2] = REGIME_RANGING;
    regimes[3] = REGIME_CALM;
    SetActiveRegimes(regimes, 4);
    
    Print("MomentumScalping initialized - Phase 3B++ signal: BUY RSI<92; SELL bar0|1 bearish; vol confirm >=");
    Print("HIGHEST WEIGHT (1.5) - Primary scalping edge based on QQ analysis");
}

//+------------------------------------------------------------------+
//| Check if strategy should be active                               |
//+------------------------------------------------------------------+
bool MomentumScalping::CheckActivation(const MarketState &state) {
    if(!IsActiveInCurrentRegime(state)) {
        return false;
    }
    
    // Phase 3B+: FY Q60 showed Aug–Dec still zero after CALM — relax T/V+RANGING+CALM atr/vol (strategy-local).
    double minAtr = m_minATRRatio;
    double volMult = m_volumeMultiplier;
    if(state.regime == REGIME_CALM) {
        minAtr = 0.82;
        volMult = 1.0;  // tick volume > avg (strict > avg*1.0)
    } else if(state.regime == REGIME_RANGING) {
        minAtr = 1.00;
        volMult = 1.02;
    }
    if(state.atrRatio < minAtr) {
        return false;
    }
    
    // Phase 3A: bar-0 tick volume is often near zero at bar open in tester — use max(bar0,bar1)
    double avgVolume = GetAverageVolume(20);
    double currentVolume = MathMax(GetVolume(0), GetVolume(1));
    if(avgVolume == 0 || currentVolume < (avgVolume * volMult)) {
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
        if(HasVolumeConfirmation(state, m_volumeMultiplier)) {
            // Phase 3B++: raise BUY ceiling (was 85) — strong H2 legs often sit 85–92 with MACD+Stoch still 2-of-3 bull
            if(state.rsi14 > 38.0 && state.rsi14 < 92.0) {
                m_signal = SIGNAL_BUY;
                m_strength = CalculateStrength(state, SIGNAL_BUY);
                return;
            }
        }
    }
    
    // Check for bearish momentum scalp — Phase 3B++: bar0|bar1 bearish (align bar0|bar1 volume); RSI cap 75
    if(IsBearishMomentum(state)) {
        if((IsBearishCandle(0) || IsBearishCandle(1)) && HasVolumeConfirmation(state, m_volumeMultiplier)) {
            if(state.rsi14 > 15.0 && state.rsi14 < 75.0) {
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
//| Check volume confirmation (RANGING cap 1.02; CALM cap 1.0 — 3B+) |
//+------------------------------------------------------------------+
bool MomentumScalping::HasVolumeConfirmation(const MarketState &state, double multiplier) {
    double avgVolume = GetAverageVolume(20);
    double currentVolume = MathMax(GetVolume(0), GetVolume(1));
    
    if(avgVolume == 0) return false;
    
    double mult = multiplier;
    // Base-path only: keep strong-volume bonus threshold strict
    if(state.regime == REGIME_CALM && multiplier <= m_volumeMultiplier + 1e-6)
        mult = MathMin(mult, 1.0);
    else if(state.regime == REGIME_RANGING && multiplier <= m_volumeMultiplier + 1e-6)
        mult = MathMin(mult, 1.02);
    
    return (currentVolume >= (avgVolume * mult));
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
    if(HasVolumeConfirmation(state, m_strongVolumeMultiplier)) {
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
    
    //--- PENALTY 1: NOT in golden hours (3A+: milder — off-hour/H2 strength was over-suppressed at Q60)
    if(!state.isGoldenHour) {
        strength -= 0.18;
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
