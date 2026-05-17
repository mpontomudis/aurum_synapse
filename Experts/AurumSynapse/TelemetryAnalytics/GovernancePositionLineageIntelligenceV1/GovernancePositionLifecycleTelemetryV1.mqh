//+------------------------------------------------------------------+
//| GovernancePositionLifecycleTelemetryV1.mqh                      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_POS_LINEAGE_TEL_V1_MQH__
#define __AURUM_GOV_POS_LINEAGE_TEL_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

struct SGovLineageTelemetryV1
{
   int total_roots;
   int total_children;
   int scale_ins;
   int scale_outs;
   int hedges;
   int recoveries;
   int orphan_lineage;
   int invalid_parent_links;
   int replay_mismatches;
   int overflow_events;
};

inline void GovLineageTelV1_Init(SGovLineageTelemetryV1 &t)
{
   t.total_roots = 0;
   t.total_children = 0;
   t.scale_ins = 0;
   t.scale_outs = 0;
   t.hedges = 0;
   t.recoveries = 0;
   t.orphan_lineage = 0;
   t.invalid_parent_links = 0;
   t.replay_mismatches = 0;
   t.overflow_events = 0;
}

#endif // __AURUM_GOV_POS_LINEAGE_TEL_V1_MQH__
