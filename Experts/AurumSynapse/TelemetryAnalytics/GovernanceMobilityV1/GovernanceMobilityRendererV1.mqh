//+------------------------------------------------------------------+
//| GovernanceMobilityRendererV1.mqh                               |
//| PHASE 24A — HTML §31–39 + CSV (observe-only)                    |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_GMB_RENDERER_V1_MQH__
#define __AURUM_GOV_GMB_RENDERER_V1_MQH__

#include "../GovernanceRuntimeVisualObservabilityV1/GovernanceRuntimeVisualHtmlWriterV1.mqh"
#include "GovernanceMobilityEngineV1.mqh"

#define GOV_GMB_FILES_DIR_V1   "AurumSynapse\\TelemetryAnalytics\\GovernanceMobility\\"

inline void GovGmbRenderV1_RowPm(string &html, const string label, const double pm)
{
   const int w = (int)MathRound(GovGmbEngV1_Clamp1000(pm) / 10.0);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(label) + "</td><td>" + DoubleToString(pm, 1) + "</td><td><div class=\"barwrap\" style=\"min-width:110px;\"><div class=\"bar\" style=\"width:" + IntegerToString(w) + "%\"></div></div></td></tr>\n");
}

inline bool GovGmbRenderV1_EnsureDir(void)
{
   FolderCreate("AurumSynapse");
   FolderCreate("AurumSynapse\\TelemetryAnalytics");
   return FolderCreate(GOV_GMB_FILES_DIR_V1);
}

