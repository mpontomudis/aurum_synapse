//+------------------------------------------------------------------+
//| GovernanceRuntimeVisualLineageGraphV1.mqh                         |
//| HTML tree + lifecycle classification (deterministic)               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_VISUAL_LIN_V1_MQH__
#define __AURUM_GOV_RUNTIME_VISUAL_LIN_V1_MQH__

#include "../GovernancePositionLineageIntelligenceV1/GovernancePositionLineageDatasetV1.mqh"
#include "../GovernancePositionLineageIntelligenceV1/GovernancePositionLineageRegistryV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionExportV1.mqh"
#include "GovernanceRuntimeVisualHtmlWriterV1.mqh"

inline string GovRuntimeVisualLinV1_Classify(const SGovLineageNodeV1 &n)
{
   if(n.recovery_depth >= 3 && n.cumulative_loss_cents > n.cumulative_profit_cents)
      return "TOXIC_RECOVERY_CASCADE";
   if(n.scale_in_count >= 2 && n.recovery_depth == 0)
      return "HEALTHY_SCALE_IN";
   if(n.recovery_depth > 0 && n.hedge_depth > 0)
      return "MARGIN_DEATH_SPIRAL";
   if(n.partial_close_count > 0 && n.scale_out_count > 2)
      return "VOLATILITY_COLLAPSE";
   if(n.lifecycle_phase == (int)GOV_LC_PHASE_CONTINUATION)
      return "TREND_CONTINUATION";
   return "LINEAGE_ACTIVE";
}

inline void GovRuntimeVisualLinV1_AppendChildren(const SGovLineageRegistryStoreV1 &reg, const int parent_idx, string &html, const int depth)
{
   for(int j = 0; j < GOV_LINEAGE_MAX_NODES_V1; j++) {
      if(reg.nodes[j].active == 0)
         continue;
      if(reg.nodes[j].parent_node_idx != parent_idx)
         continue;
      const string nm = GovStratExpV1_StratLabel(reg.nodes[j].current_owner_strategy);
      GovRuntimeVisualHtmlW1_AppendLf(html, "<li><details><summary>" + GovRuntimeVisualHtmlW1_Escape(nm) + " LID=" + IntegerToString((int)reg.nodes[j].lineage_id) + "</summary>");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<div>Net=" + IntegerToString((int)(reg.nodes[j].cumulative_profit_cents - reg.nodes[j].cumulative_loss_cents)) +
                                         " | Class=" + GovRuntimeVisualHtmlW1_Escape(GovRuntimeVisualLinV1_Classify(reg.nodes[j])) + "</div>");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<ul class=\"tree\">");
      GovRuntimeVisualLinV1_AppendChildren(reg, j, html, depth + 1);
      GovRuntimeVisualHtmlW1_AppendLf(html, "</ul></details></li>\n");
   }
}

inline void GovRuntimeVisualLinV1_Build(const SGovLineageRegistryStoreV1 &reg, string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"tree\">\n");
   for(int i = 0; i < GOV_LINEAGE_MAX_NODES_V1; i++) {
      if(reg.nodes[i].active == 0)
         continue;
      if(reg.nodes[i].parent_node_idx >= 0)
         continue;
      GovRuntimeVisualHtmlW1_AppendLf(html, "<details open><summary><b>ROOT_LINEAGE_" + IntegerToString((int)reg.nodes[i].lineage_id) + "</b> — " +
                                         GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(reg.nodes[i].originating_strategy)) + "</summary>");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<p>Classification: <code>" + GovRuntimeVisualHtmlW1_Escape(GovRuntimeVisualLinV1_Classify(reg.nodes[i])) + "</code></p>");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<ul class=\"tree\">");
      GovRuntimeVisualLinV1_AppendChildren(reg, i, html, 1);
      GovRuntimeVisualHtmlW1_AppendLf(html, "</ul></details>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</div>\n");
}

#endif // __AURUM_GOV_RUNTIME_VISUAL_LIN_V1_MQH__
