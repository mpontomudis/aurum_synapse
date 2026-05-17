//+------------------------------------------------------------------+
//| GovernanceStrategicSandboxV1.mqh                             |
//| Strategic analysis only on sandbox timelines.                   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRAT_SB_V1_MQH__
#define __AURUM_GOV_STRAT_SB_V1_MQH__

#include "../GovernanceEvolutionIntelligenceV1/GovernanceEvolutionSandboxV1.mqh"

void GovStratSbV1_CloneForStrategy(const SGovReplayTimelineV1 &src, SGovReplayTimelineV1 &dst) {
    GovEvoSbV1_CloneForEvolution(src, dst);
}

#endif // __AURUM_GOV_STRAT_SB_V1_MQH__
