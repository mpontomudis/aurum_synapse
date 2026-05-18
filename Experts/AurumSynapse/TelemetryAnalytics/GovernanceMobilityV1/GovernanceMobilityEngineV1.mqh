//+------------------------------------------------------------------+
//| GovernanceMobilityEngineV1.mqh                                  |
//| PHASE 24A — observe-only mobility / reactivation / life restoration |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_GMB_ENGINE_V1_MQH__
#define __AURUM_GOV_GMB_ENGINE_V1_MQH__

#include "../GovernanceRecoveryContinuationV1/GovernanceRecoveryContinuationDatasetV1.mqh"
#include "../AdaptiveThawStabilizationV1/AdaptiveThawStabilizationDatasetV1.mqh"
#include "../RiskLockIntelligenceV1/RiskLockIntelligenceDatasetV1.mqh"
#include "../GovernanceRestrictionForensicsV1/GovernanceRestrictionForensicsDatasetV1.mqh"
#include "../GovernanceEcologyEngineV1/GovernanceEcologyDatasetV1.mqh"
#include "GovernanceMobilityDatasetV1.mqh"

inline double GovGmbEngV1_Clamp1000(const double x)
{
   return MathMax(0.0, MathMin(1000.0, x));
}

inline ulong GovGmbEngV1_EcoPart(const SGovEcologyStoreV1 &eco)
{
   ulong s = 0;
   for(int i = 0; i < GOV_ECO_STRAT_COUNT_V1; i++)
      s += eco.s[i].bars_participation;
   return s;
}

inline int GovGmbEngV1_ClassifyMobility(const double score_pm)
{
   if(score_pm < 220.0)
      return (int)GOV_GMB_MOB_IMMOBILE_V1;
   if(score_pm < 380.0)
      return (int)GOV_GMB_MOB_PARTIAL_V1;
   if(score_pm < 520.0)
      return (int)GOV_GMB_MOB_FRAGILE_V1;
   if(score_pm < 680.0)
      return (int)GOV_GMB_MOB_STABILIZING_V1;
   return (int)GOV_GMB_MOB_HEALTHY_V1;
}

inline int GovGmbEngV1_ClassifyReactivation(const double score_pm, const double frag_pm)
{
   if(score_pm < 200.0)
      return (int)GOV_GMB_REAC_DORMANT_V1;
   if(score_pm < 340.0)
      return (int)GOV_GMB_REAC_PARTIAL_V1;
   if(frag_pm > 620.0)
      return (int)GOV_GMB_REAC_FRAGILE_V1;
   if(score_pm < 480.0)
      return (int)GOV_GMB_REAC_CONTROLLED_V1;
   if(score_pm < 650.0)
      return (int)GOV_GMB_REAC_STABILIZING_V1;
   return (int)GOV_GMB_REAC_HEALTHY_V1;
}

inline int GovGmbEngV1_ClassifySuppDecay(const double decay_rate_pm, const double pers_pm, const double fatigue_pm)
{
   if(pers_pm > 780.0 || fatigue_pm > 820.0)
      return (int)GOV_GMB_SUPP_PARALYSIS_V1;
   if(pers_pm > 520.0)
      return (int)GOV_GMB_SUPP_PERSISTENT_V1;
   if(decay_rate_pm < 35.0)
      return (int)GOV_GMB_SUPP_SLOW_DECAY_V1;
   return (int)GOV_GMB_SUPP_HEALTHY_DECAY_V1;
}

inline int GovGmbEngV1_ClassifyStratRevival(const int recovery_pm, const ulong supp_bars, const int tox_pm)
{
   if(tox_pm > 650)
      return (int)GOV_GMB_SR_TOXIC_V1;
   if(recovery_pm < 220 && supp_bars > 40UL)
      return (int)GOV_GMB_SR_DORMANT_V1;
   if(recovery_pm < 380)
      return (int)GOV_GMB_SR_WEAK_V1;
   if(recovery_pm < 560 || supp_bars > 18UL)
      return (int)GOV_GMB_SR_CONTROLLED_V1;
   return (int)GOV_GMB_SR_HEALTHY_V1;
}

