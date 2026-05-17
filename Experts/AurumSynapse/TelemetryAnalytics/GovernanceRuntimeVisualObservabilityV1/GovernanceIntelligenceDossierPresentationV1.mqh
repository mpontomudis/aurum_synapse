//+------------------------------------------------------------------+
//| GovernanceIntelligenceDossierPresentationV1.mqh                 |
//| Institutional governance intelligence dossier (HTML fragments)   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_INTEL_DOSSIER_PRESENT_V1_MQH__
#define __AURUM_GOV_INTEL_DOSSIER_PRESENT_V1_MQH__

#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionDatasetV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionExportV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyToxicityAnalyticsV1.mqh"
#include "../GovernancePositionLineageIntelligenceV1/GovernancePositionLineageRegistryV1.mqh"
#include "../GovernanceRuntimeStrategyTaggingV1/GovernanceRuntimeStrategyTaggingModuleV1.mqh"
#include "GovernanceRuntimeVisualHtmlWriterV1.mqh"
#include "GovernanceRuntimeVisualDatasetV1.mqh"
#include "GovernanceRuntimeVisualDashboardBuilderV1.mqh"
#include "GovernanceBacktestMetadataV1.mqh"
#include "GovernanceRuntimeReportRegistryV1.mqh"
#include "GovernanceBacktestInputSnapshotV1.mqh"

inline string GovIntelDossierV1_LetterFromPF_DD(const double pf, const double dd)
{
   if(pf >= 1.55 && dd < 12.0)
      return "A";
   if(pf >= 1.25 && dd < 18.0)
      return "B";
   if(pf >= 1.05 && dd < 28.0)
      return "C";
   if(pf >= 0.95 && dd < 40.0)
      return "D";
   return "F";
}

inline string GovIntelDossierV1_LetterFromAvgTox(const int avgtox)
{
   if(avgtox <= 280)
      return "A";
   if(avgtox <= 420)
      return "B";
   if(avgtox <= 560)
      return "C";
   if(avgtox <= 700)
      return "D";
   return "F";
}

inline string GovIntelDossierV1_ProdReadiness(const int surv, const string stab, const double pf, const double dd)
{
   if(surv >= 82 && stab == "STABLE" && pf >= 1.45 && dd < 14.0)
      return "INSTITUTIONAL_READY";
   if(surv >= 72 && stab == "STABLE" && pf >= 1.2 && dd < 22.0)
      return "PRODUCTION_CANDIDATE";
   if(surv >= 58 && stab != "UNSTABLE" && pf >= 1.05 && dd < 32.0)
      return "CONTROLLED_LIVE_TEST";
   if(surv >= 42 && dd < 45.0)
      return "LIMITED_DEPLOYMENT";
   if(pf < 0.98 || dd > 48.0 || stab == "UNSTABLE")
      return "RESEARCH_ONLY";
   return "EXPERIMENTAL";
}

inline string GovIntelDossierV1_FinalVerdictEnum(const string readiness)
{
   if(readiness == "INSTITUTIONAL_READY" || readiness == "PRODUCTION_CANDIDATE")
      return readiness;
   if(readiness == "CONTROLLED_LIVE_TEST")
      return "CONTROLLED_LIVE_TEST";
   if(readiness == "LIMITED_DEPLOYMENT")
      return "LIMITED_DEPLOYMENT";
   if(readiness == "RESEARCH_ONLY")
      return "RESEARCH_ONLY";
   return "EXPERIMENTAL";
}

