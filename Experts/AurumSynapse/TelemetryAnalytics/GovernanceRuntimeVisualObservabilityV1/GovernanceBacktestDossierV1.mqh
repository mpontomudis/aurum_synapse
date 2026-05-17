//+------------------------------------------------------------------+
//| GovernanceBacktestDossierV1.mqh                                 |
//| PHASE 20B — full HTML dossier orchestration (cold path)          |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_BACKTEST_DOSSIER_V1_MQH__
#define __AURUM_GOV_BACKTEST_DOSSIER_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "../GovernanceRuntimeStrategyTaggingV1/GovernanceRuntimeStrategyTaggingModuleV1.mqh"
#include "../GovernancePositionLineageIntelligenceV1/GovernancePositionLineageRegistryV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionDatasetV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionExportV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyToxicityAnalyticsV1.mqh"
#include "GovernanceRuntimeVisualContractsV1.mqh"
#include "GovernanceRuntimeVisualDatasetV1.mqh"
#include "GovernanceRuntimeVisualHtmlWriterV1.mqh"
#include "GovernanceRuntimeVisualCssV1.mqh"
#include "GovernanceRuntimeVisualJsV1.mqh"
#include "GovernanceRuntimeVisualChartBuilderV1.mqh"
#include "GovernanceRuntimeVisualLineageGraphV1.mqh"
#include "GovernanceRuntimeVisualDashboardBuilderV1.mqh"
#include "GovernanceRuntimeVisualReplayV1.mqh"
#include "../GovernanceRuntimeObservabilityExportV1/GovernanceRuntimeObservabilityReplayV1.mqh"
#include "GovernanceBacktestMetadataV1.mqh"
#include "GovernanceBacktestInputSnapshotV1.mqh"
#include "GovernanceBacktestEnvironmentSnapshotV1.mqh"
#include "GovernanceBacktestCapitalDiagnosticsV1.mqh"
#include "GovernanceBacktestSurvivabilityV1.mqh"
#include "GovernanceBacktestReplayTimelineV1.mqh"
#include "GovernanceBacktestRecoveryAnalysisV1.mqh"
#include "GovernanceBacktestFailureDiagnosticsV1.mqh"
#include "GovernanceBacktestRecommendationsV1.mqh"
#include "GovernanceBacktestComparativeInsightsV1.mqh"
#include "../GovernancePositionLineageIntelligenceV1/GovernanceRecoveryChainAnalyticsV1.mqh"

inline string GovBacktestDossierV1_RegimeDossierLabel(const int regime)
{
   switch(GovClampInt32(regime, 0, 5)) {
   case 0: return "TRENDING";
   case 1: return "RANGING";
   case 2: return "HIGH_VOL";
   case 3: return "LOW_VOL";
   case 4: return "NEWS";
   default: return "LIQUIDITY_VACUUM";
   }
}

inline void GovBacktestDossierV1_AppendStrategyActivation(const SGovStratAttribSummaryV1 &sum, SGovStratAttribSummaryV1 &tmp, string &html)
{
   for(int z = 0; z < GOV_SATTR_STRAT_COUNT_V1; z++)
      GovStratToxV1_Score(z, tmp, tmp.tox[z]);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-sact\"><h2>3. Strategy activation</h2>\n<table><thead><tr><th>Strategy</th><th>Input gate</th><th>Trades</th><th>Net¢</th><th>Tox</th><th>Ecology role</th></tr></thead><tbody>\n");
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      const SGovStratAttribStatsV1 st = sum.bd.by_strat[i];
      const long net = st.gross_win_cents - st.gross_loss_cents;
      string role = "PARTICIPANT";
      if(!g_gov_dossier_strat_en_v1[i])
         role = "DISABLED_INPUT_GATE";
      else if(i == (int)GOV_STRAT_GR && tmp.tox[i].score_0_1000 > 450)
         role = "EMERGENCY_LADDER";
      else if(i == (int)GOV_STRAT_BO && tmp.tox[i].score_0_1000 > 600)
         role = "TOXIC_VOL_AMPLIFIER";
      else if(i == (int)GOV_STRAT_TF && st.trades >= 2 && st.pf_milli > 1100)
         role = "PRIMARY_ALPHA";
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(i)) + "</td><td>" +
                                         (g_gov_dossier_strat_en_v1[i] ? "ENABLED" : "DISABLED") + "</td><td>" + IntegerToString(st.trades) + "</td><td>" +
                                         IntegerToString((int)net) + "</td><td>" + IntegerToString(tmp.tox[i].score_0_1000) + "</td><td>" +
                                         GovRuntimeVisualHtmlW1_Escape(role) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></section>\n");
}

