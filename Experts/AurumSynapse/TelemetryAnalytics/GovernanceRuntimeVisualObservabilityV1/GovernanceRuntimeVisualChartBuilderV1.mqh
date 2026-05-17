//+------------------------------------------------------------------+
//| GovernanceRuntimeVisualChartBuilderV1.mqh                       |
//| Strategy / regime tables + bar markup (deterministic)            |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_VISUAL_CHART_V1_MQH__
#define __AURUM_GOV_RUNTIME_VISUAL_CHART_V1_MQH__

#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionDatasetV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionExportV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyToxicityAnalyticsV1.mqh"
#include "GovernanceRuntimeVisualHtmlWriterV1.mqh"

inline string GovRuntimeVisualChartV1_ToxBadgeClass(const int score)
{
   if(score < 400)
      return "tox-low";
   if(score < 700)
      return "tox-med";
   return "tox-high";
}

inline string GovRuntimeVisualChartV1_ToxLabel(const int score)
{
   if(score < 400)
      return "LOW";
   if(score < 700)
      return "MED";
   return "HIGH";
}

inline void GovRuntimeVisualChartV1_StrategyTable(const SGovStratAttribSummaryV1 &sum, string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table id=\"tblStrat\" data-sort-col=\"-1\" data-sort-dir=\"asc\"><thead><tr>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblStrat',0)\">Strategy</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblStrat',1)\">Trades</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblStrat',2)\">Winrate%</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblStrat',3)\">PF</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblStrat',4)\">Profit</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblStrat',5)\">Toxicity</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tr></thead><tbody>\n");
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      const SGovStratAttribStatsV1 st = sum.bd.by_strat[i];
      SGovStratAttribToxicityV1 tx;
      GovStratToxV1_Score(i, sum, tx);
      const int wr = (st.trades > 0) ? (int)((100L * (long)st.wins) / (long)st.trades) : 0;
      const long net = st.gross_win_cents - st.gross_loss_cents;
      const double pf = (double)st.pf_milli / 1000.0;
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(i)) + "</td>");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<td>" + IntegerToString(st.trades) + "</td>");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<td>" + IntegerToString(wr) + "</td>");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<td class=\"heat\">" + DoubleToString(pf, 3) + "</td>");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<td>" + IntegerToString((int)net) + "</td>");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<td><span class=\"badge " + GovRuntimeVisualChartV1_ToxBadgeClass(tx.score_0_1000) + "\">" +
                                         GovRuntimeVisualChartV1_ToxLabel(tx.score_0_1000) + "</span> (" + IntegerToString(tx.score_0_1000) + ")</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"grid\" style=\"margin-top:12px;\">\n");
   for(int j = 0; j < GOV_SATTR_STRAT_COUNT_V1; j++) {
      const SGovStratAttribStatsV1 st = sum.bd.by_strat[j];
      const int wrb = (st.trades > 0) ? (int)((100L * (long)st.wins) / (long)st.trades) : 0;
      GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>" + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(j)) + " winrate</b>");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"barwrap\"><div class=\"bar\" style=\"width:" + IntegerToString(wrb) + "%\"></div></div></div>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</div>\n");
}

inline void GovRuntimeVisualChartV1_RegimeTable(const SGovStratAttribSummaryV1 &sum, string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table><thead><tr><th>Regime</th><th>Trades</th><th>Net</th><th>PF</th></tr></thead><tbody>\n");
   for(int r = 0; r < GOV_SATTR_REGIME_COUNT_V1; r++) {
      const SGovStratAttribStatsV1 st = sum.bd.regime.by_reg[r];
      const long net = st.gross_win_cents - st.gross_loss_cents;
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovStratTagV1_RegimeCode(r)) + "</td><td>" + IntegerToString(st.trades) + "</td><td>" +
                                         IntegerToString((int)net) + "</td><td>" + DoubleToString((double)st.pf_milli / 1000.0, 3) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
}

#endif // __AURUM_GOV_RUNTIME_VISUAL_CHART_V1_MQH__