inline void GovIntelDossierV1_AppendExecutive(const string sym,
                                             const ENUM_TIMEFRAMES tf,
                                             const string report_ts,
                                             const SGovRuntimeTaggingModuleV1 &mod,
                                             const SGovLineageRegistryStoreV1 &lin,
                                             SGovStratAttribSummaryV1 &sum,
                                             const SGovVisualExecSummaryV1 &ex,
                                             const SGovBacktestTradeStatsV1 &ts,
                                             string &html)
{
   for(int z = 0; z < GOV_SATTR_STRAT_COUNT_V1; z++)
      GovStratToxV1_Score(z, sum, sum.tox[z]);
   const int wr = (ex.total_trades > 0) ? (int)((100L * (long)ex.profit_trades) / (long)ex.total_trades) : 0;
   const int avgtox = GovRuntimeVisualDashV1_AvgToxicityScore(sum);
   const int surv = GovRuntimeVisualDashV1_SurvivabilityScore(ex, sum);
   const string stab = GovRuntimeVisualDashV1_StabilityClass(ex, sum);
   const string gov_letter = GovIntelDossierV1_LetterFromPF_DD(ex.profit_factor, ex.balance_dd_rel_pct);
   const string tox_letter = GovIntelDossierV1_LetterFromAvgTox(avgtox);
   string stab_letter = "C";
   if(stab == "STABLE")
      stab_letter = "A";
   else if(stab == "BORDERLINE")
      stab_letter = "C";
   else if(stab == "UNSTABLE")
      stab_letter = "F";
   const string readiness = GovIntelDossierV1_ProdReadiness(surv, stab, ex.profit_factor, ex.balance_dd_rel_pct);
   int dom_fail = -1;
   int max_tox = -1;
   int dom_win = -1;
   long max_net = LONG_MIN;
   int total_tr = 0;
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      total_tr += sum.bd.by_strat[i].trades;
      if(sum.bd.by_strat[i].trades > 0 && sum.tox[i].score_0_1000 > max_tox) {
         max_tox = sum.tox[i].score_0_1000;
         dom_fail = i;
      }
      const long net = sum.bd.by_strat[i].gross_win_cents - sum.bd.by_strat[i].gross_loss_cents;
      if(sum.bd.by_strat[i].trades > 0 && net > max_net) {
         max_net = net;
         dom_win = i;
      }
   }
   string dom_fail_lab = "N_A";
   if(dom_fail >= 0)
      dom_fail_lab = GovStratExpV1_StratLabel(dom_fail);
   string dom_win_lab = "N_A";
   if(dom_win >= 0 && max_net > LONG_MIN)
      dom_win_lab = GovStratExpV1_StratLabel(dom_win);

   string alert_html = "";
   if(ex.balance_dd_rel_pct > 32.0)
      alert_html += "<div class=\"gov-banner gov-banner-crit\"><span class=\"gov-banner-tag\">CRITICAL</span> Drawdown telemetry exceeds institutional comfort band (&gt;32% rel).</div>\n";
   if(avgtox > 620)
      alert_html += "<div class=\"gov-banner gov-banner-crit\"><span class=\"gov-banner-tag\">TOXICITY</span> Mean strategy toxicity elevated; ecology re-weighting advised.</div>\n";
   if(lin.tel.overflow_events > 0)
      alert_html += "<div class=\"gov-banner gov-banner-warn\"><span class=\"gov-banner-tag\">REGISTRY</span> Lineage ring pressure detected (overflow_events=" + IntegerToString(lin.tel.overflow_events) + ").</div>\n";
   if(ex.valid == 0)
      alert_html += "<div class=\"gov-banner gov-banner-warn\"><span class=\"gov-banner-tag\">CONFIDENCE</span> Tester statistics unavailable; performance grades are chart-only proxies.</div>\n";
   if(StringLen(alert_html) <= 0)
      alert_html = "<div class=\"gov-banner gov-banner-ok\"><span class=\"gov-banner-tag\">CLEAR</span> No executive-tier automated alerts for this snapshot.</div>\n";

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s1\" class=\"gov-intel-sec gov-hero-sec\">\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-hero-grid\">\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-hero-copy\"><p class=\"gov-kicker\">Aurum Synapse · Governance intelligence layer</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<h2><span class=\"gov-sec-num\">01</span> Executive governance summary</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Autonomous dossier emission synthesizes execution telemetry, strategy ecology, lineage propagation, and breach classifiers into a single oversight narrative. Scope: " +
                                         GovRuntimeVisualHtmlW1_Escape(sym) + " · " + GovRuntimeVisualHtmlW1_Escape(GovBacktestMetaV1_PeriodStr(tf)) + " · export " +
                                         GovRuntimeVisualHtmlW1_Escape(report_ts) + ".</p>\n");
   if(g_gov_report_export_ctx_v1.valid != 0) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<details class=\"gov-run-meta\"><summary>Library run identifiers</summary><table class=\"doss-meta\"><tbody>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>RUN ID</td><td class=\"mono\">" + GovRuntimeVisualHtmlW1_Escape(g_gov_report_export_ctx_v1.report_core_id) + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>RUN number</td><td class=\"mono\">" + GovRuntimeVisualHtmlW1_Escape(g_gov_report_export_ctx_v1.run_label) + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Previous run</td><td class=\"mono\">" + GovRuntimeVisualHtmlW1_Escape(StringLen(g_gov_report_export_ctx_v1.prev_report_id) > 0 ? g_gov_report_export_ctx_v1.prev_report_id : "N_A") + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Baseline run</td><td class=\"mono\">" + GovRuntimeVisualHtmlW1_Escape(StringLen(g_gov_report_export_ctx_v1.baseline_report_id) > 0 ? g_gov_report_export_ctx_v1.baseline_report_id : "N_A") + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Best historical PF (same symbol/TF)</td><td class=\"mono\">" + GovRuntimeVisualHtmlW1_Escape(StringLen(g_gov_report_export_ctx_v1.best_pf_report_id) > 0 ? g_gov_report_export_ctx_v1.best_pf_report_id : "N_A") + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Safest historical DD (same symbol/TF)</td><td class=\"mono\">" + GovRuntimeVisualHtmlW1_Escape(StringLen(g_gov_report_export_ctx_v1.safest_dd_report_id) > 0 ? g_gov_report_export_ctx_v1.safest_dd_report_id : "N_A") + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Most profitable run (same symbol/TF)</td><td class=\"mono\">" + GovRuntimeVisualHtmlW1_Escape(StringLen(g_gov_report_export_ctx_v1.richest_report_id) > 0 ? g_gov_report_export_ctx_v1.richest_report_id : "N_A") + "</td></tr>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></details>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-risk-strip\"><span class=\"gov-pill gov-pill-gold\">Governance " + gov_letter + "</span>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<span class=\"gov-pill gov-pill-red\">Toxicity " + tox_letter + "</span>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<span class=\"gov-pill gov-pill-green\">Stability " + stab_letter + "</span>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<span class=\"gov-pill gov-pill-blue\">Readiness " + GovRuntimeVisualHtmlW1_Escape(readiness) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-micro\">Telemetry confidence: " + ((ex.valid != 0) ? "HIGH (tester statistics bound)" : "DEGRADED (non-tester export)") +
                                         " · Bridge rows=" + IntegerToString(mod.bridge.total) + " · Lineage roots=" + IntegerToString(lin.tel.total_roots) + "</p></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-hero-metrics\">\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-metric-card\"><label>Net profit</label><strong data-metric=\"np\">" + DoubleToString(ex.net_profit, 2) + "</strong></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-metric-card\"><label>Profit factor</label><strong data-metric=\"pf\">" + DoubleToString(ex.profit_factor, 3) + "</strong></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-metric-card\"><label>Winrate</label><strong data-metric=\"wr\">" + IntegerToString(wr) + "%</strong></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-metric-card gov-metric-warn\"><label>Drawdown (bal)</label><strong data-metric=\"dd\">" + DoubleToString(ex.balance_dd_rel_pct, 2) + "%</strong></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-metric-card\"><label>Survivability score</label><strong class=\"gov-accent-green\">" + IntegerToString(surv) + "</strong><div class=\"gov-prog\"><i style=\"width:" + IntegerToString(surv) + "%\"></i></div></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-metric-card\"><label>Recovery factor</label><strong>" + DoubleToString(ex.recovery_factor, 3) + "</strong></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</div></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-banner-stack\">" + alert_html + "</div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-grid-4\">\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-intel-card\"><h3>Dominant failure ecology</h3><p>" + GovRuntimeVisualHtmlW1_Escape(dom_fail_lab) + "</p><span class=\"gov-sev sev-high\">Attribution-weighted toxicity peak</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-intel-card\"><h3>Dominant winning ecology</h3><p>" + GovRuntimeVisualHtmlW1_Escape(dom_win_lab) + "</p><span class=\"gov-sev sev-info\">Largest net cent contribution</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-intel-card\"><h3>Ecology mass concentration</h3><p>" + ((total_tr > 0 && dom_fail >= 0 && sum.bd.by_strat[dom_fail].trades > 0) ?
                                                                                                                           IntegerToString((int)(100L * (long)sum.bd.by_strat[dom_fail].trades / (long)total_tr)) : "0") +
                                         "% peak strategy load</p><span class=\"gov-sev sev-warn\">Solo dominance risk if &gt;35%</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-intel-card\"><h3>Strategic snapshot</h3><ul class=\"gov-bullet\">\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<li>Stability class <code>" + GovRuntimeVisualHtmlW1_Escape(stab) + "</code> from DD × toxicity coupling.</li>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<li>Expectancy telemetry " + DoubleToString(ts.expectancy, 4) + (ex.valid != 0 ? " (tester-bound)" : " (n/a)") + ".</li>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<li>Consensus diagnostics in section 06 correlate multi-strategy overlap via regime centroids.</li>\n</ul></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</div></section>\n");
}

