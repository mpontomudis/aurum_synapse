//+------------------------------------------------------------------+
//| GovernanceTransitionHooksV1.mqh                                |
//| Edge-triggered governance memory (no polling ambiguity).        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EXEC_TRANSITION_HOOKS_V1_MQH__
#define __AURUM_GOV_EXEC_TRANSITION_HOOKS_V1_MQH__

#include "../GovernanceStateMachineV1/GovernanceTypesV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "../GovernanceEvidenceIntegrationV1/GovernanceRegimeClassifierV1.mqh"
#include "../GovernanceEvidenceIntegrationV1/GovernanceCampaignMemoryV1.mqh"
#include "GovernanceQuarantineEngineV1.mqh"

void GovernanceTransitionHooksV1_OnPostTick(SGovernanceCampaignMemoryV1 &mem,
                                           const uchar gs_before,
                                           const uchar gs_after,
                                           const ENUM_GOV_EXEC_QUARANTINE_V1 q_prev,
                                           const ENUM_GOV_EXEC_QUARANTINE_V1 q_after,
                                           const uchar surv_emergency_before,
                                           const uchar surv_emergency_after,
                                           const ENUM_GOV_MARKET_REGIME_V1 mr_after) {
    if(gs_after == (uchar)GOV_STATE_LOCKDOWN && gs_before != (uchar)GOV_STATE_LOCKDOWN)
        mem.lockdown_entry_count = GovSaturatingAdd32(mem.lockdown_entry_count, 1);

    if((int)q_after > (int)q_prev && q_after != GOV_EXEC_QUAR_V1_NONE)
        mem.quarantine_escalation_count = GovSaturatingAdd32(mem.quarantine_escalation_count, 1);

    if(surv_emergency_after != 0 && surv_emergency_before == 0)
        mem.survivability_emergency_escalation = GovSaturatingAdd32(mem.survivability_emergency_escalation, 1);

    const uchar mr_u = (uchar)mr_after;
    if(mr_after == GOV_MR_V1_TOXIC || mr_after == GOV_MR_V1_STRUCTURAL_BREAKDOWN) {
        if(mem.last_market_regime_wire == mr_u)
            mem.toxic_regime_persist_epochs = GovSaturatingAdd32(mem.toxic_regime_persist_epochs, 1);
        else
            mem.toxic_regime_persist_epochs = 1;
    } else {
        mem.toxic_regime_persist_epochs = 0;
    }
    mem.last_market_regime_wire = mr_u;
    mem.last_governance_state_wire = gs_after;
    mem.last_exec_quarantine_level = (uchar)q_after;
}

#endif // __AURUM_GOV_EXEC_TRANSITION_HOOKS_V1_MQH__
