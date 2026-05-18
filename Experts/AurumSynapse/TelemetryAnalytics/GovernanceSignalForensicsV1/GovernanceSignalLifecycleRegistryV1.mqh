//+------------------------------------------------------------------+
//| GovernanceSignalLifecycleRegistryV1.mqh                         |
//| PHASE 21 — ring buffer of last N signal records                  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SIG_LIFECYCLE_REG_V1_MQH__
#define __AURUM_GOV_SIG_LIFECYCLE_REG_V1_MQH__

#include "GovernanceSignalForensicsDatasetV1.mqh"

struct SGovSignalLifecycleRegistryV1
{
   SGovSignalRecordV1 ring[GOV_SIG_FORENSICS_RING_CAP_V1];
   int head;
   int count;
   ulong next_id;
};

inline void GovSigLifecycleV1_Init(SGovSignalLifecycleRegistryV1 &r)
{
   r.head = 0;
   r.count = 0;
   r.next_id = 1;
   for(int i = 0; i < GOV_SIG_FORENSICS_RING_CAP_V1; i++) {
      r.ring[i].signal_id = 0;
      r.ring[i].ts = 0;
      r.ring[i].strategy_id = -1;
      r.ring[i].regime_id = -1;
      r.ring[i].session_id = -1;
      r.ring[i].volatility_id = -1;
      r.ring[i].direction = 0;
      r.ring[i].quality_score = 0;
      r.ring[i].trend_align = false;
      r.ring[i].key_level_ok = false;
      r.ring[i].momentum_ok = false;
      r.ring[i].spread_ok = false;
      r.ring[i].session_ok = false;
      r.ring[i].risk_ok = false;
      r.ring[i].consensus_ok = false;
      r.ring[i].reject_reason = 0;
      r.ring[i].final_state = GOV_SIG_CREATED;
   }
}

inline void GovSigLifecycleV1_Push(SGovSignalLifecycleRegistryV1 &r, const SGovSignalRecordV1 &rec)
{
   const int idx = r.head;
   r.ring[idx].signal_id = r.next_id++;
   r.ring[idx].ts = rec.ts;
   r.ring[idx].strategy_id = rec.strategy_id;
   r.ring[idx].regime_id = rec.regime_id;
   r.ring[idx].session_id = rec.session_id;
   r.ring[idx].volatility_id = rec.volatility_id;
   r.ring[idx].direction = rec.direction;
   r.ring[idx].quality_score = rec.quality_score;
   r.ring[idx].trend_align = rec.trend_align;
   r.ring[idx].key_level_ok = rec.key_level_ok;
   r.ring[idx].momentum_ok = rec.momentum_ok;
   r.ring[idx].spread_ok = rec.spread_ok;
   r.ring[idx].session_ok = rec.session_ok;
   r.ring[idx].risk_ok = rec.risk_ok;
   r.ring[idx].consensus_ok = rec.consensus_ok;
   r.ring[idx].reject_reason = rec.reject_reason;
   r.ring[idx].final_state = rec.final_state;
   r.head = (r.head + 1) % GOV_SIG_FORENSICS_RING_CAP_V1;
   if(r.count < GOV_SIG_FORENSICS_RING_CAP_V1)
      r.count++;
}

#endif // __AURUM_GOV_SIG_LIFECYCLE_REG_V1_MQH__
