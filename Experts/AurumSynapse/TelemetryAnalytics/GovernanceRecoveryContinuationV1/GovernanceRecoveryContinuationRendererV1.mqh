//+------------------------------------------------------------------+
//| GovernanceRecoveryContinuationRendererV1.mqh                     |
//| PHASE 24 — HTML §27–30 + CSV exports (observe-only)              |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RCI_RENDERER_V1_MQH__
#define __AURUM_GOV_RCI_RENDERER_V1_MQH__

#include "../GovernanceRuntimeVisualObservabilityV1/GovernanceRuntimeVisualHtmlWriterV1.mqh"
#include "GovernanceRecoveryContinuationEngineV1.mqh"

#define GOV_RCI_FILES_DIR_V1   "AurumSynapse\\TelemetryAnalytics\\GovernanceRecoveryContinuation\\"

inline void GovRciRenderV1_RowPm(string &html, const string label, const double pm)
{
   const int w = (int)MathRound(GovRciEngV1_Clamp1000(pm) / 10.0);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(label) + "</td><td>" + DoubleToString(pm, 1) + "</td><td><div class=\"barwrap\" style=\"min-width:110px;\"><div class=\"bar\" style=\"width:" + IntegerToString(w) + "%\"></div></div></td></tr>\n");
}

inline bool GovRciRenderV1_EnsureDir(void)
{
   FolderCreate("AurumSynapse");
   FolderCreate("AurumSynapse\\TelemetryAnalytics");
   return FolderCreate(GOV_RCI_FILES_DIR_V1);
}

