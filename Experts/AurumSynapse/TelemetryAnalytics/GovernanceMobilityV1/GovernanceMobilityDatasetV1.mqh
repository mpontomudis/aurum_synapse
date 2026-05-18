//+------------------------------------------------------------------+
//| GovernanceMobilityDatasetV1.mqh                                 |
//| PHASE 24A — governance mobility & controlled reactivation (observe)|
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_GMB_DATASET_V1_MQH__
#define __AURUM_GOV_GMB_DATASET_V1_MQH__

#define GOV_GMB_MOBILITY_CT_V1       5
#define GOV_GMB_REACTIV_CT_V1        6
#define GOV_GMB_SUPP_DECAY_CT_V1    4
#define GOV_GMB_STRAT_REVIVAL_CT_V1 5
#define GOV_GMB_PARTICIP_CT_V1      5
#define GOV_GMB_VITALITY_CT_V1      6
#define GOV_GMB_ANTISTARVE_CT_V1    4

enum ENUM_GOV_GMB_MOBILITY_CLASS_V1
{
   GOV_GMB_MOB_IMMOBILE_V1 = 0,
   GOV_GMB_MOB_PARTIAL_V1,
   GOV_GMB_MOB_FRAGILE_V1,
   GOV_GMB_MOB_STABILIZING_V1,
   GOV_GMB_MOB_HEALTHY_V1
};

enum ENUM_GOV_GMB_REACTIV_STATE_V1
{
   GOV_GMB_REAC_DORMANT_V1 = 0,
   GOV_GMB_REAC_PARTIAL_V1,
   GOV_GMB_REAC_CONTROLLED_V1,
   GOV_GMB_REAC_STABILIZING_V1,
   GOV_GMB_REAC_HEALTHY_V1,
   GOV_GMB_REAC_FRAGILE_V1
};

enum ENUM_GOV_GMB_SUPP_DECAY_V1
{
   GOV_GMB_SUPP_HEALTHY_DECAY_V1 = 0,
   GOV_GMB_SUPP_SLOW_DECAY_V1,
   GOV_GMB_SUPP_PERSISTENT_V1,
   GOV_GMB_SUPP_PARALYSIS_V1
};

enum ENUM_GOV_GMB_STRAT_REVIVAL_V1
{
   GOV_GMB_SR_DORMANT_V1 = 0,
   GOV_GMB_SR_WEAK_V1,
   GOV_GMB_SR_CONTROLLED_V1,
   GOV_GMB_SR_HEALTHY_V1,
   GOV_GMB_SR_TOXIC_V1
};

enum ENUM_GOV_GMB_PARTICIP_CONT_V1
{
   GOV_GMB_PC_DEAD_V1 = 0,
   GOV_GMB_PC_FRAGMENTED_V1,
   GOV_GMB_PC_FRAGILE_V1,
   GOV_GMB_PC_STABILIZING_V1,
   GOV_GMB_PC_HEALTHY_V1
};

enum ENUM_GOV_GMB_VITALITY_V2_V1
{
   GOV_GMB_V2_DORMANT_V1 = 0,
   GOV_GMB_V2_SURVIVING_V1,
   GOV_GMB_V2_AWAKENING_V1,
   GOV_GMB_V2_STABILIZING_V1,
   GOV_GMB_V2_OPERATIONAL_V1,
   GOV_GMB_V2_HEALTHY_ADAPTIVE_V1
};

enum ENUM_GOV_GMB_ANTISTARVE_V1
{
   GOV_GMB_AS_HEALTHY_V1 = 0,
   GOV_GMB_AS_ELEVATED_V1,
   GOV_GMB_AS_OVERPROTECTIVE_V1,
   GOV_GMB_AS_OP_PARALYZED_V1
};

struct SGovGmbStoreV1
{
   bool     enabled;
   ulong    bars_observed;

   double   governance_mobility_score_pm;
   double   adaptive_mobility_confidence_pm;
   double   participation_restoration_velocity_pm;
   double   operational_reactivation_rate_pm;
   double   mobility_inertia_pm;
   double   adaptive_recovery_continuity_pm;
   double   recovery_life_restoration_score_pm;
   int      mobility_class;

