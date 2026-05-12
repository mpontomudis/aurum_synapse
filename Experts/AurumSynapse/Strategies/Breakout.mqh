//+------------------------------------------------------------------+
//|                                                     Breakout.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Breakout Strategy - Swing Level Breaks + Volume Confirmation"

#include "BaseStrategy.mqh"

//+------------------------------------------------------------------+
//| Breakout Strategy                                                |
//|                                                                  |
//| Logic:                                                           |
//|   BUY:  Price breaks above swing high + confirmation             |
//|   SELL: Price breaks below swing low + confirmation              |
//|                                                                  |
//| Swing Detection: Last 50 bars, minimum 3 bars apart             |
//| Breakout Confirmation:                                           |
//|   - Close beyond level (not just wick)                           |
//|   - Sustained for 2 bars                                         |
//|   - Candle size > 0.5 × ATR                                      |
//|   - Volume > 1.2 × average                                       |
//|                                                                  |
//| Strength Calculation:                                            |
//|   Base: 0.5                                                      |
//|   +0.15 if volume spike > 1.5× average                           |
//|   +0.15 if candle size > ATR                                     |
//|   +0.10 if multiple swing levels broken                          |
//|   +0.10 if trend aligned                                         |
//|                                                                  |
//| Activation: TRENDING, VOLATILE, RANGING (Phase 3A+ — range breaks)|
//| Phase 3A: swing "nearest" = time-nearest pivot (array[0]);       |
//| confirmation uses max(bar0,bar1) vol/body (new-bar open timing).  |
//| Phase 3A+: IsActiveInCurrentRegime; atrRatio floor 0.10; SELL     |
//| bar-1 bearish (bull-tape noise filter).                            |
//| Phase 3B H2 continuity: SELL bar0|bar1 bearish; dead-zone str    |
//| penalty T/V only; volume gate skipped if avgVolume==0 (tester).   |
//+------------------------------------------------------------------+
class Breakout : public BaseStrategy {
private:
    //--- Strategy-specific settings
    int              m_swingLookback;        // Bars to scan for swings (50)
    int              m_swingMinDistance;     // Min bars between swings (3)
    double           m_volumeMultiplier;     // Volume vs avg (rehab ~1.05)
    double           m_candleSizeMultiplier; // Body vs ATR (rehab ~0.35)
    int              m_confirmBars;          // Bars to confirm breakout (2)
    
    //--- Swing level tracking
    double           m_swingHighs[10];       // Last 10 swing highs
    double           m_swingLows[10];        // Last 10 swing lows
    int              m_swingHighCount;
    int              m_swingLowCount;
    
    //--- Breakout tracking
    bool             m_breakoutInProgress;
    int              m_breakoutConfirmCount;
    ENUM_SIGNAL      m_breakoutDirection;
    
    //--- Helper methods
    void             FindSwingHighs();
    void             FindSwingLows();
    bool             IsBreakoutConfirmed(const MarketState &state, ENUM_SIGNAL direction);
    double           CalculateAverageVolume(int periods);
    bool             IsBullishBreakout(const MarketState &state);
    bool             IsBearishBreakout(const MarketState &state);
    double           CalculateStrength(const MarketState &state, ENUM_SIGNAL direction);
    double           GetNearestSwingHigh();
    double           GetNearestSwingLow();
    
protected:
    //--- Pure virtual implementations
    virtual bool     CheckActivation(const MarketState &state);
    virtual void     CalculateSignal(const MarketState &state);
    
public:
    //--- Constructor / Destructor
    Breakout();
    ~Breakout();
    
