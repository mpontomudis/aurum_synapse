//+------------------------------------------------------------------+
//|                                                  AurumSynapse.mq5 |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Aurum Synapse - AI-Powered Gold Trading System"
#property description "8 Strategies | Weighted Consensus | Quality Scoring"
#property description "Institutional-Grade Risk Management"

//--- Include all components
#include "Engine/MarketAnalyzer.mqh"
#include "Engine/StrategyManager.mqh"
#include "Engine/SignalManager.mqh"
#include "Engine/QualityFilter.mqh"
#include "Execution/MoneyManager.mqh"
#include "Management/RiskManager.mqh"
#include "Execution/TradeManager.mqh"
#include "UI/InfoPanel.mqh"
#include "UI/Logger.mqh"

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+

//--- General Settings
input group "=== GENERAL SETTINGS ==="
input ENUM_LOT_METHOD InpLotMethod = LOT_FIXED;           // Lot Sizing Method
input double InpFixedLot = 0.01;                          // Fixed Lot Size
input double InpRiskPercent = 1.0;                        // Risk % per Trade (Auto mode)
input int InpMagicNumber = 20260505;                      // Magic Number
input int InpMaxSpreadPoints = 30;                        // Max Spread (points)

//--- Strategy Activation
input group "=== STRATEGY ACTIVATION (8) ==="
input bool InpUseTrendFollowing = true;                   // [1] TrendFollowing
input bool InpUseBreakout = true;                         // [2] Breakout
input bool InpUseMeanReversion = true;                    // [3] MeanReversion
input bool InpUseSupplyDemand = true;                     // [4] SupplyDemand
input bool InpUseSmartMoney = true;                       // [5] SmartMoney
input bool InpUsePriceAction = true;                      // [6] PriceAction
input bool InpUseGridRecovery = false;                    // [7] GridRecovery (Risky!)
input bool InpUseMomentumScalp = true;                    // [8] MomentumScalp (Primary Edge)

//--- Risk Management
input group "=== RISK MANAGEMENT ==="
input double InpMaxRiskPerTrade = 3.0;                    // Max Risk % per Trade
input double InpMaxDailyLossPct = 5.0;                    // Max Daily Loss %
input double InpMaxEquityDD = 12.0;                       // Max Equity DD %
input int InpMaxConsecutiveLosses = 3;                    // Max Consecutive Losses
input int InpMaxOpenPositions = 5;                        // Max Open Positions

//--- Time Filters
input group "=== TIME FILTERS ==="
input bool InpUseTimeFilter = false;                      // Enable Time Filter
input int InpHourFrom = 0;                                // Trading Hour From (WIT)
input int InpHourTo = 23;                                 // Trading Hour To (WIT)
input bool InpTradeMon = true;                            // Trade Monday
input bool InpTradeTue = true;                            // Trade Tuesday
input bool InpTradeWed = true;                            // Trade Wednesday
input bool InpTradeThu = true;                            // Trade Thursday
input bool InpTradeFri = true;                            // Trade Friday

//--- Quality Filter
input group "=== QUALITY FILTER ==="
input int InpMinQualityScore = 50;                        // Min Quality Score (50-70)
input bool InpRequireTrendAlignment = false;              // Require Trend Alignment
input bool InpRequireKeyLevel = false;                    // Require Key Level Proximity
input bool InpRequireMomentum = false;                    // Require Momentum Confirmation

//--- Consensus Settings
input group "=== CONSENSUS ENGINE ==="
input int InpMinConsensus = 3;                            // Min Strategies Agreement (1-8)

//--- TP/SL Settings
input group "=== TP/SL SETTINGS ==="
input double InpTPCoefficient = 2.0;                      // TP Coefficient (x SL)
input double InpSLPoints = 100;                           // SL Distance (points)
input bool InpUseTrailing = true;                         // Enable Trailing Stop
input double InpTrailStartPips = 10;                      // Trailing Start (pips)
input double InpTrailDistPips = 5;                        // Trailing Distance (pips)

//--- Visual Panel
input group "=== VISUAL PANEL ==="
input bool InpShowPanel = true;                           // Show Info Panel
input int InpPanelUpdateSeconds = 1;                      // Panel Update (seconds)

//--- Diagnostics (Jul–Dec bar time only; throttled — see Aurum_*H2* helpers)
input group "=== DIAGNOSTIC (H2 Jul–Dec) ==="
input bool InpDiagH2JulDec = true;                        // Log state-change & rejects (Jul–Dec only)

//+------------------------------------------------------------------+
//| GLOBAL OBJECTS                                                   |
//+------------------------------------------------------------------+
MarketAnalyzer *g_marketAnalyzer = NULL;
StrategyManager *g_strategyManager = NULL;
SignalManager *g_signalManager = NULL;
QualityFilter *g_qualityFilter = NULL;
MoneyManager *g_moneyManager = NULL;
RiskManager *g_riskManager = NULL;
TradeManager *g_tradeManager = NULL;
InfoPanel *g_infoPanel = NULL;

//+------------------------------------------------------------------+
//| GLOBAL STATE                                                     |
//+------------------------------------------------------------------+
datetime g_lastBarTime = 0;
bool g_initialized = false;
int g_totalTrades = 0;

//--- H2 diagnostic throttling (Jul–Dec only when InpDiagH2JulDec)
static ulong   g_h2LastMarketFingerprint = 0;
static ulong   g_h2LastRejectSignature   = 0;
static ulong   g_h2LastGateDaySig        = 0; // early-gate: one line per (reason, calendar day)