inline void GovIntelDossierV1_AppendConsensusIntel(SGovStratAttribSummaryV1 &sum, string &html)
{
   for(int z = 0; z < GOV_SATTR_STRAT_COUNT_V1; z++)
      GovStratToxV1_Score(z, sum, sum.tox[z]);
   int total_tr = 0;
   for(int t = 0; t < GOV_SATTR_STRAT_COUNT_V1; t++)
      total_tr += sum.bd.by_strat[t].trades;
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s6\" class=\"gov-intel-sec\">\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<h2><span class=\"gov-sec-num\">06</span> Consensus engine intelligence</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Participation lattice ranks each strategy by traded mass, regime concentration, and toxicity coupling. High concentration with elevated toxicity flags false-consensus / solo-entry risk.</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table id=\"tblConsensus\" data-sort-col=\"-1\" data-sort-dir=\"asc\"><thead><tr>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblConsensus',0)\">Strategy</th><th onclick=\"govSort('tblConsensus',1)\">Trades</th><th onclick=\"govSort('tblConsensus',2)\">Mass %</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblConsensus',3)\">Regime centroid ¢</th><th onclick=\"govSort('tblConsensus',4)\">Toxicity</th><th onclick=\"govSort('tblConsensus',5)\">Conflict flag</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tr></thead><tbody>\n");
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      const SGovStratAttribStatsV1 st = sum.bd.by_strat[i];
      long best_r = 0;
      int br = 0;
      for(int r = 0; r < GOV_SATTR_REGIME_COUNT_V1; r++) {
         const long v = sum.cross_strat_regime_cents[i][r];
         if(MathAbs(v) > MathAbs(best_r)) {
            best_r = v;
            br = r;
         }
      }
      const int mass_pct = (total_tr > 0 && st.trades > 0) ? (int)(100L * (long)st.trades / (long)total_tr) : 0;
      string flag = "NEUTRAL";
      if(st.trades > 0 && mass_pct > 38 && sum.tox[i].score_0_1000 > 520)
         flag = "TOXIC_SOLO";
      else if(st.trades > 0 && mass_pct > 32 && (double)st.pf_milli < 950.0)
         flag = "FALSE_CONSENSUS";
      else if(st.trades > 0 && sum.tox[i].regime_mismatch > 420)
         flag = "REGIME_CONFLICT";
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(i)) + "</td><td>" + IntegerToString(st.trades) + "</td><td>" + IntegerToString(mass_pct) + "</td><td>" +
                                         IntegerToString((int)best_r) + " @" + GovRuntimeVisualHtmlW1_Escape(GovStratTagV1_RegimeCode(br)) + "</td><td>" + IntegerToString(sum.tox[i].score_0_1000) + "</td><td><span class=\"gov-flag\">" +
                                         GovRuntimeVisualHtmlW1_Escape(flag) + "</span></td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<h3 class=\"gov-h3\">Strategy × regime agreement heatmap (attributed ¢)</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-scroll-x\"><table class=\"gov-heat-grid\"><thead><tr><th>Strategy</th>\n");
   for(int r = 0; r < GOV_SATTR_REGIME_COUNT_V1; r++)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<th>" + GovRuntimeVisualHtmlW1_Escape(GovStratTagV1_RegimeCode(r)) + "</th>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tr></thead><tbody>\n");
   for(int s = 0; s < GOV_SATTR_STRAT_COUNT_V1; s++) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(s)) + "</td>\n");
      for(int r = 0; r < GOV_SATTR_REGIME_COUNT_V1; r++) {
         const long v = sum.cross_strat_regime_cents[s][r];
         string cls = "heat-zero";
         if(v > 0)
            cls = "heat-pos";
         if(v < 0)
            cls = "heat-neg";
         GovRuntimeVisualHtmlW1_AppendLf(html, "<td class=\"" + cls + "\">" + IntegerToString((int)v) + "</td>\n");
      }
      GovRuntimeVisualHtmlW1_AppendLf(html, "</tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-note\">Heatmap cells are attributed cent notionals per regime axis (telemetry-bound, not broker cash).</p></section>\n");
}