   double   controlled_reactivation_score_pm;
   double   selective_strategy_revival_pm;
   double   recovery_activation_success_pm;
   double   reactivation_fragility_pm;
   double   participation_reactivation_delay_pm;
   double   safe_reentry_probability_pm;
   double   adaptive_reactivation_stability_pm;
   int      reactivation_state;

   double   suppression_decay_rate_pm;
   double   suppression_persistence_track_pm;
   double   suppression_fatigue_track_pm;
   double   adaptive_suppression_release_pm;
   double   participation_recovery_after_suppression_pm;
   double   suppression_inertia_pm;
   int      suppression_decay_class;

   int      strategy_revival_worst_class;
   double   strategy_revival_avg_pm;
   ulong    strategy_reactivation_success_ct;
   double   strategy_relock_risk_pm;

   double   participation_continuity_score_pm;
   double   adaptive_execution_flow_pm;
   ulong    participation_streak_bars;
   double   execution_restoration_duration_pm;
   double   opportunity_recovery_rate_pm;
   double   starvation_recovery_velocity_pm;
   int      participation_continuity_class;

   double   adaptive_vitality_v2_pm;
   double   operational_life_score_pm;
   double   ecosystem_reanimation_pm;
   double   participation_health_pm;
   double   governance_respiration_pm;
   double   adaptive_recovery_energy_pm;
   double   vitality_decay_pm;
   double   vitality_restoration_pm;
   int      vitality_v2_class;

   double   starvation_persistence_pm;
   double   starvation_density_pm;
   double   participation_suffocation_pm;
   double   governance_overprotection_pm;
   double   adaptive_activity_absence_pm;
   double   opportunity_extinction_risk_pm;
   int      anti_starvation_class;

   double   ecology_revival_probability_pm;
   double   participation_entropy_recovery_track_pm;
   double   diversity_restoration_pm;
   double   monoculture_decay_pm;
   double   adaptive_ecology_reanimation_pm;
   double   ecosystem_breathing_rate_pm;

   double   adaptive_life_probability_track_pm;
   double   governance_restoration_cycle_pm;
   double   ecosystem_awakeness_pm;
   double   adaptive_operationality_pm;
   double   post_survival_vitality_pm;
   double   restoration_stability_pm;

   ulong    mobility_hist[GOV_GMB_MOBILITY_CT_V1];
   ulong    reactivation_hist[GOV_GMB_REACTIV_CT_V1];
   ulong    suppression_decay_hist[GOV_GMB_SUPP_DECAY_CT_V1];
   ulong    strategy_revival_hist[GOV_GMB_STRAT_REVIVAL_CT_V1];
   ulong    participation_hist[GOV_GMB_PARTICIP_CT_V1];
   ulong    vitality_v2_hist[GOV_GMB_VITALITY_CT_V1];
   ulong    anti_starve_hist[GOV_GMB_ANTISTARVE_CT_V1];

   double   prev_suppression_persistence;
   ulong    prev_ecology_part;
};

inline SGovGmbStoreV1 g_gov_gmb_v1;

