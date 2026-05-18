//+------------------------------------------------------------------+
//| GovernanceSignalForensicsHtmlV1.mqh                             |
//| PHASE 21 — dossier HTML block (embedded CSS fragment only)       |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SIG_FORENSICS_HTML_V1_MQH__
#define __AURUM_GOV_SIG_FORENSICS_HTML_V1_MQH__

#include "GovernanceSignalForensicsTelemetryV1.mqh"
#include "GovernanceSignalRejectReasonV1.mqh"
#include "GovernanceSignalMonthlyAnalyticsV1.mqh"
#include "GovernanceSignalFilterHeatmapV1.mqh"
#include "GovernanceSignalStrategyActivationV1.mqh"
#include "GovernanceSignalConsensusForensicsV1.mqh"
#include "GovernanceSignalRegimeSuppressionV1.mqh"
#include "../GovernanceStrategyVocabularyV1.mqh"
#include "../GovernanceRuntimeVisualObservabilityV1/GovernanceRuntimeVisualHtmlWriterV1.mqh"

inline string GovSigForensicsHtmlV1_RegimeRowLab(const int ridx)
{
   switch(GovClampInt32(ridx, 0, 3)) {
   case 0:
      return "TRENDING";
   case 1:
      return "RANGING";
   case 2:
      return "VOLATILE";
   default:
      return "CALM";
   }
}

