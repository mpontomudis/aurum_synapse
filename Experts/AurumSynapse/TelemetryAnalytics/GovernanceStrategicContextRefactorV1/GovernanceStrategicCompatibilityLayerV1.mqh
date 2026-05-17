//+------------------------------------------------------------------+
//| GovernanceStrategicCompatibilityLayerV1.mqh                      |
//| Migration notes + thin adapters (no heavy upstream includes).    |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRATEGIC_COMPAT_V1_MQH__
#define __AURUM_GOV_STRATEGIC_COMPAT_V1_MQH__

#include "GovernanceStrategicContextRouterV1.mqh"

// Strategic intelligence live pipeline renamed to avoid symbol clash
// with strategy ATTRIBUTION live helpers:
//   GovStrategicAggV1_BuildSummary(...)
//   GovStrategicLiveV1_Run(...)
// Legacy call sites should be updated; router helpers remain stable.

#endif // __AURUM_GOV_STRATEGIC_COMPAT_V1_MQH__