inline void GovBacktestDossierV1_AppendRiskConfiguration(string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-risk\"><h2>4. Risk configuration</h2>\n<div class=\"grid\">\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Max risk / trade %</b><span>" + DoubleToString(g_gov_dossier_risk_v1.max_risk_per_trade, 2) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Max daily loss %</b><span>" + DoubleToString(g_gov_dossier_risk_v1.max_daily_loss_pct, 2) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Max equity DD %</b><span>" + DoubleToString(g_gov_dossier_risk_v1.max_equity_dd_pct, 2) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Max consecutive losses</b><span>" + IntegerToString(g_gov_dossier_risk_v1.max_consecutive_losses) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Max open positions</b><span>" + IntegerToString(g_gov_dossier_risk_v1.max_open_positions) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"grid\" style=\"margin-top:12px;\"><div class=\"card\"><b>DD threshold (tester)</b><div class=\"barwrap\"><div class=\"bar\" style=\"width:40%\"></div></div></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Margin stress (placeholder)</b><div class=\"barwrap\"><div class=\"bar\" style=\"width:25%\"></div></div></div></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");
}

inline void GovBacktestDossierV1_AppendRegimeDossierTable(const SGovStratAttribSummaryV1 &sum, SGovStratAttribSummaryV1 &tmp, string &html)
{
   for(int z = 0; z < GOV_SATTR_STRAT_COUNT_V1; z++)
      GovStratToxV1_Score(z, tmp, tmp.tox[z]);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-regd\"><h2>7. Regime breakdown</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table><thead><tr><th>Regime</th><th>Trades</th><th>Net¢</th><th>PF</th><th>Avg tox</th><th>Collapse density</th></tr></thead><tbody>\n");
   for(int r = 0; r < GOV_SATTR_REGIME_COUNT_V1; r++) {
      const SGovStratAttribStatsV1 st = sum.bd.regime.by_reg[r];
      const long net = st.gross_win_cents - st.gross_loss_cents;
      int toxsum = 0;
      int tc = 0;
      for(int k = 0; k < GOV_SATTR_STRAT_COUNT_V1; k++) {
         if(sum.bd.by_strat[k].trades <= 0)
            continue;
         toxsum += tmp.tox[k].regime_mismatch;
         tc++;
      }
      const int avgx = (tc > 0) ? (toxsum / tc) : 0;
      const int cd = (st.stopout_count > 0) ? (st.stopout_count * 100 / MathMax(1, st.trades)) : 0;
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovBacktestDossierV1_RegimeDossierLabel(r)) + "</td><td>" + IntegerToString(st.trades) + "</td><td>" +
                                         IntegerToString((int)net) + "</td><td>" + DoubleToString((double)st.pf_milli / 1000.0, 3) + "</td><td>" + IntegerToString(avgx) + "</td><td>" +
                                         IntegerToString(cd) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></section>\n");
}

inline void GovBacktestDossierV1_AppendSessionTable(const SGovStratAttribSummaryV1 &sum, string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-sess\"><h2>8. Session breakdown</h2>\n<table id=\"tblSess\" data-sort-col=\"-1\" data-sort-dir=\"asc\"><thead><tr>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblSess',0)\">Session</th><th onclick=\"govSort('tblSess',1)\">Trades</th><th onclick=\"govSort('tblSess',2)\">Net¢</th><th onclick=\"govSort('tblSess',3)\">PF</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tr></thead><tbody>\n");
   for(int s = 0; s < GOV_SATTR_SESSION_COUNT_V1; s++) {
      const SGovStratAttribStatsV1 st = sum.bd.session.by_sess[s];
      const long net = st.gross_win_cents - st.gross_loss_cents;
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovStratTagV1_SessionCode(s)) + "</td><td>" + IntegerToString(st.trades) + "</td><td>" +
                                         IntegerToString((int)net) + "</td><td>" + DoubleToString((double)st.pf_milli / 1000.0, 3) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></section>\n");
}

