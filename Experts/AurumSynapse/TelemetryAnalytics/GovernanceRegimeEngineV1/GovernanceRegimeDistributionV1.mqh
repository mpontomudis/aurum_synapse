//+------------------------------------------------------------------+
//| GovernanceRegimeDistributionV1.mqh                               |
//| PHASE 22 — regime share / dominance helpers (deterministic)      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REGIME_DISTRIBUTION_V1_MQH__
#define __AURUM_GOV_REGIME_DISTRIBUTION_V1_MQH__

#include "GovernanceRegimeDatasetV1.mqh"

inline int GovRegimeDistV1_Permille(const ulong part, const ulong total)
{
   if(total == 0)
      return 0;
   return (int)(1000UL * part / total);
}

#endif
