//+------------------------------------------------------------------+
//|                                                 BaseStrategy.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Abstract Base Strategy Class"

#include "../Core/Constants.mqh"
#include "../Core/Structures.mqh"
#include "../Core/IndicatorCache.mqh"

//+------------------------------------------------------------------+
//| Base Strategy Class (Abstract)                                   |
//| All 8 concrete strategies inherit from this class                |
//| Provides common helper methods and indicator access              |
//+------------------------------------------------------------------+
class BaseStrategy {
protected:
    //--- Strategy identity
    string           m_name;                  // Strategy name
    double           m_baseWeight;            // Base weight from constants
    double           m_adaptiveWeight;        // Current adaptive weight (from RegimeMemory)
    
    //--- Signal output
    ENUM_SIGNAL      m_signal;                // Current signal (BUY/SELL/NONE)
    double           m_strength;              // Signal strength (0.0 - 1.0)
    
    //--- Active regimes
    ENUM_REGIME      m_activeRegimes[4];      // Which regimes activate this strategy
    int              m_activeRegimeCount;     // Number of active regimes
    
    //--- Shared resources
    IndicatorCache*  m_cache;                 // Shared indicator cache (not owned)
    string           m_symbol;                // Trading symbol
    ENUM_TIMEFRAMES  m_timeframe;             // Primary timeframe
    
    //--- State tracking
    bool             m_initialized;           // Initialization flag
    datetime         m_lastEvalTime;          // Last evaluation timestamp
    
    //+------------------------------------------------------------------+
    //| PURE VIRTUAL METHODS (Must be implemented by derived classes)    |
    //+------------------------------------------------------------------+
    
    // Check if strategy should be active in current market state
    virtual bool     CheckActivation(const MarketState &state) = 0;
    
    // Calculate trading signal based on strategy logic
    virtual void     CalculateSignal(const MarketState &state) = 0;
    
    //+------------------------------------------------------------------+
    //| HELPER METHODS: Indicator Access (via IndicatorCache)            |
    //+------------------------------------------------------------------+
    
    // Moving averages
    double           GetEMA(int period, int shift);
    double           GetSMA(int period, int shift);
    
    // Oscillators
    double           GetRSI(int shift);
    double           GetMACD(int buffer, int shift);  // 0=main, 1=signal
    double           GetADX(int shift);
    double           GetStoch(int buffer, int shift); // 0=K, 1=D
    
    // Volatility
    double           GetATR(int shift);
    double           GetBB(int buffer, int shift);    // 0=upper, 1=mid, 2=lower
    
    // Volume
    double           GetVolume(int shift);
    double           GetAvgVolume(int periods);
    
    //+------------------------------------------------------------------+
    //| HELPER METHODS: Price Action                                     |
    //+------------------------------------------------------------------+
    
    // OHLC access
    double           GetOpen(int shift);
    double           GetHigh(int shift);
    double           GetLow(int shift);
    double           GetClose(int shift);
    
    // Candle properties
    double           GetCandleRange(int shift);       // High - Low
    double           GetCandleBody(int shift);        // |Close - Open|
    double           GetUpperWick(int shift);         // High - max(O,C)
    double           GetLowerWick(int shift);         // min(O,C) - Low
    bool             IsBullishCandle(int shift);      // Close > Open
    bool             IsBearishCandle(int shift);      // Close < Open
    
    //+------------------------------------------------------------------+
    //| HELPER METHODS: Candlestick Patterns                             |
    //+------------------------------------------------------------------+
    
    bool             IsPinBar(int shift, bool bullish);
    bool             IsEngulfing(int shift, bool bullish);
    bool             IsDoji(int shift);
    bool             IsHammer(int shift);
    bool             IsShootingStar(int shift);
    bool             IsInsideBar(int shift);
    bool             IsOutsideBar(int shift);
    
