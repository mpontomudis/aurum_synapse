//+------------------------------------------------------------------+
//| GovernanceIncidentDatasetV1.mqh                               |
//| GOVERNANCE_INCIDENT_INTELLIGENCE_V1 — canonical incident rows |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_INCIDENT_DATASET_V1_MQH__
#define __AURUM_GOV_INCIDENT_DATASET_V1_MQH__

#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"

#define GOV_INCIDENT_V1_UNSET (-1)

enum ENUM_GOV_INCIDENT_TYPE_V1 {
    GOV_INCIDENT_V1_NONE = 0,
    GOV_INCIDENT_V1_TOX_SPIRAL = 1,
    GOV_INCIDENT_V1_SURV_COLLAPSE = 2,
    GOV_INCIDENT_V1_FALSE_RECOVERY = 3,
    GOV_INCIDENT_V1_QUAR_ESCALATION = 4,
    GOV_INCIDENT_V1_EXEC_SUPPRESSION = 5,
    GOV_INCIDENT_V1_REGIME_BREAKDOWN = 6
};

struct SGovIncidentEventV1 {
    int   incident_id;
    int   incident_type;
    ulong start_epoch;
    ulong peak_epoch;
    ulong recovery_epoch;
    int   dominant_governance_state;
    int   dominant_regime;
    int   dominant_causal_factor;
    int   toxicity_peak_ms;
    int   survivability_floor_ms;
    int   quarantine_peak;
    int   forced_flatten_count;
    int   execution_suppression_count;
    int   containment_effectiveness_score_0_1000;
    string replay_hash;
    ulong campaign_uuid;
};

struct SGovIncidentChainV1 {
    int               incident_id;
    int               incident_type;
    ulong             epoch_ids[];
    string            ladder_notes;
};

struct SGovIncidentSummaryV1 {
    SGovIncidentEventV1 events[];
    string source_replay_sha256_hex;
};

void GovernanceIncidentDatasetV1_InitEvent(SGovIncidentEventV1 &e) {
    e.incident_id = GOV_INCIDENT_V1_UNSET;
    e.incident_type = (int)GOV_INCIDENT_V1_NONE;
    e.start_epoch = 0;
    e.peak_epoch = 0;
    e.recovery_epoch = 0;
    e.dominant_governance_state = GOV_REPLAY_V1_UNSET_INT;
    e.dominant_regime = GOV_REPLAY_V1_UNSET_INT;
    e.dominant_causal_factor = GOV_REPLAY_V1_UNSET_INT;
    e.toxicity_peak_ms = GOV_REPLAY_V1_UNSET_INT;
    e.survivability_floor_ms = GOV_REPLAY_V1_UNSET_INT;
    e.quarantine_peak = GOV_INCIDENT_V1_UNSET;
    e.forced_flatten_count = 0;
    e.execution_suppression_count = 0;
    e.containment_effectiveness_score_0_1000 = 0;
    e.replay_hash = "";
    e.campaign_uuid = 0;
}

void GovernanceIncidentDatasetV1_InitSummary(SGovIncidentSummaryV1 &s) {
    ArrayResize(s.events, 0);
    s.source_replay_sha256_hex = "";
}

#endif // __AURUM_GOV_INCIDENT_DATASET_V1_MQH__
