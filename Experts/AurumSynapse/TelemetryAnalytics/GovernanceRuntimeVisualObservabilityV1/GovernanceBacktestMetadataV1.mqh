//+------------------------------------------------------------------+
//| GovernanceBacktestMetadataV1.mqh                               |
//| PHASE 20B — deterministic dossier metadata + trade stats         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_BACKTEST_META_V1_MQH__
#define __AURUM_GOV_BACKTEST_META_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "GovernanceRuntimeVisualContractsV1.mqh"
#include "GovernanceRuntimeVisualDatasetV1.mqh"
#include "GovernanceRuntimeVisualHtmlWriterV1.mqh"
#include "GovernanceRuntimeVisualTelemetryV1.mqh"
#include "GovernanceBacktestEnvironmentSnapshotV1.mqh"

inline string GovFmtV1_Duration(const uint sec)
{
   const int h = (int)(sec / 3600u);
   const int m = (int)((sec % 3600u) / 60u);
   const int s = (int)(sec % 60u);
   return StringFormat("%02dh %02dm %02ds", h, m, s);
}

struct SGovBacktestTradeStatsV1
{
   double avg_win;
   double avg_loss;
   double expectancy;
   double sharpe;
   double bal_min;
   double bal_max;
   double eq_min;
   double eq_max;
   int    valid;
};

inline void GovBacktestTradeStatsV1_Init(SGovBacktestTradeStatsV1 &t)
{
   t.avg_win = 0;
   t.avg_loss = 0;
   t.expectancy = 0;
   t.sharpe = 0;
   t.bal_min = 0;
   t.bal_max = 0;
   t.eq_min = 0;
   t.eq_max = 0;
   t.valid = 0;
}

inline void GovBacktestTradeStatsV1_FromExecAndTester(const SGovVisualExecSummaryV1 &ex, SGovBacktestTradeStatsV1 &t)
{
   GovBacktestTradeStatsV1_Init(t);
   if(MQLInfoInteger(MQL_TESTER) == 0)
      return;
   t.valid = 1;
   if(ex.profit_trades > 0)
      t.avg_win = ex.gross_profit / (double)ex.profit_trades;
   if(ex.loss_trades > 0)
      t.avg_loss = ex.gross_loss / (double)ex.loss_trades;
   t.expectancy = TesterStatistics(STAT_EXPECTED_PAYOFF);
   t.sharpe = TesterStatistics(STAT_SHARPE_RATIO);
   t.bal_min = TesterStatistics(STAT_BALANCEMIN);
   t.eq_min = TesterStatistics(STAT_EQUITYMIN);
   const double ini = TesterStatistics(STAT_INITIAL_DEPOSIT);
   const double fin_bal = AccountInfoDouble(ACCOUNT_BALANCE);
   const double fin_eq = AccountInfoDouble(ACCOUNT_EQUITY);
   // ENUM_STATISTICS has no historical peak balance/equity; span uses min vs max(initial,final) as conservative bound.
   t.bal_max = MathMax(t.bal_min, MathMax(ini, fin_bal));
   t.eq_max = MathMax(t.eq_min, MathMax(ini, fin_eq));
}

inline string GovBacktestMetaV1_PeriodStr(const ENUM_TIMEFRAMES tf)
{
   return EnumToString(tf);
}

inline string GovBacktestMetaV1_ModelingStr(void)
{
   if(MQLInfoInteger(MQL_TESTER) == 0)
      return "LIVE_OR_CHART";
   return "STRATEGY_TESTER_ACTIVE";
}