    //--- Initialization override
    virtual void     Init(IndicatorCache* cache, double baseWeight, string symbol, ENUM_TIMEFRAMES tf);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
Breakout::Breakout(void) :
    m_swingLookback(50),
    m_swingMinDistance(3),
    m_volumeMultiplier(1.05),
    m_candleSizeMultiplier(0.35),
    m_confirmBars(2),
    m_swingHighCount(0),
    m_swingLowCount(0),
    m_breakoutInProgress(false),
    m_breakoutConfirmCount(0),
    m_breakoutDirection(SIGNAL_NONE)
{
    m_name = "Breakout";
    m_baseWeight = WEIGHT_BREAKOUT;  // 1.1 from constants
    
    // Initialize swing arrays
    ArrayInitialize(m_swingHighs, 0);
    ArrayInitialize(m_swingLows, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
Breakout::~Breakout(void) {
    // Nothing to clean up
}

//+------------------------------------------------------------------+
//| Initialize strategy                                              |
//+------------------------------------------------------------------+
void Breakout::Init(IndicatorCache* cache, double baseWeight, string symbol, ENUM_TIMEFRAMES tf) {
    // Call base class init
    BaseStrategy::Init(cache, baseWeight, symbol, tf);
    
    // Phase 3A+: RANGING included — swing breaks in consolidation tape (H2 participation)
    ENUM_REGIME regimes[3];
    regimes[0] = REGIME_TRENDING;
    regimes[1] = REGIME_VOLATILE;
    regimes[2] = REGIME_RANGING;
    SetActiveRegimes(regimes, 3);
    
    Print("Breakout initialized - TRENDING+VOLATILE+RANGING; Phase 3B H2 cont. (SELL bearish bar0|1; deadZone str T/V; vol skip if avg=0)");
}

//+------------------------------------------------------------------+
//| Check if strategy should be active                               |
//+------------------------------------------------------------------+
bool Breakout::CheckActivation(const MarketState &state) {
    if(!IsActiveInCurrentRegime(state))
        return false;
    
    // Need some volatility vs average (0.10 — Phase 3A+ slight relax vs 0.12 for marginal H2/vol tape)
    if(state.atrRatio < 0.10) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate trading signal                                         |
//+------------------------------------------------------------------+
void Breakout::CalculateSignal(const MarketState &state) {
    // Find swing levels
    FindSwingHighs();
    FindSwingLows();
    
    // Check for bullish breakout
    if(IsBullishBreakout(state)) {
        if(IsBreakoutConfirmed(state, SIGNAL_BUY)) {
            m_signal = SIGNAL_BUY;
            m_strength = CalculateStrength(state, SIGNAL_BUY);
            return;
        }
    }
    
    // Check for bearish breakout — Phase 3B H2: bar0|bar1 bearish (parity SupplyDemand / MR)
    if(IsBearishBreakout(state)) {
        if((IsBearishCandle(1) || IsBearishCandle(0)) && IsBreakoutConfirmed(state, SIGNAL_SELL)) {
            m_signal = SIGNAL_SELL;
            m_strength = CalculateStrength(state, SIGNAL_SELL);
            return;
        }
    }
    
    // No valid breakout
    m_signal = SIGNAL_NONE;
    m_strength = 0.0;
}

//+------------------------------------------------------------------+
//| Find swing high levels (local peaks)                             |
//+------------------------------------------------------------------+
void Breakout::FindSwingHighs(void) {
    m_swingHighCount = 0;
    int lastSwingBar = -m_swingMinDistance;
    
    // Scan bars for swing highs
    for(int i = m_swingMinDistance; i < m_swingLookback - m_swingMinDistance; i++) {
        double currentHigh = GetHigh(i);
        bool isSwingHigh = true;
        
        // Check if this is a local peak
        for(int j = 1; j <= m_swingMinDistance; j++) {
            if(GetHigh(i - j) >= currentHigh || GetHigh(i + j) >= currentHigh) {
                isSwingHigh = false;
                break;
            }
        }
        
        // If swing high found and far enough from last one
        if(isSwingHigh && (i - lastSwingBar) >= m_swingMinDistance) {
            if(m_swingHighCount < 10) {
                m_swingHighs[m_swingHighCount] = currentHigh;
                m_swingHighCount++;
                lastSwingBar = i;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Find swing low levels (local troughs)                            |
//+------------------------------------------------------------------+
void Breakout::FindSwingLows(void) {
    m_swingLowCount = 0;
    int lastSwingBar = -m_swingMinDistance;
    
    // Scan bars for swing lows
    for(int i = m_swingMinDistance; i < m_swingLookback - m_swingMinDistance; i++) {
        double currentLow = GetLow(i);
        bool isSwingLow = true;
        
        // Check if this is a local trough
        for(int j = 1; j <= m_swingMinDistance; j++) {
            if(GetLow(i - j) <= currentLow || GetLow(i + j) <= currentLow) {
                isSwingLow = false;
                break;
            }
        }
        
        // If swing low found and far enough from last one
        if(isSwingLow && (i - lastSwingBar) >= m_swingMinDistance) {
            if(m_swingLowCount < 10) {
                m_swingLows[m_swingLowCount] = currentLow;
                m_swingLowCount++;
                lastSwingBar = i;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check if bullish breakout exists                                 |
//+------------------------------------------------------------------+
bool Breakout::IsBullishBreakout(const MarketState &state) {
    if(m_swingHighCount == 0) return false;
    
    double currentClose = GetClose(0);
    double nearestHigh = GetNearestSwingHigh();
    
    if(nearestHigh == 0) return false;
    
    // Price must close above swing high
    return (currentClose > nearestHigh);
}

//+------------------------------------------------------------------+
//| Check if bearish breakout exists                                 |
//+------------------------------------------------------------------+
bool Breakout::IsBearishBreakout(const MarketState &state) {
    if(m_swingLowCount == 0) return false;
    
    double currentClose = GetClose(0);
    double nearestLow = GetNearestSwingLow();
    
    if(nearestLow == 0) return false;
    
    // Price must close below swing low
    return (currentClose < nearestLow);
}

//+------------------------------------------------------------------+
//| Confirm breakout with volume and candle size                     |
//+------------------------------------------------------------------+
bool Breakout::IsBreakoutConfirmed(const MarketState &state, ENUM_SIGNAL direction) {
    double atr = state.atr14;
    if(atr == 0) return false;
    
    // 1. Candle size: max(bar0, bar1) — on new-bar open, body(0) is often still tiny
    double candleSize = MathMax(GetCandleBody(0), GetCandleBody(1));
    if(candleSize < (atr * m_candleSizeMultiplier)) {
        return false;
    }
    
    // 2. Volume: max(bar0, bar1) vs average — bar0 tick volume often near zero at bar start
    double avgVolume = CalculateAverageVolume(20);
    double currentVolume = MathMax(GetVolume(0), GetVolume(1));
    if(avgVolume > 0.0 && currentVolume < (avgVolume * m_volumeMultiplier)) {
        return false;
    }
    
    // 3. Check previous bar also broke the level (2-bar confirmation)
    double previousClose = GetClose(1);
    
    if(direction == SIGNAL_BUY) {
        double nearestHigh = GetNearestSwingHigh();
        if(previousClose <= nearestHigh) {
            return false;  // Previous bar didn't break level
        }
    } else if(direction == SIGNAL_SELL) {
        double nearestLow = GetNearestSwingLow();
        if(previousClose >= nearestLow) {
            return false;  // Previous bar didn't break level
        }
    }
    
    // All confirmations met
    return true;
}

//+------------------------------------------------------------------+
//| Calculate average volume over periods                            |
//+------------------------------------------------------------------+
double Breakout::CalculateAverageVolume(int periods) {
    double sum = 0;
    for(int i = 1; i <= periods; i++) {  // Start from 1 to exclude current bar
        sum += GetVolume(i);
    }
    return (periods > 0) ? sum / periods : 0;
}

//+------------------------------------------------------------------+
//| Get nearest swing high                                           |
//+------------------------------------------------------------------+
double Breakout::GetNearestSwingHigh(void) {
    if(m_swingHighCount == 0) return 0;
    
    // First pivot in scan order = time-nearest (was: max = hardest peak in window)
    return m_swingHighs[0];
}

//+------------------------------------------------------------------+
//| Get nearest swing low                                            |
//+------------------------------------------------------------------+
double Breakout::GetNearestSwingLow(void) {
    if(m_swingLowCount == 0) return 0;
    
    // First pivot = time-nearest (was: min = deepest trough in window)
    return m_swingLows[0];
}

//+------------------------------------------------------------------+
//| Calculate signal strength                                        |
//+------------------------------------------------------------------+
double Breakout::CalculateStrength(const MarketState &state, ENUM_SIGNAL direction) {
    double strength = 0.5;  // Base strength: 50%
    
    double atr = state.atr14;
    if(atr == 0) return strength;
    
    //--- Bonus 1: Strong volume spike (> 1.5× average) adds 0.15
    double avgVolume = CalculateAverageVolume(20);
    if(avgVolume > 0) {
        double currentVolume = MathMax(GetVolume(0), GetVolume(1));
        if(currentVolume > (avgVolume * 1.5)) {
            strength += 0.15;
        }
    }
    
    //--- Bonus 2: Large candle (> ATR) adds 0.15 — max(bar0,bar1) for new-bar parity
    double candleSize = MathMax(GetCandleBody(0), GetCandleBody(1));
    if(candleSize > atr) {
        strength += 0.15;
    }
    
    //--- Bonus 3: Multiple levels broken adds 0.10
    int levelsBroken = 0;
    double currentClose = GetClose(0);
    
    if(direction == SIGNAL_BUY) {
        for(int i = 0; i < m_swingHighCount; i++) {
            if(currentClose > m_swingHighs[i]) levelsBroken++;
        }
    } else {
        for(int i = 0; i < m_swingLowCount; i++) {
            if(currentClose < m_swingLows[i]) levelsBroken++;
        }
    }
    
    if(levelsBroken > 1) {
        strength += 0.10;
    }
    
    //--- Bonus 4: Trend aligned adds 0.10
    bool trendAligned = false;
    if(direction == SIGNAL_BUY) {
        trendAligned = (state.trendDir == TREND_UP);
    } else {
        trendAligned = (state.trendDir == TREND_DOWN);
    }
    
    if(trendAligned) {
        strength += 0.10;
    }
    
    //--- Bonus 5: Golden hour adds 0.05
    if(state.isGoldenHour) {
        strength += 0.05;
    }
    
    //--- Penalty: Dead zone — Phase 3B H2: only TRENDING/VOLATILE (RANGING home tape; Q60 survival)
    if(IsDeadZone(state) &&
       (state.regime == REGIME_TRENDING || state.regime == REGIME_VOLATILE)) {
        strength *= 0.7;
    }
    
    // Normalize to 0.0 - 1.0 range
    return NormalizeStrength(strength);
}

//+------------------------------------------------------------------+
//| END OF BREAKOUT STRATEGY                                         |
//+------------------------------------------------------------------+
