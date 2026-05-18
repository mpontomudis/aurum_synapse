//+------------------------------------------------------------------+
//| GovernanceRecoveryContinuationDatasetV1.mqh                    |
//| PHASE 24 — recovery continuation & adaptive reactivation (observe)|
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RCI_DATASET_V1_MQH__
#define __AURUM_GOV_RCI_DATASET_V1_MQH__

#define GOV_RCI_RING_V1           24
#define GOV_RCI_INERTIA_CLASS_CT_V1  5
#define GOV_RCI_LIFE_PHASE_CT_V1     8

enum ENUM_GOV_RCI_INERTIA_CLASS_V1
{
   GOV_RCI_INERTIA_LOW_V1 = 0,
   GOV_RCI_INERTIA_MODERATE_V1,
   GOV_RCI_INERTIA_HIGH_V1,
   GOV_RCI_INERTIA_CRITICAL_V1,
   GOV_RCI_INERTIA_STABLE_DEAD_V1
};

enum ENUM_GOV_RCI_LIFE_PHASE_V1
{
   GOV_RCI_LIFE_SURVIVAL_V1 = 0,
   GOV_RCI_LIFE_STABILIZATION_V1,
   GOV_RCI_LIFE_THAW_V1,
   GOV_RCI_LIFE_REACTIVATION_V1,
   GOV_RCI_LIFE_ADAPTIVE_RESTORATION_V1,
   GOV_RCI_LIFE_ECOLOGICAL_RECOVERY_V1,
   GOV_RCI_LIFE_LIVING_CONTINUITY_V1,
   GOV_RCI_LIFE_DORMANT_TRAP_V1
};

enum ENUM_GOV_RCI_TIMELINE_CODE_V1
{
   GOV_RCI_TL_NONE_V1 = 0,
   GOV_RCI_TL_THAW_ATTEMPT_V1,
   GOV_RCI_TL_CONTINUATION_FAIL_V1,
   GOV_RCI_TL_ACTIVATION_SPIKE_V1,
   GOV_RCI_TL_RESTORATION_COLLAPSE_V1,
   GOV_RCI_TL_RECOVERY_STREAK_V1,
   GOV_RCI_TL_ECOSYSTEM_WAKE_V1,
   GOV_RCI_TL_POST_THAW_REGRESS_V1
};

struct SGovRciTimelineEntryV1
{
   ulong bar_idx;
   int   code;
};

struct SGovRciStoreV1
{
   bool     enabled;
   ulong    bars_observed;

   double   continuation_confidence_pm;
   double   recovery_continuity_pm;
   double   activation_inertia_pm;
   double   adaptive_life_probability_pm;
   double   governance_dormancy_depth_pm;
   double   post_thaw_momentum_survival_pm;
   double   recovery_decay_pressure_pm;
   double   ecosystem_awakening_readiness_pm;
   double   participation_restoration_probability_pm;
   double   strategic_reentry_resistance_pm;

   ulong    continuation_streak_bars;
   ulong    continuation_collapse_events;
   ulong    continuation_plateau_zones;
   ulong    thaw_to_activity_latency_last;
   ulong    recovery_momentum_half_life_bars;
   double   recovery_slope_degradation_pm;
   ulong    adaptive_restoration_attempts;
   ulong    governance_reactivation_failures;

   double   inertia_accum_pm;
   ulong    dormant_governance_age_bars;
   double   inactivity_drag_pm;
   double   suppression_persistence_pm;
   double   strategy_activation_hesitation_pm;
   ulong    ecology_starvation_age_bars;
   double   dormant_reinforcement_pm;
   double   anti_reactivation_pressure_pm;
   int      inertia_class;
   double   paralysis_severity_pm;
   double   restoration_resistance_pm;
   double   activation_friction_pm;
   double   recovery_blockers_pm;

   double   ecology_wake_probability_pm;
   ulong    dormant_strategy_age_bars;
   double   ecology_awakening_pressure_pm;
   double   adaptive_participation_readiness_pm;
   double   suppression_fatigue_pm;
   double   regime_safe_reactivation_pm;
   double   strategy_hesitation_map_pm;
   double   ecosystem_vitality_pm;
   double   adaptive_ecosystem_respiration_pm;
   double   strategy_life_signals_pm;
   double   ecology_restoration_confidence_pm;
   double   participation_entropy_recovery_pm;
   int      dead_ecosystem_loop_hint;

   int      governance_life_phase;
   double   adaptive_vitality_pm;
   double   ecosystem_respiration_pm;
   double   governance_pulse_pm;
   double   recovery_circulation_pm;
   double   adaptive_nervous_continuity_pm;
   double   governance_vitality_pm;
   double   adaptive_life_score_pm;
   double   ecosystem_survivability_pm;
   double   restoration_sustainability_pm;
   double   adaptive_continuity_confidence_pm;

   double   forensic_survival_without_life_pm;
   double   forensic_perpetual_stabilization_pm;
   double   forensic_dormant_trap_pm;
   double   forensic_adaptive_paralysis_cycle_pm;

   ulong    continuation_duration_hist[8];
   ulong    inertia_class_hist[GOV_RCI_INERTIA_CLASS_CT_V1];
   ulong    life_phase_hist[GOV_RCI_LIFE_PHASE_CT_V1];

