//+------------------------------------------------------------------+
//|                                    TestEngineComponents.mq5     |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Test: MarketAnalyzer + SignalManager + QualityFilter |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "1.00"
#property description "Test EA - Verify all 3 engine components"

#include "../Engine/StrategyManager.mqh"
#include "../Engine/MarketAnalyzer.mqh"
#include "../Engine/SignalManager.mqh"
#include "../Engine/QualityFilter.mqh"

//--- Global objects
StrategyManager *g_stratManager = NULL;
MarketAnalyzer  *g_analyzer = NULL;
SignalManager   *g_signalMgr = NULL;
QualityFilter   *g_qualityFilter = NULL;

//--- Test state
datetime g_lastBarTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization                                             |
//+------------------------------------------------------------------+
int OnInit() {
    Print("========================================");
    Print("  AURUM SYNAPSE - Engine Components Test");
    Print("========================================");
    
    //--- 1. Create Strategy Manager (manages all 8 strategies)
    Print("\n[1/4] Initializing Strategy Manager...");
    g_stratManager = new StrategyManager();
    if(g_stratManager == NULL) {
        Print("ERROR: Failed to create StrategyManager");
        return INIT_FAILED;
    }
    
    if(!g_stratManager.Init(_Symbol, PERIOD_M1)) {
        Print("ERROR: StrategyManager initialization failed");
        delete g_stratManager;
        return INIT_FAILED;
    }
    Print("✓ Strategy Manager initialized (8 strategies loaded)");
    
    //--- 2. Create Market Analyzer (regime classification)
    Print("\n[2/4] Initializing Market Analyzer...");
    g_analyzer = new MarketAnalyzer();
    if(g_analyzer == NULL) {
        Print("ERROR: Failed to create MarketAnalyzer");
        delete g_stratManager;
        return INIT_FAILED;
    }
    
    if(!g_analyzer.Init(_Symbol, PERIOD_M1)) {
        Print("ERROR: MarketAnalyzer initialization failed");
        delete g_stratManager;
        delete g_analyzer;
        return INIT_FAILED;
    }
    Print("✓ Market Analyzer initialized (9 indicators loaded)");
    
    //--- 3. Create Signal Manager (consensus voting)
    Print("\n[3/4] Initializing Signal Manager...");
    g_signalMgr = new SignalManager();
    if(g_signalMgr == NULL) {
        Print("ERROR: Failed to create SignalManager");
        delete g_stratManager;
        delete g_analyzer;
        return INIT_FAILED;
    }
    Print("✓ Signal Manager initialized (weighted voting ready)");
    
    //--- 4. Create Quality Filter (11-component scoring)
    Print("\n[4/4] Initializing Quality Filter...");
    g_qualityFilter = new QualityFilter();
    if(g_qualityFilter == NULL) {
        Print("ERROR: Failed to create QualityFilter");
        delete g_stratManager;
        delete g_analyzer;
        delete g_signalMgr;
        return INIT_FAILED;
    }
    
    if(!g_qualityFilter.Init(_Symbol)) {
        Print("ERROR: QualityFilter initialization failed");
        delete g_stratManager;
        delete g_analyzer;
        delete g_signalMgr;
        delete g_qualityFilter;
        return INIT_FAILED;
    }
    Print("✓ Quality Filter initialized (MTF EMAs loaded)");
    
    Print("\n========================================");
    Print("  ALL ENGINE COMPONENTS INITIALIZED!");
    Print("  Ready to test full pipeline...");
    Print("========================================\n");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("Cleaning up engine components...");
    
    if(g_qualityFilter != NULL) delete g_qualityFilter;
    if(g_signalMgr != NULL) delete g_signalMgr;
    if(g_analyzer != NULL) delete g_analyzer;
    if(g_stratManager != NULL) delete g_stratManager;
    
    Print("Test EA stopped.");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick() {
    //--- Check for new bar
    datetime currentBarTime = iTime(_Symbol, PERIOD_M1, 0);
    if(currentBarTime == g_lastBarTime) return;
    g_lastBarTime = currentBarTime;
    
    Print("\n========== NEW BAR: ", TimeToString(currentBarTime, TIME_DATE|TIME_MINUTES), " ==========");
    
    //--- Step 1: Update Market Analyzer
    if(!g_analyzer.Update()) {
        Print("WARNING: MarketAnalyzer update failed");
        return;
    }
    
    MarketState state = g_analyzer.GetState();
    
    //--- Print Market State
    Print("\n--- MARKET STATE ---");
    Print("Regime: ", EnumToString(state.regime), 
          " | Trend: ", EnumToString(state.trendDir),
          " | Session: ", EnumToString(state.session));
    Print("ADX: ", DoubleToString(state.adx, 1),
          " | ATR Ratio: ", DoubleToString(state.atrRatio, 2),
          " | RSI: ", DoubleToString(state.rsi14, 1));
    Print("Golden Hour: ", state.isGoldenHour ? "YES ⭐" : "No",
          " | Hour WIT: ", state.hourWIT);
    
    //--- Step 2: Evaluate all strategies
    g_stratManager.EvaluateAll(state);
    
    SignalResult signals[8];
    g_stratManager.GetAllSignals(signals);
    
    int activeCount = g_stratManager.GetActiveStrategyCount();
    Print("\n--- STRATEGY SIGNALS (", activeCount, "/8 active) ---");
    
    for(int i = 0; i < 8; i++) {
        if(g_stratManager.IsStrategyActive(i)) {
            Print(signals[i].strategyName, ": ",
                  EnumToString(signals[i].signal),
                  " | Strength: ", DoubleToString(signals[i].strength, 1),
                  " | Weight: ", DoubleToString(signals[i].weight, 1));
        }
    }
    
    //--- Step 3: Get Consensus Signal
    ENUM_SIGNAL consensus = g_signalMgr.GetConsensusSignal(signals, 8);
    double consensusStrength = g_signalMgr.GetConsensusStrength();
    double agreementPct = g_signalMgr.GetAgreementPercentage();
    
    Print("\n--- CONSENSUS VOTE ---");
    Print("BUY votes: ", g_signalMgr.GetBuyCount(), 
          " | Score: ", DoubleToString(g_signalMgr.GetBuyScore(), 1));
    Print("SELL votes: ", g_signalMgr.GetSellCount(),
          " | Score: ", DoubleToString(g_signalMgr.GetSellScore(), 1));
    Print("Consensus: ", EnumToString(consensus),
          " | Strength: ", DoubleToString(consensusStrength, 1),
          " | Agreement: ", DoubleToString(agreementPct, 1), "%");
    
    //--- Step 4: Calculate Quality Score
    if(consensus != SIGNAL_NONE) {
        double qualityScore = g_qualityFilter.CalculateSetupScore(state, consensus, 
                                                                   consensusStrength, agreementPct);
        
        Print("\n--- QUALITY SCORE ---");
        Print("Total: ", DoubleToString(qualityScore, 1), "/100 pts");
        
        //--- Get detailed breakdown
        double trend, level, momentum, volume, session, volatility;
        double consensusComp, structure, liquidity, spread, timeExit;
        
        g_qualityFilter.GetScoreBreakdown(trend, level, momentum, volume, session, 
                                          volatility, consensusComp, structure, 
                                          liquidity, spread, timeExit);
        
        Print("Breakdown:");
        Print("  Trend Alignment: ", DoubleToString(trend, 1), "/12");
        Print("  Key Level Prox: ", DoubleToString(level, 1), "/12");
        Print("  Momentum: ", DoubleToString(momentum, 1), "/10");
        Print("  Volume: ", DoubleToString(volume, 1), "/8");
        Print("  Session: ", DoubleToString(session, 1), "/15 ⭐");
        Print("  Volatility: ", DoubleToString(volatility, 1), "/8");
        Print("  Consensus: ", DoubleToString(consensusComp, 1), "/10");
        Print("  Structure: ", DoubleToString(structure, 1), "/10");
        Print("  Liquidity: ", DoubleToString(liquidity, 1), "/5");
        Print("  Spread: ", DoubleToString(spread, 1), "/5");
        Print("  Time-to-Exit: ", DoubleToString(timeExit, 1), "/5");
        
        //--- Quality Rating
        string rating = "";
        if(qualityScore >= 70) rating = "EXCELLENT ⭐⭐⭐";
        else if(qualityScore >= 60) rating = "GOOD ⭐⭐";
        else if(qualityScore >= 50) rating = "ACCEPTABLE ⭐";
        else rating = "POOR ❌ (Reject)";
        
        Print("\n🎯 FINAL VERDICT: ", EnumToString(consensus), 
              " | Quality: ", rating,
              " (", DoubleToString(qualityScore, 1), " pts)");
    }
    else {
        Print("\n⚠️ NO CONSENSUS - No trade signal");
    }
    
    Print("========================================\n");
}

//+------------------------------------------------------------------+
//| END OF TEST EA                                                    |
//+------------------------------------------------------------------+
