//+------------------------------------------------------------------+
//| GovernanceShadowRuntimeLaneV1.mqh                               |
//| Append-only integer ring — shadow lane (no replay / export)    |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SHADOW_RUNTIME_LANE_V1_MQH__
#define __AURUM_GOV_SHADOW_RUNTIME_LANE_V1_MQH__

#include "GovernanceRuntimeShadowContractV1.mqh"

#ifndef GOV_RUNTIME_SHADOW_LANE_NO_REPLAY
   #define GOV_RUNTIME_SHADOW_LANE_NO_REPLAY 1
#endif

#ifndef GOV_RUNTIME_SHADOW_QUEUE_CAP_V1
   #define GOV_RUNTIME_SHADOW_QUEUE_CAP_V1 256
#endif

#ifndef GOV_RUNTIME_SHADOW_QUEUE_SLOT_WORDS_V1
   #define GOV_RUNTIME_SHADOW_QUEUE_SLOT_WORDS_V1 16
#endif

struct SGovRuntimeShadowQueueSlotV1
{
   long v[GOV_RUNTIME_SHADOW_QUEUE_SLOT_WORDS_V1];
};

struct SGovRuntimeShadowQueueV1
{
   SGovRuntimeShadowQueueSlotV1 slots[GOV_RUNTIME_SHADOW_QUEUE_CAP_V1];
   int head;
   int tail;
   int count;
   uint total_pushes;
};

//+------------------------------------------------------------------+
inline void GovRuntimeShadowQueueV1_Init(SGovRuntimeShadowQueueV1 &q)
{
   q.head = 0;
   q.tail = 0;
   q.count = 0;
   q.total_pushes = 0;
}

//+------------------------------------------------------------------+
inline void GovRuntimeShadowQueueV1_Clear(SGovRuntimeShadowQueueV1 &q)
{
   GovRuntimeShadowQueueV1_Init(q);
}

//+------------------------------------------------------------------+
inline int GovRuntimeShadowQueueV1_Count(const SGovRuntimeShadowQueueV1 &q)
{
   return q.count;
}

//+------------------------------------------------------------------+
inline void GovRuntimeShadowQueueV1_PackSnapshot(const SGovRuntimeShadowSnapshotV1 &s,
                                                 SGovRuntimeShadowQueueSlotV1 &slot)
{
   for(int i = 0; i < GOV_RUNTIME_SHADOW_QUEUE_SLOT_WORDS_V1; i++)
      slot.v[i] = 0;
   slot.v[0] = (long)s.ts_utc;
   slot.v[1] = GovRuntimeShadowV1_SymbolHash(s.symbol);
   slot.v[2] = s.spread_points;
   slot.v[3] = s.equity_cents;
   slot.v[4] = s.max_equity_dd_bp;
   slot.v[5] = (long)s.open_positions;
   slot.v[6] = (long)s.strategy_id;
   slot.v[7] = s.quality_score_bp;
   slot.v[8] = (s.execution_allowed_native ? 1L : 0L);
   slot.v[9] = (long)s.governance_shadow_state;
   slot.v[10] = (long)s.survivability_score_0_100;
   slot.v[11] = (long)s.toxicity_score_0_100;
   slot.v[12] = (long)s.anomaly_flags;
}

//+------------------------------------------------------------------+
//| O(1) append — overwrites oldest when full. No File*, no parser.  |
//+------------------------------------------------------------------+
inline bool GovRuntimeShadowQueueV1_Append(SGovRuntimeShadowQueueV1 &q,
                                           const SGovRuntimeShadowSnapshotV1 &s)
{
   SGovRuntimeShadowQueueSlotV1 slot;
   GovRuntimeShadowQueueV1_PackSnapshot(s, slot);
   const int cap = GOV_RUNTIME_SHADOW_QUEUE_CAP_V1;
   q.slots[q.tail] = slot;
   q.tail = (q.tail + 1) % cap;
   if(q.count < cap)
      q.count++;
   else
      q.head = (q.head + 1) % cap;
   q.total_pushes++;
   return true;
}

//+------------------------------------------------------------------+
//| Reserved hook: drain to cold pipeline (timer / worker). No-op.  |
//+------------------------------------------------------------------+
inline int GovRuntimeShadowLaneV1_DeferredDrainHint(const SGovRuntimeShadowQueueV1 &q)
{
   return q.count;
}

//+------------------------------------------------------------------+
//| Compile-time contract marker for harness self-check.             |
//+------------------------------------------------------------------+
inline bool GovRuntimeShadowLaneV1_ContractColdLaneOnly(void)
{
   return (GOV_RUNTIME_SHADOW_LANE_NO_REPLAY == 1 && GOV_RUNTIME_SHADOW_CONTRACT_V1_NO_REPLAY == 1);
}

#endif // __AURUM_GOV_SHADOW_RUNTIME_LANE_V1_MQH__
