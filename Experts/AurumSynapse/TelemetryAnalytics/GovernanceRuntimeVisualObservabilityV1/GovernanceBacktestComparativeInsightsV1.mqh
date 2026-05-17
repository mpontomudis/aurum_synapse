//+------------------------------------------------------------------+
//| GovernanceBacktestComparativeInsightsV1.mqh                       |
//| PHASE 20B — report vs report (KV baseline diff, deterministic)   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_BACKTEST_CMP_V1_MQH__
#define __AURUM_GOV_BACKTEST_CMP_V1_MQH__

#include "GovernanceRuntimeVisualHtmlWriterV1.mqh"
#include "../GovernanceRuntimeObservabilityExportV1/GovernanceRuntimeObservabilityReplayV1.mqh"
#include "GovernanceBacktestInputSnapshotV1.mqh"

inline void GovBacktestCmpV1_AppendSection(const string current_kv, string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-cmp\"><h2>17. Comparative insights</h2>\n");
   if(StringLen(g_gov_dossier_compare_baseline_kv_v1) <= 0) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<p><i>No baseline KV pinned (set <code>g_gov_dossier_compare_baseline_kv_v1</code> before export).</i></p>\n");
   } else {
      const ulong h0 = GovRuntimeObsReplayV1_Hash64(g_gov_dossier_compare_baseline_kv_v1);
      const ulong h1 = GovRuntimeObsReplayV1_Hash64(current_kv);
      GovRuntimeVisualHtmlW1_AppendLf(html, "<table class=\"doss-meta\"><tbody>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>baseline_hash</td><td class=\"mono\">" + IntegerToString((long)h0) + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>current_hash</td><td class=\"mono\">" + IntegerToString((long)h1) + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>equality</td><td>" + ((h0 == h1) ? "IDENTICAL_PAYLOAD" : "DIFFERENT_PAYLOAD") + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<p style=\"color:#8b949e;font-size:0.85rem;\">Line-level diff reserved for dossier_compare drill-down.</p>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p style=\"color:#8b949e;font-size:0.85rem;\">Massive backtest index: store <code>governance_report_*.json</code> sidecars and diff hashes in your analytics DB.</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");
}

#endif // __AURUM_GOV_BACKTEST_CMP_V1_MQH__
