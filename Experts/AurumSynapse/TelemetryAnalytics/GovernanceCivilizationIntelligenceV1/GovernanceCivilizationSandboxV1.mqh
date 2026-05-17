//+------------------------------------------------------------------+
//| GovernanceCivilizationSandboxV1.mqh                            |
//| Replay-safe clone for civilization-scale analysis.               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CIV_SB_V1_MQH__
#define __AURUM_GOV_CIV_SB_V1_MQH__

#include "../GovernanceStrategicIntelligenceV1/GovernanceStrategicSandboxV1.mqh"

void GovCivSbV1_CloneForCivilization(const SGovReplayTimelineV1 &src, SGovReplayTimelineV1 &dst) {
    GovStratSbV1_CloneForStrategy(src, dst);
}

#endif // __AURUM_GOV_CIV_SB_V1_MQH__
