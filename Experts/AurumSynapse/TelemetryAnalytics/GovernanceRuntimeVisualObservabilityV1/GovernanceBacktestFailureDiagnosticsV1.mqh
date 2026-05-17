//+------------------------------------------------------------------+
//| GovernanceBacktestFailureDiagnosticsV1.mqh                       |
//| PHASE 20B — root-cause heuristics (cold path)                    |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_BACKTEST_FAIL_V1_MQH__
#define __AURUM_GOV_BACKTEST_FAIL_V1_MQH__

#include "../GovernanceRuntimeObservabilityExportV1/GovernanceRuntimeObservabilityDatasetV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionDatasetV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyToxicityAnalyticsV1.mqh"
#include "../GovernancePositionLineageIntelligenceV1/GovernancePositionLineageRegistryV1.mqh"
#include "GovernanceRuntimeVisualHtmlWriterV1.mqh"
#include "GovernanceRuntimeVisualDatasetV1.mqh"

inline void GovBacktestFailV1_AppendSection(const SGovStratAttribSummaryV1 &sum,
                                           const SGovVisualExecSummaryV1 &ex,
                                           const SGovLineageRegistryStoreV1 &lin,
                                           string &html)
{
   SGovStratAttribSummaryV1 tmp = sum;
   for(int z = 0; z < GOV_SATTR_STRAT_COUNT_V1; z++)
      GovStratToxV1_Score(z, tmp, tmp.tox[z]);

   int max_rd = 0;
   for(int i = 0; i < GOV_LINEAGE_MAX_NODES_V1; i++) {
      if(lin.nodes[i].active == 0)
         continue;
      max_rd = MathMax(max_rd, lin.nodes[i].recovery_depth);
   }
   const SGovRuntimeObsCapitalSnapV1 c = g_gov_runtime_obs_report_v1.cap;

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-fail\"><h2>18. Failure diagnostics</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<ul>\n");
   if(c.result_code == (int)GOV_CAP_RES_LOT_COLLAPSE_MIN_VOLUME)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<li class=\"sev-crit\">LOT_COLLAPSE_MIN_VOLUME — lot normalization below broker minimum.</li>\n");
   if(c.result_code == (int)GOV_CAP_RES_FREE_MARGIN_LOW || c.result_code == (int)GOV_CAP_RES_INSUFFICIENT_MARGIN)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<li class=\"sev-crit\">MARGIN_DEATH — margin exhaustion / insufficient free margin.</li>\n");
   if(ex.balance_dd_rel_pct > 30.0)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<li class=\"sev-warn\">DRAWDOWN_STRESS — balance-relative drawdown elevated.</li>\n");
   if(max_rd >= 3)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<li class=\"sev-warn\">TOXIC_RECOVERY_CASCADE — deep recovery generations detected.</li>\n");
   int hi_tox = 0;
   for(int k = 0; k < GOV_SATTR_STRAT_COUNT_V1; k++) {
      if(tmp.tox[k].score_0_1000 > 700 && tmp.bd.by_strat[k].trades > 0)
         hi_tox++;
   }
   if(hi_tox >= 2)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<li class=\"sev-warn\">STRATEGY_TOXICITY_CLUSTER — multiple strategies with elevated toxicity.</li>\n");
   if(ex.total_trades > 500 && ex.profit_factor < 1.0)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<li class=\"sev-opt\">OVERTRADING_PF_COMPRESSION — high trade count with PF below 1.</li>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</ul>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");
}

#endif // __AURUM_GOV_BACKTEST_FAIL_V1_MQH__