   double   prev_recovery_momentum_pm;
   ulong    prev_continuation_streak;
   ulong    dormant_streak_bars;
   ulong    plateau_streak_bars;
   ulong    prev_ecology_part_sum;
   ulong    thaw_window_start_bar;
   bool     thaw_window_track;
   ulong    last_exec_bar_seen;

   SGovRciTimelineEntryV1 ring[GOV_RCI_RING_V1];
   int      ring_wi;
   int      ring_count;

   string   last_narrative_summary;
};

inline SGovRciStoreV1 g_gov_rci_v1;

inline void GovRciDsV1_PushRing(SGovRciStoreV1 &st, const ulong bar_idx, const int code)
{
   const int wi = st.ring_wi;
   st.ring[wi].bar_idx = bar_idx;
   st.ring[wi].code = code;
   st.ring_wi = (wi + 1) % GOV_RCI_RING_V1;
   if(st.ring_count < GOV_RCI_RING_V1)
      st.ring_count++;
}

inline void GovRciDsV1_Init(SGovRciStoreV1 &st)
{
   st.enabled = false;
   st.bars_observed = 0;
   st.continuation_confidence_pm = 0.0;
   st.recovery_continuity_pm = 0.0;
   st.activation_inertia_pm = 0.0;
   st.adaptive_life_probability_pm = 0.0;
   st.governance_dormancy_depth_pm = 0.0;
   st.post_thaw_momentum_survival_pm = 0.0;
   st.recovery_decay_pressure_pm = 0.0;
   st.ecosystem_awakening_readiness_pm = 0.0;
   st.participation_restoration_probability_pm = 0.0;
   st.strategic_reentry_resistance_pm = 0.0;
   st.continuation_streak_bars = 0;
   st.continuation_collapse_events = 0;
   st.continuation_plateau_zones = 0;
   st.thaw_to_activity_latency_last = 0;
   st.recovery_momentum_half_life_bars = 0;
   st.recovery_slope_degradation_pm = 0.0;
   st.adaptive_restoration_attempts = 0;
   st.governance_reactivation_failures = 0;
   st.inertia_accum_pm = 0.0;
   st.dormant_governance_age_bars = 0;
   st.inactivity_drag_pm = 0.0;
   st.suppression_persistence_pm = 0.0;
   st.strategy_activation_hesitation_pm = 0.0;
   st.ecology_starvation_age_bars = 0;
   st.dormant_reinforcement_pm = 0.0;
   st.anti_reactivation_pressure_pm = 0.0;
   st.inertia_class = (int)GOV_RCI_INERTIA_LOW_V1;
   st.paralysis_severity_pm = 0.0;
   st.restoration_resistance_pm = 0.0;
   st.activation_friction_pm = 0.0;
   st.recovery_blockers_pm = 0.0;
   st.ecology_wake_probability_pm = 0.0;
   st.dormant_strategy_age_bars = 0;
   st.ecology_awakening_pressure_pm = 0.0;
   st.adaptive_participation_readiness_pm = 0.0;
   st.suppression_fatigue_pm = 0.0;
   st.regime_safe_reactivation_pm = 0.0;
   st.strategy_hesitation_map_pm = 0.0;
   st.ecosystem_vitality_pm = 0.0;
   st.adaptive_ecosystem_respiration_pm = 0.0;
   st.strategy_life_signals_pm = 0.0;
   st.ecology_restoration_confidence_pm = 0.0;
   st.participation_entropy_recovery_pm = 0.0;
   st.dead_ecosystem_loop_hint = 0;
   st.governance_life_phase = (int)GOV_RCI_LIFE_SURVIVAL_V1;
   st.adaptive_vitality_pm = 0.0;
   st.ecosystem_respiration_pm = 0.0;
   st.governance_pulse_pm = 0.0;
   st.recovery_circulation_pm = 0.0;
   st.adaptive_nervous_continuity_pm = 0.0;
   st.governance_vitality_pm = 0.0;
   st.adaptive_life_score_pm = 0.0;
   st.ecosystem_survivability_pm = 0.0;
   st.restoration_sustainability_pm = 0.0;
   st.adaptive_continuity_confidence_pm = 0.0;
   st.forensic_survival_without_life_pm = 0.0;
   st.forensic_perpetual_stabilization_pm = 0.0;
   st.forensic_dormant_trap_pm = 0.0;
   st.forensic_adaptive_paralysis_cycle_pm = 0.0;
   for(int i = 0; i < 8; i++)
      st.continuation_duration_hist[i] = 0;
   for(int j = 0; j < GOV_RCI_INERTIA_CLASS_CT_V1; j++)
      st.inertia_class_hist[j] = 0;
   for(int k = 0; k < GOV_RCI_LIFE_PHASE_CT_V1; k++)
      st.life_phase_hist[k] = 0;
   st.prev_recovery_momentum_pm = 0.0;
   st.prev_continuation_streak = 0;
   st.dormant_streak_bars = 0;
   st.plateau_streak_bars = 0;
   st.prev_ecology_part_sum = 0;
   st.thaw_window_start_bar = 0;
   st.thaw_window_track = false;
   st.last_exec_bar_seen = 0;
   st.ring_wi = 0;
   st.ring_count = 0;
   for(int r = 0; r < GOV_RCI_RING_V1; r++) {
      st.ring[r].bar_idx = 0;
      st.ring[r].code = 0;
   }
   st.last_narrative_summary = "";
}

#endif // __AURUM_GOV_RCI_DATASET_V1_MQH__
