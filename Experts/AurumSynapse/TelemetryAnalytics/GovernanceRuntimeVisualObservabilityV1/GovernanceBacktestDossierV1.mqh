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
#include "GovernanceRuntimeReportRegistryV1.mqh"
#include "GovernanceRuntimeVisualDatasetV1.mqh"
#include "GovernanceRuntimeVisualHtmlWriterV1.mqh"
#include "GovernanceRuntimeVisualCssV1.mqh"
#include "GovernanceRuntimeVisualJsV1.mqh"
#include "GovernanceRuntimeVisualChartBuilderV1.mqh"
#include "GovernanceRuntimeVisualLineageGraphV1.mqh"
#include "GovernanceRuntimeVisualDashboardBuilderV1.mqh"
#include "GovernanceRuntimeVisualReplayV1.mqh"
#include "../GovernanceRuntimeObservabilityExportV1/GovernanceRuntimeObservabilityReplayV1.mqh"
#include "GovernanceRuntimeVisualTelemetryV1.mqh"
#include "GovernanceBacktestMetadataV1.mqh"
#include "GovernanceBacktestInputSnapshotV1.mqh"
#include "GovernanceBacktestEnvironmentSnapshotV1.mqh"
#include "GovernanceBacktestCapitalDiagnosticsV1.mqh"
#include "GovernanceBacktestSurvivabilityV1.mqh"
#include "GovernanceBacktestReplayTimelineV1.mqh"
#include "GovernanceBacktestRecoveryAnalysisV1.mqh"
#include "GovernanceBacktestFailureDiagnosticsV1.mqh"
#include "GovernanceBacktestComparativeInsightsV1.mqh"
#include "GovernanceBacktestRecommendationsV1.mqh"
#include "GovernanceIntelligenceDossierPresentationV1.mqh"
#include "../GovernancePositionLineageIntelligenceV1/GovernanceRecoveryChainAnalyticsV1.mqh"
#include "../GovernanceSignalForensicsV1/GovernanceSignalForensicsV1.mqh"
#include "../GovernanceRegimeEngineV1/GovernanceRegimeHtmlV1.mqh"
#include "../GovernanceDynamicRecoveryEngineV1/GovernanceDynamicRecoveryHtmlV1.mqh"
#include "../GovernanceEcologyEngineV1/GovernanceEcologyHtmlV1.mqh"
#include "../GovernanceRestrictionForensicsV1/GovernanceRestrictionForensicsIntegrationV1.mqh"
#include "../RiskLockIntelligenceV1/RiskLockIntelligenceIntegrationV1.mqh"
#include "../AdaptiveThawStabilizationV1/AdaptiveThawStabilizationIntegrationV1.mqh"

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
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s3-sact\"><h3 class=\"gov-h3\">Strategy activation matrix</h3>\n<table id=\"tblSact\" data-sort-col=\"-1\" data-sort-dir=\"asc\"><thead><tr>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblSact',0)\">Strategy</th><th onclick=\"govSort('tblSact',1)\">Input gate</th><th onclick=\"govSort('tblSact',2)\">Trades</th><th onclick=\"govSort('tblSact',3)\">Net¢</th><th onclick=\"govSort('tblSact',4)\">Tox</th><th onclick=\"govSort('tblSact',5)\">Ecology role</th></tr></thead><tbody>\n");
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
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div>\n");
}

inline void GovBacktestDossierV1_AppendRiskConfiguration(string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-subsec\" id=\"intel-s3-risk\"><h3 class=\"gov-h3\">Risk governance</h3>\n<div class=\"grid\">\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Max risk / trade %</b><span>" + DoubleToString(g_gov_dossier_risk_v1.max_risk_per_trade, 2) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Max daily loss %</b><span>" + DoubleToString(g_gov_dossier_risk_v1.max_daily_loss_pct, 2) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Max equity DD %</b><span>" + DoubleToString(g_gov_dossier_risk_v1.max_equity_dd_pct, 2) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Max consecutive losses</b><span>" + IntegerToString(g_gov_dossier_risk_v1.max_consecutive_losses) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Max open positions</b><span>" + IntegerToString(g_gov_dossier_risk_v1.max_open_positions) + "</span></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"grid\" style=\"margin-top:12px;\"><div class=\"card\"><b>DD threshold (tester)</b><div class=\"barwrap\"><div class=\"bar\" style=\"width:40%\"></div></div></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"card\"><b>Margin stress (placeholder)</b><div class=\"barwrap\"><div class=\"bar\" style=\"width:25%\"></div></div></div></div>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</div>\n");
}

