//+------------------------------------------------------------------+
//| GovernanceStrategicDependencyMapV1.mqh                         |
//| Static dependency registry (no runtime graph, no includes).      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRATEGIC_DEPMAP_V1_MQH__
#define __AURUM_GOV_STRATEGIC_DEPMAP_V1_MQH__

#define GOV_DEP_REPLAY_V1       1
#define GOV_DEP_RESILIENCE_V1   2
#define GOV_DEP_EVOLUTION_V1    3
#define GOV_DEP_STRATEGIC_V1    4
#define GOV_DEP_ATTRIBUTION_V1  5
#define GOV_DEP_TOXICITY_V1     6
#define GOV_DEP_ECOLOGY_V1      7
#define GOV_DEP_COMPAT_V1      8

inline bool GovDepMapV1_IsLegalChain(const int a, const int b)
{
   if(a == b)
      return false;
   if(a == GOV_DEP_ATTRIBUTION_V1 && b == GOV_DEP_REPLAY_V1)
      return false;
   return true;
}

#endif // __AURUM_GOV_STRATEGIC_DEPMAP_V1_MQH__
