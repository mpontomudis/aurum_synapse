//+------------------------------------------------------------------+
//| GovernanceEvolutionSandboxV1.mqh                             |
//| Evolution analysis only on replay / simulation clones.         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EVO_SB_V1_MQH__
#define __AURUM_GOV_EVO_SB_V1_MQH__

#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceSandboxV1.mqh"

void GovEvoSbV1_CloneForEvolution(const SGovReplayTimelineV1 &src, SGovReplayTimelineV1 &dst) {
    GovResilSbV1_CloneForAnalysis(src, dst);
}

#endif // __AURUM_GOV_EVO_SB_V1_MQH__