inline void GovIntelDossierV1_AppendSignalQualityIntel(const SGovStratAttribSummaryV1 &sum, const SGovVisualExecSummaryV1 &ex, string &html)
{
   const int q = sum.bd.exec.quality_score_x1000;
   const int slip = sum.bd.exec.slip_proxy_ticks;
   const int ree = sum.bd.exec.reentry_count;
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s7\" class=\"gov-intel-sec\">\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<h2><span class=\"gov-sec-num\">07</span> Signal quality intelligence</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Quality stack aggregates bridge-level execution proxies: composite quality score, re-entry pressure, and synthetic slippage ticks.</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-grid-3\">\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-intel-card\"><h3>Composite quality</h3><p class=\"gov-stat\">" + IntegerToString(q) + " <span class=\"gov-unit\">milli-scale index</span></p><div class=\"gov-prog gov-prog-blue\"><i style=\"width:" +
                                         IntegerToString(GovClampInt32(q / 10, 0, 100)) + "%\"></i></div></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-intel-card\"><h3>Re-entry density</h3><p class=\"gov-stat\">" + IntegerToString(ree) + "</p><span class=\"gov-sev sev-warn\">Elevated re-entry correlates with microstructure churn.</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-intel-card\"><h3>Slippage proxy</h3><p class=\"gov-stat\">" + IntegerToString(slip) + " ticks</p><span class=\"gov-sev sev-info\">Synthetic bridge estimate; not exchange FIX.</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</div>\n");
   const double fpp = (ex.total_trades > 0) ? ((double)ree / (double)ex.total_trades) : 0.0;
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table class=\"gov-table-sub\"><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>False-positive proxy</td><td>re-entry / trades = " + DoubleToString(fpp, 4) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table><p class=\"gov-note\">Accepted vs rejected signal ledger requires deal-level hook expansion; field above is governance proxy only.</p></section>\n");
}

