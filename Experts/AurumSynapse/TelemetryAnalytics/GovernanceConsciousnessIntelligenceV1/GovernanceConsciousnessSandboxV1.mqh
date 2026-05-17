//+------------------------------------------------------------------+
//| GovernanceConsciousnessSandboxV1.mqh                            |
//| GOVERNANCE_CONSCIOUSNESS_INTELLIGENCE_V1 — replay-safe clone      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CON_SB_V1_MQH__
#define __AURUM_GOV_CON_SB_V1_MQH__

#include "../GovernanceEcologyIntelligenceV1/GovernanceEcologySandboxV1.mqh"

void GovConSbV1_CloneForConsciousness(const SGovReplayTimelineV1 &src, SGovReplayTimelineV1 &dst) {
    GovEcoSbV1_CloneForEcology(src, dst);
}

#endif // __AURUM_GOV_CON_SB_V1_MQH__
