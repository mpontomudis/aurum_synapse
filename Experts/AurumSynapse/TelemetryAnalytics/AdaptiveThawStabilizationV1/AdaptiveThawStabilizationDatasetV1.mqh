//+------------------------------------------------------------------+
//| AdaptiveThawStabilizationDatasetV1.mqh                         |
//| PHASE 23.7 — adaptive thaw / anti-paralysis telemetry (observe) |
//+------------------------------------------------------------------+
#ifndef __AURUM_ATS_DATASET_V1_MQH__
#define __AURUM_ATS_DATASET_V1_MQH__

#define GOV_ATS_THAW_STATE_CT_V1     6
#define GOV_ATS_DECAY_CT_V1          4
#define GOV_ATS_FLOAT_V2_CT_V1       5
#define GOV_ATS_RECOVERY_CT_V1       5
#define GOV_ATS_PARALYSIS_CT_V1     4

enum ENUM_GOV_ATS_THAW_STATE_V1
{
   GOV_ATS_THAW_NONE_V1 = 0,
   GOV_ATS_THAW_WEAK_V1,
   GOV_ATS_THAW_STABILIZING_V1,
   GOV_ATS_THAW_HEALTHY_V1,
   GOV_ATS_THAW_RELAPSE_RISK_V1,
   GOV_ATS_THAW_FALSE_RECOVERY_V1
};

enum ENUM_GOV_ATS_DECAY_CLASS_V1
{
   GOV_ATS_DECAY_HEALTHY_V1 = 0,
   GOV_ATS_DECAY_SLOW_V1,
   GOV_ATS_DECAY_STUCK_V1,
   GOV_ATS_DECAY_PARALYSIS_LOOP_V1
};

enum ENUM_GOV_ATS_FLOAT_V2_V1
{
   GOV_ATS_FLOAT2_NORMAL_V1 = 0,
   GOV_ATS_FLOAT2_ELEVATED_V1,
   GOV_ATS_FLOAT2_TEMP_SPIKE_V1,
   GOV_ATS_FLOAT2_STRUCTURAL_V1,
   GOV_ATS_FLOAT2_COLLAPSE_V1
};

enum ENUM_GOV_ATS_RECOVERY_STATE_V1
{
   GOV_ATS_REC_COLLAPSING_V1 = 0,
   GOV_ATS_REC_STALLED_V1,
   GOV_ATS_REC_STABILIZING_V1,
   GOV_ATS_REC_RECOVERING_V1,
   GOV_ATS_REC_HEALTHY_V1
};

enum ENUM_GOV_ATS_PARALYSIS_STATE_V1
{
   GOV_ATS_PAR_HEALTHY_V1 = 0,
   GOV_ATS_PAR_ELEVATED_V1,
   GOV_ATS_PAR_OVERDEFENSIVE_V1,
   GOV_ATS_PAR_PARALYZED_V1
};

struct SGovAtsStoreV1
{
   bool     enabled;
   ulong    bars_observed;

   double   prev_eq_dd;
   double   recovery_ema;
   ulong    prev_ecology_part_sum;

   double   last_thaw_confidence_pm;
   double   last_thaw_relapse_pm;
   double   last_thaw_stability_pm;
   int      last_thaw_state;

   ulong    lock_age_bars_last;
   double   last_lock_decay_rate_pm;
   int      last_decay_class;

   double   last_float_norm_pm;
   double   last_float_recovery_vel_pm;
   int      last_float_v2_class;

   double   last_dd_context_pm;
   double   last_vol_adj_dd;
   double   last_spread_adj_dd;

   double   last_recovery_momentum_pm;
   int      last_recovery_state;

   double   last_paralysis_index_pm;
   double   last_defensive_overreaction_pm;
   int      last_paralysis_state;

   double   last_exec_continuity_pm;
   ulong    last_bars_since_exec_hint;

   double   last_ecology_recovery_pm;
   double   last_suppression_decay_pm;

   double   last_stress_accum_pm;
   double   last_stress_decay_pm;
   double   last_nervous_resilience_pm;

   ulong    thaw_state_hist[GOV_ATS_THAW_STATE_CT_V1];
   ulong    decay_hist[GOV_ATS_DECAY_CT_V1];
   ulong    float_v2_hist[GOV_ATS_FLOAT_V2_CT_V1];
   ulong    recovery_hist[GOV_ATS_RECOVERY_CT_V1];
   ulong    paralysis_hist[GOV_ATS_PARALYSIS_CT_V1];
};

inline SGovAtsStoreV1 g_gov_ats_v1;

inline void GovAtsDsV1_Init(SGovAtsStoreV1 &st)
{
   st.enabled = false;
   st.bars_observed = 0;
   st.prev_eq_dd = 0.0;
   st.recovery_ema = 0.0;
   st.prev_ecology_part_sum = 0;
   st.last_thaw_confidence_pm = 0.0;
   st.last_thaw_relapse_pm = 0.0;
   st.last_thaw_stability_pm = 0.0;
   st.last_thaw_state = (int)GOV_ATS_THAW_NONE_V1;
   st.lock_age_bars_last = 0;
   st.last_lock_decay_rate_pm = 0.0;
   st.last_decay_class = (int)GOV_ATS_DECAY_HEALTHY_V1;
   st.last_float_norm_pm = 0.0;
   st.last_float_recovery_vel_pm = 0.0;
   st.last_float_v2_class = (int)GOV_ATS_FLOAT2_NORMAL_V1;
   st.last_dd_context_pm = 0.0;
   st.last_vol_adj_dd = 0.0;
   st.last_spread_adj_dd = 0.0;
   st.last_recovery_momentum_pm = 0.0;
   st.last_recovery_state = (int)GOV_ATS_REC_STALLED_V1;
   st.last_paralysis_index_pm = 0.0;
   st.last_defensive_overreaction_pm = 0.0;
   st.last_paralysis_state = (int)GOV_ATS_PAR_HEALTHY_V1;
   st.last_exec_continuity_pm = 0.0;
   st.last_bars_since_exec_hint = 0;
   st.last_ecology_recovery_pm = 0.0;
   st.last_suppression_decay_pm = 0.0;
   st.last_stress_accum_pm = 0.0;
   st.last_stress_decay_pm = 0.0;
   st.last_nervous_resilience_pm = 0.0;
   for(int i = 0; i < GOV_ATS_THAW_STATE_CT_V1; i++)
      st.thaw_state_hist[i] = 0;
   for(int j = 0; j < GOV_ATS_DECAY_CT_V1; j++)
      st.decay_hist[j] = 0;
   for(int f = 0; f < GOV_ATS_FLOAT_V2_CT_V1; f++)
      st.float_v2_hist[f] = 0;
   for(int r = 0; r < GOV_ATS_RECOVERY_CT_V1; r++)
      st.recovery_hist[r] = 0;
   for(int p = 0; p < GOV_ATS_PARALYSIS_CT_V1; p++)
      st.paralysis_hist[p] = 0;
}

#endif // __AURUM_ATS_DATASET_V1_MQH__
