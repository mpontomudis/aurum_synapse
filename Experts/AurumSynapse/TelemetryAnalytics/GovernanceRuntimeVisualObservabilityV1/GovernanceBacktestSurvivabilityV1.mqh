//+------------------------------------------------------------------+
//| GovernanceBacktestSurvivabilityV1.mqh                            |
//| PHASE 20B — deposit tier matrix (deterministic rules)            |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_BACKTEST_SURV_V1_MQH__
#define __AURUM_GOV_BACKTEST_SURV_V1_MQH__

#include "GovernanceRuntimeVisualHtmlWriterV1.mqh"
#include "GovernanceRuntimeVisualDatasetV1.mqh"

inline string GovBacktestSurvV1_Status(const double deposit_label, const double dd_pct)
{
   if(deposit_label <= 200.0 && dd_pct > 18.0)
      return "COLLAPSE";
   if(deposit_label <= 500.0 && dd_pct > 22.0)
      return "UNSTABLE";
   if(deposit_label <= 1000.0 && dd_pct > 28.0)
      return "BORDERLINE";
   if(deposit_label <= 3000.0 && dd_pct > 35.0)
      return "BORDERLINE";
   if(deposit_label >= 10000.0 && dd_pct < 15.0)
      return "SAFE";
   if(deposit_label >= 3000.0 && dd_pct < 25.0)
      return "STABLE";
   return "BORDERLINE";
}

inline void GovBacktestSurvV1_AppendMatrix(const SGovVisualExecSummaryV1 &ex, string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-surv\"><h2>13. Survivability matrix</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table><thead><tr><th>Deposit</th><th>Status</th></tr></thead><tbody>\n");
   const double dd = ex.balance_dd_rel_pct;
   const double d0[5] = {200.0, 500.0, 1000.0, 3000.0, 10000.0};
   for(int j = 0; j < 5; j++)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>$" + DoubleToString(d0[j], 0) + "</td><td>" +
                                         GovRuntimeVisualHtmlW1_Escape(GovBacktestSurvV1_Status(d0[j], dd)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></section>\n");
}

#endif // __AURUM_GOV_BACKTEST_SURV_V1_MQH__
