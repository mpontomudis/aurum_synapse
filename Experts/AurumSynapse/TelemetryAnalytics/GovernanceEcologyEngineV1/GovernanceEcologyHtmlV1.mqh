//+------------------------------------------------------------------+
//| GovernanceEcologyHtmlV1.mqh                                     |
//| PHASE 23 — dossier §23 Strategy Ecology Intelligence             |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECOLOGY_HTML_V1_MQH__
#define __AURUM_GOV_ECOLOGY_HTML_V1_MQH__

#include "../GovernanceRuntimeVisualObservabilityV1/GovernanceRuntimeVisualHtmlWriterV1.mqh"
#include "GovernanceEcologyDatasetV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionExportV1.mqh"

inline string GovEcoHtmlV1_StateLabel(const int st)
{
   switch(st) {
   case GOV_ECO_ST_ACTIVE:
      return "ACTIVE";
   case GOV_ECO_ST_SUPPRESSED:
      return "SUPPRESSED";
   case GOV_ECO_ST_PASSIVE:
      return "PASSIVE";
   case GOV_ECO_ST_THROTTLED:
      return "THROTTLED";
   case GOV_ECO_ST_DOMINANT:
      return "DOMINANT";
   case GOV_ECO_ST_RECOVERING:
      return "RECOVERING";
   case GOV_ECO_ST_TOXIC:
      return "TOXIC";
   case GOV_ECO_ST_DISABLED_BY_REGIME:
      return "DISABLED_BY_REGIME";
   default:
      return "UNKNOWN";
   }
}

