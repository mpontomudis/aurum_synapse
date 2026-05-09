//+------------------------------------------------------------------+
//|                                                   Structures.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                                   Copyright 2026, Aurum Synapse  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://github.com/aurumsynapse"
#property version   "2.00"

#include "Constants.mqh"

//+------------------------------------------------------------------+
//| Market State Structure                                           |
//+------------------------------------------------------------------+
struct MarketState {
    // Regime
    ENUM_REGIME      regime;
    ENUM_TREND_DIR   trendDir;
    ENUM_STRUCTURE   structure;
    
    // Price context
    double           bid;
    double           ask;
    double           spread;
    double           atr14;
    double           atrRatio;
    
    // Key levels
    double           nearestSupport;
    double           nearestResistance;
    double           supplyZones[5];
    double           demandZones[5];
    
    // Session
    ENUM_SESSION     session;
    int              hourWIT;
    bool             isGoldenHour;
    
    // Indicators
    double           ema21;
    double           ema50;
    double           ema200;
    double           rsi14;
    double           macdMain;
    double           macdSignal;
    double           bbUpper;
    double           bbMiddle;
    double           bbLower;
    double           adx;
    double           stochK;
    double           stochD;
    
    // Volume / activity
    double           tickVolume;
    double           avgTickVolume;
    double           volumeRatio;
    
    // Metadata
    datetime         timestamp;
    bool             isNewBar;
};

//+------------------------------------------------------------------+
//| Signal Result Structure                                          |
//+------------------------------------------------------------------+
struct SignalResult {
    string           strategyName;
    ENUM_SIGNAL      signal;
    double           strength;      // 0.0 - 1.0
    double           weight;        // Adaptive weight
    bool             isActive;
};

//+------------------------------------------------------------------+
//| Quality Component Structure                                      |
//+------------------------------------------------------------------+
struct QualityComponent {
    string           name;
    int              score;         // Points awarded
    int              maxScore;      // Maximum possible
    string           reason;
};

//+------------------------------------------------------------------+
//| Trade Request Structure                                          |
//+------------------------------------------------------------------+
struct TradeRequest {
    ENUM_SIGNAL      signal;
    double           lotSize;
    double           entryPrice;
    double           stopLoss;
    double           takeProfit;
    int              qualityScore;
    datetime         timestamp;
    string           reasoning;
};

//+------------------------------------------------------------------+
//| Session State Structure                                          |
//+------------------------------------------------------------------+
struct SessionState {
    int              tradesToday;
    int              tradesThisHour;
    datetime         lastTradeTime;
    double           dailyPnL;
    double           peakEquity;
    int              consecutiveLosses;
    bool             isCoolingDown;
    datetime         cooldownUntil;
    
    void Init() {
        tradesToday = 0;
        tradesThisHour = 0;
        lastTradeTime = 0;
        dailyPnL = 0.0;
        peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        consecutiveLosses = 0;
        isCoolingDown = false;
        cooldownUntil = 0;
    }
};

//+------------------------------------------------------------------+
//| Regime Statistics Structure                                      |
//+------------------------------------------------------------------+
struct RegimeStats {
    int              totalTrades;
    int              wins;
    double           totalProfit;
    double           totalLoss;
    double           winRate;
    double           profitFactor;
    double           adaptiveWeight;
};

//+------------------------------------------------------------------+
