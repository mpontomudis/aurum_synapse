//+------------------------------------------------------------------+
//|                                              MarketAnalyzer.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Market Analyzer - Regime Classification & Market State Detection"

#include "../Core/Constants.mqh"
#include "../Core/Structures.mqh"

//+------------------------------------------------------------------+
//| Market Analyzer Class                                            |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Classify market regime (TRENDING/RANGING/VOLATILE/CALM)     |
//|   - Detect trend direction and market structure                  |
//|   - Identify trading sessions and golden hours                   |
//|   - Find key support/resistance levels                           |
//|   - Calculate volatility metrics (ATR ratio)                     |
//|   - Update state on H1 bar close (efficiency)                    |
//|                                                                  |
//| Regime Classification Logic:                                     |
//|   TRENDING: ADX > 25                                             |
//|   VOLATILE: ATR ratio > 1.5                                      |
//|   CALM: ADX < 15 AND BB width < 0.01                             |
//|   RANGING: Default (ADX 15-25, normal volatility)                |
//+------------------------------------------------------------------+
class MarketAnalyzer {
private:
    //--- Symbol and timeframe
    string           m_symbol;
    ENUM_TIMEFRAMES  m_timeframe;
    
    //--- Indicator handles
    int              m_handleEMA21;
    int              m_handleEMA50;
    int              m_handleEMA200;
    int              m_handleRSI14;
    int              m_handleMACD;
    int              m_handleBB;
    int              m_handleATR14;
    int              m_handleADX14;
    int              m_handleStoch;
    
    //--- State management
    datetime         m_lastH1Close;
    MarketState      m_currentState;
    bool             m_initialized;
    
    //--- Analysis methods
    ENUM_REGIME      DetectRegime();
    ENUM_TREND_DIR   DetectTrend();
    ENUM_STRUCTURE   DetectStructure();
    ENUM_SESSION     DetectSession();
    void             FindKeyLevels();
    void             UpdateIndicators();
    void             CalculateATRRatio();
    bool             IsTrendingMarket();
    bool             IsRangingMarket();
    bool             IsVolatileMarket();
    bool             IsCalmMarket();
    
public:
    //--- Constructor / Destructor
    MarketAnalyzer();
    ~MarketAnalyzer();
    
    //--- Initialization
    bool             Init(string symbol, ENUM_TIMEFRAMES timeframe);
    void             Deinit();
    
    //--- Main update method
    bool             Update();
    void             GetMarketState(MarketState &state);
    ENUM_REGIME      ClassifyMarket();
    
