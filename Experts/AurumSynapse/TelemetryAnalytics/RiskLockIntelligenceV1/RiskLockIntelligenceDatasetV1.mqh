//+------------------------------------------------------------------+
//| RiskLockIntelligenceDatasetV1.mqh                              |
//| PHASE 23.6 — risk lock / thaw physiology telemetry (observe-only)|
//+------------------------------------------------------------------+
#ifndef __AURUM_RLI_DATASET_V1_MQH__
#define __AURUM_RLI_DATASET_V1_MQH__

#define GOV_RLI_RING_V1          64
#define GOV_RLI_THAW_RELOCK_V1   8

enum ENUM_GOV_RLI_LOCK_ORIGIN_V1
{
   GOV_RLI_ORIG_DD_SPIKE_V1 = 0,
   GOV_RLI_ORIG_FLOATING_PRESSURE_V1,
   GOV_RLI_ORIG_SPREAD_EXPANSION_V1,
   GOV_RLI_ORIG_EXEC_TOXICITY_V1,
   GOV_RLI_ORIG_VOL_COLLAPSE_V1,
   GOV_RLI_ORIG_ECOLOGY_CASCADE_V1,
   GOV_RLI_ORIG_REGIME_INSTABILITY_V1,
   GOV_RLI_ORIG_RECOVERY_FAILURE_V1,
   GOV_RLI_ORIG_UNKNOWN_V1
};

enum ENUM_GOV_RLI_FLOAT_CLASS_V1
{
   GOV_RLI_FLOAT_MICRO_V1 = 0,
   GOV_RLI_FLOAT_NORMAL_V1,
   GOV_RLI_FLOAT_ELEVATED_V1,
   GOV_RLI_FLOAT_STRUCTURAL_V1,
   GOV_RLI_FLOAT_COLLAPSE_V1
};

enum ENUM_GOV_RLI_DD_CLASS_V1
{
   GOV_RLI_DD_TRANSIENT_V1 = 0,
   GOV_RLI_DD_VOLATILITY_V1,
   GOV_RLI_DD_EXECUTION_V1,
   GOV_RLI_DD_LIQUIDITY_V1,
   GOV_RLI_DD_STRUCTURAL_V1,
   GOV_RLI_DD_GRID_V1,
   GOV_RLI_DD_TESTER_ARTIFACT_V1
};

enum ENUM_GOV_RLI_LOCK_PERSIST_V1
{
   GOV_RLI_LP_HEALTHY_V1 = 0,
   GOV_RLI_LP_DEFENSIVE_V1,
   GOV_RLI_LP_OVEREXTENDED_V1,
   GOV_RLI_LP_PARALYSIS_V1
};

struct SGovRliLockRecordV1
{
   ulong    id;
   datetime t0;
   datetime t1;
   ulong    bar0;
   ulong    bar1;
   int      origin;
   int      regime_slot0;
   double   eq_dd0;
   double   balance0;
   double   equity0;
   double   floating_pressure0;
   double   spread_pts0;
   double   atr_ratio0;
   int      ecology_suppress_prev;
   int      deny_detail0;
   int      halt_reason0;
   ulong    duration_bars;
};

struct SGovRliStoreV1
{
   bool     enabled;

   bool     prev_can_trade;
   int      prev_regime_slot;
   int      ecology_suppress_prev_bar;

   ulong    lock_seq;
   bool     lock_active;
   ulong    active_lock_id;
   ulong    active_lock_bar0;
   datetime active_lock_t0;
   int      active_origin;
   int      active_regime0;
   double   active_eq_dd0;
   double   active_bal0;
   double   active_eq0;
   double   active_fp0;
   double   active_spread0;
   double   active_atr0;
   int      active_eco_prev;
   int      active_deny0;
   int      active_halt0;

