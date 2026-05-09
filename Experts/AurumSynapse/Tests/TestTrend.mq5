//+------------------------------------------------------------------+
//|                                                    TestTrend.mq5 |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "1.00"
#property description "Test EA for TrendFollowing Strategy"

//--- Include necessary files
#include "../Core/Constants.mqh"
#include "../Core/Structures.mqh"
#include "../Core/IndicatorCache.mqh"
#include "../Strategies/TrendFollowing.mqh"

//--- Input parameters
input bool     InpShowDebug = true;      // Show debug messages

//--- Global variables
TrendFollowing*  g_trendStrategy;
IndicatorCache*  g_cache;
datetime         g_lastBarTime;
int              g_barCount;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print("========================================");
    Print("TestTrend EA - Initializing");
    Print("========================================");
    
    // Initialize counter
    g_barCount = 0;
    g_lastBarTime = 0;
    
    // Create indicator cache
    g_cache = new IndicatorCache();
    if(g_cache == NULL) {
        Print("ERROR: Failed to create IndicatorCache");
        return INIT_FAILED;
    }
    
    if(!g_cache.Init(_Symbol, PERIOD_M1)) {
        Print("ERROR: Failed to initialize IndicatorCache");
        delete g_cache;
        return INIT_FAILED;
    }
    
    Print("IndicatorCache initialized successfully");
    
    // Create TrendFollowing strategy
    g_trendStrategy = new TrendFollowing();
    if(g_trendStrategy == NULL) {
        Print("ERROR: Failed to create TrendFollowing strategy");
        delete g_cache;
        return INIT_FAILED;
    }
    
    // Initialize strategy
    g_trendStrategy.Init(g_cache, WEIGHT_TREND_FOLLOWING, _Symbol, PERIOD_M1);
    
    Print("TrendFollowing strategy initialized successfully");
    Print("Base Weight: ", DoubleToString(WEIGHT_TREND_FOLLOWING, 2));
    Print("Active Regime: TRENDING");
    Print("========================================");
    Print("Waiting for new bars...");
    Print("========================================");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("========================================");
    Print("TestTrend EA - Shutting down");
    Print("Total bars evaluated: ", g_barCount);
    Print("Deinit reason: ", reason);
    Print("========================================");
    
    // Cleanup
    if(g_trendStrategy != NULL) {
        delete g_trendStrategy;
        g_trendStrategy = NULL;
    }
    
    if(g_cache != NULL) {
        g_cache.Deinit();
        delete g_cache;
        g_cache = NULL;
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    // Check for new bar
    datetime currentBarTime = iTime(_Symbol, PERIOD_M1, 0);
    
    if(currentBarTime == g_lastBarTime) {
        return;  // Not a new bar
    }
    
    g_lastBarTime = currentBarTime;
    g_barCount++;
    
    // Create mock MarketState (simplified for testing)
    MarketState state;
    
    // Fill basic price data
    state.bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    state.ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    state.spread = (state.ask - state.bid) / _Point;
    state.timestamp = TimeCurrent();
    state.isNewBar = true;
    
    // Get current indicator values from cache
    if(!g_cache.Refresh(state)) {
        if(InpShowDebug) {
            Print("WARNING: Cache refresh failed on bar ", g_barCount);
        }
        return;
    }
    
    // Fill indicator values from cache
    state.ema21 = g_cache.GetEMA(21);
    state.ema50 = g_cache.GetEMA(50);
    state.ema200 = g_cache.GetEMA(200);
    state.rsi14 = g_cache.GetRSI();
    state.macdMain = g_cache.GetMACD(0);
    state.macdSignal = g_cache.GetMACD(1);
    state.adx = g_cache.GetADX();
    state.bbUpper = g_cache.GetBB(0);
    state.bbMiddle = g_cache.GetBB(1);
    state.bbLower = g_cache.GetBB(2);
    state.stochK = g_cache.GetStoch(0);
    state.stochD = g_cache.GetStoch(1);
    state.atr14 = g_cache.GetATR();
    
    // Set ATR ratio (current / 20-bar average)
    // Simplified: assume ratio of 1.0 for testing
    state.atrRatio = 1.0;
    
    // Determine regime based on ADX
    if(state.adx > 25) {
        state.regime = REGIME_TRENDING;
    } else if(state.adx < 15) {
        state.regime = REGIME_CALM;
    } else {
        state.regime = REGIME_RANGING;
    }
    
    // Determine trend direction
    if(state.ema21 > state.ema50 && state.ema50 > state.ema200) {
        state.trendDir = TREND_UP;
        state.structure = STRUCTURE_HH_HL;
    } else if(state.ema21 < state.ema50 && state.ema50 < state.ema200) {
        state.trendDir = TREND_DOWN;
        state.structure = STRUCTURE_LL_LH;
    } else {
        state.trendDir = TREND_FLAT;
        state.structure = STRUCTURE_NONE;
    }
    
    // Set session (simplified)
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    state.hourWIT = dt.hour;  // Using server time as WIT approximation
    
    if(state.hourWIT >= 22 || state.hourWIT <= 1) {
        state.session = SESSION_ASIAN;
        state.isGoldenHour = (state.hourWIT == 22 || state.hourWIT == 23);
    } else if(state.hourWIT >= 7 && state.hourWIT <= 16) {
        state.session = SESSION_LONDON;
        state.isGoldenHour = (state.hourWIT == 8 || state.hourWIT == 9);
    } else if(state.hourWIT >= 14 && state.hourWIT <= 23) {
        state.session = SESSION_NEWYORK;
    } else {
        state.session = SESSION_ASIAN;
    }
    
    // Set key levels (simplified - set to zero for testing)
    state.nearestSupport = 0;
    state.nearestResistance = 0;
    for(int i = 0; i < 5; i++) {
        state.supplyZones[i] = 0;
        state.demandZones[i] = 0;
    }
    
    // Volume data
    state.tickVolume = (double)iVolume(_Symbol, PERIOD_M1, 0);
    state.avgTickVolume = state.tickVolume;  // Simplified
    state.volumeRatio = 1.0;
    
    // Evaluate strategy
    g_trendStrategy.Evaluate(state);
    
    // Get results
    ENUM_SIGNAL signal = g_trendStrategy.GetSignal();
    double strength = g_trendStrategy.GetStrength();
    double weight = g_trendStrategy.GetWeight();
    bool isActive = g_trendStrategy.IsActive();
    string name = g_trendStrategy.GetName();
    
    // Print results
    Print("========================================");
    Print("BAR #", g_barCount, " - ", TimeToString(state.timestamp, TIME_DATE|TIME_MINUTES));
    Print("----------------------------------------");
    Print("Market State:");
    Print("  Regime: ", RegimeToString(state.regime));
    Print("  Trend: ", TrendDirToString(state.trendDir));
    Print("  Structure: ", StructureToString(state.structure));
    Print("  ADX: ", DoubleToString(state.adx, 2));
    Print("  RSI: ", DoubleToString(state.rsi14, 2));
    Print("  Price: ", DoubleToString(state.bid, 2));
    Print("  EMA21: ", DoubleToString(state.ema21, 2));
    Print("  EMA50: ", DoubleToString(state.ema50, 2));
    Print("  EMA200: ", DoubleToString(state.ema200, 2));
    Print("----------------------------------------");
    Print("TrendFollowing Strategy:");
    Print("  Signal: ", SignalToString(signal));
    Print("  Strength: ", DoubleToString(strength, 3));
    Print("  Weight: ", DoubleToString(weight, 2));
    Print("  Active: ", (isActive ? "YES" : "NO"));
    
    if(signal != SIGNAL_NONE) {
        Print("  >>> SIGNAL DETECTED: ", SignalToString(signal), 
              " with strength ", DoubleToString(strength * 100, 1), "%");
    }
    
    Print("========================================");
}

