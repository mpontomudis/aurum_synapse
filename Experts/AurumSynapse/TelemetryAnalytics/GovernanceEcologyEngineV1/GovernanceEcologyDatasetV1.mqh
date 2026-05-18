//+------------------------------------------------------------------+
//| GovernanceEcologyDatasetV1.mqh                                  |
//| PHASE 23 — adaptive strategy ecology runtime contracts           |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECOLOGY_DATASET_V1_MQH__
#define __AURUM_GOV_ECOLOGY_DATASET_V1_MQH__

#define GOV_ECO_STRAT_COUNT_V1       8
#define GOV_ECO_SESSION_COUNT_V1     4
#define GOV_ECO_VOL_BUCKET_V1        4
#define GOV_ECO_MONTHS_V1            12

enum ENUM_GOV_ECOLOGY_PART_STATE_V1
{
   GOV_ECO_ST_ACTIVE = 0,
   GOV_ECO_ST_SUPPRESSED,
   GOV_ECO_ST_PASSIVE,
   GOV_ECO_ST_THROTTLED,
   GOV_ECO_ST_DOMINANT,
   GOV_ECO_ST_RECOVERING,
   GOV_ECO_ST_TOXIC,
   GOV_ECO_ST_DISABLED_BY_REGIME
};

struct SGovEcologyStratSliceV1
{
   int      compatibility_score_permille;
   int      survivability_score_permille;
   int      toxicity_score_permille;
   int      participation_score_permille;
   int      confidence_score_permille;

   int      ecology_health_pm;
   int      ecology_pressure_pm;
   int      ecology_stability_pm;
   int      ecology_dependency_pm;
   int      ecology_recovery_pm;

   int      part_state;

   ulong    bars_participation;
   ulong    bars_suppression;
   ulong    bars_throttled;
   ulong    bars_dominant;
   ulong    regime_alignment_hits;
   ulong    regime_mismatch_hits;
   ulong    recovery_cycles;
   ulong    failure_cycles;

   ulong    dominance_pick_bars;
   ulong    month_participation_bars[GOV_ECO_MONTHS_V1];
};

struct SGovEcologyStoreV1
{
   bool     enabled;
   ulong    bar_index;
   datetime last_ts;

   int      ecology_diversity_score_pm;
   int      ecology_entropy_score_pm;
   int      ecology_balance_score_pm;
   int      monoculture_warn;

   ulong    cooccur[GOV_ECO_STRAT_COUNT_V1][GOV_ECO_STRAT_COUNT_V1];
   ulong    strat_bars_by_sess[GOV_ECO_STRAT_COUNT_V1][GOV_ECO_SESSION_COUNT_V1];
   ulong    strat_bars_by_vol[GOV_ECO_STRAT_COUNT_V1][GOV_ECO_VOL_BUCKET_V1];

   int      last_bar_suppress_clears;
   int      last_bar_throttle_events;

   SGovEcologyStratSliceV1 s[GOV_ECO_STRAT_COUNT_V1];
};

inline SGovEcologyStoreV1 g_gov_ecology_v1;

inline void GovEcoDsV1_InitStrat(SGovEcologyStratSliceV1 &z)
{
   z.compatibility_score_permille = 500;
   z.survivability_score_permille = 500;
   z.toxicity_score_permille = 200;
   z.participation_score_permille = 500;
   z.confidence_score_permille = 500;
   z.ecology_health_pm = 500;
   z.ecology_pressure_pm = 200;
   z.ecology_stability_pm = 500;
   z.ecology_dependency_pm = 200;
   z.ecology_recovery_pm = 400;
   z.part_state = GOV_ECO_ST_ACTIVE;
   z.bars_participation = 0;
   z.bars_suppression = 0;
   z.bars_throttled = 0;
   z.bars_dominant = 0;
   z.regime_alignment_hits = 0;
   z.regime_mismatch_hits = 0;
   z.recovery_cycles = 0;
   z.failure_cycles = 0;
   z.dominance_pick_bars = 0;
   for(int m = 0; m < GOV_ECO_MONTHS_V1; m++)
      z.month_participation_bars[m] = 0;
}

inline void GovEcoDsV1_Init(SGovEcologyStoreV1 &st)
{
   st.enabled = false;
   st.bar_index = 0;
   st.last_ts = 0;
   st.ecology_diversity_score_pm = 0;
   st.ecology_entropy_score_pm = 0;
   st.ecology_balance_score_pm = 0;
   st.monoculture_warn = 0;
   st.last_bar_suppress_clears = 0;
   st.last_bar_throttle_events = 0;
   for(int i = 0; i < GOV_ECO_STRAT_COUNT_V1; i++) {
      for(int j = 0; j < GOV_ECO_STRAT_COUNT_V1; j++)
         st.cooccur[i][j] = 0;
      for(int ss = 0; ss < GOV_ECO_SESSION_COUNT_V1; ss++)
         st.strat_bars_by_sess[i][ss] = 0;
      for(int vv = 0; vv < GOV_ECO_VOL_BUCKET_V1; vv++)
         st.strat_bars_by_vol[i][vv] = 0;
      GovEcoDsV1_InitStrat(st.s[i]);
   }
}

#endif // __AURUM_GOV_ECOLOGY_DATASET_V1_MQH__
