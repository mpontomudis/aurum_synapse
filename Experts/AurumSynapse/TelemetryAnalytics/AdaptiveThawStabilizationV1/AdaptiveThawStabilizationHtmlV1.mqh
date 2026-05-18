//+------------------------------------------------------------------+
//| AdaptiveThawStabilizationHtmlV1.mqh                            |
//| PHASE 23.7 — dossier §26 (observe-only)                         |
//+------------------------------------------------------------------+
#ifndef __AURUM_ATS_HTML_V1_MQH__
#define __AURUM_ATS_HTML_V1_MQH__

#include "../GovernanceRuntimeVisualObservabilityV1/GovernanceRuntimeVisualHtmlWriterV1.mqh"
#include "AdaptiveThawStabilizationEngineV1.mqh"

inline void GovAtsHtmlV1_AppendBarRow(string &html, const string label, const double pm)
{
   const int w = (int)MathRound(GovAtsEngV1_Clamp1000(pm) / 10.0);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(label) + "</td><td>" + DoubleToString(pm, 1) + "</td><td><div class=\"barwrap\" style=\"min-width:120px;\"><div class=\"bar\" style=\"width:" + IntegerToString(w) + "%\"></div></div></td></tr>\n");
}

inline void GovAtsHtmlV1_AppendSection26(string &html, SGovAtsStoreV1 &st)
{
   if(!st.enabled) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s26\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">26</span> Adaptive thaw & anti-paralysis stabilization</h2>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-note\">Phase 23.7 telemetry disabled (<code>InpGovPhase237AdaptiveThawStabilization</code>).</p></section>\n");
      return;
   }

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s26\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">26</span> Adaptive thaw & anti-paralysis stabilization</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Telemetry-only recovery intelligence: thaw confidence, lock decay, floating normalization, contextual DD, recovery momentum, paralysis risk, execution continuity, ecology reactivation, and governance nervous-system stress/decay — does not alter RiskManager or thaw permissions.</p>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s26-1\"><h3 class=\"gov-h3\">26.1 Adaptive thaw intelligence</h3>\n<table id=\"tblAtsThaw\"><thead><tr><th>metric</th><th>permille</th><th>thaw confidence timeline</th></tr></thead><tbody>\n");
   GovAtsHtmlV1_AppendBarRow(html, "thaw_confidence", st.last_thaw_confidence_pm);
   GovAtsHtmlV1_AppendBarRow(html, "thaw_stability", st.last_thaw_stability_pm);
   GovAtsHtmlV1_AppendBarRow(html, "thaw_relapse_signal", st.last_thaw_relapse_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>thaw_state_class</td><td colspan=\"2\">" + IntegerToString(st.last_thaw_state) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s26-2\"><h3 class=\"gov-h3\">26.2 Lock decay dynamics</h3>\n<table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>lock_age_bars</td><td>" + IntegerToString((long)st.lock_age_bars_last) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>decay_class</td><td>" + IntegerToString(st.last_decay_class) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>decay_rate_pm</td><td>" + DoubleToString(st.last_lock_decay_rate_pm, 2) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table><p class=\"gov-note\">Defensive decay graph (tabular): histogram in <code>lock_decay.csv</code>.</p></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s26-3\"><h3 class=\"gov-h3\">26.3 Floating pressure normalization</h3>\n<table><tbody>\n");
   GovAtsHtmlV1_AppendBarRow(html, "float_norm_pm", st.last_float_norm_pm);
   GovAtsHtmlV1_AppendBarRow(html, "float_recovery_vel", st.last_float_recovery_vel_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>float_v2_class</td><td colspan=\"2\">" + IntegerToString(st.last_float_v2_class) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table><p class=\"gov-note\">Floating normalization curve: permille bars above.</p></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s26-4\"><h3 class=\"gov-h3\">26.4 Contextual DD interpretation</h3>\n<table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>dd_context_pm</td><td>" + DoubleToString(st.last_dd_context_pm, 2) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>volatility_adjusted_dd</td><td>" + DoubleToString(st.last_vol_adj_dd, 4) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>spread_adjusted_dd</td><td>" + DoubleToString(st.last_spread_adj_dd, 4) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s26-5\"><h3 class=\"gov-h3\">26.5 Recovery momentum</h3>\n<table><tbody>\n");
   GovAtsHtmlV1_AppendBarRow(html, "recovery_momentum", st.last_recovery_momentum_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>recovery_state</td><td colspan=\"2\">" + IntegerToString(st.last_recovery_state) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table><p class=\"gov-note\">Recovery momentum graph: bar row above.</p></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s26-6\"><h3 class=\"gov-h3\">26.6 Governance paralysis detection</h3>\n<table><tbody>\n");
   GovAtsHtmlV1_AppendBarRow(html, "paralysis_index", st.last_paralysis_index_pm);
   GovAtsHtmlV1_AppendBarRow(html, "defensive_overreaction", st.last_defensive_overreaction_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>paralysis_state</td><td colspan=\"2\">" + IntegerToString(st.last_paralysis_state) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table><p class=\"gov-note\">Paralysis probability heatmap: export <code>paralysis_detection.csv</code> for offline heatmaps.</p></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s26-7\"><h3 class=\"gov-h3\">26.7 Execution continuity recovery</h3>\n<table><tbody>\n");
   GovAtsHtmlV1_AppendBarRow(html, "exec_continuity", st.last_exec_continuity_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>bars_since_exec_hint</td><td colspan=\"2\">" + IntegerToString((long)st.last_bars_since_exec_hint) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s26-8\"><h3 class=\"gov-h3\">26.8 Ecology recovery stabilization</h3>\n<table><tbody>\n");
   GovAtsHtmlV1_AppendBarRow(html, "ecology_recovery", st.last_ecology_recovery_pm);
   GovAtsHtmlV1_AppendBarRow(html, "suppression_decay", st.last_suppression_decay_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s26-9\"><h3 class=\"gov-h3\">26.9 Governance nervous system</h3>\n<table><tbody>\n");
   GovAtsHtmlV1_AppendBarRow(html, "stress_accum", st.last_stress_accum_pm);
   GovAtsHtmlV1_AppendBarRow(html, "stress_decay", st.last_stress_decay_pm);
   GovAtsHtmlV1_AppendBarRow(html, "adaptive_resilience", st.last_nervous_resilience_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table><p class=\"gov-note\">Stress/recovery lifecycle map: juxtapose stress_accum vs adaptive_resilience bars.</p></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s26-10\"><h3 class=\"gov-h3\">26.10 Stabilization recommendations</h3><ol>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<li>If paralysis_index stays elevated while DD is benign, review false-panic overlap (restriction forensics §24) before any policy change.</li>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<li>When thaw_relapse_signal dominates thaw_confidence, treat recovery as fragile — still telemetry-only; do not force thaw.</li>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<li>Correlate float_v2_class with contextual DD to distinguish temporary floating spikes from structural exposure.</li>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</ol></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");
}

#endif // __AURUM_ATS_HTML_V1_MQH__
