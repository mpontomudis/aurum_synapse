//+------------------------------------------------------------------+
//| GovernanceRuntimeVisualDashboardBuilderV1.mqh                     |
//| Single-file HTML dashboard (embedded CSS/JS)                     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_VISUAL_DASH_V1_MQH__
#define __AURUM_GOV_RUNTIME_VISUAL_DASH_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "../GovernanceRuntimeObservabilityExportV1/GovernanceRuntimeObservabilityDatasetV1.mqh"
#include "../GovernanceRuntimeStrategyTaggingV1/GovernanceRuntimeStrategyTaggingModuleV1.mqh"
#include "../GovernanceRuntimeStrategyTaggingV1/GovernanceRuntimeAttributionBridgeV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionDatasetV1.mqh"
#include "../GovernancePositionLineageIntelligenceV1/GovernancePositionLineageRegistryV1.mqh"
#include "../GovernanceRuntimeObservabilityExportV1/GovernanceRuntimeObservabilityReplayV1.mqh"
#include "GovernanceRuntimeVisualContractsV1.mqh"
#include "GovernanceRuntimeVisualDatasetV1.mqh"
#include "GovernanceRuntimeVisualHtmlWriterV1.mqh"
#include "GovernanceRuntimeVisualCssV1.mqh"
#include "GovernanceRuntimeVisualJsV1.mqh"
#include "GovernanceRuntimeVisualChartBuilderV1.mqh"
#include "GovernanceRuntimeVisualLineageGraphV1.mqh"
#include "GovernanceRuntimeVisualReplayV1.mqh"

inline int GovRuntimeVisualDashV1_AvgToxicityScore(const SGovStratAttribSummaryV1 &sum)
{
   int agg = 0;
   int cnt = 0;
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      if(sum.bd.by_strat[i].trades <= 0)
         continue;
      agg = GovSaturatingAdd32(agg, sum.tox[i].score_0_1000);
      cnt++;
   }
   return (cnt > 0) ? (agg / cnt) : 0;
}

inline int GovRuntimeVisualDashV1_SurvivabilityScore(const SGovVisualExecSummaryV1 &ex, const SGovStratAttribSummaryV1 &sum)
{
   const int avgt = GovRuntimeVisualDashV1_AvgToxicityScore(sum);
   const int ddp = GovClampInt32((int)ex.balance_dd_rel_pct, 0, 100);
   int s = 100 - (ddp * 4) / 10 - (avgt * 8) / 100;
   return GovClampInt32(s, 0, 100);
}

inline string GovRuntimeVisualDashV1_StabilityClass(const SGovVisualExecSummaryV1 &ex, const SGovStratAttribSummaryV1 &sum)
{
   int agg_tox = 0;
   int cnt = 0;
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      if(sum.bd.by_strat[i].trades <= 0)
         continue;
      agg_tox = GovSaturatingAdd32(agg_tox, sum.tox[i].score_0_1000);
      cnt++;
   }
   const int avg = (cnt > 0) ? (agg_tox / cnt) : 0;
   if(ex.balance_dd_rel_pct > 35.0 || avg > 650)
      return "UNSTABLE";
   if(ex.balance_dd_rel_pct > 20.0 || avg > 500)
      return "BORDERLINE";
   return "STABLE";
}

inline string GovRuntimeVisualDashV1_SurvivabilityStatus(const double deposit_label, const double dd_pct)
{
   if(deposit_label <= 200.0 && dd_pct > 18.0)
      return "COLLAPSE";
   if(deposit_label <= 500.0 && dd_pct > 22.0)
      return "UNSTABLE";
   if(deposit_label <= 1000.0 && dd_pct > 28.0)
      return "BORDERLINE";
   if(deposit_label <= 3000.0 && dd_pct > 35.0)
      return "BORDERLINE";
   if(deposit_label >= 10000.0 && dd_pct < 15.0)
      return "SAFE";
   if(deposit_label >= 3000.0 && dd_pct < 25.0)
      return "STABLE";
   return "BORDERLINE";
}

inline void GovRuntimeVisualDashV1_AppendToxicityDetail(SGovStratAttribSummaryV1 &sum, string &html)
{
   for(int k = 0; k < GOV_SATTR_STRAT_COUNT_V1; k++)
      GovStratToxV1_Score(k, sum, sum.tox[k]);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table><thead><tr><th>Strategy</th><th>Score</th><th>RegimeMismatch</th><th>Stopout‰</th><th>Tail‰</th><th>VolTox</th></tr></thead><tbody>\n");
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      const SGovStratAttribToxicityV1 t = sum.tox[i];
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(i)) + "</td><td>" + IntegerToString(t.score_0_1000) + "</td><td>" +
                                         IntegerToString(t.regime_mismatch) + "</td><td>" + IntegerToString(t.stopout_rate_x1000) + "</td><td>" + IntegerToString(t.loss_persist) + "</td><td>" +
                                         IntegerToString(t.vol_toxicity) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
}

