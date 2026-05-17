//+------------------------------------------------------------------+
//| GovernanceEcologySandboxV1.mqh                                    |
//| GOVERNANCE_ECOLOGY_INTELLIGENCE_V1 — replay-safe clone           |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECO_SB_V1_MQH__
#define __AURUM_GOV_ECO_SB_V1_MQH__

#include "../GovernanceTemporalIntelligenceV1/GovernanceTemporalSandboxV1.mqh"

void GovEcoSbV1_CloneForEcology(const SGovReplayTimelineV1 &src, SGovReplayTimelineV1 &dst) {
    GovTmpSbV1_CloneForTemporal(src, dst);
}

#endif // __AURUM_GOV_ECO_SB_V1_MQH__
