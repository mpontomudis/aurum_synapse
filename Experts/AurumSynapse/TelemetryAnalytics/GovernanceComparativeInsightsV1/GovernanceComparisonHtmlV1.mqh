//+------------------------------------------------------------------+
//| GovernanceComparisonHtmlV1.mqh                                |
//| PHASE 20C — comparative insights HTML                            |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CMP_HTML_V1_MQH__
#define __AURUM_GOV_CMP_HTML_V1_MQH__

#include "GovernanceComparisonDiffV1.mqh"
#include "GovernanceComparisonScoringV1.mqh"
#include "GovernanceComparisonReplayV1.mqh"
#include "../GovernanceRuntimeVisualObservabilityV1/GovernanceRuntimeVisualHtmlWriterV1.mqh"
#include "../GovernanceRuntimeObservabilityExportV1/GovernanceRuntimeObservabilityReplayV1.mqh"
#include "../GovernanceRuntimeVisualObservabilityV1/GovernanceRuntimeVisualContractsV1.mqh"
#include "../GovernanceRuntimeVisualObservabilityV1/GovernanceRuntimeReportRegistryV1.mqh"
#include "../GovernanceRuntimeVisualObservabilityV1/GovernanceBacktestInputSnapshotV1.mqh"

inline void GovCmpHtmlV1_AppendSection(const string current_kv,
                                      const SGovCmpRunRecordV1 &baseline,
                                      const SGovCmpRunRecordV1 &current,
                                      string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<article id=\"intel-cmp\" class=\"gov-subarticle\"><h3 class=\"gov-h3\">Cross-run comparative telemetry</h3>\n");

   const ulong h0 = GovRuntimeObsReplayV1_Hash64(g_gov_dossier_compare_baseline_kv_v1);
   const ulong h1 = GovRuntimeObsReplayV1_Hash64(current_kv);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<details><summary>Input KV baseline hash</summary>\n<table class=\"doss-meta\"><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>baseline_kv_hash</td><td class=\"mono\">" + IntegerToString((long)h0) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>current_kv_hash</td><td class=\"mono\">" + IntegerToString((long)h1) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>equality</td><td>" + ((StringLen(g_gov_dossier_compare_baseline_kv_v1) > 0 && h0 == h1) ? "IDENTICAL_PAYLOAD" : "DIFFERENT_OR_UNPINNED") + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></details>\n");

   if(baseline.valid == 0) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<p><i>No prior governance baseline row found under <code>" + GovRuntimeVisualHtmlW1_Escape(GOV_VISUAL_BASELINE_CSV_V1) +
                                        "</code> or <code>" + GovRuntimeVisualHtmlW1_Escape(GOV_REPORT_REGISTRY_CSV_V1) +
                                        "</code>. Next export will establish RUN-vs-RUN history.</i></p>\n");
   } else {
      SGovCmpDiffLinesV1 d;
      GovCmpDiffV1_Build(baseline, current, d);
      const int sb = GovCmpScoreV1_StabilityPoints(baseline);
      const int sc = GovCmpScoreV1_StabilityPoints(current);
      GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"grid\">\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Compared to run</b><span class=\"mono\">" + GovRuntimeVisualHtmlW1_Escape(baseline.run_ts) + "</span></div>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Baseline hash</b><span class=\"mono\">" + IntegerToString((long)GovCmpReplayV1_Hash(baseline)) + "</span></div>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Current hash</b><span class=\"mono\">" + IntegerToString((long)GovCmpReplayV1_Hash(current)) + "</span></div>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Stability score</b><span>" + IntegerToString(sb) + " -> " + IntegerToString(sc) + "</span></div>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "</div>\n");

      GovRuntimeVisualHtmlW1_AppendLf(html, "<h3>Improvements</h3><ul>\n");
      if(d.ni == 0)
         GovRuntimeVisualHtmlW1_AppendLf(html, "<li><i>None detected vs baseline thresholds.</i></li>\n");
      for(int i = 0; i < d.ni; i++)
         GovRuntimeVisualHtmlW1_AppendLf(html, "<li class=\"sev-stab\">" + GovRuntimeVisualHtmlW1_Escape(d.improve[i]) + "</li>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "</ul>\n<h3>Degradations / regressions</h3><ul>\n");
      if(d.nd == 0)
         GovRuntimeVisualHtmlW1_AppendLf(html, "<li><i>None detected.</i></li>\n");
      for(int j = 0; j < d.nd; j++)
         GovRuntimeVisualHtmlW1_AppendLf(html, "<li class=\"sev-warn\">" + GovRuntimeVisualHtmlW1_Escape(d.degrade[j]) + "</li>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "</ul>\n");

      GovRuntimeVisualHtmlW1_AppendLf(html, "<details><summary>RUN vs RUN snapshot</summary><table class=\"doss-meta\"><tbody>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>PF</td><td>" + DoubleToString(baseline.pf, 3) + " -> " + DoubleToString(current.pf, 3) + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>DD bal %</td><td>" + DoubleToString(baseline.dd_bal_pct, 2) + " -> " + DoubleToString(current.dd_bal_pct, 2) + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Max tox</td><td>" + IntegerToString(baseline.max_tox) + " -> " + IntegerToString(current.max_tox) + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Recovery cascades</td><td>" + IntegerToString(baseline.recovery_cascades) + " -> " + IntegerToString(current.recovery_cascades) + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Deposit cents</td><td>" + IntegerToString((int)baseline.deposit_cents) + " -> " + IntegerToString((int)current.deposit_cents) + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></details>\n");
   }

   if(g_gov_report_export_ctx_v1.valid != 0) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<h4>Historical library anchors</h4>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-note\">Derived from <code>" + GovRuntimeVisualHtmlW1_Escape(GOV_REPORT_REGISTRY_CSV_V1) + "</code> (same symbol and timeframe). Use with baseline deltas above.</p>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<table class=\"doss-meta\"><thead><tr><th>Anchor</th><th>Run ID</th><th>PF</th><th>DD bal %</th><th>Max tox (est.)</th></tr></thead><tbody>\n");
      if(g_gov_report_export_ctx_v1.cmp_best_pf.valid != 0)
         GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Best PF</td><td class=\"mono\">" + GovRuntimeVisualHtmlW1_Escape(g_gov_report_export_ctx_v1.cmp_best_pf.run_ts) + "</td><td>" + DoubleToString(g_gov_report_export_ctx_v1.cmp_best_pf.pf, 3) + "</td><td>" +
                                               DoubleToString(g_gov_report_export_ctx_v1.cmp_best_pf.dd_bal_pct, 2) + "</td><td>" + IntegerToString(g_gov_report_export_ctx_v1.cmp_best_pf.max_tox) + "</td></tr>\n");
      else
         GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Best PF</td><td colspan=\"4\"><i>No prior rows for this symbol/TF.</i></td></tr>\n");
      if(g_gov_report_export_ctx_v1.cmp_safest_dd.valid != 0)
         GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Lowest DD</td><td class=\"mono\">" + GovRuntimeVisualHtmlW1_Escape(g_gov_report_export_ctx_v1.cmp_safest_dd.run_ts) + "</td><td>" + DoubleToString(g_gov_report_export_ctx_v1.cmp_safest_dd.pf, 3) + "</td><td>" +
                                               DoubleToString(g_gov_report_export_ctx_v1.cmp_safest_dd.dd_bal_pct, 2) + "</td><td>" + IntegerToString(g_gov_report_export_ctx_v1.cmp_safest_dd.max_tox) + "</td></tr>\n");
      else
         GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Lowest DD</td><td colspan=\"4\"><i>No prior rows for this symbol/TF.</i></td></tr>\n");
      if(g_gov_report_export_ctx_v1.cmp_richest.valid != 0)
         GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Most profitable</td><td class=\"mono\">" + GovRuntimeVisualHtmlW1_Escape(g_gov_report_export_ctx_v1.cmp_richest.run_ts) + "</td><td>" + DoubleToString(g_gov_report_export_ctx_v1.cmp_richest.pf, 3) + "</td><td>" +
                                               DoubleToString(g_gov_report_export_ctx_v1.cmp_richest.dd_bal_pct, 2) + "</td><td>" + IntegerToString(g_gov_report_export_ctx_v1.cmp_richest.max_tox) + "</td></tr>\n");
      else
         GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Most profitable</td><td colspan=\"4\"><i>No prior rows for this symbol/TF.</i></td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
   }

   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"mono\" style=\"color:#8b949e;font-size:0.85rem;\">Baseline store: append-only CSV+JSONL under MQL5 Files. Schema dossier=" +
                                         IntegerToString((int)GOV_DOSSIER_SCHEMA_VER_V1) + "</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</article>\n");
}

#endif // __AURUM_GOV_CMP_HTML_V1_MQH__
