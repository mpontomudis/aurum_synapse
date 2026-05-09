//+------------------------------------------------------------------+
//|                                               IndicatorCache.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                                   Copyright 2026, Aurum Synapse  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://github.com/aurumsynapse"
#property version   "2.00"

#include "Structures.mqh"

//+------------------------------------------------------------------+
//| Indicator Cache Class                                            |
//| Manages shared indicator handles and prevents duplicate calls    |
//+------------------------------------------------------------------+
class IndicatorCache {
private:
    // Indicator handles
    int              m_handleEMA21;
    int              m_handleEMA50;
    int              m_handleEMA200;
    int              m_handleRSI14;
    int              m_handleMACD;
    int              m_handleBB;
    int              m_handleATR14;
    int              m_handleADX14;
    int              m_handleStoch;
    
    // Symbol and timeframe
    string           m_symbol;
    ENUM_TIMEFRAMES  m_timeframe;
    
    // Last update time
    datetime         m_lastUpdate;
    
    // Buffer arrays
    double           m_emaBuffer[];
    double           m_rsiBuffer[];
    double           m_macdBuffer[];
    double           m_bbBuffer[];
    double           m_atrBuffer[];
    double           m_adxBuffer[];
    double           m_stochBuffer[];
    
public:
    // Constructor / Destructor
    IndicatorCache();
    ~IndicatorCache();
    
    // Initialization
    bool Init(string symbol, ENUM_TIMEFRAMES timeframe);
    void Deinit();
    
    // Update methods
    bool Refresh(const MarketState &state);
    bool IsStale();
    
    // Accessor methods
    double GetEMA(int period);
    double GetRSI();
    double GetMACD(int buffer);  // 0=main, 1=signal
    double GetBB(int buffer);    // 0=upper, 1=middle, 2=lower
    double GetATR();
    double GetADX();
    double GetStoch(int buffer); // 0=K, 1=D
    
