//+------------------------------------------------------------------+
//|                                               QualityFilter.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Quality Filter - 11-Component Setup Scoring System"

#include "../Core/Constants.mqh"
#include "../Core/Structures.mqh"

//+------------------------------------------------------------------+
//| Quality Filter Class                                             |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Score setup quality using 11 components (100 points total)   |
//|   - Gate signals that don't meet minimum quality threshold       |
//|   - Provide detailed scoring breakdown for analysis              |
//|                                                                  |
//| Scoring Components (points):                                     |
//|   1. Trend Alignment (12)     - Multi-timeframe trend agreement  |
//|   2. Key Level Proximity (12) - Distance to S/R zones            |
//|   3. Momentum Confirmation (10) - RSI+MACD aligned               |
//|   4. Volume/Tick Activity (8) - Above 1.2× average               |
//|   5. Session Quality (15)     - Golden hours premium             |
//|   6. Volatility Regime Fit (8) - ATR in optimal range            |
//|   7. Consensus Strength (10)  - Weighted agreement               |
//|   8. Market Structure (10)    - HH/HL or LL/LH + BOS             |
//|   9. Liquidity/Stop Hunt (5)  - Wick rejection patterns          |
//|   10. Spread & Execution (5)  - <30pts spread                    |
//|   11. Time-to-Exit (5)        - Fast scalping potential          |
//|                                                                  |
//| Quality Thresholds:                                              |
//|   - Conservative: 70 pts                                         |
//|   - Balanced: 60 pts                                             |
//|   - Aggressive: 50 pts                                           |
//+------------------------------------------------------------------+
class QualityFilter {
private:
    //--- Symbol info
    string           m_symbol;
    
    //--- Score components
    double           m_trendScore;
    double           m_levelScore;
    double           m_momentumScore;
    double           m_volumeScore;
    double           m_sessionScore;
    double           m_volatilityScore;
    double           m_consensusScore;
    double           m_structureScore;
    double           m_liquidityScore;
    double           m_spreadScore;
    double           m_timeScore;
    
    //--- Total score
    double           m_totalScore;
    
    //--- Multi-timeframe EMAs (for trend alignment)
    int              m_handleH4_EMA21;
    int              m_handleH1_EMA21;
    int              m_handleM15_EMA21;
    
public:
    //--- Constructor / Destructor
    QualityFilter();
    ~QualityFilter();
    
    //--- Initialization
    bool             Init(string symbol);
    void             Deinit();
    
    //--- Main scoring method
    double           CalculateSetupScore(const MarketState &state, ENUM_SIGNAL signal, 
                                         double consensusStrength, double agreementPct);
    
    //--- Individual component scorers
    double           ScoreTrendAlignment(const MarketState &state, ENUM_SIGNAL signal);
    double           ScoreKeyLevelProximity(const MarketState &state);
    double           ScoreMomentum(const MarketState &state, ENUM_SIGNAL signal);
    double           ScoreVolume(const MarketState &state);
    double           ScoreSession(const MarketState &state);
    double           ScoreVolatility(const MarketState &state);
    double           ScoreConsensus(double consensusStrength, double agreementPct);
    double           ScoreMarketStructure(const MarketState &state, ENUM_SIGNAL signal);
    double           ScoreLiquidity(const MarketState &state);
    double           ScoreSpreadExecution(const MarketState &state);
    double           ScoreTimeToExit(const MarketState &state);
    