inline void GovEcoHtmlV1_AppendSection23(string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s23\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">23</span> Strategy ecology intelligence</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Phase 23 activates adaptive participation governance: regime-aware compatibility, toxicity-aware throttling, dominance/diversity telemetry, and dependency co-occurrence — without auto-optimizing parameters or bypassing RiskManager.</p>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s23-1\"><h3 class=\"gov-h3\">23.1 Ecology overview</h3>\n<table class=\"doss-meta\"><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>enabled</td><td>" + (g_gov_ecology_v1.enabled ? "true" : "false") + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>ecology_diversity ‰</td><td>" + IntegerToString(g_gov_ecology_v1.ecology_diversity_score_pm) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>ecology_entropy ‰</td><td>" + IntegerToString(g_gov_ecology_v1.ecology_entropy_score_pm) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>ecology_balance ‰</td><td>" + IntegerToString(g_gov_ecology_v1.ecology_balance_score_pm) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>monoculture_warn</td><td>" + IntegerToString(g_gov_ecology_v1.monoculture_warn) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s23-2\"><h3 class=\"gov-h3\">23.2 Strategy participation matrix</h3>\n<table><thead><tr><th>Strategy</th><th>State</th><th>Participation bars</th><th>Suppression bars</th><th>Throttle bars</th><th>Dominance picks</th></tr></thead><tbody>\n");
   for(int i = 0; i < GOV_ECO_STRAT_COUNT_V1; i++) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(i)) + "</td><td>" +
                                         GovRuntimeVisualHtmlW1_Escape(GovEcoHtmlV1_StateLabel(g_gov_ecology_v1.s[i].part_state)) + "</td><td>" +
                                         IntegerToString((long)g_gov_ecology_v1.s[i].bars_participation) + "</td><td>" +
                                         IntegerToString((long)g_gov_ecology_v1.s[i].bars_suppression) + "</td><td>" +
                                         IntegerToString((long)g_gov_ecology_v1.s[i].bars_throttled) + "</td><td>" +
                                         IntegerToString((long)g_gov_ecology_v1.s[i].dominance_pick_bars) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s23-3\"><h3 class=\"gov-h3\">23.3 Strategy ↔ regime compatibility (telemetry)</h3>\n<table><thead><tr><th>Strategy</th><th>compat ‰</th><th>align hits</th><th>mismatch hits</th></tr></thead><tbody>\n");
   for(int j = 0; j < GOV_ECO_STRAT_COUNT_V1; j++) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(j)) + "</td><td>" +
                                         IntegerToString(g_gov_ecology_v1.s[j].compatibility_score_permille) + "</td><td>" +
                                         IntegerToString((long)g_gov_ecology_v1.s[j].regime_alignment_hits) + "</td><td>" +
                                         IntegerToString((long)g_gov_ecology_v1.s[j].regime_mismatch_hits) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table><p class=\"gov-note\">Preferred sleeves are inferred from Aurum regime labels (trend→TF, sweep→SM, expansion→scalp, etc.).</p></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s23-4\"><h3 class=\"gov-h3\">23.4 Ecology toxicity map</h3>\n<table><thead><tr><th>Strategy</th><th>tox ‰</th><th>pressure ‰</th></tr></thead><tbody>\n");
   for(int t = 0; t < GOV_ECO_STRAT_COUNT_V1; t++) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(t)) + "</td><td>" +
                                         IntegerToString(g_gov_ecology_v1.s[t].toxicity_score_permille) + "</td><td>" +
                                         IntegerToString(g_gov_ecology_v1.s[t].ecology_pressure_pm) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s23-5\"><h3 class=\"gov-h3\">23.5 Strategy suppression analysis</h3>\n<p>Suppression duration (bars) tracked alongside participation; regime-disabled sleeves are tagged DISABLED_BY_REGIME.</p>\n<ul>\n");
   for(int u = 0; u < GOV_ECO_STRAT_COUNT_V1; u++) {
      if(g_gov_ecology_v1.s[u].bars_suppression > 0UL || g_gov_ecology_v1.s[u].part_state == GOV_ECO_ST_SUPPRESSED || g_gov_ecology_v1.s[u].part_state == GOV_ECO_ST_TOXIC) {
         GovRuntimeVisualHtmlW1_AppendLf(html, "<li><b>" + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(u)) + "</b> — " +
                                            GovRuntimeVisualHtmlW1_Escape(GovEcoHtmlV1_StateLabel(g_gov_ecology_v1.s[u].part_state)) + ", suppression_bars=" +
                                            IntegerToString((long)g_gov_ecology_v1.s[u].bars_suppression) + "</li>\n");
      }
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</ul></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s23-6\"><h3 class=\"gov-h3\">23.6 Ecology diversity &amp; entropy</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"barwrap\" title=\"diversity\"><div class=\"bar\" style=\"width:" + IntegerToString(g_gov_ecology_v1.ecology_diversity_score_pm / 10) + "%\"></div></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"barwrap\" title=\"entropy\"><div class=\"bar\" style=\"width:" + IntegerToString(g_gov_ecology_v1.ecology_entropy_score_pm / 10) + "%\"></div></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"barwrap\" title=\"balance\"><div class=\"bar\" style=\"width:" + IntegerToString(g_gov_ecology_v1.ecology_balance_score_pm / 10) + "%\"></div></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s23-7\"><h3 class=\"gov-h3\">23.7 Strategy dependency graph (co-occurrence)</h3>\n<table><thead><tr><th></th>");
   for(int c = 0; c < GOV_ECO_STRAT_COUNT_V1; c++)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<th>" + IntegerToString(c) + "</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tr></thead><tbody>\n");
   for(int r = 0; r < GOV_ECO_STRAT_COUNT_V1; r++) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><th>" + IntegerToString(r) + "</th>");
      for(int c2 = 0; c2 < GOV_ECO_STRAT_COUNT_V1; c2++)
         GovRuntimeVisualHtmlW1_AppendLf(html, "<td>" + IntegerToString((long)g_gov_ecology_v1.cooccur[r][c2]) + "</td>");
      GovRuntimeVisualHtmlW1_AppendLf(html, "</tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table><p class=\"gov-note\">Counts joint non-NONE signal bars before ecology masking (post input + DD recovery preservation).</p></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s23-8\"><h3 class=\"gov-h3\">23.8 Strategy survivability matrix</h3>\n<table><thead><tr><th>Strategy</th><th>surv ‰</th><th>recovery ‰</th><th>health ‰</th></tr></thead><tbody>\n");
   for(int w = 0; w < GOV_ECO_STRAT_COUNT_V1; w++) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(w)) + "</td><td>" +
                                         IntegerToString(g_gov_ecology_v1.s[w].survivability_score_permille) + "</td><td>" +
                                         IntegerToString(g_gov_ecology_v1.s[w].ecology_recovery_pm) + "</td><td>" +
                                         IntegerToString(g_gov_ecology_v1.s[w].ecology_health_pm) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s23-9\"><h3 class=\"gov-h3\">23.9 Dominance &amp; monoculture detection</h3>\n<table><tbody>\n");
   ulong mx = 0;
   int midx = 0;
   ulong sm = 0;
   for(int d = 0; d < GOV_ECO_STRAT_COUNT_V1; d++) {
      sm += g_gov_ecology_v1.s[d].dominance_pick_bars;
      if(g_gov_ecology_v1.s[d].dominance_pick_bars > mx) {
         mx = g_gov_ecology_v1.s[d].dominance_pick_bars;
         midx = d;
      }
   }
   const int share = (sm > 0UL) ? (int)MathMin(1000UL, (1000UL * mx) / sm) : 0;
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Leading strategy</td><td>" + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(midx)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Dominance share ‰</td><td>" + IntegerToString(share) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s23-10\"><h3 class=\"gov-h3\">23.10 Ecology recommendations</h3>\n<ul>\n");
   if(g_gov_ecology_v1.monoculture_warn != 0)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<li>Monoculture risk — one strategy dominates picks; consider widening participation via regime calibration (22A) and sleeve hygiene.</li>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<li>Review strategies with high suppression bars vs alignment hits — indicates regime mismatch persistence.</li>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<li>CSV exports: <code>AurumSynapse/TelemetryAnalytics/Ecology/</code> for offline ecology QA.</li>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</ul></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\"><h3 class=\"gov-h3\">Participation heatmap (month × strategy)</h3>\n<table><thead><tr><th>Strategy</th>");
   for(int mo = 0; mo < 12; mo++)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<th>M" + IntegerToString(mo + 1) + "</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tr></thead><tbody>\n");
   for(int s2 = 0; s2 < GOV_ECO_STRAT_COUNT_V1; s2++) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(s2)) + "</td>");
      for(int mo2 = 0; mo2 < 12; mo2++) {
         const ulong v = g_gov_ecology_v1.s[s2].month_participation_bars[mo2];
         const int heat = (int)MathMin(100UL, v);
         GovRuntimeVisualHtmlW1_AppendLf(html, "<td title=\"bars " + IntegerToString((long)v) + "\">" + IntegerToString(heat) + "</td>");
      }
      GovRuntimeVisualHtmlW1_AppendLf(html, "</tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");
}

#endif // __AURUM_GOV_ECOLOGY_HTML_V1_MQH__
