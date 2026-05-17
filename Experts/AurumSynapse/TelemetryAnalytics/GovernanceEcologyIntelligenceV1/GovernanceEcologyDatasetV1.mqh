//+------------------------------------------------------------------+
//| GovernanceEcologyDatasetV1.mqh                                 |
//| GOVERNANCE_ECOLOGY_INTELLIGENCE_V1 — datasets                    |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECO_DS_V1_MQH__
#define __AURUM_GOV_ECO_DS_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

struct SGovEcologyEntityV1 {
    int ecosystem_id;
    int entity_layer_code;
    int pressure_milli;
    int survivability_milli;
    int collapse_exposure_milli;
    int adaptation_pressure_milli;
    int recovery_coexistence_milli;
    int species_code;
    string replay_hash;
};

struct SGovEcologySpeciesV1 {
    int entity_id;
    int species_code;
    int classification_confidence_milli;
    int threshold_margin_milli;
};

struct SGovEcologyPressureV1 {
    int quarantine_pressure_milli;
    int execution_suppression_load_milli;
    int intervention_exhaustion_milli;
    int recovery_resource_scarcity_milli;
    int survivability_resource_strain_milli;
};

struct SGovEcologyCollapseV1 {
    int cascading_collapse_milli;
    int synchronized_failure_milli;
    int ecosystem_instability_milli;
    int biodiversity_collapse_milli;
    int resilience_extinction_milli;
    int collapse_contagion_milli;
};

struct SGovEcologyResilienceV1 {
    int ecosystem_resilience_milli;
    int ecosystem_recovery_speed_milli;
    int biodiversity_recovery_milli;
    int collapse_resistance_milli;
    int long_horizon_ecological_survivability_milli;
};

struct SGovEcologyCoexistenceV1 {
    int coexistence_stability_milli;
    int recovery_harmony_milli;
    int regime_compatibility_milli;
    int intervention_interference_milli;
    int temporal_sync_stability_milli;
};

struct SGovEcologyBiodiversityV1 {
    int diversity_score_milli;
    int regime_diversity_milli;
    int resilience_diversity_milli;
    int survivability_diversity_milli;
    int civilization_variation_milli;
    int ecosystem_concentration_risk_milli;
};

struct SGovEcologySummaryV1 {
    int ecology_window_id;
    string replay_hash;
    string policy_fingerprint;
    int entity_count;
    int ecological_stability_milli;
    int biodiversity_index_milli;
    int collapse_exposure_milli;
    int coexistence_quality_milli;
    int ecosystem_resilience_milli;
    int predation_pressure_milli;
};

struct SGovEcologyComparisonV1 {
    int d_ecological_stability_milli;
    int d_biodiversity_index_milli;
    int d_collapse_exposure_milli;
    int d_coexistence_quality_milli;
    int d_ecosystem_resilience_milli;
    int d_predation_pressure_milli;
};

void GovEcoDsV1_InitEntity(SGovEcologyEntityV1 &e) {
    e.ecosystem_id = 0;
    e.entity_layer_code = 0;
    e.pressure_milli = 0;
    e.survivability_milli = 0;
    e.collapse_exposure_milli = 0;
    e.adaptation_pressure_milli = 0;
    e.recovery_coexistence_milli = 0;
    e.species_code = (int)GOV_SPECIES_BALANCED;
    e.replay_hash = "";
}

void GovEcoDsV1_InitSpecies(SGovEcologySpeciesV1 &s) {
    s.entity_id = 0;
    s.species_code = (int)GOV_SPECIES_BALANCED;
    s.classification_confidence_milli = 0;
    s.threshold_margin_milli = 0;
}

void GovEcoDsV1_InitPress(SGovEcologyPressureV1 &p) {
    p.quarantine_pressure_milli = 0;
    p.execution_suppression_load_milli = 0;
    p.intervention_exhaustion_milli = 0;
    p.recovery_resource_scarcity_milli = 0;
    p.survivability_resource_strain_milli = 0;
}

void GovEcoDsV1_InitCollapse(SGovEcologyCollapseV1 &c) {
    c.cascading_collapse_milli = 0;
    c.synchronized_failure_milli = 0;
    c.ecosystem_instability_milli = 0;
    c.biodiversity_collapse_milli = 0;
    c.resilience_extinction_milli = 0;
    c.collapse_contagion_milli = 0;
}

void GovEcoDsV1_InitEcoRes(SGovEcologyResilienceV1 &r) {
    r.ecosystem_resilience_milli = 0;
    r.ecosystem_recovery_speed_milli = 0;
    r.biodiversity_recovery_milli = 0;
    r.collapse_resistance_milli = 0;
    r.long_horizon_ecological_survivability_milli = 0;
}

void GovEcoDsV1_InitCoexist(SGovEcologyCoexistenceV1 &c) {
    c.coexistence_stability_milli = 0;
    c.recovery_harmony_milli = 0;
    c.regime_compatibility_milli = 0;
    c.intervention_interference_milli = 0;
    c.temporal_sync_stability_milli = 0;
}

void GovEcoDsV1_InitBiodiv(SGovEcologyBiodiversityV1 &b) {
    b.diversity_score_milli = 0;
    b.regime_diversity_milli = 0;
    b.resilience_diversity_milli = 0;
    b.survivability_diversity_milli = 0;
    b.civilization_variation_milli = 0;
    b.ecosystem_concentration_risk_milli = 0;
}

void GovEcoDsV1_InitSummary(SGovEcologySummaryV1 &s) {
    s.ecology_window_id = 0;
    s.replay_hash = "";
    s.policy_fingerprint = "";
    s.entity_count = 0;
    s.ecological_stability_milli = 0;
    s.biodiversity_index_milli = 0;
    s.collapse_exposure_milli = 0;
    s.coexistence_quality_milli = 0;
    s.ecosystem_resilience_milli = 0;
    s.predation_pressure_milli = 0;
}

void GovEcoDsV1_InitCmp(SGovEcologyComparisonV1 &c) {
    c.d_ecological_stability_milli = 0;
    c.d_biodiversity_index_milli = 0;
    c.d_collapse_exposure_milli = 0;
    c.d_coexistence_quality_milli = 0;
    c.d_ecosystem_resilience_milli = 0;
    c.d_predation_pressure_milli = 0;
}

#endif // __AURUM_GOV_ECO_DS_V1_MQH__
