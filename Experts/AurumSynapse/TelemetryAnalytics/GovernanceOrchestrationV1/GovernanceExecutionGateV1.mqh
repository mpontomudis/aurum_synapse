//+------------------------------------------------------------------+
//| GovernanceExecutionGateV1.mqh                                  |
//| Fail-closed execution gating (deterministic composition).        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EXEC_GATE_V1_MQH__
#define __AURUM_GOV_EXEC_GATE_V1_MQH__

#include "../GovernanceStateMachineV1/GovernanceTypesV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "GovernanceQuarantineEngineV1.mqh"
#include "GovernanceSurvivabilityProtectorV1.mqh"

void GovernanceExecutionGateV1_Apply(const SGovernanceDecisionOutputV1 &dec,
                                    const ENUM_GOV_EXEC_QUARANTINE_V1 q,
                                    const SGovSurvivabilityProtectOutputV1 &prot,
                                    uchar &out_entry_allowed,
                                    uchar &out_recovery_allowed,
                                    uchar &out_averaging_allowed,
                                    uchar &out_hedging_allowed,
                                    uchar &out_execution_allowed) {
    out_execution_allowed = dec.execution_allowed;
    out_entry_allowed = dec.execution_allowed;
    out_recovery_allowed = dec.recovery_allowed;
    out_averaging_allowed = dec.averaging_allowed;
    out_hedging_allowed = dec.averaging_allowed;

    if(q == GOV_EXEC_QUAR_V1_SOFT) {
        out_averaging_allowed = 0;
        out_hedging_allowed = 0;
    } else if(q == GOV_EXEC_QUAR_V1_HARD) {
        out_entry_allowed = 0;
        out_recovery_allowed = 0;
        out_averaging_allowed = 0;
        out_hedging_allowed = 0;
    } else if(q == GOV_EXEC_QUAR_V1_TERMINAL) {
        out_execution_allowed = 0;
        out_entry_allowed = 0;
        out_recovery_allowed = 0;
        out_averaging_allowed = 0;
        out_hedging_allowed = 0;
    }

    if(prot.survivability_emergency != 0 && q >= GOV_EXEC_QUAR_V1_HARD) {
        out_entry_allowed = 0;
        out_recovery_allowed = 0;
        out_averaging_allowed = 0;
        out_hedging_allowed = 0;
    }

    if(prot.forced_flatten_required != 0) {
        out_execution_allowed = 0;
        out_entry_allowed = 0;
        out_recovery_allowed = 0;
        out_averaging_allowed = 0;
        out_hedging_allowed = 0;
    }

    if(dec.execution_allowed == 0) {
        out_execution_allowed = 0;
        out_entry_allowed = 0;
    }
}

int GovernanceExecutionGateV1_EffectiveMaxDepth(const SGovernanceDecisionOutputV1 &dec,
                                               const ENUM_GOV_EXEC_QUARANTINE_V1 q,
                                               const SGovSurvivabilityProtectOutputV1 &prot) {
    int d = GovClampInt32(dec.max_campaign_depth, 0, 1000000);
    if(q == GOV_EXEC_QUAR_V1_SOFT)
        d = GovClampInt32(d - 1, 0, 1000000);
    if(q == GOV_EXEC_QUAR_V1_HARD)
        d = GovClampInt32(d - 2, 0, 1000000);
    if(q == GOV_EXEC_QUAR_V1_TERMINAL)
        d = 0;
    if(prot.survivability_emergency != 0)
        d = GovClampInt32(d - 1, 0, 1000000);
    return d;
}

#endif // __AURUM_GOV_EXEC_GATE_V1_MQH__
