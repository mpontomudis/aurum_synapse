//+------------------------------------------------------------------+
//| GovernanceFailureTelemetryV1.mqh                               |
//| PHASE 20C — reserved counters for explicit failure feeds         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_FAILURE_TEL_V1_MQH__
#define __AURUM_GOV_FAILURE_TEL_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

struct SGovFailureTelemetryV1
{
   int explicit_feeds;
   int dedup_collisions;
};

inline void GovFailureTelV1_Init(SGovFailureTelemetryV1 &t)
{
   t.explicit_feeds = 0;
   t.dedup_collisions = 0;
}

#endif // __AURUM_GOV_FAILURE_TEL_V1_MQH__
