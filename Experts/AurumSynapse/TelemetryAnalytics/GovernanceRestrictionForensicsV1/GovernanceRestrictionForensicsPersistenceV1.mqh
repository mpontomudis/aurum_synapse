//+------------------------------------------------------------------+
//| GovernanceRestrictionForensicsPersistenceV1.mqh                 |
//| PHASE 23.5 — CSV exports (observe-only)                          |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RF_PERSIST_V1_MQH__
#define __AURUM_GOV_RF_PERSIST_V1_MQH__

#include "GovernanceRestrictionForensicsEngineV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionExportV1.mqh"
#include "../GovernanceEcologyEngineV1/GovernanceEcologyDatasetV1.mqh"

#define GOV_RF_FILES_DIR_V1   "AurumSynapse\\TelemetryAnalytics\\RestrictionForensics\\"

inline bool GovRfPersistV1_EnsureDir(void)
{
   FolderCreate("AurumSynapse");
   FolderCreate("AurumSynapse\\TelemetryAnalytics");
   return FolderCreate(GOV_RF_FILES_DIR_V1);
}

inline string GovRfPersistV1_VetoLabel(const int v)
{
   switch(v) {
   case GOV_RF_VETO_CONSENSUS_TOO_LOW_V1: return "CONSENSUS_TOO_LOW";
   case GOV_RF_VETO_REGIME_CONFLICT_V1: return "REGIME_CONFLICT";
   case GOV_RF_VETO_TOXICITY_BLOCK_V1: return "TOXICITY_BLOCK";
   case GOV_RF_VETO_RISK_BLOCK_V1: return "RISK_BLOCK";
   case GOV_RF_VETO_DD_LOCK_V1: return "DD_LOCK";
   case GOV_RF_VETO_VOLATILITY_FILTER_V1: return "VOL_OR_QUALITY";
   case GOV_RF_VETO_SESSION_FILTER_V1: return "SESSION_FILTER";
   case GOV_RF_VETO_SPREAD_FILTER_V1: return "SPREAD_FILTER";
   case GOV_RF_VETO_ECOLOGY_SUPPRESSION_V1: return "ECOLOGY_SUPPRESSION";
   case GOV_RF_VETO_OTHER_V1: return "OTHER";
   default: return "UNKNOWN";
   }
}

inline string GovRfPersistV1_StratStarveClass(const ulong peak)
{
   if(peak >= 5000)
      return "EXTINCT";
   if(peak >= 1500)
      return "DORMANT";
   if(peak >= 400)
      return "STARVING";
   if(peak >= 120)
      return "UNDERUTILIZED";
   return "HEALTHY";
}

inline bool GovRfPersistV1_WriteConsensusRejections(const SGovRfStoreV1 &st)
{
   GovRfPersistV1_EnsureDir();
   const string path = GOV_RF_FILES_DIR_V1 + "consensus_rejections.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "veto_class", "count");
   for(int i = 0; i < GOV_RF_VETO_CLASS_CT_V1; i++)
      FileWrite(h, GovRfPersistV1_VetoLabel(i), IntegerToString((long)st.veto_class_counts[i]));
   FileWrite(h, "consensus_attempts", IntegerToString((long)st.consensus_attempts));
   FileWrite(h, "consensus_passes", IntegerToString((long)st.consensus_passes));
   FileWrite(h, "consensus_failures", IntegerToString((long)st.consensus_failures));
   FileWrite(h, "split_brain_bars", IntegerToString((long)st.consensus_split_brain_bars));
   FileClose(h);
   return true;
}

inline bool GovRfPersistV1_WriteExecutionWaterfall(const SGovRfStoreV1 &st)
{
   GovRfPersistV1_EnsureDir();
   const string path = GOV_RF_FILES_DIR_V1 + "execution_waterfall.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "ts", "stage", "sig_reason", "deny_ct", "veto_class", "strat_slot");
   const int n = st.ring_count;
   for(int k = 0; k < n; k++) {
      const int idx = (st.ring_wi - 1 - k + GOV_RF_RING_CAP_V1 * 2) % GOV_RF_RING_CAP_V1;
      const SGovRfWaterfallEntryV1 e = st.ring[idx];
      FileWrite(h, TimeToString(e.ts, TIME_DATE | TIME_SECONDS), IntegerToString(e.stage), IntegerToString(e.sig_reason),
                IntegerToString(e.deny_ct), GovRfPersistV1_VetoLabel(e.veto_class), IntegerToString(e.strat_slot));
   }
   FileClose(h);
   return true;
}

inline bool GovRfPersistV1_WriteStrategyStarvation(const SGovRfStoreV1 &st)
{
   GovRfPersistV1_EnsureDir();
   const string path = GOV_RF_FILES_DIR_V1 + "strategy_starvation.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "strategy", "bars_since_signal", "peak_drought_bars", "class");
   for(int i = 0; i < GOV_RF_STRAT_CT_V1; i++) {
      FileWrite(h, GovStratExpV1_StratLabel(i), IntegerToString(st.strat_starve_bars[i]), IntegerToString((long)st.strat_starve_peak[i]),
                GovRfPersistV1_StratStarveClass(st.strat_starve_peak[i]));
   }
   FileClose(h);
   return true;
}

inline bool GovRfPersistV1_WriteRegimeOverfiltering(const SGovRfStoreV1 &st)
{
   GovRfPersistV1_EnsureDir();
   const string path = GOV_RF_FILES_DIR_V1 + "regime_overfiltering.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "eff_min_consensus_slot", "bars_at_eff_min");
   for(int i = 0; i < 9; i++)
      FileWrite(h, IntegerToString(i + 1), IntegerToString((long)st.hist_eff_min_consensus[i]));
   FileWrite(h, "regime_transition_bars", IntegerToString((long)st.regime_transition_bars));
   FileWrite(h, "bars_observed", IntegerToString((long)st.bars_observed));
   FileClose(h);
   return true;
}

