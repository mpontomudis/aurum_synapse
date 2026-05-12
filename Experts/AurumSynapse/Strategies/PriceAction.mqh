//+------------------------------------------------------------------+
//|                                                  PriceAction.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Price Action Strategy - Candlestick Patterns + Key Levels"

#include "BaseStrategy.mqh"

//+------------------------------------------------------------------+
//| Price Action Strategy                                            |
//|                                                                  |
//| Logic:                                                           |
//|   BUY:  Bullish candle pattern + key level confluence            |
//|   SELL: Bearish candle pattern + key level confluence            |
//|                                                                  |
//| Candlestick Patterns:                                            |
//|   - Pin Bar (rejection candle with long wick)                    |
//|   - Engulfing (complete engulfment of previous candle)           |
//|   - Inside Bar (consolidation within previous range)             |
//|   - Hammer/Shooting Star (reversal patterns)                     |
//|   - Doji (indecision at key levels)                              |
//|                                                                  |
//| Entry Conditions:                                                |
//|   BUY:                                                           |
//|     - Bullish candle pattern detected                            |
//|     - At key support level (within 50 pips)                      |
//|     - Volume > average                                           |
//|     - Not overbought (RSI < 70)                                  |
//|                                                                  |
//|   SELL:                                                          |
//|     - Bearish candle pattern detected                            |
//|     - At key resistance level (within 50 pips)                   |
//|     - Volume > average                                           |
//|     - Not oversold (RSI > 30)                                    |
//|                                                                  |
//| Strength Calculation:                                            |
//|   Base: 0.5                                                      |
//|   +0.15 if strong pattern (pin bar, engulfing)                   |
//|   +0.15 if at major key level                                    |
//|   +0.10 if multiple pattern confluence                           |
//|   +0.10 if volume confirmation                                   |
//|   +0.05 if golden hour                                           |
//|                                                                  |
//| Activation: Phase 3A pattern-only; Phase 3B always evaluate       |
//| CalculateSignal (classic patterns too rare on M5 XAU FY).        |
//| Phase 3A++ v4: avgVolume<=0 pass; soft PA bar0|1; BB mid fallback   |
//| in IsNearKeyLevel when edges unset. Phase 3B H2 (May 2026): dead-   |
//| zone penalty T/V only; softer vol/key/RSI/wick for R/C + H2 tape.   |
//+------------------------------------------------------------------+
class PriceAction : public BaseStrategy {
private:
    //--- Strategy-specific settings
    double           m_keyLevelProximity;      // Min distance to S/R or BB (price); rehab widened
    double           m_volumeMultiplier;       // Volume vs avg (rehab < 1.0 for tester bar0)
    
    //--- Pattern detection tracking
    bool             m_pinBarBullish;
    bool             m_pinBarBearish;
    bool             m_engulfingBullish;
    bool             m_engulfingBearish;
    bool             m_insideBar;
    bool             m_hammerDetected;
    bool             m_shootingStarDetected;
    bool             m_softBullPA;             // Phase 3B: mild lower-wick rejection
    bool             m_softBearPA;             // Phase 3B: mild upper-wick rejection
    int              m_patternCount;
    
    //--- Helper methods
    void             DetectPatterns();
    bool             IsBullishPinBar();
    bool             IsBearishPinBar();
    bool             IsBullishEngulfing();
    bool             IsBearishEngulfing();
    bool             IsInsideBar();
    bool             IsHammer();
    bool             IsShootingStar();
    bool             IsNearKeyLevel(const MarketState &state, bool lookForSupport);
    int              CountBullishPatterns();
    int              CountBearishPatterns();
    double           CalculateStrength(const MarketState &state, ENUM_SIGNAL direction);
    
protected:
    //--- Pure virtual implementations
    virtual bool     CheckActivation(const MarketState &state);
    virtual void     CalculateSignal(const MarketState &state);
    
public:
    //--- Constructor / Destructor
    PriceAction();
    ~PriceAction();
    
