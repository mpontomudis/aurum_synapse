//+------------------------------------------------------------------+
//| GovernanceQuarantineEngineV1.mqh                               |
//| Execution-layer quarantine (deterministic, explainable).         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EXEC_QUARANTINE_ENGINE_V1_MQH__
#define __AURUM_GOV_EXEC_QUARANTINE_ENGINE_V1_MQH__

#include "../GovernanceStateMachineV1/GovernanceTypesV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "../GovernanceEvidenceIntegrationV1/GovernanceRegimeClassifierV1.mqh"
#include "../GovernanceEvidenceIntegrationV1/GovernanceL0RuntimeEvidenceV1.mqh"
#include "../GovernanceEvidenceIntegrationV1/GovernanceCampaignMemoryV1.mqh"
#include "../ToxicityAnalyticsV1.mqh"
#include "../SurvivabilityAnalyticsV1.mqh"

enum ENUM_GOV_EXEC_QUARANTINE_V1 {
    GOV_EXEC_QUAR_V1_NONE = 0,
    GOV_EXEC_QUAR_V1_SOFT = 1,
    GOV_EXEC_QUAR_V1_HARD = 2,
    GOV_EXEC_QUAR_V1_TERMINAL = 3
};

ENUM_GOV_EXEC_QUARANTINE_V1 GovernanceQuarantineEngineV1_Classify(const uchar governance_state,
                                                                   const ENUM_GOV_MARKET_REGIME_V1 mr,
                                                                   const ENUM_TOXICITY_STATE_V1 tx,
                                                                   const ENUM_SURVIVABILITY_STATE_V1 sv,
                                                                   const SGovernanceCampaignMemoryV1 &mem) {
    if(governance_state == (uchar)GOV_STATE_LOCKDOWN)
        return GOV_EXEC_QUAR_V1_TERMINAL;
    if(mem.toxic_regime_persist_epochs >= 4)
        return GOV_EXEC_QUAR_V1_HARD;
    if(sv == SURVIVE_V1_TERMINATED || tx == TOX_V1_TERMINAL)
        return GOV_EXEC_QUAR_V1_TERMINAL;
    if(mr == GOV_MR_V1_STRUCTURAL_BREAKDOWN || tx == TOX_V1_COLLAPSING)
        return GOV_EXEC_QUAR_V1_HARD;
    if(mem.recovery_failure_streak >= 5 || mem.structural_toxic_persistence >= 8)
        return GOV_EXEC_QUAR_V1_HARD;
    if(mr == GOV_MR_V1_TOXIC || tx == TOX_V1_TOXIC || tx == TOX_V1_UNSTABLE)
        return GOV_EXEC_QUAR_V1_SOFT;
    if(mem.consecutive_toxic_campaigns >= 3 || mem.recovery_failure_streak >= 2)
        return GOV_EXEC_QUAR_V1_SOFT;
    if(sv == SURVIVE_V1_CRITICAL && mr != GOV_MR_V1_RECOVERY_WINDOW)
        return GOV_EXEC_QUAR_V1_SOFT;
    return GOV_EXEC_QUAR_V1_NONE;
}

#endif // __AURUM_GOV_EXEC_QUARANTINE_ENGINE_V1_MQH__
