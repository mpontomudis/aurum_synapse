//+------------------------------------------------------------------+
//| GovernanceRuntimeStrategyTaggingModuleV1.mqh                    |
//| Shared module POD (registry + bridge + telemetry)                |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_STRAT_TAG_MODULE_V1_MQH__
#define __AURUM_GOV_RUNTIME_STRAT_TAG_MODULE_V1_MQH__

#include "GovernanceRuntimeTradeIdentityRegistryV1.mqh"
#include "GovernanceRuntimeAttributionBridgeV1.mqh"
#include "GovernanceRuntimeTaggingTelemetryV1.mqh"

struct SGovRuntimeTaggingModuleV1
{
   SGovRunTagRegistryStoreV1 reg;
   SGovRunAttrBridgeStoreV1  bridge;
   SGovRunTagTelemetryStoreV1 tel;
};

#endif // __AURUM_GOV_RUNTIME_STRAT_TAG_MODULE_V1_MQH__