    //--- Accessors
    MarketState      GetState() const { return m_currentState; }
    bool             IsStale();
    bool             IsInitialized() { return m_initialized; }
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
MarketAnalyzer::MarketAnalyzer(void) :
    m_handleEMA21(INVALID_HANDLE),
    m_handleEMA50(INVALID_HANDLE),
    m_handleEMA200(INVALID_HANDLE),
    m_handleRSI14(INVALID_HANDLE),
    m_handleMACD(INVALID_HANDLE),
    m_handleBB(INVALID_HANDLE),
    m_handleATR14(INVALID_HANDLE),
    m_handleADX14(INVALID_HANDLE),
    m_handleStoch(INVALID_HANDLE),
    m_lastH1Close(0),
    m_initialized(false)
{
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
MarketAnalyzer::~MarketAnalyzer(void) {
    Deinit();
}

//+------------------------------------------------------------------+
//| Initialize market analyzer                                       |
//+------------------------------------------------------------------+
bool MarketAnalyzer::Init(string symbol, ENUM_TIMEFRAMES timeframe) {
    m_symbol = symbol;
    m_timeframe = timeframe;
    
    Print("MarketAnalyzer - Initializing for ", symbol);
    
    //--- Create indicator handles
    m_handleEMA21 = iMA(symbol, PERIOD_H1, 21, 0, MODE_EMA, PRICE_CLOSE);
    m_handleEMA50 = iMA(symbol, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE);
    m_handleEMA200 = iMA(symbol, PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE);
    m_handleRSI14 = iRSI(symbol, PERIOD_H1, 14, PRICE_CLOSE);
    m_handleMACD = iMACD(symbol, PERIOD_H1, 12, 26, 9, PRICE_CLOSE);
    m_handleBB = iBands(symbol, PERIOD_H1, 20, 0, 2.0, PRICE_CLOSE);
    m_handleATR14 = iATR(symbol, PERIOD_H1, 14);
    m_handleADX14 = iADX(symbol, PERIOD_H1, 14);
    m_handleStoch = iStochastic(symbol, PERIOD_H1, 5, 3, 3, MODE_SMA, STO_LOWHIGH);
    
    //--- Validate handles
    if(m_handleEMA21 == INVALID_HANDLE || m_handleEMA50 == INVALID_HANDLE ||
       m_handleEMA200 == INVALID_HANDLE || m_handleRSI14 == INVALID_HANDLE ||
       m_handleMACD == INVALID_HANDLE || m_handleBB == INVALID_HANDLE ||
       m_handleATR14 == INVALID_HANDLE || m_handleADX14 == INVALID_HANDLE ||
       m_handleStoch == INVALID_HANDLE) {
        Print("ERROR: Failed to create indicator handles");
        Deinit();
        return false;
    }
    
    m_initialized = true;
    Print("MarketAnalyzer initialized successfully");
    
    return true;
}

//+------------------------------------------------------------------+
//| Cleanup                                                           |
//+------------------------------------------------------------------+
void MarketAnalyzer::Deinit(void) {
    if(m_handleEMA21 != INVALID_HANDLE) IndicatorRelease(m_handleEMA21);
    if(m_handleEMA50 != INVALID_HANDLE) IndicatorRelease(m_handleEMA50);
    if(m_handleEMA200 != INVALID_HANDLE) IndicatorRelease(m_handleEMA200);
    if(m_handleRSI14 != INVALID_HANDLE) IndicatorRelease(m_handleRSI14);
    if(m_handleMACD != INVALID_HANDLE) IndicatorRelease(m_handleMACD);
    if(m_handleBB != INVALID_HANDLE) IndicatorRelease(m_handleBB);
    if(m_handleATR14 != INVALID_HANDLE) IndicatorRelease(m_handleATR14);
    if(m_handleADX14 != INVALID_HANDLE) IndicatorRelease(m_handleADX14);
    if(m_handleStoch != INVALID_HANDLE) IndicatorRelease(m_handleStoch);
    
    m_initialized = false;
}

//+------------------------------------------------------------------+
//| Update market state (called on each tick, updates on H1 close)   |
//+------------------------------------------------------------------+
bool MarketAnalyzer::Update(void) {
    if(!m_initialized) return false;
    
    //--- Update only on H1 bar close (efficiency)
    datetime currentH1Close = iTime(m_symbol, PERIOD_H1, 0);
    if(currentH1Close == m_lastH1Close) {
        return true;  // Use cached state
    }
    
    m_lastH1Close = currentH1Close;
    
    //--- Update current prices
    m_currentState.bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
    m_currentState.ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
    m_currentState.spread = (m_currentState.ask - m_currentState.bid) / _Point;
    m_currentState.timestamp = TimeCurrent();
    m_currentState.isNewBar = true;
    
    //--- Update indicators
    UpdateIndicators();
    
    //--- Classify market
    m_currentState.regime = DetectRegime();
    m_currentState.trendDir = DetectTrend();
    m_currentState.structure = DetectStructure();
    m_currentState.session = DetectSession();
    
    //--- Find key levels
    FindKeyLevels();
    
    //--- Calculate ATR ratio
    CalculateATRRatio();
    
    //--- Volume data
    m_currentState.tickVolume = (double)iVolume(m_symbol, m_timeframe, 0);
    m_currentState.avgTickVolume = m_currentState.tickVolume;  // Simplified
    m_currentState.volumeRatio = 1.0;
    
    return true;
}

//+------------------------------------------------------------------+
//| Get market state (copy to external variable)                     |
//+------------------------------------------------------------------+
void MarketAnalyzer::GetMarketState(MarketState &state) {
    state = m_currentState;
}

//+------------------------------------------------------------------+
//| Classify market regime                                           |
//+------------------------------------------------------------------+
ENUM_REGIME MarketAnalyzer::ClassifyMarket(void) {
    return DetectRegime();
}

//+------------------------------------------------------------------+
//| Update all indicator values                                      |
//+------------------------------------------------------------------+
void MarketAnalyzer::UpdateIndicators(void) {
    double buffer[1];
    
    //--- EMAs
    if(CopyBuffer(m_handleEMA21, 0, 0, 1, buffer) == 1) m_currentState.ema21 = buffer[0];
    if(CopyBuffer(m_handleEMA50, 0, 0, 1, buffer) == 1) m_currentState.ema50 = buffer[0];
    if(CopyBuffer(m_handleEMA200, 0, 0, 1, buffer) == 1) m_currentState.ema200 = buffer[0];
    
    //--- RSI
    if(CopyBuffer(m_handleRSI14, 0, 0, 1, buffer) == 1) m_currentState.rsi14 = buffer[0];
    
    //--- MACD
    if(CopyBuffer(m_handleMACD, 0, 0, 1, buffer) == 1) m_currentState.macdMain = buffer[0];
    if(CopyBuffer(m_handleMACD, 1, 0, 1, buffer) == 1) m_currentState.macdSignal = buffer[0];
    
    //--- ADX
    if(CopyBuffer(m_handleADX14, 0, 0, 1, buffer) == 1) m_currentState.adx = buffer[0];
    
    //--- Bollinger Bands
    if(CopyBuffer(m_handleBB, 1, 0, 1, buffer) == 1) m_currentState.bbUpper = buffer[0];
    if(CopyBuffer(m_handleBB, 0, 0, 1, buffer) == 1) m_currentState.bbMiddle = buffer[0];
    if(CopyBuffer(m_handleBB, 2, 0, 1, buffer) == 1) m_currentState.bbLower = buffer[0];
    
    //--- Stochastic
    if(CopyBuffer(m_handleStoch, 0, 0, 1, buffer) == 1) m_currentState.stochK = buffer[0];
    if(CopyBuffer(m_handleStoch, 1, 0, 1, buffer) == 1) m_currentState.stochD = buffer[0];
    
    //--- ATR
    if(CopyBuffer(m_handleATR14, 0, 0, 1, buffer) == 1) m_currentState.atr14 = buffer[0];
}

//+------------------------------------------------------------------+
//| Calculate ATR ratio (current / 20-bar average)                   |
//+------------------------------------------------------------------+
void MarketAnalyzer::CalculateATRRatio(void) {
    double atrArray[20];
    if(CopyBuffer(m_handleATR14, 0, 0, 20, atrArray) == 20) {
        double sum = 0;
        for(int i = 0; i < 20; i++) {
            sum += atrArray[i];
        }
        double avgATR = sum / 20.0;
        m_currentState.atrRatio = (avgATR > 0) ? m_currentState.atr14 / avgATR : 1.0;
    } else {
        m_currentState.atrRatio = 1.0;
    }
}

//+------------------------------------------------------------------+
//| Detect market regime                                             |
//+------------------------------------------------------------------+
ENUM_REGIME MarketAnalyzer::DetectRegime(void) {
    if(IsTrendingMarket()) return REGIME_TRENDING;
    if(IsCalmMarket()) return REGIME_CALM;
    if(IsVolatileMarket()) return REGIME_VOLATILE;
    return REGIME_RANGING;  // Default
}

//+------------------------------------------------------------------+
//| Check if market is trending                                      |
//+------------------------------------------------------------------+
bool MarketAnalyzer::IsTrendingMarket(void) {
    return (m_currentState.adx > 25);
}

//+------------------------------------------------------------------+
//| Check if market is ranging                                       |
//+------------------------------------------------------------------+
bool MarketAnalyzer::IsRangingMarket(void) {
    return (m_currentState.adx >= 15 && m_currentState.adx <= 25 && 
            m_currentState.atrRatio <= 1.5);
}

//+------------------------------------------------------------------+
//| Check if market is volatile                                      |
//+------------------------------------------------------------------+
bool MarketAnalyzer::IsVolatileMarket(void) {
    return (m_currentState.atrRatio > 1.5);
}

//+------------------------------------------------------------------+
//| Check if market is calm                                          |
//+------------------------------------------------------------------+
bool MarketAnalyzer::IsCalmMarket(void) {
    double bbWidth = 0;
    if(m_currentState.bbMiddle > 0) {
        bbWidth = (m_currentState.bbUpper - m_currentState.bbLower) / m_currentState.bbMiddle;
    }
    
    return (m_currentState.adx < 15 && bbWidth < 0.01);
}

//+------------------------------------------------------------------+
//| Detect trend direction                                           |
//+------------------------------------------------------------------+
ENUM_TREND_DIR MarketAnalyzer::DetectTrend(void) {
    if(m_currentState.ema21 > m_currentState.ema50 && 
       m_currentState.ema50 > m_currentState.ema200) {
        return TREND_UP;
    }
    
    if(m_currentState.ema21 < m_currentState.ema50 && 
       m_currentState.ema50 < m_currentState.ema200) {
        return TREND_DOWN;
    }
    
    return TREND_FLAT;
}

//+------------------------------------------------------------------+
//| Detect market structure                                          |
//+------------------------------------------------------------------+
ENUM_STRUCTURE MarketAnalyzer::DetectStructure(void) {
    if(m_currentState.trendDir == TREND_UP) {
        return STRUCTURE_HH_HL;  // Higher Highs/Higher Lows
    }
    
    if(m_currentState.trendDir == TREND_DOWN) {
        return STRUCTURE_LL_LH;  // Lower Lows/Lower Highs
    }
    
    return STRUCTURE_NONE;
}

//+------------------------------------------------------------------+
//| Detect trading session                                           |
//+------------------------------------------------------------------+
ENUM_SESSION MarketAnalyzer::DetectSession(void) {
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    m_currentState.hourWIT = dt.hour;
    
    //--- Check for golden hours
    m_currentState.isGoldenHour = (dt.hour == 22 || dt.hour == 23 || 
                                    dt.hour == 8 || dt.hour == 9);
    
    //--- Determine session
    if(dt.hour >= 22 || dt.hour <= 1) {
        return SESSION_ASIAN;
    } else if(dt.hour >= 7 && dt.hour <= 16) {
        return SESSION_LONDON;
    } else if(dt.hour >= 14 && dt.hour <= 23) {
        return SESSION_NEWYORK;
    }
    
    return SESSION_ASIAN;  // Default
}

//+------------------------------------------------------------------+
//| Find key support/resistance levels                               |
//+------------------------------------------------------------------+
void MarketAnalyzer::FindKeyLevels(void) {
    //--- Simplified: Use Bollinger Bands as key levels
    m_currentState.nearestSupport = m_currentState.bbLower;
    m_currentState.nearestResistance = m_currentState.bbUpper;
    
    //--- Clear supply/demand zones (handled by SupplyDemand strategy)
    for(int i = 0; i < 5; i++) {
        m_currentState.supplyZones[i] = 0;
        m_currentState.demandZones[i] = 0;
    }
}

//+------------------------------------------------------------------+
//| Check if data is stale                                           |
//+------------------------------------------------------------------+
bool MarketAnalyzer::IsStale(void) {
    datetime currentH1Close = iTime(m_symbol, PERIOD_H1, 0);
    return (currentH1Close != m_lastH1Close);
}

//+------------------------------------------------------------------+
//| END OF MARKET ANALYZER                                           |
//+------------------------------------------------------------------+