inline void GovRuntimeVisualDashV1_AppendBridgeTimeline(const SGovRuntimeTaggingModuleV1 &mod, string &html, const int max_rows)
{
   const int kmax = MathMin(mod.bridge.total, GOV_RTAG_BRIDGE_CAP_V1);
   const int n = MathMin(max_rows, kmax);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table><thead><tr><th>#</th><th>Strategy</th><th>Regime</th><th>Profit¢</th><th>Stopout</th><th>Tail</th></tr></thead><tbody>\n");
   for(int i = 0; i < n; i++) {
      const int idx = GovRunAttrBridgeV1_FlattenIndex(mod.bridge, i);
      const SGovStratAttribTradeV1 tr = mod.bridge.tr[idx];
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + IntegerToString(i) + "</td><td>" + IntegerToString(tr.strat) + "</td><td>" + IntegerToString(tr.regime) + "</td><td>" +
                                         IntegerToString((int)tr.profit_cents) + "</td><td>" + IntegerToString(tr.stopout) + "</td><td>" + IntegerToString(tr.tail_loss) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
}

inline void GovRuntimeVisualDashV1_AppendCapital(const SGovRuntimeObsCapitalSnapV1 &cap, string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>RequestedLot</td><td>" + GovRuntimeVisualHtmlW1_Escape(DoubleToString((double)cap.requested_lot_micro / 100000000.0, 4)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>NormalizedLot</td><td>" + GovRuntimeVisualHtmlW1_Escape(DoubleToString((double)cap.normalized_lot_micro / 100000000.0, 4)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>BrokerMinLot</td><td>" + GovRuntimeVisualHtmlW1_Escape(DoubleToString((double)cap.broker_min_lot_micro / 100000000.0, 4)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>FreeMargin</td><td>" + GovRuntimeVisualHtmlW1_Escape(DoubleToString((double)cap.margin_free_cent / 100.0, 2)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>MarginRequired</td><td>" + GovRuntimeVisualHtmlW1_Escape(DoubleToString((double)cap.margin_req_cent / 100.0, 2)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>LastBlockReason</td><td>" + GovRuntimeVisualHtmlW1_Escape(cap.last_block_reason) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>ResultCode</td><td>" + IntegerToString(cap.result_code) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
}

inline void GovRuntimeVisualDashV1_AppendExecCards(const SGovVisualExecSummaryV1 &ex, const SGovStratAttribSummaryV1 &sum, string &html)
{
   const int wr = (ex.total_trades > 0) ? (int)((100L * (long)ex.profit_trades) / (long)ex.total_trades) : 0;
   const int avgtox = GovRuntimeVisualDashV1_AvgToxicityScore(sum);
   const int surv = GovRuntimeVisualDashV1_SurvivabilityScore(ex, sum);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"grid\">\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Total Net Profit</b><span>" + DoubleToString(ex.net_profit, 2) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Gross Profit</b><span>" + DoubleToString(ex.gross_profit, 2) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Gross Loss</b><span>" + DoubleToString(ex.gross_loss, 2) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Profit Factor</b><span>" + DoubleToString(ex.profit_factor, 3) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Recovery Factor</b><span>" + DoubleToString(ex.recovery_factor, 3) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Max DD % (bal)</b><span>" + DoubleToString(ex.balance_dd_rel_pct, 2) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Total Trades</b><span>" + IntegerToString(ex.total_trades) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Winrate</b><span>" + IntegerToString(wr) + "%</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Toxicity score (avg 0–1000)</b><span>" + IntegerToString(avgtox) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Survivability score (0–100)</b><span>" + IntegerToString(surv) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"grid\" style=\"margin-top:12px;\"><div class=\"card\"><b>DD gauge</b><div class=\"barwrap\"><div class=\"bar\" style=\"width:" +
                                         IntegerToString(GovClampInt32((int)ex.balance_dd_rel_pct, 0, 100)) + "%\"></div></div></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>PF gauge</b><div class=\"barwrap\"><div class=\"bar\" style=\"width:" +
                                         IntegerToString(GovClampInt32((int)(ex.profit_factor * 33.0), 0, 100)) + "%\"></div></div></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Toxicity badge</b><span class=\"badge " + GovRuntimeVisualChartV1_ToxBadgeClass(avgtox) + "\">" +
                                         GovRuntimeVisualChartV1_ToxLabel(avgtox) + "</span></div></div>\n");
}

inline void GovRuntimeVisualDashV1_AppendLegacyAnalyticsCore(const string sym,
                                                            const SGovRuntimeTaggingModuleV1 &mod,
                                                            const SGovLineageRegistryStoreV1 &lin,
                                                            SGovStratAttribSummaryV1 &sum,
                                                            const SGovVisualExecSummaryV1 &ex,
                                                            string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-exec\"><h2>Executive summary (core)</h2>\n");
   GovRuntimeVisualDashV1_AppendExecCards(ex, sum, html);
   if(ex.valid == 0)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<p><i>Tester statistics unavailable (not in Strategy Tester).</i></p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p><b>Stability classification:</b> <code>" + GovRuntimeVisualHtmlW1_Escape(GovRuntimeVisualDashV1_StabilityClass(ex, sum)) + "</code></p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-strat\"><h2>Strategy breakdown (core)</h2>\n");
   GovRuntimeVisualChartV1_StrategyTable(sum, html);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-lin\"><h2>Position lineage (core)</h2>\n");
   GovRuntimeVisualLinV1_Build(lin, html);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-tox\"><h2>Toxicity analytics (core)</h2>\n");
   GovRuntimeVisualDashV1_AppendToxicityDetail(sum, html);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-cap\"><h2>Capital diagnostics (core)</h2>\n");
   GovRuntimeVisualDashV1_AppendCapital(g_gov_runtime_obs_report_v1.cap, html);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-surv\"><h2>Survivability matrix (core)</h2>\n<table><thead><tr><th>Deposit</th><th>Status</th></tr></thead><tbody>\n");
   const double dd = ex.balance_dd_rel_pct;
   const double d0[5] = {200.0, 500.0, 1000.0, 3000.0, 10000.0};
   for(int j = 0; j < 5; j++)
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>$" + DoubleToString(d0[j], 0) + "</td><td>" +
                                         GovRuntimeVisualHtmlW1_Escape(GovRuntimeVisualDashV1_SurvivabilityStatus(d0[j], dd)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-reg\"><h2>Regime analytics (core)</h2>\n");
   GovRuntimeVisualChartV1_RegimeTable(sum, html);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-tl\"><h2>Replay timeline (core)</h2>\n");
   GovRuntimeVisualDashV1_AppendBridgeTimeline(mod, html, 64);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");
}

