//+------------------------------------------------------------------+
//| GovernanceRegimeTransitionV1.mqh                                |
//| PHASE 22 — regime change ring + post-transition counters         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REGIME_TRANSITION_V1_MQH__
#define __AURUM_GOV_REGIME_TRANSITION_V1_MQH__

#include "GovernanceRegimeDatasetV1.mqh"

inline void GovRegimeTrV1_OnChange(SGovRegimeRuntimeStoreV1 &s,
                                   const datetime ts,
                                   const int from_slot,
                                   const int to_slot,
                                   const long tox_delta)
{
   s.transitions_total++;
   s.post_transition_bars = 0;
   s.post_transition_tox_accum = tox_delta;
   const int cap = GOV_REGIME_TRANSITION_RING_V1;
   const int idx = (s.tr_head + s.tr_count) % cap;
   s.tr_ring[idx].ts = ts;
   s.tr_ring[idx].from_reg = from_slot;
   s.tr_ring[idx].to_reg = to_slot;
   s.tr_ring[idx].post_bars = 0;
   s.tr_ring[idx].post_tox_proxy = tox_delta;
   if(s.tr_count < cap)
      s.tr_count++;
   else
      s.tr_head = (s.tr_head + 1) % cap;
}

inline void GovRegimeTrV1_PostBarTick(SGovRegimeRuntimeStoreV1 &s, const long tox_delta)
{
   if(s.transitions_total == 0)
      return;
   s.post_transition_bars++;
   s.post_transition_tox_accum += tox_delta;
   if(s.tr_count <= 0)
      return;
   const int tail = (s.tr_head + s.tr_count - 1) % GOV_REGIME_TRANSITION_RING_V1;
   s.tr_ring[tail].post_bars = s.post_transition_bars;
   s.tr_ring[tail].post_tox_proxy += tox_delta;
}

#endif // __AURUM_GOV_REGIME_TRANSITION_V1_MQH__
