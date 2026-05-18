//+------------------------------------------------------------------+
//| GovernanceRegimeHtmlV1.mqh                                       |
//| PHASE 22 — dossier section 22 HTML                               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REGIME_HTML_V1_MQH__
#define __AURUM_GOV_REGIME_HTML_V1_MQH__

#include "../GovernanceRuntimeVisualObservabilityV1/GovernanceRuntimeVisualHtmlWriterV1.mqh"
#include "../GovernanceRuntimeVisualObservabilityV1/GovernanceRuntimeVisualDatasetV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionExportV1.mqh"
#include "../GovernanceSignalForensicsV1/GovernanceSignalForensicsTelemetryV1.mqh"
#include "GovernanceRegimeMonthlyAnalyticsV1.mqh"
#include "GovernanceRegimeDatasetV1.mqh"

inline string GovRegimeHtmlV1_RegimeName(const int slot)
{
   switch(slot) {
   case 0: return "UNKNOWN";
   case 1: return "TRENDING";
   case 2: return "RANGING";
   case 3: return "HIGH_VOL";
   case 4: return "LOW_VOL";
   case 5: return "BREAKOUT";
   case 6: return "MEAN_REVERSION";
   case 7: return "LIQUIDITY_SWEEP";
   case 8: return "ACCUMULATION";
   case 9: return "DISTRIBUTION";
   case 10: return "VOLATILITY_EXPANSION";
   case 11: return "VOLATILITY_COMPRESSION";
   default: return "—";
   }
}

inline string GovRegimeHtmlV1_MonthShort(const int m)
{
   if(m == 0) return "Jan";
   if(m == 1) return "Feb";
   if(m == 2) return "Mar";
   if(m == 3) return "Apr";
   if(m == 4) return "May";
   if(m == 5) return "Jun";
   if(m == 6) return "Jul";
   if(m == 7) return "Aug";
   if(m == 8) return "Sep";
   if(m == 9) return "Oct";
   if(m == 10) return "Nov";
   return "Dec";
}

