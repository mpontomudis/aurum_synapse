//+------------------------------------------------------------------+
//| GovernanceTemporalSandboxV1.mqh                               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_TMP_SB_V1_MQH__
#define __AURUM_GOV_TMP_SB_V1_MQH__

#include "../GovernanceCivilizationIntelligenceV1/GovernanceCivilizationSandboxV1.mqh"

void GovTmpSbV1_CloneForTemporal(const SGovReplayTimelineV1 &src, SGovReplayTimelineV1 &dst) {
    GovCivSbV1_CloneForCivilization(src, dst);
}

#endif // __AURUM_GOV_TMP_SB_V1_MQH__