//+------------------------------------------------------------------+
//| H2 window: July–December (bar open time, server / chart time)    |
//+------------------------------------------------------------------+
bool Aurum_IsH2DiagnosticMonth(const datetime barTime) {
    if(!InpDiagH2JulDec) return false;
    MqlDateTime dt;
    TimeToStruct(barTime, dt);
    return (dt.mon >= 7 && dt.mon <= 12);
}

//+------------------------------------------------------------------+
//| Compact fingerprint for regime / context (cheap on new bar)       |
//+------------------------------------------------------------------+
ulong Aurum_MarketFingerprint(const MarketState &m) {
    ulong r = ((ulong)m.regime & (ulong)0xFF) << 56;
    r |= ((ulong)(m.trendDir + 2) & (ulong)0xF) << 52;
    r |= ((ulong)(m.structure + 2) & (ulong)0xF) << 48;
    r |= ((ulong)m.session & (ulong)0xF) << 44;
    r |= ((ulong)(m.hourWIT & 31)) << 39;
    r |= ((ulong)(int)(m.rsi14 * 10.0 + 500.0) & (ulong)0x7FF) << 28;
    r |= ((ulong)(int)(m.adx * 10.0) & (ulong)0x3FF) << 18;
    r |= ((ulong)(int)(m.atrRatio * 100.0) & (ulong)0x3FFFF);
    return r;
}

//+------------------------------------------------------------------+
string Aurum_RejectReasonText(const ENUM_SIGNAL_REJECT_REASON reason) {
    switch(reason) {
        case SIGNAL_REJECT_NO_CONSENSUS:         return "NO_CONSENSUS";
        case SIGNAL_REJECT_QUALITY_LOW:          return "QUALITY_LOW";
        case SIGNAL_REJECT_REQUIRE_TREND:        return "REQUIRE_TREND";
        case SIGNAL_REJECT_REQUIRE_KEYLEVEL:     return "REQUIRE_KEYLEVEL";
        case SIGNAL_REJECT_REQUIRE_MOMENTUM:     return "REQUIRE_MOMENTUM";
        case SIGNAL_REJECT_MAX_POSITIONS:        return "MAX_POSITIONS";
        case SIGNAL_REJECT_MAX_CONSEC_LOSSES:    return "MAX_CONSEC_LOSSES";
        case SIGNAL_REJECT_RISK_HALT:            return "RISK_HALT";
        case SIGNAL_REJECT_TIME_FILTER:          return "TIME_FILTER";
        case SIGNAL_REJECT_SPREAD:               return "SPREAD";
        case SIGNAL_REJECT_MARKET_UPDATE_FAIL:   return "MARKET_UPDATE_FAIL";
        default:                                 return "NONE";
    }
}

//+------------------------------------------------------------------+
//| Log MarketState summary only when fingerprint changes (H2)      |
//+------------------------------------------------------------------+
void Aurum_LogH2MarketStateIfChanged(const MarketState &m, const datetime barTime) {
    if(!Aurum_IsH2DiagnosticMonth(barTime)) return;
    const ulong fp = Aurum_MarketFingerprint(m);
    if(fp == g_h2LastMarketFingerprint) return;
    g_h2LastMarketFingerprint = fp;
    PrintFormat("[H2-DIAG] STATE bar=%s regime=%s trend=%s struct=%s sess=%s hWIT=%d rsi=%.1f adx=%.1f atrR=%.3f bid=%.5f sprPts=%.1f",
                TimeToString(barTime, TIME_DATE | TIME_MINUTES),
                EnumToString(m.regime),
                EnumToString(m.trendDir),
                EnumToString(m.structure),
                EnumToString(m.session),
                m.hourWIT,
                m.rsi14,
                m.adx,
                m.atrRatio,
                m.bid,
                m.spread);
}

//+------------------------------------------------------------------+
//| Log rejection when (reason,consensus,quality bucket,votes) shifts |
//+------------------------------------------------------------------+
void Aurum_LogH2RejectIfChanged(const datetime barTime,
                                const ENUM_SIGNAL_REJECT_REASON reason,
                                const ENUM_SIGNAL consensus,
                                const double qualityScore,
                                const int buyCount,
                                const int sellCount) {
    if(!Aurum_IsH2DiagnosticMonth(barTime)) return;
    const int qBucket = (int)MathFloor(qualityScore);
    const ulong sig = ((ulong)reason << 56)
                    | (((ulong)(consensus + 2)) & (ulong)0xFF) << 48
                    | ((ulong)(qBucket & 0xFFFF)) << 32
                    | ((ulong)(buyCount & 0xFF)) << 16
                    | ((ulong)(sellCount & 0xFF));
    if(sig == g_h2LastRejectSignature) return;
    g_h2LastRejectSignature = sig;
    int consensusCount = 0;
    if(consensus == SIGNAL_BUY)       consensusCount = buyCount;
    else if(consensus == SIGNAL_SELL) consensusCount = sellCount;
    else                               consensusCount = MathMax(buyCount, sellCount);
    PrintFormat("[H2-DIAG] REJECT bar=%s reason=%s consensus=%s consensusCount=%d buy=%d sell=%d qualityScore=%.2f minQ=%d",
                TimeToString(barTime, TIME_DATE | TIME_MINUTES),
                Aurum_RejectReasonText(reason),
                EnumToString(consensus),
                consensusCount,
                buyCount,
                sellCount,
                qualityScore,
                InpMinQualityScore);
}

