//+------------------------------------------------------------------+
//| GovernanceThrottleEngineV1.mqh                                 |
//| Deterministic execution pacing (integer ms; epoch-coupled).     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EXEC_THROTTLE_ENGINE_V1_MQH__
#define __AURUM_GOV_EXEC_THROTTLE_ENGINE_V1_MQH__

#include "../GovernanceStateMachineV1/GovernanceTypesV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "../GovernanceEvidenceIntegrationV1/GovernanceRegimeClassifierV1.mqh"
#include "../GovernanceEvidenceIntegrationV1/GovernanceEvidenceNormalizerV1.mqh"
#include "../GovernanceEvidenceIntegrationV1/GovernanceL0RuntimeEvidenceV1.mqh"
#include "../GovernanceEvidenceIntegrationV1/GovernanceCampaignMemoryV1.mqh"

int GovernanceThrottleEngineV1_ComputeIntervalMs(const uchar governance_state,
                                                 const ENUM_GOV_MARKET_REGIME_V1 mr,
                                                 const SGovL0RuntimeEvidenceV1 &rt,
                                                 const SGovernanceCampaignMemoryV1 &mem,
                                                 const int base_throttle_ms) {
    int b = GovClampInt32(base_throttle_ms, 0, 1000000);
    int mult = 1000;
    if(governance_state == (uchar)GOV_STATE_SURVIVAL || governance_state == (uchar)GOV_STATE_DEFENSIVE)
        mult = 1500;
    else if(governance_state == (uchar)GOV_STATE_CAUTION)
        mult = 1200;
    else if(governance_state == (uchar)GOV_STATE_LOCKDOWN)
        mult = 5000;
    int outv = (int)((long)b * (long)mult / 1000);
    if(mr == GOV_MR_V1_STRUCTURAL_BREAKDOWN)
        outv = GovClampInt32(outv + 5000, 0, 1000000);
    else if(mr == GOV_MR_V1_TOXIC || mr == GOV_MR_V1_FRAGILE)
        outv = GovClampInt32(outv + 2000, 0, 1000000);
    const int press = GovClampInt32((GOV_EVID_MILLI_MAX - rt.survivability_score_ms) / 1000, 0, 100);
    outv = GovClampInt32(outv + press * 10 + mem.structural_toxic_persistence * 5, 0, 1000000);
    return outv;
}

#endif // __AURUM_GOV_EXEC_THROTTLE_ENGINE_V1_MQH__
