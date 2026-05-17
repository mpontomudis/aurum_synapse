//+------------------------------------------------------------------+
//| GovernanceResearchDatasetV1.mqh                               |
//| GOVERNANCE_AUTONOMOUS_RESEARCH_V1 — observation structs         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RESEARCH_DATASET_V1_MQH__
#define __AURUM_GOV_RESEARCH_DATASET_V1_MQH__

#define GOV_RES_OBS_V1_TOX_RECUR     1
#define GOV_RES_OBS_V1_LOCK_CHURN    2
#define GOV_RES_OBS_V1_FRAG_PERSIST  3
#define GOV_RES_OBS_V1_CTN_DEGRADE   4
#define GOV_RES_OBS_V1_SURV_DECAY   5
#define GOV_RES_OBS_V1_QUAR_SAT      6
#define GOV_RES_OBS_V1_SURV_COLL_REP 7

struct SGovResearchWindowV1 {
    int   epoch_span;
    ulong epoch_lo;
    ulong epoch_hi;
};

struct SGovResearchObservationV1 {
    int    code;
    int    intensity_0_1000;
    string detail;
};

struct SGovResearchSummaryV1 {
    int    observation_window_epochs;
    int    incident_density_per_1000;
    int    containment_quality_0_1000;
    int    survivability_preservation_0_1000;
    int    quarantine_pressure_0_1000;
    int    regime_fragility_0_1000;
    int    recovery_stability_0_1000;
    int    throttle_pressure_0_1000;
    int    governance_health_index;
    string dominant_behavior_fingerprint;
    string policy_fingerprint;
    string replay_hash;
    SGovResearchObservationV1 obs[];
};

void GovResDsV1_InitWin(SGovResearchWindowV1 &w) {
    w.epoch_span = 0;
    w.epoch_lo = 0;
    w.epoch_hi = 0;
}

void GovResDsV1_InitObs(SGovResearchObservationV1 &o) {
    o.code = 0;
    o.intensity_0_1000 = 0;
    o.detail = "";
}

void GovResDsV1_InitSum(SGovResearchSummaryV1 &s) {
    s.observation_window_epochs = 0;
    s.incident_density_per_1000 = 0;
    s.containment_quality_0_1000 = 0;
    s.survivability_preservation_0_1000 = 0;
    s.quarantine_pressure_0_1000 = 0;
    s.regime_fragility_0_1000 = 0;
    s.recovery_stability_0_1000 = 0;
    s.throttle_pressure_0_1000 = 0;
    s.governance_health_index = 0;
    s.dominant_behavior_fingerprint = "";
    s.policy_fingerprint = "";
    s.replay_hash = "";
    ArrayResize(s.obs, 0);
}

#endif // __AURUM_GOV_RESEARCH_DATASET_V1_MQH__