inline void GovIntelDossierV1_AppendRegimeCompatMatrix(const SGovStratAttribSummaryV1 &sum, string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<h3 class=\"gov-h3\">Strategy–regime compatibility matrix (governance index)</h3>\n<div class=\"gov-scroll-x\"><table class=\"gov-heat-grid\"><thead><tr><th>Strategy</th>\n");
   for(int r = 0; r < GOV_SATTR_REGIME_COUNT_V1; r++)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<th>" + GovRuntimeVisualHtmlW1_Escape(GovStratTagV1_RegimeCode(r)) + "</th>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tr></thead><tbody>\n");
   for(int s = 0; s < GOV_SATTR_STRAT_COUNT_V1; s++) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(s)) + "</td>\n");
      for(int r = 0; r < GOV_SATTR_REGIME_COUNT_V1; r++) {
         const int c = sum.compat_regime[s][r];
         GovRuntimeVisualHtmlW1_AppendLf(html, "<td class=\"heat-compat\">" + IntegerToString(c) + "</td>\n");
      }
      GovRuntimeVisualHtmlW1_AppendLf(html, "</tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");
}

inline void GovIntelDossierV1_AppendLineageMutationIntel(const SGovLineageRegistryStoreV1 &lin, string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-grid-3 gov-purple-row\">\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-intel-card gov-card-purple\"><h3>Root lineage events</h3><p class=\"gov-stat\">" + IntegerToString(lin.tel.total_roots) + "</p></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-intel-card gov-card-purple\"><h3>Child / mutation propagation</h3><p class=\"gov-stat\">" + IntegerToString(lin.tel.total_children) + " children · " + IntegerToString(lin.mut_count) + " mutations logged</p></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-intel-card gov-card-purple\"><h3>Recovery escalations</h3><p class=\"gov-stat\">" + IntegerToString(lin.tel.recoveries) + "</p><span class=\"gov-sev sev-warn\">Hedges " + IntegerToString(lin.tel.hedges) + " · scale-in " + IntegerToString(lin.tel.scale_ins) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-note\">Purple lane encodes mutation intelligence (lifecycle graph follows). Toxic propagation inferred when recovery counts rise with elevated mean toxicity in section 12.</p>\n");
}

