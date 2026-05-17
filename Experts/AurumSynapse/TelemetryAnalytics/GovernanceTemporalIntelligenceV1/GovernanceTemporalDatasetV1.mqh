//+------------------------------------------------------------------+
//| GovernanceTemporalDatasetV1.mqh                                 |
//| GOVERNANCE_TEMPORAL_INTELLIGENCE_V1 — datasets                   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_TMP_DS_V1_MQH__
#define __AURUM_GOV_TMP_DS_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

struct SGovTemporalEpochV1 {
    int epoch_id;
    int era_id;
    int epoch_duration;
    int continuity_score_milli;
    int survivability_score_milli;
    int governance_pressure_milli;
    int decay_velocity_milli;
    int recovery_strength_milli;
    int collapse_risk_milli;
};

struct SGovGovernanceAgingV1 {
    int governance_age_epochs;
    int fatigue_accumulation_milli;
    int survivability_decay_milli;
    int continuity_decay_milli;
    int governance_entropy_milli;
    int temporal_instability_milli;
};

struct SGovContinuityV1 {
    int continuity_strength_milli;
    int continuity_break_risk_milli;
    int recovery_recurrence_milli;
    int governance_persistence_milli;
    int temporal_alignment_milli;
};

struct SGovCyclePatternV1 {
    int cycle_count;
    int cycle_stability_milli;
    int cycle_recurrence_milli;
    int collapse_cycle_milli;
    int recovery_cycle_milli;
    int seasonal_instability_milli;
};

struct SGovEraTransitionV1 {
    int transition_count;
    int transition_pressure_milli;
    int era_fragmentation_milli;
    int regime_shift_milli;
    int civilization_shift_milli;
};

struct SGovTemporalPressureV1 {
    int cumulative_pressure_milli;
    int delayed_recovery_pressure_milli;
    int governance_saturation_milli;
    int temporal_overload_milli;
    int systemic_pressure_milli;
};

struct SGovTemporalDecayV1 {
    int decay_acceleration_milli;
    int resilience_decay_milli;
    int survivability_decay_milli;
    int civilization_decay_milli;
    int structural_decay_milli;
};

struct SGovTemporalStabilityV1 {
    int temporal_stability_milli;
    int long_horizon_survivability_milli;
    int civilization_continuity_milli;
    int collapse_resistance_milli;
    int governance_endurance_milli;
};

struct SGovTemporalSummaryV1 {
    int temporal_window_id;
    string replay_hash;
    string policy_fingerprint;
    int epoch_count;
    int temporal_stability_milli;
    int long_cycle_survivability_milli;
    int era_transition_pressure_milli;
    int cumulative_temporal_pressure_milli;
    int decay_composite_milli;
    int continuity_strength_milli;
    int aging_entropy_milli;
};

struct SGovTemporalComparisonV1 {
    int d_temporal_stability_milli;
    int d_long_cycle_survivability_milli;
    int d_era_transition_pressure_milli;
    int d_cumulative_temporal_pressure_milli;
    int d_decay_composite_milli;
    int d_continuity_strength_milli;
    int d_aging_entropy_milli;
};

void GovTmpDsV1_InitEpoch(SGovTemporalEpochV1 &e) {
    e.epoch_id = 0;
    e.era_id = 0;
    e.epoch_duration = 0;
    e.continuity_score_milli = 0;
    e.survivability_score_milli = 0;
    e.governance_pressure_milli = 0;
    e.decay_velocity_milli = 0;
    e.recovery_strength_milli = 0;
    e.collapse_risk_milli = 0;
}

void GovTmpDsV1_InitAging(SGovGovernanceAgingV1 &a) {
    a.governance_age_epochs = 0;
    a.fatigue_accumulation_milli = 0;
    a.survivability_decay_milli = 0;
    a.continuity_decay_milli = 0;
    a.governance_entropy_milli = 0;
    a.temporal_instability_milli = 0;
}

void GovTmpDsV1_InitCont(SGovContinuityV1 &c) {
    c.continuity_strength_milli = 0;
    c.continuity_break_risk_milli = 0;
    c.recovery_recurrence_milli = 0;
    c.governance_persistence_milli = 0;
    c.temporal_alignment_milli = 0;
}

void GovTmpDsV1_InitCycle(SGovCyclePatternV1 &c) {
    c.cycle_count = 0;
    c.cycle_stability_milli = 0;
    c.cycle_recurrence_milli = 0;
    c.collapse_cycle_milli = 0;
    c.recovery_cycle_milli = 0;
    c.seasonal_instability_milli = 0;
}

void GovTmpDsV1_InitEraTr(SGovEraTransitionV1 &e) {
    e.transition_count = 0;
    e.transition_pressure_milli = 0;
    e.era_fragmentation_milli = 0;
    e.regime_shift_milli = 0;
    e.civilization_shift_milli = 0;
}

void GovTmpDsV1_InitPress(SGovTemporalPressureV1 &p) {
    p.cumulative_pressure_milli = 0;
    p.delayed_recovery_pressure_milli = 0;
    p.governance_saturation_milli = 0;
    p.temporal_overload_milli = 0;
    p.systemic_pressure_milli = 0;
}

void GovTmpDsV1_InitDecay(SGovTemporalDecayV1 &d) {
    d.decay_acceleration_milli = 0;
    d.resilience_decay_milli = 0;
    d.survivability_decay_milli = 0;
    d.civilization_decay_milli = 0;
    d.structural_decay_milli = 0;
}

void GovTmpDsV1_InitStab(SGovTemporalStabilityV1 &s) {
    s.temporal_stability_milli = 0;
    s.long_horizon_survivability_milli = 0;
    s.civilization_continuity_milli = 0;
    s.collapse_resistance_milli = 0;
    s.governance_endurance_milli = 0;
}

void GovTmpDsV1_InitSummary(SGovTemporalSummaryV1 &s) {
    s.temporal_window_id = 0;
    s.replay_hash = "";
    s.policy_fingerprint = "";
    s.epoch_count = 0;
    s.temporal_stability_milli = 0;
    s.long_cycle_survivability_milli = 0;
    s.era_transition_pressure_milli = 0;
    s.cumulative_temporal_pressure_milli = 0;
    s.decay_composite_milli = 0;
    s.continuity_strength_milli = 0;
    s.aging_entropy_milli = 0;
}

void GovTmpDsV1_InitCmp(SGovTemporalComparisonV1 &c) {
    c.d_temporal_stability_milli = 0;
    c.d_long_cycle_survivability_milli = 0;
    c.d_era_transition_pressure_milli = 0;
    c.d_cumulative_temporal_pressure_milli = 0;
    c.d_decay_composite_milli = 0;
    c.d_continuity_strength_milli = 0;
    c.d_aging_entropy_milli = 0;
}

#endif // __AURUM_GOV_TMP_DS_V1_MQH__
