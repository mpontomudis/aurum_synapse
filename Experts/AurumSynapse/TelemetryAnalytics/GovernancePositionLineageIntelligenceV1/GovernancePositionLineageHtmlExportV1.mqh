//+------------------------------------------------------------------+
//| GovernancePositionLineageHtmlExportV1.mqh                       |
//| PHASE 20C — forensic lineage serialization (cold path, LF-only)   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_POS_LINEAGE_HTML_EXPORT_V1_MQH__
#define __AURUM_GOV_POS_LINEAGE_HTML_EXPORT_V1_MQH__

#include "GovernancePositionLineageRegistryV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionExportV1.mqh"
#include "../GovernanceRuntimeVisualObservabilityV1/GovernanceRuntimeVisualHtmlWriterV1.mqh"

#define GOV_LIN_HTML_MAX_NODES_V1   512

struct SGovLineageHtmlWorkV1
{
   SGovLineageNodeV1 nodes[GOV_LIN_HTML_MAX_NODES_V1];
   int               n;
};

inline void GovLineageHtmlW1_Clear(SGovLineageHtmlWorkV1 &w)
{
   w.n = 0;
}

inline bool GovLineageHtmlW1_HasId(const SGovLineageHtmlWorkV1 &w, const uint lid)
{
   if(lid == 0)
      return false;
   for(int i = 0; i < w.n; i++) {
      if(w.nodes[i].lineage_id == lid)
         return true;
   }
   return false;
}

inline bool GovLineageHtmlW1_Push(SGovLineageHtmlWorkV1 &w, const SGovLineageNodeV1 &node)
{
   if(node.lineage_id == 0)
      return false;
   if(w.n >= GOV_LIN_HTML_MAX_NODES_V1)
      return false;
   if(GovLineageHtmlW1_HasId(w, node.lineage_id))
      return false;
   w.nodes[w.n++] = node;
   return true;
}

inline void GovLineageHtmlW1_Gather(const SGovLineageRegistryStoreV1 &reg, SGovLineageHtmlWorkV1 &w)
{
   GovLineageHtmlW1_Clear(w);
   for(int i = 0; i < GOV_LINEAGE_MAX_NODES_V1; i++) {
      if(reg.nodes[i].active == 1)
         GovLineageHtmlW1_Push(w, reg.nodes[i]);
   }
   for(int a = 0; a < GOV_LINEAGE_ARCHIVE_MAX_V1; a++) {
      if(reg.archive_nodes[a].active == 2)
         GovLineageHtmlW1_Push(w, reg.archive_nodes[a]);
   }
   for(int i = 0; i < w.n - 1; i++) {
      for(int j = i + 1; j < w.n; j++) {
         if(w.nodes[j].lineage_id < w.nodes[i].lineage_id) {
            const SGovLineageNodeV1 t = w.nodes[i];
            w.nodes[i] = w.nodes[j];
            w.nodes[j] = t;
         }
      }
   }
}

inline string GovLineageHtmlW1_MutLabel(const int mt)
{
   switch(mt) {
   case GOV_MUT_NEW_ENTRY: return "NEW_ENTRY";
   case GOV_MUT_CONTINUATION: return "CONTINUATION";
   case GOV_MUT_SCALE_IN: return "SCALE_IN";
   case GOV_MUT_SCALE_OUT: return "SCALE_OUT";
   case GOV_MUT_PARTIAL_CLOSE: return "PARTIAL_CLOSE";
   case GOV_MUT_HEDGE: return "HEDGE";
   case GOV_MUT_RECOVERY: return "RECOVERY";
   case GOV_MUT_REVERSAL: return "REVERSAL";
   case GOV_MUT_TRANSFER_OWNERSHIP: return "TRANSFER_OWNERSHIP";
   default: return "NONE";
   }
}