//+------------------------------------------------------------------+
//| Early gates: at most once per calendar day per reason (H2)       |
//+------------------------------------------------------------------+
void Aurum_LogH2GateOncePerDay(const datetime barTime, const ENUM_SIGNAL_REJECT_REASON reason) {
    if(!Aurum_IsH2DiagnosticMonth(barTime)) return;
    MqlDateTime dt;
    TimeToStruct(barTime, dt);
    const ushort dayKey = (ushort)((dt.mon << 8) | (dt.day & 0xFF));
    const ulong sig = ((ulong)reason << 32) | (ulong)dayKey;
    if(sig == g_h2LastGateDaySig) return;
    g_h2LastGateDaySig = sig;
    PrintFormat("[H2-DIAG] GATE bar=%s reason=%s dayKey=%u",
                TimeToString(barTime, TIME_DATE | TIME_MINUTES),
                Aurum_RejectReasonText(reason),
                (uint)dayKey);
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print("========================================");
    Print("  AURUM SYNAPSE v2.0 INITIALIZATION");
    Print("========================================");
    
    //--- Initialize Logger first
    if(!Logger::Init()) {
        Print("ERROR: Logger initialization failed");
        return INIT_FAILED;
    }
    
    Logger::Info("========================================");
    Logger::Info("  AURUM SYNAPSE v2.0 - STARTING");
    Logger::Info("  Symbol: " + _Symbol);
    Logger::Info("  Timeframe: " + EnumToString(_Period));
    Logger::Info("========================================");
    
    //--- Validate inputs
    if(!ValidateInputs()) {
        Logger::Error("Input validation failed");
        Logger::Deinit();
        return INIT_FAILED;
    }
    
    //--- Create and initialize Market Analyzer
    Print("\n[1/8] Initializing Market Analyzer...");
    g_marketAnalyzer = new MarketAnalyzer();
    if(g_marketAnalyzer == NULL || !g_marketAnalyzer.Init(_Symbol, _Period)) {
        Logger::Error("MarketAnalyzer initialization failed");
        Cleanup();
        return INIT_FAILED;
    }
    Logger::Info("MarketAnalyzer initialized successfully");
    
    //--- Create and initialize Strategy Manager
    Print("[2/8] Initializing Strategy Manager...");
    g_strategyManager = new StrategyManager();
    if(g_strategyManager == NULL || !g_strategyManager.Init(_Symbol, _Period)) {
        Logger::Error("StrategyManager initialization failed");
        Cleanup();
        return INIT_FAILED;
    }
    Logger::Info("StrategyManager initialized - 8 strategies loaded");
    
    //--- Create Signal Manager
    Print("[3/8] Initializing Signal Manager...");
    g_signalManager = new SignalManager();
    if(g_signalManager == NULL) {
        Logger::Error("SignalManager creation failed");
        Cleanup();
        return INIT_FAILED;
    }
    g_signalManager.SetMinConsensus(InpMinConsensus);
    Logger::Info("SignalManager initialized - Weighted consensus ready");
    Logger::Info("  Min consensus required: " + IntegerToString(InpMinConsensus) + " strategies");
    
    //--- Create and initialize Quality Filter
    Print("[4/8] Initializing Quality Filter...");
    g_qualityFilter = new QualityFilter();
    if(g_qualityFilter == NULL || !g_qualityFilter.Init(_Symbol)) {
        Logger::Error("QualityFilter initialization failed");
        Cleanup();
        return INIT_FAILED;
    }
    Logger::Info("QualityFilter initialized - 11 components ready");
    
    //--- Create and initialize Money Manager
    Print("[5/8] Initializing Money Manager...");
    g_moneyManager = new MoneyManager();
    if(g_moneyManager == NULL || !g_moneyManager.Init(_Symbol)) {
        Logger::Error("MoneyManager initialization failed");
        Cleanup();
        return INIT_FAILED;
    }
    Logger::Info("MoneyManager initialized - Lot method: " + EnumToString(InpLotMethod));
    
    //--- Create and initialize Risk Manager
    Print("[6/8] Initializing Risk Manager...");
    g_riskManager = new RiskManager();
    if(g_riskManager == NULL || !g_riskManager.Init()) {
        Logger::Error("RiskManager initialization failed");
        Cleanup();
        return INIT_FAILED;
    }
    Logger::Info("RiskManager initialized - Circuit breakers active");
    
    //--- Create and initialize Trade Manager
    Print("[7/8] Initializing Trade Manager...");
    g_tradeManager = new TradeManager();
    if(g_tradeManager == NULL || !g_tradeManager.Init(_Symbol, InpMagicNumber)) {
        Logger::Error("TradeManager initialization failed");
        Cleanup();
        return INIT_FAILED;
    }
    Logger::Info("TradeManager initialized - Magic: " + IntegerToString(InpMagicNumber));
    
    //--- Create and initialize Info Panel
    Print("[8/8] Initializing Info Panel...");
    g_infoPanel = new InfoPanel();
    if(g_infoPanel == NULL || !g_infoPanel.Init(InpPanelUpdateSeconds)) {
        Logger::Error("InfoPanel initialization failed");
        Cleanup();
        return INIT_FAILED;
    }
    
    //--- Set EA configuration for panel display
    g_infoPanel.SetConfig(InpLotMethod, InpFixedLot, InpRiskPercent,
                          InpMagicNumber, InpMinQualityScore, InpMaxOpenPositions);
    
    Logger::Info("InfoPanel initialized - Update: " + IntegerToString(InpPanelUpdateSeconds) + "s");
    
    //--- Hide panel if disabled
    if(!InpShowPanel) {
        g_infoPanel.Hide();
    }
    
    //--- Log configuration
    LogConfiguration();
    
    //--- Success
    g_initialized = true;
    
    //--- Initialize last bar time to prevent immediate processing on first tick
    g_lastBarTime = iTime(_Symbol, _Period, 0);
    
    Print("\n========================================");
    Print("  AURUM SYNAPSE v2.0 READY");
    Print("  All components initialized successfully");
    Print("========================================\n");
    
    Logger::Info("========================================");
    Logger::Info("  INITIALIZATION COMPLETE - READY TO TRADE");
    Logger::Info("========================================");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("!!!!! ONDEINIT CALLED - REASON: ", reason, " !!!!!");
    Logger::Info("========================================");
    Logger::Info("  AURUM SYNAPSE v2.0 - STOPPING");
    Logger::Info("  Reason: " + IntegerToString(reason));
    Logger::Info("  Engine bar counter (bars processed + successful opens): " + IntegerToString(g_totalTrades));
    Logger::Info("========================================");
    
    Print("\nAurum Synapse v2.0 - Stopping...");
    Print("Reason: ", reason);
    Print("Engine bar counter (not MT5 deal count): ", g_totalTrades);
    
    //--- Cleanup all objects
    Cleanup();
    
    //--- Close logger last
    Logger::Info("Aurum Synapse v2.0 stopped successfully");
    Logger::Deinit();
    
    Print("Cleanup complete.\n");
}

