//+------------------------------------------------------------------+
//| GovernanceRuntimeTradeIdentityRegistryV1.mqh                     |
//| Fixed-size position → identity map (ring overwrite, O(n) scan).  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_TRADE_ID_REG_V1_MQH__
#define __AURUM_GOV_RUNTIME_TRADE_ID_REG_V1_MQH__

#include "GovernanceRuntimeStrategyTagDatasetV1.mqh"

#define GOV_RTAG_REGISTRY_CAP_V1   256

struct SGovRunTagRegistryEntryV1
{
   ulong                      position_id;
   uint                       seq;
   bool                       used;
   SGovRuntimeTradeIdentityV1 id;
};

struct SGovRunTagRegistryStoreV1
{
   SGovRunTagRegistryEntryV1 ent[GOV_RTAG_REGISTRY_CAP_V1];
   uint                      seq_ctr;
   uint                      ring_write;
};

//+------------------------------------------------------------------+
inline void GovRunTagRegV1_Init(SGovRunTagRegistryStoreV1 &st)
{
   st.seq_ctr = 0;
   st.ring_write = 0;
   for(int i = 0; i < GOV_RTAG_REGISTRY_CAP_V1; i++) {
      st.ent[i].position_id = 0;
      st.ent[i].seq = 0;
      st.ent[i].used = false;
      GovRunTagDsV1_InitIdentity(st.ent[i].id);
   }
}

//+------------------------------------------------------------------+
inline int GovRunTagRegV1_FindSlotByPosition(const SGovRunTagRegistryStoreV1 &st, const ulong position_id)
{
   if(position_id == 0)
      return -1;
   for(int i = 0; i < GOV_RTAG_REGISTRY_CAP_V1; i++) {
      if(st.ent[i].used && st.ent[i].position_id == position_id)
         return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Insert / refresh identity for position_id (deterministic).        |
//| Returns overflow_replace=1 if an occupied slot was recycled.      |
//+------------------------------------------------------------------+
inline bool GovRunTagRegV1_Insert(SGovRunTagRegistryStoreV1 &st,
                                  const ulong position_id,
                                  const SGovRuntimeTradeIdentityV1 &id,
                                  int &overflow_replace)
{
   overflow_replace = 0;
   if(position_id == 0)
      return false;
   const int ex = GovRunTagRegV1_FindSlotByPosition(st, position_id);
   if(ex >= 0) {
      st.ent[ex].id = id;
      st.seq_ctr++;
      st.ent[ex].seq = st.seq_ctr;
      return true;
   }
   int free_slot = -1;
   for(int j = 0; j < GOV_RTAG_REGISTRY_CAP_V1; j++) {
      if(!st.ent[j].used) {
         free_slot = j;
         break;
      }
   }
   int slot = free_slot;
   if(slot < 0) {
      slot = (int)(st.ring_write % GOV_RTAG_REGISTRY_CAP_V1);
      st.ring_write = (st.ring_write + 1U) % (uint)GOV_RTAG_REGISTRY_CAP_V1;
      overflow_replace = 1;
   }
   st.ent[slot].position_id = position_id;
   st.ent[slot].used = true;
   st.ent[slot].id = id;
   st.seq_ctr++;
   st.ent[slot].seq = st.seq_ctr;
   return true;
}

//+------------------------------------------------------------------+
inline bool GovRunTagRegV1_Find(const SGovRunTagRegistryStoreV1 &st,
                                const ulong position_id,
                                SGovRuntimeTradeIdentityV1 &out_id)
{
   const int s = GovRunTagRegV1_FindSlotByPosition(st, position_id);
   if(s < 0)
      return false;
   out_id = st.ent[s].id;
   return true;
}

//+------------------------------------------------------------------+
inline bool GovRunTagRegV1_Remove(SGovRunTagRegistryStoreV1 &st, const ulong position_id)
{
   const int s = GovRunTagRegV1_FindSlotByPosition(st, position_id);
   if(s < 0)
      return false;
   st.ent[s].used = false;
   st.ent[s].position_id = 0;
   GovRunTagDsV1_InitIdentity(st.ent[s].id);
   return true;
}

#endif // __AURUM_GOV_RUNTIME_TRADE_ID_REG_V1_MQH__
