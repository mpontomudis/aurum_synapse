//+------------------------------------------------------------------+
//| GovernanceRecoveryContinuationEngineV1.mqh                     |
//| PHASE 24 — observe-only continuation / inertia / lifecycle        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RCI_ENGINE_V1_MQH__
#define __AURUM_GOV_RCI_ENGINE_V1_MQH__

#include "../RiskLockIntelligenceV1/RiskLockIntelligenceDatasetV1.mqh"
#include "../GovernanceRestrictionForensicsV1/GovernanceRestrictionForensicsDatasetV1.mqh"
#include "../GovernanceEcologyEngineV1/GovernanceEcologyDatasetV1.mqh"
#include "../AdaptiveThawStabilizationV1/AdaptiveThawStabilizationDatasetV1.mqh"
#include "GovernanceRecoveryContinuationDatasetV1.mqh"

inline double GovRciEngV1_Clamp1000(const double x)
{
   return MathMax(0.0, MathMin(1000.0, x));
}

inline ulong GovRciEngV1_EcologyPartSum(const SGovEcologyStoreV1 &eco)
{
   ulong s = 0;
   for(int i = 0; i < GOV_ECO_STRAT_COUNT_V1; i++)
      s += eco.s[i].bars_participation;
   return s;
}

inline int GovRciEngV1_RfMaxStarve(const SGovRfStoreV1 &rf)
{
   int mx = 0;
   for(int i = 0; i < GOV_RF_STRAT_CT_V1; i++) {
      if(rf.strat_starve_bars[i] > mx)
         mx = rf.strat_starve_bars[i];
   }
   return mx;
}

inline ulong GovRciEngV1_MaxStratSuppressionBars(const SGovEcologyStoreV1 &eco)
{
   ulong mx = 0;
   for(int i = 0; i < GOV_ECO_STRAT_COUNT_V1; i++) {
      if(eco.s[i].bars_suppression > mx)
         mx = eco.s[i].bars_suppression;
   }
   return mx;
}

inline int GovRciEngV1_ClassifyInertia(const double drag_pm,
                                      const ulong dormant_bars,
                                      const double anti_react_pm,
                                      const bool stable_dead_hint)
{
   if(stable_dead_hint && dormant_bars > 40UL)
      return (int)GOV_RCI_INERTIA_STABLE_DEAD_V1;
   if(drag_pm > 820.0 || dormant_bars > 220UL)
      return (int)GOV_RCI_INERTIA_CRITICAL_V1;
   if(drag_pm > 560.0 || dormant_bars > 120UL || anti_react_pm > 700.0)
      return (int)GOV_RCI_INERTIA_HIGH_V1;
   if(drag_pm > 320.0 || dormant_bars > 48UL)
      return (int)GOV_RCI_INERTIA_MODERATE_V1;
   return (int)GOV_RCI_INERTIA_LOW_V1;
}