inline void GovBacktestDossierV1_AppendVolTable(const SGovStratAttribSummaryV1 &sum, string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-vol\"><h2>9. Volatility breakdown</h2>\n<table id=\"tblVol\" data-sort-col=\"-1\" data-sort-dir=\"asc\"><thead><tr>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblVol',0)\">Bucket</th><th onclick=\"govSort('tblVol',1)\">Trades</th><th onclick=\"govSort('tblVol',2)\">Net¢</th><th onclick=\"govSort('tblVol',3)\">PF</th><th onclick=\"govSort('tblVol',4)\">Stopouts</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tr></thead><tbody>\n");
   for(int v = 0; v < GOV_SATTR_VOL_COUNT_V1; v++) {
      const SGovStratAttribStatsV1 st = sum.bd.vol.by_vol[v];
      const long net = st.gross_win_cents - st.gross_loss_cents;
      const string lab = (v == 0) ? "LOW" : ((v == 1) ? "NORMAL" : ((v == 2) ? "HIGH" : "EXTREME"));
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + lab + "</td><td>" + IntegerToString(st.trades) + "</td><td>" +
                                         IntegerToString((int)net) + "</td><td>" + DoubleToString((double)st.pf_milli / 1000.0, 3) + "</td><td>" + IntegerToString(st.stopout_count) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></section>\n");
}

inline void GovBacktestDossierV1_AppendToxicityRadar(const SGovStratAttribSummaryV1 &sum, SGovStratAttribSummaryV1 &tmp, string &html)
{
   for(int z = 0; z < GOV_SATTR_STRAT_COUNT_V1; z++)
      GovStratToxV1_Score(z, tmp, tmp.tox[z]);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-toxrad\"><h2>11b. Toxicity radar (tabular)</h2>\n<table><thead><tr><th>Strategy</th><th>Score</th><th>Regime mismatch</th><th>Vol tox</th><th>Stopout‰</th></tr></thead><tbody>\n");
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      const SGovStratAttribToxicityV1 t = tmp.tox[i];
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(i)) + "</td><td>" + IntegerToString(t.score_0_1000) + "</td><td>" +
                                         IntegerToString(t.regime_mismatch) + "</td><td>" + IntegerToString(t.vol_toxicity) + "</td><td>" + IntegerToString(t.stopout_rate_x1000) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></section>\n");
}

inline void GovBacktestDossierV1_AppendGovernanceHashBlock(const SGovVisualExecSummaryV1 &ex, const SGovStratAttribSummaryV1 &sum, string &html)
{
   const string snap = html;
   const ulong h_replay = GovRuntimeObsReplayV1_Hash64(snap);
   const ulong h_export = GovRuntimeVisualReplayV1_Hash64Alt(snap);
   string tel = IntegerToString(ex.valid) + "|" + DoubleToString(ex.net_profit, 2) + "|" + IntegerToString(ex.total_trades);
   for(int u = 0; u < GOV_SATTR_STRAT_COUNT_V1; u++)
      tel += "|" + IntegerToString(sum.bd.by_strat[u].trades);
   const ulong h_telemetry = GovRuntimeObsReplayV1_Hash64(tel);
   const string replay_ok = (StringLen(snap) > 200) ? "PAYLOAD_OK" : "PAYLOAD_SHORT";
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-ghash\"><h2>15. Governance hash</h2><table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>replay_hash</td><td>" + IntegerToString((long)h_replay) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>export_hash</td><td>" + IntegerToString((long)h_export) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>telemetry_hash</td><td>" + IntegerToString((long)h_telemetry) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>deterministic_equality</td><td>BUILD_STABLE_V1</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>ABI</td><td>" + IntegerToString((int)GOV_VISUAL_ABI_VER_V1) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>dossier_schema</td><td>" + IntegerToString((int)GOV_DOSSIER_SCHEMA_VER_V1) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>replay_validity</td><td>" + replay_ok + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></section>\n");
}

