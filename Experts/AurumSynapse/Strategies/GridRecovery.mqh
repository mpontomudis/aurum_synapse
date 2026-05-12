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
//|   - Active regimes: VOL+TREND+RANG (Phase 3A+ v2 — CALM excluded) |
//|   - Requires reversal context (RSI arm + patterns)               |
//|                                                                  |
//| Phase 3E+ (forensic): LONG and SHORT recovery chains use         |
//|   separate level / anchor / active flags. Shared state caused    |
//|   SELL legs to inherit BUY anchor & level (state contamination). |
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
//| Activation: global atrRatio >= 0.85 (Phase 3A+ v2; roadmap §Test 3.7) |
//| Phase 3A: first grid leg must emit BUY/SELL (was armed then NONE).|
//+------------------------------------------------------------------+
class GridRecovery : public BaseStrategy {
private:
    //--- Strategy-specific settings
    int              m_maxGridLevels;          // Maximum grid levels (3)
    double           m_gridDistance;           // Grid spacing (× ATR)
    //--- Phase 3E+: separate chain state (forensic fix — no BUY/SELL cross-contamination)
    int              m_currentGridLevelLong;
    int              m_currentGridLevelShort;
    double           m_lastGridPriceLong;
    double           m_lastGridPriceShort;
    bool             m_gridActiveLong;
    bool             m_gridActiveShort;
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
    m_gridDistance(1.5),        // Phase 3F-A forensic: spacing only — canonical 1.5×ATR (RSI 42/58 unchanged)
    m_currentGridLevelLong(0),
    m_currentGridLevelShort(0),
    m_lastGridPriceLong(0),
    m_lastGridPriceShort(0),
    m_gridActiveLong(false),
    m_gridActiveShort(false),
    m_rsiArmOversold(42.0),    // Phase 3A+: 38 → 42 (wider arm for density)
    m_rsiArmOverbought(58.0)   // Phase 3A+: 62 → 58
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
    
    // Phase 3A+ v2 (restored): VOL+TREND+RANG only — same profile as canonical 17-trade §Test 3.7 row
    ENUM_REGIME regimes[3];
    regimes[0] = REGIME_VOLATILE;
    regimes[1] = REGIME_TRENDING;
    regimes[2] = REGIME_RANGING;
    SetActiveRegimes(regimes, 3);
    
    Print("GridRecovery initialized - Phase 3A+ v2 + Phase 3E+ state sep + Phase 3F-A: VOL+TREND+RANG; atrRatio>=0.85; RSI 42/58; grid 1.5xATR; MAX 3");
}