inline int GovGmbEngV1_ClassifyParticipation(const double cont_pm, const double exec_pm, const ulong streak)
{
   if(exec_pm < 180.0 && streak < 2UL)
      return (int)GOV_GMB_PC_DEAD_V1;
   if(exec_pm < 320.0)
      return (int)GOV_GMB_PC_FRAGMENTED_V1;
   if(cont_pm < 380.0)
      return (int)GOV_GMB_PC_FRAGILE_V1;
   if(cont_pm < 560.0)
      return (int)GOV_GMB_PC_STABILIZING_V1;
   return (int)GOV_GMB_PC_HEALTHY_V1;
}

inline int GovGmbEngV1_ClassifyVitalityV2(const double life_pm, const double pulse_pm, const bool can_trade, const bool locked)
{
   if(locked || !can_trade)
      return (int)GOV_GMB_V2_SURVIVING_V1;
   if(life_pm < 220.0 && pulse_pm < 300.0)
      return (int)GOV_GMB_V2_DORMANT_V1;
   if(life_pm < 380.0)
      return (int)GOV_GMB_V2_AWAKENING_V1;
   if(life_pm < 520.0)
      return (int)GOV_GMB_V2_STABILIZING_V1;
   if(life_pm < 700.0)
      return (int)GOV_GMB_V2_OPERATIONAL_V1;
   return (int)GOV_GMB_V2_HEALTHY_ADAPTIVE_V1;
}

inline int GovGmbEngV1_ClassifyAntiStarve(const double suff_pm, const double over_pm)
{
   if(suff_pm > 780.0 || over_pm > 820.0)
      return (int)GOV_GMB_AS_OP_PARALYZED_V1;
   if(suff_pm > 560.0 || over_pm > 620.0)
      return (int)GOV_GMB_AS_OVERPROTECTIVE_V1;
   if(suff_pm > 360.0 || over_pm > 420.0)
      return (int)GOV_GMB_AS_ELEVATED_V1;
   return (int)GOV_GMB_AS_HEALTHY_V1;
}