inline void GovBacktestDossierV1_BuildFullHtml(const string sym,
                                              const ENUM_TIMEFRAMES tf,
                                              const string report_ts,
                                              const SGovRuntimeTaggingModuleV1 &mod,
                                              const SGovLineageRegistryStoreV1 &lin,
                                              const SGovRecoveryStoreV1 &rec,
                                              SGovStratAttribSummaryV1 &sum,
                                              const SGovVisualExecSummaryV1 &ex,
                                              const SGovCmpRunRecordV1 &cmp_baseline,
                                              string &html)
{
   html = "";
   SGovStratAttribSummaryV1 tmp = sum;
   for(int z = 0; z < GOV_SATTR_STRAT_COUNT_V1; z++)
      GovStratToxV1_Score(z, sum, sum.tox[z]);

   SGovBacktestTradeStatsV1 tsx;
   GovBacktestTradeStatsV1_FromExecAndTester(ex, tsx);

   const string report_id = GOV_VISUAL_REPORT_PREFIX_V1 + report_ts;

   GovRuntimeVisualHtmlW1_AppendLf(html, "<!DOCTYPE html>\n<html lang=\"en\"><head><meta charset=\"utf-8\"/>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<title>Aurum Synapse — Governance Backtest Dossier</title>\n<style>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, GovRuntimeVisualCssV1_Embedded());
   GovRuntimeVisualHtmlW1_AppendLf(html, "</style></head><body>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<header><h1>Governance Backtest Dossier — " + GovRuntimeVisualHtmlW1_Escape(sym) + " " +
                                         GovRuntimeVisualHtmlW1_Escape(GovBacktestMetaV1_PeriodStr(tf)) + "</h1>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div style=\"font-size:0.8rem;color:#8b949e;margin-top:6px;\">schema=" + IntegerToString((int)GOV_DOSSIER_SCHEMA_VER_V1) +
                                         " | ABI=" + IntegerToString((int)GOV_VISUAL_ABI_VER_V1) + "</div></header>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<nav id=\"toc\"><a href=\"#s-meta\">1</a><a href=\"#s-inp\">2</a><a href=\"#s-sact\">3</a><a href=\"#s-risk\">4</a><a href=\"#s-tstats\">5</a>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<a href=\"#s-kpi\">5b</a><a href=\"#s-strat\">6</a><a href=\"#s-regd\">7</a><a href=\"#s-sess\">8</a><a href=\"#s-vol\">9</a><a href=\"#s-lin\">10</a>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<a href=\"#s-tox\">11</a><a href=\"#s-toxrad\">11b</a><a href=\"#s-capx\">12</a><a href=\"#s-surv\">13</a><a href=\"#s-rtl\">14</a><a href=\"#s-ghash\">15</a>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<a href=\"#s-env\">16</a><a href=\"#s-cmp\">17</a><a href=\"#s-fail\">18</a><a href=\"#s-rec\">19</a><a href=\"#s-reco\">20</a></nav>\n<main>\n");

   GovBacktestMetaV1_AppendSection(report_id, report_ts, sym, tf, g_gov_dossier_git_commit_v1, g_gov_dossier_build_number_v1, tsx, html);
   GovBacktestInpSnapV1_AppendSection(html);
   GovBacktestDossierV1_AppendStrategyActivation(sum, tmp, html);
   GovBacktestDossierV1_AppendRiskConfiguration(html);
   GovBacktestMetaV1_AppendTradeStatistics(ex, tsx, html);

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-kpi\"><h2>5b. Executive KPI strip</h2>\n");
   GovRuntimeVisualDashV1_AppendExecCards(ex, sum, html);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-strat\"><h2>6. Strategy breakdown</h2>\n");
   GovRuntimeVisualChartV1_StrategyTable(sum, html);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");

   GovBacktestDossierV1_AppendRegimeDossierTable(sum, tmp, html);
   GovBacktestDossierV1_AppendSessionTable(sum, html);
   GovBacktestDossierV1_AppendVolTable(sum, html);

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-lin\"><h2>10. Position lineage</h2>\n");
   GovRuntimeVisualLinV1_Build(lin, html);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-tox\"><h2>11. Toxicity analytics</h2>\n");
   GovRuntimeVisualDashV1_AppendToxicityDetail(sum, html);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");
   GovBacktestDossierV1_AppendToxicityRadar(sum, tmp, html);

   GovBacktestCapV1_AppendSection(html);
   GovBacktestSurvV1_AppendMatrix(ex, html);
   GovBacktestReplayTlV1_AppendSection(mod, html, 96);

   GovBacktestDossierV1_AppendGovernanceHashBlock(ex, sum, html);
   GovBacktestEnvSnapV1_AppendSection(sym, html);
   SGovCmpRunRecordV1 cmp_cur;
   GovCmpStoreV1_FillCurrent(report_ts, sym, tf, sum, ex, lin, rec, cmp_cur);
   GovBacktestCmpV1_AppendSection(g_gov_backtest_input_kv_v1, cmp_baseline, cmp_cur, html);
   GovBacktestFailV1_AppendSection(sym, mod, rec, sum, ex, lin, html);
   GovBacktestRecoveryV1_AppendSection(lin, html);
   GovBacktestRecV1_AppendSection(sum, ex, html);

   GovRuntimeVisualHtmlW1_AppendLf(html, "</main><footer>PHASE_20C GovernanceBacktestDossierV1 — cold path — LF-only — embedded CSS/JS</footer>\n<script>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, GovRuntimeVisualJsV1_Embedded());
   GovRuntimeVisualHtmlW1_AppendLf(html, "</script></body></html>\n");
}

#endif // __AURUM_GOV_BACKTEST_DOSSIER_V1_MQH__