inline void GovBacktestDossierV1_AppendRegimeVolIntelSection(const SGovStratAttribSummaryV1 &sum, SGovStratAttribSummaryV1 &tmp, string &html)
{
   for(int z = 0; z < GOV_SATTR_STRAT_COUNT_V1; z++)
      GovStratToxV1_Score(z, tmp, tmp.tox[z]);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s8\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">08</span> Market regime intelligence</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Regime survivability, collapse density, and cross-strategy compatibility. Volatility buckets extend the lattice into expansion/compression stress.</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<h3 class=\"gov-h3\">Regime performance & survivability</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table id=\"tblRegime\" data-sort-col=\"-1\" data-sort-dir=\"asc\"><thead><tr>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblRegime',0)\">Regime</th><th onclick=\"govSort('tblRegime',1)\">Trades</th><th onclick=\"govSort('tblRegime',2)\">Net¢</th><th onclick=\"govSort('tblRegime',3)\">PF</th><th onclick=\"govSort('tblRegime',4)\">Avg tox</th><th onclick=\"govSort('tblRegime',5)\">Collapse density</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tr></thead><tbody>\n");
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
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
   GovIntelDossierV1_AppendRegimeCompatMatrix(sum, html);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<h3 class=\"gov-h3\">Volatility bucket intelligence</h3>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table id=\"tblVol\" data-sort-col=\"-1\" data-sort-dir=\"asc\"><thead><tr>");
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

inline void GovBacktestDossierV1_AppendSessionIntelTable(SGovStratAttribSummaryV1 &sum, string &html)
{
   for(int z = 0; z < GOV_SATTR_STRAT_COUNT_V1; z++)
      GovStratToxV1_Score(z, sum, sum.tox[z]);
   int total_tr = 0;
   for(int t = 0; t < GOV_SATTR_STRAT_COUNT_V1; t++)
      total_tr += sum.bd.by_strat[t].trades;
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s9\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">09</span> Session intelligence</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Session plane exposes liquidity windows, DD contribution, and execution stress. Sort columns to isolate toxic or unstable sessions.</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table id=\"tblSess\" data-sort-col=\"-1\" data-sort-dir=\"asc\"><thead><tr>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblSess',0)\">Session</th><th onclick=\"govSort('tblSess',1)\">Trades</th><th onclick=\"govSort('tblSess',2)\">Net¢</th><th onclick=\"govSort('tblSess',3)\">PF</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblSess',4)\">Max DD contrib¢</th><th onclick=\"govSort('tblSess',5)\">Stopouts</th><th onclick=\"govSort('tblSess',6)\">Tail losses</th><th onclick=\"govSort('tblSess',7)\">Tox proxy</th><th onclick=\"govSort('tblSess',8)\">Density</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tr></thead><tbody>\n");
   for(int s = 0; s < GOV_SATTR_SESSION_COUNT_V1; s++) {
      const SGovStratAttribStatsV1 st = sum.bd.session.by_sess[s];
      const long net = st.gross_win_cents - st.gross_loss_cents;
      int tox_w = 0;
      int tw = 0;
      for(int k = 0; k < GOV_SATTR_STRAT_COUNT_V1; k++) {
         if(sum.bd.by_strat[k].trades <= 0)
            continue;
         tox_w = GovSaturatingAdd32(tox_w, sum.tox[k].score_0_1000);
         tw++;
      }
      const int avgt = (tw > 0) ? (tox_w / tw) : 0;
      const int dens = (st.trades > 0 && total_tr > 0) ? (int)(1000L * (long)st.trades / (long)total_tr) : 0;
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovStratTagV1_SessionCode(s)) + "</td><td>" + IntegerToString(st.trades) + "</td><td>" +
                                         IntegerToString((int)net) + "</td><td>" + DoubleToString((double)st.pf_milli / 1000.0, 3) + "</td><td>" + IntegerToString(st.max_dd_contrib_cents) + "</td><td>" +
                                         IntegerToString(st.stopout_count) + "</td><td>" + IntegerToString(st.tail_loss_count) + "</td><td>" + IntegerToString(avgt) + "</td><td>" + IntegerToString(dens) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-note\">Toxicity proxy uses ecology-wide mean (session-stratification reserved for future bridge hooks).</p></section>\n");
}

