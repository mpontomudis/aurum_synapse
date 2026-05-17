//+------------------------------------------------------------------+
//| GovernanceResilienceSandboxV1.mqh                              |
//| Resilience analysis only on replay/simulation clones.            |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RESIL_SB_V1_MQH__
#define __AURUM_GOV_RESIL_SB_V1_MQH__

#include "../GovernanceSimulationLabV1/GovernanceSandboxExecutionV1.mqh"

void GovResilSbV1_CloneForAnalysis(const SGovReplayTimelineV1 &src, SGovReplayTimelineV1 &dst) {
    GovSbExecV1_CloneTl(src, dst);
}

#endif // __AURUM_GOV_RESIL_SB_V1_MQH__