inline string GovLineageHtmlW1_LifecycleClass(const SGovLineageNodeV1 &n)
{
   if(n.recovery_depth >= 3 && n.cumulative_loss_cents > n.cumulative_profit_cents)
      return "TOXIC_RECOVERY_CASCADE";
   if(n.partial_close_count > 0 && n.scale_out_count > 2)
      return "VOLATILITY_COLLAPSE";
   if(n.recovery_depth > 0)
      return "RECOVERY_CHAIN";
   if(n.scale_in_count >= 2 && n.recovery_depth == 0)
      return "MUTATION_CHAIN";
   if(n.lifecycle_phase == (int)GOV_LC_PHASE_CONTINUATION)
      return "TREND_CONTINUATION";
   if(n.lifecycle_phase == (int)GOV_LC_PHASE_OPEN && n.scale_in_count == 0 && n.recovery_depth == 0)
      return "NORMAL";
   if(n.lifecycle_phase == (int)GOV_LC_PHASE_SCALE_IN && n.recovery_depth == 0)
      return "TREND_CONTINUATION";
   return "UNKNOWN";
}

inline string GovLineageHtmlW1_FailureCause(const SGovLineageNodeV1 &n)
{
   const string lc = GovLineageHtmlW1_LifecycleClass(n);
   if(lc == "TOXIC_RECOVERY_CASCADE")
      return "Recovery amplification with net loss dominance";
   if(lc == "VOLATILITY_COLLAPSE")
      return "Volatility-driven partial/scale-out churn";
   if(lc == "RECOVERY_CHAIN")
      return "Recovery ladder engaged";
   return "";
}

inline bool GovLineageHtmlW1_HasCascadeForRoot(const SGovLineageRegistryStoreV1 &reg, const uint root_id)
{
   if(root_id == 0)
      return false;
   for(int c = 0; c < GOV_LINEAGE_MAX_NODES_V1; c++) {
      if(reg.nodes[c].active != 1)
         continue;
      if(reg.nodes[c].root_lineage_id != root_id)
         continue;
      if(reg.nodes[c].recovery_depth >= 3)
         return true;
   }
   for(int a = 0; a < GOV_LINEAGE_ARCHIVE_MAX_V1; a++) {
      if(reg.archive_nodes[a].active != 2)
         continue;
      if(reg.archive_nodes[a].root_lineage_id != root_id)
         continue;
      if(reg.archive_nodes[a].recovery_depth >= 3)
         return true;
   }
   return false;
}

inline void GovLineageHtmlW1_AppendChildren(const SGovLineageRegistryStoreV1 &reg,
                                           const SGovLineageHtmlWorkV1 &w,
                                           const uint parent_lid,
                                           string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<ul class=\"tree\">\n");
   for(int k = 0; k < w.n; k++) {
      if(w.nodes[k].parent_lineage_id != parent_lid)
         continue;
      const string own = GovStratExpV1_StratLabel(w.nodes[k].current_owner_strategy);
      const string tox = (GovLineageHtmlW1_LifecycleClass(w.nodes[k]) == "TOXIC_RECOVERY_CASCADE") ? " lin-toxic" : "";
      GovRuntimeVisualHtmlW1_AppendLf(html, "<li class=\"" + tox + "\"><details><summary>" + GovRuntimeVisualHtmlW1_Escape(own) +
                                        " · LID=" + IntegerToString((int)w.nodes[k].lineage_id) + " · gen " + IntegerToString(w.nodes[k].execution_generation) + "</summary>\n");
      const long netc = w.nodes[k].cumulative_profit_cents - w.nodes[k].cumulative_loss_cents;
      GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"mono\">Net¢=" + IntegerToString((int)netc) + " | lifecycle=<code>" +
                                        GovRuntimeVisualHtmlW1_Escape(GovLineageHtmlW1_LifecycleClass(w.nodes[k])) + "</code></div>\n");
      GovLineageHtmlW1_AppendChildren(reg, w, w.nodes[k].lineage_id, html);
      GovRuntimeVisualHtmlW1_AppendLf(html, "</details></li>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</ul>\n");
}