//+------------------------------------------------------------------+
//| Check if strategy should be active                               |
//+------------------------------------------------------------------+
bool GridRecovery::CheckActivation(const MarketState &state) {
    if(!IsActiveInCurrentRegime(state)) {
        ResetGrid();
        return false;
    }
    
    // Phase 3E+: per-direction max is enforced in CalculateSignal only.
    // (Legacy single m_currentGridLevel gate removed — it mixed BUY/SELL chains.)
    
    // Phase 3A+ v2: single global atr floor (matches roadmap §Test 3.7 pre–Phase 3B H2)
    if(state.atrRatio < 0.85)
        return false;
    
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
    
    // Check if we should add to long grid (BUY) — Phase 3E+: long-only state
    if(state.rsi14 < m_rsiArmOversold) {  // Oversold (Phase 3A: slightly wider than 30)
        if(HasReversalSignal(state, true)) {
            if(m_currentGridLevelLong == 0) {
                m_lastGridPriceLong = currentPrice;
                m_currentGridLevelLong = 1;
                m_gridActiveLong = true;
                // P0 fix: first leg must vote BUY — previously fell through to SIGNAL_NONE
                m_signal = SIGNAL_BUY;
                m_strength = CalculateStrength(state, SIGNAL_BUY);
                return;
            } else if(currentPrice < (m_lastGridPriceLong - gridSpacing)) {
                if(m_currentGridLevelLong < m_maxGridLevels) {
                    m_signal = SIGNAL_BUY;
                    m_strength = CalculateStrength(state, SIGNAL_BUY);
                    m_lastGridPriceLong = currentPrice;
                    m_currentGridLevelLong++;
                    return;
                }
            }
        }
    }
    
    // Check if we should add to short grid (SELL) — Phase 3E+: short-only state
    if(state.rsi14 > m_rsiArmOverbought) {  // Overbought
        if(HasReversalSignal(state, false)) {
            if(m_currentGridLevelShort == 0) {
                m_lastGridPriceShort = currentPrice;
                m_currentGridLevelShort = 1;
                m_gridActiveShort = true;
                m_signal = SIGNAL_SELL;
                m_strength = CalculateStrength(state, SIGNAL_SELL);
                return;
            } else if(currentPrice > (m_lastGridPriceShort + gridSpacing)) {
                if(m_currentGridLevelShort < m_maxGridLevels) {
                    m_signal = SIGNAL_SELL;
                    m_strength = CalculateStrength(state, SIGNAL_SELL);
                    m_lastGridPriceShort = currentPrice;
                    m_currentGridLevelShort++;
                    return;
                }
            }
        }
    }
    
    // Reset grid if price recovered / mean-revert (neutral RSI band)
    if(m_gridActiveLong || m_gridActiveShort) {
        bool priceRecovered = (state.rsi14 >= 46.0 && state.rsi14 <= 54.0);
        if(priceRecovered)
            ResetGrid();
    }
    
    // No grid signal
    m_signal = SIGNAL_NONE;
    m_strength = 0.0;
}

//+------------------------------------------------------------------+
//| Check if should add to grid                                      |
//+------------------------------------------------------------------+
bool GridRecovery::ShouldAddToGrid(const MarketState &state, bool isLong) {
    double atr = state.atr14;
    if(atr == 0) return false;
    
    double gridSpacing = atr * m_gridDistance;
    double currentPrice = state.bid;
    
    if(isLong) {
        if(m_currentGridLevelLong >= m_maxGridLevels) return false;
        if(m_currentGridLevelLong == 0) return false;
        return (currentPrice < (m_lastGridPriceLong - gridSpacing));
    } else {
        if(m_currentGridLevelShort >= m_maxGridLevels) return false;
        if(m_currentGridLevelShort == 0) return false;
        return (currentPrice > (m_lastGridPriceShort + gridSpacing));
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
    
    // Phase 3E+: penalties use the chain that is actually emitting
    const int levelForPenalty = (direction == SIGNAL_BUY) ? m_currentGridLevelLong : m_currentGridLevelShort;
    
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
    if(levelForPenalty >= 2) {
        strength -= 0.20;
    }
    
    //--- PENALTY 2: At 3 grid levels (max) reduces by additional 0.40
    if(levelForPenalty >= 3) {
        strength -= 0.40;  // Total penalty: -0.60
    }
    
    //--- Penalty 3: Dead zone (Phase 3A+ v2 — uniform softening vs Q60 starvation split removed)
    if(IsDeadZone(state))
        strength *= 0.5;
    
    // Normalize to 0.0 - 1.0 range (will be very low)
    return NormalizeStrength(strength);
}

//+------------------------------------------------------------------+
//| Reset grid state                                                 |
//+------------------------------------------------------------------+
void GridRecovery::ResetGrid(void) {
    m_currentGridLevelLong = 0;
    m_currentGridLevelShort = 0;
    m_lastGridPriceLong = 0;
    m_lastGridPriceShort = 0;
    m_gridActiveLong = false;
    m_gridActiveShort = false;
}

//+------------------------------------------------------------------+
//| END OF GRID RECOVERY STRATEGY                                    |
//+------------------------------------------------------------------+
