//+------------------------------------------------------------------+
//| RiskLockIntelligenceHtmlV1.mqh                                 |
//| PHASE 23.6 — dossier §25 (observe-only)                          |
//+------------------------------------------------------------------+
#ifndef __AURUM_RLI_HTML_V1_MQH__
#define __AURUM_RLI_HTML_V1_MQH__

#include "../GovernanceRuntimeVisualObservabilityV1/GovernanceRuntimeVisualHtmlWriterV1.mqh"
#include "RiskLockIntelligencePersistenceV1.mqh"

inline void GovRliHtmlV1_AppendSection25(string &html, SGovRliStoreV1 &st)
{
   if(!st.enabled) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s25\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">25</span> Risk lock intelligence stabilization</h2>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-note\">Phase 23.6 telemetry disabled (<code>InpGovPhase236RiskLockIntel</code>).</p></section>\n");
      return;
   }

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s25\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">25</span> Risk lock intelligence stabilization</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Lock origin lineage, thaw responsiveness, floating-pressure normalization, DD structural classification, and starvation correlation — telemetry only; hard RiskManager protections unchanged.</p>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s25-1\"><h3 class=\"gov-h3\">25.1 Lock origin analysis</h3><table><tbody>\n");
   for(int i = 0; i < 9; i++)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovRliPersistV1_OriginLabel(i)) + "</td><td>" + IntegerToString((long)st.lock_origin_hist[i]) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>lock_events</td><td>" + IntegerToString((long)st.lock_events) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s25-2\"><h3 class=\"gov-h3\">25.2 Lock lineage graph (tabular)</h3>\n<table id=\"tblRliLin\"><thead><tr><th>id</th><th>origin</th><th>bars</th><th>eq_dd0</th><th>fp0</th></tr></thead><tbody>\n");
   const int show = MathMin(24, st.ring_count);
   for(int k = 0; k < show; k++) {
      const int idx = (st.ring_wi - 1 - k + GOV_RLI_RING_V1 * 2) % GOV_RLI_RING_V1;
      const SGovRliLockRecordV1 r = st.ring[idx];
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + IntegerToString((long)r.id) + "</td><td>" + GovRuntimeVisualHtmlW1_Escape(GovRliPersistV1_OriginLabel(r.origin)) + "</td><td>" +
                                         IntegerToString((long)r.duration_bars) + "</td><td>" + DoubleToString(r.eq_dd0, 2) + "</td><td>" + DoubleToString(r.floating_pressure0, 2) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s25-3\"><h3 class=\"gov-h3\">25.3 Thaw intelligence</h3><table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>thaw_successes</td><td>" + IntegerToString((long)st.thaw_successes) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>thaw_interruptions</td><td>" + IntegerToString((long)st.thaw_interruptions) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s25-4\"><h3 class=\"gov-h3\">25.4 Floating pressure normalization</h3><table><tbody>\n");
   const double avgp = (st.bars_observed > 0) ? (st.sum_floating_pressure / (double)st.bars_observed) : 0.0;
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>avg_fp_pct</td><td>" + DoubleToString(avgp, 4) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>float_stress_bars</td><td>" + IntegerToString((long)st.float_stress_bars) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s25-5\"><h3 class=\"gov-h3\">25.5 DD classification</h3><table><tbody>\n");
   for(int d = 0; d < 8; d++)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>class_" + IntegerToString(d) + "</td><td>" + IntegerToString((long)st.dd_class_hist[d]) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s25-6\"><h3 class=\"gov-h3\">25.6 Lock persistence analytics</h3><table><tbody>\n");
   for(int p = 0; p < 4; p++)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>persist_" + IntegerToString(p) + "</td><td>" + IntegerToString((long)st.persist_class_hist[p]) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s25-7\"><h3 class=\"gov-h3\">25.7 Execution starvation correlation</h3><table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>bars_starvation_overlap</td><td>" + IntegerToString((long)st.bars_starvation_overlap) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>max_starvation_bars</td><td>" + IntegerToString((long)st.max_starvation_bars) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s25-8\"><h3 class=\"gov-h3\">25.8 Governance stress physiology</h3><table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>governance_stress_accum</td><td>" + IntegerToString((long)st.governance_stress_accum) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>defensive_escalation_events</td><td>" + IntegerToString((long)st.defensive_escalation_events) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s25-9\"><h3 class=\"gov-h3\">25.9 Recovery responsiveness</h3><p class=\"gov-note\">Thaw duration mean is exported in <code>thaw_intelligence.csv</code>; adaptive thaw decay remains governed by Phase 22B policy only.</p></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s25-10\"><h3 class=\"gov-h3\">25.10 Stabilization recommendations</h3><ol>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<li>Review dominant lock origin histogram vs floating-pressure averages before changing any non-risk subsystem.</li>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<li>If <code>thaw_interruptions</code> dominates <code>thaw_successes</code>, investigate false-panic re-locks (telemetry-only diagnosis).</li>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<li>Correlate <code>dd_classification</code> peaks with tester sessions to filter artifact classes.</li>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</ol></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");
}

#endif // __AURUM_RLI_HTML_V1_MQH__