inline void GovLineageHtmlW1_AppendMutationTail(const SGovLineageRegistryStoreV1 &reg, string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<details style=\"margin-top:10px;\"><summary>Recent mutation ring (bounded)</summary>\n<table><thead><tr><th>#</th><th>LID</th><th>PID</th><th>Type</th><th>Δ¢</th></tr></thead><tbody>\n");
   const int cap = 48;
   int shown = 0;
   for(int k = 0; k < cap && k < GOV_LINEAGE_MAX_MUTATIONS_V1; k++) {
      const int idx = (reg.mut_widx - 1 - k + GOV_LINEAGE_MAX_MUTATIONS_V1) % GOV_LINEAGE_MAX_MUTATIONS_V1;
      if(reg.mutations[idx].mutation_type == (int)GOV_MUT_NONE && reg.mutations[idx].position_id == 0)
         continue;
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + IntegerToString(shown) + "</td><td>" + IntegerToString((int)reg.mutations[idx].lineage_id) + "</td><td>" +
                                        IntegerToString((long)reg.mutations[idx].position_id) + "</td><td class=\"mono\">" +
                                        GovRuntimeVisualHtmlW1_Escape(GovLineageHtmlW1_MutLabel(reg.mutations[idx].mutation_type)) + "</td><td>" +
                                        IntegerToString((int)reg.mutations[idx].delta_profit_cents) + "</td></tr>\n");
      shown++;
   }
   if(shown == 0)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td colspan=\"5\"><i>No mutation records in ring.</i></td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></details>\n");
}

inline void GovLineageHtmlV1_AppendForest(const SGovLineageRegistryStoreV1 &reg, string &html)
{
   SGovLineageHtmlWorkV1 w;
   GovLineageHtmlW1_Gather(reg, w);

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"lin-summary mono\">lineage_telemetry: roots=" + IntegerToString(reg.tel.total_roots) + " children=" +
                                         IntegerToString(reg.tel.total_children) + " scale_ins=" + IntegerToString(reg.tel.scale_ins) + " recoveries=" +
                                         IntegerToString(reg.tel.recoveries) + " archive_seq=" + IntegerToString(reg.archive_seq) + " mut_ring=" +
                                         IntegerToString(reg.mut_count) + "</div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"lin-forest\">\n");
   int roots = 0;
   for(int i = 0; i < w.n; i++) {
      if(w.nodes[i].parent_lineage_id != 0)
         continue;
      roots++;
      const string origin = GovStratExpV1_StratLabel(w.nodes[i].originating_strategy);
      const long netc = w.nodes[i].cumulative_profit_cents - w.nodes[i].cumulative_loss_cents;
      const string lc = GovLineageHtmlW1_LifecycleClass(w.nodes[i]);
      const string fc = GovLineageHtmlW1_FailureCause(w.nodes[i]);
      const bool casc = GovLineageHtmlW1_HasCascadeForRoot(reg, w.nodes[i].root_lineage_id);
      const string toxwrap = (lc == "TOXIC_RECOVERY_CASCADE" || casc) ? " lin-toxic" : "";
      GovRuntimeVisualHtmlW1_AppendLf(html, "<details class=\"lin-root" + toxwrap + "\" open><summary><b>ROOT_LINEAGE_" + IntegerToString((int)w.nodes[i].lineage_id) +
                                        "</b> <span class=\"badge " + (netc >= 0 ? "tox-low" : "tox-high") + "\">Net " + (netc >= 0 ? "+" : "") + IntegerToString((int)netc) + " ¢</span>");
      if(casc)
         GovRuntimeVisualHtmlW1_AppendLf(html, " <span class=\"badge tox-high\">CASCADE</span>");
      GovRuntimeVisualHtmlW1_AppendLf(html, "</summary>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"lin-card\"><p><b>Origin:</b> " + GovRuntimeVisualHtmlW1_Escape(origin) + "</p>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<p><b>Lifecycle:</b> <code>" + GovRuntimeVisualHtmlW1_Escape(lc) + "</code></p>\n");
      if(StringLen(fc) > 0)
         GovRuntimeVisualHtmlW1_AppendLf(html, "<p><b>Failure cause:</b> " + GovRuntimeVisualHtmlW1_Escape(fc) + "</p>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<p><b>Children</b></p>\n");
      GovLineageHtmlW1_AppendChildren(reg, w, w.nodes[i].lineage_id, html);
      GovRuntimeVisualHtmlW1_AppendLf(html, "</div></details>\n");
   }
   if(roots == 0) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<p><i>No root lineages in active registry or close-archive. Telemetry above reflects historical registration volume.</i></p>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</div>\n");
   GovLineageHtmlW1_AppendMutationTail(reg, html);
}

#endif // __AURUM_GOV_POS_LINEAGE_HTML_EXPORT_V1_MQH__
