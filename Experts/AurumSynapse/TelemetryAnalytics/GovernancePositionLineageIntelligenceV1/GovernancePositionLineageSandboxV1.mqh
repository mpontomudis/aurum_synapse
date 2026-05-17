//+------------------------------------------------------------------+
//| GovernancePositionLineageSandboxV1.mqh                           |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_LINEAGE_SBX_V1_MQH__
#define __AURUM_GOV_LINEAGE_SBX_V1_MQH__

#include "GovernancePositionLineageRegistryV1.mqh"

inline void GovLineageSbxV1_Clone(const SGovLineageRegistryStoreV1 &src, SGovLineageRegistryStoreV1 &dst)
{
   dst = src;
}

inline bool GovLineageSbxV1_Replay(SGovLineageRegistryStoreV1 &dst, const SGovLineageRegistryStoreV1 &frozen)
{
   dst = frozen;
   return true;
}

inline void GovLineageSbxV1_Isolate(SGovLineageRegistryStoreV1 &box)
{
   GovLineageV1_Reset(box);
}

#endif // __AURUM_GOV_LINEAGE_SBX_V1_MQH__
