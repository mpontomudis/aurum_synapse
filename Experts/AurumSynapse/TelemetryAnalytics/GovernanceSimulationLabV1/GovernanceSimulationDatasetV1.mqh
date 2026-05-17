//+------------------------------------------------------------------+
//| GovernanceSimulationDatasetV1.mqh                              |
//| GOVERNANCE_SIMULATION_LAB_V1 — scenario & metrics (integer).    |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SIM_DATASET_V1_MQH__
#define __AURUM_GOV_SIM_DATASET_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

#define GOV_STRS_V1_NONE               0
#define GOV_STRS_V1_CHRONIC_TOX        1
#define GOV_STRS_V1_SURV_COLLAPSE      2
#define GOV_STRS_V1_LOCKDOWN_CHURN     3
#define GOV_STRS_V1_FRAGILE_PERSIST    4
#define GOV_STRS_V1_QUAR_ESCAL         5
#define GOV_STRS_V1_EXEC_SUPP          6
#define GOV_STRS_V1_STRUCT_BREAK       7
#define GOV_STRS_V1_FLAT_BURST         8

#define GOV_ARCH_V1_SURV_FIRST         1
#define GOV_ARCH_V1_AGGR_CONT          2
#define GOV_ARCH_V1_QUAR_HEAVY         3
#define GOV_ARCH_V1_THR_HEAVY          4
#define GOV_ARCH_V1_REC_CONSERV        5
#define GOV_ARCH_V1_FLAT_AGGR          6
#define GOV_ARCH_V1_BALANCED           7

struct SGovSimStabilityMetricsV1 {
    int replay_stability_0_1000;
    int governance_consistency_0_1000;
    int containment_resilience_0_1000;
    int survivability_robustness_0_1000;
    int quarantine_oscillation_0_1000;
    int regime_churn_stability_0_1000;
    int flatten_containment_efficiency_0_1000;
    int intervention_coherence_0_1000;
};

struct SGovSimStressProfileV1 {
    int stress_code;
    int intensity_0_1000;
};

struct SGovSimScenarioV1 {
    int    scenario_id;
    string replay_source_hash;
    string policy_fingerprint;
    int    regime_profile_code;
    int    toxic_pressure_profile_code;
    int    survivability_profile_code;
    int    quarantine_pressure_profile_code;
    int    execution_suppression_profile_code;
    int    stress_intensity_0_1000;
    int    scenario_epoch_count;
    ulong  deterministic_seed;
    string replay_window_hash;
};

struct SGovSimPolicyRunV1 {
    int                     archetype_id;
    int                     stress_lane_code;
    int                     governance_health_proxy_0_1000;
    int                     incident_count;
    int                     epoch_count;
    SGovSimStabilityMetricsV1 stability;
    string                  lane_note;
};

struct SGovSimComparisonV1 {
    int d_governance_health_proxy;
    int d_incident_count;
    int d_stability_sum;
    int d_survivability_robustness;
};

void GovSimDsV1_InitStab(SGovSimStabilityMetricsV1 &m) {
    m.replay_stability_0_1000 = 0;
    m.governance_consistency_0_1000 = 0;
    m.containment_resilience_0_1000 = 0;
    m.survivability_robustness_0_1000 = 0;
    m.quarantine_oscillation_0_1000 = 0;
    m.regime_churn_stability_0_1000 = 0;
    m.flatten_containment_efficiency_0_1000 = 0;
    m.intervention_coherence_0_1000 = 0;
}

void GovSimDsV1_InitRun(SGovSimPolicyRunV1 &r) {
    r.archetype_id = 0;
    r.stress_lane_code = 0;
    r.governance_health_proxy_0_1000 = 0;
    r.incident_count = 0;
    r.epoch_count = 0;
    GovSimDsV1_InitStab(r.stability);
    r.lane_note = "";
}

void GovSimDsV1_InitCmp(SGovSimComparisonV1 &c) {
    c.d_governance_health_proxy = 0;
    c.d_incident_count = 0;
    c.d_stability_sum = 0;
    c.d_survivability_robustness = 0;
}

void GovSimDsV1_InitScen(SGovSimScenarioV1 &s) {
    s.scenario_id = 0;
    s.replay_source_hash = "";
    s.policy_fingerprint = "";
    s.regime_profile_code = 0;
    s.toxic_pressure_profile_code = 0;
    s.survivability_profile_code = 0;
    s.quarantine_pressure_profile_code = 0;
    s.execution_suppression_profile_code = 0;
    s.stress_intensity_0_1000 = 0;
    s.scenario_epoch_count = 0;
    s.deterministic_seed = 0;
    s.replay_window_hash = "";
}

void GovSimDsV1_InitStressProf(SGovSimStressProfileV1 &p) {
    p.stress_code = 0;
    p.intensity_0_1000 = 0;
}

int GovSimDsV1_StabSum(const SGovSimStabilityMetricsV1 &m) {
    int s = 0;
    s = GovSaturatingAdd32(s, m.replay_stability_0_1000);
    s = GovSaturatingAdd32(s, m.governance_consistency_0_1000);
    s = GovSaturatingAdd32(s, m.containment_resilience_0_1000);
    s = GovSaturatingAdd32(s, m.survivability_robustness_0_1000);
    s = GovSaturatingAdd32(s, m.quarantine_oscillation_0_1000);
    s = GovSaturatingAdd32(s, m.regime_churn_stability_0_1000);
    s = GovSaturatingAdd32(s, m.flatten_containment_efficiency_0_1000);
    s = GovSaturatingAdd32(s, m.intervention_coherence_0_1000);
    return GovClampInt32(s, 0, 1000000);
}

#endif // __AURUM_GOV_SIM_DATASET_V1_MQH__
