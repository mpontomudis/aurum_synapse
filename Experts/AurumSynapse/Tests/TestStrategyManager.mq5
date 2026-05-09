//+------------------------------------------------------------------+
//|                                          TestStrategyManager.mq5 |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "1.00"
#property description "Test EA for StrategyManager - All 8 Strategies"

//--- Include necessary files
#include "../Core/Constants.mqh"
#include "../Core/Structures.mqh"
#include "../Engine/StrategyManager.mqh"

//--- Input parameters
input bool     InpShowDebug = true;      // Show debug messages
input bool     InpShowMarket = true;     // Show market state details
input bool     InpShowAllStrategies = true; // Show all strategy details

//--- Global variables
StrategyManager* g_manager;
datetime         g_lastBarTime;
int              g_barCount;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print("========================================");
    Print("TestStrategyManager EA - Initializing");
    Print("========================================");
    
    // Initialize counter
    g_barCount = 0;
    g_lastBarTime = 0;
    
    // Create strategy manager
    g_manager = new StrategyManager();
    if(g_manager == NULL) {
        Print("ERROR: Failed to create StrategyManager");
        return INIT_FAILED;
    }
    
    // Initialize manager (will create all 8 strategies)
    if(!g_manager.Init(_Symbol, PERIOD_M1)) {
        Print("ERROR: Failed to initialize StrategyManager");
        delete g_manager;
        return INIT_FAILED;
    }
    
    Print("========================================");
    Print("StrategyManager ready - Waiting for bars...");
    Print("========================================");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("========================================");
    Print("TestStrategyManager EA - Shutting down");
    Print("Total bars evaluated: ", g_barCount);
    Print("Deinit reason: ", reason);
    Print("========================================");
    
    // Cleanup
    if(g_manager != NULL) {
        g_manager.Deinit();
        delete g_manager;
        g_manager = NULL;
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
    
    // Note: IndicatorCache is managed by StrategyManager
    // We just need to populate the state with basic data
    // The manager will handle indicator updates
    
    // Get indicators from temporary handles (for state population)
    state.ema21 = iMA(_Symbol, PERIOD_M1, 21, 0, MODE_EMA, PRICE_CLOSE);
    state.ema50 = iMA(_Symbol, PERIOD_M1, 50, 0, MODE_EMA, PRICE_CLOSE);
    state.ema200 = iMA(_Symbol, PERIOD_M1, 200, 0, MODE_EMA, PRICE_CLOSE);
    
    double rsi[];
    ArraySetAsSeries(rsi, true);
    int rsiHandle = iRSI(_Symbol, PERIOD_M1, 14, PRICE_CLOSE);
    if(CopyBuffer(rsiHandle, 0, 0, 1, rsi) == 1) {
        state.rsi14 = rsi[0];
    }
    IndicatorRelease(rsiHandle);
    
    double macd[], signal[];
    ArraySetAsSeries(macd, true);
    ArraySetAsSeries(signal, true);
    int macdHandle = iMACD(_Symbol, PERIOD_M1, 12, 26, 9, PRICE_CLOSE);
    if(CopyBuffer(macdHandle, 0, 0, 1, macd) == 1 && CopyBuffer(macdHandle, 1, 0, 1, signal) == 1) {
        state.macdMain = macd[0];
        state.macdSignal = signal[0];
    }
    IndicatorRelease(macdHandle);
    
    double adx[];
    ArraySetAsSeries(adx, true);
    int adxHandle = iADX(_Symbol, PERIOD_M1, 14);
    if(CopyBuffer(adxHandle, 0, 0, 1, adx) == 1) {
        state.adx = adx[0];
    }
    IndicatorRelease(adxHandle);
    
    double bb[];
    ArraySetAsSeries(bb, true);
    int bbHandle = iBands(_Symbol, PERIOD_M1, 20, 0, 2.0, PRICE_CLOSE);
    if(CopyBuffer(bbHandle, 1, 0, 1, bb) == 1) {
        state.bbUpper = bb[0];
    }
    if(CopyBuffer(bbHandle, 0, 0, 1, bb) == 1) {
        state.bbMiddle = bb[0];
    }
    if(CopyBuffer(bbHandle, 2, 0, 1, bb) == 1) {
        state.bbLower = bb[0];
    }
    IndicatorRelease(bbHandle);
    
    double stoch[];
    ArraySetAsSeries(stoch, true);
    int stochHandle = iStochastic(_Symbol, PERIOD_M1, 5, 3, 3, MODE_SMA, STO_LOWHIGH);
    if(CopyBuffer(stochHandle, 0, 0, 1, stoch) == 1) {
        state.stochK = stoch[0];
    }
    if(CopyBuffer(stochHandle, 1, 0, 1, stoch) == 1) {
        state.stochD = stoch[0];
    }
    IndicatorRelease(stochHandle);
    
    double atr[];
    ArraySetAsSeries(atr, true);
    int atrHandle = iATR(_Symbol, PERIOD_M1, 14);
    if(CopyBuffer(atrHandle, 0, 0, 1, atr) == 1) {
        state.atr14 = atr[0];
    }
    
    // Calculate ATR ratio
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
    
    // Determine regime
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
    
    //--- Evaluate all strategies through manager
    g_manager.EvaluateAll(state);
    
    //--- Get results from manager
    SignalResult signals[8];
    g_manager.GetAllSignals(signals);
    int activeCount = g_manager.GetActiveStrategyCount();
    
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
        Print("  Golden Hour: ", (state.isGoldenHour ? "YES ⭐" : "NO"));
        Print("----------------------------------------");
    }
    
    Print("STRATEGY MANAGER REPORT:");
    Print("  Active Strategies: ", activeCount, "/8");
    Print("----------------------------------------");
    
    // Display all strategies if requested, otherwise only active
    int signalCount = 0;
    for(int i = 0; i < 8; i++) {
        bool isActive = g_manager.IsStrategyActive(i);
        
        if(InpShowAllStrategies || isActive) {
            Print("");
            Print("Strategy [", i, "] - ", g_manager.GetStrategyName(i), ":");
            Print("  Status: ", (isActive ? "ACTIVE" : "INACTIVE"));
            Print("  Signal: ", SignalToString(signals[i].signal));
            Print("  Weight: ", DoubleToString(signals[i].weight, 2));
            
            if(signals[i].signal != SIGNAL_NONE) {
                Print("  Strength: ", DoubleToString(signals[i].strength * 100, 1), "%");
                Print("  >>> SIGNAL: ", SignalToString(signals[i].signal), 
                      " at ", DoubleToString(signals[i].strength * 100, 1), "% strength");
                signalCount++;
            }
        }
    }
    
    Print("");
    Print("========================================");
    Print("AGGREGATION SUMMARY:");
    Print("  Strategies signaling: ", signalCount, "/", activeCount);
    
    // Calculate weighted consensus
    if(signalCount >= 2) {
        int buyCount = 0;
        int sellCount = 0;
        double buyScore = 0;
        double sellScore = 0;
        double totalWeight = 0;
        string activeList = "";
        
        for(int i = 0; i < 8; i++) {
            if(signals[i].signal != SIGNAL_NONE) {
                totalWeight += signals[i].weight;
                activeList += g_manager.GetStrategyName(i) + " ";
                
                if(signals[i].signal == SIGNAL_BUY) {
                    buyCount++;
                    buyScore += signals[i].strength * signals[i].weight;
                } else if(signals[i].signal == SIGNAL_SELL) {
                    sellCount++;
                    sellScore += signals[i].strength * signals[i].weight;
                }
            }
        }
        
        Print("  Signaling: [", activeList, "]");
        Print("  BUY votes: ", buyCount, " | SELL votes: ", sellCount);
        Print("  BUY score: ", DoubleToString(buyScore, 3), 
              " | SELL score: ", DoubleToString(sellScore, 3));
        
        int requiredVotes = (int)MathMax(2, signalCount * 0.4);
        
        if(buyCount >= requiredVotes && buyScore > sellScore * 1.05) {
            double consensusStrength = buyScore / totalWeight;
            Print("  >>> CONSENSUS: BUY with ", DoubleToString(consensusStrength * 100, 1), "% strength");
            Print("  Quality: ", (signalCount >= 3 ? "HIGH" : "MEDIUM"), 
                  " (", requiredVotes, " votes required, ", buyCount, " received)");
        } else if(sellCount >= requiredVotes && sellScore > buyScore * 1.05) {
            double consensusStrength = sellScore / totalWeight;
            Print("  >>> CONSENSUS: SELL with ", DoubleToString(consensusStrength * 100, 1), "% strength");
            Print("  Quality: ", (signalCount >= 3 ? "HIGH" : "MEDIUM"),
                  " (", requiredVotes, " votes required, ", sellCount, " received)");
        } else {
            Print("  >>> NO CONSENSUS: Insufficient agreement");
            if(buyCount > 0 && sellCount > 0) {
                Print("  Conflict: ", buyCount, " BUY vs ", sellCount, " SELL");
            }
        }
    } else if(signalCount == 1) {
        Print("  Only 1 strategy signaling - consensus requires 2+");
    } else {
        Print("  No strategies signaling");
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
