//+------------------------------------------------------------------+
//|                                                SupplyDemand.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Supply/Demand Strategy - Zone Reactions & Institutional Levels"

#include "BaseStrategy.mqh"

//+------------------------------------------------------------------+
//| Supply/Demand Zone Structure                                     |
//+------------------------------------------------------------------+
struct ZoneInfo {
    double           top;              // Zone upper boundary
    double           bottom;           // Zone lower boundary
    datetime         created;          // When zone was created
    int              touchCount;       // Times price tested this zone
    double           quality;          // Zone quality (0-1, based on impulse strength)
    bool             isValid;          // Is zone still valid
};

//+------------------------------------------------------------------+
//| Supply/Demand Strategy                                           |
//|                                                                  |
//| Logic:                                                           |
//|   BUY:  Price enters fresh demand zone + rejection               |
//|   SELL: Price enters fresh supply zone + rejection               |
//|                                                                  |
//| Zone Creation:                                                   |
//|   - Detect strong impulse moves (>1.5× ATR)                      |
//|   - Identify base/consolidation before impulse                   |
//|   - Mark base as supply/demand zone                              |
//|                                                                  |
//| Entry Conditions:                                                |
//|   BUY:                                                           |
//|     - Price within demand zone boundaries                        |
//|     - Zone is fresh (tested ≤ 2 times)                           |
//|     - Bullish rejection candle (long lower wick)                 |
//|     - Volume ≥ ~0.80× average (Phase 3A+ v7; max bar0,bar1 vs avg)   |
//|                                                                  |
//|   SELL:                                                          |
//|     - Price within supply zone boundaries                        |
//|     - Zone is fresh (tested ≤ 2 times)                           |
//|     - Bearish rejection + bearish close bar1 OR bar0 (H2 cont.)    |
//|     - Volume ≥ ~0.80× average (Phase 3A+ v7; max bar0,bar1 vs avg)   |
//|                                                                  |
//| Strength Calculation:                                            |
//|   Base: 0.5                                                      |
//|   +0.15 if zone never tested (completely fresh)                  |
//|   +0.15 if strong rejection (wick > 2× body)                     |
//|   +0.10 if volume spike (>1.5× average)                          |
//|   +0.10 if high quality zone (strong impulse)                    |
//|   +0.10 if trend aligned                                         |
//|   +0.05 if golden hour                                           |
//|                                                                  |
//| Activation: ANY regime + at least 1 fresh zone nearby            |
//| Phase 3A+ v6: probe/rejection use bar0 OR bar1 (OnTick=new bar:     |
//| bar0 incomplete); looser impulse/height; v5 wick+ATR; v4 vol pass.  |
//| Phase 3A+ v7: SELL bar-1 bearish (bull-tape supply fade).            |
//| Phase 3B H2 continuity: SELL bar0|bar1 bearish (parity Breakout/MR); |
//| dead-zone strength penalty only TRENDING/VOLATILE (RANGING/CALM    |
//| H2 session survivability vs Q60). impulse 0.205; vol 0.80.         |
//+------------------------------------------------------------------+
class SupplyDemand : public BaseStrategy {
private:
    //--- Strategy-specific settings
    int              m_maxZones;               // Maximum zones to track (5)
    int              m_lookbackBars;           // Bars to scan for zones (150)
    double           m_impulseThreshold;       // Impulse vs ATR (Phase 3A+ v6 ~0.22)
    int              m_maxTouches;             // Max touches before zone invalid (2)
    double           m_zoneProximity;          // ATR multiplier for near-zone (rehab ~2.5)
    double           m_minZoneHeight;          // Min zone height vs ATR (rehab ~0.15)
    double           m_volumeMultiplier;       // Volume vs avg (rehab ~1.0)
    
    //--- Zone storage
    ZoneInfo         m_supplyZones[5];         // Active supply zones
    ZoneInfo         m_demandZones[5];         // Active demand zones
    int              m_supplyCount;
    int              m_demandCount;
    
