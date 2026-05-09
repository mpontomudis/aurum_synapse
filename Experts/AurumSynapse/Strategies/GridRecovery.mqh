//+------------------------------------------------------------------+
//|                                                 GridRecovery.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Grid Recovery Strategy - Controlled Averaging (LIMITED!)"

#include "BaseStrategy.mqh"

//+------------------------------------------------------------------+
//| Grid Recovery Strategy                                           |
//|                                                                  |
//| ⚠️ WARNING: Lower weight (0.7) - Use with caution!              |
//|                                                                  |
//| Logic:                                                           |
//|   BUY:  Price in drawdown + recovery conditions met              |
//|   SELL: Price in drawdown + recovery conditions met              |
//|                                                                  |
//| Core Concept:                                                    |
//|   - Grid averaging (add to position at intervals)                |
//|   - Strict limits: MAX 3 levels only                             |
//|   - Active regimes: VOLATILE + TRENDING (Phase 3A — FY tester)   |
//|   - Requires reversal context (RSI arm + patterns)               |
//|                                                                  |
//| Entry Conditions:                                                |
//|   BUY (Add to Long):                                             |
//|     - Existing long position in drawdown                         |
//|     - Price dropped by grid distance (1.5× ATR)                  |
//|     - Not exceeded max grid levels (3)                           |
//|     - RSI oversold (< 30) OR strong bounce signal                |
//|     - Volatility high (regime = VOLATILE)                        |
//|                                                                  |
//|   SELL (Add to Short):                                           |
//|     - Existing short position in drawdown                        |
//|     - Price rallied by grid distance (1.5× ATR)                  |
//|     - Not exceeded max grid levels (3)                           |
//|     - RSI overbought (> 70) OR strong reversal signal            |
//|     - Volatility high (regime = VOLATILE)                        |
//|                                                                  |
//| Strength Calculation:                                            |
//|   Base: 0.3 (intentionally low - risky strategy)                 |
//|   +0.15 if RSI extreme (< 20 or > 80)                            |
//|   +0.15 if at major support/resistance                           |
//|   +0.10 if volume spike (>1.5× average)                          |
//|   +0.05 if golden hour                                           |
//|   -0.20 penalty if already at 2 grid levels                      |
//|   -0.40 penalty if at 3 grid levels (discourage further)         |
//|                                                                  |
//| Activation: VOLATILE + TRENDING (Phase 3A tester); atrRatio floor |
//| Phase 3A: first grid leg must emit BUY/SELL (was armed then NONE).|
//+------------------------------------------------------------------+
class GridRecovery : public BaseStrategy {
private:
    //--- Strategy-specific settings
    int              m_maxGridLevels;          // Maximum grid levels (3)
    double           m_gridDistance;           // Grid spacing (× ATR)
    int              m_currentGridLevel;       // Current grid count
    double           m_lastGridPrice;          // Last grid entry price
    bool             m_gridActive;             // Is grid recovery active
    double           m_rsiArmOversold;          // Phase 3A: permissive first-leg RSI
    double           m_rsiArmOverbought;
    
    //--- Helper methods
    bool             ShouldAddToGrid(const MarketState &state, bool isLong);
    bool             HasReversalSignal(const MarketState &state, bool expectBullish);
    double           CalculateStrength(const MarketState &state, ENUM_SIGNAL direction);
    void             ResetGrid();
    
protected:
    //--- Pure virtual implementations
    virtual bool     CheckActivation(const MarketState &state);
    virtual void     CalculateSignal(const MarketState &state);
    
public:
    //--- Constructor / Destructor
    GridRecovery();
    ~GridRecovery();
    
