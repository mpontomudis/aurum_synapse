//+------------------------------------------------------------------+
//| GovernanceResilienceDatasetV1.mqh                              |
//| GOVERNANCE_RESILIENCE_INTELLIGENCE_V1 — canonical datasets      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RESILIENCE_DS_V1_MQH__
#define __AURUM_GOV_RESILIENCE_DS_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

struct SGovResilienceWindowV1 {
    int    resilience_window_id;
    int    start_epoch_ix;
    int    end_epoch_ix;
    string replay_hash;
};

struct SGovResilienceCurveV1 {
    int survivability_decay_slope_milli;
    int toxicity_rise_slope_milli;
    int containment_pressure_slope_milli;
    int quarantine_saturation_peak;
    int plateau_epoch_segments;
    int stabilization_recovery_epochs;
    int collapse_acceleration_score_0_1000;
    int recovery_curve_quality_0_1000;
    int degradation_velocity_milli;
    int resilience_half_life_epochs;
};

struct SGovGovernanceFatigueV1 {
    int lockdown_density_per_1000;
    int throttle_escalation_persistence_0_1000;
    int flatten_accumulation_0_1000;
    int quarantine_reuse_pressure_0_1000;
    int execution_suppression_fatigue_per_1000;
    int recovery_instability_0_1000;
    int fatigue_composite_0_1000;
};

struct SGovCollapseResistanceV1 {
    int collapse_resistance_score_0_1000;
    int resilience_interruption_efficiency_0_1000;
    int stabilization_interruption_latency_epochs;
    int containment_interruption_quality_0_1000;
};

struct SGovRegimeBrittlenessV1 {
    int brittleness_score_0_1000;
    int oscillation_index_0_1000;
    int regime_half_life_epochs;
    int stabilization_persistence_0_1000;
};

struct SGovResilienceStressResponseV1 {
    int archetype_id;
    int stress_lane_code;
    int lane_health_proxy_0_1000;
    int lane_collapse_resistance_0_1000;
    int lane_fatigue_load_0_1000;
};

struct SGovResilienceSummaryV1 {
    int    resilience_window_id;
    string replay_hash;
    string policy_fingerprint;
    int    governance_health_0_1000;
    int    containment_resilience_0_1000;
    int    survivability_resilience_0_1000;
    int    recovery_elasticity_0_1000;
    int    collapse_resistance_0_1000;
    int    quarantine_saturation_0_1000;
    int    intervention_density_0_1000;
    int    regime_brittleness_0_1000;
    int    degradation_velocity_milli;
    int    resilience_half_life_epochs;
    int    stabilization_quality_0_1000;
    int    replay_epoch_count;
};

struct SGovResilienceProfileV1 {
    SGovResilienceSummaryV1           summary;
    SGovResilienceCurveV1           curve;
    SGovGovernanceFatigueV1         fatigue;
    SGovCollapseResistanceV1        collapse;
    SGovRegimeBrittlenessV1         brittleness;
    SGovResilienceStressResponseV1 stress[];
};

struct SGovResilienceComparisonV1 {
    int d_governance_health;
    int d_containment_resilience;
    int d_survivability_resilience;
    int d_recovery_elasticity;
    int d_collapse_resistance;
    int d_quarantine_saturation;
    int d_intervention_density;
    int d_regime_brittleness;
    int d_degradation_velocity_milli;
    int d_resilience_half_life_epochs;
    int d_stabilization_quality;
};

void GovResilDsV1_InitWindow(SGovResilienceWindowV1 &w) {
    w.resilience_window_id = 0;
    w.start_epoch_ix = 0;
    w.end_epoch_ix = 0;
    w.replay_hash = "";
}

void GovResilDsV1_InitCurve(SGovResilienceCurveV1 &c) {
    c.survivability_decay_slope_milli = 0;
    c.toxicity_rise_slope_milli = 0;
    c.containment_pressure_slope_milli = 0;
    c.quarantine_saturation_peak = 0;
    c.plateau_epoch_segments = 0;
    c.stabilization_recovery_epochs = 0;
    c.collapse_acceleration_score_0_1000 = 0;
    c.recovery_curve_quality_0_1000 = 0;
    c.degradation_velocity_milli = 0;
    c.resilience_half_life_epochs = 0;
}

void GovResilDsV1_InitFatigue(SGovGovernanceFatigueV1 &f) {
    f.lockdown_density_per_1000 = 0;
    f.throttle_escalation_persistence_0_1000 = 0;
    f.flatten_accumulation_0_1000 = 0;
    f.quarantine_reuse_pressure_0_1000 = 0;
    f.execution_suppression_fatigue_per_1000 = 0;
    f.recovery_instability_0_1000 = 0;
    f.fatigue_composite_0_1000 = 0;
}

void GovResilDsV1_InitCollapse(SGovCollapseResistanceV1 &x) {
    x.collapse_resistance_score_0_1000 = 0;
    x.resilience_interruption_efficiency_0_1000 = 0;
    x.stabilization_interruption_latency_epochs = 0;
    x.containment_interruption_quality_0_1000 = 0;
}

void GovResilDsV1_InitBrittle(SGovRegimeBrittlenessV1 &b) {
    b.brittleness_score_0_1000 = 0;
    b.oscillation_index_0_1000 = 0;
    b.regime_half_life_epochs = 0;
    b.stabilization_persistence_0_1000 = 0;
}

void GovResilDsV1_InitStressResp(SGovResilienceStressResponseV1 &r) {
    r.archetype_id = 0;
    r.stress_lane_code = 0;
    r.lane_health_proxy_0_1000 = 0;
    r.lane_collapse_resistance_0_1000 = 0;
    r.lane_fatigue_load_0_1000 = 0;
}

void GovResilDsV1_InitSummary(SGovResilienceSummaryV1 &s) {
    s.resilience_window_id = 0;
    s.replay_hash = "";
    s.policy_fingerprint = "";
    s.governance_health_0_1000 = 0;
    s.containment_resilience_0_1000 = 0;
    s.survivability_resilience_0_1000 = 0;
    s.recovery_elasticity_0_1000 = 0;
    s.collapse_resistance_0_1000 = 0;
    s.quarantine_saturation_0_1000 = 0;
    s.intervention_density_0_1000 = 0;
    s.regime_brittleness_0_1000 = 0;
    s.degradation_velocity_milli = 0;
    s.resilience_half_life_epochs = 0;
    s.stabilization_quality_0_1000 = 0;
    s.replay_epoch_count = 0;
}

void GovResilDsV1_InitProfile(SGovResilienceProfileV1 &p) {
    GovResilDsV1_InitSummary(p.summary);
    GovResilDsV1_InitCurve(p.curve);
    GovResilDsV1_InitFatigue(p.fatigue);
    GovResilDsV1_InitCollapse(p.collapse);
    GovResilDsV1_InitBrittle(p.brittleness);
    ArrayResize(p.stress, 0);
}

void GovResilDsV1_InitCmp(SGovResilienceComparisonV1 &c) {
    c.d_governance_health = 0;
    c.d_containment_resilience = 0;
    c.d_survivability_resilience = 0;
    c.d_recovery_elasticity = 0;
    c.d_collapse_resistance = 0;
    c.d_quarantine_saturation = 0;
    c.d_intervention_density = 0;
    c.d_regime_brittleness = 0;
    c.d_degradation_velocity_milli = 0;
    c.d_resilience_half_life_epochs = 0;
    c.d_stabilization_quality = 0;
}

#endif // __AURUM_GOV_RESILIENCE_DS_V1_MQH__