    // Pattern wrapper methods (for convenience)
    bool             IsPinBarBullish();
    bool             IsPinBarBearish();
    bool             IsEngulfingBullish();
    bool             IsEngulfingBearish();
    bool             IsHammerPattern();
    bool             IsShootingStarPattern();
    bool             IsInsideBarPattern();
    
    //+------------------------------------------------------------------+
    //| HELPER METHODS: Market Structure                                 |
    //+------------------------------------------------------------------+
    
    bool             IsHigherHigh(int lookback);
    bool             IsHigherLow(int lookback);
    bool             IsLowerHigh(int lookback);
    bool             IsLowerLow(int lookback);
    bool             IsBullishStructure(int lookback);
    bool             IsBearishStructure(int lookback);
    
    //+------------------------------------------------------------------+
    //| HELPER METHODS: Support/Resistance & Key Levels                  |
    //+------------------------------------------------------------------+
    
    bool             IsNearSupport(const MarketState &state, double threshold);
    bool             IsNearResistance(const MarketState &state, double threshold);
    bool             IsAtKeyLevel(const MarketState &state, double threshold);
    bool             IsInSupplyZone(const MarketState &state);
    bool             IsInDemandZone(const MarketState &state);
    double           GetDistanceToSupport(const MarketState &state);
    double           GetDistanceToResistance(const MarketState &state);
    
    //+------------------------------------------------------------------+
    //| HELPER METHODS: Trend Detection                                  |
    //+------------------------------------------------------------------+
    
    bool             IsUptrend(const MarketState &state);
    bool             IsDowntrend(const MarketState &state);
    bool             IsRanging(const MarketState &state);
    bool             EMAsAligned(bool bullish);          // 21 > 50 > 200 (bullish)
    int              GetTrendStrength(const MarketState &state); // 0-100
    
    //+------------------------------------------------------------------+
    //| HELPER METHODS: Momentum & Divergence                            |
    //+------------------------------------------------------------------+
    
    bool             IsMomentumBullish();
    bool             IsMomentumBearish();
    bool             IsRSIOverBought(double level);
    bool             IsRSIOversold(double level);
    bool             IsRSIDivergenceBullish(int lookback);
    bool             IsRSIDivergenceBearish(int lookback);
    bool             IsMACDCrossBullish();
    bool             IsMACDCrossBearish();
    
    //+------------------------------------------------------------------+
    //| HELPER METHODS: Volatility                                       |
    //+------------------------------------------------------------------+
    
    bool             IsHighVolatility(const MarketState &state);
    bool             IsLowVolatility(const MarketState &state);
    bool             IsBBSqueeze();                      // BB width < avg
    bool             IsBBExpansion();                    // BB width > avg
    bool             IsPriceAtUpperBB();
    bool             IsPriceAtLowerBB();
    
    //+------------------------------------------------------------------+
    //| HELPER METHODS: Regime & Session                                 |
    //+------------------------------------------------------------------+
    
    bool             IsActiveInRegime(ENUM_REGIME regime);
    bool             IsGoldenHour(const MarketState &state);
    bool             IsDeadZone(const MarketState &state);
    bool             IsHighLiquiditySession(const MarketState &state);
    
    //+------------------------------------------------------------------+
    //| HELPER METHODS: Validation & Error Handling                      |
    //+------------------------------------------------------------------+
    
    bool             ValidateCache();
    bool             ValidateState(const MarketState &state);
    double           NormalizeStrength(double value);    // Clamp to 0.0-1.0
    void             ResetSignal();                      // Clear signal to NONE
    
    //+------------------------------------------------------------------+
    //| UTILITY METHODS                                                   |
    //+------------------------------------------------------------------+
    
    double           GetAverageVolume(int periods);
    double           PointsToPips(double points);
    double           PipsToPoints(double pips);
    string           SignalToString(ENUM_SIGNAL signal);
    string           RegimeToString(ENUM_REGIME regime);
    
public:
    //+------------------------------------------------------------------+
    //| PUBLIC INTERFACE                                                  |
    //+------------------------------------------------------------------+
    
    // Constructor / Destructor
    BaseStrategy();
    virtual ~BaseStrategy();
    