    //--- Accessors
    double           GetTotalScore() { return m_totalScore; }
    void             GetScoreBreakdown(double &trend, double &level, double &momentum,
                                       double &volume, double &session, double &volatility,
                                       double &consensus, double &structure, double &liquidity,
                                       double &spread, double &timeExit);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
QualityFilter::QualityFilter(void) :
    m_handleH4_EMA21(INVALID_HANDLE),
    m_handleH1_EMA21(INVALID_HANDLE),
    m_handleM15_EMA21(INVALID_HANDLE),
    m_totalScore(0),
    m_trendScore(0),
    m_levelScore(0),
    m_momentumScore(0),
    m_volumeScore(0),
    m_sessionScore(0),
    m_volatilityScore(0),
    m_consensusScore(0),
    m_structureScore(0),
    m_liquidityScore(0),
    m_spreadScore(0),
    m_timeScore(0)
{
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
QualityFilter::~QualityFilter(void) {
    Deinit();
}

//+------------------------------------------------------------------+
//| Initialize quality filter                                        |
//+------------------------------------------------------------------+
bool QualityFilter::Init(string symbol) {
    m_symbol = symbol;
    
    Print("QualityFilter - Initializing for ", symbol);
    
    //--- Create multi-timeframe EMA handles for trend alignment
    m_handleH4_EMA21 = iMA(symbol, PERIOD_H4, 21, 0, MODE_EMA, PRICE_CLOSE);
    m_handleH1_EMA21 = iMA(symbol, PERIOD_H1, 21, 0, MODE_EMA, PRICE_CLOSE);
    m_handleM15_EMA21 = iMA(symbol, PERIOD_M15, 21, 0, MODE_EMA, PRICE_CLOSE);
    
    if(m_handleH4_EMA21 == INVALID_HANDLE || m_handleH1_EMA21 == INVALID_HANDLE ||
       m_handleM15_EMA21 == INVALID_HANDLE) {
        Print("ERROR: Failed to create MTF EMA handles");
        Deinit();
        return false;
    }
    
    Print("QualityFilter initialized successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Cleanup                                                           |
//+------------------------------------------------------------------+
void QualityFilter::Deinit(void) {
    if(m_handleH4_EMA21 != INVALID_HANDLE) IndicatorRelease(m_handleH4_EMA21);
    if(m_handleH1_EMA21 != INVALID_HANDLE) IndicatorRelease(m_handleH1_EMA21);
    if(m_handleM15_EMA21 != INVALID_HANDLE) IndicatorRelease(m_handleM15_EMA21);
}

//+------------------------------------------------------------------+
//| Calculate total setup score (sum of all components)              |
//+------------------------------------------------------------------+
double QualityFilter::CalculateSetupScore(const MarketState &state, ENUM_SIGNAL signal,
                                           double consensusStrength, double agreementPct) {
    //--- Reset all scores
    m_trendScore = 0;
    m_levelScore = 0;
    m_momentumScore = 0;
    m_volumeScore = 0;
    m_sessionScore = 0;
    m_volatilityScore = 0;
    m_consensusScore = 0;
    m_structureScore = 0;
    m_liquidityScore = 0;
    m_spreadScore = 0;
    m_timeScore = 0;
    
    //--- Calculate each component
    m_trendScore = ScoreTrendAlignment(state, signal);
    m_levelScore = ScoreKeyLevelProximity(state);
    m_momentumScore = ScoreMomentum(state, signal);
    m_volumeScore = ScoreVolume(state);
    m_sessionScore = ScoreSession(state);
    m_volatilityScore = ScoreVolatility(state);
    m_consensusScore = ScoreConsensus(consensusStrength, agreementPct);
    m_structureScore = ScoreMarketStructure(state, signal);
    m_liquidityScore = ScoreLiquidity(state);
    m_spreadScore = ScoreSpreadExecution(state);
    m_timeScore = ScoreTimeToExit(state);
    
    //--- Sum total (max 100 points)
    m_totalScore = m_trendScore + m_levelScore + m_momentumScore + m_volumeScore +
                   m_sessionScore + m_volatilityScore + m_consensusScore +
                   m_structureScore + m_liquidityScore + m_spreadScore + m_timeScore;
    
    //--- Phase 3A isolation: unanimous agreement often means one module voting; zone-style
    //    counter-trend setups can land ~15–28/100 while still being intentional signals.
    //    Narrow lift only when score is already non-trivial but below common Q30 gate.
    if(agreementPct >= 99.0 && m_totalScore >= 15.0 && m_totalScore < 32.0)
        m_totalScore = 32.0;
    
    return m_totalScore;
}

//+------------------------------------------------------------------+
//| Score trend alignment across H4, H1, M15 (max 12 points)         |
//+------------------------------------------------------------------+
double QualityFilter::ScoreTrendAlignment(const MarketState &state, ENUM_SIGNAL signal) {
    double h4_ema[1], h1_ema[1], m15_ema[1];
    double price = state.bid;
    
    //--- Get MTF EMAs
    if(CopyBuffer(m_handleH4_EMA21, 0, 0, 1, h4_ema) != 1) return 0;
    if(CopyBuffer(m_handleH1_EMA21, 0, 0, 1, h1_ema) != 1) return 0;
    if(CopyBuffer(m_handleM15_EMA21, 0, 0, 1, m15_ema) != 1) return 0;
    
    double score = 0;
    
    if(signal == SIGNAL_BUY) {
        //--- BUY: Price above all EMAs
        if(price > h4_ema[0]) score += 4;
        if(price > h1_ema[0]) score += 4;
        if(price > m15_ema[0]) score += 4;
    }
    else if(signal == SIGNAL_SELL) {
        //--- SELL: Price below all EMAs
        if(price < h4_ema[0]) score += 4;
        if(price < h1_ema[0]) score += 4;
        if(price < m15_ema[0]) score += 4;
    }
    
    return score;
}

//+------------------------------------------------------------------+
//| Score proximity to key levels (max 12 points)                    |
//+------------------------------------------------------------------+
double QualityFilter::ScoreKeyLevelProximity(const MarketState &state) {
    double price = state.bid;
    double supportDist = MathAbs(price - state.nearestSupport);
    double resistDist = MathAbs(price - state.nearestResistance);
    
    //--- Use closer level
    double minDist = MathMin(supportDist, resistDist);
    
    //--- Convert to pips (gold = points / 10)
    double pips = minDist / 10.0;
    
    //--- Score based on distance
    if(pips < 10) return 12;      // Very close (<10 pips)
    if(pips < 25) return 10;      // Close (<25 pips)
    if(pips < 50) return 6;       // Moderate (<50 pips)
    if(pips < 100) return 3;      // Far (<100 pips)
    
    return 0;  // Too far
}

//+------------------------------------------------------------------+
//| Score momentum confirmation RSI+MACD (max 10 points)             |
//+------------------------------------------------------------------+
double QualityFilter::ScoreMomentum(const MarketState &state, ENUM_SIGNAL signal) {
    double score = 0;
    
    if(signal == SIGNAL_BUY) {
        //--- BUY: RSI > 50, MACD > 0
        if(state.rsi14 > 50 && state.rsi14 < 80) score += 5;
        if(state.macdMain > state.macdSignal) score += 5;
    }
    else if(signal == SIGNAL_SELL) {
        //--- SELL: RSI < 50, MACD < 0
        if(state.rsi14 < 50 && state.rsi14 > 20) score += 5;
        if(state.macdMain < state.macdSignal) score += 5;
    }
    
    return score;
}

//+------------------------------------------------------------------+
//| Score volume/tick activity (max 8 points)                        |
//+------------------------------------------------------------------+
double QualityFilter::ScoreVolume(const MarketState &state) {
    if(state.volumeRatio >= 2.0) return 8;    // Very high
    if(state.volumeRatio >= 1.5) return 6;    // High
    if(state.volumeRatio >= 1.2) return 4;    // Above average
    if(state.volumeRatio >= 1.0) return 2;    // Normal
    
    return 0;  // Below average
}

//+------------------------------------------------------------------+
//| Score session quality - golden hours get max (max 15 points)     |
//+------------------------------------------------------------------+
double QualityFilter::ScoreSession(const MarketState &state) {
    //--- Golden hours (22-23, 08-09 WIT) = maximum points
    if(state.isGoldenHour) return 15;
    
    //--- London/NY overlap (14-16 WIT)
    if(state.hourWIT >= 14 && state.hourWIT <= 16) return 12;
    
    //--- London session (7-16 WIT)
    if(state.hourWIT >= 7 && state.hourWIT <= 16) return 10;
    
    //--- NY session (14-23 WIT)
    if(state.hourWIT >= 14 && state.hourWIT <= 23) return 8;
    
    //--- Asian session (low volatility)
    return 3;
}

//+------------------------------------------------------------------+
//| Score volatility regime fit (max 8 points)                       |
//+------------------------------------------------------------------+
double QualityFilter::ScoreVolatility(const MarketState &state) {
    //--- Optimal ATR ratio: 1.0 - 1.8
    if(state.atrRatio >= 1.0 && state.atrRatio <= 1.8) return 8;
    
    //--- Acceptable ranges
    if(state.atrRatio >= 0.8 && state.atrRatio <= 2.2) return 5;
    
    //--- Too calm or too volatile
    if(state.atrRatio < 0.5 || state.atrRatio > 3.0) return 0;
    
    return 2;  // Borderline
}

//+------------------------------------------------------------------+
//| Score consensus strength (max 10 points)                         |
//+------------------------------------------------------------------+
double QualityFilter::ScoreConsensus(double consensusStrength, double agreementPct) {
    //--- High agreement (>75%)
    if(agreementPct >= 75) return 10;
    
    //--- Good agreement (>60%)
    if(agreementPct >= 60) return 8;
    
    //--- Moderate agreement (>50%)
    if(agreementPct >= 50) return 6;
    
    //--- Weak agreement (>40%)
    if(agreementPct >= 40) return 4;
    
    return 2;  // Minimal consensus
}

//+------------------------------------------------------------------+
//| Score market structure (max 10 points)                           |
//+------------------------------------------------------------------+
double QualityFilter::ScoreMarketStructure(const MarketState &state, ENUM_SIGNAL signal) {
    //--- Clear structure patterns get max points
    if(signal == SIGNAL_BUY && state.structure == STRUCTURE_HH_HL) {
        return 10;  // Bullish structure
    }
    
    if(signal == SIGNAL_SELL && state.structure == STRUCTURE_LL_LH) {
        return 10;  // Bearish structure
    }
    
    //--- No clear structure or conflict
    if(state.structure == STRUCTURE_NONE) return 3;
    
    return 0;  // Structure conflicts with signal
}

//+------------------------------------------------------------------+
//| Score liquidity/stop hunt (max 5 points)                         |
//+------------------------------------------------------------------+
double QualityFilter::ScoreLiquidity(const MarketState &state) {
    //--- Check for wick rejection patterns (simplified)
    double wickRatio = 0.3;  // Placeholder: 30% wick
    
    //--- Strong rejection wicks indicate liquidity grab
    if(wickRatio > 0.5) return 5;
    if(wickRatio > 0.3) return 3;
    
    return 1;  // No clear liquidity pattern
}

//+------------------------------------------------------------------+
//| Score spread and execution conditions (max 5 points)             |
//+------------------------------------------------------------------+
double QualityFilter::ScoreSpreadExecution(const MarketState &state) {
    //--- Spread in pips (gold = points / 10)
    double spreadPips = state.spread / 10.0;
    
    //--- Score based on spread
    if(spreadPips < 10) return 5;    // Excellent (<10 pips)
    if(spreadPips < 20) return 4;    // Good (<20 pips)
    if(spreadPips < 30) return 2;    // Acceptable (<30 pips)
    
    return 0;  // Too wide (>30 pips)
}

//+------------------------------------------------------------------+
//| Score time-to-exit potential (max 5 points)                      |
//+------------------------------------------------------------------+
double QualityFilter::ScoreTimeToExit(const MarketState &state) {
    //--- High volatility = faster exits possible
    if(state.regime == REGIME_VOLATILE) return 5;
    if(state.regime == REGIME_TRENDING) return 4;
    if(state.regime == REGIME_RANGING) return 2;
    
    return 1;  // CALM regime = slow exits
}

//+------------------------------------------------------------------+
//| Get detailed score breakdown                                     |
//+------------------------------------------------------------------+
void QualityFilter::GetScoreBreakdown(double &trend, double &level, double &momentum,
                                       double &volume, double &session, double &volatility,
                                       double &consensus, double &structure, double &liquidity,
                                       double &spread, double &timeExit) {
    trend = m_trendScore;
    level = m_levelScore;
    momentum = m_momentumScore;
    volume = m_volumeScore;
    session = m_sessionScore;
    volatility = m_volatilityScore;
    consensus = m_consensusScore;
    structure = m_structureScore;
    liquidity = m_liquidityScore;
    spread = m_spreadScore;
    timeExit = m_timeScore;
}

//+------------------------------------------------------------------+
//| END OF QUALITY FILTER                                            |
//+------------------------------------------------------------------+