inline bool GovRciRenderV1_WriteRecoveryContinuation(SGovRciStoreV1 &st)
{
   GovRciRenderV1_EnsureDir();
   const int h = FileOpen(GOV_RCI_FILES_DIR_V1 + "recovery_continuation.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "bars_observed", IntegerToString((long)st.bars_observed));
   FileWrite(h, "continuation_confidence_pm", DoubleToString(st.continuation_confidence_pm, 4));
   FileWrite(h, "recovery_continuity_pm", DoubleToString(st.recovery_continuity_pm, 4));
   FileWrite(h, "activation_inertia_pm", DoubleToString(st.activation_inertia_pm, 4));
   FileWrite(h, "adaptive_life_probability_pm", DoubleToString(st.adaptive_life_probability_pm, 4));
   FileWrite(h, "governance_dormancy_depth_pm", DoubleToString(st.governance_dormancy_depth_pm, 4));
   FileWrite(h, "post_thaw_momentum_survival_pm", DoubleToString(st.post_thaw_momentum_survival_pm, 4));
   FileWrite(h, "recovery_decay_pressure_pm", DoubleToString(st.recovery_decay_pressure_pm, 4));
   FileWrite(h, "ecosystem_awakening_readiness_pm", DoubleToString(st.ecosystem_awakening_readiness_pm, 4));
   FileWrite(h, "participation_restoration_probability_pm", DoubleToString(st.participation_restoration_probability_pm, 4));
   FileWrite(h, "strategic_reentry_resistance_pm", DoubleToString(st.strategic_reentry_resistance_pm, 4));
   FileWrite(h, "continuation_streak_bars", IntegerToString((long)st.continuation_streak_bars));
   FileWrite(h, "continuation_collapse_events", IntegerToString((long)st.continuation_collapse_events));
   FileWrite(h, "continuation_plateau_zones", IntegerToString((long)st.continuation_plateau_zones));
   FileWrite(h, "thaw_to_activity_latency_last", IntegerToString((long)st.thaw_to_activity_latency_last));
   FileWrite(h, "recovery_momentum_half_life_bars", IntegerToString((long)st.recovery_momentum_half_life_bars));
   FileWrite(h, "recovery_slope_degradation_pm", DoubleToString(st.recovery_slope_degradation_pm, 4));
   FileWrite(h, "adaptive_restoration_attempts", IntegerToString((long)st.adaptive_restoration_attempts));
   FileWrite(h, "governance_reactivation_failures", IntegerToString((long)st.governance_reactivation_failures));
   for(int i = 0; i < 8; i++)
      FileWrite(h, "continuation_dur_hist_" + IntegerToString(i), IntegerToString((long)st.continuation_duration_hist[i]));
   FileClose(h);
   return true;
}

inline bool GovRciRenderV1_WriteActivationInertia(SGovRciStoreV1 &st)
{
   GovRciRenderV1_EnsureDir();
   const int h = FileOpen(GOV_RCI_FILES_DIR_V1 + "activation_inertia.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "inertia_accum_pm", DoubleToString(st.inertia_accum_pm, 4));
   FileWrite(h, "dormant_governance_age_bars", IntegerToString((long)st.dormant_governance_age_bars));
   FileWrite(h, "inactivity_drag_pm", DoubleToString(st.inactivity_drag_pm, 4));
   FileWrite(h, "suppression_persistence_pm", DoubleToString(st.suppression_persistence_pm, 4));
   FileWrite(h, "strategy_activation_hesitation_pm", DoubleToString(st.strategy_activation_hesitation_pm, 4));
   FileWrite(h, "ecology_starvation_age_bars", IntegerToString((long)st.ecology_starvation_age_bars));
   FileWrite(h, "dormant_reinforcement_pm", DoubleToString(st.dormant_reinforcement_pm, 4));
   FileWrite(h, "anti_reactivation_pressure_pm", DoubleToString(st.anti_reactivation_pressure_pm, 4));
   FileWrite(h, "inertia_class", IntegerToString(st.inertia_class));
   FileWrite(h, "paralysis_severity_pm", DoubleToString(st.paralysis_severity_pm, 4));
   FileWrite(h, "restoration_resistance_pm", DoubleToString(st.restoration_resistance_pm, 4));
   FileWrite(h, "activation_friction_pm", DoubleToString(st.activation_friction_pm, 4));
   FileWrite(h, "recovery_blockers_pm", DoubleToString(st.recovery_blockers_pm, 4));
   for(int j = 0; j < GOV_RCI_INERTIA_CLASS_CT_V1; j++)
      FileWrite(h, "inertia_hist_" + IntegerToString(j), IntegerToString((long)st.inertia_class_hist[j]));
   FileClose(h);
   return true;
}

inline bool GovRciRenderV1_WriteAdaptiveReactivation(SGovRciStoreV1 &st)
{
   GovRciRenderV1_EnsureDir();
   const int h = FileOpen(GOV_RCI_FILES_DIR_V1 + "adaptive_reactivation.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "ecology_wake_probability_pm", DoubleToString(st.ecology_wake_probability_pm, 4));
   FileWrite(h, "dormant_strategy_age_bars", IntegerToString((long)st.dormant_strategy_age_bars));
   FileWrite(h, "ecology_awakening_pressure_pm", DoubleToString(st.ecology_awakening_pressure_pm, 4));
   FileWrite(h, "adaptive_participation_readiness_pm", DoubleToString(st.adaptive_participation_readiness_pm, 4));
   FileWrite(h, "suppression_fatigue_pm", DoubleToString(st.suppression_fatigue_pm, 4));
   FileWrite(h, "regime_safe_reactivation_pm", DoubleToString(st.regime_safe_reactivation_pm, 4));
   FileWrite(h, "strategy_hesitation_map_pm", DoubleToString(st.strategy_hesitation_map_pm, 4));
   FileWrite(h, "ecosystem_vitality_pm", DoubleToString(st.ecosystem_vitality_pm, 4));
   FileWrite(h, "adaptive_ecosystem_respiration_pm", DoubleToString(st.adaptive_ecosystem_respiration_pm, 4));
   FileWrite(h, "strategy_life_signals_pm", DoubleToString(st.strategy_life_signals_pm, 4));
   FileWrite(h, "ecology_restoration_confidence_pm", DoubleToString(st.ecology_restoration_confidence_pm, 4));
   FileWrite(h, "participation_entropy_recovery_pm", DoubleToString(st.participation_entropy_recovery_pm, 4));
   FileWrite(h, "dead_ecosystem_loop_hint", IntegerToString(st.dead_ecosystem_loop_hint));
   FileWrite(h, "governance_life_phase", IntegerToString(st.governance_life_phase));
   FileWrite(h, "adaptive_vitality_pm", DoubleToString(st.adaptive_vitality_pm, 4));
   FileWrite(h, "ecosystem_respiration_pm", DoubleToString(st.ecosystem_respiration_pm, 4));
   FileWrite(h, "governance_pulse_pm", DoubleToString(st.governance_pulse_pm, 4));
   FileWrite(h, "recovery_circulation_pm", DoubleToString(st.recovery_circulation_pm, 4));
   FileWrite(h, "adaptive_nervous_continuity_pm", DoubleToString(st.adaptive_nervous_continuity_pm, 4));
   FileWrite(h, "governance_vitality_pm", DoubleToString(st.governance_vitality_pm, 4));
   FileWrite(h, "adaptive_life_score_pm", DoubleToString(st.adaptive_life_score_pm, 4));
   FileWrite(h, "ecosystem_survivability_pm", DoubleToString(st.ecosystem_survivability_pm, 4));
   FileWrite(h, "restoration_sustainability_pm", DoubleToString(st.restoration_sustainability_pm, 4));
   FileWrite(h, "adaptive_continuity_confidence_pm", DoubleToString(st.adaptive_continuity_confidence_pm, 4));
   FileWrite(h, "forensic_survival_without_life_pm", DoubleToString(st.forensic_survival_without_life_pm, 4));
   FileWrite(h, "forensic_perpetual_stabilization_pm", DoubleToString(st.forensic_perpetual_stabilization_pm, 4));
   FileWrite(h, "forensic_dormant_trap_pm", DoubleToString(st.forensic_dormant_trap_pm, 4));
   FileWrite(h, "forensic_adaptive_paralysis_cycle_pm", DoubleToString(st.forensic_adaptive_paralysis_cycle_pm, 4));
   for(int k = 0; k < GOV_RCI_LIFE_PHASE_CT_V1; k++)
      FileWrite(h, "life_phase_hist_" + IntegerToString(k), IntegerToString((long)st.life_phase_hist[k]));
   FileClose(h);
   return true;
}

inline bool GovRciRenderV1_WriteAllCsv(SGovRciStoreV1 &st)
{
   if(!st.enabled)
      return true;
   bool ok = true;
   ok &= GovRciRenderV1_WriteRecoveryContinuation(st);
   ok &= GovRciRenderV1_WriteActivationInertia(st);
   ok &= GovRciRenderV1_WriteAdaptiveReactivation(st);
   return ok;
}

inline void GovRciRenderV1_AppendSection27(string &html, SGovRciStoreV1 &st)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s27\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">27</span> Recovery continuation intelligence</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Diagnoses why recovery momentum fails to sustain after thaw stabilization: continuation streaks, collapse events, plateau zones, thaw-to-activity latency, and decay pressure — telemetry only.</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table id=\"tblRciCont\"><thead><tr><th>metric</th><th>permille</th><th>continuation timeline</th></tr></thead><tbody>\n");
   GovRciRenderV1_RowPm(html, "continuation_confidence", st.continuation_confidence_pm);
   GovRciRenderV1_RowPm(html, "recovery_continuity", st.recovery_continuity_pm);
   GovRciRenderV1_RowPm(html, "post_thaw_momentum_survival", st.post_thaw_momentum_survival_pm);
   GovRciRenderV1_RowPm(html, "recovery_decay_pressure", st.recovery_decay_pressure_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>continuation_streak_bars</td><td colspan=\"2\">" + IntegerToString((long)st.continuation_streak_bars) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>continuation_collapse_events</td><td colspan=\"2\">" + IntegerToString((long)st.continuation_collapse_events) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>thaw_to_activity_latency_last</td><td colspan=\"2\">" + IntegerToString((long)st.thaw_to_activity_latency_last) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>recovery_momentum_half_life_bars</td><td colspan=\"2\">" + IntegerToString((long)st.recovery_momentum_half_life_bars) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<h3 class=\"gov-h3\">Recent continuation timeline (ring)</h3><table><thead><tr><th>bar</th><th>code</th></tr></thead><tbody>\n");
   const int n = MathMin(st.ring_count, GOV_RCI_RING_V1);
   for(int k = 0; k < n; k++) {
      const int idx = (st.ring_wi - 1 - k + GOV_RCI_RING_V1 * 2) % GOV_RCI_RING_V1;
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + IntegerToString((long)st.ring[idx].bar_idx) + "</td><td>" + IntegerToString(st.ring[idx].code) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></section>\n");
}

inline void GovRciRenderV1_AppendSection28(string &html, SGovRciStoreV1 &st)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s28\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">28</span> Activation inertia physiology</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Models why governance can remain inactive while conditions look stable: inertia accumulation, dormant age, suppression persistence, and anti-reactivation pressure.</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>inertia_class</td><td>" + IntegerToString(st.inertia_class) + "</td></tr>\n");
   GovRciRenderV1_RowPm(html, "inertia_accum", st.inertia_accum_pm);
   GovRciRenderV1_RowPm(html, "inactivity_drag", st.inactivity_drag_pm);
   GovRciRenderV1_RowPm(html, "anti_reactivation_pressure", st.anti_reactivation_pressure_pm);
   GovRciRenderV1_RowPm(html, "activation_friction", st.activation_friction_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<h3 class=\"gov-h3\">Inertia class histogram (heatmap proxy)</h3><table><thead><tr><th>class</th><th>count</th></tr></thead><tbody>\n");
   for(int j = 0; j < GOV_RCI_INERTIA_CLASS_CT_V1; j++) {
      const int w = (int)MathMin(100, 12 + (int)MathMin(88L, (long)st.inertia_class_hist[j] * 3L));
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + IntegerToString(j) + "</td><td><div class=\"barwrap\"><div class=\"bar\" style=\"width:" + IntegerToString(w) + "%\"></div></div> " + IntegerToString((long)st.inertia_class_hist[j]) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></section>\n");
}

inline void GovRciRenderV1_AppendSection29(string &html, SGovRciStoreV1 &st)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s29\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">29</span> Adaptive ecosystem reactivation</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Post-survival restoration view: wake probability, suppression fatigue, participation readiness, and dead-loop hints — does not enable strategies.</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table><tbody>\n");
   GovRciRenderV1_RowPm(html, "ecology_wake_probability", st.ecology_wake_probability_pm);
   GovRciRenderV1_RowPm(html, "ecosystem_vitality", st.ecosystem_vitality_pm);
   GovRciRenderV1_RowPm(html, "adaptive_ecosystem_respiration", st.adaptive_ecosystem_respiration_pm);
   GovRciRenderV1_RowPm(html, "ecology_restoration_confidence", st.ecology_restoration_confidence_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>dead_ecosystem_loop_hint</td><td colspan=\"2\">" + IntegerToString(st.dead_ecosystem_loop_hint) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></section>\n");
}