inline void GovIntelDossierV1_AppendForensicsShellOpen(string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s13\" class=\"gov-intel-sec gov-forensic\">\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<h2><span class=\"gov-sec-num\">13</span> Failure forensics & cascade intelligence</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Forensic plane reconstructs governance-time ordering: lineage recovery genealogy, replay slices, and RUN-vs-RUN deltas. Pair with section 11 breach cards for severity triage.</p>\n");
}

inline void GovIntelDossierV1_AppendForensicsShellClose(string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");
}

inline void GovIntelDossierV1_AppendGovernanceConfigIntro(string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Configuration lattice captures sizing, risk envelopes, activation matrix, and reproducible inputs. Severity bars encode nominal distance to institutional defaults.</p>\n");
}

inline void GovIntelDossierV1_AppendKvLensCards(string &html)
{
   int c_lot = 0;
   int c_sess = 0;
   int c_tp = 0;
   int c_html = 0;
   int c_cons = 0;
   if(StringLen(g_gov_backtest_input_kv_v1) > 0) {
      c_lot = (StringFind(g_gov_backtest_input_kv_v1, "Lot") >= 0 || StringFind(g_gov_backtest_input_kv_v1, "lot") >= 0 || StringFind(g_gov_backtest_input_kv_v1, "Volume") >= 0) ? 1 : 0;
      c_sess = (StringFind(g_gov_backtest_input_kv_v1, "Session") >= 0 || StringFind(g_gov_backtest_input_kv_v1, "sess") >= 0) ? 1 : 0;
      c_tp = (StringFind(g_gov_backtest_input_kv_v1, "TP") >= 0 || StringFind(g_gov_backtest_input_kv_v1, "SL") >= 0) ? 1 : 0;
      c_html = (StringFind(g_gov_backtest_input_kv_v1, "Html") >= 0 || StringFind(g_gov_backtest_input_kv_v1, "HTML") >= 0 || StringFind(g_gov_backtest_input_kv_v1, "governance") >= 0) ? 1 : 0;
      c_cons = (StringFind(g_gov_backtest_input_kv_v1, "Consensus") >= 0 || StringFind(g_gov_backtest_input_kv_v1, "consensus") >= 0) ? 1 : 0;
   }
   string lot_txt = (c_lot != 0) ? "KV tokens detected (lot / volume axis)." : "No explicit lot tokens in KV export.";
   string lot_cls = (c_lot != 0) ? "ok" : "warn";
   string lot_w = (c_lot != 0) ? "88" : "40";
   string sess_txt = (c_sess != 0) ? "Session controls referenced in KV." : "Session axis not echoed in KV (verify harness).";
   string sess_cls = (c_sess != 0) ? "ok" : "warn";
   string sess_w = (c_sess != 0) ? "80" : "45";
   string tp_txt = (c_tp != 0) ? "Bracket parameters referenced." : "No TP/SL tokens captured in KV snapshot.";
   string tp_cls = (c_tp != 0) ? "ok" : "warn";
   string tp_w = (c_tp != 0) ? "82" : "50";
   string ch_txt = (c_cons != 0) ? "present" : "absent";
   string h_txt = (c_html != 0) ? "present" : "absent";
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-grid-4\">\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-intel-card\"><h3>Lot sizing governance</h3><p>" + GovRuntimeVisualHtmlW1_Escape(lot_txt) + "</p><div class=\"gov-sev-bar\"><i class=\"gov-sev-" + lot_cls + "\" style=\"width:" + lot_w + "%\"></i></div></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-intel-card\"><h3>Session governance</h3><p>" + GovRuntimeVisualHtmlW1_Escape(sess_txt) + "</p><div class=\"gov-sev-bar\"><i class=\"gov-sev-" + sess_cls + "\" style=\"width:" + sess_w + "%\"></i></div></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-intel-card\"><h3>TP / SL governance</h3><p>" + GovRuntimeVisualHtmlW1_Escape(tp_txt) + "</p><div class=\"gov-sev-bar\"><i class=\"gov-sev-" + tp_cls + "\" style=\"width:" + tp_w + "%\"></i></div></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-intel-card\"><h3>Consensus / HTML emission</h3><p>Consensus KV " + ch_txt + " · HTML telemetry " + h_txt + ".</p><div class=\"gov-sev-bar\"><i class=\"gov-sev-ok\" style=\"width:70%\"></i></div></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</div>\n");
}

