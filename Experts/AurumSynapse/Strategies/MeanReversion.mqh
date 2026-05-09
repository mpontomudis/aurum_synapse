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
//|     - RSI > 70 (overbought)                                      |
//|     - Price above EMA21                                          |
//|                                                                  |
//| Strength Calculation:                                            |
//|   Base: 0.5                                                      |
//|   +0.15 if RSI extreme (<20 or >80)                              |
//|   +0.15 if price beyond BB (not just near)                       |
//|   +0.10 if low volatility (ATR ratio < 0.8)                      |
//|   +0.10 if multiple touches of BB (consolidation)                |
//|   +0.05 if golden hour                                           |
//|   -0.30 penalty if ADX > 25 (trending, not ranging)              |
//|                                                                  |
//| Activation: RANGING or CALM regimes                              |
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
    m_rsiOverbought(55.0),         // PHASE 1: Relaxed from 70 to 55
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
    
    // Set active regimes (RANGING and CALM)
    ENUM_REGIME regimes[2];
    regimes[0] = REGIME_RANGING;
    regimes[1] = REGIME_CALM;
    SetActiveRegimes(regimes, 2);
    
    Print("MeanReversion initialized - Active in RANGING and CALM regimes");
}

//+------------------------------------------------------------------+
//| Check if strategy should be active                               |
//+------------------------------------------------------------------+
bool MeanReversion::CheckActivation(const MarketState &state) {
    // Active in RANGING or CALM regimes
    if(state.regime != REGIME_RANGING && state.regime != REGIME_CALM) {
        return false;
    }
    
    // PHASE 1 TESTING: ADX check temporarily disabled to allow more signals
    // Will re-enable after Phase 1 validation completes
    /*
    // Don't trade in strong trends (ADX > 30)
    if(state.adx > 30) {
        return false;
    }
    */
    
    // Need visible range (Bollinger Bands should be defined)
    double bbWidth = state.bbUpper - state.bbLower;
    if(bbWidth <= 0 || state.bbMiddle <= 0) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate trading signal                                         |
//+------------------------------------------------------------------+
void MeanReversion::CalculateSignal(const MarketState &state) {
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
            if(state.bid > state.ema21) {  // Price above short-term EMA
                m_signal = SIGNAL_SELL;
                m_strength = CalculateStrength(state, SIGNAL_SELL);
                return;
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
    
    //--- Penalty 1: ADX > 25 (trending, not ideal for mean reversion) reduces by 30%
    if(state.adx > 25) {
        strength *= 0.7;
    }
    
    //--- Penalty 2: Dead zone reduces strength
    if(IsDeadZone(state)) {
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
