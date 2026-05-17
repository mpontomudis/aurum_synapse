//+------------------------------------------------------------------+
//| GovernanceStrategicDatasetV1.mqh                             |
//| GOVERNANCE_STRATEGIC_INTELLIGENCE_V1 — canonical datasets      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRAT_DS_V1_MQH__
#define __AURUM_GOV_STRAT_DS_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

struct SGovStrategicWindowV1 {
    int    strategic_window_id;
    int    epoch_lo_ix;
    int    epoch_hi_ix;
    string replay_hash;
};

struct SGovStrategicContainmentV1 {
    int long_cycle_stability_0_1000;
    int escalation_interruption_eff_0_1000;
    int containment_pacing_quality_0_1000;
    int strategic_lockdown_efficiency_0_1000;
    int catastrophic_interrupt_quality_0_1000;
    int containment_sustain_horizon_0_1000;
};

struct SGovStrategicEnduranceV1 {
    int survivability_persistence_0_1000;
    int recovery_endurance_0_1000;
    int containment_sustainability_0_1000;
    int fatigue_endurance_0_1000;
    int intervention_longevity_0_1000;
    int catastrophic_resistance_endurance_0_1000;
    int degradation_persistence_0_1000;
    int endurance_composite_0_1000;
};

struct SGovStrategicTrajectoryV1 {
    int sustainability_slope_milli;
    int degradation_stabilization_0_1000;
    int survivability_persistence_traj_0_1000;
    int fatigue_stabilization_0_1000;
    int recovery_sustainability_traj_0_1000;
    int regime_endurance_balance_0_1000;
    int collapse_trajectory_risk_0_1000;
};

struct SGovStrategicBudgetV1 {
    int quarantine_expenditure_density_0_1000;
    int flatten_expenditure_accum_0_1000;
    int throttle_escalation_cost_0_1000;
    int execution_suppression_cost_0_1000;
    int recovery_pacing_cost_0_1000;
    int containment_resource_persistence_0_1000;
    int budget_pressure_composite_0_1000;
};

struct SGovCatastrophicResistanceV1 {
    int catastrophic_resistance_score_0_1000;
    int collapse_interruption_capacity_0_1000;
    int strategic_survival_capacity_0_1000;
    int systemic_recovery_capacity_0_1000;
};

struct SGovStrategicSummaryV1 {
    int    strategic_window_id;
    string replay_hash;
    string policy_fingerprint;
    int    lineage_id;
    int    governance_health_0_1000;
    int    survivability_horizon_0_1000;
    int    endurance_capacity_0_1000;
    int    intervention_budget_score_0_1000;
    int    strategic_containment_quality_0_1000;
    int    sustainability_index_0_1000;
    int    catastrophic_resistance_0_1000;
    int    degradation_stability_0_1000;
    int    regime_endurance_balance_0_1000;
    int    collapse_avoidance_score_0_1000;
    int    recovery_sustainability_0_1000;
    int    fatigue_sustainability_0_1000;
    int    strategic_epoch_count;
};

struct SGovStrategicComparisonV1 {
    int d_sustainability_index_0_1000;
    int d_endurance_capacity_0_1000;
    int d_intervention_budget_score_0_1000;
    int d_catastrophic_resistance_0_1000;
    int d_collapse_avoidance_score_0_1000;
    int d_survivability_horizon_0_1000;
};

void GovStratDsV1_InitWindow(SGovStrategicWindowV1 &w) {
    w.strategic_window_id = 0;
    w.epoch_lo_ix = 0;
    w.epoch_hi_ix = 0;
    w.replay_hash = "";
}

void GovStratDsV1_InitCtn(SGovStrategicContainmentV1 &c) {
    c.long_cycle_stability_0_1000 = 0;
    c.escalation_interruption_eff_0_1000 = 0;
    c.containment_pacing_quality_0_1000 = 0;
    c.strategic_lockdown_efficiency_0_1000 = 0;
    c.catastrophic_interrupt_quality_0_1000 = 0;
    c.containment_sustain_horizon_0_1000 = 0;
}

void GovStratDsV1_InitEnd(SGovStrategicEnduranceV1 &e) {
    e.survivability_persistence_0_1000 = 0;
    e.recovery_endurance_0_1000 = 0;
    e.containment_sustainability_0_1000 = 0;
    e.fatigue_endurance_0_1000 = 0;
    e.intervention_longevity_0_1000 = 0;
    e.catastrophic_resistance_endurance_0_1000 = 0;
    e.degradation_persistence_0_1000 = 0;
    e.endurance_composite_0_1000 = 0;
}

void GovStratDsV1_InitTraj(SGovStrategicTrajectoryV1 &t) {
    t.sustainability_slope_milli = 0;
    t.degradation_stabilization_0_1000 = 0;
    t.survivability_persistence_traj_0_1000 = 0;
    t.fatigue_stabilization_0_1000 = 0;
    t.recovery_sustainability_traj_0_1000 = 0;
    t.regime_endurance_balance_0_1000 = 0;
    t.collapse_trajectory_risk_0_1000 = 0;
}

void GovStratDsV1_InitBud(SGovStrategicBudgetV1 &b) {
    b.quarantine_expenditure_density_0_1000 = 0;
    b.flatten_expenditure_accum_0_1000 = 0;
    b.throttle_escalation_cost_0_1000 = 0;
    b.execution_suppression_cost_0_1000 = 0;
    b.recovery_pacing_cost_0_1000 = 0;
    b.containment_resource_persistence_0_1000 = 0;
    b.budget_pressure_composite_0_1000 = 0;
}

void GovStratDsV1_InitCat(SGovCatastrophicResistanceV1 &c) {
    c.catastrophic_resistance_score_0_1000 = 0;
    c.collapse_interruption_capacity_0_1000 = 0;
    c.strategic_survival_capacity_0_1000 = 0;
    c.systemic_recovery_capacity_0_1000 = 0;
}

void GovStratDsV1_InitSummary(SGovStrategicSummaryV1 &s) {
    s.strategic_window_id = 0;
    s.replay_hash = "";
    s.policy_fingerprint = "";
    s.lineage_id = 0;
    s.governance_health_0_1000 = 0;
    s.survivability_horizon_0_1000 = 0;
    s.endurance_capacity_0_1000 = 0;
    s.intervention_budget_score_0_1000 = 0;
    s.strategic_containment_quality_0_1000 = 0;
    s.sustainability_index_0_1000 = 0;
    s.catastrophic_resistance_0_1000 = 0;
    s.degradation_stability_0_1000 = 0;
    s.regime_endurance_balance_0_1000 = 0;
    s.collapse_avoidance_score_0_1000 = 0;
    s.recovery_sustainability_0_1000 = 0;
    s.fatigue_sustainability_0_1000 = 0;
    s.strategic_epoch_count = 0;
}

void GovStratDsV1_InitCmp(SGovStrategicComparisonV1 &c) {
    c.d_sustainability_index_0_1000 = 0;
    c.d_endurance_capacity_0_1000 = 0;
    c.d_intervention_budget_score_0_1000 = 0;
    c.d_catastrophic_resistance_0_1000 = 0;
    c.d_collapse_avoidance_score_0_1000 = 0;
    c.d_survivability_horizon_0_1000 = 0;
}

#endif // __AURUM_GOV_STRAT_DS_V1_MQH__