//+------------------------------------------------------------------+
//| Expert tick function - MAIN TRADING LOGIC                        |
//+------------------------------------------------------------------+
void OnTick() {
    if(!g_initialized) {
        return;
    }
    
    //--- Reentrancy guard: block nested OnTick() execution (tester safety)
    static bool s_inOnTick = false;
    if(s_inOnTick) return;
    s_inOnTick = true;
    
    // Use single-exit pattern to guarantee guard reset
    do {
    
    //--- CRITICAL: Only process on NEW BAR to avoid stack overflow from excessive processing
    datetime currentBarTime = iTime(_Symbol, _Period, 0);
    if(currentBarTime == g_lastBarTime) {
        //--- Not a new bar - skip processing
        if(InpShowPanel && g_infoPanel != NULL) {
            UpdatePanel();
        }
        break;
    }
    
    //--- NEW BAR detected - proceed with processing
    g_lastBarTime = currentBarTime;
    g_totalTrades++;  // Count bars processed
    
    const bool h2Diag = Aurum_IsH2DiagnosticMonth(currentBarTime);
    
    //--- DIAGNOSTIC: Log every 10 bars (reduced from every tick to prevent stack issues)
    if(!h2Diag && (g_totalTrades <= 3 || g_totalTrades % 10 == 0)) {
        PrintFormat("[BAR #%d] Processing new bar @ %s", g_totalTrades, TimeToString(currentBarTime, TIME_DATE | TIME_MINUTES));
    }
    
    //--- 1. Check risk limits (CRITICAL - CHECK FIRST)
    if(!g_riskManager.CanTrade()) {
        Aurum_LogH2GateOncePerDay(currentBarTime, SIGNAL_REJECT_RISK_HALT);
        if(!h2Diag && g_totalTrades <= 3) {
            string msg = "[BLOCKED] Risk Manager - " + g_riskManager.GetHaltReason();
            Print(msg);
        }
        UpdatePanel();
        break;
    }
    
    //--- 2. Check time filter
    if(!IsTimeAllowed()) {
        Aurum_LogH2GateOncePerDay(currentBarTime, SIGNAL_REJECT_TIME_FILTER);
        if(!h2Diag && g_totalTrades <= 3) {
            Print("[BLOCKED] Time Filter");
        }
        UpdatePanel();
        break;
    }
    
    //--- 3. Check spread filter
    double spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
    if(spread > InpMaxSpreadPoints) {
        Aurum_LogH2GateOncePerDay(currentBarTime, SIGNAL_REJECT_SPREAD);
        if(!h2Diag && g_totalTrades <= 3) {
            PrintFormat("[BLOCKED] Spread too wide: %.1f > %d", spread, InpMaxSpreadPoints);
        }
        UpdatePanel();
        break;
    }
    
    //--- 4. Update market analysis
    if(!g_marketAnalyzer.Update()) {
        Aurum_LogH2GateOncePerDay(currentBarTime, SIGNAL_REJECT_MARKET_UPDATE_FAIL);
        Logger::Warning("[ERROR] MarketAnalyzer update failed");
        break;
    }
    
    MarketState marketState = g_marketAnalyzer.GetState();
    Aurum_LogH2MarketStateIfChanged(marketState, currentBarTime);
    
    //--- 5. Evaluate all strategies
    g_strategyManager.EvaluateAll(marketState);
    
    //--- 6. Get all signals
    // Use fixed-size array to avoid per-bar dynamic allocations
    SignalResult signals[8];
    g_strategyManager.GetAllSignals(signals);
    
    //--- Mask disabled strategies before consensus (indices = StrategyManager order)
    if(!InpUseTrendFollowing)   { signals[0].signal = SIGNAL_NONE; signals[0].strength = 0.0; }
    if(!InpUseBreakout)         { signals[1].signal = SIGNAL_NONE; signals[1].strength = 0.0; }
    if(!InpUseMeanReversion)    { signals[2].signal = SIGNAL_NONE; signals[2].strength = 0.0; }
    if(!InpUseSupplyDemand)     { signals[3].signal = SIGNAL_NONE; signals[3].strength = 0.0; }
    if(!InpUseSmartMoney)       { signals[4].signal = SIGNAL_NONE; signals[4].strength = 0.0; }
    if(!InpUsePriceAction)      { signals[5].signal = SIGNAL_NONE; signals[5].strength = 0.0; }
    if(!InpUseGridRecovery)     { signals[6].signal = SIGNAL_NONE; signals[6].strength = 0.0; }
    if(!InpUseMomentumScalp)    { signals[7].signal = SIGNAL_NONE; signals[7].strength = 0.0; }
    
    int activeCount = g_strategyManager.GetActiveStrategyCount();
    
    //--- DIAGNOSTIC: Count signals and show strategy details (first 3 bars only, non-H2)
    if(!h2Diag && g_totalTrades <= 3) {
        int buyCount = 0, sellCount = 0, noneCount = 0;
        for(int i = 0; i < 8; i++) {
            if(signals[i].signal == SIGNAL_BUY) buyCount++;
            else if(signals[i].signal == SIGNAL_SELL) sellCount++;
            else noneCount++;
        }
        Print("[SIGNALS] Active: ", activeCount, " | BUY: ", buyCount, " | SELL: ", sellCount, " | NONE: ", noneCount);
        Print("[REGIME] Current: ", EnumToString(marketState.regime), " | ADX: ", DoubleToString(marketState.adx, 1), " | ATR Ratio: ", DoubleToString(marketState.atrRatio, 2));
        
        // Show indicator values to verify they're populated
        Print("[INDICATORS] EMA21: ", DoubleToString(marketState.ema21, 2), 
              " | RSI: ", DoubleToString(marketState.rsi14, 1),
              " | ATR: ", DoubleToString(marketState.atr14, 2));
        
        // Show Bollinger Bands (critical for MeanReversion)
        Print("[BB] Upper: ", DoubleToString(marketState.bbUpper, 2),
              " | Mid: ", DoubleToString(marketState.bbMiddle, 2),
              " | Lower: ", DoubleToString(marketState.bbLower, 2),
              " | Width: ", DoubleToString(marketState.bbUpper - marketState.bbLower, 2));
        
        // Show price levels
        Print("[PRICE] Bid: ", DoubleToString(marketState.bid, 2),
              " | Ask: ", DoubleToString(marketState.ask, 2),
              " | Close[0]: ", DoubleToString(iClose(_Symbol, _Period, 0), 2));
    }
    
    //--- 7. Calculate consensus
    ENUM_SIGNAL consensus = g_signalManager.GetConsensusSignal(signals, 8);
    double consensusStrength = g_signalManager.GetConsensusStrength();
    double agreementPct = g_signalManager.GetAgreementPercentage();
    const int buyVotes = g_signalManager.GetBuyCount();
    const int sellVotes = g_signalManager.GetSellCount();
    
    if(consensus != SIGNAL_NONE && !h2Diag) {
        PrintFormat("[CONSENSUS] %s detected! Strength: %.2f", EnumToString(consensus), consensusStrength);
    }
    
    //--- 8. Consensus / quality / execution gate
    if(consensus == SIGNAL_NONE) {
        Aurum_LogH2RejectIfChanged(currentBarTime, SIGNAL_REJECT_NO_CONSENSUS, SIGNAL_NONE, 0.0, buyVotes, sellVotes);
    } else {
        double qualityScore = g_qualityFilter.CalculateSetupScore(marketState, consensus,
                                                                  consensusStrength, agreementPct);
        if(!h2Diag) {
            PrintFormat("[QUALITY] Score: %.1f/100 (Min: %d)", qualityScore, InpMinQualityScore);
        }
        
        if(qualityScore < InpMinQualityScore) {
            Aurum_LogH2RejectIfChanged(currentBarTime, SIGNAL_REJECT_QUALITY_LOW, consensus, qualityScore, buyVotes, sellVotes);
        } else {
            ENUM_SIGNAL_REJECT_REASON reqFail = SIGNAL_REJECT_NONE;
            if(!CheckQualityRequirements(marketState, consensus, reqFail)) {
                Aurum_LogH2RejectIfChanged(currentBarTime, reqFail, consensus, qualityScore, buyVotes, sellVotes);
                if(!h2Diag) {
                    PrintFormat("[BLOCKED] Quality requirements not met (%s)", Aurum_RejectReasonText(reqFail));
                }
            } else {
                ENUM_SIGNAL_REJECT_REASON posFail = SIGNAL_REJECT_NONE;
                if(!CanOpenNewPosition(posFail)) {
                    Aurum_LogH2RejectIfChanged(currentBarTime, posFail, consensus, qualityScore, buyVotes, sellVotes);
                    if(!h2Diag) {
                        if(posFail == SIGNAL_REJECT_MAX_POSITIONS)
                            Print("[BLOCKED] Max positions reached");
                        else
                            Print("[BLOCKED] Max consecutive losses reached");
                    }
                } else {
                    if(!h2Diag) {
                        Print("[TRADE] *** EXECUTING TRADE ***");
                    }
                    ExecuteTrade(consensus, marketState, qualityScore);
                }
            }
        }
    }
    
    //--- 9. Manage existing positions (trailing stops, etc)
    ManageOpenPositions();
    
    //--- 10. Update info panel
    UpdatePanel();
    
    } while(false);
    
    s_inOnTick = false;
}

