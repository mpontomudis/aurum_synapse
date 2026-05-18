//+------------------------------------------------------------------+
//| GovernanceRestrictionForensicsHtmlV1.mqh                       |
//| PHASE 23.5 — dossier §24 (forensic observability)                |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RF_HTML_V1_MQH__
#define __AURUM_GOV_RF_HTML_V1_MQH__

#include "../GovernanceRuntimeVisualObservabilityV1/GovernanceRuntimeVisualHtmlWriterV1.mqh"
#include "GovernanceRestrictionForensicsEngineV1.mqh"
#include "../GovernanceEcologyEngineV1/GovernanceEcologyDatasetV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionExportV1.mqh"

inline string GovRfHtmlV1_RcRankLabel(const int id)
{
   switch(id) {
   case 1: return "RiskManager / CanTrade() denials & post-consensus risk halt";
   case 2: return "Consensus strictness (failures vs attempts)";
   case 3: return "Ecology suppression pressure (clears / throttles)";
   case 4: return "Equity vs balance DD divergence telemetry";
   case 5: return "Regime churn & split-brain vote collisions";
   case 6: return "Quality / requirement gating density";
   default: return "Unknown pressure";
   }
}

inline void GovRfHtmlV1_AppendSection24(string &html, SGovRfStoreV1 &rf, const SGovEcologyStoreV1 &eco)
{
   if(!rf.enabled) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s24\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">24</span> Governance restriction forensics</h2>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-note\">Phase 23.5 telemetry is disabled (set <code>InpGovPhase235RestrictionForensics</code> true on the EA for live accumulation).</p></section>\n");
      return;
   }

   GovRfEngV1_RecomputeRootCauseVector(rf);

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s24\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">24</span> Governance restriction forensics</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Phase 23.5 explains starvation and over-suppression: consensus strictness, RiskManager denials, DD telemetry divergence, ecology pressure, regime histograms, and a bounded execution-rejection waterfall — observe-only; no threshold mutation.</p>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s24-1\"><h3 class=\"gov-h3\">24.1 Consensus restriction analysis</h3>\n<table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>consensus_attempts</td><td>" + IntegerToString((long)rf.consensus_attempts) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>consensus_passes</td><td>" + IntegerToString((long)rf.consensus_passes) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>consensus_failures</td><td>" + IntegerToString((long)rf.consensus_failures) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>split_brain_bars</td><td>" + IntegerToString((long)rf.consensus_split_brain_bars) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>last_eff_min_consensus</td><td>" + IntegerToString(rf.last_eff_min_consensus) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s24-2\"><h3 class=\"gov-h3\">24.2 RiskManager blocking diagnostics</h3>\n<table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>cantrade_samples</td><td>" + IntegerToString((long)rf.risk_cantrade_samples) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>cantrade_denies</td><td>" + IntegerToString((long)rf.risk_cantrade_denies) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>deny_dd_lock</td><td>" + IntegerToString((long)rf.risk_deny_dd_lock) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>deny_daily_loss</td><td>" + IntegerToString((long)rf.risk_deny_daily) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>deny_consecutive</td><td>" + IntegerToString((long)rf.risk_deny_consec) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>lost_opportunities_risk_halt</td><td>" + IntegerToString((long)rf.lost_opportunities_risk_halt) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   const double avgdiv = (rf.dd_probe_bars > 0) ? (rf.sum_dd_divergence_pct / (double)rf.dd_probe_bars) : 0.0;
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s24-3\"><h3 class=\"gov-h3\">24.3 DD telemetry anomaly investigation</h3>\n<table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>dd_probe_bars</td><td>" + IntegerToString((long)rf.dd_probe_bars) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>dd_anomaly_bars (heuristic)</td><td>" + IntegerToString((long)rf.dd_anomaly_bars) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>avg_equity_balance_div_pct</td><td>" + DoubleToString(avgdiv, 4) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>max_equity_balance_div_pct</td><td>" + DoubleToString(rf.max_dd_divergence_pct, 4) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s24-4\"><h3 class=\"gov-h3\">24.4 Strategy starvation matrix</h3>\n<table id=\"tblRfStarve\" data-sort-col=\"-1\" data-sort-dir=\"asc\"><thead><tr>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblRfStarve',0)\">Strategy</th><th onclick=\"govSort('tblRfStarve',1)\">Bars since signal</th><th onclick=\"govSort('tblRfStarve',2)\">Peak drought</th></tr></thead><tbody>\n");
   for(int i = 0; i < GOV_RF_STRAT_CT_V1; i++) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(i)) + "</td><td>" + IntegerToString(rf.strat_starve_bars[i]) + "</td><td>" +
                                         IntegerToString((long)rf.strat_starve_peak[i]) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s24-5\"><h3 class=\"gov-h3\">24.5 Regime overfiltering analysis</h3>\n<table><thead><tr><th>eff_min_slot</th><th>bars</th></tr></thead><tbody>\n");
   for(int j = 0; j < 9; j++)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + IntegerToString(j + 1) + "</td><td>" + IntegerToString((long)rf.hist_eff_min_consensus[j]) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table><p class=\"gov-note\">Slot 9 aggregates effective min &gt; 8 (clamped telemetry bucket).</p></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s24-6\"><h3 class=\"gov-h3\">24.6 Ecology suppression pressure</h3>\n<table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>suppress_clears_total</td><td>" + IntegerToString((long)rf.ecology_suppress_clears_total) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>throttle_events_total</td><td>" + IntegerToString((long)rf.ecology_throttle_events_total) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>last_bar_suppress_clears</td><td>" + IntegerToString(eco.last_bar_suppress_clears) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>last_bar_throttle_events</td><td>" + IntegerToString(eco.last_bar_throttle_events) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s24-7\"><h3 class=\"gov-h3\">24.7 Execution rejection waterfall</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p>Stages: 1 open → 2 market → 3 risk_early → 4 time → 5 spread → 6 consensus → 7 quality → 8 requirement → 9 risk_halt → 10 position → 11 allowed.</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table id=\"tblRfFall\" data-sort-col=\"-1\" data-sort-dir=\"asc\"><thead><tr>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblRfFall',0)\">ts</th><th onclick=\"govSort('tblRfFall',1)\">stage</th><th onclick=\"govSort('tblRfFall',2)\">sig_reason</th><th onclick=\"govSort('tblRfFall',3)\">veto</th></tr></thead><tbody>\n");
   const int show = MathMin(48, rf.ring_count);
   for(int k = 0; k < show; k++) {
      const int idx = (rf.ring_wi - 1 - k + GOV_RF_RING_CAP_V1 * 2) % GOV_RF_RING_CAP_V1;
      const SGovRfWaterfallEntryV1 e = rf.ring[idx];
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(TimeToString(e.ts, TIME_DATE | TIME_SECONDS)) + "</td><td>" + IntegerToString(e.stage) + "</td><td>" +
                                         IntegerToString(e.sig_reason) + "</td><td>" + IntegerToString(e.veto_class) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s24-8\"><h3 class=\"gov-h3\">24.8 Governance pressure heatmap (tabular)</h3>\n<table><tbody>\n");
   for(int v = 0; v < GOV_RF_VETO_CLASS_CT_V1; v++)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>veto_" + IntegerToString(v) + "</td><td>" + IntegerToString((long)rf.veto_class_counts[v]) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s24-9\"><h3 class=\"gov-h3\">24.9 Lock persistence & recovery analysis</h3>\n<table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>bars_under_risk_denial</td><td>" + IntegerToString((long)rf.bars_under_risk_denial) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>risk_thaw_bars_accum</td><td>" + IntegerToString(rf.risk_thaw_bars_accum) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s24-10\"><h3 class=\"gov-h3\">24.10 Restriction root-cause summary</h3>\n<ol>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<li><b>Rank 1</b> — " + GovRuntimeVisualHtmlW1_Escape(GovRfHtmlV1_RcRankLabel(rf.last_rc_rank1)) + " <span class=\"gov-note\">(score " +
                                         DoubleToString(rf.last_rc_score1_pm, 1) + ")</span></li>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<li><b>Rank 2</b> — " + GovRuntimeVisualHtmlW1_Escape(GovRfHtmlV1_RcRankLabel(rf.last_rc_rank2)) + " <span class=\"gov-note\">(score " +
                                         DoubleToString(rf.last_rc_score2_pm, 1) + ")</span></li>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<li><b>Rank 3</b> — " + GovRuntimeVisualHtmlW1_Escape(GovRfHtmlV1_RcRankLabel(rf.last_rc_rank3)) + " <span class=\"gov-note\">(score " +
                                         DoubleToString(rf.last_rc_score3_pm, 1) + ")</span></li>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</ol><p class=\"gov-note\">Ranker is heuristic telemetry only — not an optimizer.</p></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");
}

#endif // __AURUM_GOV_RF_HTML_V1_MQH__
