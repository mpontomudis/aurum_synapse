//+------------------------------------------------------------------+
//|                                           TestTwoStrategies.mq5 |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "1.00"
#property description "Test EA for TrendFollowing and Breakout Strategies"

//--- Include necessary files
#include "../Core/Constants.mqh"
#include "../Core/Structures.mqh"
#include "../Core/IndicatorCache.mqh"
#include "../Strategies/TrendFollowing.mqh"
#include "../Strategies/Breakout.mqh"

//--- Input parameters
input bool     InpShowDebug = true;      // Show debug messages
input bool     InpShowMarket = true;     // Show market state details

//--- Global variables
TrendFollowing*  g_trendStrategy;
Breakout*        g_breakoutStrategy;
IndicatorCache*  g_cache;
datetime         g_lastBarTime;
int              g_barCount;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print("========================================");
    Print("TestTwoStrategies EA - Initializing");
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
    
    g_trendStrategy.Init(g_cache, WEIGHT_TREND_FOLLOWING, _Symbol, PERIOD_M1);
    Print("TrendFollowing strategy initialized - Weight: ", DoubleToString(WEIGHT_TREND_FOLLOWING, 2));
    
    // Create Breakout strategy
    g_breakoutStrategy = new Breakout();
    if(g_breakoutStrategy == NULL) {
        Print("ERROR: Failed to create Breakout strategy");
        delete g_trendStrategy;
        delete g_cache;
        return INIT_FAILED;
    }
    
    g_breakoutStrategy.Init(g_cache, WEIGHT_BREAKOUT, _Symbol, PERIOD_M1);
    Print("Breakout strategy initialized - Weight: ", DoubleToString(WEIGHT_BREAKOUT, 2));
    
    Print("========================================");
    Print("Both strategies ready - Waiting for bars...");
    Print("========================================");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("========================================");
    Print("TestTwoStrategies EA - Shutting down");
    Print("Total bars evaluated: ", g_barCount);
    Print("Deinit reason: ", reason);
    Print("========================================");
    
    // Cleanup
    if(g_trendStrategy != NULL) {
        delete g_trendStrategy;
        g_trendStrategy = NULL;
    }
    
    if(g_breakoutStrategy != NULL) {
        delete g_breakoutStrategy;
        g_breakoutStrategy = NULL;
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
    
    // Create MarketState
    MarketState state;
    
    // Fill basic price data
    state.bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    state.ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    state.spread = (state.ask - state.bid) / _Point;
    state.timestamp = TimeCurrent();
    state.isNewBar = true;
    
    // Refresh cache and get indicators
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
    
    // Calculate ATR ratio (current / 20-bar average)
    // Simplified: Using a direct iATR call for average calculation
    int atrHandle = iATR(_Symbol, PERIOD_M1, 14);
    if(atrHandle != INVALID_HANDLE) {
        double atrArray[20];
        if(CopyBuffer(atrHandle, 0, 0, 20, atrArray) == 20) {
            double atrSum = 0;
            for(int i = 0; i < 20; i++) {
                atrSum += atrArray[i];
            }
            double avgATR = atrSum / 20.0;
            state.atrRatio = (avgATR > 0) ? state.atr14 / avgATR : 1.0;
        } else {
            state.atrRatio = 1.0;  // Default if calculation fails
        }
        IndicatorRelease(atrHandle);
    } else {
        state.atrRatio = 1.0;  // Default if handle creation fails
    }
    
    // Determine regime based on ADX and BB width
    double bbWidth = (state.bbUpper - state.bbLower) / state.bbMiddle;
    
    if(state.adx > 25) {
        state.regime = REGIME_TRENDING;
    } else if(state.adx < 15 && bbWidth < 0.01) {
        state.regime = REGIME_CALM;
    } else if(state.atrRatio > 1.5) {
        state.regime = REGIME_VOLATILE;
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
    
    // Set session
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    state.hourWIT = dt.hour;
    
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
    
    // Set key levels (simplified)
    state.nearestSupport = 0;
    state.nearestResistance = 0;
    for(int i = 0; i < 5; i++) {
        state.supplyZones[i] = 0;
        state.demandZones[i] = 0;
    }
    
    // Volume data
    state.tickVolume = (double)iVolume(_Symbol, PERIOD_M1, 0);
    state.avgTickVolume = state.tickVolume;
    state.volumeRatio = 1.0;
    
    //--- Evaluate both strategies
    g_trendStrategy.Evaluate(state);
    g_breakoutStrategy.Evaluate(state);
    
    //--- Get TrendFollowing results
    ENUM_SIGNAL trendSignal = g_trendStrategy.GetSignal();
    double trendStrength = g_trendStrategy.GetStrength();
    double trendWeight = g_trendStrategy.GetWeight();
    bool trendActive = g_trendStrategy.IsActive();
    
    //--- Get Breakout results
    ENUM_SIGNAL breakoutSignal = g_breakoutStrategy.GetSignal();
    double breakoutStrength = g_breakoutStrategy.GetStrength();
    double breakoutWeight = g_breakoutStrategy.GetWeight();
    bool breakoutActive = g_breakoutStrategy.IsActive();
    
    //--- Print results
    Print("========================================");
    Print("BAR #", g_barCount, " - ", TimeToString(state.timestamp, TIME_DATE|TIME_MINUTES));
    Print("========================================");
    
    if(InpShowMarket) {
        Print("Market State:");
        Print("  Regime: ", RegimeToString(state.regime), 
              " | Trend: ", TrendDirToString(state.trendDir),
              " | Session: ", SessionToString(state.session));
        Print("  ADX: ", DoubleToString(state.adx, 1),
              " | RSI: ", DoubleToString(state.rsi14, 1),
              " | ATR Ratio: ", DoubleToString(state.atrRatio, 2));
        Print("  Price: ", DoubleToString(state.bid, 2),
              " | EMA21: ", DoubleToString(state.ema21, 2),
              " | EMA50: ", DoubleToString(state.ema50, 2));
        Print("----------------------------------------");
    }
    
    Print("STRATEGY 1 - TrendFollowing:");
    Print("  Status: ", (trendActive ? "ACTIVE" : "INACTIVE"));
    Print("  Signal: ", SignalToString(trendSignal));
    
    if(trendSignal != SIGNAL_NONE) {
        Print("  Strength: ", DoubleToString(trendStrength * 100, 1), "%");
        Print("  Weight: ", DoubleToString(trendWeight, 2));
        Print("  >>> SIGNAL: ", SignalToString(trendSignal), 
              " at ", DoubleToString(trendStrength * 100, 1), "% strength");
    }
    
    Print("");
    Print("STRATEGY 2 - Breakout:");
    Print("  Status: ", (breakoutActive ? "ACTIVE" : "INACTIVE"));
    Print("  Signal: ", SignalToString(breakoutSignal));
    
    if(breakoutSignal != SIGNAL_NONE) {
        Print("  Strength: ", DoubleToString(breakoutStrength * 100, 1), "%");
        Print("  Weight: ", DoubleToString(breakoutWeight, 2));
        Print("  >>> SIGNAL: ", SignalToString(breakoutSignal),
              " at ", DoubleToString(breakoutStrength * 100, 1), "% strength");
    }
    
    //--- Show consensus if both active
    if(trendSignal != SIGNAL_NONE && breakoutSignal != SIGNAL_NONE) {
        Print("");
        Print("*** CONSENSUS STATUS ***");
        
        if(trendSignal == breakoutSignal) {
            double combinedStrength = (trendStrength * trendWeight + breakoutStrength * breakoutWeight) / 
                                     (trendWeight + breakoutWeight);
            Print("  ALIGNED: Both strategies agree on ", SignalToString(trendSignal));
            Print("  Combined Strength: ", DoubleToString(combinedStrength * 100, 1), "%");
        } else {
            Print("  CONFLICT: Strategies disagree");
            Print("  Trend wants: ", SignalToString(trendSignal),
                  " | Breakout wants: ", SignalToString(breakoutSignal));
        }
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
        case STRUCTURE_HH_HL: return "HH/HL";
        case STRUCTURE_LL_LH: return "LL/LH";
        case STRUCTURE_NONE:  return "NONE";
        default:              return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| Helper function: Session to string                               |
//+------------------------------------------------------------------+
string SessionToString(ENUM_SESSION session) {
    switch(session) {
        case SESSION_ASIAN:   return "ASIAN";
        case SESSION_LONDON:  return "LONDON";
        case SESSION_NEWYORK: return "NEWYORK";
        default:              return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| END OF TEST EA                                                   |
//+------------------------------------------------------------------+
