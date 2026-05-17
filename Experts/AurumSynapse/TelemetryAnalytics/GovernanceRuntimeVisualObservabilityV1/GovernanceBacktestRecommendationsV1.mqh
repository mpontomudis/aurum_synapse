//+------------------------------------------------------------------+
//| GovernanceBacktestRecommendationsV1.mqh                          |
//| PHASE 20B — auto governance recommendations (rules)             |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_BACKTEST_REC_V1_MQH__
#define __AURUM_GOV_BACKTEST_REC_V1_MQH__

#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionDatasetV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyToxicityAnalyticsV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionExportV1.mqh"
#include "GovernanceRuntimeVisualHtmlWriterV1.mqh"
#include "GovernanceRuntimeVisualDatasetV1.mqh"
#include "GovernanceBacktestInputSnapshotV1.mqh"

inline void GovBacktestRecV1_AppendSection(const SGovStratAttribSummaryV1 &sum,
                                        const SGovVisualExecSummaryV1 &ex,
                                        string &html)
{
   SGovStratAttribSummaryV1 tmp = sum;
   for(int z = 0; z < GOV_SATTR_STRAT_COUNT_V1; z++)
      GovStratToxV1_Score(z, tmp, tmp.tox[z]);

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-reco\"><h2>20. Recommendations</h2>\n<ul>\n");
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      if(tmp.bd.by_strat[i].trades <= 0)
         continue;
      if(tmp.tox[i].score_0_1000 > 750) {
         GovRuntimeVisualHtmlW1_AppendLf(html, "<li class=\"sev-crit\">CRITICAL: Review / isolate " + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(i)) +
                                            " — toxicity score " + IntegerToString(tmp.tox[i].score_0_1000) + ".</li>\n");
      } else if(tmp.tox[i].score_0_1000 > 550) {
         GovRuntimeVisualHtmlW1_AppendLf(html, "<li class=\"sev-warn\">WARNING: Tighten filters on " + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(i)) + ".</li>\n");
      }
   }
   if(ex.balance_dd_rel_pct > 25.0)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<li class=\"sev-warn\">STABILITY: Reduce risk-per-trade or tighten consensus while DD &gt; 25%.</li>\n");
   if(!g_gov_dossier_strat_en_v1[(int)GOV_STRAT_GR] && tmp.bd.by_strat[(int)GOV_STRAT_GR].trades > 0)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<li class=\"sev-opt\">OPTIMIZATION: GridRecovery disabled in inputs but attribution shows activity — verify tagging.</li>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<li class=\"sev-stab\">STABILITY: Keep governance replay hashes for regression compares across runs.</li>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</ul></section>\n");
}

#endif // __AURUM_GOV_BACKTEST_REC_V1_MQH__
