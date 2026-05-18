//+------------------------------------------------------------------+
//| GovernanceBacktestEnvironmentSnapshotV1.mqh                      |
//| PHASE 20B — broker / symbol execution envelope                   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_BACKTEST_ENV_V1_MQH__
#define __AURUM_GOV_BACKTEST_ENV_V1_MQH__

#include "GovernanceRuntimeVisualHtmlWriterV1.mqh"
#include "GovernanceRuntimeVisualDatasetV1.mqh"

inline void GovBacktestEnvSnapV1_AppendTableRowsImpl(string &html, const string sym)
{
   const double vmin = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   const double vmax = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   const double vstep = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   const int stops = (int)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>terminal_build</td><td>" + IntegerToString((int)TerminalInfoInteger(TERMINAL_BUILD)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>terminal_company</td><td>" + GovRuntimeVisualHtmlW1_Escape(AccountInfoString(ACCOUNT_COMPANY)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>server</td><td>" + GovRuntimeVisualHtmlW1_Escape(AccountInfoString(ACCOUNT_SERVER)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>trade_mode</td><td>" + IntegerToString((int)AccountInfoInteger(ACCOUNT_TRADE_MODE)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>symbol_min_lot</td><td>" + DoubleToString(vmin, 4) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>symbol_max_lot</td><td>" + DoubleToString(vmax, 4) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>symbol_lot_step</td><td>" + DoubleToString(vstep, 4) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>symbol_stops_level_pts</td><td>" + IntegerToString(stops) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>symbol_point</td><td>" + DoubleToString(SymbolInfoDouble(sym, SYMBOL_POINT), (int)SymbolInfoInteger(sym, SYMBOL_DIGITS)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>tester</td><td>" + IntegerToString((int)MQLInfoInteger(MQL_TESTER)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>visual_mode</td><td>" + IntegerToString((int)MQLInfoInteger(MQL_VISUAL_MODE)) + "</td></tr>\n");
}

inline void GovBacktestEnvSnapV1_AppendTableRows(string &html, const SGovVisualExecSummaryV1 &sum)
{
   (void)sum;
   GovBacktestEnvSnapV1_AppendTableRowsImpl(html, _Symbol);
}

inline void GovBacktestEnvSnapV1_AppendTableRowsSym(const string sym, string &html)
{
   GovBacktestEnvSnapV1_AppendTableRowsImpl(html, sym);
}

inline void GovBacktestEnvSnapV1_AppendSection(const string sym, string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-env\"><h2>16. Environment snapshot</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table class=\"doss-meta\"><tbody>\n");
   GovBacktestEnvSnapV1_AppendTableRowsSym(sym, html);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></section>\n");
}

#endif // __AURUM_GOV_BACKTEST_ENV_V1_MQH__
