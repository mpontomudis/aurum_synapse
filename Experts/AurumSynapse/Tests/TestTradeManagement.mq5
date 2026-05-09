//+------------------------------------------------------------------+
//|                                TestTradeManagement.mq5          |
//|                                      Aurum Synapse v2.0 Pro      |
//|                Test: MoneyManager + RiskManager + TradeManager   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "1.00"
#property description "Test EA - Verify all 3 trade management components"

#include "../Execution/MoneyManager.mqh"
#include "../Management/RiskManager.mqh"
#include "../Execution/TradeManager.mqh"

//--- Input parameters for testing
input ENUM_LOT_METHOD InpLotMethod = LOT_FIXED;        // Lot sizing method
input double InpFixedLot = 0.01;                       // Fixed lot size
input double InpRiskPercent = 1.0;                     // Risk percent (auto mode)
input double InpMaxDailyLossPct = 5.0;                 // Max daily loss %
input double InpMaxEquityDDPct = 12.0;                 // Max equity DD %
input int InpMagicNumber = 20260505;                   // Magic number

//--- Global objects
MoneyManager *g_moneyMgr = NULL;
RiskManager  *g_riskMgr = NULL;
TradeManager *g_tradeMgr = NULL;

//--- Test state
datetime g_lastBarTime = 0;
int g_testCount = 0;

