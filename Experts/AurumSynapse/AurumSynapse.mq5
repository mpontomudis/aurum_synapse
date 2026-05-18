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

//=== Telemetry (compile-time; default OFF). TEST C: A=both off | B=T1 only | C=T1+T2. Enabling T2 without T1 fails compile (TelemetryConfig.mqh). ===
#define AURUM_TELEMETRY_T1
#define AURUM_TELEMETRY_T2

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
#include "Core/TradeDiag.mqh"
#include "TelemetryAnalytics/GovernanceRuntimeStrategyTaggingV1/GovernanceRuntimeStrategyTaggingV1.mqh"
#include "TelemetryAnalytics/GovernanceSignalForensicsV1/GovernanceSignalForensicsV1.mqh"
#include "TelemetryAnalytics/GovernanceRegimeEngineV1/GovernanceRegimeIntegrationV1.mqh"
#ifdef AURUM_TELEMETRY_T1
#include "Telemetry/TelemetryCollector.mqh"
#endif
#ifdef AURUM_TELEMETRY_T2
#include "Telemetry/TelemetryPersistence.mqh"
#endif

// GOV_RUNTIME_INJECTION_CANDIDATE — optional future: shadow queue init / feature flags (no wiring in this baseline).

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+

//--- General Settings
input group "=== GENERAL SETTINGS ==="
input ENUM_LOT_METHOD InpLotMethod = LOT_FIXED;           // Lot Sizing Method
input double InpFixedLot = 0.01;                          // Fixed Lot Size
input double InpRiskPercent = 1.0;                        // Risk % per Trade (Auto mode)
input double InpBalanceStep = 500.0;                      // Fixed per Balance: balance step ($)
input double InpBaseLotPerStep = 0.01;                    // Fixed per Balance: lot per step
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
//--- Phase 3D research: observability vs execution (tester / lab only — default OFF)
input bool InpInvestigationSignalObservability = false;   // If true: EvaluateAll even when RiskManager halts; NEVER opens/modifies trades while halted
input bool InpGovRuntimeTagAppendComment = false;          // Append governance runtime tag to order comment (MT5-safe truncation)

input group "=== GOVERNANCE RUNTIME OBSERVABILITY ==="
input bool InpGovRuntimeObsJournal = true;                   // Print governance report to Journal on stop (OnDeinit / OnTester)
input bool InpGovRuntimeObsFile = false;                     // Also write report to file (MQL5/Files relative path)
input string InpGovRuntimeObsFilePath = "governance_runtime_obs.txt";
input bool InpGovRuntimeObsOnTester = true;                   // Emit report from OnTester()

input group "=== GOVERNANCE VISUAL HTML (PHASE 20A) ==="
input bool InpGovVisualHtmlExport = true;                     // Write governance_report_*.html on stop (OnDeinit live / OnTester)
input bool InpGovVisualSidecars = false;                      // Optional .css / .js / .json next to HTML
input bool InpGovVisualHtmlOnTester = true;                   // Emit HTML from OnTester() when in Strategy Tester