inline void GovSigForensicsHtmlV1_AppendSection(const SGovSignalForensicsTelemetryV1 &t, string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<style>.gov-sigf-mini{font-size:.72rem;color:var(--muted);} .gov-sigf-bar{height:8px;background:#21262d;border-radius:4px;overflow:hidden;margin:4px 0 10px;} .gov-sigf-bar>i{display:block;height:100%;background:linear-gradient(90deg,var(--intel),var(--gold));}</style>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s21\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">21</span> SIGNAL FORENSICS INTELLIGENCE</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Decision observability: deterministic signal lifecycle, monthly activation collapse, filter suppression heatmaps, consensus ecology, and regime starvation — replay-safe integer telemetry only.</p>\n");

   ulong mxrej = 0;
   ulong sumrej = 0;
   int topj = GOV_SIG_REJECT_UNKNOWN;
   for(int j = 0; j < GOV_SIG_REJECT_REASON_COUNT_V1; j++) {
      if(j == GOV_SIG_REJECT_NONE)
         continue;
      sumrej += t.reject_by_reason[j];
      if(t.reject_by_reason[j] > mxrej) {
         mxrej = t.reject_by_reason[j];
         topj = j;
      }
   }
   const int dom_pct = (sumrej > 0) ? (int)(100ULL * mxrej / sumrej) : 0;
   string sev_class = "gov-pill-blue";
   if(dom_pct >= 880)
      sev_class = "gov-pill-red";
   else if(dom_pct >= 700)
      sev_class = "gov-pill-gold";

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"sigf-lifecycle\"><h3 class=\"gov-h3\">1. Signal lifecycle summary</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-sigf-mini\">State hits (saturating): CREATED / FILTERED / REJECTED / ACCEPTED / EXECUTED / CLOSED</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>CREATED</td><td>" + IntegerToString(t.state_hits[GOV_SIG_CREATED]) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>FILTERED</td><td>" + IntegerToString(t.state_hits[GOV_SIG_FILTERED]) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>REJECTED</td><td>" + IntegerToString(t.state_hits[GOV_SIG_REJECTED]) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>ACCEPTED</td><td>" + IntegerToString(t.state_hits[GOV_SIG_ACCEPTED]) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>EXECUTED</td><td>" + IntegerToString(t.state_hits[GOV_SIG_EXECUTED]) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>CLOSED</td><td>" + IntegerToString(t.state_hits[GOV_SIG_CLOSED]) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p><span class=\"gov-pill " + sev_class + "\">Suppression severity: " + IntegerToString(dom_pct) + "% " +
                                         GovRuntimeVisualHtmlW1_Escape(GovSigRejectV1_Label(topj)) + "</span></p></div>\n");

   ulong mxC = 1;
   for(int m = 0; m < GOV_SIG_FORENSICS_MONTH_BUCKETS_V1; m++) {
      if(t.month_created[m] > mxC)
         mxC = t.month_created[m];
   }

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"sigf-monthly\"><h3 class=\"gov-h3\">2. Monthly signal activation</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table id=\"tblSigMonth\" data-sort-col=\"-1\" data-sort-dir=\"asc\"><thead><tr>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblSigMonth',0)\">Month</th><th onclick=\"govSort('tblSigMonth',1)\">Created</th><th onclick=\"govSort('tblSigMonth',2)\">Passed</th><th onclick=\"govSort('tblSigMonth',3)\">Rejected</th><th>Activation</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tr></thead><tbody>\n");
   for(int m = 0; m < GOV_SIG_FORENSICS_MONTH_BUCKETS_V1; m++) {
      const ulong c = t.month_created[m];
      const ulong p = t.month_passed[m];
      const ulong rj = t.month_rejected[m];
      const int pw = (mxC > 0) ? (int)(100ULL * p / mxC) : 0;
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovSigMonthlyV1_AbbrFromIndex0_11(m) + "</td><td>" + IntegerToString(c) + "</td><td>" + IntegerToString(p) + "</td><td>" + IntegerToString(rj) + "</td><td><div class=\"gov-sigf-bar\"><i style=\"width:" + IntegerToString(pw) + "%\"></i></div></td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"sigf-filter\"><h3 class=\"gov-h3\">3. Filter suppression matrix</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table id=\"tblSigRej\" data-sort-col=\"-1\" data-sort-dir=\"asc\"><thead><tr><th onclick=\"govSort('tblSigRej',0)\">Reject axis</th><th onclick=\"govSort('tblSigRej',1)\">Count</th></tr></thead><tbody>\n");
   for(int j = 0; j < GOV_SIG_REJECT_REASON_COUNT_V1; j++) {
      if(j == GOV_SIG_REJECT_NONE)
         continue;
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovSigRejectV1_Label(j)) + "</td><td>" + IntegerToString(t.reject_by_reason[j]) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"sigf-strategy\"><h3 class=\"gov-h3\">4. Strategy activation matrix</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table id=\"tblSigStrat\" data-sort-col=\"-1\" data-sort-dir=\"asc\"><thead><tr>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblSigStrat',0)\">Strategy</th><th onclick=\"govSort('tblSigStrat',1)\">Signals</th><th onclick=\"govSort('tblSigStrat',2)\">Accepted</th><th onclick=\"govSort('tblSigStrat',3)\">Rejected</th><th>Act‰</th><th>Bar</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tr></thead><tbody>\n");
   for(int s = 0; s < GOV_SIG_FORENSICS_STRATEGY_SLOTS_V1; s++) {
      const int pm = GovSigStratActV1_AcceptPermille(t.strat_sig[s], t.strat_acc[s]);
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovStrategyV1_NameFromAxisIndex(s)) + "</td><td>" + IntegerToString(t.strat_sig[s]) + "</td><td>" +
                                         IntegerToString(t.strat_acc[s]) + "</td><td>" + IntegerToString(t.strat_rej[s]) + "</td><td>" + IntegerToString(pm) + "</td><td><div class=\"gov-sigf-bar\"><i style=\"width:" + IntegerToString(pm / 10) + "%\"></i></div></td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   const int cpass = GovSigConsensusV1_PassPermille(t.consensus_pass, t.consensus_fail);
   const int avga = GovSigConsensusV1_AgreeingAvgPermille(t.consensus_agree_sum, t.consensus_agree_samples);

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"sigf-consensus\"><h3 class=\"gov-h3\">5. Consensus collapse diagnostics</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Consensus pass rate ‰</td><td>" + IntegerToString(cpass) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Avg agreeing strategies ‰ (×1000 scale)</td><td>" + IntegerToString(avga) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Attempts / pass / fail</td><td>" + IntegerToString(t.consensus_attempts) + " / " + IntegerToString(t.consensus_pass) + " / " + IntegerToString(t.consensus_fail) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"sigf-regime\"><h3 class=\"gov-h3\">6. Regime suppression analysis</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table id=\"tblSigReg\" data-sort-col=\"-1\" data-sort-dir=\"asc\"><thead><tr>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblSigReg',0)\">Regime</th><th onclick=\"govSort('tblSigReg',1)\">Signals</th><th onclick=\"govSort('tblSigReg',2)\">Accepted</th><th>Accept‰</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tr></thead><tbody>\n");
   for(int r = 0; r < GOV_SIG_FORENSICS_REGIME_SLOTS_V1; r++) {
      const int ap = GovSigRegimeV1_AcceptPermille(t.reg_sig[r], t.reg_acc[r]);
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovSigForensicsHtmlV1_RegimeRowLab(r)) + "</td><td>" + IntegerToString(t.reg_sig[r]) + "</td><td>" +
                                         IntegerToString(t.reg_acc[r]) + "</td><td>" + IntegerToString(ap) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"sigf-dead\"><h3 class=\"gov-h3\">7. Dead signal zones</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p>First starvation month index (1–12): <b>" + IntegerToString(t.dead_zone_month_first_1_12) + "</b> · ring depth: <b>" + IntegerToString(t.life.count) + "</b></p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table id=\"tblSigHeatM\" data-sort-col=\"-1\" data-sort-dir=\"asc\"><thead><tr><th onclick=\"govSort('tblSigHeatM',0)\">Month</th><th onclick=\"govSort('tblSigHeatM',1)\">CONS</th><th onclick=\"govSort('tblSigHeatM',2)\">QUAL</th><th onclick=\"govSort('tblSigHeatM',3)\">TREND</th></tr></thead><tbody>\n");
   for(int m = 0; m < GOV_SIG_FORENSICS_MONTH_BUCKETS_V1; m++) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovSigMonthlyV1_AbbrFromIndex0_11(m) + "</td><td>" + IntegerToString(GovSigHeatmapV1_CellMonthRej(t, m, GOV_SIG_REJECT_CONSENSUS)) + "</td><td>" +
                                         IntegerToString(GovSigHeatmapV1_CellMonthRej(t, m, GOV_SIG_REJECT_QUALITY)) + "</td><td>" + IntegerToString(GovSigHeatmapV1_CellMonthRej(t, m, GOV_SIG_REJECT_TREND)) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"sigf-starve\"><h3 class=\"gov-h3\">8. Signal starvation alerts</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-banner-stack\">\n");
   if(t.starvation_alerts > 0)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-banner gov-banner-warn\"><span class=\"gov-banner-tag\">STARVE</span>Signal starvation episodes (counter): " + IntegerToString(t.starvation_alerts) + "</div>\n");
   if(dom_pct >= 920 && topj == GOV_SIG_REJECT_TREND)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-banner gov-banner-warn\"><span class=\"gov-banner-tag\">TREND</span>Trend alignment rejects dominate the ecology.</div>\n");
   if(cpass < 100 && t.consensus_attempts > 50)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-banner gov-banner-crit\"><span class=\"gov-banner-tag\">CONS</span>Consensus collapse detected (pass rate &lt;10%).</div>\n");
   if(GovSigHeatmapV1_CellStratRej(t, (int)STRATEGY_MOMENTUM_SCALP, GOV_SIG_REJECT_QUALITY) == 0 && t.strat_sig[(int)STRATEGY_MOMENTUM_SCALP] == 0 && t.strat_acc[(int)STRATEGY_MOMENTUM_SCALP] == 0)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-banner gov-banner-warn\"><span class=\"gov-banner-tag\">ECO</span>MomentumScalp participation is zero in this replay window.</div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</div><p class=\"gov-note\">Heatmap cells are rejection counts by month × reason; strategy/regime slices available in CSV export (Phase 21 export block).</p></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");
}

#endif // __AURUM_GOV_SIG_FORENSICS_HTML_V1_MQH__
