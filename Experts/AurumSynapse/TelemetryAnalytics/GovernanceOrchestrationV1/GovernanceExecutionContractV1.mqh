//+------------------------------------------------------------------+
//| GovernanceExecutionContractV1.mqh                              |
//| LIVE_GOVERNANCE_ORCHESTRATION_V1 — immutable execution contract |
//| Integer-only authority; replay-reconstructable snapshot.         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EXEC_CONTRACT_V1_MQH__
#define __AURUM_GOV_EXEC_CONTRACT_V1_MQH__

#include "../GovernanceStateMachineV1/GovernanceTypesV1.mqh"

struct SGovernanceExecutionContractV1 {
    uchar governance_state;
    uchar regime_state;
    uchar execution_allowed;
    uchar entry_allowed;
    uchar recovery_allowed;
    uchar averaging_allowed;
    uchar hedging_allowed;
    uchar forced_flatten_required;
    int   risk_multiplier_milli;
    int   exposure_cap_milli;
    int   max_campaign_depth;
    int   throttle_interval_ms;
    int   cooldown_epochs;
    uchar quarantine_active;
    uchar survivability_emergency;
    int   causal_reason_code;
    string policy_fingerprint;
    string evidence_fingerprint;
    ulong contract_epoch;
};

void GovernanceExecutionContractV1_InitFailClosed(SGovernanceExecutionContractV1 &c) {
    c.governance_state = (uchar)GOV_STATE_INVALID;
    c.regime_state = 0;
    c.execution_allowed = 0;
    c.entry_allowed = 0;
    c.recovery_allowed = 0;
    c.averaging_allowed = 0;
    c.hedging_allowed = 0;
    c.forced_flatten_required = 0;
    c.risk_multiplier_milli = 0;
    c.exposure_cap_milli = 0;
    c.max_campaign_depth = 0;
    c.throttle_interval_ms = 0;
    c.cooldown_epochs = 0;
    c.quarantine_active = 0;
    c.survivability_emergency = 0;
    c.causal_reason_code = 0;
    c.policy_fingerprint = "";
    c.evidence_fingerprint = "";
    c.contract_epoch = 0;
}

#endif // __AURUM_GOV_EXEC_CONTRACT_V1_MQH__