//+------------------------------------------------------------------+
//| Expert initialization                                             |
//+------------------------------------------------------------------+
int OnInit() {
    Print("========================================");
    Print("  TRADE MANAGEMENT COMPONENTS TEST");
    Print("========================================");
    
    //--- 1. Initialize Money Manager
    Print("\n[1/3] Initializing Money Manager...");
    g_moneyMgr = new MoneyManager();
    if(g_moneyMgr == NULL) {
        Print("ERROR: Failed to create MoneyManager");
        return INIT_FAILED;
    }
    
    if(!g_moneyMgr.Init(_Symbol)) {
        Print("ERROR: MoneyManager initialization failed");
        delete g_moneyMgr;
        return INIT_FAILED;
    }
    Print("✓ Money Manager initialized");
    
    //--- 2. Initialize Risk Manager
    Print("\n[2/3] Initializing Risk Manager...");
    g_riskMgr = new RiskManager();
    if(g_riskMgr == NULL) {
        Print("ERROR: Failed to create RiskManager");
        delete g_moneyMgr;
        return INIT_FAILED;
    }
    
    if(!g_riskMgr.Init()) {
        Print("ERROR: RiskManager initialization failed");
        delete g_moneyMgr;
        delete g_riskMgr;
        return INIT_FAILED;
    }
    Print("✓ Risk Manager initialized");
    
    //--- 3. Initialize Trade Manager
    Print("\n[3/3] Initializing Trade Manager...");
    g_tradeMgr = new TradeManager();
    if(g_tradeMgr == NULL) {
        Print("ERROR: Failed to create TradeManager");
        delete g_moneyMgr;
        delete g_riskMgr;
        return INIT_FAILED;
    }
    
    if(!g_tradeMgr.Init(_Symbol, InpMagicNumber)) {
        Print("ERROR: TradeManager initialization failed");
        delete g_moneyMgr;
        delete g_riskMgr;
        delete g_tradeMgr;
        return INIT_FAILED;
    }
    Print("✓ Trade Manager initialized");
    
    Print("\n========================================");
    Print("  ALL COMPONENTS INITIALIZED!");
    Print("  Lot Method: ", EnumToString(InpLotMethod));
    Print("  Risk Limits: ", InpMaxDailyLossPct, "% daily | ", InpMaxEquityDDPct, "% DD");
    Print("========================================\n");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("\n========================================");
    Print("  TEST SUMMARY");
    Print("========================================");
    
    if(g_tradeMgr != NULL) {
        Print("Orders Opened: ", g_tradeMgr.GetOrdersOpened());
        Print("Orders Closed: ", g_tradeMgr.GetOrdersClosed());
        Print("Orders Failed: ", g_tradeMgr.GetOrdersFailed());
    }
    
    if(g_riskMgr != NULL) {
        Print("Daily P/L: $", DoubleToString(g_riskMgr.GetDailyPnL(), 2));
        Print("Consecutive Wins: ", g_riskMgr.GetConsecutiveWins());
        Print("Consecutive Losses: ", g_riskMgr.GetConsecutiveLosses());
        Print("Equity DD: ", DoubleToString(g_riskMgr.GetEquityDD(), 2), "%");
    }
    
    Print("========================================\n");
    
    //--- Cleanup
    if(g_tradeMgr != NULL) delete g_tradeMgr;
    if(g_riskMgr != NULL) delete g_riskMgr;
    if(g_moneyMgr != NULL) delete g_moneyMgr;
    
    Print("Test EA stopped.");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick() {
    //--- Check for new bar
    datetime currentBarTime = iTime(_Symbol, PERIOD_M5, 0);
    if(currentBarTime == g_lastBarTime) return;
    g_lastBarTime = currentBarTime;
    
    g_testCount++;
    
    Print("\n========== TEST #", g_testCount, " - ", TimeToString(currentBarTime, TIME_DATE|TIME_MINUTES), " ==========");
    
    //--- Test 1: Check risk limits
    Print("\n--- RISK STATUS ---");
    Print("Can Trade: ", g_riskMgr.CanTrade() ? "YES" : "NO");
    Print("Daily P/L: $", DoubleToString(g_riskMgr.GetDailyPnL(), 2));
    Print("Equity DD: ", DoubleToString(g_riskMgr.GetEquityDD(), 2), "%");
    Print("Peak Equity: $", DoubleToString(g_riskMgr.GetPeakEquity(), 2));
    Print("Consecutive Wins: ", g_riskMgr.GetConsecutiveWins());
    Print("Consecutive Losses: ", g_riskMgr.GetConsecutiveLosses());
    
    if(g_riskMgr.IsHalted()) {
        Print("🛑 CIRCUIT BREAKER ACTIVE: ", g_riskMgr.GetHaltReason());
        return;
    }
    
    //--- Test 2: Calculate lot sizes using different methods
    Print("\n--- LOT SIZING TEST ---");
    
    //--- Calculate SL distance (example: 100 points)
    double slDistancePoints = 100.0;
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    //--- Method 1: Fixed lot
    double lot1 = g_moneyMgr.CalculateLotSize(LOT_FIXED, 0, 0.01, 0, 0, 0);
    Print("Fixed Lot: ", lot1);
    
    //--- Method 2: Auto (risk-based)
    double lot2 = g_moneyMgr.CalculateLotSize(LOT_AUTO, InpRiskPercent, 0, 0, 3.0, slDistancePoints);
    Print("Auto Lot (", InpRiskPercent, "% risk): ", lot2);
    double riskAmount = g_moneyMgr.CalculateRiskAmount(lot2, slDistancePoints);
    Print("  Risk Amount: $", DoubleToString(riskAmount, 2));
    
    //--- Method 3: Fixed per balance
    double lot3 = g_moneyMgr.CalculateLotSize(LOT_FIXED_PER_BALANCE, 0, 0, 0.01, 0, 0);
    Print("Fixed per Balance: ", lot3);
    
    //--- Show broker limits
    Print("Broker Limits: Min=", g_moneyMgr.GetMinLot(), 
          " Max=", g_moneyMgr.GetMaxLot(),
          " Step=", g_moneyMgr.GetLotStep());
    
    //--- Test 3: Count open positions
    Print("\n--- POSITION STATUS ---");
    int openPos = g_tradeMgr.CountOpenPositions();
    Print("Open Positions: ", openPos);
    
    //--- Test 4: Check margin for hypothetical trade
    Print("\n--- MARGIN CHECK ---");
    double testLot = 0.01;
    bool marginOK = g_moneyMgr.CheckMarginRequirement(testLot, ORDER_TYPE_BUY);
    Print("Margin check (", testLot, " lot): ", marginOK ? "PASS" : "FAIL");
    
    //--- Test 5: Risk limit checks
    Print("\n--- RISK LIMIT CHECKS ---");
    bool dailyLossOK = !g_riskMgr.IsDailyLossExceeded(InpMaxDailyLossPct);
    bool equityDDOK = !g_riskMgr.IsEquityDDExceeded(InpMaxEquityDDPct);
    bool consecutiveOK = !g_riskMgr.IsMaxConsecutiveLossesReached();
    
    Print("Daily Loss Check: ", dailyLossOK ? "PASS" : "FAIL");
    Print("Equity DD Check: ", equityDDOK ? "PASS" : "FAIL");
    Print("Consecutive Loss Check: ", consecutiveOK ? "PASS" : "FAIL");
    
    //--- Test 6: Simulate position management (trailing stops)
    if(openPos > 0) {
        Print("\n--- POSITION MANAGEMENT ---");
        bool managed = g_tradeMgr.ManagePositions(true, 10.0, 5.0);  // Trail after 10 pips, 5 pips distance
        Print("Trailing Stop Update: ", managed ? "SUCCESS" : "SKIPPED");
    }
    
    //--- Display execution statistics
    Print("\n--- EXECUTION STATISTICS ---");
    Print("Total Opened: ", g_tradeMgr.GetOrdersOpened());
    Print("Total Closed: ", g_tradeMgr.GetOrdersClosed());
    Print("Total Failed: ", g_tradeMgr.GetOrdersFailed());
    
    Print("========================================\n");
    
    //--- Note: This is a test EA - it does NOT actually open trades
    //--- To test actual execution, manually trigger test trades
    Print("💡 TIP: To test execution, manually call OpenBuy/OpenSell from terminal");
}

//+------------------------------------------------------------------+
//| Test function for manual trade execution                         |
//+------------------------------------------------------------------+
void TestOpenBuyOrder() {
    if(!g_riskMgr.CanTrade()) {
        Print("⚠️ Cannot trade - Risk limits exceeded");
        return;
    }
    
    //--- Calculate lot size
    double lot = g_moneyMgr.CalculateLotSize(InpLotMethod, InpRiskPercent, 
                                               InpFixedLot, 0.01, 3.0, 100.0);
    
    //--- Calculate SL/TP (example: 100 points SL, 200 points TP)
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double sl = ask - (100 * point);
    double tp = ask + (200 * point);
    
    //--- Open position
    Print("\n🧪 TEST: Opening BUY position...");
    ulong ticket = g_tradeMgr.OpenBuy(lot, sl, tp, 75, "TEST BUY");
    
    if(ticket > 0) {
        Print("✅ TEST BUY SUCCESS - Ticket: ", ticket);
        g_riskMgr.OnTradeOpened(lot);
    } else {
        Print("❌ TEST BUY FAILED");
    }
}

//+------------------------------------------------------------------+
//| Test function for manual trade closure                           |
//+------------------------------------------------------------------+
void TestCloseAllOrders() {
    Print("\n🧪 TEST: Closing all positions...");
    bool success = g_tradeMgr.CloseAllPositions();
    Print(success ? "✅ All positions closed" : "⚠️ Some positions remain open");
}

//+------------------------------------------------------------------+
//| END OF TEST EA                                                    |
//+------------------------------------------------------------------+