inline bool GovGmbRenderV1_WriteGovernanceMobility(SGovGmbStoreV1 &st)
{
   GovGmbRenderV1_EnsureDir();
   const int h = FileOpen(GOV_GMB_FILES_DIR_V1 + "governance_mobility.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "bars_observed", IntegerToString((long)st.bars_observed));
   FileWrite(h, "governance_mobility_score_pm", DoubleToString(st.governance_mobility_score_pm, 4));
   FileWrite(h, "adaptive_mobility_confidence_pm", DoubleToString(st.adaptive_mobility_confidence_pm, 4));
   FileWrite(h, "participation_restoration_velocity_pm", DoubleToString(st.participation_restoration_velocity_pm, 4));
   FileWrite(h, "operational_reactivation_rate_pm", DoubleToString(st.operational_reactivation_rate_pm, 4));
   FileWrite(h, "mobility_inertia_pm", DoubleToString(st.mobility_inertia_pm, 4));
   FileWrite(h, "adaptive_recovery_continuity_pm", DoubleToString(st.adaptive_recovery_continuity_pm, 4));
   FileWrite(h, "recovery_life_restoration_score_pm", DoubleToString(st.recovery_life_restoration_score_pm, 4));
   FileWrite(h, "mobility_class", IntegerToString(st.mobility_class));
   for(int i = 0; i < GOV_GMB_MOBILITY_CT_V1; i++)
      FileWrite(h, "mobility_hist_" + IntegerToString(i), IntegerToString((long)st.mobility_hist[i]));
   FileClose(h);
   return true;
}

inline bool GovGmbRenderV1_WriteControlledReactivation(SGovGmbStoreV1 &st)
{
   GovGmbRenderV1_EnsureDir();
   const int h = FileOpen(GOV_GMB_FILES_DIR_V1 + "controlled_reactivation.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "controlled_reactivation_score_pm", DoubleToString(st.controlled_reactivation_score_pm, 4));
   FileWrite(h, "selective_strategy_revival_pm", DoubleToString(st.selective_strategy_revival_pm, 4));
   FileWrite(h, "recovery_activation_success_pm", DoubleToString(st.recovery_activation_success_pm, 4));
   FileWrite(h, "reactivation_fragility_pm", DoubleToString(st.reactivation_fragility_pm, 4));
   FileWrite(h, "participation_reactivation_delay_pm", DoubleToString(st.participation_reactivation_delay_pm, 4));
   FileWrite(h, "safe_reentry_probability_pm", DoubleToString(st.safe_reentry_probability_pm, 4));
   FileWrite(h, "adaptive_reactivation_stability_pm", DoubleToString(st.adaptive_reactivation_stability_pm, 4));
   FileWrite(h, "reactivation_state", IntegerToString(st.reactivation_state));
   for(int r = 0; r < GOV_GMB_REACTIV_CT_V1; r++)
      FileWrite(h, "reactivation_hist_" + IntegerToString(r), IntegerToString((long)st.reactivation_hist[r]));
   FileClose(h);
   return true;
}

inline bool GovGmbRenderV1_WriteSuppressionDecay(SGovGmbStoreV1 &st)
{
   GovGmbRenderV1_EnsureDir();
   const int h = FileOpen(GOV_GMB_FILES_DIR_V1 + "suppression_decay.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "suppression_decay_rate_pm", DoubleToString(st.suppression_decay_rate_pm, 4));
   FileWrite(h, "suppression_persistence_track_pm", DoubleToString(st.suppression_persistence_track_pm, 4));
   FileWrite(h, "suppression_fatigue_track_pm", DoubleToString(st.suppression_fatigue_track_pm, 4));
   FileWrite(h, "adaptive_suppression_release_pm", DoubleToString(st.adaptive_suppression_release_pm, 4));
   FileWrite(h, "participation_recovery_after_suppression_pm", DoubleToString(st.participation_recovery_after_suppression_pm, 4));
   FileWrite(h, "suppression_inertia_pm", DoubleToString(st.suppression_inertia_pm, 4));
   FileWrite(h, "suppression_decay_class", IntegerToString(st.suppression_decay_class));
   for(int s = 0; s < GOV_GMB_SUPP_DECAY_CT_V1; s++)
      FileWrite(h, "suppression_decay_hist_" + IntegerToString(s), IntegerToString((long)st.suppression_decay_hist[s]));
   FileClose(h);
   return true;
}

inline bool GovGmbRenderV1_WriteStrategyRevival(SGovGmbStoreV1 &st)
{
   GovGmbRenderV1_EnsureDir();
   const int h = FileOpen(GOV_GMB_FILES_DIR_V1 + "strategy_revival.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "strategy_revival_worst_class", IntegerToString(st.strategy_revival_worst_class));
   FileWrite(h, "strategy_revival_avg_pm", DoubleToString(st.strategy_revival_avg_pm, 4));
   FileWrite(h, "strategy_reactivation_success_ct", IntegerToString((long)st.strategy_reactivation_success_ct));
   FileWrite(h, "strategy_relock_risk_pm", DoubleToString(st.strategy_relock_risk_pm, 4));
   for(int v = 0; v < GOV_GMB_STRAT_REVIVAL_CT_V1; v++)
      FileWrite(h, "strategy_revival_hist_" + IntegerToString(v), IntegerToString((long)st.strategy_revival_hist[v]));
   FileClose(h);
   return true;
}

inline bool GovGmbRenderV1_WriteParticipationContinuity(SGovGmbStoreV1 &st)
{
   GovGmbRenderV1_EnsureDir();
   const int h = FileOpen(GOV_GMB_FILES_DIR_V1 + "participation_continuity.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "participation_continuity_score_pm", DoubleToString(st.participation_continuity_score_pm, 4));
   FileWrite(h, "adaptive_execution_flow_pm", DoubleToString(st.adaptive_execution_flow_pm, 4));
   FileWrite(h, "participation_streak_bars", IntegerToString((long)st.participation_streak_bars));
   FileWrite(h, "execution_restoration_duration_pm", DoubleToString(st.execution_restoration_duration_pm, 4));
   FileWrite(h, "opportunity_recovery_rate_pm", DoubleToString(st.opportunity_recovery_rate_pm, 4));
   FileWrite(h, "starvation_recovery_velocity_pm", DoubleToString(st.starvation_recovery_velocity_pm, 4));
   FileWrite(h, "participation_continuity_class", IntegerToString(st.participation_continuity_class));
   for(int p = 0; p < GOV_GMB_PARTICIP_CT_V1; p++)
      FileWrite(h, "participation_hist_" + IntegerToString(p), IntegerToString((long)st.participation_hist[p]));
   FileClose(h);
   return true;
}

inline bool GovGmbRenderV1_WriteVitalityRestoration(SGovGmbStoreV1 &st)
{
   GovGmbRenderV1_EnsureDir();
   const int h = FileOpen(GOV_GMB_FILES_DIR_V1 + "vitality_restoration.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "adaptive_vitality_v2_pm", DoubleToString(st.adaptive_vitality_v2_pm, 4));
   FileWrite(h, "operational_life_score_pm", DoubleToString(st.operational_life_score_pm, 4));
   FileWrite(h, "ecosystem_reanimation_pm", DoubleToString(st.ecosystem_reanimation_pm, 4));
   FileWrite(h, "participation_health_pm", DoubleToString(st.participation_health_pm, 4));
   FileWrite(h, "governance_respiration_pm", DoubleToString(st.governance_respiration_pm, 4));
   FileWrite(h, "adaptive_recovery_energy_pm", DoubleToString(st.adaptive_recovery_energy_pm, 4));
   FileWrite(h, "vitality_decay_pm", DoubleToString(st.vitality_decay_pm, 4));
   FileWrite(h, "vitality_restoration_pm", DoubleToString(st.vitality_restoration_pm, 4));
   FileWrite(h, "vitality_v2_class", IntegerToString(st.vitality_v2_class));
   for(int z = 0; z < GOV_GMB_VITALITY_CT_V1; z++)
      FileWrite(h, "vitality_v2_hist_" + IntegerToString(z), IntegerToString((long)st.vitality_v2_hist[z]));
   FileClose(h);
   return true;
}

inline bool GovGmbRenderV1_WriteAntiStarvation(SGovGmbStoreV1 &st)
{
   GovGmbRenderV1_EnsureDir();
   const int h = FileOpen(GOV_GMB_FILES_DIR_V1 + "anti_starvation.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "starvation_persistence_pm", DoubleToString(st.starvation_persistence_pm, 4));
   FileWrite(h, "starvation_density_pm", DoubleToString(st.starvation_density_pm, 4));
   FileWrite(h, "participation_suffocation_pm", DoubleToString(st.participation_suffocation_pm, 4));
   FileWrite(h, "governance_overprotection_pm", DoubleToString(st.governance_overprotection_pm, 4));
   FileWrite(h, "adaptive_activity_absence_pm", DoubleToString(st.adaptive_activity_absence_pm, 4));
   FileWrite(h, "opportunity_extinction_risk_pm", DoubleToString(st.opportunity_extinction_risk_pm, 4));
   FileWrite(h, "anti_starvation_class", IntegerToString(st.anti_starvation_class));
   for(int a = 0; a < GOV_GMB_ANTISTARVE_CT_V1; a++)
      FileWrite(h, "anti_starve_hist_" + IntegerToString(a), IntegerToString((long)st.anti_starve_hist[a]));
   FileClose(h);
   return true;
}

inline bool GovGmbRenderV1_WriteEcologyRestoration(SGovGmbStoreV1 &st)
{
   GovGmbRenderV1_EnsureDir();
   const int h = FileOpen(GOV_GMB_FILES_DIR_V1 + "ecology_restoration.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "ecology_revival_probability_pm", DoubleToString(st.ecology_revival_probability_pm, 4));
   FileWrite(h, "participation_entropy_recovery_track_pm", DoubleToString(st.participation_entropy_recovery_track_pm, 4));
   FileWrite(h, "diversity_restoration_pm", DoubleToString(st.diversity_restoration_pm, 4));
   FileWrite(h, "monoculture_decay_pm", DoubleToString(st.monoculture_decay_pm, 4));
   FileWrite(h, "adaptive_ecology_reanimation_pm", DoubleToString(st.adaptive_ecology_reanimation_pm, 4));
   FileWrite(h, "ecosystem_breathing_rate_pm", DoubleToString(st.ecosystem_breathing_rate_pm, 4));
   FileClose(h);
   return true;
}

inline bool GovGmbRenderV1_WriteGovernanceLifeRestoration(SGovGmbStoreV1 &st)
{
   GovGmbRenderV1_EnsureDir();
   const int h = FileOpen(GOV_GMB_FILES_DIR_V1 + "governance_life_restoration.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "adaptive_life_probability_track_pm", DoubleToString(st.adaptive_life_probability_track_pm, 4));
   FileWrite(h, "governance_restoration_cycle_pm", DoubleToString(st.governance_restoration_cycle_pm, 4));
   FileWrite(h, "ecosystem_awakeness_pm", DoubleToString(st.ecosystem_awakeness_pm, 4));
   FileWrite(h, "adaptive_operationality_pm", DoubleToString(st.adaptive_operationality_pm, 4));
   FileWrite(h, "post_survival_vitality_pm", DoubleToString(st.post_survival_vitality_pm, 4));
   FileWrite(h, "restoration_stability_pm", DoubleToString(st.restoration_stability_pm, 4));
   FileClose(h);
   return true;
}

inline bool GovGmbRenderV1_WriteAllCsv(SGovGmbStoreV1 &st)
{
   if(!st.enabled)
      return true;
   bool ok = true;
   ok &= GovGmbRenderV1_WriteGovernanceMobility(st);
   ok &= GovGmbRenderV1_WriteControlledReactivation(st);
   ok &= GovGmbRenderV1_WriteSuppressionDecay(st);
   ok &= GovGmbRenderV1_WriteStrategyRevival(st);
   ok &= GovGmbRenderV1_WriteParticipationContinuity(st);
   ok &= GovGmbRenderV1_WriteVitalityRestoration(st);
   ok &= GovGmbRenderV1_WriteAntiStarvation(st);
   ok &= GovGmbRenderV1_WriteEcologyRestoration(st);
   ok &= GovGmbRenderV1_WriteGovernanceLifeRestoration(st);
   return ok;
}

inline void GovGmbRenderV1_AppendStrategyMatrix(string &html, const SGovEcologyStoreV1 &eco)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s34-matrix\"><h3 class=\"gov-h3\">Strategy revival matrix (ecology slices)</h3>\n<table id=\"tblGmbStrat\"><thead><tr><th>slot</th><th>recovery_pm</th><th>supp_bars</th><th>tox_pm</th><th>class</th></tr></thead><tbody>\n");
   for(int i = 0; i < GOV_ECO_STRAT_COUNT_V1; i++) {
      const int c = GovGmbEngV1_ClassifyStratRevival(eco.s[i].ecology_recovery_pm, eco.s[i].bars_suppression, eco.s[i].toxicity_score_permille);
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + IntegerToString(i) + "</td><td>" + IntegerToString(eco.s[i].ecology_recovery_pm) + "</td><td>" + IntegerToString((long)eco.s[i].bars_suppression) + "</td><td>" + IntegerToString(eco.s[i].toxicity_score_permille) + "</td><td>" + IntegerToString(c) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");
}

inline void GovGmbRenderV1_AppendHistHeat(string &html, const string title, ulong &hist[], const int n)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\"><h3 class=\"gov-h3\">" + GovRuntimeVisualHtmlW1_Escape(title) + "</h3>\n<table class=\"gov-heat\"><thead><tr>");
   for(int i = 0; i < n; i++)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<th>" + IntegerToString(i) + "</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tr></thead><tbody><tr>");
   ulong mx = 1;
   for(int j = 0; j < n; j++)
      if(hist[j] > mx)
         mx = hist[j];
   for(int k = 0; k < n; k++) {
      const int w = (int)MathRound(100.0 * ((double)hist[k] / (double)mx));
      GovRuntimeVisualHtmlW1_AppendLf(html, "<td><div class=\"barwrap\" style=\"min-width:48px;\"><div class=\"bar\" style=\"width:" + IntegerToString(w) + "%\"></div></div><span class=\"gov-mono\">" + IntegerToString((long)hist[k]) + "</span></td>");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tr></tbody></table></div>\n");
}

inline void GovGmbRenderV1_AppendDossierSections3139(string &html, SGovGmbStoreV1 &st, const SGovEcologyStoreV1 &eco)
{
   if(!st.enabled) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s31\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">31–39</span> Governance mobility &amp; life restoration (Phase 24A)</h2>\n<p class=\"gov-note\">Phase 24A telemetry disabled (<code>InpGovPhase24aGovernanceMobilityIntel</code>).</p></section>\n");
      return;
   }

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s31\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">31</span> Governance mobility</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Mobility score, inertia, and restoration velocity — observational; does not loosen risk locks.</p>\n<table id=\"tblGmbMob\"><thead><tr><th>metric</th><th>permille</th><th>mobility graph</th></tr></thead><tbody>\n");
   GovGmbRenderV1_RowPm(html, "governance_mobility_score_pm", st.governance_mobility_score_pm);
   GovGmbRenderV1_RowPm(html, "adaptive_mobility_confidence_pm", st.adaptive_mobility_confidence_pm);
   GovGmbRenderV1_RowPm(html, "mobility_inertia_pm", st.mobility_inertia_pm);
   GovGmbRenderV1_RowPm(html, "participation_restoration_velocity_pm", st.participation_restoration_velocity_pm);
   GovGmbRenderV1_RowPm(html, "operational_reactivation_rate_pm", st.operational_reactivation_rate_pm);
   GovGmbRenderV1_RowPm(html, "recovery_life_restoration_score_pm", st.recovery_life_restoration_score_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table><p>mobility_class=" + IntegerToString(st.mobility_class) + "</p></section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s32\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">32</span> Controlled reactivation</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Gradual re-entry diagnostics: fragility vs safe reentry vs stability.</p>\n<table id=\"tblGmbReac\"><thead><tr><th>metric</th><th>permille</th><th>reactivation lifecycle</th></tr></thead><tbody>\n");
   GovGmbRenderV1_RowPm(html, "controlled_reactivation_score_pm", st.controlled_reactivation_score_pm);
   GovGmbRenderV1_RowPm(html, "reactivation_fragility_pm", st.reactivation_fragility_pm);
   GovGmbRenderV1_RowPm(html, "safe_reentry_probability_pm", st.safe_reentry_probability_pm);
   GovGmbRenderV1_RowPm(html, "adaptive_reactivation_stability_pm", st.adaptive_reactivation_stability_pm);
   GovGmbRenderV1_RowPm(html, "participation_reactivation_delay_pm", st.participation_reactivation_delay_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table><p>reactivation_state=" + IntegerToString(st.reactivation_state) + "</p></section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s33\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">33</span> Suppression decay intelligence</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Persistence, fatigue, and release after stabilization.</p>\n<table><thead><tr><th>metric</th><th>permille</th><th>decay curve</th></tr></thead><tbody>\n");
   GovGmbRenderV1_RowPm(html, "suppression_decay_rate_pm", st.suppression_decay_rate_pm);
   GovGmbRenderV1_RowPm(html, "suppression_persistence_track_pm", st.suppression_persistence_track_pm);
   GovGmbRenderV1_RowPm(html, "suppression_fatigue_track_pm", st.suppression_fatigue_track_pm);
   GovGmbRenderV1_RowPm(html, "adaptive_suppression_release_pm", st.adaptive_suppression_release_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table><p>suppression_decay_class=" + IntegerToString(st.suppression_decay_class) + "</p></section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s34\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">34</span> Selective strategy revival</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Per-strategy revival classes before full ecology restoration.</p>\n");
   GovGmbRenderV1_AppendStrategyMatrix(html, eco);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table><tbody><tr><td>strategy_revival_worst_class</td><td>" + IntegerToString(st.strategy_revival_worst_class) + "</td></tr>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>strategy_relock_risk_pm</td><td>" + DoubleToString(st.strategy_relock_risk_pm, 2) + "</td></tr></tbody></table></section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s35\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">35</span> Participation continuity</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Execution flow continuity vs starvation recovery velocity.</p>\n<table><thead><tr><th>metric</th><th>permille</th><th>heatmap lane</th></tr></thead><tbody>\n");
   GovGmbRenderV1_RowPm(html, "participation_continuity_score_pm", st.participation_continuity_score_pm);
   GovGmbRenderV1_RowPm(html, "adaptive_execution_flow_pm", st.adaptive_execution_flow_pm);
   GovGmbRenderV1_RowPm(html, "opportunity_recovery_rate_pm", st.opportunity_recovery_rate_pm);
   GovGmbRenderV1_RowPm(html, "starvation_recovery_velocity_pm", st.starvation_recovery_velocity_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
   ulong pc_hist[];
   ArrayResize(pc_hist, GOV_GMB_PARTICIP_CT_V1);
   for(int ph = 0; ph < GOV_GMB_PARTICIP_CT_V1; ph++)
      pc_hist[ph] = st.participation_hist[ph];
   GovGmbRenderV1_AppendHistHeat(html, "Participation continuity class histogram", pc_hist, GOV_GMB_PARTICIP_CT_V1);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p>participation_continuity_class=" + IntegerToString(st.participation_continuity_class) + " · streak_bars=" + IntegerToString((long)st.participation_streak_bars) + "</p></section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s36\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">36</span> Governance vitality restoration</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Vitality V2: respiration, decay vs restoration energy.</p>\n<table><thead><tr><th>metric</th><th>permille</th><th>vitality graph</th></tr></thead><tbody>\n");
   GovGmbRenderV1_RowPm(html, "operational_life_score_pm", st.operational_life_score_pm);
   GovGmbRenderV1_RowPm(html, "vitality_restoration_pm", st.vitality_restoration_pm);
   GovGmbRenderV1_RowPm(html, "vitality_decay_pm", st.vitality_decay_pm);
   GovGmbRenderV1_RowPm(html, "adaptive_recovery_energy_pm", st.adaptive_recovery_energy_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table><p>vitality_v2_class=" + IntegerToString(st.vitality_v2_class) + "</p></section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s37\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">37</span> Anti-starvation governance</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">When protection pressure suffocates operational continuity.</p>\n<table><thead><tr><th>metric</th><th>permille</th><th>starvation pressure</th></tr></thead><tbody>\n");
   GovGmbRenderV1_RowPm(html, "participation_suffocation_pm", st.participation_suffocation_pm);
   GovGmbRenderV1_RowPm(html, "governance_overprotection_pm", st.governance_overprotection_pm);
   GovGmbRenderV1_RowPm(html, "starvation_density_pm", st.starvation_density_pm);
   GovGmbRenderV1_RowPm(html, "adaptive_activity_absence_pm", st.adaptive_activity_absence_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table><p>anti_starvation_class=" + IntegerToString(st.anti_starvation_class) + "</p></section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s38\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">38</span> Ecology restoration</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Diversity restoration vs monoculture decay; ecosystem breathing.</p>\n<table><thead><tr><th>metric</th><th>permille</th><th>ecology map</th></tr></thead><tbody>\n");
   GovGmbRenderV1_RowPm(html, "ecology_revival_probability_pm", st.ecology_revival_probability_pm);
   GovGmbRenderV1_RowPm(html, "diversity_restoration_pm", st.diversity_restoration_pm);
   GovGmbRenderV1_RowPm(html, "monoculture_decay_pm", st.monoculture_decay_pm);
   GovGmbRenderV1_RowPm(html, "ecosystem_breathing_rate_pm", st.ecosystem_breathing_rate_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s39\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">39</span> Governance life restoration</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Adaptive life probability vs restoration cycle and post-survival vitality.</p>\n<table><thead><tr><th>metric</th><th>permille</th><th>life timeline</th></tr></thead><tbody>\n");
   GovGmbRenderV1_RowPm(html, "adaptive_life_probability_track_pm", st.adaptive_life_probability_track_pm);
   GovGmbRenderV1_RowPm(html, "governance_restoration_cycle_pm", st.governance_restoration_cycle_pm);
   GovGmbRenderV1_RowPm(html, "ecosystem_awakeness_pm", st.ecosystem_awakeness_pm);
   GovGmbRenderV1_RowPm(html, "post_survival_vitality_pm", st.post_survival_vitality_pm);
   GovGmbRenderV1_RowPm(html, "restoration_stability_pm", st.restoration_stability_pm);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></section>\n");
}

#endif // __AURUM_GOV_GMB_RENDERER_V1_MQH__
