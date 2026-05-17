//+------------------------------------------------------------------+
//| GovernanceBacktestRecoveryAnalysisV1.mqh                         |
//| PHASE 20B — recovery genealogy from lineage registry             |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_BACKTEST_RECOVERY_V1_MQH__
#define __AURUM_GOV_BACKTEST_RECOVERY_V1_MQH__

#include "../GovernancePositionLineageIntelligenceV1/GovernancePositionLineageRegistryV1.mqh"
#include "GovernanceRuntimeVisualHtmlWriterV1.mqh"

inline void GovBacktestRecoveryV1_AppendSection(const SGovLineageRegistryStoreV1 &reg, string &html)
{
   int max_depth = 0;
   int rec_nodes = 0;
   int active = 0;
   long loss_c = 0;
   for(int i = 0; i < GOV_LINEAGE_MAX_NODES_V1; i++) {
      if(reg.nodes[i].active == 0)
         continue;
      active++;
      max_depth = MathMax(max_depth, reg.nodes[i].recovery_depth);
      if(reg.nodes[i].recovery_depth > 0)
         rec_nodes++;
      loss_c += reg.nodes[i].cumulative_loss_cents;
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-rec\"><h2>19. Recovery analysis</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table class=\"doss-meta\"><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>active_nodes</td><td>" + IntegerToString(active) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>recovery_nodes</td><td>" + IntegerToString(rec_nodes) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>max_recovery_depth</td><td>" + IntegerToString(max_depth) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>registry_loss_cents_sum</td><td>" + IntegerToString((int)loss_c) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>telemetry_recoveries</td><td>" + IntegerToString(reg.tel.recoveries) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p style=\"color:#8b949e;font-size:0.85rem;\">Escalation factor approximates max_recovery_depth vs healthy_gen1 baseline (heuristic).</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");
}

#endif // __AURUM_GOV_BACKTEST_RECOVERY_V1_MQH__
