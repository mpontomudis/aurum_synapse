//+------------------------------------------------------------------+
//|                                                   SmartMoney.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Smart Money Concepts - BOS/CHoCH + Order Blocks + Market Structure"

#include "BaseStrategy.mqh"

//+------------------------------------------------------------------+
//| Smart Money Concepts Strategy                                    |
//|                                                                  |
//| Logic:                                                           |
//|   BUY:  Bullish BOS + market structure shift                     |
//|   SELL: Bearish BOS + market structure shift                     |
//|                                                                  |
//| Core Concepts:                                                   |
//|   - Break of Structure (BOS): Price breaks previous high/low     |
//|   - Change of Character (CHoCH): Trend reversal signal           |
//|   - Order Blocks: Institutional accumulation/distribution zones  |
//|   - Market Structure: Higher Highs/Lows or Lower Lows/Highs      |
//|                                                                  |
//| Entry Conditions:                                                |
//|   BUY:                                                           |
//|     - Bullish BOS detected (break above previous high)           |
//|     - Market structure shows HH/HL pattern                       |
//|     - Price retraces to bullish order block                      |
//|     - Momentum confirmation (RSI > 45, MACD bullish)             |
//|                                                                  |
//|   SELL:                                                          |
//|     - Bearish BOS detected (break below previous low)            |
//|     - Market structure shows LL/LH pattern                       |
//|     - Price retraces to bearish order block                      |
//|     - Momentum confirmation (RSI < 55, MACD bearish)             |
//|                                                                  |
//| Strength Calculation:                                            |
//|   Base: 0.5                                                      |
//|   +0.20 if strong BOS (>2× ATR move)                             |
//|   +0.15 if clear market structure (HH/HL or LL/LH confirmed)     |
//|   +0.10 if order block reaction (within last 10 bars)            |
//|   +0.10 if momentum aligned (MACD + RSI)                         |
//|   +0.05 if golden hour                                           |
//|                                                                  |
//| Activation: trending/volatile/ranging/calm + primed swing refs   |
//| Phase 3A+: STRUCTURE_NONE + BOS; Phase 3A++: bar0|1 sweep; CALM on. |
//| Phase 3B H2: dead-zone penalty T/V only; OB retest 1.12×ATR; OB age|
//| +2; bear sweep/OB allow HH_HL (bull-tape fakeout path).            |
//+------------------------------------------------------------------+
class SmartMoney : public BaseStrategy {
private:
    //--- Strategy-specific settings
    int              m_lookbackBars;           // Bars to scan for structure (50)
    double           m_bosThreshold;           // BOS min break vs ATR (Phase 3A++ ~0.45)
    int              m_structurePeriod;        // Period for structure analysis (20)
    int              m_orderBlockMaxAge;       // Max age of order block (Phase 3B: 12)
    
    //--- Market structure tracking
    double           m_lastHigh;
    double           m_lastLow;
    int              m_lastHighBar;
    int              m_lastLowBar;
    bool             m_bosDetected;
    bool             m_bosBullish;
    double           m_orderBlockPrice;
    int              m_orderBlockAge;
    double           m_bearOBPrice;        // Phase 3A+ short-side: separate bearish order block
    int              m_bearOBAge;
    
    //--- Helper methods
    void             UpdateMarketStructure();
    bool             DetectBullishBOS();
    bool             DetectBearishBOS();
    bool             DetectBearishSweep();     // Phase 3A+ v5: liquidity sweep above swing high → sell
    bool             DetectBullishSweep();     // symmetric: sweep below swing low → buy
    bool             IsAtOrderBlock(double price, bool bullish);
    bool             HasMomentumConfirmation(const MarketState &state, bool bullish);
    double           GetBOSStrength(double breakDistance, double atr);
    double           CalculateStrength(const MarketState &state, ENUM_SIGNAL direction);
    
protected:
    //--- Pure virtual implementations
    virtual bool     CheckActivation(const MarketState &state);
    virtual void     CalculateSignal(const MarketState &state);
    
public:
    //--- Constructor / Destructor
    SmartMoney();
    ~SmartMoney();
    