inline void GovRegimeHtmlV1_AppendSection22(const SGovRegimeRuntimeStoreV1 &rg,
                                            const SGovSignalForensicsTelemetryV1 &sigf,
                                            const SGovStratAttribSummaryV1 &sum,
                                            const SGovVisualExecSummaryV1 &ex,
                                            string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s22\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">22</span> Regime detection intelligence</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Adaptive market-regime layer: deterministic factor fusion, transition tracking, monthly dominance, strategy-regime compatibility, and starvation diagnostics (Phase 22).</p>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"reg22-current\"><h3 class=\"gov-h3\">1. Current regime state</h3>\n<table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>EAurum regime</td><td><code>" +
                                         GovRuntimeVisualHtmlW1_Escape(GovRegimeHtmlV1_RegimeName(GovRegimeDsV1_RegimeSlot(rg.current_regime))) + "</code></td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Total classified bars</td><td>" + IntegerToString((long)rg.total_bars) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Transitions</td><td>" + IntegerToString((long)rg.transitions_total) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Bars since change</td><td>" + IntegerToString(rg.bars_since_change) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"reg22-dist\"><h3 class=\"gov-h3\">2. Regime distribution</h3>\n<table id=\"tblReg22Dist\"><thead><tr><th>Regime</th><th>Bars</th><th>Share permille</th></tr></thead><tbody>\n");
   for(int r = 0; r < GOV_REGIME_AURUM_SLOT_COUNT_V1; r++) {
      const ulong c = rg.regime_hist[r];
      const int permille = (rg.total_bars > 0) ? (int)(1000UL * c / MathMax(1UL, rg.total_bars)) : 0;
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovRegimeHtmlV1_RegimeName(r)) + "</td><td>" + IntegerToString((long)c) + "</td><td>" + IntegerToString(permille) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-note\">Attribution trade_count_input=" + IntegerToString(sum.trade_count_input) + " (cold summary).</p>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"reg22-month\"><h3 class=\"gov-h3\">3. Monthly regime timeline</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table id=\"tblReg22Mo\"><thead><tr><th>Month</th><th>Dominant</th><th>Signals</th><th>Trades</th><th>Net cents</th><th>DD %</th></tr></thead><tbody>\n");
   for(int m = 0; m < 12; m++) {
      const int dom = GovRegimeMoV1_DominantRegimeSlot(rg, m);
      const ulong sigc = rg.month_signals[m];
      const ulong trc = (ulong)rg.month_trades[m];
      const long net = rg.month_net_cents[m];
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRegimeHtmlV1_MonthShort(m) + "</td><td>" + GovRuntimeVisualHtmlW1_Escape(GovRegimeHtmlV1_RegimeName(dom)) + "</td><td>" +
                                         IntegerToString((long)sigc) + "</td><td>" + IntegerToString((long)trc) + "</td><td>" + IntegerToString((int)net) + "</td><td>" +
                                         DoubleToString(ex.balance_dd_rel_pct, 2) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table><p class=\"gov-note\">DD % column shows run-level balance DD (tester); monthly decomposition uses regime bar mass.</p></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"reg22-tr\"><h3 class=\"gov-h3\">4. Regime transition analysis</h3>\n<table><thead><tr><th>Time</th><th>From</th><th>To</th><th>Post bars</th><th>Tox proxy</th></tr></thead><tbody>\n");
   for(int k = 0; k < rg.tr_count && k < 24; k++) {
      const int idx = (rg.tr_head + rg.tr_count - 1 - k + GOV_REGIME_TRANSITION_RING_V1) % GOV_REGIME_TRANSITION_RING_V1;
      const SGovRegimeTransitionV1 tr = rg.tr_ring[idx];
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + TimeToString(tr.ts, TIME_DATE | TIME_MINUTES) + "</td><td>" + GovRegimeHtmlV1_RegimeName(tr.from_reg) + "</td><td>" +
                                         GovRegimeHtmlV1_RegimeName(tr.to_reg) + "</td><td>" + IntegerToString((long)tr.post_bars) + "</td><td>" + IntegerToString((int)tr.post_tox_proxy) + "</td></tr>\n");
   }
   if(rg.tr_count == 0)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td colspan=\"5\">No transitions recorded yet.</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"reg22-mx\"><h3 class=\"gov-h3\">5. Strategy-regime compatibility</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table id=\"tblReg22Mx\"><thead><tr><th>Strategy</th><th>Top regime</th><th>Trades</th><th>Win pct</th><th>PF proxy</th></tr></thead><tbody>\n");
   for(int s = 0; s < GOV_REGIME_STRAT_SLOTS_V1; s++) {
      int best = 0;
      int mt = 0;
      for(int r = 0; r < GOV_REGIME_AURUM_SLOT_COUNT_V1; r++) {
         if(rg.strat_regime[s][r].trades > mt) {
            mt = rg.strat_regime[s][r].trades;
            best = r;
         }
      }
      const SGovRegimeStratCellV1 c = rg.strat_regime[s][best];
      const int wr = (c.trades > 0) ? (int)(1000L * (long)c.wins / (long)c.trades) : 0;
      const double pf = (c.trades > 0) ? (1.0 + (double)c.profit_cents / (double)MathMax(1, c.trades)) : 0.0;
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(s)) + "</td><td>" + GovRegimeHtmlV1_RegimeName(best) + "</td><td>" +
                                         IntegerToString(c.trades) + "</td><td>" + DoubleToString(wr / 10.0, 1) + "</td><td>" + DoubleToString(pf, 2) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"reg22-surv\"><h3 class=\"gov-h3\">6. Regime survivability</h3>\n<table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Max frozen streak bars</td><td>" + IntegerToString((long)rg.frozen_streak_max) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>Post-transition tox proxy sum</td><td>" + IntegerToString((int)rg.post_transition_tox_accum) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"reg22-vexp\"><h3 class=\"gov-h3\">7. Volatility expansion analysis</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p>Expansion bars: " + IntegerToString((long)rg.regime_hist[GovRegimeDsV1_RegimeSlot(AURUM_REGIME_VOLATILITY_EXPANSION)]) +
                                         " | Breakout bars: " + IntegerToString((long)rg.regime_hist[GovRegimeDsV1_RegimeSlot(AURUM_REGIME_BREAKOUT)]) + "</p></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"reg22-comp\"><h3 class=\"gov-h3\">8. Compression zones</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p>Compression plus accumulation bars: " +
                                         IntegerToString((long)(rg.regime_hist[GovRegimeDsV1_RegimeSlot(AURUM_REGIME_VOLATILITY_COMPRESSION)] + rg.regime_hist[GovRegimeDsV1_RegimeSlot(AURUM_REGIME_ACCUMULATION)])) + "</p></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"reg22-collapse\"><h3 class=\"gov-h3\">9. Regime collapse alerts</h3>\n");
   if(rg.diversity_collapse)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-warn\"><b>REGIME_DIVERSITY_COLLAPSE</b> dominant regime exceeded 90 percent bar share or frozen streak exceeded 5000 bars.</p>\n");
   else
      GovRuntimeVisualHtmlW1_AppendLf(html, "<p>No diversity collapse flag at dossier snapshot.</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"reg22-starve\"><h3 class=\"gov-h3\">10. Regime starvation diagnostics</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p>Signal forensics starvation alerts: " + IntegerToString((long)sigf.starvation_alerts) + "</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p>Phase 22 diversity collapse evaluations: " + IntegerToString((long)rg.diversity_collapse_hits) + "</p></div>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");
}

#endif // __AURUM_GOV_REGIME_HTML_V1_MQH__
