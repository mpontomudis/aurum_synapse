//+------------------------------------------------------------------+
//| GovernanceL0RuntimeEvidenceV1.mqh                               |
//| GOVERNANCE_EVIDENCE_INTEGRATION_V1 — canonical L0 evidence      |
//| Integer milli authority (0..10000) + deterministic counters.   |
//| Immutable after publish: single-writer = fusion pipeline only.  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_L0_RUNTIME_EVIDENCE_V1_MQH__
#define __AURUM_GOV_L0_RUNTIME_EVIDENCE_V1_MQH__

struct SGovL0RuntimeEvidenceV1 {
    ulong  lifecycle_id;
    string campaign_uuid;
    int    toxicity_score_ms;
    int    survivability_score_ms;
    int    execution_quality_ms;
    int    recovery_instability_ms;
    int    causal_pressure_ms;
    int    volatility_toxicity_ms;
    int    structural_instability_ms;
    int    drawdown_pressure_ms;
    int    consecutive_toxic_campaigns;
    int    active_recovery_depth;
    int    campaign_duration_epochs;
    int    governance_confidence_ms;
    ulong  evidence_timestamp_epoch;
};

void GovernanceL0RuntimeEvidenceV1_Init(SGovL0RuntimeEvidenceV1 &z) {
    z.lifecycle_id = 0;
    z.campaign_uuid = "";
    z.toxicity_score_ms = 0;
    z.survivability_score_ms = 0;
    z.execution_quality_ms = 0;
    z.recovery_instability_ms = 0;
    z.causal_pressure_ms = 0;
    z.volatility_toxicity_ms = 0;
    z.structural_instability_ms = 0;
    z.drawdown_pressure_ms = 0;
    z.consecutive_toxic_campaigns = 0;
    z.active_recovery_depth = 0;
    z.campaign_duration_epochs = 0;
    z.governance_confidence_ms = 0;
    z.evidence_timestamp_epoch = 0;
}

#endif // __AURUM_GOV_L0_RUNTIME_EVIDENCE_V1_MQH__
