//+------------------------------------------------------------------+
//|                                        TestUIComponents.mq5     |
//|                                      Aurum Synapse v2.0 Pro      |
//|                      Test: InfoPanel + Logger                    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "1.00"
#property description "Test EA - Verify InfoPanel and Logger components"

#include "../UI/InfoPanel.mqh"
#include "../UI/Logger.mqh"
#include "../Core/Constants.mqh"
#include "../Core/Structures.mqh"

//--- Global objects
InfoPanel *g_panel = NULL;

//--- Test state
datetime g_lastBarTime = 0;
int g_testCount = 0;

//+------------------------------------------------------------------+
//| Expert initialization                                             |
//+------------------------------------------------------------------+
int OnInit() {
    Print("========================================");
    Print("  UI COMPONENTS TEST");
    Print("========================================");
    
    //--- 1. Initialize Logger
    Print("\n[1/2] Initializing Logger...");
    if(!Logger::Init()) {
        Print("ERROR: Logger initialization failed");
        return INIT_FAILED;
    }
    
    Logger::Info("========================================");
    Logger::Info("  AURUM SYNAPSE v2.0 TEST SESSION");
    Logger::Info("========================================");
    Logger::Info("Test EA started - Symbol: " + _Symbol);
    
    Print("✓ Logger initialized");
    
    //--- 2. Initialize InfoPanel
    Print("\n[2/2] Initializing Info Panel...");
    g_panel = new InfoPanel();
    if(g_panel == NULL) {
        Logger::Error("Failed to create InfoPanel");
        Logger::Deinit();
        return INIT_FAILED;
    }
    
    if(!g_panel.Init(1)) {  // Update every 1 second
        Logger::Error("InfoPanel initialization failed");
        delete g_panel;
        Logger::Deinit();
        return INIT_FAILED;
    }
    
    //--- Set test configuration
    g_panel.SetConfig(LOT_FIXED, 0.01, 1.5, 123456, 60, 5);
    
    Logger::Info("InfoPanel initialized successfully");
    Print("✓ Info Panel initialized");
    
    Print("\n========================================");
    Print("  ALL UI COMPONENTS INITIALIZED!");
    Print("  Logger: Writing to MQL5/Files/AurumSynapse/");
    Print("  InfoPanel: Displaying on chart");
    Print("========================================\n");
    
    Logger::Info("All UI components initialized successfully");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Logger::Info("========================================");
    Logger::Info("  TEST SESSION ENDED");
    Logger::Info("  Reason: " + IntegerToString(reason));
    Logger::Info("  Total test cycles: " + IntegerToString(g_testCount));
    Logger::Info("========================================");
    
    //--- Cleanup
    if(g_panel != NULL) {
        g_panel.Clear();
        delete g_panel;
    }
    
    Logger::Deinit();
    
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
    
    g_testCount++;
    
    Logger::Info("========== TEST CYCLE #" + IntegerToString(g_testCount) + " ==========");
    
    //--- Create test market state
    MarketState state;
    state.timestamp = TimeCurrent();
    state.bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    state.ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    state.spread = (state.ask - state.bid) / _Point;
    
    //--- Get some indicators for test
    double ema21[1], rsi[1], atr[1], adx[1];
    int hEMA = iMA(_Symbol, PERIOD_H1, 21, 0, MODE_EMA, PRICE_CLOSE);
    int hRSI = iRSI(_Symbol, PERIOD_H1, 14, PRICE_CLOSE);
    int hATR = iATR(_Symbol, PERIOD_H1, 14);
    int hADX = iADX(_Symbol, PERIOD_H1, 14);
    
    if(CopyBuffer(hEMA, 0, 0, 1, ema21) == 1) state.ema21 = ema21[0];
    if(CopyBuffer(hRSI, 0, 0, 1, rsi) == 1) state.rsi14 = rsi[0];
    if(CopyBuffer(hATR, 0, 0, 1, atr) == 1) state.atr14 = atr[0];
    if(CopyBuffer(hADX, 0, 0, 1, adx) == 1) state.adx = adx[0];
    
    //--- Classify market
    if(state.adx > 25) state.regime = REGIME_TRENDING;
    else if(state.adx < 15) state.regime = REGIME_CALM;
    else state.regime = REGIME_RANGING;
    
    if(state.ema21 > state.bid) state.trendDir = TREND_UP;
    else state.trendDir = TREND_DOWN;
    
    //--- Detect session
    MqlDateTime dt;
    TimeCurrent(dt);
    state.hourWIT = dt.hour;
    
    if(dt.hour >= 7 && dt.hour <= 16) state.session = SESSION_LONDON;
    else if(dt.hour >= 14 && dt.hour <= 23) state.session = SESSION_NEWYORK;
    else state.session = SESSION_ASIAN;
    
    state.isGoldenHour = (dt.hour == 22 || dt.hour == 23 || dt.hour == 8 || dt.hour == 9);
    
    state.atrRatio = 1.0;  // Simplified for test
    
    //--- Create test strategy active states
    bool strategyActive[8];
    for(int i = 0; i < 8; i++) {
        strategyActive[i] = (MathRand() % 2 == 0);  // Random ON/OFF for test
    }
    
    //--- Count active strategies
    int activeCount = 0;
    for(int i = 0; i < 8; i++) {
        if(strategyActive[i]) activeCount++;
    }
    
    //--- Create test consensus
    ENUM_SIGNAL consensus = SIGNAL_NONE;
    double consensusStrength = 0;
    double agreementPct = 0;
    int qualityScore = 0;
    
    if(activeCount >= 3) {
        consensus = (state.rsi14 > 50) ? SIGNAL_BUY : SIGNAL_SELL;
        consensusStrength = 150.0 + (MathRand() % 100);
        agreementPct = 60.0 + (MathRand() % 40);
        qualityScore = 50 + (MathRand() % 30);
    }
    
    //--- Test risk values
    double dailyPnL = -50.0 + (MathRand() % 100);  // Random -50 to +50
    double equityDD = (MathRand() % 8);  // Random 0-8%
    int consecutiveLosses = (MathRand() % 4);  // Random 0-3
    
    //--- Log market state
    Logger::Info("Market State: " + EnumToString(state.regime) + 
                 " | Trend: " + EnumToString(state.trendDir) +
                 " | ADX: " + DoubleToString(state.adx, 1));
    
    //--- Log session info
    if(state.isGoldenHour) {
        Logger::Info("GOLDEN HOUR detected! ⭐");
    }
    
    //--- Log signal
    if(consensus != SIGNAL_NONE) {
        Logger::LogSignal(EnumToString(consensus), activeCount, consensusStrength, qualityScore);
    }
    
    //--- Test trade logging (simulate)
    if(g_testCount % 5 == 0 && consensus != SIGNAL_NONE) {
        ulong fakeTicket = 123456789 + g_testCount;
        Logger::LogTrade(fakeTicket, "OPEN_" + EnumToString(consensus), 0.01,
                        state.bid, state.bid - 100*_Point, state.bid + 200*_Point, qualityScore);
    }
    
    //--- Update info panel
    g_panel.Update(state,
                   strategyActive,
                   8,
                   consensus,
                   consensusStrength,
                   agreementPct,
                   qualityScore,
                   dailyPnL,
                   equityDD,
                   consecutiveLosses);
    
    //--- Release handles
    IndicatorRelease(hEMA);
    IndicatorRelease(hRSI);
    IndicatorRelease(hATR);
    IndicatorRelease(hADX);
    
    //--- Flush logger every 10 cycles
    if(g_testCount % 10 == 0) {
        Logger::Flush();
        Logger::Debug("Logger flushed at cycle " + IntegerToString(g_testCount));
    }
}

//+------------------------------------------------------------------+
//| Test logging functions                                            |
//+------------------------------------------------------------------+
void TestLogging() {
    Logger::Debug("This is a DEBUG message");
    Logger::Info("This is an INFO message");
    Logger::Warning("This is a WARNING message");
    Logger::Error("This is an ERROR message");
    Logger::Trade("This is a TRADE message");
    
    Logger::LogError("TestFunction", "Simulated error for testing");
}

//+------------------------------------------------------------------+
//| END OF TEST EA                                                    |
//+------------------------------------------------------------------+
