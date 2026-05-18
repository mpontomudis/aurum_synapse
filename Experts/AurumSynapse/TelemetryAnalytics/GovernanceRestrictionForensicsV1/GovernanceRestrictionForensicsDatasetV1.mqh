//+------------------------------------------------------------------+
//| GovernanceRestrictionForensicsDatasetV1.mqh                     |
//| PHASE 23.5 — governance restriction forensics (observe-only)   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RF_DATASET_V1_MQH__
#define __AURUM_GOV_RF_DATASET_V1_MQH__

#include "../../Core/Constants.mqh"

#define GOV_RF_STRAT_CT_V1       8
#define GOV_RF_RING_CAP_V1       256
#define GOV_RF_VETO_CLASS_CT_V1  11
#define GOV_RF_STAGE_CT_V1       16

enum ENUM_GOV_RF_VETO_CLASS_V1
{
   GOV_RF_VETO_UNKNOWN_V1 = 0,
   GOV_RF_VETO_CONSENSUS_TOO_LOW_V1,
   GOV_RF_VETO_REGIME_CONFLICT_V1,
   GOV_RF_VETO_TOXICITY_BLOCK_V1,
   GOV_RF_VETO_RISK_BLOCK_V1,
   GOV_RF_VETO_DD_LOCK_V1,
   GOV_RF_VETO_VOLATILITY_FILTER_V1,
   GOV_RF_VETO_SESSION_FILTER_V1,
   GOV_RF_VETO_SPREAD_FILTER_V1,
   GOV_RF_VETO_ECOLOGY_SUPPRESSION_V1,
   GOV_RF_VETO_OTHER_V1
};

enum ENUM_GOV_RF_PIPELINE_STAGE_V1
{
   GOV_RF_STAGE_SIGNAL_OPEN_V1 = 1,
   GOV_RF_STAGE_EARLY_MARKET_V1 = 2,
   GOV_RF_STAGE_RISK_EARLY_V1 = 3,
   GOV_RF_STAGE_TIME_V1 = 4,
   GOV_RF_STAGE_SPREAD_V1 = 5,
   GOV_RF_STAGE_CONSENSUS_V1 = 6,
   GOV_RF_STAGE_QUALITY_V1 = 7,
   GOV_RF_STAGE_REQUIREMENT_V1 = 8,
   GOV_RF_STAGE_RISK_HALT_V1 = 9,
   GOV_RF_STAGE_POSITION_V1 = 10,
   GOV_RF_STAGE_EXEC_ALLOWED_V1 = 11
};

struct SGovRfWaterfallEntryV1
{
   datetime ts;
   int      stage;
   int      sig_reason;
   int      deny_ct;
   int      veto_class;
   int      strat_slot;
};

struct SGovRfStoreV1
{
   bool     enabled;

   ulong    bars_observed;
   ulong    bars_pipeline_entered;

   ulong    consensus_attempts;
   ulong    consensus_passes;
   ulong    consensus_failures;

   ulong    sum_buy_votes;
   ulong    sum_sell_votes;
   ulong    sum_none_votes;

   ulong    veto_class_counts[GOV_RF_VETO_CLASS_CT_V1];
   ulong    reject_by_sig_reason[24];
   ulong    reject_stage_counts[GOV_RF_STAGE_CT_V1];

   ulong    risk_cantrade_samples;
   ulong    risk_cantrade_denies;
   ulong    risk_deny_dd_lock;
   ulong    risk_deny_daily;
   ulong    risk_deny_consec;
   ulong    risk_deny_other;

   int      risk_deny_streak_bars;
   int      risk_thaw_bars_accum;
   ulong    bars_under_risk_denial;

   double   peak_balance_obs;
   ulong    dd_probe_bars;
   ulong    dd_anomaly_bars;
   double   sum_dd_divergence_pct;
   double   max_dd_divergence_pct;
   double   sum_floating_pressure_pm;

   ulong    ecology_suppress_clears_total;
   ulong    ecology_throttle_events_total;
   ulong    ecology_buy_removed_bars;
   ulong    ecology_sell_removed_bars;