inline void GovGmbEngV1_OnBar(SGovGmbStoreV1 &gmb,
                             const SGovRciStoreV1 &rci,
                             const SGovAtsStoreV1 &ats,
                             const SGovRliStoreV1 &rli,
                             const SGovRfStoreV1 &rf,
                             const SGovEcologyStoreV1 &eco,
                             const bool can_trade)
{
   if(!gmb.enabled)
      return;
   gmb.bars_observed++;

   const bool locked = rli.lock_active || !can_trade;
   const ulong eco_sum = GovGmbEngV1_EcoPart(eco);
   const long eco_delta = (gmb.prev_ecology_part > 0UL) ? ((long)eco_sum - (long)gmb.prev_ecology_part) : 0L;
   gmb.prev_ecology_part = eco_sum;

   gmb.mobility_inertia_pm = GovGmbEngV1_Clamp1000(rci.activation_inertia_pm * 0.85 + ats.last_paralysis_index_pm * 0.15);
   gmb.adaptive_recovery_continuity_pm = rci.adaptive_continuity_confidence_pm;
   gmb.participation_restoration_velocity_pm = GovGmbEngV1_Clamp1000((double)MathMax(0L, eco_delta) * 42.0 + rci.participation_restoration_probability_pm * 0.35);
   gmb.operational_reactivation_rate_pm = GovGmbEngV1_Clamp1000((rf.bars_observed > 0UL) ? ((double)rf.trade_open_success / (double)rf.bars_observed) * 980.0 : 0.0);
   gmb.adaptive_mobility_confidence_pm = GovGmbEngV1_Clamp1000(
                                            ats.last_thaw_confidence_pm * 0.35 + rci.continuation_confidence_pm * 0.35 + gmb.operational_reactivation_rate_pm * 0.3 - gmb.mobility_inertia_pm * 0.12);
   gmb.governance_mobility_score_pm = GovGmbEngV1_Clamp1000(
                                         rci.continuation_confidence_pm * 0.26 + rci.recovery_continuity_pm * 0.22 + ats.last_exec_continuity_pm * 0.24
                                         + rci.adaptive_continuity_confidence_pm * 0.18 + gmb.participation_restoration_velocity_pm * 0.15 - rci.governance_dormancy_depth_pm * 0.18);
   gmb.recovery_life_restoration_score_pm = GovGmbEngV1_Clamp1000(
                                              rci.adaptive_life_probability_pm * 0.35 + rci.ecology_restoration_confidence_pm * 0.35 + gmb.participation_restoration_velocity_pm * 0.3);
   gmb.mobility_class = GovGmbEngV1_ClassifyMobility(gmb.governance_mobility_score_pm);

   gmb.safe_reentry_probability_pm = GovGmbEngV1_Clamp1000(rci.regime_safe_reactivation_pm * 0.45 + (1.0 - rci.restoration_resistance_pm / 1000.0) * 420.0);
   gmb.reactivation_fragility_pm = GovGmbEngV1_Clamp1000((double)rci.governance_reactivation_failures * 22.0 + rci.recovery_blockers_pm * 0.45 + ats.last_thaw_relapse_pm * 0.25);
   gmb.recovery_activation_success_pm = GovGmbEngV1_Clamp1000((double)rci.adaptive_restoration_attempts * 8.0 + gmb.operational_reactivation_rate_pm * 0.55);
   gmb.participation_reactivation_delay_pm = GovGmbEngV1_Clamp1000((double)rci.thaw_to_activity_latency_last * 4.2 + (double)ats.last_bars_since_exec_hint * 0.65);
   gmb.adaptive_reactivation_stability_pm = GovGmbEngV1_Clamp1000(ats.last_thaw_stability_pm * 0.5 + (1000.0 - gmb.reactivation_fragility_pm) * 0.5);
   gmb.controlled_reactivation_score_pm = GovGmbEngV1_Clamp1000(
                                             gmb.safe_reentry_probability_pm * 0.3 + gmb.adaptive_reactivation_stability_pm * 0.35 + gmb.recovery_activation_success_pm * 0.25 - gmb.reactivation_fragility_pm * 0.2);

   int worst_sr = (int)GOV_GMB_SR_DORMANT_V1;
   double sum_sr = 0.0;
   int tox_ct = 0;
   for(int si = 0; si < GOV_ECO_STRAT_COUNT_V1; si++) {
      const SGovEcologyStratSliceV1 z = eco.s[si];
      const int cls = GovGmbEngV1_ClassifyStratRevival(z.ecology_recovery_pm, z.bars_suppression, z.toxicity_score_permille);
      if(cls > worst_sr)
         worst_sr = cls;
      sum_sr += (double)z.ecology_recovery_pm;
      if(z.toxicity_score_permille > 600)
         tox_ct++;
   }
   gmb.strategy_revival_worst_class = worst_sr;
   gmb.strategy_revival_avg_pm = GovGmbEngV1_Clamp1000(sum_sr / (double)GOV_ECO_STRAT_COUNT_V1);
   gmb.selective_strategy_revival_pm = GovGmbEngV1_Clamp1000(gmb.strategy_revival_avg_pm + (double)(GOV_ECO_STRAT_COUNT_V1 - tox_ct) * 12.0);
   gmb.strategy_reactivation_success_ct = rci.adaptive_restoration_attempts;
   gmb.strategy_relock_risk_pm = GovGmbEngV1_Clamp1000((double)rli.thaw_interruptions * 25.0 + ats.last_thaw_relapse_pm * 0.6);

   gmb.reactivation_state = GovGmbEngV1_ClassifyReactivation(gmb.controlled_reactivation_score_pm, gmb.reactivation_fragility_pm);

   const double pers = rci.suppression_persistence_pm;
   gmb.suppression_persistence_track_pm = pers;
   gmb.suppression_fatigue_track_pm = rci.suppression_fatigue_pm;
   gmb.suppression_decay_rate_pm = GovGmbEngV1_Clamp1000(MathMax(0.0, gmb.prev_suppression_persistence - pers) * 12.0 + (double)eco.last_bar_suppress_clears * 45.0);
   gmb.prev_suppression_persistence = pers;
   gmb.adaptive_suppression_release_pm = GovGmbEngV1_Clamp1000((double)eco.last_bar_suppress_clears * 38.0 + gmb.suppression_decay_rate_pm * 0.6);
   gmb.participation_recovery_after_suppression_pm = GovGmbEngV1_Clamp1000((double)MathMax(0L, eco_delta) * 30.0 + rci.participation_restoration_probability_pm * 0.35);
   gmb.suppression_inertia_pm = GovGmbEngV1_Clamp1000(pers * 0.55 + gmb.suppression_fatigue_track_pm * 0.45);
   gmb.suppression_decay_class = GovGmbEngV1_ClassifySuppDecay(gmb.suppression_decay_rate_pm, pers, gmb.suppression_fatigue_track_pm);

   if(ats.last_exec_continuity_pm > 400.0 && eco_delta >= 0L)
      gmb.participation_streak_bars++;
   else if(ats.last_exec_continuity_pm < 220.0)
      gmb.participation_streak_bars = 0;

   gmb.participation_continuity_score_pm = GovGmbEngV1_Clamp1000(
                                              ats.last_exec_continuity_pm * 0.45 + rci.recovery_continuity_pm * 0.35 + (double)gmb.participation_streak_bars * 6.0);
   gmb.adaptive_execution_flow_pm = GovGmbEngV1_Clamp1000(ats.last_exec_continuity_pm * 0.6 + gmb.operational_reactivation_rate_pm * 0.4);
   gmb.execution_restoration_duration_pm = GovGmbEngV1_Clamp1000((double)ats.last_bars_since_exec_hint * 1.4 + gmb.participation_reactivation_delay_pm * 0.35);
   gmb.opportunity_recovery_rate_pm = GovGmbEngV1_Clamp1000((double)rf.bars_with_executable_consensus / (double)MathMax(1UL, rf.bars_observed) * 920.0);
   gmb.starvation_recovery_velocity_pm = GovGmbEngV1_Clamp1000(MathMax(0.0, 700.0 - (double)rci.ecology_starvation_age_bars * 1.1));
   gmb.participation_continuity_class = GovGmbEngV1_ClassifyParticipation(gmb.participation_continuity_score_pm, ats.last_exec_continuity_pm, gmb.participation_streak_bars);

   gmb.adaptive_vitality_v2_pm = rci.adaptive_vitality_pm;
   gmb.operational_life_score_pm = GovGmbEngV1_Clamp1000(rci.governance_vitality_pm * 0.45 + ats.last_nervous_resilience_pm * 0.55);
   gmb.ecosystem_reanimation_pm = rci.adaptive_ecosystem_respiration_pm;
   gmb.participation_health_pm = GovGmbEngV1_Clamp1000((double)eco.ecology_balance_score_pm + gmb.participation_continuity_score_pm * 0.25);
   gmb.governance_respiration_pm = rci.governance_pulse_pm;
   gmb.adaptive_recovery_energy_pm = GovGmbEngV1_Clamp1000(rci.recovery_circulation_pm * 0.5 + gmb.recovery_life_restoration_score_pm * 0.5);
   gmb.vitality_decay_pm = GovGmbEngV1_Clamp1000(rci.recovery_decay_pressure_pm * 0.55 + gmb.mobility_inertia_pm * 0.35);
   gmb.vitality_restoration_pm = GovGmbEngV1_Clamp1000(rci.restoration_sustainability_pm * 0.55 + gmb.adaptive_recovery_energy_pm * 0.45);
   gmb.vitality_v2_class = GovGmbEngV1_ClassifyVitalityV2(rci.adaptive_life_score_pm, rci.governance_pulse_pm, can_trade, locked);

   const double starv_dense = (rli.bars_observed > 0UL) ? ((double)rli.bars_starvation_overlap / (double)rli.bars_observed) * 1000.0 : 0.0;
   gmb.starvation_density_pm = GovGmbEngV1_Clamp1000(starv_dense);
   gmb.starvation_persistence_pm = GovGmbEngV1_Clamp1000((double)rci.ecology_starvation_age_bars * 1.8 + starv_dense * 0.4);
   gmb.participation_suffocation_pm = GovGmbEngV1_Clamp1000(rci.forensic_survival_without_life_pm * 0.45 + gmb.starvation_persistence_pm * 0.55);
   gmb.governance_overprotection_pm = GovGmbEngV1_Clamp1000(rci.forensic_adaptive_paralysis_cycle_pm * 0.5 + ats.last_defensive_overreaction_pm * 0.5);
   gmb.adaptive_activity_absence_pm = GovGmbEngV1_Clamp1000(rci.governance_dormancy_depth_pm * 0.55 + (1000.0 - ats.last_exec_continuity_pm) * 0.45);
   gmb.opportunity_extinction_risk_pm = GovGmbEngV1_Clamp1000((double)rf.lost_opportunities_risk_halt * 0.35 + gmb.starvation_density_pm * 0.45);
   gmb.anti_starvation_class = GovGmbEngV1_ClassifyAntiStarve(gmb.participation_suffocation_pm, gmb.governance_overprotection_pm);

   gmb.ecology_revival_probability_pm = rci.ecology_wake_probability_pm;
   gmb.participation_entropy_recovery_track_pm = rci.participation_entropy_recovery_pm;
   gmb.diversity_restoration_pm = GovGmbEngV1_Clamp1000((double)eco.ecology_diversity_score_pm + (double)eco.ecology_entropy_score_pm * 0.35);
   gmb.monoculture_decay_pm = GovGmbEngV1_Clamp1000((double)eco.monoculture_warn * 120.0 + (1000.0 - gmb.diversity_restoration_pm) * 0.25);
   gmb.adaptive_ecology_reanimation_pm = rci.adaptive_ecosystem_respiration_pm;
   gmb.ecosystem_breathing_rate_pm = GovGmbEngV1_Clamp1000(gmb.adaptive_ecology_reanimation_pm * 0.55 + (double)eco.last_bar_suppress_clears * 28.0);

   gmb.adaptive_life_probability_track_pm = rci.adaptive_life_probability_pm;
   gmb.governance_restoration_cycle_pm = GovGmbEngV1_Clamp1000((double)rci.governance_life_phase * 110.0 + gmb.controlled_reactivation_score_pm * 0.35);
   gmb.ecosystem_awakeness_pm = GovGmbEngV1_Clamp1000(gmb.ecology_revival_probability_pm * 0.45 + gmb.ecosystem_breathing_rate_pm * 0.55);
   gmb.adaptive_operationality_pm = GovGmbEngV1_Clamp1000(gmb.operational_life_score_pm * 0.5 + gmb.adaptive_execution_flow_pm * 0.5);
   gmb.post_survival_vitality_pm = GovGmbEngV1_Clamp1000(rci.post_thaw_momentum_survival_pm * 0.4 + gmb.operational_life_score_pm * 0.35 + gmb.recovery_life_restoration_score_pm * 0.25);
   gmb.restoration_stability_pm = GovGmbEngV1_Clamp1000(gmb.adaptive_reactivation_stability_pm * 0.5 + rci.restoration_sustainability_pm * 0.5);

   for(int v = 0; v < GOV_GMB_STRAT_REVIVAL_CT_V1; v++)
      gmb.strategy_revival_hist[v] = 0;
   for(int si2 = 0; si2 < GOV_ECO_STRAT_COUNT_V1; si2++) {
      const SGovEcologyStratSliceV1 z2 = eco.s[si2];
      const int c2 = GovGmbEngV1_ClassifyStratRevival(z2.ecology_recovery_pm, z2.bars_suppression, z2.toxicity_score_permille);
      if(c2 >= 0 && c2 < GOV_GMB_STRAT_REVIVAL_CT_V1)
         gmb.strategy_revival_hist[c2]++;
   }

   const int mc = (gmb.mobility_class >= 0 && gmb.mobility_class < GOV_GMB_MOBILITY_CT_V1) ? gmb.mobility_class : 0;
   gmb.mobility_hist[mc]++;
   const int rs = (gmb.reactivation_state >= 0 && gmb.reactivation_state < GOV_GMB_REACTIV_CT_V1) ? gmb.reactivation_state : 0;
   gmb.reactivation_hist[rs]++;
   const int sd = (gmb.suppression_decay_class >= 0 && gmb.suppression_decay_class < GOV_GMB_SUPP_DECAY_CT_V1) ? gmb.suppression_decay_class : 0;
   gmb.suppression_decay_hist[sd]++;
   const int pc = (gmb.participation_continuity_class >= 0 && gmb.participation_continuity_class < GOV_GMB_PARTICIP_CT_V1) ? gmb.participation_continuity_class : 0;
   gmb.participation_hist[pc]++;
   const int v2 = (gmb.vitality_v2_class >= 0 && gmb.vitality_v2_class < GOV_GMB_VITALITY_CT_V1) ? gmb.vitality_v2_class : 0;
   gmb.vitality_v2_hist[v2]++;
   const int as = (gmb.anti_starvation_class >= 0 && gmb.anti_starvation_class < GOV_GMB_ANTISTARVE_CT_V1) ? gmb.anti_starvation_class : 0;
   gmb.anti_starve_hist[as]++;
}

#endif // __AURUM_GOV_GMB_ENGINE_V1_MQH__