inline void GovRciEngV1_OnBar(SGovRciStoreV1 &st,
                             const SGovRliStoreV1 &rli,
                             const SGovRfStoreV1 &rf,
                             const SGovEcologyStoreV1 &eco,
                             const SGovAtsStoreV1 &ats,
                             const ulong bar_seq,
                             const double eq_dd,
                             const bool can_trade)
{
   if(!st.enabled)
      return;
   st.bars_observed++;

   const ulong eco_sum = GovRciEngV1_EcologyPartSum(eco);
   const long eco_delta = (st.bars_observed > 1UL && st.prev_ecology_part_sum > 0UL)
                          ? ((long)eco_sum - (long)st.prev_ecology_part_sum)
                          : 0L;
   st.prev_ecology_part_sum = eco_sum;

   const bool locked_or_halt = (!can_trade || rli.lock_active);
   const bool exec_this_bar = (rli.last_exec_bar_idx == bar_seq && bar_seq > 0UL);
   if(exec_this_bar)
      st.last_exec_bar_seen = bar_seq;

   const bool activity_pulse = (exec_this_bar || eco_delta > 0L || ats.last_exec_continuity_pm > 420.0);
   const bool favorable = (can_trade && !rli.lock_active && ats.last_thaw_confidence_pm >= 380.0 && eq_dd < 11.0);

   if(favorable && activity_pulse) {
      st.continuation_streak_bars++;
      st.dormant_streak_bars = 0;
   } else if(favorable) {
      st.dormant_streak_bars++;
      if(st.continuation_streak_bars > 0UL)
         st.continuation_streak_bars = 0;
   } else {
      st.continuation_streak_bars = 0;
      if(locked_or_halt)
         st.dormant_streak_bars = 0;
      else
         st.dormant_streak_bars++;
   }

   if(st.prev_continuation_streak >= 8UL && st.continuation_streak_bars == 0UL && favorable) {
      st.continuation_collapse_events++;
      GovRciDsV1_PushRing(st, bar_seq, (int)GOV_RCI_TL_CONTINUATION_FAIL_V1);
   }
   st.prev_continuation_streak = st.continuation_streak_bars;

   const double mom_delta = ats.last_recovery_momentum_pm - st.prev_recovery_momentum_pm;
   st.recovery_slope_degradation_pm = GovRciEngV1_Clamp1000(MathMax(0.0, -mom_delta) * 4.0);
   if(MathAbs(mom_delta) < 18.0) {
      st.plateau_streak_bars++;
      if(st.plateau_streak_bars == 25UL)
         st.continuation_plateau_zones++;
   } else {
      if(st.plateau_streak_bars > 24UL && MathAbs(mom_delta) > 35.0)
         st.continuation_plateau_zones++;
      st.plateau_streak_bars = 0;
   }
   st.prev_recovery_momentum_pm = ats.last_recovery_momentum_pm;

   if(rli.in_post_thaw_window && !st.thaw_window_track) {
      st.thaw_window_track = true;
      st.thaw_window_start_bar = bar_seq;
   }
   if(st.thaw_window_track && activity_pulse && st.thaw_window_start_bar > 0UL && bar_seq >= st.thaw_window_start_bar) {
      st.thaw_to_activity_latency_last = bar_seq - st.thaw_window_start_bar;
      GovRciDsV1_PushRing(st, bar_seq, (int)GOV_RCI_TL_ACTIVATION_SPIKE_V1);
      st.thaw_window_track = false;
   }
   if(!rli.in_post_thaw_window)
      st.thaw_window_track = false;

   if(activity_pulse && favorable && ats.last_recovery_state >= (int)GOV_ATS_REC_STABILIZING_V1)
      st.adaptive_restoration_attempts++;
   if(favorable && ats.last_paralysis_index_pm > 720.0 && st.dormant_streak_bars > 12UL)
      st.governance_reactivation_failures++;

   const double deny_ratio = (rf.bars_observed > 0UL) ? ((double)rf.bars_under_risk_denial / (double)rf.bars_observed) : 0.0;
   const int mx_starve = GovRciEngV1_RfMaxStarve(rf);
   const ulong bars_since_exec = (rli.last_exec_bar_idx > 0UL && bar_seq > rli.last_exec_bar_idx) ? (bar_seq - rli.last_exec_bar_idx) : rli.bars_observed;

   st.governance_dormancy_depth_pm = GovRciEngV1_Clamp1000(
                                        (double)st.dormant_streak_bars * 2.6 + (double)bars_since_exec * 0.55 + deny_ratio * 420.0);
   st.post_thaw_momentum_survival_pm = GovRciEngV1_Clamp1000(
                                          ats.last_recovery_momentum_pm * 0.55 + ats.last_thaw_stability_pm * 0.45 - (rli.in_post_thaw_window ? 40.0 : 0.0));
   st.recovery_decay_pressure_pm = GovRciEngV1_Clamp1000(
                                      (eq_dd < ats.prev_eq_dd + 0.05 ? 120.0 : 0.0) + (activity_pulse ? 0.0 : 280.0) + st.recovery_slope_degradation_pm * 0.35);

   st.continuation_confidence_pm = GovRciEngV1_Clamp1000(
                                      ats.last_thaw_confidence_pm * 0.35 + ats.last_recovery_momentum_pm * 0.3 + ats.last_exec_continuity_pm * 0.25
                                      - st.governance_dormancy_depth_pm * 0.22);
   st.recovery_continuity_pm = GovRciEngV1_Clamp1000(
                                  ats.last_exec_continuity_pm * (locked_or_halt ? 0.25 : 1.0) + (double)MathMin(80L, eco_delta) * 5.0);
   st.activation_inertia_pm = GovRciEngV1_Clamp1000(
                                 (double)st.dormant_streak_bars * 3.1 + (double)mx_starve * 1.15 + ats.last_paralysis_index_pm * 0.25);
   st.adaptive_life_probability_pm = GovRciEngV1_Clamp1000(
                                         (double)eco.ecology_entropy_score_pm * 0.45 + (double)eco.ecology_diversity_score_pm * 0.55
                                         + (double)MathMax(0L, eco_delta) * 12.0);
   st.ecosystem_awakening_readiness_pm = GovRciEngV1_Clamp1000(
                                           ats.last_ecology_recovery_pm + (double)eco.last_bar_suppress_clears * 28.0 + st.adaptive_life_probability_pm * 0.2);
   st.participation_restoration_probability_pm = GovRciEngV1_Clamp1000(
                                                    700.0 - (double)mx_starve * 1.4 - deny_ratio * 380.0 + (double)eco_delta * 8.0);
   st.strategic_reentry_resistance_pm = GovRciEngV1_Clamp1000(
                                           (double)rf.lost_opportunities_risk_halt * 0.15 + (double)rf.consensus_failures * 0.22 + ats.last_defensive_overreaction_pm * 0.35);

   st.inertia_accum_pm = GovRciEngV1_Clamp1000(st.activation_inertia_pm + deny_ratio * 500.0);
   st.dormant_governance_age_bars = st.dormant_streak_bars;
   st.inactivity_drag_pm = GovRciEngV1_Clamp1000((double)st.dormant_streak_bars * 2.2 + (double)bars_since_exec * 0.65);
   st.suppression_persistence_pm = GovRciEngV1_Clamp1000((double)GovRciEngV1_MaxStratSuppressionBars(eco) * 2.5 + (double)eco.last_bar_throttle_events * 40.0);
   st.strategy_activation_hesitation_pm = GovRciEngV1_Clamp1000(st.strategic_reentry_resistance_pm * 0.6 + st.suppression_persistence_pm * 0.35);
   st.ecology_starvation_age_bars = (ulong)MathMax(mx_starve, (int)MathMin(100000, (int)bars_since_exec));
   st.dormant_reinforcement_pm = GovRciEngV1_Clamp1000((double)st.dormant_streak_bars * 1.8 + st.suppression_persistence_pm * 0.4);
   st.anti_reactivation_pressure_pm = GovRciEngV1_Clamp1000(ats.last_paralysis_index_pm * 0.7 + st.strategic_reentry_resistance_pm * 0.3);
   st.paralysis_severity_pm = ats.last_paralysis_index_pm;
   st.restoration_resistance_pm = GovRciEngV1_Clamp1000(st.anti_reactivation_pressure_pm + st.inactivity_drag_pm * 0.35);
   st.activation_friction_pm = GovRciEngV1_Clamp1000(st.restoration_resistance_pm * 0.55 + (double)mx_starve * 1.2);
   st.recovery_blockers_pm = GovRciEngV1_Clamp1000(deny_ratio * 900.0 + (locked_or_halt ? 180.0 : 0.0) + st.strategic_reentry_resistance_pm * 0.25);

   const bool stable_dead_hint = (favorable && st.dormant_streak_bars > 35UL && ats.last_thaw_confidence_pm > 520.0 && ats.last_exec_continuity_pm < 320.0);
   st.inertia_class = GovRciEngV1_ClassifyInertia(st.inactivity_drag_pm, st.dormant_streak_bars, st.anti_reactivation_pressure_pm, stable_dead_hint);

   st.ecology_wake_probability_pm = GovRciEngV1_Clamp1000(st.ecosystem_awakening_readiness_pm * 0.55 + (double)eco.ecology_balance_score_pm * 0.45);
   st.dormant_strategy_age_bars = GovRciEngV1_MaxStratSuppressionBars(eco);
   st.ecology_awakening_pressure_pm = GovRciEngV1_Clamp1000((double)eco.last_bar_suppress_clears * 45.0 + st.participation_restoration_probability_pm * 0.25);
   st.adaptive_participation_readiness_pm = GovRciEngV1_Clamp1000(st.participation_restoration_probability_pm * 0.5 + st.adaptive_life_probability_pm * 0.5);
   st.suppression_fatigue_pm = GovRciEngV1_Clamp1000((double)st.dormant_strategy_age_bars * 1.8 + st.suppression_persistence_pm * 0.35);
   st.regime_safe_reactivation_pm = GovRciEngV1_Clamp1000(800.0 - eq_dd * 28.0 - (locked_or_halt ? 200.0 : 0.0));
   st.strategy_hesitation_map_pm = st.strategy_activation_hesitation_pm;
   st.ecosystem_vitality_pm = GovRciEngV1_Clamp1000((double)eco.ecology_diversity_score_pm * 0.5 + (double)eco.ecology_entropy_score_pm * 0.5);
   st.adaptive_ecosystem_respiration_pm = GovRciEngV1_Clamp1000((double)MathMax(0L, eco_delta) * 25.0 + (double)eco.last_bar_suppress_clears * 22.0);
   st.strategy_life_signals_pm = GovRciEngV1_Clamp1000((double)MathMax(0L, eco_delta) * 40.0 + ats.last_exec_continuity_pm * 0.35);
   st.ecology_restoration_confidence_pm = GovRciEngV1_Clamp1000(st.ecology_wake_probability_pm * 0.4 + st.adaptive_participation_readiness_pm * 0.45);
   st.participation_entropy_recovery_pm = GovRciEngV1_Clamp1000((double)eco.ecology_entropy_score_pm * 0.7 + (double)MathMax(0L, eco_delta) * 15.0);
   st.dead_ecosystem_loop_hint = (eco.monoculture_warn > 0 && eco_sum < 20UL && favorable) ? 1 : 0;

   int phase = (int)GOV_RCI_LIFE_SURVIVAL_V1;
   if(locked_or_halt)
      phase = (int)GOV_RCI_LIFE_SURVIVAL_V1;
   else if(eq_dd >= 9.5)
      phase = (int)GOV_RCI_LIFE_STABILIZATION_V1;
   else if(rli.in_post_thaw_window)
      phase = (int)GOV_RCI_LIFE_THAW_V1;
   else if(stable_dead_hint || st.inertia_class == (int)GOV_RCI_INERTIA_STABLE_DEAD_V1)
      phase = (int)GOV_RCI_LIFE_DORMANT_TRAP_V1;
   else if(eco.ecology_entropy_score_pm > 380 && eco_delta > 0L)
      phase = (int)GOV_RCI_LIFE_ECOLOGICAL_RECOVERY_V1;
   else if(st.continuation_streak_bars > 6UL && activity_pulse)
      phase = (int)GOV_RCI_LIFE_LIVING_CONTINUITY_V1;
   else if(ats.last_recovery_state == (int)GOV_ATS_REC_RECOVERING_V1 || ats.last_recovery_state == (int)GOV_ATS_REC_STABILIZING_V1)
      phase = (int)GOV_RCI_LIFE_REACTIVATION_V1;
   else if(st.adaptive_participation_readiness_pm > 520.0)
      phase = (int)GOV_RCI_LIFE_ADAPTIVE_RESTORATION_V1;
   else
      phase = (int)GOV_RCI_LIFE_REACTIVATION_V1;
   st.governance_life_phase = phase;

   st.adaptive_vitality_pm = GovRciEngV1_Clamp1000(st.adaptive_life_probability_pm * 0.45 + ats.last_nervous_resilience_pm * 0.55);
   st.ecosystem_respiration_pm = st.adaptive_ecosystem_respiration_pm;
   st.governance_pulse_pm = GovRciEngV1_Clamp1000(700.0 - st.paralysis_severity_pm * 0.45 + (activity_pulse ? 120.0 : 0.0));
   st.recovery_circulation_pm = GovRciEngV1_Clamp1000(ats.last_recovery_momentum_pm * 0.5 + st.recovery_continuity_pm * 0.5);
   st.adaptive_nervous_continuity_pm = GovRciEngV1_Clamp1000(ats.last_nervous_resilience_pm * 0.5 + st.continuation_confidence_pm * 0.5);
   st.governance_vitality_pm = GovRciEngV1_Clamp1000(st.governance_pulse_pm * 0.4 + st.adaptive_vitality_pm * 0.35 + st.ecosystem_vitality_pm * 0.25);
   st.adaptive_life_score_pm = GovRciEngV1_Clamp1000(st.adaptive_life_probability_pm * 0.5 + st.strategy_life_signals_pm * 0.5);
   st.ecosystem_survivability_pm = GovRciEngV1_Clamp1000((double)eco.ecology_balance_score_pm + st.ecosystem_vitality_pm * 0.35);
   st.restoration_sustainability_pm = GovRciEngV1_Clamp1000(st.ecology_restoration_confidence_pm * 0.55 + MathMax(0.0, 280.0 - st.restoration_resistance_pm * 0.28));
   st.adaptive_continuity_confidence_pm = GovRciEngV1_Clamp1000(st.continuation_confidence_pm * 0.45 + st.recovery_continuity_pm * 0.55);

   st.recovery_momentum_half_life_bars = (ulong)MathMax(8UL, MathMin(2000UL, (ulong)(420.0 / MathMax(8.0, st.recovery_slope_degradation_pm + 5.0))));

   st.forensic_survival_without_life_pm = GovRciEngV1_Clamp1000((favorable ? 280.0 : 0.0) + (st.dormant_streak_bars > 50UL ? 320.0 : 0.0) + (1.0 - st.adaptive_life_probability_pm / 1000.0) * 200.0);
   st.forensic_perpetual_stabilization_pm = GovRciEngV1_Clamp1000((st.plateau_streak_bars > 30UL ? 260.0 : 0.0) + (ats.last_thaw_stability_pm > 700.0 && st.continuation_streak_bars < 2UL ? 240.0 : 0.0));
   st.forensic_dormant_trap_pm = GovRciEngV1_Clamp1000((phase == (int)GOV_RCI_LIFE_DORMANT_TRAP_V1 ? 500.0 : 0.0) + stable_dead_hint * 220.0);
   st.forensic_adaptive_paralysis_cycle_pm = GovRciEngV1_Clamp1000(ats.last_paralysis_index_pm * 0.5 + st.activation_inertia_pm * 0.5);

   const int dur_idx = (int)MathMin(7L, (long)(st.continuation_streak_bars / 6UL));
   st.continuation_duration_hist[dur_idx]++;

   const int ic = (st.inertia_class >= 0 && st.inertia_class < GOV_RCI_INERTIA_CLASS_CT_V1) ? st.inertia_class : 0;
   st.inertia_class_hist[ic]++;
   const int lp = (st.governance_life_phase >= 0 && st.governance_life_phase < GOV_RCI_LIFE_PHASE_CT_V1) ? st.governance_life_phase : 0;
   st.life_phase_hist[lp]++;

   string nar = "";
   if(locked_or_halt)
      nar = "Life-phase: survival or halt — continuation telemetry is subordinate to RiskManager lock state.";
   else if(phase == (int)GOV_RCI_LIFE_DORMANT_TRAP_V1 || stable_dead_hint)
      nar = "Dormant-trap signature: thaw/stabilization looks healthy but execution and ecology participation remain flat — defensive inertia dominates adaptive restoration.";
   else if(st.continuation_collapse_events > 0UL && st.continuation_confidence_pm < 400.0)
      nar = "Continuation weakness: post-thaw momentum collapsed before sustained activation; correlate with restriction forensics and ecology suppression clears.";
   else if(st.dead_ecosystem_loop_hint != 0)
      nar = "Ecology risk: monoculture / low participation entropy — revival may require diversity signals, not faster unlocking.";
   else if(st.adaptive_continuity_confidence_pm > 560.0)
      nar = "Adaptive continuity strengthening: continuation and recovery channels align; still observational — verify with execution and ecology CSVs.";
   else
      nar = "Mixed recovery continuation: monitor inertia class vs thaw confidence to separate temporary drag from structural participation absence.";
   st.last_narrative_summary = nar;
}

#endif // __AURUM_GOV_RCI_ENGINE_V1_MQH__