    //--- Helper methods
    void             DetectZones();
    void             FindSupplyZones();
    void             FindDemandZones();
    bool             IsInDemandZone(double price, int &zoneIndex);
    bool             IsInSupplyZone(double price, int &zoneIndex);
    bool             IsBullishRejection();
    bool             IsBearishRejection();
    bool             IsBullishRejectionShift(const int sh);
    bool             IsBearishRejectionShift(const int sh);
    double           GetZoneQuality(int impulseSize, double atr);
    void             UpdateZoneTouches(int zoneIndex, bool isSupply);
    void             InvalidateOldZones(int maxAge);
    double           DistancePriceToZone(const double price, const double zBottom, const double zTop);
    double           GetAtrForZones(void);
    double           CalculateStrength(const MarketState &state, ENUM_SIGNAL direction, int zoneIndex, bool isSupply);
    
protected:
    //--- Pure virtual implementations
    virtual bool     CheckActivation(const MarketState &state);
    virtual void     CalculateSignal(const MarketState &state);
    
public:
    //--- Constructor / Destructor
    SupplyDemand();
    ~SupplyDemand();
    
    //--- Initialization override
    virtual void     Init(IndicatorCache* cache, double baseWeight, string symbol, ENUM_TIMEFRAMES tf);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
SupplyDemand::SupplyDemand(void) :
    m_maxZones(5),
    m_lookbackBars(150),
    m_impulseThreshold(0.205),
    m_maxTouches(2),
    m_zoneProximity(4.2),
    m_minZoneHeight(0.02),
    m_volumeMultiplier(0.80),
    m_supplyCount(0),
    m_demandCount(0)
{
    m_name = "SupplyDemand";
    m_baseWeight = WEIGHT_SUPPLY_DEMAND;  // 1.2 from constants
    
    // Initialize zone arrays
    for(int i = 0; i < 5; i++) {
        m_supplyZones[i].isValid = false;
        m_demandZones[i].isValid = false;
    }
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
SupplyDemand::~SupplyDemand(void) {
    // Nothing to clean up
}

//+------------------------------------------------------------------+
//| Initialize strategy                                              |
//+------------------------------------------------------------------+
void SupplyDemand::Init(IndicatorCache* cache, double baseWeight, string symbol, ENUM_TIMEFRAMES tf) {
    // Call base class init
    BaseStrategy::Init(cache, baseWeight, symbol, tf);
    
    // Set active regimes (ALL regimes - supply/demand works anywhere)
    ENUM_REGIME regimes[4];
    regimes[0] = REGIME_TRENDING;
    regimes[1] = REGIME_RANGING;
    regimes[2] = REGIME_VOLATILE;
    regimes[3] = REGIME_CALM;
    SetActiveRegimes(regimes, 4);
    
    Print("SupplyDemand initialized - ALL regimes; Phase 3B H2 cont. (SELL bearish bar0|1; deadZone str×0.7 T/V only; v7 base)");
}

//+------------------------------------------------------------------+
//| Distance from price to nearest edge of [zBottom, zTop] box         |
//+------------------------------------------------------------------+
double SupplyDemand::DistancePriceToZone(const double price, const double zBottom, const double zTop) {
    double lo = MathMin(zBottom, zTop);
    double hi = MathMax(zBottom, zTop);
    if(price < lo) return lo - price;
    if(price > hi) return price - hi;
    return 0.0;
}

//+------------------------------------------------------------------+
//| ATR for zone geometry: cache ATR or mean range (never 0)         |
//+------------------------------------------------------------------+
double SupplyDemand::GetAtrForZones(void) {
    double a = GetATR();
    if(a > 0.0)
        return a;
    const int n = 14;
    double sum = 0.0;
    for(int i = 1; i <= n; i++)
        sum += GetHigh(i) - GetLow(i);
    double avgR = sum / (double)n;
    double pt = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
    return MathMax(avgR, pt * 50.0);
}

//+------------------------------------------------------------------+
//| Check if strategy should be active                               |
//+------------------------------------------------------------------+
bool SupplyDemand::CheckActivation(const MarketState &state) {
    if(!IsActiveInCurrentRegime(state))
        return false;
    
    // Detect/update zones
    DetectZones();
    
    bool hasValidSupply = false;
    bool hasValidDemand = false;
    for(int i = 0; i < m_supplyCount; i++) {
        if(m_supplyZones[i].isValid && m_supplyZones[i].touchCount <= m_maxTouches) {
            hasValidSupply = true;
            break;
        }
    }
    for(int i = 0; i < m_demandCount; i++) {
        if(m_demandZones[i].isValid && m_demandZones[i].touchCount <= m_maxTouches) {
            hasValidDemand = true;
            break;
        }
    }
    if(!hasValidSupply && !hasValidDemand)
        return false;
    
    double currentPrice = state.bid;
    double atr = state.atr14;
    if(atr <= 0)
        return true;
    
    double proximityDistance = atr * m_zoneProximity;
    
    for(int i = 0; i < m_supplyCount; i++) {
        if(!m_supplyZones[i].isValid) continue;
        if(m_supplyZones[i].touchCount > m_maxTouches) continue;
        
        double distanceToZone = DistancePriceToZone(currentPrice, m_supplyZones[i].bottom, m_supplyZones[i].top);
        if(distanceToZone < proximityDistance) {
            return true;
        }
    }
    
    for(int i = 0; i < m_demandCount; i++) {
        if(!m_demandZones[i].isValid) continue;
        if(m_demandZones[i].touchCount > m_maxTouches) continue;
        
        double distanceToZone = DistancePriceToZone(currentPrice, m_demandZones[i].bottom, m_demandZones[i].top);
        if(distanceToZone < proximityDistance) {
            return true;
        }
    }
    
    // Phase 3A: zones exist — still run CalculateSignal (entries gated there)
    return true;
}

//+------------------------------------------------------------------+
//| Calculate trading signal                                         |
//+------------------------------------------------------------------+
void SupplyDemand::CalculateSignal(const MarketState &state) {
    double currentPrice = state.bid;
    int zoneIndex = -1;
    
    // Check for demand zone entry (BUY signal)
    if(IsInDemandZone(currentPrice, zoneIndex)) {
        if(zoneIndex >= 0 && m_demandZones[zoneIndex].touchCount <= m_maxTouches) {
            if(IsBullishRejection()) {
                // Check volume confirmation
                double avgVolume = GetAverageVolume(20);
                double currentVolume = MathMax(GetVolume(0), GetVolume(1));
                // v4: tester often yields avgVolume==0 (no tick vol in window) — do not hard-block
                bool volOk = (avgVolume <= 0.0) || (currentVolume >= (avgVolume * m_volumeMultiplier));
                
                if(volOk) {
                    m_signal = SIGNAL_BUY;
                    m_strength = CalculateStrength(state, SIGNAL_BUY, zoneIndex, false);
                    UpdateZoneTouches(zoneIndex, false);
                    return;
                }
            }
        }
    }
    
    // Check for supply zone entry (SELL) — v7: bar-1 bearish close filters weak supply fades in bull tape
    if(IsInSupplyZone(currentPrice, zoneIndex)) {
        if(zoneIndex >= 0 && m_supplyZones[zoneIndex].touchCount <= m_maxTouches) {
            if(IsBearishRejection() && (IsBearishCandle(1) || IsBearishCandle(0))) {
                // Check volume confirmation
                double avgVolume = GetAverageVolume(20);
                double currentVolume = MathMax(GetVolume(0), GetVolume(1));
                bool volOk = (avgVolume <= 0.0) || (currentVolume >= (avgVolume * m_volumeMultiplier));
                
                if(volOk) {
                    m_signal = SIGNAL_SELL;
                    m_strength = CalculateStrength(state, SIGNAL_SELL, zoneIndex, true);
                    UpdateZoneTouches(zoneIndex, true);
                    return;
                }
            }
        }
    }
    
    // No valid supply/demand signal
    m_signal = SIGNAL_NONE;
    m_strength = 0.0;
}

//+------------------------------------------------------------------+
//| Detect supply and demand zones                                   |
//+------------------------------------------------------------------+
void SupplyDemand::DetectZones(void) {
    // Invalidate old zones (older than 50 bars)
    InvalidateOldZones(50);
    
    // Find new zones
    FindSupplyZones();
    FindDemandZones();
}

//+------------------------------------------------------------------+
//| Find supply zones (areas before bearish impulse)                 |
//+------------------------------------------------------------------+
void SupplyDemand::FindSupplyZones(void) {
    double atr = GetAtrForZones();
    
    double impulseThreshold = atr * m_impulseThreshold;
    m_supplyCount = 0;
    
    // Scan for bearish impulse moves (older high → newer low)
    for(int i = 5; i < m_lookbackBars - 3 && m_supplyCount < m_maxZones; i++) {
        double impulseDrop = GetHigh(i + 3) - GetLow(i);
        
        // Check if this is a strong bearish impulse (drop > threshold)
        if(impulseDrop > impulseThreshold) {
            // Consolidation proxy near impulse (rehab)
            double zoneTop = MathMax(GetHigh(i), GetHigh(i + 1));
            double zoneLow = MathMin(GetLow(i + 1), GetLow(i + 2));
            if(zoneLow > zoneTop) {
                double tmp = zoneTop;
                zoneTop = zoneLow;
                zoneLow = tmp;
            }
            double zoneHeight = zoneTop - zoneLow;
            
            // Zone must have minimum height
            if(zoneHeight > (atr * m_minZoneHeight)) {
                // Check if zone already exists (avoid duplicates)
                bool isDuplicate = false;
                for(int j = 0; j < m_supplyCount; j++) {
                    if(MathAbs(m_supplyZones[j].top - zoneTop) < atr * 0.5) {
                        isDuplicate = true;
                        break;
                    }
                }
                
                if(!isDuplicate) {
                    m_supplyZones[m_supplyCount].top = zoneTop;
                    m_supplyZones[m_supplyCount].bottom = zoneLow;
                    m_supplyZones[m_supplyCount].created = iTime(m_symbol, m_timeframe, i);
                    m_supplyZones[m_supplyCount].touchCount = 0;
                    m_supplyZones[m_supplyCount].quality = GetZoneQuality((int)(impulseDrop / atr), atr);
                    m_supplyZones[m_supplyCount].isValid = true;
                    m_supplyCount++;
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Find demand zones (areas before bullish impulse)                 |
//+------------------------------------------------------------------+
void SupplyDemand::FindDemandZones(void) {
    double atr = GetAtrForZones();
    
    double impulseThreshold = atr * m_impulseThreshold;
    m_demandCount = 0;
    
    // Scan for bullish impulse moves (older low → newer high)
    for(int i = 5; i < m_lookbackBars - 3 && m_demandCount < m_maxZones; i++) {
        double impulseRally = GetHigh(i) - GetLow(i + 3);
        
        // Check if this is a strong bullish impulse (rally > threshold)
        if(impulseRally > impulseThreshold) {
            // Consolidation proxy (rehab)
            double zoneTop = MathMax(GetHigh(i + 1), GetHigh(i + 2));
            double zoneLow = MathMin(GetLow(i), GetLow(i + 1));
            if(zoneLow > zoneTop) {
                double tmp = zoneTop;
                zoneTop = zoneLow;
                zoneLow = tmp;
            }
            double zoneHeight = zoneTop - zoneLow;
            
            // Zone must have minimum height
            if(zoneHeight > (atr * m_minZoneHeight)) {
                // Check if zone already exists (avoid duplicates)
                bool isDuplicate = false;
                for(int j = 0; j < m_demandCount; j++) {
                    if(MathAbs(m_demandZones[j].bottom - zoneLow) < atr * 0.5) {
                        isDuplicate = true;
                        break;
                    }
                }
                
                if(!isDuplicate) {
                    m_demandZones[m_demandCount].top = zoneTop;
                    m_demandZones[m_demandCount].bottom = zoneLow;
                    m_demandZones[m_demandCount].created = iTime(m_symbol, m_timeframe, i);
                    m_demandZones[m_demandCount].touchCount = 0;
                    m_demandZones[m_demandCount].quality = GetZoneQuality((int)(impulseRally / atr), atr);
                    m_demandZones[m_demandCount].isValid = true;
                    m_demandCount++;
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check if price is in demand zone                                 |
//+------------------------------------------------------------------+
bool SupplyDemand::IsInDemandZone(double price, int &zoneIndex) {
    double atr = GetAtrForZones();
    double pad = atr * 0.38;
    // v6: new-bar tick — include closed bar (1) wicks; bar 0 alone is often incomplete
    double probe = MathMin(price, MathMin(GetLow(0), GetLow(1)));
    
    for(int i = 0; i < m_demandCount; i++) {
        if(!m_demandZones[i].isValid) continue;
        
        if(probe >= m_demandZones[i].bottom - pad && probe <= m_demandZones[i].top + pad) {
            zoneIndex = i;
            return true;
        }
    }
    
    zoneIndex = -1;
    return false;
}

//+------------------------------------------------------------------+
//| Check if price is in supply zone                                 |
//+------------------------------------------------------------------+
bool SupplyDemand::IsInSupplyZone(double price, int &zoneIndex) {
    double atr = GetAtrForZones();
    double pad = atr * 0.38;
    double probe = MathMax(price, MathMax(GetHigh(0), GetHigh(1)));
    
    for(int i = 0; i < m_supplyCount; i++) {
        if(!m_supplyZones[i].isValid) continue;
        
        if(probe >= m_supplyZones[i].bottom - pad && probe <= m_supplyZones[i].top + pad) {
            zoneIndex = i;
            return true;
        }
    }
    
    zoneIndex = -1;
    return false;
}

//+------------------------------------------------------------------+
//| Check for bullish rejection candle                               |
//+------------------------------------------------------------------+
bool SupplyDemand::IsBullishRejectionShift(const int sh) {
    double open = GetOpen(sh);
    double close = GetClose(sh);
    double low = GetLow(sh);
    
    double body = MathAbs(close - open);
    double pt = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
    if(body < pt) body = pt;
    
    double lowerWick = MathMin(open, close) - low;
    
    return (lowerWick > body * 0.5 || lowerWick > pt * 12.0);
}

bool SupplyDemand::IsBullishRejection(void) {
    return (IsBullishRejectionShift(0) || IsBullishRejectionShift(1));
}

//+------------------------------------------------------------------+
//| Check for bearish rejection candle                               |
//+------------------------------------------------------------------+
bool SupplyDemand::IsBearishRejectionShift(const int sh) {
    double open = GetOpen(sh);
    double close = GetClose(sh);
    double high = GetHigh(sh);
    
    double body = MathAbs(close - open);
    double pt = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
    if(body < pt) body = pt;
    
    double upperWick = high - MathMax(open, close);
    
    return (upperWick > body * 0.5 || upperWick > pt * 12.0);
}

bool SupplyDemand::IsBearishRejection(void) {
    return (IsBearishRejectionShift(0) || IsBearishRejectionShift(1));
}

//+------------------------------------------------------------------+
//| Calculate zone quality based on impulse strength                 |
//+------------------------------------------------------------------+
double SupplyDemand::GetZoneQuality(int impulseSize, double atr) {
    // Quality based on impulse strength (in ATR multiples)
    // 1.5 ATR = 0.5, 3.0 ATR = 1.0
    double quality = (impulseSize - 1.5) / 1.5;
    return NormalizeStrength(quality);
}

//+------------------------------------------------------------------+
//| Update zone touch count                                          |
//+------------------------------------------------------------------+
void SupplyDemand::UpdateZoneTouches(int zoneIndex, bool isSupply) {
    if(isSupply && zoneIndex >= 0 && zoneIndex < m_supplyCount) {
        m_supplyZones[zoneIndex].touchCount++;
        
        // Invalidate if too many touches
        if(m_supplyZones[zoneIndex].touchCount > m_maxTouches) {
            m_supplyZones[zoneIndex].isValid = false;
        }
    } else if(!isSupply && zoneIndex >= 0 && zoneIndex < m_demandCount) {
        m_demandZones[zoneIndex].touchCount++;
        
        // Invalidate if too many touches
        if(m_demandZones[zoneIndex].touchCount > m_maxTouches) {
            m_demandZones[zoneIndex].isValid = false;
        }
    }
}

//+------------------------------------------------------------------+
//| Invalidate zones older than maxAge bars                          |
//+------------------------------------------------------------------+
void SupplyDemand::InvalidateOldZones(int maxAge) {
    datetime currentTime = iTime(m_symbol, m_timeframe, 0);
    datetime threshold = currentTime - (maxAge * PeriodSeconds(m_timeframe));
    
    // Invalidate old supply zones
    for(int i = 0; i < m_supplyCount; i++) {
        if(m_supplyZones[i].created < threshold) {
            m_supplyZones[i].isValid = false;
        }
    }
    
    // Invalidate old demand zones
    for(int i = 0; i < m_demandCount; i++) {
        if(m_demandZones[i].created < threshold) {
            m_demandZones[i].isValid = false;
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate signal strength                                        |
//+------------------------------------------------------------------+
double SupplyDemand::CalculateStrength(const MarketState &state, ENUM_SIGNAL direction, int zoneIndex, bool isSupply) {
    double strength = 0.5;  // Base strength: 50%
    
    // Get zone info
    double zoneQuality = 0;
    int touchCount = 0;
    
    if(isSupply && zoneIndex >= 0 && zoneIndex < m_supplyCount) {
        zoneQuality = m_supplyZones[zoneIndex].quality;
        touchCount = m_supplyZones[zoneIndex].touchCount;
    } else if(!isSupply && zoneIndex >= 0 && zoneIndex < m_demandCount) {
        zoneQuality = m_demandZones[zoneIndex].quality;
        touchCount = m_demandZones[zoneIndex].touchCount;
    }
    
    //--- Bonus 1: Fresh zone (never tested) adds 0.15
    if(touchCount == 0) {
        strength += 0.15;
    }
    
    //--- Bonus 2: Strong rejection candle — max(bar0,bar1) wick vs body (parity with entry probe)
    double pt = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
    bool strongRejection = false;
    if(direction == SIGNAL_BUY) {
        double best = 0.0;
        for(int sh = 0; sh <= 1; sh++) {
            double o = GetOpen(sh), c = GetClose(sh), l = GetLow(sh);
            double body = MathAbs(c - o);
            if(body < pt) body = pt;
            double lowerWick = MathMin(o, c) - l;
            best = MathMax(best, lowerWick / body);
        }
        strongRejection = (best > 3.0);
    } else {
        double best = 0.0;
        for(int sh = 0; sh <= 1; sh++) {
            double o = GetOpen(sh), c = GetClose(sh), h = GetHigh(sh);
            double body = MathAbs(c - o);
            if(body < pt) body = pt;
            double upperWick = h - MathMax(o, c);
            best = MathMax(best, upperWick / body);
        }
        strongRejection = (best > 3.0);
    }
    
    if(strongRejection) {
        strength += 0.15;
    }
    
    //--- Bonus 3: Volume spike (>1.5× average) adds 0.10
    double avgVolume = GetAverageVolume(20);
    if(avgVolume > 0) {
        double currentVolume = MathMax(GetVolume(0), GetVolume(1));
        if(currentVolume > (avgVolume * 1.5)) {
            strength += 0.10;
        }
    }
    
    //--- Bonus 4: High quality zone adds 0.10
    if(zoneQuality > 0.7) {
        strength += 0.10;
    }
    
    //--- Bonus 5: Trend aligned adds 0.10
    bool trendAligned = false;
    if(direction == SIGNAL_BUY) {
        trendAligned = (state.trendDir == TREND_UP);
    } else {
        trendAligned = (state.trendDir == TREND_DOWN);
    }
    
    if(trendAligned) {
        strength += 0.10;
    }
    
    //--- Bonus 6: Golden hour adds 0.05
    if(state.isGoldenHour) {
        strength += 0.05;
    }
    
    //--- Penalty: Dead zone reduces strength — Phase 3B H2: only TRENDING/VOLATILE
    //    (zone strategy is regime-agnostic; RANGING/CALM H2 should not session-starve Q60)
    if(IsDeadZone(state) &&
       (state.regime == REGIME_TRENDING || state.regime == REGIME_VOLATILE)) {
        strength *= 0.7;
    }
    
    //--- Penalty: Multiple touches reduce strength
    if(touchCount > 0) {
        strength *= (1.0 - (touchCount * 0.15));  // -15% per touch
    }
    
    // Normalize to 0.0 - 1.0 range
    return NormalizeStrength(strength);
}

//+------------------------------------------------------------------+
//| END OF SUPPLY/DEMAND STRATEGY                                    |
//+------------------------------------------------------------------+