   ulong    hist_eff_min_consensus[9];

   ulong    regime_transition_bars;
   int      strat_starve_bars[GOV_RF_STRAT_CT_V1];
   ulong    strat_starve_peak[GOV_RF_STRAT_CT_V1];

   ulong    bars_with_executable_consensus;
   ulong    lost_opportunities_risk_halt;
   ulong    trade_open_success;

   ulong    consensus_split_brain_bars;

   int      last_eff_min_consensus;
   int      last_base_min_consensus;

   SGovRfWaterfallEntryV1 ring[GOV_RF_RING_CAP_V1];
   int      ring_wi;
   int      ring_count;

   int      last_rc_rank1;
   int      last_rc_rank2;
   int      last_rc_rank3;
   double   last_rc_score1_pm;
   double   last_rc_score2_pm;
   double   last_rc_score3_pm;
};

inline SGovRfStoreV1 g_gov_rf_v1;

inline void GovRfDsV1_ClearRing(SGovRfStoreV1 &st)
{
   st.ring_wi = 0;
   st.ring_count = 0;
   for(int i = 0; i < GOV_RF_RING_CAP_V1; i++) {
      st.ring[i].ts = 0;
      st.ring[i].stage = 0;
      st.ring[i].sig_reason = 0;
      st.ring[i].deny_ct = 0;
      st.ring[i].veto_class = 0;
      st.ring[i].strat_slot = -1;
   }
}

inline void GovRfDsV1_Init(SGovRfStoreV1 &st)
{
   st.enabled = false;
   st.bars_observed = 0;
   st.bars_pipeline_entered = 0;
   st.consensus_attempts = 0;
   st.consensus_passes = 0;
   st.consensus_failures = 0;
   st.sum_buy_votes = 0;
   st.sum_sell_votes = 0;
   st.sum_none_votes = 0;
   for(int v = 0; v < GOV_RF_VETO_CLASS_CT_V1; v++)
      st.veto_class_counts[v] = 0;
   for(int r = 0; r < 24; r++)
      st.reject_by_sig_reason[r] = 0;
   for(int s = 0; s < GOV_RF_STAGE_CT_V1; s++)
      st.reject_stage_counts[s] = 0;
   st.risk_cantrade_samples = 0;
   st.risk_cantrade_denies = 0;
   st.risk_deny_dd_lock = 0;
   st.risk_deny_daily = 0;
   st.risk_deny_consec = 0;
   st.risk_deny_other = 0;
   st.risk_deny_streak_bars = 0;
   st.risk_thaw_bars_accum = 0;
   st.bars_under_risk_denial = 0;
   st.peak_balance_obs = 0.0;
   st.dd_probe_bars = 0;
   st.dd_anomaly_bars = 0;
   st.sum_dd_divergence_pct = 0.0;
   st.max_dd_divergence_pct = 0.0;
   st.sum_floating_pressure_pm = 0.0;
   st.ecology_suppress_clears_total = 0;
   st.ecology_throttle_events_total = 0;
   st.ecology_buy_removed_bars = 0;
   st.ecology_sell_removed_bars = 0;
   for(int h = 0; h < 9; h++)
      st.hist_eff_min_consensus[h] = 0;
   st.regime_transition_bars = 0;
   for(int i = 0; i < GOV_RF_STRAT_CT_V1; i++) {
      st.strat_starve_bars[i] = 0;
      st.strat_starve_peak[i] = 0;
   }
   st.bars_with_executable_consensus = 0;
   st.lost_opportunities_risk_halt = 0;
   st.trade_open_success = 0;
   st.consensus_split_brain_bars = 0;
   st.last_eff_min_consensus = 0;
   st.last_base_min_consensus = 0;
   GovRfDsV1_ClearRing(st);
   st.last_rc_rank1 = 0;
   st.last_rc_rank2 = 0;
   st.last_rc_rank3 = 0;
   st.last_rc_score1_pm = 0.0;
   st.last_rc_score2_pm = 0.0;
   st.last_rc_score3_pm = 0.0;
}

#endif // __AURUM_GOV_RF_DATASET_V1_MQH__