input group "=== GOVERNANCE BACKTEST DOSSIER (PHASE 20B) ==="
input string InpGovDossierGitCommit = "";                    // Optional git SHA / build id for dossier metadata
input int InpGovDossierBuildNumber = 0;                       // Optional CI build number
input bool InpGovDossierCompareExport = false;                // Also write *_governance_report_compare.html stub
input bool InpGovRegimeCsvAppend = false;                     // Append regime telemetry rows to CSV (tester / explicit)

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
//| Map ENUM_SIGNAL_REJECT_REASON → TradeDiag Reason= token (Journal)|
//+------------------------------------------------------------------+
string Aurum_RejectReasonToTradeDiagBlocked(const ENUM_SIGNAL_REJECT_REASON reason) {
    switch(reason) {
        case SIGNAL_REJECT_NO_CONSENSUS:         return "NoConsensus";
        case SIGNAL_REJECT_QUALITY_LOW:          return "QualityScoreLow";
        case SIGNAL_REJECT_REQUIRE_TREND:        return "RequireTrendAlignment";
        case SIGNAL_REJECT_REQUIRE_KEYLEVEL:     return "RequireKeyLevel";
        case SIGNAL_REJECT_REQUIRE_MOMENTUM:     return "RequireMomentum";
        case SIGNAL_REJECT_MAX_POSITIONS:        return "MaxOpenPositions";
        case SIGNAL_REJECT_MAX_CONSEC_LOSSES:    return "MaxConsecutiveLosses";
        case SIGNAL_REJECT_RISK_HALT:            return "RiskManager";
        case SIGNAL_REJECT_TIME_FILTER:          return "TradingHoursFilter";
        case SIGNAL_REJECT_SPREAD:               return "SpreadTooHigh";
        case SIGNAL_REJECT_MARKET_UPDATE_FAIL:   return "MarketUpdateFail";
        default:                                 return "SignalRejected";
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
//| PHASE 20B — dossier reproducibility snapshot (cold path only)    |
//+------------------------------------------------------------------+
string Aurum_FmtDossierInputSnapshotV1(void) {
    string o = "";
    o += "InpLotMethod=" + EnumToString(InpLotMethod) + "\n";
    o += "InpFixedLot=" + DoubleToString(InpFixedLot, 4) + "\n";
    o += "InpRiskPercent=" + DoubleToString(InpRiskPercent, 2) + "\n";
    o += "InpBalanceStep=" + DoubleToString(InpBalanceStep, 2) + "\n";
    o += "InpBaseLotPerStep=" + DoubleToString(InpBaseLotPerStep, 4) + "\n";
    o += "InpMagicNumber=" + IntegerToString(InpMagicNumber) + "\n";
    o += "InpMaxSpreadPoints=" + IntegerToString(InpMaxSpreadPoints) + "\n";
    o += "InpUseTrendFollowing=" + IntegerToString((int)InpUseTrendFollowing) + "\n";
    o += "InpUseBreakout=" + IntegerToString((int)InpUseBreakout) + "\n";
    o += "InpUseMeanReversion=" + IntegerToString((int)InpUseMeanReversion) + "\n";
    o += "InpUseSupplyDemand=" + IntegerToString((int)InpUseSupplyDemand) + "\n";
    o += "InpUseSmartMoney=" + IntegerToString((int)InpUseSmartMoney) + "\n";
    o += "InpUsePriceAction=" + IntegerToString((int)InpUsePriceAction) + "\n";
    o += "InpUseGridRecovery=" + IntegerToString((int)InpUseGridRecovery) + "\n";
    o += "InpUseMomentumScalp=" + IntegerToString((int)InpUseMomentumScalp) + "\n";
    o += "InpMaxRiskPerTrade=" + DoubleToString(InpMaxRiskPerTrade, 2) + "\n";
    o += "InpMaxDailyLossPct=" + DoubleToString(InpMaxDailyLossPct, 2) + "\n";
    o += "InpMaxEquityDD=" + DoubleToString(InpMaxEquityDD, 2) + "\n";
    o += "InpMaxConsecutiveLosses=" + IntegerToString(InpMaxConsecutiveLosses) + "\n";
    o += "InpMaxOpenPositions=" + IntegerToString(InpMaxOpenPositions) + "\n";
    o += "InpUseTimeFilter=" + IntegerToString((int)InpUseTimeFilter) + "\n";
    o += "InpHourFrom=" + IntegerToString(InpHourFrom) + "\n";
    o += "InpHourTo=" + IntegerToString(InpHourTo) + "\n";
    o += "InpTradeMon=" + IntegerToString((int)InpTradeMon) + "\n";
    o += "InpTradeTue=" + IntegerToString((int)InpTradeTue) + "\n";
    o += "InpTradeWed=" + IntegerToString((int)InpTradeWed) + "\n";
    o += "InpTradeThu=" + IntegerToString((int)InpTradeThu) + "\n";
    o += "InpTradeFri=" + IntegerToString((int)InpTradeFri) + "\n";
    o += "InpMinQualityScore=" + IntegerToString(InpMinQualityScore) + "\n";
    o += "InpRequireTrendAlignment=" + IntegerToString((int)InpRequireTrendAlignment) + "\n";
    o += "InpRequireKeyLevel=" + IntegerToString((int)InpRequireKeyLevel) + "\n";
    o += "InpRequireMomentum=" + IntegerToString((int)InpRequireMomentum) + "\n";
    o += "InpMinConsensus=" + IntegerToString(InpMinConsensus) + "\n";
    o += "InpTPCoefficient=" + DoubleToString(InpTPCoefficient, 2) + "\n";
    o += "InpSLPoints=" + DoubleToString(InpSLPoints, 1) + "\n";
    o += "InpUseTrailing=" + IntegerToString((int)InpUseTrailing) + "\n";
    o += "InpTrailStartPips=" + DoubleToString(InpTrailStartPips, 1) + "\n";
    o += "InpTrailDistPips=" + DoubleToString(InpTrailDistPips, 1) + "\n";
    o += "InpShowPanel=" + IntegerToString((int)InpShowPanel) + "\n";
    o += "InpPanelUpdateSeconds=" + IntegerToString(InpPanelUpdateSeconds) + "\n";
    o += "InpDiagH2JulDec=" + IntegerToString((int)InpDiagH2JulDec) + "\n";
    o += "InpInvestigationSignalObservability=" + IntegerToString((int)InpInvestigationSignalObservability) + "\n";
    o += "InpGovRuntimeTagAppendComment=" + IntegerToString((int)InpGovRuntimeTagAppendComment) + "\n";
    o += "InpGovRuntimeObsJournal=" + IntegerToString((int)InpGovRuntimeObsJournal) + "\n";
    o += "InpGovRuntimeObsFile=" + IntegerToString((int)InpGovRuntimeObsFile) + "\n";
    o += "InpGovRuntimeObsFilePath=" + InpGovRuntimeObsFilePath + "\n";
    o += "InpGovRuntimeObsOnTester=" + IntegerToString((int)InpGovRuntimeObsOnTester) + "\n";
    o += "InpGovVisualHtmlExport=" + IntegerToString((int)InpGovVisualHtmlExport) + "\n";
    o += "InpGovVisualSidecars=" + IntegerToString((int)InpGovVisualSidecars) + "\n";
    o += "InpGovVisualHtmlOnTester=" + IntegerToString((int)InpGovVisualHtmlOnTester) + "\n";
    o += "InpGovDossierGitCommit=" + InpGovDossierGitCommit + "\n";
    o += "InpGovDossierBuildNumber=" + IntegerToString(InpGovDossierBuildNumber) + "\n";
    o += "InpGovDossierCompareExport=" + IntegerToString((int)InpGovDossierCompareExport) + "\n";
    return o;
}

void Aurum_FillDossierColdSnapshotV1(void) {
    g_gov_dossier_git_commit_v1 = (StringLen(InpGovDossierGitCommit) > 0) ? InpGovDossierGitCommit : "unset";
    g_gov_dossier_build_number_v1 = InpGovDossierBuildNumber;
    g_gov_dossier_strat_en_v1[0] = InpUseTrendFollowing;
    g_gov_dossier_strat_en_v1[1] = InpUseBreakout;
    g_gov_dossier_strat_en_v1[2] = InpUseMeanReversion;
    g_gov_dossier_strat_en_v1[3] = InpUseSupplyDemand;
    g_gov_dossier_strat_en_v1[4] = InpUseSmartMoney;
    g_gov_dossier_strat_en_v1[5] = InpUsePriceAction;
    g_gov_dossier_strat_en_v1[6] = InpUseGridRecovery;
    g_gov_dossier_strat_en_v1[7] = InpUseMomentumScalp;
    g_gov_dossier_risk_v1.max_risk_per_trade = InpMaxRiskPerTrade;
    g_gov_dossier_risk_v1.max_daily_loss_pct = InpMaxDailyLossPct;
    g_gov_dossier_risk_v1.max_equity_dd_pct = InpMaxEquityDD;
    g_gov_dossier_risk_v1.max_consecutive_losses = InpMaxConsecutiveLosses;
    g_gov_dossier_risk_v1.max_open_positions = InpMaxOpenPositions;
    g_gov_backtest_input_kv_v1 = Aurum_FmtDossierInputSnapshotV1();
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    // GOV_COLD_PATH_ONLY — OnInit may host shadow queue allocation / file-common paths; never in OnTick hot path.
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

    GovRunTagIntV1_ModuleInit();
    GovRuntimeObsIntV1_ModuleInit();
    GovRuntimeVisualIntV1_ModuleInit();
    GovSigForensicsV1_ModuleInit();
    GovRegimeIntV1_ModuleInit();
    GovRuntimeObsIntV1_Configure(InpGovRuntimeObsJournal, InpGovRuntimeObsFile, InpGovRuntimeObsFilePath,
                                 GOV_RUNTIME_OBS_FLAG_INCLUDE_RAW);
    
    //--- Phase 3D: observability mode is tester-only (never on live charts)
    if(InpInvestigationSignalObservability && !MQLInfoInteger(MQL_TESTER)) {
        Print("ERROR: InpInvestigationSignalObservability is allowed only in the Strategy Tester");
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
    //--- Must match Inputs tab: Init() alone used Constants.mqh (e.g. consec=3) — caused misleading backtests vs UI
    g_riskManager.SetRiskLimitsFromInputs(InpMaxEquityDD, InpMaxConsecutiveLosses, InpMaxDailyLossPct);
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
                          InpMagicNumber, InpMinQualityScore, InpMaxOpenPositions,
                          InpBalanceStep, InpBaseLotPerStep);
    
    Logger::Info("InfoPanel initialized - Update: " + IntegerToString(InpPanelUpdateSeconds) + "s");
    
    //--- Hide panel if disabled
    if(!InpShowPanel) {
        g_infoPanel.Hide();
    }
    
    //--- Log configuration
    LogConfiguration();
    
    if(InpInvestigationSignalObservability) {
        Print("*** Phase 3D: InpInvestigationSignalObservability=TRUE — EvaluateAll runs when risk halts; no ExecuteTrade / no ManageOpenPositions while halted (tester only). ***");
        Logger::Warning("Phase 3D investigation mode: signal observability separated from execution");
    }
    
    //--- Success
    g_initialized = true;

    // GOV_RUNTIME_INJECTION_CANDIDATE — post-init shadow lane hooks (must remain non-blocking; default OFF).
    
    //--- Initialize last bar time to prevent immediate processing on first tick
    g_lastBarTime = iTime(_Symbol, _Period, 0);
    
    Print("\n========================================");
    Print("  AURUM SYNAPSE v2.0 READY");
    Print("  All components initialized successfully");
    Print("========================================\n");
    
    Logger::Info("========================================");
    Logger::Info("  INITIALIZATION COMPLETE - READY TO TRADE");
    Logger::Info("========================================");
#ifdef AURUM_TELEMETRY_T2
    // GOV_COLD_PATH_ONLY — timer-based persistence drain; safe for deferred governance drain patterns.
    TelemetryT2_Init();
    if(TelemetryT2_IsReady())
        EventSetTimer(TELEMETRY_T2_TIMER_MS);
#endif
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
#ifdef AURUM_TELEMETRY_T2
    EventKillTimer();
    TelemetryT2_Deinit();
#endif
    GovRuntimeObsIntV1_EmitEndOfRun(_Symbol, reason);
    if(InpGovVisualHtmlExport && MQLInfoInteger(MQL_TESTER) == 0) {
        Aurum_FillDossierColdSnapshotV1();
        GovRuntimeVisualIntV1_ExportGovernanceReportV1(_Symbol, _Period, InpGovVisualSidecars, InpGovDossierCompareExport);
    }
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
    // GOV_RUNTIME_INJECTION_CANDIDATE — tick entry: any shadow work must respect new-bar gate + reentrancy guard.
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

    // GOV_SHADOW_SAFE_POINT — bar-open boundary: cheapest place for per-bar shadow snapshot (no I/O).
    
    const int diagOpenCount = (g_tradeManager != NULL ? g_tradeManager.CountOpenPositions() : -1);
    
    const bool h2Diag = Aurum_IsH2DiagnosticMonth(currentBarTime);
    
    //--- DIAGNOSTIC: Log every 10 bars (reduced from every tick to prevent stack issues)
    if(!h2Diag && (g_totalTrades <= 3 || g_totalTrades % 10 == 0)) {
        PrintFormat("[BAR #%d] Processing new bar @ %s", g_totalTrades, TimeToString(currentBarTime, TIME_DATE | TIME_MINUTES));
    }
    
    //--- 1. Risk authorization (execution) — observability may continue in Phase 3D lab mode
    const bool execRiskAllows = g_riskManager.CanTrade();
    // GOV_RUNTIME_INJECTION_CANDIDATE — align native CanTrade() with shadow execution_allowed (observe-only v1).
    if(!execRiskAllows) {
        Aurum_LogH2GateOncePerDay(currentBarTime, SIGNAL_REJECT_RISK_HALT);
        TradeDiag_Blocked("RiskManager", _Symbol, 0.0, diagOpenCount);
        if(!h2Diag && g_totalTrades <= 3) {
            string msg = "[BLOCKED] Risk Manager - " + g_riskManager.GetHaltReason();
            Print(msg);
        }
        if(!InpInvestigationSignalObservability) {
            GovSigForensicsV1_NotifyEarlyReject(currentBarTime, REGIME_CALM, SIGNAL_REJECT_RISK_HALT, true);
            UpdatePanel();
            break;
        }
        // Phase 3D: fall through to market update + EvaluateAll; execution gated below
    }
    
    //--- 2. Check time filter
    if(!IsTimeAllowed()) {
        Aurum_LogH2GateOncePerDay(currentBarTime, SIGNAL_REJECT_TIME_FILTER);
        TradeDiag_Blocked("TradingHoursFilter", _Symbol, 0.0, diagOpenCount);
        if(!h2Diag && g_totalTrades <= 3) {
            Print("[BLOCKED] Time Filter");
        }
        GovSigForensicsV1_NotifyEarlyReject(currentBarTime, REGIME_CALM, SIGNAL_REJECT_TIME_FILTER, true);
        UpdatePanel();
        break;
    }
    
    //--- 3. Check spread filter
    double spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
    if(spread > InpMaxSpreadPoints) {
        Aurum_LogH2GateOncePerDay(currentBarTime, SIGNAL_REJECT_SPREAD);
        TradeDiag_Blocked("SpreadTooHigh", _Symbol, 0.0, diagOpenCount);
        if(!h2Diag && g_totalTrades <= 3) {
            PrintFormat("[BLOCKED] Spread too wide: %.1f > %d", spread, InpMaxSpreadPoints);
        }
        GovSigForensicsV1_NotifyEarlyReject(currentBarTime, REGIME_CALM, SIGNAL_REJECT_SPREAD, true);
        UpdatePanel();
        break;
    }
    
    //--- 4. Update market analysis
    if(!g_marketAnalyzer.Update()) {
        Aurum_LogH2GateOncePerDay(currentBarTime, SIGNAL_REJECT_MARKET_UPDATE_FAIL);
        TradeDiag_Blocked("MarketUpdateFail", _Symbol, 0.0, diagOpenCount);
        Logger::Warning("[ERROR] MarketAnalyzer update failed");
        GovSigForensicsV1_NotifyEarlyReject(currentBarTime, REGIME_CALM, SIGNAL_REJECT_MARKET_UPDATE_FAIL, true);
        break;
    }
    
    MarketState marketState = g_marketAnalyzer.GetState();
    MqlRates gov_reg_rates[];
    ArraySetAsSeries(gov_reg_rates, true);
    const int gov_reg_n = CopyRates(_Symbol, _Period, 0, 96, gov_reg_rates);
    const double gov_reg_spread_pts = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
    GovRegimeIntV1_OnBar(marketState, gov_reg_rates, gov_reg_n, currentBarTime, gov_reg_spread_pts,
                        (InpGovRegimeCsvAppend && MQLInfoInteger(MQL_TESTER) != 0));
    GovRegimeIntV1_ApplyLegacyOverlay(marketState);
    Aurum_LogH2MarketStateIfChanged(marketState, currentBarTime);

    GovSigForensicsV1_NotifyPipelineOpen(currentBarTime);
    GovRegimeIntV1_OnPipelineSignal(currentBarTime);

    // GOV_SHADOW_SAFE_POINT — pre-signal: regime / state available for lightweight shadow capture.
    
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
#ifdef AURUM_TELEMETRY_T1
    double qualityScoreForTelemetry = TELEMETRY_NULL_DOUBLE;
#endif
    
    if(consensus != SIGNAL_NONE && !h2Diag) {
        PrintFormat("[CONSENSUS] %s detected! Strength: %.2f", EnumToString(consensus), consensusStrength);
    }
    
    //--- 8. Consensus / quality / execution gate
    if(consensus == SIGNAL_NONE) {
        GovSigForensicsV1_OnConsensusResolvedNone(currentBarTime, marketState);
        Aurum_LogH2RejectIfChanged(currentBarTime, SIGNAL_REJECT_NO_CONSENSUS, SIGNAL_NONE, 0.0, buyVotes, sellVotes);
        TradeDiag_Blocked("NoConsensus", _Symbol, 0.0, diagOpenCount);
    } else {
        GovSigForensicsV1_OnConsensusResolvedOk(currentBarTime, marketState, consensus, buyVotes, sellVotes);
        const int domStrat = GovSigForensicsV1_DominantStratSlot8(signals[0], signals[1], signals[2], signals[3], signals[4], signals[5], signals[6], signals[7], consensus);
        double qualityScore = g_qualityFilter.CalculateSetupScore(marketState, consensus,
                                                                  consensusStrength, agreementPct);
#ifdef AURUM_TELEMETRY_T1
        qualityScoreForTelemetry = qualityScore;
#endif
        if(!h2Diag) {
            PrintFormat("[QUALITY] Score: %.1f/100 (Min: %d)", qualityScore, InpMinQualityScore);
        }
        
        if(qualityScore < InpMinQualityScore) {
            Aurum_LogH2RejectIfChanged(currentBarTime, SIGNAL_REJECT_QUALITY_LOW, consensus, qualityScore, buyVotes, sellVotes);
            TradeDiag_Blocked("QualityScoreLow", _Symbol, 0.0, diagOpenCount);
            GovSigForensicsV1_RecordReject(currentBarTime, marketState, domStrat, consensus, (int)qualityScore, SIGNAL_REJECT_QUALITY_LOW, false);
        } else {
            ENUM_SIGNAL_REJECT_REASON reqFail = SIGNAL_REJECT_NONE;
            if(!CheckQualityRequirements(marketState, consensus, reqFail)) {
                Aurum_LogH2RejectIfChanged(currentBarTime, reqFail, consensus, qualityScore, buyVotes, sellVotes);
                if(!h2Diag) {
                    PrintFormat("[BLOCKED] Quality requirements not met (%s)", Aurum_RejectReasonText(reqFail));
                }
                GovSigForensicsV1_RecordReject(currentBarTime, marketState, domStrat, consensus, (int)qualityScore, reqFail, false);
            } else {
                if(!execRiskAllows) {
                    // Phase 3D: consensus/quality path visible for research; no new orders while risk halt
                    Aurum_LogH2RejectIfChanged(currentBarTime, SIGNAL_REJECT_RISK_HALT, consensus, qualityScore, buyVotes, sellVotes);
                    TradeDiag_Blocked("RiskManager", _Symbol, 0.0, diagOpenCount);
                    GovSigForensicsV1_RecordReject(currentBarTime, marketState, domStrat, consensus, (int)qualityScore, SIGNAL_REJECT_RISK_HALT, false);
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
                        GovSigForensicsV1_RecordReject(currentBarTime, marketState, domStrat, consensus, (int)qualityScore, posFail, false);
                    } else {
                        if(!h2Diag) {
                            Print("[TRADE] *** EXECUTING TRADE ***");
                        }
                        // GOV_RUNTIME_INJECTION_CANDIDATE — pre-order shadow snapshot hook (must never block native path).
                        GovSigForensicsV1_RecordAccepted(currentBarTime, marketState, domStrat, consensus, (int)qualityScore);
                        ExecuteTrade(consensus, marketState, qualityScore, signals);
                    }
                }
            }
        }
    }
#ifdef AURUM_TELEMETRY_T1
    TelemetryBarRow s_telemetryBarRow;
    TelemetryCollector_BuildBarRow(currentBarTime, marketState, signals, consensus,
                                   consensusStrength, agreementPct, qualityScoreForTelemetry,
                                   execRiskAllows, s_telemetryBarRow);
    TelemetryRingBuffer_PushCopy(s_telemetryBarRow);
#ifdef AURUM_TELEMETRY_T2
    TelemetryT2_EnqueueCopy(s_telemetryBarRow);
#endif
#endif

    // GOV_COLD_PATH_ONLY — ring-buffer / replay-append / forensic export must drain here or in OnTimer, not above.
    
    //--- 9. Manage existing positions (trailing stops, etc) — suppressed during risk halt (no modifies)
    if(execRiskAllows)
        // GOV_SHADOW_SAFE_POINT — post-position / modify path; shadow may observe fills vs trail state.
        ManageOpenPositions();
    
    //--- 10. Update info panel
    UpdatePanel();
    
    } while(false);
    
    s_inOnTick = false;
}