inline void GovGmbDsV1_Init(SGovGmbStoreV1 &st)
{
   st.enabled = false;
   st.bars_observed = 0;
   st.governance_mobility_score_pm = 0.0;
   st.adaptive_mobility_confidence_pm = 0.0;
   st.participation_restoration_velocity_pm = 0.0;
   st.operational_reactivation_rate_pm = 0.0;
   st.mobility_inertia_pm = 0.0;
   st.adaptive_recovery_continuity_pm = 0.0;
   st.recovery_life_restoration_score_pm = 0.0;
   st.mobility_class = (int)GOV_GMB_MOB_IMMOBILE_V1;
   st.controlled_reactivation_score_pm = 0.0;
   st.selective_strategy_revival_pm = 0.0;
   st.recovery_activation_success_pm = 0.0;
   st.reactivation_fragility_pm = 0.0;
   st.participation_reactivation_delay_pm = 0.0;
   st.safe_reentry_probability_pm = 0.0;
   st.adaptive_reactivation_stability_pm = 0.0;
   st.reactivation_state = (int)GOV_GMB_REAC_DORMANT_V1;
   st.suppression_decay_rate_pm = 0.0;
   st.suppression_persistence_track_pm = 0.0;
   st.suppression_fatigue_track_pm = 0.0;
   st.adaptive_suppression_release_pm = 0.0;
   st.participation_recovery_after_suppression_pm = 0.0;
   st.suppression_inertia_pm = 0.0;
   st.suppression_decay_class = (int)GOV_GMB_SUPP_HEALTHY_DECAY_V1;
   st.strategy_revival_worst_class = (int)GOV_GMB_SR_DORMANT_V1;
   st.strategy_revival_avg_pm = 0.0;
   st.strategy_reactivation_success_ct = 0;
   st.strategy_relock_risk_pm = 0.0;
   st.participation_continuity_score_pm = 0.0;
   st.adaptive_execution_flow_pm = 0.0;
   st.participation_streak_bars = 0;
   st.execution_restoration_duration_pm = 0.0;
   st.opportunity_recovery_rate_pm = 0.0;
   st.starvation_recovery_velocity_pm = 0.0;
   st.participation_continuity_class = (int)GOV_GMB_PC_DEAD_V1;
   st.adaptive_vitality_v2_pm = 0.0;
   st.operational_life_score_pm = 0.0;
   st.ecosystem_reanimation_pm = 0.0;
   st.participation_health_pm = 0.0;
   st.governance_respiration_pm = 0.0;
   st.adaptive_recovery_energy_pm = 0.0;
   st.vitality_decay_pm = 0.0;
   st.vitality_restoration_pm = 0.0;
   st.vitality_v2_class = (int)GOV_GMB_V2_DORMANT_V1;
   st.starvation_persistence_pm = 0.0;
   st.starvation_density_pm = 0.0;
   st.participation_suffocation_pm = 0.0;
   st.governance_overprotection_pm = 0.0;
   st.adaptive_activity_absence_pm = 0.0;
   st.opportunity_extinction_risk_pm = 0.0;
   st.anti_starvation_class = (int)GOV_GMB_AS_HEALTHY_V1;
   st.ecology_revival_probability_pm = 0.0;
   st.participation_entropy_recovery_track_pm = 0.0;
   st.diversity_restoration_pm = 0.0;
   st.monoculture_decay_pm = 0.0;
   st.adaptive_ecology_reanimation_pm = 0.0;
   st.ecosystem_breathing_rate_pm = 0.0;
   st.adaptive_life_probability_track_pm = 0.0;
   st.governance_restoration_cycle_pm = 0.0;
   st.ecosystem_awakeness_pm = 0.0;
   st.adaptive_operationality_pm = 0.0;
   st.post_survival_vitality_pm = 0.0;
   st.restoration_stability_pm = 0.0;
   for(int i = 0; i < GOV_GMB_MOBILITY_CT_V1; i++)
      st.mobility_hist[i] = 0;
   for(int r = 0; r < GOV_GMB_REACTIV_CT_V1; r++)
      st.reactivation_hist[r] = 0;
   for(int s = 0; s < GOV_GMB_SUPP_DECAY_CT_V1; s++)
      st.suppression_decay_hist[s] = 0;
   for(int v = 0; v < GOV_GMB_STRAT_REVIVAL_CT_V1; v++)
      st.strategy_revival_hist[v] = 0;
   for(int p = 0; p < GOV_GMB_PARTICIP_CT_V1; p++)
      st.participation_hist[p] = 0;
   for(int z = 0; z < GOV_GMB_VITALITY_CT_V1; z++)
      st.vitality_v2_hist[z] = 0;
   for(int a = 0; a < GOV_GMB_ANTISTARVE_CT_V1; a++)
      st.anti_starve_hist[a] = 0;
   st.prev_suppression_persistence = 0.0;
   st.prev_ecology_part = 0;
}

#endif // __AURUM_GOV_GMB_DATASET_V1_MQH__