    // Initialization
    virtual void     Init(IndicatorCache* cache, double baseWeight, string symbol, ENUM_TIMEFRAMES tf);
    
    // Main evaluation method (called every bar/tick)
    void             Evaluate(const MarketState &state);
    
    //--- Accessor methods
    ENUM_SIGNAL      GetSignal() const         { return m_signal; }
    double           GetStrength() const       { return m_strength; }
    double           GetWeight() const         { return m_adaptiveWeight; }
    double           GetBaseWeight() const     { return m_baseWeight; }
    string           GetName() const           { return m_name; }
    bool             IsActive() const          { return m_signal != SIGNAL_NONE; }
    bool             IsInitialized() const     { return m_initialized; }
    
    //--- Weight management
    void             SetAdaptiveWeight(double weight);
    
    //--- Active regime management
    void             SetActiveRegimes(ENUM_REGIME &regimes[], int count);
    bool             IsActiveInCurrentRegime(const MarketState &state);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
BaseStrategy::BaseStrategy(void) :
    m_name("BaseStrategy"),
    m_baseWeight(1.0),
    m_adaptiveWeight(1.0),
    m_signal(SIGNAL_NONE),
    m_strength(0.0),
    m_cache(NULL),
    m_symbol(""),
    m_timeframe(PERIOD_M1),
    m_initialized(false),
    m_lastEvalTime(0),
    m_activeRegimeCount(0)
{
    // m_activeRegimes is a fixed-size array [4]; no resize needed
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
BaseStrategy::~BaseStrategy(void) {
    // Nothing to clean up (cache is not owned by strategy)
}

//+------------------------------------------------------------------+
//| Initialize strategy                                              |
//+------------------------------------------------------------------+
void BaseStrategy::Init(IndicatorCache* cache, double baseWeight, string symbol, ENUM_TIMEFRAMES tf) {
    if(cache == NULL) {
        Print("ERROR: ", m_name, " - IndicatorCache is NULL");
        return;
    }
    
    m_cache = cache;
    m_baseWeight = baseWeight;
    m_adaptiveWeight = baseWeight;
    m_symbol = symbol;
    m_timeframe = tf;
    m_initialized = true;
    
    ResetSignal();
    
    Print(m_name, " initialized - Weight: ", DoubleToString(m_baseWeight, 2));
}

//+------------------------------------------------------------------+
//| Main evaluation method                                           |
//+------------------------------------------------------------------+
void BaseStrategy::Evaluate(const MarketState &state) {
    // Reset signal at start of evaluation
    ResetSignal();
    
    // Validate inputs
    if(!m_initialized) {
        Print("ERROR: ", m_name, " - Not initialized");
        return;
    }
    
    if(!ValidateCache()) {
        return;
    }
    
    if(!ValidateState(state)) {
        return;
    }
    
    // Store evaluation time
    m_lastEvalTime = state.timestamp;
    
    // Check if strategy should be active in current regime
    if(!CheckActivation(state)) {
        // Strategy is not active in this regime/condition
        return;
    }
    
    // Calculate signal (implemented by derived class)
    CalculateSignal(state);
    
    // Normalize strength to 0.0 - 1.0 range
    m_strength = NormalizeStrength(m_strength);
}

//+------------------------------------------------------------------+
//| Set adaptive weight (from RegimeMemory)                          |
//+------------------------------------------------------------------+
void BaseStrategy::SetAdaptiveWeight(double weight) {
    m_adaptiveWeight = MathMax(MIN_ADAPTIVE_WEIGHT, 
                                MathMin(MAX_ADAPTIVE_WEIGHT, weight));
}

//+------------------------------------------------------------------+
//| Set active regimes for this strategy                             |
//+------------------------------------------------------------------+
void BaseStrategy::SetActiveRegimes(ENUM_REGIME &regimes[], int count) {
    m_activeRegimeCount = MathMin(count, 4);
    for(int i = 0; i < m_activeRegimeCount; i++) {
        m_activeRegimes[i] = regimes[i];
    }
}

//+------------------------------------------------------------------+
//| Check if strategy is active in current regime                    |
//+------------------------------------------------------------------+
bool BaseStrategy::IsActiveInCurrentRegime(const MarketState &state) {
    if(m_activeRegimeCount == 0) {
        return true;  // Active in all regimes if none specified
    }
    
    for(int i = 0; i < m_activeRegimeCount; i++) {
        if(m_activeRegimes[i] == state.regime) {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| INDICATOR ACCESS METHODS                                          |
//+------------------------------------------------------------------+

double BaseStrategy::GetEMA(int period, int shift = 0) {
    if(m_cache == NULL) return 0.0;
    return m_cache.GetEMA(period);  // Cache returns current value
}

double BaseStrategy::GetSMA(int period, int shift = 0) {
    // SMA not cached, calculate directly
    double buffer[];
    ArraySetAsSeries(buffer, true);
    int copied = CopyBuffer(iMA(m_symbol, m_timeframe, period, 0, MODE_SMA, PRICE_CLOSE), 0, shift, 1, buffer);
    if(copied <= 0) return 0.0;
    return buffer[0];
}

double BaseStrategy::GetRSI(int shift = 0) {
    if(m_cache == NULL) return 0.0;
    return m_cache.GetRSI();
}

double BaseStrategy::GetMACD(int buffer, int shift = 0) {
    if(m_cache == NULL) return 0.0;
    return m_cache.GetMACD(buffer);
}

double BaseStrategy::GetATR(int shift = 0) {
    if(m_cache == NULL) return 0.0;
    return m_cache.GetATR();
}

double BaseStrategy::GetBB(int buffer, int shift = 0) {
    if(m_cache == NULL) return 0.0;
    return m_cache.GetBB(buffer);
}

double BaseStrategy::GetADX(int shift = 0) {
    if(m_cache == NULL) return 0.0;
    return m_cache.GetADX();
}

double BaseStrategy::GetStoch(int buffer, int shift = 0) {
    if(m_cache == NULL) return 0.0;
    return m_cache.GetStoch(buffer);
}

//+------------------------------------------------------------------+
//| PRICE ACTION METHODS                                              |
//+------------------------------------------------------------------+

double BaseStrategy::GetOpen(int shift = 0) {
    return iOpen(m_symbol, m_timeframe, shift);
}

double BaseStrategy::GetHigh(int shift = 0) {
    return iHigh(m_symbol, m_timeframe, shift);
}

double BaseStrategy::GetLow(int shift = 0) {
    return iLow(m_symbol, m_timeframe, shift);
}

double BaseStrategy::GetClose(int shift = 0) {
    return iClose(m_symbol, m_timeframe, shift);
}

double BaseStrategy::GetVolume(int shift = 0) {
    return (double)iVolume(m_symbol, m_timeframe, shift);
}

double BaseStrategy::GetAvgVolume(int periods = 20) {
    double sum = 0.0;
    for(int i = 0; i < periods; i++) {
        sum += GetVolume(i);
    }
    return sum / periods;
}

double BaseStrategy::GetCandleRange(int shift = 0) {
    return GetHigh(shift) - GetLow(shift);
}

double BaseStrategy::GetCandleBody(int shift = 0) {
    return MathAbs(GetClose(shift) - GetOpen(shift));
}

double BaseStrategy::GetUpperWick(int shift = 0) {
    double high = GetHigh(shift);
    double open = GetOpen(shift);
    double close = GetClose(shift);
    return high - MathMax(open, close);
}

double BaseStrategy::GetLowerWick(int shift = 0) {
    double low = GetLow(shift);
    double open = GetOpen(shift);
    double close = GetClose(shift);
    return MathMin(open, close) - low;
}

bool BaseStrategy::IsBullishCandle(int shift = 0) {
    return GetClose(shift) > GetOpen(shift);
}

bool BaseStrategy::IsBearishCandle(int shift = 0) {
    return GetClose(shift) < GetOpen(shift);
}

//+------------------------------------------------------------------+
//| CANDLESTICK PATTERN METHODS                                       |
//+------------------------------------------------------------------+

bool BaseStrategy::IsPinBar(int shift = 0, bool bullish = true) {
    double body = GetCandleBody(shift);
    double range = GetCandleRange(shift);
    double upperWick = GetUpperWick(shift);
    double lowerWick = GetLowerWick(shift);
    
    if(range == 0) return false;
    
    if(bullish) {
        // Bullish pin bar: long lower wick, small body
        return (lowerWick > body * 2) && (lowerWick > range * 0.6) && 
               (upperWick < body);
    } else {
        // Bearish pin bar: long upper wick, small body
        return (upperWick > body * 2) && (upperWick > range * 0.6) && 
               (lowerWick < body);
    }
}

bool BaseStrategy::IsEngulfing(int shift = 0, bool bullish = true) {
    if(shift < 0 || shift >= iBars(m_symbol, m_timeframe) - 1) return false;
    
    double body0 = GetCandleBody(shift);
    double body1 = GetCandleBody(shift + 1);
    
    if(bullish) {
        // Bullish engulfing: current bullish candle engulfs previous bearish
        return IsBullishCandle(shift) && IsBearishCandle(shift + 1) &&
               body0 > body1 &&
               GetClose(shift) > GetOpen(shift + 1) &&
               GetOpen(shift) < GetClose(shift + 1);
    } else {
        // Bearish engulfing: current bearish candle engulfs previous bullish
        return IsBearishCandle(shift) && IsBullishCandle(shift + 1) &&
               body0 > body1 &&
               GetClose(shift) < GetOpen(shift + 1) &&
               GetOpen(shift) > GetClose(shift + 1);
    }
}

bool BaseStrategy::IsDoji(int shift = 0) {
    double body = GetCandleBody(shift);
    double range = GetCandleRange(shift);
    
    if(range == 0) return false;
    
    // Body < 10% of range
    return (body / range) < 0.1;
}

bool BaseStrategy::IsHammer(int shift = 0) {
    return IsPinBar(shift, true) && IsBullishCandle(shift);
}

bool BaseStrategy::IsShootingStar(int shift = 0) {
    return IsPinBar(shift, false) && IsBearishCandle(shift);
}

bool BaseStrategy::IsInsideBar(int shift = 0) {
    if(shift < 0 || shift >= iBars(m_symbol, m_timeframe) - 1) return false;
    
    return GetHigh(shift) < GetHigh(shift + 1) &&
           GetLow(shift) > GetLow(shift + 1);
}

bool BaseStrategy::IsOutsideBar(int shift = 0) {
    if(shift < 0 || shift >= iBars(m_symbol, m_timeframe) - 1) return false;
    
    return GetHigh(shift) > GetHigh(shift + 1) &&
           GetLow(shift) < GetLow(shift + 1);
}

//+------------------------------------------------------------------+
//| Pattern wrapper methods (for convenience)                        |
//+------------------------------------------------------------------+

bool BaseStrategy::IsPinBarBullish(void) {
    return IsPinBar(0, true);
}

bool BaseStrategy::IsPinBarBearish(void) {
    return IsPinBar(0, false);
}

bool BaseStrategy::IsEngulfingBullish(void) {
    return IsEngulfing(0, true);
}

bool BaseStrategy::IsEngulfingBearish(void) {
    return IsEngulfing(0, false);
}

bool BaseStrategy::IsHammerPattern(void) {
    return IsHammer(0);
}

bool BaseStrategy::IsShootingStarPattern(void) {
    return IsShootingStar(0);
}

bool BaseStrategy::IsInsideBarPattern(void) {
    return IsInsideBar(0);
}

//+------------------------------------------------------------------+
//| MARKET STRUCTURE METHODS                                          |
//+------------------------------------------------------------------+

bool BaseStrategy::IsHigherHigh(int lookback = 10) {
    double currentHigh = GetHigh(0);
    for(int i = 1; i <= lookback; i++) {
        if(GetHigh(i) >= currentHigh) return false;
    }
    return true;
}

bool BaseStrategy::IsHigherLow(int lookback = 10) {
    double currentLow = GetLow(0);
    for(int i = 1; i <= lookback; i++) {
        if(GetLow(i) <= currentLow) return false;
    }
    return true;
}

bool BaseStrategy::IsLowerHigh(int lookback = 10) {
    double currentHigh = GetHigh(0);
    for(int i = 1; i <= lookback; i++) {
        if(GetHigh(i) <= currentHigh) return false;
    }
    return true;
}

bool BaseStrategy::IsLowerLow(int lookback = 10) {
    double currentLow = GetLow(0);
    for(int i = 1; i <= lookback; i++) {
        if(GetLow(i) >= currentLow) return false;
    }
    return true;
}

bool BaseStrategy::IsBullishStructure(int lookback = 20) {
    // Check for series of higher highs and higher lows
    int hhCount = 0;
    int hlCount = 0;
    
    for(int i = 0; i < lookback - 5; i += 5) {
        if(GetHigh(i) > GetHigh(i + 5)) hhCount++;
        if(GetLow(i) > GetLow(i + 5)) hlCount++;
    }
    
    return (hhCount >= 2 && hlCount >= 2);
}

bool BaseStrategy::IsBearishStructure(int lookback = 20) {
    // Check for series of lower highs and lower lows
    int lhCount = 0;
    int llCount = 0;
    
    for(int i = 0; i < lookback - 5; i += 5) {
        if(GetHigh(i) < GetHigh(i + 5)) lhCount++;
        if(GetLow(i) < GetLow(i + 5)) llCount++;
    }
    
    return (lhCount >= 2 && llCount >= 2);
}

//+------------------------------------------------------------------+
//| SUPPORT/RESISTANCE METHODS                                        |
//+------------------------------------------------------------------+

bool BaseStrategy::IsNearSupport(const MarketState &state, double threshold = 50) {
    return GetDistanceToSupport(state) <= threshold;
}

bool BaseStrategy::IsNearResistance(const MarketState &state, double threshold = 50) {
    return GetDistanceToResistance(state) <= threshold;
}

bool BaseStrategy::IsAtKeyLevel(const MarketState &state, double threshold = 50) {
    return IsNearSupport(state, threshold) || IsNearResistance(state, threshold);
}

bool BaseStrategy::IsInSupplyZone(const MarketState &state) {
    double price = state.bid;
    for(int i = 0; i < ArraySize(state.supplyZones); i++) {
        if(state.supplyZones[i] == 0) continue;
        double distance = MathAbs(price - state.supplyZones[i]) / _Point;
        if(distance <= ZONE_WIDTH_PIPS * 10) return true;
    }
    return false;
}

bool BaseStrategy::IsInDemandZone(const MarketState &state) {
    double price = state.bid;
    for(int i = 0; i < ArraySize(state.demandZones); i++) {
        if(state.demandZones[i] == 0) continue;
        double distance = MathAbs(price - state.demandZones[i]) / _Point;
        if(distance <= ZONE_WIDTH_PIPS * 10) return true;
    }
    return false;
}

double BaseStrategy::GetDistanceToSupport(const MarketState &state) {
    if(state.nearestSupport == 0) return 999999;
    return MathAbs(state.bid - state.nearestSupport) / _Point;
}

double BaseStrategy::GetDistanceToResistance(const MarketState &state) {
    if(state.nearestResistance == 0) return 999999;
    return MathAbs(state.bid - state.nearestResistance) / _Point;
}

//+------------------------------------------------------------------+
//| TREND DETECTION METHODS                                           |
//+------------------------------------------------------------------+

bool BaseStrategy::IsUptrend(const MarketState &state) {
    return state.trendDir == TREND_UP;
}

bool BaseStrategy::IsDowntrend(const MarketState &state) {
    return state.trendDir == TREND_DOWN;
}

bool BaseStrategy::IsRanging(const MarketState &state) {
    return state.regime == REGIME_RANGING;
}

bool BaseStrategy::EMAsAligned(bool bullish) {
    double ema21 = GetEMA(21);
    double ema50 = GetEMA(50);
    double ema200 = GetEMA(200);
    
    if(ema21 == 0 || ema50 == 0 || ema200 == 0) return false;
    
    if(bullish) {
        return (ema21 > ema50) && (ema50 > ema200);
    } else {
        return (ema21 < ema50) && (ema50 < ema200);
    }
}

int BaseStrategy::GetTrendStrength(const MarketState &state) {
    int strength = 0;
    
    // ADX contribution (0-40 points)
    if(state.adx > 40) strength += 40;
    else if(state.adx > 25) strength += (int)state.adx;
    
    // EMA alignment (0-30 points)
    if(EMAsAligned(true) || EMAsAligned(false)) strength += 30;
    
    // Structure (0-30 points)
    if(state.structure == STRUCTURE_HH_HL || state.structure == STRUCTURE_LL_LH) {
        strength += 30;
    }
    
    return MathMin(100, strength);
}

//+------------------------------------------------------------------+
//| MOMENTUM & DIVERGENCE METHODS                                     |
//+------------------------------------------------------------------+

bool BaseStrategy::IsMomentumBullish(void) {
    double rsi = GetRSI();
    double macdMain = GetMACD(0);
    double stochK = GetStoch(0);
    
    int bullishCount = 0;
    if(rsi > 50) bullishCount++;
    if(macdMain > 0) bullishCount++;
    if(stochK > 50) bullishCount++;
    
    return bullishCount >= 2;
}

bool BaseStrategy::IsMomentumBearish(void) {
    double rsi = GetRSI();
    double macdMain = GetMACD(0);
    double stochK = GetStoch(0);
    
    int bearishCount = 0;
    if(rsi < 50) bearishCount++;
    if(macdMain < 0) bearishCount++;
    if(stochK < 50) bearishCount++;
    
    return bearishCount >= 2;
}

bool BaseStrategy::IsRSIOverBought(double level = 70) {
    return GetRSI() > level;
}

bool BaseStrategy::IsRSIOversold(double level = 30) {
    return GetRSI() < level;
}

bool BaseStrategy::IsMACDCrossBullish(void) {
    double macdMain0 = GetMACD(0, 0);
    double macdSignal0 = GetMACD(1, 0);
    // Note: For proper cross detection, we'd need shift=1 values
    // This is a simplified version
    return (macdMain0 > macdSignal0) && (macdMain0 > 0);
}

bool BaseStrategy::IsMACDCrossBearish(void) {
    double macdMain0 = GetMACD(0, 0);
    double macdSignal0 = GetMACD(1, 0);
    return (macdMain0 < macdSignal0) && (macdMain0 < 0);
}

//+------------------------------------------------------------------+
//| VOLATILITY METHODS                                                |
//+------------------------------------------------------------------+

bool BaseStrategy::IsHighVolatility(const MarketState &state) {
    return state.atrRatio > ATR_HIGH_VOLATILITY;
}

bool BaseStrategy::IsLowVolatility(const MarketState &state) {
    return state.atrRatio < ATR_LOW_VOLATILITY;
}

bool BaseStrategy::IsBBSqueeze(void) {
    double bbUpper = GetBB(0);
    double bbLower = GetBB(2);
    double bbWidth = bbUpper - bbLower;
    
    // Calculate average width over last 20 bars
    // Simplified: just check if current width is small
    double atr = GetATR();
    return (bbWidth < atr * 1.5);
}

bool BaseStrategy::IsBBExpansion(void) {
    return !IsBBSqueeze();
}

bool BaseStrategy::IsPriceAtUpperBB(void) {
    double close = GetClose(0);
    double bbUpper = GetBB(0);
    return MathAbs(close - bbUpper) < (bbUpper * 0.001);  // Within 0.1%
}

bool BaseStrategy::IsPriceAtLowerBB(void) {
    double close = GetClose(0);
    double bbLower = GetBB(2);
    return MathAbs(close - bbLower) < (bbLower * 0.001);
}

//+------------------------------------------------------------------+
//| REGIME & SESSION METHODS                                          |
//+------------------------------------------------------------------+

bool BaseStrategy::IsActiveInRegime(ENUM_REGIME regime) {
    for(int i = 0; i < m_activeRegimeCount; i++) {
        if(m_activeRegimes[i] == regime) return true;
    }
    return false;
}

bool BaseStrategy::IsGoldenHour(const MarketState &state) {
    return state.isGoldenHour;
}

bool BaseStrategy::IsDeadZone(const MarketState &state) {
    int hour = state.hourWIT;
    return (hour >= DEAD_ZONE_1_START && hour < DEAD_ZONE_1_END) ||
           (hour >= DEAD_ZONE_2_START && hour < DEAD_ZONE_2_END);
}

bool BaseStrategy::IsHighLiquiditySession(const MarketState &state) {
    return state.session == SESSION_OVERLAP || state.session == SESSION_LONDON;
}

//+------------------------------------------------------------------+
//| VALIDATION & ERROR HANDLING                                       |
//+------------------------------------------------------------------+

bool BaseStrategy::ValidateCache(void) {
    if(m_cache == NULL) {
        Print("ERROR: ", m_name, " - IndicatorCache is NULL");
        return false;
    }
    
    if(m_cache.IsStale()) {
        // Cache data is stale, but not a critical error
        return true;
    }
    
    return true;
}

bool BaseStrategy::ValidateState(const MarketState &state) {
    if(state.timestamp == 0) {
        Print("WARNING: ", m_name, " - Invalid timestamp in MarketState");
        return false;
    }
    
    if(state.bid <= 0 || state.ask <= 0) {
        Print("WARNING: ", m_name, " - Invalid price in MarketState");
        return false;
    }
    
    return true;
}

double BaseStrategy::NormalizeStrength(double value) {
    return MathMax(0.0, MathMin(1.0, value));
}

void BaseStrategy::ResetSignal(void) {
    m_signal = SIGNAL_NONE;
    m_strength = 0.0;
}

//+------------------------------------------------------------------+
//| UTILITY METHODS                                                   |
//+------------------------------------------------------------------+

double BaseStrategy::PointsToPips(double points) {
    return points / 10.0;  // For XAUUSD: 10 points = 1 pip
}

double BaseStrategy::PipsToPoints(double pips) {
    return pips * 10.0;
}

string BaseStrategy::SignalToString(ENUM_SIGNAL signal) {
    switch(signal) {
        case SIGNAL_BUY:  return "BUY";
        case SIGNAL_SELL: return "SELL";
        case SIGNAL_NONE: return "NONE";
        default:          return "UNKNOWN";
    }
}

string BaseStrategy::RegimeToString(ENUM_REGIME regime) {
    switch(regime) {
        case REGIME_TRENDING: return "TRENDING";
        case REGIME_RANGING:  return "RANGING";
        case REGIME_VOLATILE: return "VOLATILE";
        case REGIME_CALM:     return "CALM";
        default:              return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| Calculate average volume over specified periods                  |
//+------------------------------------------------------------------+
double BaseStrategy::GetAverageVolume(int periods = 20) {
    if(periods <= 0) return 0.0;
    
    double sum = 0.0;
    int count = 0;
    
    for(int i = 1; i <= periods; i++) {  // Start from 1 to exclude current bar
        double volume = GetVolume(i);  // Fixed: double instead of long
        if(volume > 0) {
            sum += volume;
            count++;
        }
    }
    
    return (count > 0) ? sum / count : 0.0;
}

//+------------------------------------------------------------------+
//| END OF BASE STRATEGY                                              |
//+------------------------------------------------------------------+