inline void GovIntelDossierV1_AppendPerformanceSupplement(const SGovVisualExecSummaryV1 &ex,
                                                         const SGovStratAttribSummaryV1 &sum,
                                                         const SGovBacktestTradeStatsV1 &ts,
                                                         string &html)
{
   double ini = 0;
   if(ts.valid != 0)
      ini = TesterStatistics(STAT_INITIAL_DEPOSIT);
   const double cap_eff = (ini > 1.0) ? (ex.net_profit / ini) * 100.0 : 0.0;
   const double gp = MathAbs(ex.gross_profit) + 0.0001;
   const double prof_eff = ex.net_profit / gp * 100.0;
   long hold_num = 0;
   int hold_den = 0;
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      if(sum.bd.by_strat[i].trades <= 0)
         continue;
      hold_num += (long)sum.bd.by_strat[i].avg_hold_bars_x100 * (long)sum.bd.by_strat[i].trades;
      hold_den += sum.bd.by_strat[i].trades;
   }
   const double avg_hold = (hold_den > 0) ? ((double)hold_num / (double)hold_den / 100.0) : 0.0;
   const int dir_bias = (ex.total_trades > 0) ? (int)(100L * (long)ex.long_trades / (long)ex.total_trades) : 0;
   GovRuntimeVisualHtmlW1_AppendLf(html, "<h3 class=\"gov-h3\">Capital & execution efficiency</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-grid-4\">\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-intel-card\"><h3>Capital efficiency</h3><p class=\"gov-stat\">" + DoubleToString(cap_eff, 2) + "%</p><span class=\"gov-note\">Net / initial (tester only).</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-intel-card\"><h3>Profitability efficiency</h3><p class=\"gov-stat\">" + DoubleToString(prof_eff, 1) + "%</p><span class=\"gov-note\">Net over gross profit envelope.</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-intel-card\"><h3>Directional bias</h3><p class=\"gov-stat\">" + IntegerToString(dir_bias) + "% long</p><span class=\"gov-note\">Remainder short book.</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-intel-card\"><h3>Avg hold (bars)</h3><p class=\"gov-stat\">" + DoubleToString(avg_hold, 2) + "</p><span class=\"gov-note\">Trade-weighted ecology mean.</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-interpret\"><span class=\"gov-interpret-label\">Interpretation</span> Volatility-adjusted return proxy leans on Sharpe " + DoubleToString(ts.sharpe, 3) +
                                         "; combine with regime survivability in section 08 before scaling capital.</p>\n");
}

