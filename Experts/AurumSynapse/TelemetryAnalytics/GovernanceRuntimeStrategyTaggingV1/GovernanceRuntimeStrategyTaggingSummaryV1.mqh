//+------------------------------------------------------------------+
//| GovernanceRuntimeStrategyTaggingSummaryV1.mqh                  |
//| Bridge → SGovStratAttribSummaryV1 (shared cold path)             |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_STRAT_TAG_SUMMARY_V1_MQH__
#define __AURUM_GOV_RUNTIME_STRAT_TAG_SUMMARY_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "GovernanceRuntimeAttributionBridgeV1.mqh"

inline void GovRunTagIntV1_BuildSummaryFromBridge(const SGovRunAttrBridgeStoreV1 &bridge,
                                                   SGovStratAttribSummaryV1 &sum)
{
   GovStrAttrDsV1_InitSummary(sum);
   const int kmax = MathMin(bridge.total, GOV_RTAG_BRIDGE_CAP_V1);
   for(int i = 0; i < kmax; i++) {
      const int idx = GovRunAttrBridgeV1_FlattenIndex(bridge, i);
      GovStratAttrV1_AccTrade(sum, bridge.tr[idx]);
   }
   GovStratAttrV1_Finalize(sum);
}

#endif // __AURUM_GOV_RUNTIME_STRAT_TAG_SUMMARY_V1_MQH__