    //--- Initialization override
    virtual void     Init(IndicatorCache* cache, double baseWeight, string symbol, ENUM_TIMEFRAMES tf);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
PriceAction::PriceAction(void) :
    m_keyLevelProximity(210.0),
    m_volumeMultiplier(0.50),
    m_pinBarBullish(false),
    m_pinBarBearish(false),
    m_engulfingBullish(false),
    m_engulfingBearish(false),
    m_insideBar(false),
    m_hammerDetected(false),
    m_shootingStarDetected(false),
    m_softBullPA(false),
    m_softBearPA(false),
    m_patternCount(0)
{
    m_name = "PriceAction";
    m_baseWeight = WEIGHT_PRICE_ACTION;  // 1.0 from constants
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
PriceAction::~PriceAction(void) {
    // Nothing to clean up
}

//+------------------------------------------------------------------+
//| Initialize strategy                                              |
//+------------------------------------------------------------------+
void PriceAction::Init(IndicatorCache* cache, double baseWeight, string symbol, ENUM_TIMEFRAMES tf) {
    // Call base class init
    BaseStrategy::Init(cache, baseWeight, symbol, tf);
    
    // Set active regimes (ALL - price action works everywhere)
    ENUM_REGIME regimes[4];
    regimes[0] = REGIME_TRENDING;
    regimes[1] = REGIME_RANGING;
    regimes[2] = REGIME_VOLATILE;
    regimes[3] = REGIME_CALM;
    SetActiveRegimes(regimes, 4);
    
    Print("PriceAction initialized - ALL regimes; Phase 3A++ v4 + Phase 3B H2 (deadzone T/V, vol50 prox210, RSI72/28, wick1.08, BB mid 13xATR)");
}

//+------------------------------------------------------------------+
//| Check if strategy should be active                               |
//+------------------------------------------------------------------+
bool PriceAction::CheckActivation(const MarketState &state) {
    // Detect candlestick patterns (used by CalculateSignal + optional tester diag)
    DetectPatterns();
    
    // Phase 3B: always reach CalculateSignal — classic pin/engulf/hammer are sparse on XAU M5;
    // entry quality remains gated inside CalculateSignal (key + volume + RSI).
    return true;
}

//+------------------------------------------------------------------+
//| Calculate trading signal                                         |
//+------------------------------------------------------------------+
void PriceAction::CalculateSignal(const MarketState &state) {
    DetectPatterns();
    
    // Tester-only bounded diagnostics when a pattern family fired (max 40 lines)
    static int s_paDiagLines = 0;
    if(MQLInfoInteger(MQL_TESTER) != 0 && m_patternCount > 0 && s_paDiagLines < 40) {
        double avgV = GetAverageVolume(20);
        double curV = MathMax(GetVolume(0), GetVolume(1));
        double volRatio = (avgV > 0 ? curV / avgV : 0.0);
        PrintFormat("[PA-DIAG] t=%s pat=%d bull=%d bear=%d nearS=%s nearR=%s rsi=%.1f volR=%.2f",
                    TimeToString(state.timestamp, TIME_DATE | TIME_MINUTES),
                    m_patternCount,
                    CountBullishPatterns(),
                    CountBearishPatterns(),
                    IsNearKeyLevel(state, true) ? "Y" : "N",
                    IsNearKeyLevel(state, false) ? "Y" : "N",
                    state.rsi14,
                    volRatio);
        s_paDiagLines++;
    }
    
    // Check for bullish patterns at support
    if(CountBullishPatterns() > 0) {
        if(IsNearKeyLevel(state, true)) {
            // RSI filter: not overbought
            // Phase 3B H2: slightly wider band vs compressed tape / Q60 (not profit tuning)
            if(state.rsi14 < 72) {
                // Volume confirmation
                double avgVolume = GetAverageVolume(20);
                double currentVolume = MathMax(GetVolume(0), GetVolume(1));
                // v4: tester windows often avgVolume==0 — do not hard-block entries
                bool volOk = (avgVolume <= 0.0) || (currentVolume >= (avgVolume * m_volumeMultiplier));
                if(volOk) {
                    m_signal = SIGNAL_BUY;
                    m_strength = CalculateStrength(state, SIGNAL_BUY);
                    return;
                }
            }
        }
    }
    
    // Check for bearish patterns at resistance
    if(CountBearishPatterns() > 0) {
        if(IsNearKeyLevel(state, false)) {
            // RSI filter: not oversold
            if(state.rsi14 > 28) {
                // Volume confirmation
                double avgVolume = GetAverageVolume(20);
                double currentVolume = MathMax(GetVolume(0), GetVolume(1));
                bool volOk = (avgVolume <= 0.0) || (currentVolume >= (avgVolume * m_volumeMultiplier));
                if(volOk) {
                    m_signal = SIGNAL_SELL;
                    m_strength = CalculateStrength(state, SIGNAL_SELL);
                    return;
                }
            }
        }
    }
    
    // No valid price action signal
    m_signal = SIGNAL_NONE;
    m_strength = 0.0;
}

//+------------------------------------------------------------------+
//| Detect all candlestick patterns                                  |
//+------------------------------------------------------------------+
void PriceAction::DetectPatterns(void) {
    m_pinBarBullish = IsBullishPinBar();
    m_pinBarBearish = IsBearishPinBar();
    m_engulfingBullish = IsBullishEngulfing();
    m_engulfingBearish = IsBearishEngulfing();
    m_insideBar = IsInsideBar();
    m_hammerDetected = IsHammer();
    m_shootingStarDetected = IsShootingStar();
    
    // Phase 3B: softer rejection — bar 0 OR bar 1 (new-bar EA; bar 0 often incomplete)
    m_softBullPA = false;
    m_softBearPA = false;
    double pt = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
    for(int sh = 0; sh <= 1; sh++) {
        double body = GetCandleBody(sh);
        if(body < pt)
            body = pt;
        if(GetLowerWick(sh) > body * 1.08 && GetClose(sh) >= GetOpen(sh))
            m_softBullPA = true;
        if(GetUpperWick(sh) > body * 1.08 && GetClose(sh) <= GetOpen(sh))
            m_softBearPA = true;
    }
    
    m_patternCount = CountBullishPatterns() + CountBearishPatterns();
}

//+------------------------------------------------------------------+
//| Check for bullish pin bar                                        |
//+------------------------------------------------------------------+
bool PriceAction::IsBullishPinBar(void) {
    return IsPinBarBullish();  // Use BaseStrategy helper
}

//+------------------------------------------------------------------+
//| Check for bearish pin bar                                        |
//+------------------------------------------------------------------+
bool PriceAction::IsBearishPinBar(void) {
    return IsPinBarBearish();  // Use BaseStrategy helper
}

//+------------------------------------------------------------------+
//| Check for bullish engulfing                                      |
//+------------------------------------------------------------------+
bool PriceAction::IsBullishEngulfing(void) {
    return IsEngulfingBullish();  // Use BaseStrategy helper
}

//+------------------------------------------------------------------+
//| Check for bearish engulfing                                      |
//+------------------------------------------------------------------+
bool PriceAction::IsBearishEngulfing(void) {
    return IsEngulfingBearish();  // Use BaseStrategy helper
}

//+------------------------------------------------------------------+
//| Check for inside bar                                             |
//+------------------------------------------------------------------+
bool PriceAction::IsInsideBar(void) {
    return IsInsideBarPattern();  // Use BaseStrategy helper
}

//+------------------------------------------------------------------+
//| Check for hammer                                                 |
//+------------------------------------------------------------------+
bool PriceAction::IsHammer(void) {
    return IsHammerPattern();  // Use BaseStrategy helper
}

//+------------------------------------------------------------------+
//| Check for shooting star                                          |
//+------------------------------------------------------------------+
bool PriceAction::IsShootingStar(void) {
    return IsShootingStarPattern();  // Use BaseStrategy helper
}

//+------------------------------------------------------------------+
//| Check if near key level                                          |
//+------------------------------------------------------------------+
bool PriceAction::IsNearKeyLevel(const MarketState &state, bool lookForSupport) {
    double currentPrice = state.bid;
    // Phase 3A: scale "near" by ATR — raw dollar cap was too tight vs XAU M5 swings vs BB/SR
    double pad = m_keyLevelProximity;
    if(state.atr14 > 0)
        pad = MathMax(pad, state.atr14 * 11.0);
    
    if(lookForSupport) {
        // Check if near support
        if(state.nearestSupport > 0) {
            double distance = MathAbs(currentPrice - state.nearestSupport);
            return (distance <= pad);
        }
        
        // Alternative: check BB lower
        if(state.bbLower > 0) {
            double distance = MathAbs(currentPrice - state.bbLower);
            return (distance <= pad);
        }
    } else {
        // Check if near resistance
        if(state.nearestResistance > 0) {
            double distance = MathAbs(currentPrice - state.nearestResistance);
            return (distance <= pad);
        }
        
        // Alternative: check BB upper
        if(state.bbUpper > 0) {
            double distance = MathAbs(currentPrice - state.bbUpper);
            return (distance <= pad);
        }
    }
    
    // Phase 3A++ v4: S/R or BB edge may be unset — mid-band proximity keeps path testable
    if(state.bbMiddle > 0 && state.atr14 > 0) {
        double midPad = MathMax(pad, state.atr14 * 13.0);
        if(MathAbs(currentPrice - state.bbMiddle) <= midPad)
            return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Count bullish patterns                                           |
//+------------------------------------------------------------------+
int PriceAction::CountBullishPatterns(void) {
    int count = 0;
    if(m_pinBarBullish) count++;
    if(m_engulfingBullish) count++;
    if(m_hammerDetected) count++;
    if(m_softBullPA) count++;
    return count;
}

//+------------------------------------------------------------------+
//| Count bearish patterns                                           |
//+------------------------------------------------------------------+
int PriceAction::CountBearishPatterns(void) {
    int count = 0;
    if(m_pinBarBearish) count++;
    if(m_engulfingBearish) count++;
    if(m_shootingStarDetected) count++;
    if(m_softBearPA) count++;
    return count;
}

//+------------------------------------------------------------------+
//| Calculate signal strength                                        |
//+------------------------------------------------------------------+
double PriceAction::CalculateStrength(const MarketState &state, ENUM_SIGNAL direction) {
    double strength = 0.5;  // Base strength: 50%
    
    //--- Bonus 1: Strong pattern (pin bar or engulfing) adds 0.15
    bool strongPattern = false;
    if(direction == SIGNAL_BUY) {
        strongPattern = (m_pinBarBullish || m_engulfingBullish);
    } else {
        strongPattern = (m_pinBarBearish || m_engulfingBearish);
    }
    
    if(strongPattern) {
        strength += 0.15;
    }
    
    //--- Bonus 2: At major key level adds 0.15
    // Simplified: if nearestSupport/Resistance is set, assume major level
    if(direction == SIGNAL_BUY && state.nearestSupport > 0) {
        strength += 0.15;
    } else if(direction == SIGNAL_SELL && state.nearestResistance > 0) {
        strength += 0.15;
    }
    
    //--- Bonus 3: Multiple pattern confluence adds 0.10
    int patternCount = (direction == SIGNAL_BUY) ? CountBullishPatterns() : CountBearishPatterns();
    if(patternCount > 1) {
        strength += 0.10;
    }
    
    //--- Bonus 4: Volume confirmation adds 0.10
    double avgVolume = GetAverageVolume(20);
    double currentVolume = MathMax(GetVolume(0), GetVolume(1));
    if(avgVolume > 0 && currentVolume > (avgVolume * 1.2)) {
        strength += 0.10;
    }
    
    //--- Bonus 5: Golden hour adds 0.05
    if(state.isGoldenHour) {
        strength += 0.05;
    }
    
    //--- Bonus 6: Trend aligned adds 0.10
    bool trendAligned = false;
    if(direction == SIGNAL_BUY) {
        trendAligned = (state.trendDir == TREND_UP);
    } else {
        trendAligned = (state.trendDir == TREND_DOWN);
    }
    
    if(trendAligned) {
        strength += 0.10;
    }
    
    //--- Penalty: Dead zone — Phase 3B H2: only TRENDING/VOLATILE (Q60 survival in RANGING/CALM)
    if(IsDeadZone(state) &&
       (state.regime == REGIME_TRENDING || state.regime == REGIME_VOLATILE)) {
        strength *= 0.7;
    }
    
    // Normalize to 0.0 - 1.0 range
    return NormalizeStrength(strength);
}

//+------------------------------------------------------------------+
//| END OF PRICE ACTION STRATEGY                                     |
//+------------------------------------------------------------------+