inline void GovIntelDossierV1_AppendFinalVerdict(const SGovVisualExecSummaryV1 &ex, SGovStratAttribSummaryV1 &sum, string &html)
{
   for(int z = 0; z < GOV_SATTR_STRAT_COUNT_V1; z++)
      GovStratToxV1_Score(z, sum, sum.tox[z]);
   const int avgtox = GovRuntimeVisualDashV1_AvgToxicityScore(sum);
   const int surv = GovRuntimeVisualDashV1_SurvivabilityScore(ex, sum);
   const string stab = GovRuntimeVisualDashV1_StabilityClass(ex, sum);
   const string gov_letter = GovIntelDossierV1_LetterFromPF_DD(ex.profit_factor, ex.balance_dd_rel_pct);
   const string tox_letter = GovIntelDossierV1_LetterFromAvgTox(avgtox);
   string stab_letter = "C";
   if(stab == "STABLE")
      stab_letter = "A";
   else if(stab == "BORDERLINE")
      stab_letter = "C";
   else if(stab == "UNSTABLE")
      stab_letter = "F";
   const string readiness = GovIntelDossierV1_ProdReadiness(surv, stab, ex.profit_factor, ex.balance_dd_rel_pct);
   const string verdict = GovIntelDossierV1_FinalVerdictEnum(readiness);
   string cap_suit = "RETAIL_SCALE";
   if(ex.net_profit > 5000.0 && ex.balance_dd_rel_pct < 18.0)
      cap_suit = "INSTITUTIONAL_SCALE";
   else if(ex.net_profit > 1500.0)
      cap_suit = "SMB_PROP";
   string inst_suit = (verdict == "INSTITUTIONAL_READY" || verdict == "PRODUCTION_CANDIDATE") ? "PASS" : "CONDITIONAL";
   string deploy = (stab == "UNSTABLE") ? "SANDBOX_ONLY" : "SELECTIVE_SYMBOLS";
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s15\" class=\"gov-intel-sec gov-verdict\">\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<h2><span class=\"gov-sec-num\">15</span> Final governance verdict</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-verdict-core\"><div class=\"gov-verdict-stamp\">" + GovRuntimeVisualHtmlW1_Escape(verdict) + "</div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table class=\"gov-verdict-grid\"><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Survivability grade</td><td>" + IntegerToString(surv) + " / 100</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Governance grade</td><td>" + gov_letter + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Toxicity grade</td><td>" + tox_letter + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Stability grade</td><td>" + stab_letter + " (" + GovRuntimeVisualHtmlW1_Escape(stab) + ")</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Production readiness</td><td>" + GovRuntimeVisualHtmlW1_Escape(readiness) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Capital suitability</td><td>" + cap_suit + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Institutional suitability</td><td>" + inst_suit + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Deployment scope</td><td>" + deploy + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Recommended environment</td><td>" + ((MQLInfoInteger(MQL_TESTER) != 0) ? "FORWARD_VALIDATION_AFTER_TESTER" : "LIVE_OBSERVATION_WITH_KILL_SWITCH") + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-note\">Verdict is rules-engine output from survivability, stability class, PF/DD telemetry, and mean toxicity; not investment advice.</p></section>\n");
}

#endif // __AURUM_GOV_INTEL_DOSSIER_PRESENT_V1_MQH__