inline void GovBacktestMetaV1_AppendSection(const string report_id,
                                           const string report_ts,
                                           const string sym,
                                           const ENUM_TIMEFRAMES tf,
                                           const string git_commit,
                                           const int build_number,
                                           const SGovBacktestTradeStatsV1 &ts,
                                           string &html)
{
   const int bars = (MQLInfoInteger(MQL_TESTER) != 0) ? iBars(sym, tf) : 0;
   const int psec = (int)PeriodSeconds(tf);
   const long span_est = (long)bars * (long)psec;
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s2\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">02</span> Backtest metadata</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Reproducibility lattice: identifiers, tester span, and execution envelope for institutional attestation.</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table class=\"doss-meta\"><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>report_id</td><td class=\"mono\">" + GovRuntimeVisualHtmlW1_Escape(report_id) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>timestamp</td><td class=\"mono\">" + GovRuntimeVisualHtmlW1_Escape(report_ts) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>EA version</td><td>" + GovRuntimeVisualHtmlW1_Escape(MQLInfoString(MQL_PROGRAM_NAME)) + " terminal_build=" +
                                         IntegerToString((int)TerminalInfoInteger(TERMINAL_BUILD)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>governance_ABI</td><td>" + IntegerToString((int)GOV_VISUAL_ABI_VER_V1) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>dossier_schema</td><td>" + IntegerToString((int)GOV_DOSSIER_SCHEMA_VER_V1) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>git_commit</td><td class=\"mono\">" + GovRuntimeVisualHtmlW1_Escape(git_commit) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>build_number</td><td>" + IntegerToString(build_number) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>symbol</td><td>" + GovRuntimeVisualHtmlW1_Escape(sym) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>timeframe</td><td>" + GovRuntimeVisualHtmlW1_Escape(GovBacktestMetaV1_PeriodStr(tf)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>modeling_mode</td><td>" + GovRuntimeVisualHtmlW1_Escape(GovBacktestMetaV1_ModelingStr()) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>spread_points</td><td>" + IntegerToString((int)SymbolInfoInteger(sym, SYMBOL_SPREAD)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>leverage</td><td>1:" + IntegerToString((int)AccountInfoInteger(ACCOUNT_LEVERAGE)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>account_balance</td><td>" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + " " +
                                         AccountInfoString(ACCOUNT_CURRENCY) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>bars_series</td><td>" + IntegerToString(bars) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>bars_processed</td><td>" + IntegerToString(bars) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>dataset_coverage_seconds_est</td><td>" + IntegerToString((int)span_est) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>backtest_started_utc</td><td class=\"mono\">" +
                                         ((g_gov_visual_runtime_v1.started_at > 0) ? GovRuntimeVisualHtmlW1_Escape(TimeToString(g_gov_visual_runtime_v1.started_at, TIME_DATE | TIME_SECONDS)) : "N_A") + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>backtest_finished_utc</td><td class=\"mono\">" +
                                         ((g_gov_visual_runtime_v1.finished_at > 0) ? GovRuntimeVisualHtmlW1_Escape(TimeToString(g_gov_visual_runtime_v1.finished_at, TIME_DATE | TIME_SECONDS)) : "N_A") + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>runtime_duration_seconds</td><td>" + IntegerToString((int)g_gov_visual_runtime_v1.runtime_seconds) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>runtime_duration_hms</td><td class=\"mono\">" + GovRuntimeVisualHtmlW1_Escape(GovFmtV1_Duration(g_gov_visual_runtime_v1.runtime_seconds)) + "</td></tr>\n");
   if(ts.valid != 0) {
      const double ini_dep = TesterStatistics(STAT_INITIAL_DEPOSIT);
      const double fin_bal = AccountInfoDouble(ACCOUNT_BALANCE);
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>initial_balance_tester</td><td>" + DoubleToString(ini_dep, 2) + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>final_balance_account</td><td>" + DoubleToString(fin_bal, 2) + "</td></tr>\n");
   }
   if(MQLInfoInteger(MQL_TESTER) != 0) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>modeling_quality_descriptor</td><td>" + GovRuntimeVisualHtmlW1_Escape(GovBacktestMetaV1_ModelingStr()) + " · strategy_tester</td></tr>\n");
   } else {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>modeling_quality_descriptor</td><td>" + GovRuntimeVisualHtmlW1_Escape(GovBacktestMetaV1_ModelingStr()) + "</td></tr>\n");
   }
   if(ts.valid != 0) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>tester_expectancy</td><td>" + DoubleToString(ts.expectancy, 4) + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>tester_sharpe</td><td>" + DoubleToString(ts.sharpe, 4) + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>tester_balance_min</td><td>" + DoubleToString(ts.bal_min, 2) + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>tester_balance_max</td><td>" + DoubleToString(ts.bal_max, 2) + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>tester_equity_min</td><td>" + DoubleToString(ts.eq_min, 2) + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>tester_equity_max</td><td>" + DoubleToString(ts.eq_max, 2) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<h3 class=\"gov-h3\">Execution envelope · environment metadata</h3>\n<table class=\"doss-meta\"><tbody>\n");
   GovBacktestEnvSnapV1_AppendTableRows(sym, html);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></section>\n");
}

inline void GovBacktestMetaV1_AppendTradeStatisticsPanel(const SGovVisualExecSummaryV1 &ex, const SGovBacktestTradeStatsV1 &ts, string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<h3 class=\"gov-h3\">Ledger & distribution</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table><thead><tr><th>Metric</th><th>Value</th></tr></thead><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Total trades</td><td>" + IntegerToString(ex.total_trades) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Long trades</td><td>" + IntegerToString(ex.long_trades) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Short trades</td><td>" + IntegerToString(ex.short_trades) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Profit trades</td><td>" + IntegerToString(ex.profit_trades) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Loss trades</td><td>" + IntegerToString(ex.loss_trades) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Winrate %</td><td>" + IntegerToString((ex.total_trades > 0) ? (int)((100L * (long)ex.profit_trades) / (long)ex.total_trades) : 0) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Average win</td><td>" + DoubleToString(ts.avg_win, 2) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Average loss</td><td>" + DoubleToString(ts.avg_loss, 2) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Profit factor</td><td>" + DoubleToString(ex.profit_factor, 3) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Recovery factor</td><td>" + DoubleToString(ex.recovery_factor, 3) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Expectancy</td><td>" + DoubleToString(ts.expectancy, 4) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Sharpe (tester)</td><td>" + DoubleToString(ts.sharpe, 4) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Net profit</td><td>" + DoubleToString(ex.net_profit, 2) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"mono\" style=\"color:#8b949e;\">Span high uses max(min,initial,final); intra-test peak is not in ENUM_STATISTICS.</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"grid\" style=\"margin-top:12px;\"><div class=\"card\"><b>Equity span (min→high)</b><span>" +
                                         DoubleToString(ts.eq_min, 2) + " → " + DoubleToString(ts.eq_max, 2) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Balance span (min→high)</b><span>" +
                                         DoubleToString(ts.bal_min, 2) + " → " + DoubleToString(ts.bal_max, 2) + "</span></div></div>\n");
}

#endif // __AURUM_GOV_BACKTEST_META_V1_MQH__