inline void GovRciRenderV1_AppendSection30(string &html, SGovRciStoreV1 &st)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s30\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">30</span> Governance life-cycle continuity</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Survival → stabilization → thaw → reactivation → living continuity; vitality and pulse bands synthesize ATS + ecology + continuation.</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>governance_life_phase</td><td colspan=\"2\">" + IntegerToString(st.governance_life_phase) + "</td></tr>\n");
   GovRciRenderV1_RowPm(html, "governance_vitality", st.governance_vitality_pm);
   GovRciRenderV1_RowPm(html, "adaptive_life_score", st.adaptive_life_score_pm);
   GovRciRenderV1_RowPm(html, "governance_pulse", st.governance_pulse_pm);
   GovRciRenderV1_RowPm(html, "adaptive_continuity_confidence", st.adaptive_continuity_confidence_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<h3 class=\"gov-h3\">Forensic correlation strip</h3><table><tbody>\n");
   GovRciRenderV1_RowPm(html, "survival_without_life", st.forensic_survival_without_life_pm);
   GovRciRenderV1_RowPm(html, "perpetual_stabilization_loop", st.forensic_perpetual_stabilization_pm);
   GovRciRenderV1_RowPm(html, "dormant_governance_trap", st.forensic_dormant_trap_pm);
   GovRciRenderV1_RowPm(html, "adaptive_paralysis_cycle", st.forensic_adaptive_paralysis_cycle_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s30-nar\"><h3 class=\"gov-h3\">Narrative diagnosis (explanatory)</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-note\">" + GovRuntimeVisualHtmlW1_Escape(st.last_narrative_summary) + "</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-note\">Exports: <code>recovery_continuation.csv</code>, <code>activation_inertia.csv</code>, <code>adaptive_reactivation.csv</code> under TelemetryAnalytics/GovernanceRecoveryContinuation/</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</div></section>\n");
}

inline void GovRciRenderV1_AppendDossierSections2730(string &html, SGovRciStoreV1 &st)
{
   if(!st.enabled) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s27\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">27–30</span> Recovery continuation suite</h2>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-note\">Phase 24 telemetry disabled (<code>InpGovPhase24RecoveryContinuationIntel</code>).</p></section>\n");
      return;
   }
   GovRciRenderV1_AppendSection27(html, st);
   GovRciRenderV1_AppendSection28(html, st);
   GovRciRenderV1_AppendSection29(html, st);
   GovRciRenderV1_AppendSection30(html, st);
}

#endif // __AURUM_GOV_RCI_RENDERER_V1_MQH__