//+------------------------------------------------------------------+
//| Validate input parameters                                        |
//+------------------------------------------------------------------+
bool ValidateInputs() {
    bool valid = true;
    
    //--- Validate risk parameters
    if(InpMaxRiskPerTrade <= 0 || InpMaxRiskPerTrade > 10) {
        Print("ERROR: Invalid max risk per trade (must be 0.1-10%): ", InpMaxRiskPerTrade);
        valid = false;
    }
    
    if(InpMaxDailyLossPct <= 0 || InpMaxDailyLossPct > 20) {
        Print("ERROR: Invalid max daily loss (must be 1-20%): ", InpMaxDailyLossPct);
        valid = false;
    }
    
    if(InpMaxEquityDD <= 0 || InpMaxEquityDD > 50) {
        Print("ERROR: Invalid max equity DD (must be 5-50%): ", InpMaxEquityDD);
        valid = false;
    }
    
    //--- Validate lot sizing
    if(InpLotMethod == LOT_FIXED && InpFixedLot <= 0) {
        Print("ERROR: Invalid fixed lot size: ", InpFixedLot);
        valid = false;
    }
    
    if(InpLotMethod == LOT_AUTO && InpRiskPercent <= 0) {
        Print("ERROR: Invalid risk percent: ", InpRiskPercent);
        valid = false;
    }
    
    //--- Validate quality score
    if(InpMinQualityScore < 30 || InpMinQualityScore > 90) {
        Print("ERROR: Invalid min quality score (must be 30-90): ", InpMinQualityScore);
        valid = false;
    }
    
    //--- Validate consensus
    if(InpMinConsensus < 1 || InpMinConsensus > 8) {
        Print("ERROR: Invalid min consensus (must be 1-8): ", InpMinConsensus);
        valid = false;
    }
    
    //--- Validate spread
    if(InpMaxSpreadPoints <= 0 || InpMaxSpreadPoints > 100) {
        Print("ERROR: Invalid max spread (must be 10-100): ", InpMaxSpreadPoints);
        valid = false;
    }
    
    //--- Check at least one strategy enabled
    if(!InpUseTrendFollowing && !InpUseBreakout && !InpUseMeanReversion &&
       !InpUseSupplyDemand && !InpUseSmartMoney && !InpUsePriceAction &&
       !InpUseGridRecovery && !InpUseMomentumScalp) {
        Print("ERROR: At least one strategy must be enabled");
        valid = false;
    }
    
    return valid;
}

