//+------------------------------------------------------------------+
//| GovernanceMetaAnalyticsDatasetV1.mqh                            |
//| GOVERNANCE_META_ANALYTICS_V1 — canonical longitudinal metrics   |
//| Integer-first; rates scaled to per-1000-epochs where noted.      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_META_ANALYTICS_DATASET_V1_MQH__
#define __AURUM_GOV_META_ANALYTICS_DATASET_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

#define GOV_META_V1_FLAG_ARCH_AGGRESSIVE_CONTAIN   1
#define GOV_META_V1_FLAG_ARCH_SURVIVABILITY_FIRST  2
#define GOV_META_V1_FLAG_ARCH_QUARANTINE_HEAVY    4
#define GOV_META_V1_FLAG_ARCH_THROTTLE_HEAVY      8
#define GOV_META_V1_FLAG_ARCH_RECOVERY_CONSERV    16
#define GOV_META_V1_FLAG_ARCH_FLATTEN_AGGRESSIVE  32

struct SGovMetaIncidentStatsV1 {
    int raw_epoch_denominator;
    int raw_incident_total;
    int raw_toxic_spiral;
    int raw_survivability_collapse;
    int raw_false_recovery;
    int raw_quarantine_escalation;
    int raw_exec_suppression;
    int raw_regime_breakdown;
    int raw_forced_flatten_sum;
    int raw_quarantine_epoch_hits;
    int incident_frequency_per_1000_epochs;
    int toxic_spiral_frequency_per_1000_epochs;
    int survivability_collapse_frequency_per_1000_epochs;
    int quarantine_frequency_per_1000_epochs;
    int forced_flatten_frequency_per_1000_epochs;
    int regime_breakdown_density_per_1000_epochs;
    int containment_success_rate_0_1000;
    int survivability_preservation_score_0_1000;
    int average_lockdown_duration_epochs;
    int recovery_stabilization_score_0_1000;
    int governance_response_latency_avg_epochs;
    int internal_containment_eff_sum;
    int internal_containment_eff_n;
    int internal_surv_pres_sum;
    int internal_surv_pres_n;
    int internal_rec_stab_sum;
    int internal_rec_stab_n;
};

struct SGovMetaContainmentStatsV1 {
    int prevented_escalation_epochs;
    int prevented_escalation_ratio_per_1000;
    int containment_stabilization_ratio_per_1000;
    int survivability_preservation_delta_score_0_1000;
    int forced_flatten_effectiveness_0_1000;
    int quarantine_stabilization_efficiency_0_1000;
    int toxic_regime_interruption_ratio_per_1000;
    int governance_intervention_efficiency_per_1000;
    int throttle_aggressiveness_score_0_1000;
    int quarantine_aggressiveness_score_0_1000;
    int exposure_compression_sum_milli;
};

struct SGovMetaRegimeStatsV1 {
    int regime_persistence_max_epochs;
    int regime_churn_count;
    int structural_breakdown_frequency_per_1000_epochs;
    int fragile_regime_recurrence_count;
    int toxic_regime_half_life_epochs;
    int recovery_regime_stabilization_epochs;
    int recovery_stabilization_score_0_1000;
};

struct SGovMetaPolicyFingerprintV1 {
    int  archetype_flags;
    int  archetype_primary_code;
    string policy_behavior_fingerprint;
    string dominant_policy_fingerprint;
};

struct SGovMetaGovernanceHealthV1 {
    int governance_health_index_0_1000;
    int replay_stability_0_1000;
    int containment_quality_0_1000;
    int survivability_preservation_0_1000;
    int escalation_interruption_0_1000;
    int quarantine_effectiveness_0_1000;
    int recovery_stabilization_0_1000;
    int execution_containment_efficiency_0_1000;
};