    // Validation
    bool ValidateHandles();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
IndicatorCache::IndicatorCache() :
    m_handleEMA21(INVALID_HANDLE),
    m_handleEMA50(INVALID_HANDLE),
    m_handleEMA200(INVALID_HANDLE),
    m_handleRSI14(INVALID_HANDLE),
    m_handleMACD(INVALID_HANDLE),
    m_handleBB(INVALID_HANDLE),
    m_handleATR14(INVALID_HANDLE),
    m_handleADX14(INVALID_HANDLE),
    m_handleStoch(INVALID_HANDLE),
    m_symbol(""),
    m_timeframe(PERIOD_CURRENT),
    m_lastUpdate(0)
{
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
IndicatorCache::~IndicatorCache() {
    Deinit();
}

//+------------------------------------------------------------------+
//| Initialize all indicator handles                                 |
//+------------------------------------------------------------------+
bool IndicatorCache::Init(string symbol, ENUM_TIMEFRAMES timeframe) {
    m_symbol = symbol;
    m_timeframe = timeframe;
    
    Print("IndicatorCache: Initializing for ", symbol, " ", EnumToString(timeframe));
    
    // Create EMA handles
    m_handleEMA21 = iMA(symbol, timeframe, EMA_PERIOD_FAST, 0, MODE_EMA, PRICE_CLOSE);
    if(m_handleEMA21 == INVALID_HANDLE) {
        Print("ERROR: Failed to create EMA21 handle");
        return false;
    }
    
    m_handleEMA50 = iMA(symbol, timeframe, EMA_PERIOD_MEDIUM, 0, MODE_EMA, PRICE_CLOSE);
    if(m_handleEMA50 == INVALID_HANDLE) {
        Print("ERROR: Failed to create EMA50 handle");
        return false;
    }
    
    m_handleEMA200 = iMA(symbol, timeframe, EMA_PERIOD_SLOW, 0, MODE_EMA, PRICE_CLOSE);
    if(m_handleEMA200 == INVALID_HANDLE) {
        Print("ERROR: Failed to create EMA200 handle");
        return false;
    }
    
    // Create RSI handle
    m_handleRSI14 = iRSI(symbol, timeframe, RSI_PERIOD, PRICE_CLOSE);
    if(m_handleRSI14 == INVALID_HANDLE) {
        Print("ERROR: Failed to create RSI14 handle");
        return false;
    }
    
    // Create MACD handle
    m_handleMACD = iMACD(symbol, timeframe, MACD_FAST_PERIOD, MACD_SLOW_PERIOD, MACD_SIGNAL_PERIOD, PRICE_CLOSE);
    if(m_handleMACD == INVALID_HANDLE) {
        Print("ERROR: Failed to create MACD handle");
        return false;
    }
    
    // Create Bollinger Bands handle
    m_handleBB = iBands(symbol, timeframe, BB_PERIOD, 0, BB_DEVIATION, PRICE_CLOSE);
    if(m_handleBB == INVALID_HANDLE) {
        Print("ERROR: Failed to create Bollinger Bands handle");
        return false;
    }
    
    // Create ATR handle
    m_handleATR14 = iATR(symbol, timeframe, ATR_PERIOD);
    if(m_handleATR14 == INVALID_HANDLE) {
        Print("ERROR: Failed to create ATR14 handle");
        return false;
    }
    
    // Create ADX handle
    m_handleADX14 = iADX(symbol, timeframe, ADX_PERIOD);
    if(m_handleADX14 == INVALID_HANDLE) {
        Print("ERROR: Failed to create ADX14 handle");
        return false;
    }
    
    // Create Stochastic handle
    m_handleStoch = iStochastic(symbol, timeframe, STOCH_K_PERIOD, STOCH_D_PERIOD, STOCH_SLOWING, MODE_SMA, STO_LOWHIGH);
    if(m_handleStoch == INVALID_HANDLE) {
        Print("ERROR: Failed to create Stochastic handle");
        return false;
    }
    
    Print("IndicatorCache: All handles created successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Release all indicator handles                                    |
//+------------------------------------------------------------------+
void IndicatorCache::Deinit() {
    if(m_handleEMA21 != INVALID_HANDLE) IndicatorRelease(m_handleEMA21);
    if(m_handleEMA50 != INVALID_HANDLE) IndicatorRelease(m_handleEMA50);
    if(m_handleEMA200 != INVALID_HANDLE) IndicatorRelease(m_handleEMA200);
    if(m_handleRSI14 != INVALID_HANDLE) IndicatorRelease(m_handleRSI14);
    if(m_handleMACD != INVALID_HANDLE) IndicatorRelease(m_handleMACD);
    if(m_handleBB != INVALID_HANDLE) IndicatorRelease(m_handleBB);
    if(m_handleATR14 != INVALID_HANDLE) IndicatorRelease(m_handleATR14);
    if(m_handleADX14 != INVALID_HANDLE) IndicatorRelease(m_handleADX14);
    if(m_handleStoch != INVALID_HANDLE) IndicatorRelease(m_handleStoch);
    
    Print("IndicatorCache: All handles released");
}

//+------------------------------------------------------------------+
//| Refresh all indicator buffers                                    |
//+------------------------------------------------------------------+
bool IndicatorCache::Refresh(const MarketState &state) {
    // Just return true for now - actual buffer copying happens in Get methods
    m_lastUpdate = TimeCurrent();
    return true;
}

//+------------------------------------------------------------------+
//| Check if cache data is stale                                     |
//+------------------------------------------------------------------+
bool IndicatorCache::IsStale() {
    return (TimeCurrent() - m_lastUpdate) > 60;  // Stale after 60 seconds
}

//+------------------------------------------------------------------+
//| Get EMA value                                                    |
//+------------------------------------------------------------------+
double IndicatorCache::GetEMA(int period) {
    int handle = INVALID_HANDLE;
    
    // Select the appropriate handle
    if(period == EMA_PERIOD_FAST) handle = m_handleEMA21;
    else if(period == EMA_PERIOD_MEDIUM) handle = m_handleEMA50;
    else if(period == EMA_PERIOD_SLOW) handle = m_handleEMA200;
    else return 0.0;
    
    if(handle == INVALID_HANDLE) return 0.0;
    
    double buffer[];
    ArraySetAsSeries(buffer, true);
    
    if(CopyBuffer(handle, 0, 0, 1, buffer) <= 0) {
        return 0.0;
    }
    
    return buffer[0];
}

//+------------------------------------------------------------------+
//| Get RSI value                                                    |
//+------------------------------------------------------------------+
double IndicatorCache::GetRSI() {
    if(m_handleRSI14 == INVALID_HANDLE) return 0.0;
    
    double buffer[];
    ArraySetAsSeries(buffer, true);
    
    if(CopyBuffer(m_handleRSI14, 0, 0, 1, buffer) <= 0) {
        return 0.0;
    }
    
    return buffer[0];
}

//+------------------------------------------------------------------+
//| Get MACD value                                                   |
//+------------------------------------------------------------------+
double IndicatorCache::GetMACD(int buffer) {
    if(m_handleMACD == INVALID_HANDLE) return 0.0;
    
    double values[];
    ArraySetAsSeries(values, true);
    
    if(CopyBuffer(m_handleMACD, buffer, 0, 1, values) <= 0) {
        return 0.0;
    }
    
    return values[0];
}

//+------------------------------------------------------------------+
//| Get Bollinger Band value                                         |
//+------------------------------------------------------------------+
double IndicatorCache::GetBB(int buffer) {
    if(m_handleBB == INVALID_HANDLE) return 0.0;
    
    double values[];
    ArraySetAsSeries(values, true);
    
    // BB buffers: 0=BASE_LINE, 1=UPPER_BAND, 2=LOWER_BAND
    int bbBuffer = buffer;
    if(buffer == 0) bbBuffer = 1;  // Upper
    else if(buffer == 1) bbBuffer = 0;  // Middle
    else if(buffer == 2) bbBuffer = 2;  // Lower
    
    if(CopyBuffer(m_handleBB, bbBuffer, 0, 1, values) <= 0) {
        return 0.0;
    }
    
    return values[0];
}

//+------------------------------------------------------------------+
//| Get ATR value                                                    |
//+------------------------------------------------------------------+
double IndicatorCache::GetATR() {
    if(m_handleATR14 == INVALID_HANDLE) return 0.0;
    
    double buffer[];
    ArraySetAsSeries(buffer, true);
    
    if(CopyBuffer(m_handleATR14, 0, 0, 1, buffer) <= 0) {
        return 0.0;
    }
    
    return buffer[0];
}

//+------------------------------------------------------------------+
//| Get ADX value                                                    |
//+------------------------------------------------------------------+
double IndicatorCache::GetADX() {
    if(m_handleADX14 == INVALID_HANDLE) return 0.0;
    
    double buffer[];
    ArraySetAsSeries(buffer, true);
    
    if(CopyBuffer(m_handleADX14, 0, 0, 1, buffer) <= 0) {
        return 0.0;
    }
    
    return buffer[0];
}

//+------------------------------------------------------------------+
//| Get Stochastic value                                             |
//+------------------------------------------------------------------+
double IndicatorCache::GetStoch(int buffer) {
    if(m_handleStoch == INVALID_HANDLE) return 0.0;
    
    double values[];
    ArraySetAsSeries(values, true);
    
    if(CopyBuffer(m_handleStoch, buffer, 0, 1, values) <= 0) {
        return 0.0;
    }
    
    return values[0];
}

//+------------------------------------------------------------------+
//| Validate all handles are created                                 |
//+------------------------------------------------------------------+
bool IndicatorCache::ValidateHandles() {
    return (m_handleEMA21 != INVALID_HANDLE &&
            m_handleEMA50 != INVALID_HANDLE &&
            m_handleEMA200 != INVALID_HANDLE &&
            m_handleRSI14 != INVALID_HANDLE &&
            m_handleMACD != INVALID_HANDLE &&
            m_handleBB != INVALID_HANDLE &&
            m_handleATR14 != INVALID_HANDLE &&
            m_handleADX14 != INVALID_HANDLE &&
            m_handleStoch != INVALID_HANDLE);
}

//+------------------------------------------------------------------+