//+------------------------------------------------------------------+
//| Helper function: Signal to string                                |
//+------------------------------------------------------------------+
string SignalToString(ENUM_SIGNAL signal) {
    switch(signal) {
        case SIGNAL_BUY:  return "BUY";
        case SIGNAL_SELL: return "SELL";
        case SIGNAL_NONE: return "NONE";
        default:          return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| Helper function: Regime to string                                |
//+------------------------------------------------------------------+
string RegimeToString(ENUM_REGIME regime) {
    switch(regime) {
        case REGIME_TRENDING: return "TRENDING";
        case REGIME_RANGING:  return "RANGING";
        case REGIME_VOLATILE: return "VOLATILE";
        case REGIME_CALM:     return "CALM";
        default:              return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| Helper function: Trend direction to string                       |
//+------------------------------------------------------------------+
string TrendDirToString(ENUM_TREND_DIR trend) {
    switch(trend) {
        case TREND_UP:   return "UP";
        case TREND_DOWN: return "DOWN";
        case TREND_FLAT: return "FLAT";
        default:         return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| Helper function: Structure to string                             |
//+------------------------------------------------------------------+
string StructureToString(ENUM_STRUCTURE structure) {
    switch(structure) {
        case STRUCTURE_HH_HL: return "HH/HL (Bullish)";
        case STRUCTURE_LL_LH: return "LL/LH (Bearish)";
        case STRUCTURE_NONE:  return "NONE";
        default:              return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| END OF TEST EA                                                   |
//+------------------------------------------------------------------+