inline void GovRuntimeVisualDashV1_BuildHtml(const string sym,
                                            const SGovRuntimeTaggingModuleV1 &mod,
                                            const SGovLineageRegistryStoreV1 &lin,
                                            SGovStratAttribSummaryV1 &sum,
                                            const SGovVisualExecSummaryV1 &ex,
                                            string &html)
{
   html = "";
   for(int z = 0; z < GOV_SATTR_STRAT_COUNT_V1; z++)
      GovStratToxV1_Score(z, sum, sum.tox[z]);

   GovRuntimeVisualHtmlW1_AppendLf(html, "<!DOCTYPE html>\n<html lang=\"en\"><head><meta charset=\"utf-8\"/>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<title>Aurum Synapse — Governance Report</title>\n<style>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, GovRuntimeVisualCssV1_Embedded());
   GovRuntimeVisualHtmlW1_AppendLf(html, "</style></head><body>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<header><h1>Governance Runtime Visual Observability — " + GovRuntimeVisualHtmlW1_Escape(sym) + "</h1>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div style=\"font-size:0.8rem;color:#8b949e;margin-top:6px;\">ABI=" + IntegerToString((int)GOV_VISUAL_ABI_VER_V1) + " | magic=" + IntegerToString((int)GOV_VISUAL_MAGIC_V1) + "</div></header>\n<main>\n");

   GovRuntimeVisualDashV1_AppendLegacyAnalyticsCore(sym, mod, lin, sum, ex, html);

   const string snap = html;
   const ulong h_replay = GovRuntimeObsReplayV1_Hash64(snap);
   const ulong h_export = GovRuntimeVisualReplayV1_Hash64Alt(snap);
   string tel = IntegerToString(ex.valid) + "|" + DoubleToString(ex.net_profit, 2) + "|" + IntegerToString(ex.total_trades);
   for(int u = 0; u < GOV_SATTR_STRAT_COUNT_V1; u++)
      tel += "|" + IntegerToString(sum.bd.by_strat[u].trades);
   const ulong h_telemetry = GovRuntimeObsReplayV1_Hash64(tel);
   const string replay_ok = (StringLen(snap) > 200) ? "PAYLOAD_OK" : "PAYLOAD_SHORT";
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section><h2>9. Governance Replay Hash</h2><table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>replay_hash</td><td>" + IntegerToString((long)h_replay) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>export_hash</td><td>" + IntegerToString((long)h_export) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>telemetry_hash</td><td>" + IntegerToString((long)h_telemetry) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>deterministic_equality</td><td>BUILD_STABLE_V1</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>replay_validity</td><td>" + replay_ok + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section><h2>10. Massive Backtest Aggregation</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p>Report library: unique files <code>" + GovRuntimeVisualHtmlW1_Escape(GOV_VISUAL_REPORT_PREFIX_V1) + "*_SYMBOL_TF_*_RUN_####" +
                                         GovRuntimeVisualHtmlW1_Escape(GOV_VISUAL_HTML_EXT_V1) + "</code> plus <code>report_registry.csv</code> and <code>index.html</code>.</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p>Store under <code>" + GovRuntimeVisualHtmlW1_Escape(GOV_VISUAL_REPORT_DIR_V1) + "</code> (terminal MQL5 Files tree).</p></section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "</main><footer>Generated by Aurum Synapse — GovernanceRuntimeVisualObservabilityV1 (cold path). LF-only.</footer>\n<script>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, GovRuntimeVisualJsV1_Embedded());
   GovRuntimeVisualHtmlW1_AppendLf(html, "</script></body></html>\n");
}

#endif // __AURUM_GOV_RUNTIME_VISUAL_DASH_V1_MQH__