inline bool GovRfPersistV1_WriteEcologySuppression(const SGovEcologyStoreV1 &eco, const SGovRfStoreV1 &st)
{
   GovRfPersistV1_EnsureDir();
   const string path = GOV_RF_FILES_DIR_V1 + "ecology_suppression.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "strat", "bars_suppression", "bars_throttled", "bars_participation", "recovery_cycles", "failure_cycles");
   for(int i = 0; i < GOV_ECO_STRAT_COUNT_V1; i++) {
      FileWrite(h, GovStratExpV1_StratLabel(i), IntegerToString((long)eco.s[i].bars_suppression),
                IntegerToString((long)eco.s[i].bars_throttled), IntegerToString((long)eco.s[i].bars_participation),
                IntegerToString((long)eco.s[i].recovery_cycles), IntegerToString((long)eco.s[i].failure_cycles));
   }
   FileWrite(h, "__rf_aggregate__", IntegerToString((long)st.ecology_suppress_clears_total),
             IntegerToString((long)st.ecology_throttle_events_total), IntegerToString((long)st.ecology_buy_removed_bars),
             IntegerToString((long)st.ecology_sell_removed_bars), "", "");
   FileClose(h);
   return true;
}

inline bool GovRfPersistV1_WriteDdAnomalies(const SGovRfStoreV1 &st)
{
   GovRfPersistV1_EnsureDir();
   const string path = GOV_RF_FILES_DIR_V1 + "dd_anomalies.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   const double avgdiv = (st.dd_probe_bars > 0) ? (st.sum_dd_divergence_pct / (double)st.dd_probe_bars) : 0.0;
   FileWrite(h, "metric", "value");
   FileWrite(h, "dd_probe_bars", IntegerToString((long)st.dd_probe_bars));
   FileWrite(h, "dd_anomaly_bars", IntegerToString((long)st.dd_anomaly_bars));
   FileWrite(h, "avg_equity_balance_divergence_pct", DoubleToString(avgdiv, 4));
   FileWrite(h, "max_equity_balance_divergence_pct", DoubleToString(st.max_dd_divergence_pct, 4));
   FileWrite(h, "peak_balance_obs", DoubleToString(st.peak_balance_obs, 2));
   FileWrite(h, "avg_floating_pressure_pm", DoubleToString((st.dd_probe_bars > 0 ? st.sum_floating_pressure_pm / (double)st.dd_probe_bars : 0.0), 4));
   FileClose(h);
   return true;
}

inline void GovRfPersistV1_FillRootCauseScratch(SGovRfStoreV1 &st)
{
   GovRfEngV1_RecomputeRootCauseVector(st);
}

inline bool GovRfPersistV1_WriteGovernancePressure(SGovRfStoreV1 &st)
{
   GovRfPersistV1_EnsureDir();
   GovRfPersistV1_FillRootCauseScratch(st);
   const string path = GOV_RF_FILES_DIR_V1 + "governance_pressure.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   const double bars = (double)MathMax(1UL, st.bars_observed);
   const double execDeny = (double)st.risk_cantrade_denies / (double)MathMax(1UL, st.risk_cantrade_samples);
   const double overblock = 1000.0 * execDeny;
   FileWrite(h, "metric", "value_pm_or_permille_note");
   FileWrite(h, "risk_overblocking_score_pm", DoubleToString(overblock, 2));
   FileWrite(h, "execution_denial_ratio_permille", DoubleToString(execDeny * 1000.0, 2));
   FileWrite(h, "consensus_failure_ratio_permille", DoubleToString((st.consensus_attempts > 0 ? (double)st.consensus_failures / (double)st.consensus_attempts * 1000.0 : 0.0), 2));
   FileWrite(h, "ecology_suppress_clears_per_1000_bars", DoubleToString((double)st.ecology_suppress_clears_total / bars, 4));
   FileWrite(h, "restriction_rc_rank1", IntegerToString(st.last_rc_rank1));
   FileWrite(h, "restriction_rc_rank2", IntegerToString(st.last_rc_rank2));
   FileWrite(h, "restriction_rc_rank3", IntegerToString(st.last_rc_rank3));
   FileWrite(h, "restriction_rc_score1_pm", DoubleToString(st.last_rc_score1_pm, 2));
   FileWrite(h, "restriction_rc_score2_pm", DoubleToString(st.last_rc_score2_pm, 2));
   FileWrite(h, "restriction_rc_score3_pm", DoubleToString(st.last_rc_score3_pm, 2));
   FileWrite(h, "lost_opportunities_risk_halt", IntegerToString((long)st.lost_opportunities_risk_halt));
   FileWrite(h, "trade_open_success", IntegerToString((long)st.trade_open_success));
   FileClose(h);
   return true;
}

inline bool GovRfPersistV1_WriteAll(SGovRfStoreV1 &st, const SGovEcologyStoreV1 &eco)
{
   if(!st.enabled)
      return true;
   bool ok = true;
   ok &= GovRfPersistV1_WriteConsensusRejections(st);
   ok &= GovRfPersistV1_WriteExecutionWaterfall(st);
   ok &= GovRfPersistV1_WriteStrategyStarvation(st);
   ok &= GovRfPersistV1_WriteRegimeOverfiltering(st);
   ok &= GovRfPersistV1_WriteEcologySuppression(eco, st);
   ok &= GovRfPersistV1_WriteDdAnomalies(st);
   ok &= GovRfPersistV1_WriteGovernancePressure(st);
   return ok;
}

#endif // __AURUM_GOV_RF_PERSIST_V1_MQH__