void GovernanceMetaAnalyticsDatasetV1_InitIncidentStats(SGovMetaIncidentStatsV1 &m) {
    m.raw_epoch_denominator = 0;
    m.raw_incident_total = 0;
    m.raw_toxic_spiral = 0;
    m.raw_survivability_collapse = 0;
    m.raw_false_recovery = 0;
    m.raw_quarantine_escalation = 0;
    m.raw_exec_suppression = 0;
    m.raw_regime_breakdown = 0;
    m.raw_forced_flatten_sum = 0;
    m.raw_quarantine_epoch_hits = 0;
    m.incident_frequency_per_1000_epochs = 0;
    m.toxic_spiral_frequency_per_1000_epochs = 0;
    m.survivability_collapse_frequency_per_1000_epochs = 0;
    m.quarantine_frequency_per_1000_epochs = 0;
    m.forced_flatten_frequency_per_1000_epochs = 0;
    m.regime_breakdown_density_per_1000_epochs = 0;
    m.containment_success_rate_0_1000 = 0;
    m.survivability_preservation_score_0_1000 = 0;
    m.average_lockdown_duration_epochs = 0;
    m.recovery_stabilization_score_0_1000 = 0;
    m.governance_response_latency_avg_epochs = 0;
    m.internal_containment_eff_sum = 0;
    m.internal_containment_eff_n = 0;
    m.internal_surv_pres_sum = 0;
    m.internal_surv_pres_n = 0;
    m.internal_rec_stab_sum = 0;
    m.internal_rec_stab_n = 0;
}

void GovernanceMetaAnalyticsDatasetV1_InitContainmentStats(SGovMetaContainmentStatsV1 &m) {
    m.prevented_escalation_epochs = 0;
    m.prevented_escalation_ratio_per_1000 = 0;
    m.containment_stabilization_ratio_per_1000 = 0;
    m.survivability_preservation_delta_score_0_1000 = 0;
    m.forced_flatten_effectiveness_0_1000 = 0;
    m.quarantine_stabilization_efficiency_0_1000 = 0;
    m.toxic_regime_interruption_ratio_per_1000 = 0;
    m.governance_intervention_efficiency_per_1000 = 0;
    m.throttle_aggressiveness_score_0_1000 = 0;
    m.quarantine_aggressiveness_score_0_1000 = 0;
    m.exposure_compression_sum_milli = 0;
}

void GovernanceMetaAnalyticsDatasetV1_InitRegimeStats(SGovMetaRegimeStatsV1 &m) {
    m.regime_persistence_max_epochs = 0;
    m.regime_churn_count = 0;
    m.structural_breakdown_frequency_per_1000_epochs = 0;
    m.fragile_regime_recurrence_count = 0;
    m.toxic_regime_half_life_epochs = 0;
    m.recovery_regime_stabilization_epochs = 0;
    m.recovery_stabilization_score_0_1000 = 0;
}

void GovernanceMetaAnalyticsDatasetV1_InitFingerprint(SGovMetaPolicyFingerprintV1 &f) {
    f.archetype_flags = 0;
    f.archetype_primary_code = 0;
    f.policy_behavior_fingerprint = "";
    f.dominant_policy_fingerprint = "";
}

void GovernanceMetaAnalyticsDatasetV1_InitHealth(SGovMetaGovernanceHealthV1 &h) {
    h.governance_health_index_0_1000 = 0;
    h.replay_stability_0_1000 = 0;
    h.containment_quality_0_1000 = 0;
    h.survivability_preservation_0_1000 = 0;
    h.escalation_interruption_0_1000 = 0;
    h.quarantine_effectiveness_0_1000 = 0;
    h.recovery_stabilization_0_1000 = 0;
    h.execution_containment_efficiency_0_1000 = 0;
}

int GovernanceMetaAnalyticsDatasetV1_RatePer1000(const int numer, const int denom) {
    if(denom <= 0)
        return 0;
    const long x = (long)numer * (long)1000 / (long)denom;
    return GovSaturateLongToInt32(x);
}

#endif // __AURUM_GOV_META_ANALYTICS_DATASET_V1_MQH__
