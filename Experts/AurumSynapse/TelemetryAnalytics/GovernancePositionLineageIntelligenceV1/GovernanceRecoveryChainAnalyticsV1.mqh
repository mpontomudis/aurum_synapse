//+------------------------------------------------------------------+
//| GovernanceRecoveryChainAnalyticsV1.mqh                           |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RECOVERY_CHAIN_V1_MQH__
#define __AURUM_GOV_RECOVERY_CHAIN_V1_MQH__

#include "GovernancePositionLineageRegistryV1.mqh"

struct SGovRecoveryStoreV1
{
   SGovRecoveryChainV1 chains[GOV_LINEAGE_MAX_RECOVERY_V1];
   int                 widx;
   int                 count;
};

inline void GovRecoveryStoreV1_Init(SGovRecoveryStoreV1 &s)
{
   s.widx = 0;
   s.count = 0;
   for(int i = 0; i < GOV_LINEAGE_MAX_RECOVERY_V1; i++) {
      s.chains[i].root_lineage_id = 0;
      s.chains[i].last_lineage_id = 0;
      s.chains[i].generation_depth = 0;
      s.chains[i].toxic_score_0_1000 = 0;
      s.chains[i].exposure_ratio_micro = 0;
   }
}

inline void GovRecoveryV1_Register(SGovRecoveryStoreV1 &s, const uint root_lineage_id, const uint last_lineage_id, const int depth)
{
   SGovRecoveryChainV1 c;
   c.root_lineage_id = root_lineage_id;
   c.last_lineage_id = last_lineage_id;
   c.generation_depth = GovClampInt32(depth, 0, 1000000);
   c.toxic_score_0_1000 = 0;
   c.exposure_ratio_micro = 0;
   s.chains[s.widx] = c;
   s.widx = (s.widx + 1) % GOV_LINEAGE_MAX_RECOVERY_V1;
   s.count = GovSaturatingAdd32(s.count, 1);
}

inline void GovRecoveryV1_Analyze(SGovRecoveryStoreV1 &s, SGovLineageRegistryStoreV1 &st)
{
   for(int i = 0; i < GOV_LINEAGE_MAX_RECOVERY_V1; i++) {
      if(s.chains[i].root_lineage_id == 0)
         continue;
      const int ix = GovLineageV1_FindByLineage(st, s.chains[i].last_lineage_id);
      if(ix < 0)
         st.tel.replay_mismatches = GovSaturatingAdd32(st.tel.replay_mismatches, 1);
   }
}

inline bool GovRecoveryV1_IsToxic(const SGovRecoveryChainV1 &c)
{
   return (c.toxic_score_0_1000 >= 500);
}

inline int GovRecoveryV1_ChainDepth(const SGovRecoveryChainV1 &c)
{
   return c.generation_depth;
}

inline long GovRecoveryV1_ExposureRatio(const SGovRecoveryChainV1 &c)
{
   return c.exposure_ratio_micro;
}

#endif // __AURUM_GOV_RECOVERY_CHAIN_V1_MQH__
