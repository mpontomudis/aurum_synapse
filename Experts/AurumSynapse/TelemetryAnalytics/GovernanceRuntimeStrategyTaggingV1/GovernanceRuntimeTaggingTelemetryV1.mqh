//+------------------------------------------------------------------+
//| GovernanceRuntimeTaggingTelemetryV1.mqh                          |
//| Integer counters — append-only style increments only.           |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_TAG_TEL_V1_MQH__
#define __AURUM_GOV_RUNTIME_TAG_TEL_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionDatasetV1.mqh"

struct SGovRunTagTelemetryStoreV1
{
   int trades_by_strategy[GOV_SATTR_STRAT_COUNT_V1];
   int trades_by_regime[GOV_SATTR_REGIME_COUNT_V1];
   int trades_by_vol[GOV_SATTR_VOL_COUNT_V1];
   int trades_by_session[GOV_SATTR_SESSION_COUNT_V1];
   int tag_injection_fail;
   int unknown_strategy;
   int registry_overflow;
   int orphan_close;
   int commits;
};

inline void GovRunTagTelV1_Init(SGovRunTagTelemetryStoreV1 &t)
{
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++)
      t.trades_by_strategy[i] = 0;
   for(int r = 0; r < GOV_SATTR_REGIME_COUNT_V1; r++)
      t.trades_by_regime[r] = 0;
   for(int v = 0; v < GOV_SATTR_VOL_COUNT_V1; v++)
      t.trades_by_vol[v] = 0;
   for(int s = 0; s < GOV_SATTR_SESSION_COUNT_V1; s++)
      t.trades_by_session[s] = 0;
   t.tag_injection_fail = 0;
   t.unknown_strategy = 0;
   t.registry_overflow = 0;
   t.orphan_close = 0;
   t.commits = 0;
}

// Counts closed trades pushed through the attribution bridge (commit path).
inline void GovRunTagTelV1_OnCommittedTrade(SGovRunTagTelemetryStoreV1 &t, const int sid, const int rid, const int vid, const int tid)
{
   const int si = GovClampInt32(sid, 0, GOV_SATTR_STRAT_COUNT_V1 - 1);
   const int ri = GovClampInt32(rid, 0, GOV_SATTR_REGIME_COUNT_V1 - 1);
   const int vi = GovClampInt32(vid, 0, GOV_SATTR_VOL_COUNT_V1 - 1);
   const int ii = GovClampInt32(tid, 0, GOV_SATTR_SESSION_COUNT_V1 - 1);
   t.trades_by_strategy[si] = GovSaturatingAdd32(t.trades_by_strategy[si], 1);
   t.trades_by_regime[ri] = GovSaturatingAdd32(t.trades_by_regime[ri], 1);
   t.trades_by_vol[vi] = GovSaturatingAdd32(t.trades_by_vol[vi], 1);
   t.trades_by_session[ii] = GovSaturatingAdd32(t.trades_by_session[ii], 1);
}

#endif // __AURUM_GOV_RUNTIME_TAG_TEL_V1_MQH__