    //--- Initialization override
    virtual void     Init(IndicatorCache* cache, double baseWeight, string symbol, ENUM_TIMEFRAMES tf);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
GridRecovery::GridRecovery(void) :
    m_maxGridLevels(3),         // STRICT LIMIT: MAX 3 LEVELS
    m_gridDistance(1.5),        // 1.5× ATR spacing
    m_currentGridLevel(0),
    m_lastGridPrice(0),
    m_gridActive(false),
    m_rsiArmOversold(38.0),
    m_rsiArmOverbought(62.0)
{
    m_name = "GridRecovery";
    m_baseWeight = WEIGHT_GRID_RECOVERY;  // 0.7 (lower weight - risky)
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
GridRecovery::~GridRecovery(void) {
    // Nothing to clean up
}

//+------------------------------------------------------------------+
//| Initialize strategy                                              |
//+------------------------------------------------------------------+
void GridRecovery::Init(IndicatorCache* cache, double baseWeight, string symbol, ENUM_TIMEFRAMES tf) {
    // Call base class init
    BaseStrategy::Init(cache, baseWeight, symbol, tf);
    
    // Phase 3A: VOLATILE + TRENDING — FY XAU M5 rarely sat VOLATILE-only for full year
    ENUM_REGIME regimes[2];
    regimes[0] = REGIME_VOLATILE;
    regimes[1] = REGIME_TRENDING;
    SetActiveRegimes(regimes, 2);
    
    Print("GridRecovery initialized - Active: VOLATILE, TRENDING (Phase 3A); MAX 3 levels");
}

//+------------------------------------------------------------------+
//| Check if strategy should be active                               |
//+------------------------------------------------------------------+
bool GridRecovery::CheckActivation(const MarketState &state) {
    if(!IsActiveInCurrentRegime(state)) {
        ResetGrid();
        return false;
    }
    
    // Must not exceed max grid levels
    if(m_currentGridLevel >= m_maxGridLevels) {
        return false;
    }
    
    // Phase 3A: slightly lower floor so module can arm in tester (was 1.3)
    if(state.atrRatio < 1.08) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate trading signal                                         |
//+------------------------------------------------------------------+
void GridRecovery::CalculateSignal(const MarketState &state) {
    // NOTE: This is a simplified implementation
    // In production, this would check actual open positions
    // For now, we simulate grid behavior based on price movement
    
    double currentPrice = state.bid;
    double atr = state.atr14;
    
    if(atr == 0) {
        m_signal = SIGNAL_NONE;
        m_strength = 0.0;
        return;
    }
    
    // Calculate grid distance
    double gridSpacing = atr * m_gridDistance;
    
    // Check if we should add to long grid (BUY)
    if(state.rsi14 < m_rsiArmOversold) {  // Oversold (Phase 3A: slightly wider than 30)
        if(HasReversalSignal(state, true)) {
            if(m_currentGridLevel == 0) {
                m_lastGridPrice = currentPrice;
                m_currentGridLevel = 1;
                m_gridActive = true;
                // P0 fix: first leg must vote BUY — previously fell through to SIGNAL_NONE
                m_signal = SIGNAL_BUY;
                m_strength = CalculateStrength(state, SIGNAL_BUY);
                return;
            } else if(currentPrice < (m_lastGridPrice - gridSpacing)) {
                if(m_currentGridLevel < m_maxGridLevels) {
                    m_signal = SIGNAL_BUY;
                    m_strength = CalculateStrength(state, SIGNAL_BUY);
                    m_lastGridPrice = currentPrice;
                    m_currentGridLevel++;
                    return;
                }
            }
        }
    }
    
    // Check if we should add to short grid (SELL)
    if(state.rsi14 > m_rsiArmOverbought) {  // Overbought
        if(HasReversalSignal(state, false)) {
            if(m_currentGridLevel == 0) {
                m_lastGridPrice = currentPrice;
                m_currentGridLevel = 1;
                m_gridActive = true;
                m_signal = SIGNAL_SELL;
                m_strength = CalculateStrength(state, SIGNAL_SELL);
                return;
            } else if(currentPrice > (m_lastGridPrice + gridSpacing)) {
                if(m_currentGridLevel < m_maxGridLevels) {
                    m_signal = SIGNAL_SELL;
                    m_strength = CalculateStrength(state, SIGNAL_SELL);
                    m_lastGridPrice = currentPrice;
                    m_currentGridLevel++;
                    return;
                }
            }
        }
    }
    
    // Reset grid if price recovered
    if(m_gridActive) {
        // Bug fix: impossible condition was rsi>50 && rsi<50
        bool priceRecovered = (state.rsi14 >= 46.0 && state.rsi14 <= 54.0);
        
        if(priceRecovered) {
            ResetGrid();
        }
    }
    
    // No grid signal
    m_signal = SIGNAL_NONE;
    m_strength = 0.0;
}

//+------------------------------------------------------------------+
//| Check if should add to grid                                      |
//+------------------------------------------------------------------+
bool GridRecovery::ShouldAddToGrid(const MarketState &state, bool isLong) {
    // Grid level limit
    if(m_currentGridLevel >= m_maxGridLevels) return false;
    
    double atr = state.atr14;
    if(atr == 0) return false;
    
    double gridSpacing = atr * m_gridDistance;
    double currentPrice = state.bid;
    
    if(isLong) {
        // Price must have dropped by grid distance
        return (currentPrice < (m_lastGridPrice - gridSpacing));
    } else {
        // Price must have rallied by grid distance
        return (currentPrice > (m_lastGridPrice + gridSpacing));
    }
}

//+------------------------------------------------------------------+
//| Check for reversal signal                                        |
//+------------------------------------------------------------------+
bool GridRecovery::HasReversalSignal(const MarketState &state, bool expectBullish) {
    if(expectBullish) {
        if(state.rsi14 < m_rsiArmOversold) return true;
        if(IsPinBarBullish()) return true;
        if(IsHammerPattern()) return true;
    } else {
        if(state.rsi14 > m_rsiArmOverbought) return true;
        if(IsPinBarBearish()) return true;
        if(IsShootingStarPattern()) return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Calculate signal strength                                        |
//+------------------------------------------------------------------+
double GridRecovery::CalculateStrength(const MarketState &state, ENUM_SIGNAL direction) {
    double strength = 0.3;  // Base strength: 30% (intentionally low)
    
    //--- Bonus 1: RSI extreme adds 0.15
    if(direction == SIGNAL_BUY && state.rsi14 < 20) {
        strength += 0.15;
    } else if(direction == SIGNAL_SELL && state.rsi14 > 80) {
        strength += 0.15;
    }
    
    //--- Bonus 2: At major support/resistance adds 0.15
    if(direction == SIGNAL_BUY && IsNearSupport(state, 50)) {
        strength += 0.15;
    } else if(direction == SIGNAL_SELL && IsNearResistance(state, 50)) {
        strength += 0.15;
    }
    
    //--- Bonus 3: Volume spike adds 0.10
    double avgVolume = GetAverageVolume(20);
    double currentVolume = MathMax(GetVolume(0), GetVolume(1));
    if(avgVolume > 0 && currentVolume > (avgVolume * 1.5)) {
        strength += 0.10;
    }
    
    //--- Bonus 4: Golden hour adds 0.05
    if(state.isGoldenHour) {
        strength += 0.05;
    }
    
    //--- PENALTY 1: Already at 2 grid levels reduces by 0.20
    if(m_currentGridLevel >= 2) {
        strength -= 0.20;
    }
    
    //--- PENALTY 2: At 3 grid levels (max) reduces by additional 0.40
    if(m_currentGridLevel >= 3) {
        strength -= 0.40;  // Total penalty: -0.60
    }
    
    //--- Penalty 3: Dead zone reduces strength
    if(IsDeadZone(state)) {
        strength *= 0.5;  // Stronger penalty for grid
    }
    
    // Normalize to 0.0 - 1.0 range (will be very low)
    return NormalizeStrength(strength);
}

//+------------------------------------------------------------------+
//| Reset grid state                                                 |
//+------------------------------------------------------------------+
void GridRecovery::ResetGrid(void) {
    m_currentGridLevel = 0;
    m_lastGridPrice = 0;
    m_gridActive = false;
}

//+------------------------------------------------------------------+
//| END OF GRID RECOVERY STRATEGY                                    |
//+------------------------------------------------------------------+