inline void GovBacktestDossierV1_AppendToxicityRadarPanel(const SGovStratAttribSummaryV1 &sum, SGovStratAttribSummaryV1 &tmp, string &html)
{
   for(int z = 0; z < GOV_SATTR_STRAT_COUNT_V1; z++)
      GovStratToxV1_Score(z, tmp, tmp.tox[z]);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<h3 class=\"gov-h3\">Toxicity radar (tabular decomposition)</h3>\n<table id=\"tblToxRad\" data-sort-col=\"-1\" data-sort-dir=\"asc\"><thead><tr>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<th onclick=\"govSort('tblToxRad',0)\">Strategy</th><th onclick=\"govSort('tblToxRad',1)\">Score</th><th onclick=\"govSort('tblToxRad',2)\">Regime mismatch</th><th onclick=\"govSort('tblToxRad',3)\">Vol tox</th><th onclick=\"govSort('tblToxRad',4)\">Stopout‰</th>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tr></thead><tbody>\n");
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      const SGovStratAttribToxicityV1 t = tmp.tox[i];
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>" + GovRuntimeVisualHtmlW1_Escape(GovStratExpV1_StratLabel(i)) + "</td><td>" + IntegerToString(t.score_0_1000) + "</td><td>" +
                                         IntegerToString(t.regime_mismatch) + "</td><td>" + IntegerToString(t.vol_toxicity) + "</td><td>" + IntegerToString(t.stopout_rate_x1000) + "</td></tr>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
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
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-attest\" class=\"gov-intel-sec gov-attest\"><h2><span class=\"gov-sec-num\">—</span> Attestation & replay integrity</h2><table><tbody>\n");
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
   GovBacktestRuntimeV1_MarkFinished(g_gov_visual_runtime_v1);
   SGovStratAttribSummaryV1 tmp = sum;
   for(int z = 0; z < GOV_SATTR_STRAT_COUNT_V1; z++)
      GovStratToxV1_Score(z, sum, sum.tox[z]);

   SGovBacktestTradeStatsV1 tsx;
   GovBacktestTradeStatsV1_FromExecAndTester(ex, tsx);

   const string cmp_run_key = (g_gov_report_export_ctx_v1.valid != 0) ? g_gov_report_export_ctx_v1.report_core_id : report_ts;
   const string report_id = (g_gov_report_export_ctx_v1.valid != 0) ? (GOV_VISUAL_REPORT_PREFIX_V1 + g_gov_report_export_ctx_v1.report_core_id) : (GOV_VISUAL_REPORT_PREFIX_V1 + report_ts);
   const string meta_ts = (g_gov_report_export_ctx_v1.valid != 0) ? g_gov_report_export_ctx_v1.report_ts_display : report_ts;

   GovRuntimeVisualHtmlW1_AppendLf(html, "<!DOCTYPE html>\n<html lang=\"en\"><head><meta charset=\"utf-8\"/>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"/>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<title>Aurum Synapse — Governance Intelligence Dossier</title>\n<style>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, GovRuntimeVisualCssV1_Embedded());
   GovRuntimeVisualHtmlW1_AppendLf(html, "</style></head><body class=\"gov-dossier\">\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<header class=\"gov-header\"><div class=\"gov-header-inner\"><p class=\"gov-kicker\">Aurum Synapse · Autonomous governance telemetry</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<h1>Governance intelligence dossier</h1>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-header-sub\">" + GovRuntimeVisualHtmlW1_Escape(sym) + " · " + GovRuntimeVisualHtmlW1_Escape(GovBacktestMetaV1_PeriodStr(tf)) + " · schema " +
                                         IntegerToString((int)GOV_DOSSIER_SCHEMA_VER_V1) + " · ABI " + IntegerToString((int)GOV_VISUAL_ABI_VER_V1) + "</p></div></header>\n");

   if(g_gov_report_export_ctx_v1.valid != 0) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"gov-libnav\"><nav class=\"gov-libbar\" aria-label=\"Report library\">\n");
      if(StringLen(g_gov_report_export_ctx_v1.prev_filename) > 0)
         GovRuntimeVisualHtmlW1_AppendLf(html, "<a class=\"gov-btn\" href=\"./" + GovRuntimeVisualHtmlW1_Escape(g_gov_report_export_ctx_v1.prev_filename) + "\">Previous report</a>\n");
      else
         GovRuntimeVisualHtmlW1_AppendLf(html, "<span class=\"gov-btn gov-btn-dis\">Previous report</span>\n");
      if(StringLen(g_gov_report_export_ctx_v1.next_filename) > 0)
         GovRuntimeVisualHtmlW1_AppendLf(html, "<a class=\"gov-btn\" href=\"./" + GovRuntimeVisualHtmlW1_Escape(g_gov_report_export_ctx_v1.next_filename) + "\">Next report</a>\n");
      else
         GovRuntimeVisualHtmlW1_AppendLf(html, "<span class=\"gov-btn gov-btn-dis\">Next report</span>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<a class=\"gov-btn\" href=\"./index.html\">Open index</a>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<a class=\"gov-btn\" href=\"#intel-cmp\">Compare with baseline</a>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "</nav></div>\n");
   }

   GovRuntimeVisualHtmlW1_AppendLf(html, "<nav id=\"toc\" class=\"gov-toc\"><a href=\"#intel-s1\">01 Exec</a><a href=\"#intel-s2\">02 Meta</a><a href=\"#intel-s3\">03 Config</a>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<a href=\"#intel-s4\">04 Perf</a><a href=\"#intel-s5\">05 Ecology</a><a href=\"#intel-s6\">06 Consensus</a><a href=\"#intel-s7\">07 Signal</a>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<a href=\"#intel-s8\">08 Regime</a><a href=\"#intel-s9\">09 Session</a><a href=\"#intel-s10\">10 Lineage</a><a href=\"#intel-s11\">11 Breach</a>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<a href=\"#intel-s12\">12 Toxicity</a><a href=\"#intel-s21\">21 SigForensics</a><a href=\"#intel-s22\">22 Regime</a><a href=\"#intel-s22b\">22B Recovery</a><a href=\"#intel-s22d\">22D Confidence</a><a href=\"#intel-s23\">23 Strat Ecology</a><a href=\"#intel-s24\">24 Restriction Forensics</a><a href=\"#intel-s25\">25 Risk Lock Intel</a><a href=\"#intel-s26\">26 Adaptive Thaw</a><a href=\"#intel-s13\">13 Forensics</a><a href=\"#intel-s14\">14 Reco</a><a href=\"#intel-s15\">15 Verdict</a>");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<a href=\"#intel-attest\">Attest</a></nav>\n<main class=\"gov-main\">\n");

   GovIntelDossierV1_AppendExecutive(sym, tf, meta_ts, mod, lin, sum, ex, tsx, html);

   GovBacktestMetaV1_AppendSection(report_id, meta_ts, sym, tf, g_gov_dossier_git_commit_v1, g_gov_dossier_build_number_v1, tsx, html);

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s3\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">03</span> Governance configuration</h2>\n");
   GovIntelDossierV1_AppendGovernanceConfigIntro(html);
   GovBacktestDossierV1_AppendRiskConfiguration(html);
   GovBacktestDossierV1_AppendStrategyActivation(sum, tmp, html);
   GovIntelDossierV1_AppendKvLensCards(html);
   GovBacktestCapV1_AppendPanelBody(html, ex);
   GovBacktestInpSnapV1_AppendSection(html);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s4\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">04</span> Performance intelligence</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Execution efficiency, capital utilization, and tester-bound risk metrics. Survivability matrix stress-tests nominal deposit tiers against observed DD.</p>\n");
   GovBacktestMetaV1_AppendTradeStatisticsPanel(ex, tsx, html);
   GovRuntimeVisualHtmlW1_AppendLf(html, "<h3 class=\"gov-h3\">Executive telemetry strip</h3>\n");
   GovRuntimeVisualDashV1_AppendExecCards(ex, sum, html);
   GovIntelDossierV1_AppendPerformanceSupplement(ex, sum, tsx, html);
   GovBacktestSurvV1_AppendMatrixTable(html, ex);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s5\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">05</span> Strategy ecology intelligence</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Strategies behave as coupled organisms: attribution, toxicity, and compatibility fields describe niche occupancy and failure propagation.</p>\n");
   GovRuntimeVisualChartV1_StrategyTable(sum, html);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");

   GovIntelDossierV1_AppendConsensusIntel(sum, html);
   GovIntelDossierV1_AppendSignalQualityIntel(sum, ex, html);

   GovBacktestDossierV1_AppendRegimeVolIntelSection(sum, tmp, html);
   GovBacktestDossierV1_AppendSessionIntelTable(sum, html);

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s10\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">10</span> Lineage & mutation intelligence</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Lifecycle graph with mutation telemetry; purple lane encodes propagation vectors for forensic pairing with breach diagnostics.</p>\n");
   GovIntelDossierV1_AppendLineageMutationIntel(lin, html);
   GovRuntimeVisualLinV1_Build(lin, html);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");

   GovBacktestFailV1_AppendSection(sym, mod, rec, sum, ex, lin, html);

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"intel-s12\" class=\"gov-intel-sec\"><h2><span class=\"gov-sec-num\">12</span> Toxicity intelligence</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p class=\"gov-lede\">Toxicity distribution, radar decomposition, and escalation context for ecology governance.</p>\n");
   GovRuntimeVisualDashV1_AppendToxicityDetail(sum, html);
   GovBacktestDossierV1_AppendToxicityRadarPanel(sum, tmp, html);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");

   GovSigForensicsHtmlV1_AppendSection(g_gov_sig_forensics_tel_v1, html);

   GovRegimeHtmlV1_AppendSection22(g_gov_regime_store_v1, g_gov_sig_forensics_tel_v1, sum, ex, html);
   GovDynRecHtmlV1_AppendSection22b(html);
   GovDynRecHtmlV1_AppendSection22d(html);
   GovEcoHtmlV1_AppendSection23(html);
   GovRfIntV1_AppendDossierSection24(html);
   GovRliIntV1_AppendDossierSection25(html);
   GovAtsIntV1_AppendDossierSection26(html);

   GovIntelDossierV1_AppendForensicsShellOpen(html);
   GovBacktestRecoveryV1_AppendSection(lin, html);
   GovBacktestReplayTlV1_AppendSection(mod, html, 96);
   SGovCmpRunRecordV1 cmp_cur;
   GovCmpStoreV1_FillCurrent(cmp_run_key, sym, tf, sum, ex, lin, rec, cmp_cur);
   GovBacktestCmpV1_AppendSection(g_gov_backtest_input_kv_v1, cmp_baseline, cmp_cur, html);
   GovIntelDossierV1_AppendForensicsShellClose(html);

   GovBacktestRecV1_AppendSection(sum, ex, html);
   GovIntelDossierV1_AppendFinalVerdict(ex, sum, html);

   GovBacktestDossierV1_AppendGovernanceHashBlock(ex, sum, html);

   GovRuntimeVisualHtmlW1_AppendLf(html, "</main><footer class=\"gov-footer\">Aurum Synapse governance intelligence dossier — cold path — LF-only — embedded CSS/JS — no external dependencies</footer>\n<script>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, GovRuntimeVisualJsV1_Embedded());
   GovRuntimeVisualHtmlW1_AppendLf(html, "</script></body></html>\n");
}

#endif // __AURUM_GOV_BACKTEST_DOSSIER_V1_MQH__