    //--- Initialization override
    virtual void     Init(IndicatorCache* cache, double baseWeight, string symbol, ENUM_TIMEFRAMES tf);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
SmartMoney::SmartMoney(void) :
    m_lookbackBars(50),
    // Phase 3A+: density rehab — BOS vs 20-bar extremes was starving trades at Q60.
    // Tighten the swing window and reduce the ATR break requirement to get statistically usable n.
    m_bosThreshold(0.25),
    m_structurePeriod(12),
    m_orderBlockMaxAge(12),
    m_lastHigh(0),
    m_lastLow(0),
    m_lastHighBar(0),
    m_lastLowBar(0),
    m_bosDetected(false),
    m_bosBullish(false),
    m_orderBlockPrice(0),
    m_orderBlockAge(0),
    m_bearOBPrice(0),
    m_bearOBAge(0)
{
    m_name = "SmartMoney";
    m_baseWeight = WEIGHT_SMART_MONEY;  // 1.3 from constants
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
SmartMoney::~SmartMoney(void) {
    // Nothing to clean up
}

//+------------------------------------------------------------------+
//| Initialize strategy                                              |
//+------------------------------------------------------------------+
void SmartMoney::Init(IndicatorCache* cache, double baseWeight, string symbol, ENUM_TIMEFRAMES tf) {
    // Call base class init
    BaseStrategy::Init(cache, baseWeight, symbol, tf);
    
    // Phase 3A++: include CALM — otherwise long CALM spans silence the module
    ENUM_REGIME regimes[4];
    regimes[0] = REGIME_TRENDING;
    regimes[1] = REGIME_VOLATILE;
    regimes[2] = REGIME_RANGING;
    regimes[3] = REGIME_CALM;
    SetActiveRegimes(regimes, 4);
    
    Print("SmartMoney initialized - T/V/R/C + Phase 3B H2: OB retest 1.12xATR, OB age 12, deadzone T/V only, bear sweep/OB+HH_HL");
}

//+------------------------------------------------------------------+
//| Check if strategy should be active                               |
//+------------------------------------------------------------------+
bool SmartMoney::CheckActivation(const MarketState &state) {
    if(!IsActiveInCurrentRegime(state))
        return false;
    
    // Phase 3A+: do NOT block when ADX>25 (TRENDING) but EMA stack is flat (STRUCTURE_NONE) —
    // that combination is common on XAU M5 and previously skipped CalculateSignal entirely.
    
    // Prime swing references for Detect* inside CalculateSignal.
    // IMPORTANT: UpdateMarketStructure() clears m_bosDetected; never return that here
    // before CalculateSignal runs (previous code caused permanent silence).
    UpdateMarketStructure();
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate trading signal                                         |
//+------------------------------------------------------------------+
void SmartMoney::CalculateSignal(const MarketState &state) {
    double atr = GetATR();

    // Phase 3A+ short-side: bearish OB retest (separate tracking, not overwritten by bullish BOS)
    if(m_bearOBPrice > 0 && m_bearOBAge <= m_orderBlockMaxAge && atr > 0) {
        bool structOk = (state.structure == STRUCTURE_LL_LH || state.structure == STRUCTURE_NONE ||
                         state.structure == STRUCTURE_HH_HL);
        if(structOk && MathAbs(state.bid - m_bearOBPrice) < atr * 1.12 && HasMomentumConfirmation(state, false)) {
            m_signal = SIGNAL_SELL;
            m_strength = CalculateStrength(state, SIGNAL_SELL);
            return;
        }
    }

    // Bullish OB retest (uses m_orderBlockPrice set by bullish BOS)
    if(m_orderBlockPrice > 0 && m_orderBlockAge <= m_orderBlockMaxAge && m_bosBullish && atr > 0) {
        bool structOk = (state.structure == STRUCTURE_HH_HL || state.structure == STRUCTURE_NONE);
        if(structOk && MathAbs(state.bid - m_orderBlockPrice) < atr * 1.12 && HasMomentumConfirmation(state, true)) {
            m_signal = SIGNAL_BUY;
            m_strength = CalculateStrength(state, SIGNAL_BUY);
            return;
        }
    }

    // Phase 3A+ v5: liquidity sweep sells (swept swing high, rejected back below)
    if(DetectBearishSweep()) {
        bool structOk = (state.structure == STRUCTURE_LL_LH || state.structure == STRUCTURE_NONE ||
                         state.structure == STRUCTURE_HH_HL);
        if(structOk && HasMomentumConfirmation(state, false)) {
            m_signal = SIGNAL_SELL;
            m_strength = CalculateStrength(state, SIGNAL_SELL);
            m_bearOBPrice = GetHigh(1);
            m_bearOBAge = 0;
            return;
        }
    }

    // Liquidity sweep buys (swept swing low, rejected back above)
    if(DetectBullishSweep()) {
        bool structOk = (state.structure == STRUCTURE_HH_HL || state.structure == STRUCTURE_NONE);
        if(structOk && HasMomentumConfirmation(state, true)) {
            m_signal = SIGNAL_BUY;
            m_strength = CalculateStrength(state, SIGNAL_BUY);
            m_orderBlockPrice = GetLow(1);
            m_orderBlockAge = 0;
            m_bosBullish = true;
            return;
        }
    }

    // Fresh bearish BOS (checked before bullish to avoid bull-trend priority starvation)
    if(DetectBearishBOS()) {
        bool structOk = (state.structure == STRUCTURE_LL_LH) || (state.structure == STRUCTURE_NONE);
        if(structOk && HasMomentumConfirmation(state, false)) {
            m_signal = SIGNAL_SELL;
            m_strength = CalculateStrength(state, SIGNAL_SELL);
            return;
        }
    }

    // Fresh bullish BOS
    if(DetectBullishBOS()) {
        bool structOk = (state.structure == STRUCTURE_HH_HL) || (state.structure == STRUCTURE_NONE);
        if(structOk && HasMomentumConfirmation(state, true)) {
            m_signal = SIGNAL_BUY;
            m_strength = CalculateStrength(state, SIGNAL_BUY);
            return;
        }
    }

    m_signal = SIGNAL_NONE;
    m_strength = 0.0;
}

//+------------------------------------------------------------------+
//| Update market structure (highs and lows)                         |
//+------------------------------------------------------------------+
void SmartMoney::UpdateMarketStructure(void) {
    m_bosDetected = false;
    m_orderBlockAge++;
    m_bearOBAge++;
    
    // Find recent significant high
    double recentHigh = GetHigh(1);
    int highBar = 1;
    for(int i = 2; i <= m_structurePeriod; i++) {
        double high = GetHigh(i);
        if(high > recentHigh) {
            recentHigh = high;
            highBar = i;
        }
    }
    
    // Find recent significant low
    double recentLow = GetLow(1);
    int lowBar = 1;
    for(int i = 2; i <= m_structurePeriod; i++) {
        double low = GetLow(i);
        if(low < recentLow) {
            recentLow = low;
            lowBar = i;
        }
    }
    
    // Update structure
    m_lastHigh = recentHigh;
    m_lastLow = recentLow;
    m_lastHighBar = highBar;
    m_lastLowBar = lowBar;
}

//+------------------------------------------------------------------+
//| Detect bullish Break of Structure                                |
//+------------------------------------------------------------------+
bool SmartMoney::DetectBullishBOS(void) {
    // New-bar OnTick: bar 0 is forming — include last closed bar wick/body in sweep
    double currentHigh = MathMax(GetHigh(0), GetHigh(1));
    double atr = GetATR();
    
    if(atr == 0 || m_lastHigh == 0) return false;
    
    // Price must break above swing high (recent window from UpdateMarketStructure)
    if(currentHigh > m_lastHigh) {
        double breakDistance = currentHigh - m_lastHigh;
        
        if(breakDistance > (atr * m_bosThreshold)) {
            m_bosDetected = true;
            m_bosBullish = true;
            
            // Mark order block (the consolidation before BOS)
            m_orderBlockPrice = GetLow(m_lastHighBar);
            m_orderBlockAge = 0;
            
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Detect bearish Break of Structure                                |
//+------------------------------------------------------------------+
bool SmartMoney::DetectBearishBOS(void) {
    double currentLow = MathMin(GetLow(0), GetLow(1));
    double atr = GetATR();
    
    if(atr == 0 || m_lastLow == 0) return false;
    
    if(currentLow < m_lastLow) {
        double breakDistance = m_lastLow - currentLow;
        
        if(breakDistance > (atr * m_bosThreshold)) {
            m_bosDetected = true;
            m_bosBullish = false;
            
            double obPrice = GetHigh(m_lastLowBar);
            m_orderBlockPrice = obPrice;
            m_orderBlockAge = 0;
            m_bearOBPrice = obPrice;
            m_bearOBAge = 0;
            
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Detect bearish liquidity sweep (sell signal in bull markets)      |
//| Bar 1 swept above the 12-bar swing high then closed back below   |
//| it with a bearish body — classic stop-hunt / fake breakout.      |
//+------------------------------------------------------------------+
bool SmartMoney::DetectBearishSweep(void) {
    if(m_lastHigh == 0) return false;
    
    double high1  = GetHigh(1);
    double close1 = GetClose(1);
    double open1  = GetOpen(1);
    double low1   = GetLow(1);
    double range1 = high1 - low1;
    
    if(range1 <= 0) return false;
    
    bool sweptHigh    = (high1 > m_lastHigh);
    bool closedBelow  = (close1 < m_lastHigh);
    bool bearishClose = (close1 < open1);
    bool upperWick    = (high1 - MathMax(close1, open1)) > range1 * 0.33;
    
    return (sweptHigh && closedBelow && bearishClose && upperWick);
}

//+------------------------------------------------------------------+
//| Detect bullish liquidity sweep (symmetric — sweep below low)     |
//+------------------------------------------------------------------+
bool SmartMoney::DetectBullishSweep(void) {
    if(m_lastLow == 0) return false;
    
    double high1  = GetHigh(1);
    double close1 = GetClose(1);
    double open1  = GetOpen(1);
    double low1   = GetLow(1);
    double range1 = high1 - low1;
    
    if(range1 <= 0) return false;
    
    bool sweptLow     = (low1 < m_lastLow);
    bool closedAbove  = (close1 > m_lastLow);
    bool bullishClose = (close1 > open1);
    bool lowerWick    = (MathMin(close1, open1) - low1) > range1 * 0.33;
    
    return (sweptLow && closedAbove && bullishClose && lowerWick);
}

//+------------------------------------------------------------------+
//| Check if price is at order block                                 |
//+------------------------------------------------------------------+
bool SmartMoney::IsAtOrderBlock(double price, bool bullish) {
    if(m_orderBlockAge > m_orderBlockMaxAge) return false;
    if(m_orderBlockPrice == 0) return false;
    
    double atr = GetATR();
    if(atr == 0) return false;
    
    // Price should be near order block (within 1× ATR)
    double distance = MathAbs(price - m_orderBlockPrice);
    return (distance < atr);
}

//+------------------------------------------------------------------+
//| Check momentum confirmation                                      |
//+------------------------------------------------------------------+
bool SmartMoney::HasMomentumConfirmation(const MarketState &state, bool bullish) {
    // Phase 3A++: OR gate — strict AND vetoed many valid BOS bars (RSI vs MACD phase lag)
    if(bullish) {
        const bool rsiOk = (state.rsi14 >= 32.0);
        const bool macdOk = (state.macdMain >= state.macdSignal);
        return (rsiOk || macdOk);
    } else {
        const bool rsiOk = (state.rsi14 <= 68.0);
        const bool macdOk = (state.macdMain <= state.macdSignal);
        return (rsiOk || macdOk);
    }
}

//+------------------------------------------------------------------+
//| Get BOS strength multiplier                                      |
//+------------------------------------------------------------------+
double SmartMoney::GetBOSStrength(double breakDistance, double atr) {
    if(atr == 0) return 1.0;
    
    // Strong BOS = >2× ATR
    double multiplier = breakDistance / atr;
    return (multiplier > 2.0) ? 1.0 : 0.0;
}

//+------------------------------------------------------------------+
//| Calculate signal strength                                        |
//+------------------------------------------------------------------+
double SmartMoney::CalculateStrength(const MarketState &state, ENUM_SIGNAL direction) {
    double strength = 0.5;  // Base strength: 50%
    
    double atr = state.atr14;
    if(atr == 0) return strength;
    
    //--- Bonus 1: Strong BOS (>2× ATR) adds 0.20
    double breakDistance = 0;
    if(direction == SIGNAL_BUY && m_lastHigh > 0) {
        breakDistance = GetHigh(0) - m_lastHigh;
    } else if(direction == SIGNAL_SELL && m_lastLow > 0) {
        breakDistance = m_lastLow - GetLow(0);
    }
    
    if(breakDistance > (atr * 2.0)) {
        strength += 0.20;
    }
    
    //--- Bonus 2: Clear market structure adds 0.15
    if(state.structure == STRUCTURE_HH_HL || state.structure == STRUCTURE_LL_LH) {
        strength += 0.15;
    }
    
    //--- Bonus 3: Order block reaction adds 0.10
    if(m_orderBlockAge <= m_orderBlockMaxAge) {
        strength += 0.10;
    }
    
    //--- Bonus 4: Momentum aligned (MACD + RSI) adds 0.10
    bool momentumAligned = HasMomentumConfirmation(state, direction == SIGNAL_BUY);
    if(momentumAligned) {
        strength += 0.10;
    }
    
    //--- Bonus 5: Golden hour adds 0.05
    if(state.isGoldenHour) {
        strength += 0.05;
    }
    
    //--- Bonus 6: Trend confirmation adds 0.10
    bool trendAligned = false;
    if(direction == SIGNAL_BUY) {
        trendAligned = (state.trendDir == TREND_UP);
    } else {
        trendAligned = (state.trendDir == TREND_DOWN);
    }
    
    if(trendAligned) {
        strength += 0.10;
    }
    
    //--- Penalty: Dead zone — Phase 3B: only in TRENDING/VOLATILE (H2/session strength vs Q60 in RANGING/CALM)
    if(IsDeadZone(state) &&
       (state.regime == REGIME_TRENDING || state.regime == REGIME_VOLATILE)) {
        strength *= 0.7;
    }
    
    // Normalize to 0.0 - 1.0 range
    return NormalizeStrength(strength);
}

//+------------------------------------------------------------------+
//| END OF SMART MONEY STRATEGY                                      |
//+------------------------------------------------------------------+