#ifdef AURUM_TELEMETRY_T2
//+------------------------------------------------------------------+
//| Timer — T2 persistence drain only (cold path)                  |
//+------------------------------------------------------------------+
void OnTimer() {
    // GOV_COLD_PATH_ONLY — background lane; governance drain must mirror this pattern (throttled).
    TelemetryT2_OnTimerDrain();
}
#endif

//+------------------------------------------------------------------+
//| Trade transaction hook — feed RiskManager on position closes     |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result) {
    // GOV_SHADOW_SAFE_POINT — post-deal / risk accounting hook; future shadow compares native vs replay ledger.
    if(!g_initialized || g_riskManager == NULL)
        return;
    if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
        return;
    if(trans.deal == 0)
        return;
    if(!HistoryDealSelect(trans.deal))
        return;
    if(HistoryDealGetString(trans.deal, DEAL_SYMBOL) != _Symbol)
        return;
    if(HistoryDealGetInteger(trans.deal, DEAL_MAGIC) != (long)InpMagicNumber)
        return;
    GovLineageLiveV1_OnTradeTransaction(trans, _Symbol, (long)InpMagicNumber);
    ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
    if(entry != DEAL_ENTRY_OUT)
        return;
    double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT)
                     + HistoryDealGetDouble(trans.deal, DEAL_SWAP)
                     + HistoryDealGetDouble(trans.deal, DEAL_COMMISSION);
    bool wasProfit = (profit > 0.0);
    const ulong gov_pos = (ulong)HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID);
    const datetime gov_dts = (datetime)HistoryDealGetInteger(trans.deal, DEAL_TIME);
    const long gov_pcents = (long)MathRound(profit * 100.0);
    SGovRuntimeTradeIdentityV1 gov_rid;
    GovRunTagDsV1_InitIdentity(gov_rid);
    if(GovRunAttrV1_FindByTicket(g_gov_rtag_module_v1.reg, gov_pos, gov_rid))
       GovRegimeIntV1_OnAttributedTradeClose(gov_dts, gov_rid.strategy_id, gov_pos, gov_pcents);
    GovRunTagIntV1_OnTradeClose(_Symbol, (long)InpMagicNumber, trans.deal);
    g_riskManager.OnTradeClosed(wasProfit, profit);
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
    
    if(InpLotMethod == LOT_FIXED_PER_BALANCE) {
        if(InpBalanceStep <= 0.0) {
            Print("ERROR: InpBalanceStep must be > 0 for Fixed per Balance: ", InpBalanceStep);
            valid = false;
        }
        if(InpBaseLotPerStep <= 0.0) {
            Print("ERROR: InpBaseLotPerStep must be > 0 for Fixed per Balance: ", InpBaseLotPerStep);
            valid = false;
        }
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
    
    if(!dayAllowed) {
        return false;
    }
    
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
    const int diagPos = (g_tradeManager != NULL ? g_tradeManager.CountOpenPositions() : -1);
    //--- Check trend alignment if required
    if(InpRequireTrendAlignment) {
        if(signal == SIGNAL_BUY && state.trendDir != TREND_UP) {
            outReason = SIGNAL_REJECT_REQUIRE_TREND;
            TradeDiag_Blocked(Aurum_RejectReasonToTradeDiagBlocked(outReason), _Symbol, 0.0, diagPos);
            return false;
        }
        if(signal == SIGNAL_SELL && state.trendDir != TREND_DOWN) {
            outReason = SIGNAL_REJECT_REQUIRE_TREND;
            TradeDiag_Blocked(Aurum_RejectReasonToTradeDiagBlocked(outReason), _Symbol, 0.0, diagPos);
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
            TradeDiag_Blocked(Aurum_RejectReasonToTradeDiagBlocked(outReason), _Symbol, 0.0, diagPos);
            return false;
        }
    }
    
    //--- Check momentum if required
    if(InpRequireMomentum) {
        if(signal == SIGNAL_BUY && state.rsi14 < 50) {
            outReason = SIGNAL_REJECT_REQUIRE_MOMENTUM;
            TradeDiag_Blocked(Aurum_RejectReasonToTradeDiagBlocked(outReason), _Symbol, 0.0, diagPos);
            return false;
        }
        if(signal == SIGNAL_SELL && state.rsi14 > 50) {
            outReason = SIGNAL_REJECT_REQUIRE_MOMENTUM;
            TradeDiag_Blocked(Aurum_RejectReasonToTradeDiagBlocked(outReason), _Symbol, 0.0, diagPos);
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
        TradeDiag_Blocked("MaxOpenPositions", _Symbol, 0.0, openCount);
        return false;
    }
    
    //--- Check consecutive losses
    if(g_riskManager.GetConsecutiveLosses() >= InpMaxConsecutiveLosses) {
        Logger::Warning("Max consecutive losses reached");
        rejectOut = SIGNAL_REJECT_MAX_CONSEC_LOSSES;
        TradeDiag_Blocked("MaxConsecutiveLosses", _Symbol, 0.0, openCount);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Execute trade                                                    |
//+------------------------------------------------------------------+
void ExecuteTrade(ENUM_SIGNAL signal, const MarketState &state, double qualityScore, const SignalResult &gov_rtag_signals[]) {
    // GOV_RUNTIME_INJECTION_CANDIDATE — execution hot path: shadow must be append-only / non-blocking only.
    //--- Reentrancy guard: prevent nested trade execution (safety vs callback/event loops)
    static bool s_inExecuteTrade = false;
    if(s_inExecuteTrade) {
        TradeDiag_Blocked("ExecuteTradeReentry", _Symbol, 0.0,
                          g_tradeManager != NULL ? g_tradeManager.CountOpenPositions() : -1);
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
        InpBalanceStep,
        InpBaseLotPerStep,
        InpMaxRiskPerTrade,
        InpSLPoints
    );
    
    double lotDiagRequestedEarly = -1.0;
    if(InpLotMethod == LOT_FIXED)
        lotDiagRequestedEarly = InpFixedLot;
    else if(InpLotMethod == LOT_FIXED_PER_BALANCE)
        lotDiagRequestedEarly = g_moneyManager.ComputeFixedPerBalanceLot(
            AccountInfoDouble(ACCOUNT_BALANCE), InpBalanceStep, InpBaseLotPerStep);

    if(lot <= 0) {
        Logger::Error("Invalid lot size calculated: " + DoubleToString(lot, 2));
        GovRuntimeObsV1_RefreshAccountSnapshot(_Symbol);
        GovRuntimeObsV1_FeedOrderContext((int)GOV_CAP_RES_LOT_INVALID,
                                        (lotDiagRequestedEarly >= 0.0 ? lotDiagRequestedEarly : lot), lot, 0.0);
        TradeDiag_Blocked("InvalidLotCalculated", _Symbol, lot, g_tradeManager.CountOpenPositions());
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
            GovRuntimeObsV1_RefreshAccountSnapshot(_Symbol);
            GovRuntimeObsV1_FeedOrderContext((int)GOV_CAP_RES_INVALID_STOPS, lot, lot, 0.0);
            TradeDiag_Blocked("InvalidStops", _Symbol, lot, g_tradeManager.CountOpenPositions());
            EXEC_TRADE_DONE();
            return;
        }
    } else {
        if(sl <= price || tp >= price) {
            Print("ERROR: Invalid SL/TP for SELL - SL: ", sl, " Price: ", price, " TP: ", tp);
            GovRuntimeObsV1_RefreshAccountSnapshot(_Symbol);
            GovRuntimeObsV1_FeedOrderContext((int)GOV_CAP_RES_INVALID_STOPS, lot, lot, 0.0);
            TradeDiag_Blocked("InvalidStops", _Symbol, lot, g_tradeManager.CountOpenPositions());
            EXEC_TRADE_DONE();
            return;
        }
    }
    
    Print("[TRADE PARAMS] ", EnumToString(signal), " | Price: ", price, " | SL: ", sl, " | TP: ", tp, " | Lot: ", lot);
    
    double lotDiagRequested = -1.0;
    if(InpLotMethod == LOT_FIXED)
        lotDiagRequested = InpFixedLot;
    else if(InpLotMethod == LOT_FIXED_PER_BALANCE)
        lotDiagRequested = g_moneyManager.ComputeFixedPerBalanceLot(
            AccountInfoDouble(ACCOUNT_BALANCE), InpBalanceStep, InpBaseLotPerStep);
    if(lotDiagRequested >= 0.0)
        Print("[LOT_DIAG ExecuteTrade] RequestedLot=", DoubleToString(lotDiagRequested, 4),
              " FinalLot=", DoubleToString(lot, 4),
              " FreeMargin=", DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2));
    else
        Print("[LOT_DIAG ExecuteTrade] Method=", EnumToString(InpLotMethod),
              " FinalLot=", DoubleToString(lot, 4),
              " FreeMargin=", DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2));
    
    //--- Structured allow log (margin snapshot only; OpenBuy/OpenSell re-check margin unchanged)
    double marginReqAllowed = 0.0;
    const ENUM_ORDER_TYPE otyAllowed = (signal == SIGNAL_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
    const int execOpenCount = g_tradeManager.CountOpenPositions();
    if(OrderCalcMargin(otyAllowed, _Symbol, lot, price, marginReqAllowed))
        TradeDiag_Allowed(_Symbol, lot, marginReqAllowed, execOpenCount);

    const double symMinVolDiag = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    if(symMinVolDiag > 0.0 && lot + 1e-12 < symMinVolDiag) {
        GovRuntimeObsV1_RefreshAccountSnapshot(_Symbol);
        double reqCap = lot;
        if(lotDiagRequested >= 0.0)
            reqCap = lotDiagRequested;
        else if(lotDiagRequestedEarly >= 0.0)
            reqCap = lotDiagRequestedEarly;
        GovRuntimeObsV1_FeedOrderContext((int)GOV_CAP_RES_LOT_COLLAPSE_MIN_VOLUME, reqCap, lot, marginReqAllowed);
    }
    
    //--- Runtime governance tag — optional comment suffix only (execution math unchanged).
    string order_comment = "AS2.0_Q" + IntegerToString((int)qualityScore);
    const int prim_rtag = GovRunTagIntV1_SelectPrimaryStrategyIndex(signal, gov_rtag_signals);
    const int idx_rtag = (prim_rtag < 0) ? (int)STRATEGY_MOMENTUM_SCALP : prim_rtag;
    SGovRuntimeTradeIdentityV1 pre_id;
    GovRunTagIntV1_BuildIdentityCore(idx_rtag, state.regime, state.session, state.atrRatio, 0, (datetime)TimeCurrent(), qualityScore, pre_id);
    if(InpGovRuntimeTagAppendComment)
        order_comment = GovRunTagIntV1_FormatOrderComment(order_comment, pre_id.tag, true);
    
    //--- Execute order
    ulong ticket = 0;
    
    if(signal == SIGNAL_BUY) {
        ticket = g_tradeManager.OpenBuy(lot, sl, tp, (int)qualityScore, order_comment, lotDiagRequested);
    } else {
        ticket = g_tradeManager.OpenSell(lot, sl, tp, (int)qualityScore, order_comment, lotDiagRequested);
    }
    
    //--- Handle result
    if(ticket > 0) {
        g_totalTrades++;
        g_riskManager.OnTradeOpened(lot);
        GovRunTagIntV1_OnTradeOpen(_Symbol, ticket, signal, gov_rtag_signals, state.regime, state.session, state.atrRatio, qualityScore);
        GovRegimeIntV1_RecordOpenOrder(_Symbol, ticket);
        GovSigForensicsV1_RecordExecuted((datetime)TimeCurrent(), state,
                                       GovSigForensicsV1_DominantStratSlot8(gov_rtag_signals[0], gov_rtag_signals[1], gov_rtag_signals[2], gov_rtag_signals[3], gov_rtag_signals[4], gov_rtag_signals[5], gov_rtag_signals[6], gov_rtag_signals[7], signal), signal, (int)qualityScore);

        Logger::LogTrade(ticket, "OPEN_" + EnumToString(signal), lot, price, sl, tp, (int)qualityScore);
        Logger::Info("Trade #" + IntegerToString(g_totalTrades) + " opened successfully");
    } else {
        Logger::Error("Trade execution failed");
        GovRuntimeObsV1_RefreshAccountSnapshot(_Symbol);
        double reqFail = lot;
        if(lotDiagRequested >= 0.0)
            reqFail = lotDiagRequested;
        else if(lotDiagRequestedEarly >= 0.0)
            reqFail = lotDiagRequestedEarly;
        GovRuntimeObsV1_FeedOrderContext((int)GOV_CAP_RES_ORDER_SEND_FAILED, reqFail, lot, marginReqAllowed);
    }
    
    EXEC_TRADE_DONE();
#undef EXEC_TRADE_DONE
}

//+------------------------------------------------------------------+
//| Manage open positions (trailing stops, etc)                      |
//+------------------------------------------------------------------+
void ManageOpenPositions() {
    // GOV_SHADOW_SAFE_POINT — trailing / modify batching; no governance FSM decisions here (v1).
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
    if(InpLotMethod == LOT_FIXED_PER_BALANCE) {
        Logger::Info("Fixed per Balance — step: " + DoubleToString(InpBalanceStep, 2) +
                     " | base lot/step: " + DoubleToString(InpBaseLotPerStep, 4));
    }
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
//| Strategy Tester hook — governance observability (cold path)      |
//+------------------------------------------------------------------+
double OnTester() {
    if(InpGovRuntimeObsOnTester)
        GovRuntimeObsIntV1_EmitEndOfRun(_Symbol, 0);
    if(InpGovVisualHtmlExport && InpGovVisualHtmlOnTester) {
        Aurum_FillDossierColdSnapshotV1();
        GovRuntimeVisualIntV1_ExportGovernanceReportV1(_Symbol, _Period, InpGovVisualSidecars, InpGovDossierCompareExport);
    }
    return 0.0;
}

//+------------------------------------------------------------------+
//| END OF AURUM SYNAPSE v2.0                                        |
//+------------------------------------------------------------------+