//+------------------------------------------------------------------+
//| Check if current time allowed for trading                        |
//+------------------------------------------------------------------+
bool IsTimeAllowed() {
    if(!InpUseTimeFilter) return true;
    
    MqlDateTime dt;
    TimeCurrent(dt);
    
    //--- Check day of week
    bool dayAllowed = false;
    switch(dt.day_of_week) {
        case 1: dayAllowed = InpTradeMon; break;
        case 2: dayAllowed = InpTradeTue; break;
        case 3: dayAllowed = InpTradeWed; break;
        case 4: dayAllowed = InpTradeThu; break;
        case 5: dayAllowed = InpTradeFri; break;
        default: dayAllowed = false;
    }
    
    if(!dayAllowed) return false;
    
    //--- Check hour range
    if(dt.hour < InpHourFrom || dt.hour > InpHourTo) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check additional quality requirements                            |
//+------------------------------------------------------------------+
bool CheckQualityRequirements(const MarketState &state, const ENUM_SIGNAL signal, ENUM_SIGNAL_REJECT_REASON &outReason) {
    outReason = SIGNAL_REJECT_NONE;
    //--- Check trend alignment if required
    if(InpRequireTrendAlignment) {
        if(signal == SIGNAL_BUY && state.trendDir != TREND_UP) {
            outReason = SIGNAL_REJECT_REQUIRE_TREND;
            return false;
        }
        if(signal == SIGNAL_SELL && state.trendDir != TREND_DOWN) {
            outReason = SIGNAL_REJECT_REQUIRE_TREND;
            return false;
        }
    }
    
    //--- Check key level proximity if required
    if(InpRequireKeyLevel) {
        double price = (signal == SIGNAL_BUY) ? state.bid : state.ask;
        double supportDist = MathAbs(price - state.nearestSupport);
        double resistDist = MathAbs(price - state.nearestResistance);
        double minDist = MathMin(supportDist, resistDist);
        
        //--- Require within 50 pips
        if(minDist > 500 * _Point) {
            outReason = SIGNAL_REJECT_REQUIRE_KEYLEVEL;
            return false;
        }
    }
    
    //--- Check momentum if required
    if(InpRequireMomentum) {
        if(signal == SIGNAL_BUY && state.rsi14 < 50) {
            outReason = SIGNAL_REJECT_REQUIRE_MOMENTUM;
            return false;
        }
        if(signal == SIGNAL_SELL && state.rsi14 > 50) {
            outReason = SIGNAL_REJECT_REQUIRE_MOMENTUM;
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if we can open new position                                |
//+------------------------------------------------------------------+
bool CanOpenNewPosition(ENUM_SIGNAL_REJECT_REASON &rejectOut) {
    rejectOut = SIGNAL_REJECT_NONE;
    //--- Check max open positions
    int openCount = g_tradeManager.CountOpenPositions();
    if(openCount >= InpMaxOpenPositions) {
        Logger::Warning("Max open positions reached: " + IntegerToString(openCount));
        rejectOut = SIGNAL_REJECT_MAX_POSITIONS;
        return false;
    }
    
    //--- Check consecutive losses
    if(g_riskManager.GetConsecutiveLosses() >= InpMaxConsecutiveLosses) {
        Logger::Warning("Max consecutive losses reached");
        rejectOut = SIGNAL_REJECT_MAX_CONSEC_LOSSES;
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Execute trade                                                    |
//+------------------------------------------------------------------+
void ExecuteTrade(ENUM_SIGNAL signal, const MarketState &state, double qualityScore) {
    //--- Reentrancy guard: prevent nested trade execution (safety vs callback/event loops)
    static bool s_inExecuteTrade = false;
    if(s_inExecuteTrade) {
        Print("[GUARD] ExecuteTrade re-entry blocked");
        return;
    }
    s_inExecuteTrade = true;
    #define EXEC_TRADE_DONE() { s_inExecuteTrade = false; }

    Print("======== EXECUTING TRADE ========");
    Print("Signal: ", EnumToString(signal), " | Quality: ", qualityScore);
    
    //--- Calculate lot size
    double lot = g_moneyManager.CalculateLotSize(
        InpLotMethod,
        InpRiskPercent,
        InpFixedLot,
        0.01,  // Fixed per balance (simplified)
        InpMaxRiskPerTrade,
        InpSLPoints
    );
    
    if(lot <= 0) {
        Logger::Error("Invalid lot size calculated: " + DoubleToString(lot, 2));
        EXEC_TRADE_DONE();
        return;
    }
    
    //--- Calculate SL/TP
    double point = _Point;
    double tick = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    int stopLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    
    Print("[SYMBOL INFO] Point: ", point, " | Tick: ", tick, " | Digits: ", digits, " | StopLevel: ", stopLevel);
    Print("[INPUT PARAMS] InpSLPoints: ", InpSLPoints, " | InpTPCoefficient: ", InpTPCoefficient);
    
    double price = (signal == SIGNAL_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : 
                                             SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    double sl = 0, tp = 0;
    double slDistance = InpSLPoints * point;
    double tpDistance = slDistance * InpTPCoefficient;
    
    Print("[CALCULATED] slDistance: ", slDistance, " | tpDistance: ", tpDistance);
    
    // Ensure minimum stop level is respected
    double minDistance = stopLevel * point;
    
    // CRITICAL FIX: For XAUUSD in Strategy Tester, enforce WIDE minimum distances
    // Real ticks show high volatility - need wider stops to avoid immediate SL hits
    if(StringFind(_Symbol, "XAUUSD") >= 0 || StringFind(_Symbol, "GOLD") >= 0) {
        double minGoldSL = 50.0;   // $50 minimum for SL (increased from $20)
        double minGoldTP = 100.0;  // $100 minimum for TP (must be > SL, 2:1 R:R)
        
        if(minDistance < minGoldSL) {
            minDistance = minGoldSL;
            Print("[GOLD OVERRIDE] Enforcing minimum SL distance: ", minGoldSL);
        }
        
        // Adjust SL distance
        if(slDistance < minDistance) {
            Print("[WARNING] SL distance too small, adjusting from ", slDistance, " to ", minDistance);
            slDistance = minDistance;
        }
        
        // Adjust TP distance separately (must be larger than SL)
        if(tpDistance < minGoldTP) {
            Print("[WARNING] TP distance too small, adjusting from ", tpDistance, " to ", minGoldTP);
            tpDistance = minGoldTP;
        }
    } else {
        // For other symbols, use standard validation
        Print("[MIN DISTANCE] stopLevel * point = ", stopLevel, " * ", point, " = ", minDistance);
        
        if(slDistance < minDistance) {
            Print("[WARNING] SL distance too small, adjusting from ", slDistance, " to ", minDistance);
            slDistance = minDistance;
        }
        if(tpDistance < minDistance) {
            Print("[WARNING] TP distance too small, adjusting from ", tpDistance, " to ", minDistance);
            tpDistance = minDistance;
        }
    }
    
    Print("[FINAL DISTANCES] SL: ", slDistance, " | TP: ", tpDistance);
    
    if(signal == SIGNAL_BUY) {
        sl = NormalizeDouble(price - slDistance, (int)digits);
        tp = NormalizeDouble(price + tpDistance, (int)digits);
    } else {
        sl = NormalizeDouble(price + slDistance, (int)digits);
        tp = NormalizeDouble(price - tpDistance, (int)digits);
    }
    
    Print("[NORMALIZED] SL: ", sl, " | TP: ", tp);
    
    // Validate SL/TP are not zero and in correct direction
    if(signal == SIGNAL_BUY) {
        if(sl >= price || tp <= price) {
            Print("ERROR: Invalid SL/TP for BUY - SL: ", sl, " Price: ", price, " TP: ", tp);
            EXEC_TRADE_DONE();
            return;
        }
    } else {
        if(sl <= price || tp >= price) {
            Print("ERROR: Invalid SL/TP for SELL - SL: ", sl, " Price: ", price, " TP: ", tp);
            EXEC_TRADE_DONE();
            return;
        }
    }
    
    Print("[TRADE PARAMS] ", EnumToString(signal), " | Price: ", price, " | SL: ", sl, " | TP: ", tp, " | Lot: ", lot);
    
    //--- Execute order
    ulong ticket = 0;
    
    if(signal == SIGNAL_BUY) {
        ticket = g_tradeManager.OpenBuy(lot, sl, tp, (int)qualityScore, 
                                        "AS2.0_Q" + IntegerToString((int)qualityScore));
    } else {
        ticket = g_tradeManager.OpenSell(lot, sl, tp, (int)qualityScore,
                                         "AS2.0_Q" + IntegerToString((int)qualityScore));
    }
    
    //--- Handle result
    if(ticket > 0) {
        g_totalTrades++;
        g_riskManager.OnTradeOpened(lot);
        
        Logger::LogTrade(ticket, "OPEN_" + EnumToString(signal), lot, price, sl, tp, (int)qualityScore);
        Logger::Info("Trade #" + IntegerToString(g_totalTrades) + " opened successfully");
    } else {
        Logger::Error("Trade execution failed");
    }
    
    EXEC_TRADE_DONE();
#undef EXEC_TRADE_DONE
}

//+------------------------------------------------------------------+
//| Manage open positions (trailing stops, etc)                      |
//+------------------------------------------------------------------+
void ManageOpenPositions() {
    if(g_tradeManager == NULL) return;
    
    //--- Update trailing stops
    if(InpUseTrailing) {
        g_tradeManager.ManagePositions(true, InpTrailStartPips, InpTrailDistPips);
    }
}

//+------------------------------------------------------------------+
//| Update info panel                                                |
//+------------------------------------------------------------------+
void UpdatePanel() {
    if(!InpShowPanel || g_infoPanel == NULL) return;
    
    //--- Get current market state
    MarketState state = g_marketAnalyzer.GetState();
    
    //--- Get strategy active states
    bool strategyActive[8];
    for(int i = 0; i < 8; i++) {
        strategyActive[i] = g_strategyManager.IsStrategyActive(i);
    }
    
    //--- Get latest consensus
    SignalResult signals[8];
    g_strategyManager.GetAllSignals(signals);
    ENUM_SIGNAL consensus = g_signalManager.GetConsensusSignal(signals, 8);
    double consensusStrength = g_signalManager.GetConsensusStrength();
    double agreementPct = g_signalManager.GetAgreementPercentage();
    
    //--- Calculate quality for display (if signal present)
    double qualityScore = 0;
    if(consensus != SIGNAL_NONE) {
        qualityScore = g_qualityFilter.CalculateSetupScore(state, consensus, consensusStrength, agreementPct);
    }
    
    //--- Get risk info
    double dailyPnL = g_riskManager.GetDailyPnL();
    double equityDD = g_riskManager.GetEquityDD();
    int consecutiveLosses = g_riskManager.GetConsecutiveLosses();
    
    //--- Update panel
    g_infoPanel.Update(
        state,
        strategyActive,
        8,
        consensus,
        consensusStrength,
        agreementPct,
        (int)qualityScore,
        dailyPnL,
        equityDD,
        consecutiveLosses
    );
}

//+------------------------------------------------------------------+
//| Log configuration                                                |
//+------------------------------------------------------------------+
void LogConfiguration() {
    Logger::Info("--- CONFIGURATION ---");
    Logger::Info("Lot Method: " + EnumToString(InpLotMethod));
    Logger::Info("Fixed Lot: " + DoubleToString(InpFixedLot, 2));
    Logger::Info("Risk %: " + DoubleToString(InpRiskPercent, 1));
    Logger::Info("Max Risk/Trade: " + DoubleToString(InpMaxRiskPerTrade, 1) + "%");
    Logger::Info("Max Daily Loss: " + DoubleToString(InpMaxDailyLossPct, 1) + "%");
    Logger::Info("Max Equity DD: " + DoubleToString(InpMaxEquityDD, 1) + "%");
    Logger::Info("Max Consecutive Losses: " + IntegerToString(InpMaxConsecutiveLosses));
    Logger::Info("Min Quality Score: " + IntegerToString(InpMinQualityScore));
    Logger::Info("Max Spread: " + IntegerToString(InpMaxSpreadPoints) + " points");
    Logger::Info("--- STRATEGIES ENABLED ---");
    Logger::Info("TrendFollowing: " + (InpUseTrendFollowing ? "YES" : "NO"));
    Logger::Info("Breakout: " + (InpUseBreakout ? "YES" : "NO"));
    Logger::Info("MeanReversion: " + (InpUseMeanReversion ? "YES" : "NO"));
    Logger::Info("SupplyDemand: " + (InpUseSupplyDemand ? "YES" : "NO"));
    Logger::Info("SmartMoney: " + (InpUseSmartMoney ? "YES" : "NO"));
    Logger::Info("PriceAction: " + (InpUsePriceAction ? "YES" : "NO"));
    Logger::Info("GridRecovery: " + (InpUseGridRecovery ? "YES" : "NO"));
    Logger::Info("MomentumScalp: " + (InpUseMomentumScalp ? "YES" : "NO"));
    Logger::Info("H2 Jul-Dec diagnostic PrintFormat: " + (InpDiagH2JulDec ? "ON" : "OFF"));
    Logger::Info("--- CONFIGURATION END ---");
}

//+------------------------------------------------------------------+
//| Cleanup all objects                                              |
//+------------------------------------------------------------------+
void Cleanup() {
    if(g_infoPanel != NULL) { delete g_infoPanel; g_infoPanel = NULL; }
    if(g_tradeManager != NULL) { delete g_tradeManager; g_tradeManager = NULL; }
    if(g_riskManager != NULL) { delete g_riskManager; g_riskManager = NULL; }
    if(g_moneyManager != NULL) { delete g_moneyManager; g_moneyManager = NULL; }
    if(g_qualityFilter != NULL) { delete g_qualityFilter; g_qualityFilter = NULL; }
    if(g_signalManager != NULL) { delete g_signalManager; g_signalManager = NULL; }
    if(g_strategyManager != NULL) { delete g_strategyManager; g_strategyManager = NULL; }
    if(g_marketAnalyzer != NULL) { delete g_marketAnalyzer; g_marketAnalyzer = NULL; }
    
    g_initialized = false;
}

//+------------------------------------------------------------------+
//| END OF AURUM SYNAPSE v2.0                                        |
//+------------------------------------------------------------------+