   ulong    bars_observed;
   ulong    total_lock_bars;
   ulong    lock_events;
   ulong    lock_origin_hist[9];
   ulong    thaw_successes;
   ulong    thaw_interruptions;
   ulong    thaw_duration_bars_sum;
   ulong    thaw_attempts;

   ulong    bars_starvation_overlap;
   ulong    last_exec_bar_idx;
   ulong    max_starvation_bars;

   double   prev_eq_dd;
   ulong    float_streak_bars;
   ulong    float_stress_bars;
   ulong    float_recovery_bars;
   double   sum_floating_pressure;
   ulong    dd_class_hist[8];

   ulong    persist_class_hist[4];
   ulong    governance_stress_accum;
   ulong    defensive_escalation_events;

   ulong    bars_since_prev_thaw;
   bool     in_post_thaw_window;

   SGovRliLockRecordV1 ring[GOV_RLI_RING_V1];
   int      ring_wi;
   int      ring_count;
};

inline SGovRliStoreV1 g_gov_rli_v1;

inline void GovRliDsV1_Init(SGovRliStoreV1 &st)
{
   st.enabled = false;
   st.prev_can_trade = true;
   st.prev_regime_slot = -1;
   st.ecology_suppress_prev_bar = 0;
   st.lock_seq = 0;
   st.lock_active = false;
   st.active_lock_id = 0;
   st.active_lock_bar0 = 0;
   st.active_lock_t0 = 0;
   st.active_origin = (int)GOV_RLI_ORIG_UNKNOWN_V1;
   st.active_regime0 = 0;
   st.active_eq_dd0 = 0.0;
   st.active_bal0 = 0.0;
   st.active_eq0 = 0.0;
   st.active_fp0 = 0.0;
   st.active_spread0 = 0.0;
   st.active_atr0 = 0.0;
   st.active_eco_prev = 0;
   st.active_deny0 = 0;
   st.active_halt0 = 0;
   st.bars_observed = 0;
   st.total_lock_bars = 0;
   st.lock_events = 0;
   for(int i = 0; i < 9; i++)
      st.lock_origin_hist[i] = 0;
   st.thaw_successes = 0;
   st.thaw_interruptions = 0;
   st.thaw_duration_bars_sum = 0;
   st.thaw_attempts = 0;
   st.bars_starvation_overlap = 0;
   st.last_exec_bar_idx = 0;
   st.max_starvation_bars = 0;
   st.prev_eq_dd = 0.0;
   st.float_streak_bars = 0;
   st.float_stress_bars = 0;
   st.float_recovery_bars = 0;
   st.sum_floating_pressure = 0.0;
   for(int d = 0; d < 8; d++)
      st.dd_class_hist[d] = 0;
   for(int p = 0; p < 4; p++)
      st.persist_class_hist[p] = 0;
   st.governance_stress_accum = 0;
   st.defensive_escalation_events = 0;
   st.bars_since_prev_thaw = 1000000;
   st.in_post_thaw_window = false;
   st.ring_wi = 0;
   st.ring_count = 0;
   for(int r = 0; r < GOV_RLI_RING_V1; r++) {
      st.ring[r].id = 0;
      st.ring[r].t0 = 0;
      st.ring[r].t1 = 0;
      st.ring[r].bar0 = 0;
      st.ring[r].bar1 = 0;
      st.ring[r].origin = 0;
      st.ring[r].regime_slot0 = 0;
      st.ring[r].eq_dd0 = 0.0;
      st.ring[r].balance0 = 0.0;
      st.ring[r].equity0 = 0.0;
      st.ring[r].floating_pressure0 = 0.0;
      st.ring[r].spread_pts0 = 0.0;
      st.ring[r].atr_ratio0 = 0.0;
      st.ring[r].ecology_suppress_prev = 0;
      st.ring[r].deny_detail0 = 0;
      st.ring[r].halt_reason0 = 0;
      st.ring[r].duration_bars = 0;
   }
}

#endif // __AURUM_RLI_DATASET_V1_MQH__
