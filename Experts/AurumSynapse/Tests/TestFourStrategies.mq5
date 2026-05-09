//+------------------------------------------------------------------+
//|                                          TestFourStrategies.mq5 |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "1.00"
#property description "Test EA for TrendFollowing, Breakout, MeanReversion, and SupplyDemand Strategies"

//--- Include necessary files
#include "../Core/Constants.mqh"
#include "../Core/Structures.mqh"
#include "../Core/IndicatorCache.mqh"
#include "../Strategies/TrendFollowing.mqh"
#include "../Strategies/Breakout.mqh"
#include "../Strategies/MeanReversion.mqh"
#include "../Strategies/SupplyDemand.mqh"

//--- Input parameters
input bool     InpShowDebug = true;      // Show debug messages
input bool     InpShowMarket = true;     // Show market state details
input bool     InpShowZones = true;      // Show supply/demand zones

//--- Global variables
TrendFollowing*  g_trendStrategy;
Breakout*        g_breakoutStrategy;
MeanReversion*   g_meanReversionStrategy;
SupplyDemand*    g_supplyDemandStrategy;
IndicatorCache*  g_cache;
datetime         g_lastBarTime;
int              g_barCount;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print("========================================");
    Print("TestFourStrategies EA - Initializing");
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
    
    // Create MeanReversion strategy
    g_meanReversionStrategy = new MeanReversion();
    if(g_meanReversionStrategy == NULL) {
        Print("ERROR: Failed to create MeanReversion strategy");
        delete g_breakoutStrategy;
        delete g_trendStrategy;
        delete g_cache;
        return INIT_FAILED;
    }
    
    g_meanReversionStrategy.Init(g_cache, WEIGHT_MEAN_REVERSION, _Symbol, PERIOD_M1);
    Print("MeanReversion strategy initialized - Weight: ", DoubleToString(WEIGHT_MEAN_REVERSION, 2));
    
    // Create SupplyDemand strategy
    g_supplyDemandStrategy = new SupplyDemand();
    if(g_supplyDemandStrategy == NULL) {
        Print("ERROR: Failed to create SupplyDemand strategy");
        delete g_meanReversionStrategy;
        delete g_breakoutStrategy;
        delete g_trendStrategy;
        delete g_cache;
        return INIT_FAILED;
    }
    
    g_supplyDemandStrategy.Init(g_cache, WEIGHT_SUPPLY_DEMAND, _Symbol, PERIOD_M1);
    Print("SupplyDemand strategy initialized - Weight: ", DoubleToString(WEIGHT_SUPPLY_DEMAND, 2));
    
    Print("========================================");
    Print("All 4 strategies ready - Waiting for bars...");
    Print("========================================");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("========================================");
    Print("TestFourStrategies EA - Shutting down");
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
    
    if(g_meanReversionStrategy != NULL) {
        delete g_meanReversionStrategy;
        g_meanReversionStrategy = NULL;
    }
    
    if(g_supplyDemandStrategy != NULL) {
        delete g_supplyDemandStrategy;
        g_supplyDemandStrategy = NULL;
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
            state.atrRatio = 1.0;
        }
        IndicatorRelease(atrHandle);
    } else {
        state.atrRatio = 1.0;
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
    
    //--- Evaluate all four strategies
    g_trendStrategy.Evaluate(state);
    g_breakoutStrategy.Evaluate(state);
    g_meanReversionStrategy.Evaluate(state);
    g_supplyDemandStrategy.Evaluate(state);
    
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
    
    //--- Get MeanReversion results
    ENUM_SIGNAL meanRevSignal = g_meanReversionStrategy.GetSignal();
    double meanRevStrength = g_meanReversionStrategy.GetStrength();
    double meanRevWeight = g_meanReversionStrategy.GetWeight();
    bool meanRevActive = g_meanReversionStrategy.IsActive();
    
    //--- Get SupplyDemand results
    ENUM_SIGNAL supDemSignal = g_supplyDemandStrategy.GetSignal();
    double supDemStrength = g_supplyDemandStrategy.GetStrength();
    double supDemWeight = g_supplyDemandStrategy.GetWeight();
    bool supDemActive = g_supplyDemandStrategy.IsActive();
    
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
              " | ATR: ", DoubleToString(state.atr14, 2));
        Print("  Price: ", DoubleToString(state.bid, 2),
              " | BB: [", DoubleToString(state.bbLower, 2), " - ", DoubleToString(state.bbUpper, 2), "]");
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
    
    Print("");
    Print("STRATEGY 3 - MeanReversion:");
    Print("  Status: ", (meanRevActive ? "ACTIVE" : "INACTIVE"));
    Print("  Signal: ", SignalToString(meanRevSignal));
    
    if(meanRevSignal != SIGNAL_NONE) {
        Print("  Strength: ", DoubleToString(meanRevStrength * 100, 1), "%");
        Print("  Weight: ", DoubleToString(meanRevWeight, 2));
        Print("  >>> SIGNAL: ", SignalToString(meanRevSignal),
              " at ", DoubleToString(meanRevStrength * 100, 1), "% strength");
    }
    
    Print("");
    Print("STRATEGY 4 - SupplyDemand:");
    Print("  Status: ", (supDemActive ? "ACTIVE" : "INACTIVE"));
    Print("  Signal: ", SignalToString(supDemSignal));
    
    if(supDemSignal != SIGNAL_NONE) {
        Print("  Strength: ", DoubleToString(supDemStrength * 100, 1), "%");
        Print("  Weight: ", DoubleToString(supDemWeight, 2));
        Print("  >>> SIGNAL: ", SignalToString(supDemSignal),
              " at ", DoubleToString(supDemStrength * 100, 1), "% strength");
    }
    
    //--- Calculate weighted consensus
    int activeCount = 0;
    int buyCount = 0;
    int sellCount = 0;
    double buyScore = 0;
    double sellScore = 0;
    double totalWeight = 0;
    string activeList = "";
    
    // Count signals and calculate weighted scores
    if(trendSignal != SIGNAL_NONE) {
        activeCount++;
        totalWeight += trendWeight;
        activeList += "Trend ";
        if(trendSignal == SIGNAL_BUY) {
            buyCount++;
            buyScore += trendStrength * trendWeight;
        } else if(trendSignal == SIGNAL_SELL) {
            sellCount++;
            sellScore += trendStrength * trendWeight;
        }
    }
    
    if(breakoutSignal != SIGNAL_NONE) {
        activeCount++;
        totalWeight += breakoutWeight;
        activeList += "Breakout ";
        if(breakoutSignal == SIGNAL_BUY) {
            buyCount++;
            buyScore += breakoutStrength * breakoutWeight;
        } else if(breakoutSignal == SIGNAL_SELL) {
            sellCount++;
            sellScore += breakoutStrength * breakoutWeight;
        }
    }
    
    if(meanRevSignal != SIGNAL_NONE) {
        activeCount++;
        totalWeight += meanRevWeight;
        activeList += "MeanRev ";
        if(meanRevSignal == SIGNAL_BUY) {
            buyCount++;
            buyScore += meanRevStrength * meanRevWeight;
        } else if(meanRevSignal == SIGNAL_SELL) {
            sellCount++;
            sellScore += meanRevStrength * meanRevWeight;
        }
    }
    
    if(supDemSignal != SIGNAL_NONE) {
        activeCount++;
        totalWeight += supDemWeight;
        activeList += "SupDem ";
        if(supDemSignal == SIGNAL_BUY) {
            buyCount++;
            buyScore += supDemStrength * supDemWeight;
        } else if(supDemSignal == SIGNAL_SELL) {
            sellCount++;
            sellScore += supDemStrength * supDemWeight;
        }
    }
    
    //--- Show consensus analysis if at least 2 strategies active
    if(activeCount >= 2) {
        Print("");
        Print("*** WEIGHTED CONSENSUS ***");
        Print("  Active: ", activeCount, "/4 [", activeList, "]");
        Print("  BUY votes: ", buyCount, " | SELL votes: ", sellCount);
        Print("  BUY score: ", DoubleToString(buyScore, 3), 
              " | SELL score: ", DoubleToString(sellScore, 3));
        
        // Calculate required votes (min 2, or 40% of active)
        int requiredVotes = (int)MathMax(2, activeCount * 0.4);
        
        if(buyCount >= requiredVotes && buyScore > sellScore * 1.05) {
            double consensusStrength = buyScore / totalWeight;
            Print("  >>> CONSENSUS: BUY with ", DoubleToString(consensusStrength * 100, 1), "% strength");
            Print("  Quality: ", (activeCount >= 3 ? "HIGH" : "MEDIUM"), 
                  " (", requiredVotes, " votes required, ", buyCount, " received)");
        } else if(sellCount >= requiredVotes && sellScore > buyScore * 1.05) {
            double consensusStrength = sellScore / totalWeight;
            Print("  >>> CONSENSUS: SELL with ", DoubleToString(consensusStrength * 100, 1), "% strength");
            Print("  Quality: ", (activeCount >= 3 ? "HIGH" : "MEDIUM"),
                  " (", requiredVotes, " votes required, ", sellCount, " received)");
        } else {
            Print("  >>> NO CONSENSUS: Insufficient agreement");
            if(buyCount > 0 && sellCount > 0) {
                Print("  Conflict detected: ", buyCount, " BUY vs ", sellCount, " SELL");
            } else {
                Print("  Margin too small (need 5% advantage)");
            }
        }
    } else if(activeCount == 1) {
        Print("");
        Print("*** SINGLE STRATEGY ACTIVE ***");
        Print("  Only 1 strategy signaling [", activeList, "] - consensus requires 2+");
    } else {
        Print("");
        Print("*** NO ACTIVE STRATEGIES ***");
        Print("  Market conditions not suitable for any strategy");
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
