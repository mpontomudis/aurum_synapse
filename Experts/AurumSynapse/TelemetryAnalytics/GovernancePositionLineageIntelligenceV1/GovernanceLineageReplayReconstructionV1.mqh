//+------------------------------------------------------------------+
//| GovernanceLineageReplayReconstructionV1.mqh                     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_LINEAGE_REPLAY_V1_MQH__
#define __AURUM_GOV_LINEAGE_REPLAY_V1_MQH__

#include "GovernancePositionLineageRegistryV1.mqh"
#include "GovernancePositionMutationEngineV1.mqh"

inline long GovReplayLineageV1_SatAdd64(const long a, const long b)
{
   if(b > 0 && a > 9223372036854775807L - b)
      return 9223372036854775807L;
   if(b < 0 && a < (-9223372036854775807L - 1L) - b)
      return (-9223372036854775807L - 1L);
   return a + b;
}

inline bool GovReplayLineageV1_Rebuild(SGovLineageRegistryStoreV1 &st,
                                       SGovLineageReplayRowV1 &rows[],
                                       const int n,
                                       string &err)
{
   err = "";
   GovLineageV1_Reset(st);
   if(n < 0 || n > GOV_LINEAGE_MAX_REPLAY_ROWS_V1) {
      err = "GOV_REPLAY_ROW_RANGE";
      return false;
   }
   for(int k = 0; k < n; k++) {
      const SGovLineageReplayRowV1 r = rows[k];
      if(r.position_id == 0) {
         err = "GOV_REPLAY_ZERO_POS";
         return false;
      }
      const int ent = GovClampInt32(r.deal_entry, 0, 4);
      if(ent == (int)DEAL_ENTRY_IN) {
         const int ex = GovLineageV1_FindByPosition(st, r.position_id);
         if(ex < 0) {
            const int root = GovLineageV1_RegisterRoot(st, r.position_id, r.strategy_id, r.ts);
            if(root < 0) {
               err = "GOV_REPLAY_ROOT_FAIL";
               return false;
            }
            st.nodes[root].position_volume_milli = r.volume_milli;
         } else {
            const long prev = st.nodes[ex].position_volume_milli;
            const int mt = GovMutationV1_Detect(ent, prev, r.volume_milli, 0, 0, 0);
            SGovPositionMutationV1 mu;
            GovLineageDsV1_InitMutation(mu);
            mu.lineage_id = st.nodes[ex].lineage_id;
            mu.position_id = r.position_id;
            mu.mutation_type = mt;
            mu.ts = r.ts;
            mu.volume_delta_milli = r.volume_milli - prev;
            GovLineageV1_PushMutation(st, mu);
            if(GovMutationV1_IsScaleIn(mt)) {
               st.nodes[ex].scale_in_count = GovSaturatingAdd32(st.nodes[ex].scale_in_count, 1);
               st.tel.scale_ins = GovSaturatingAdd32(st.tel.scale_ins, 1);
            }
            st.nodes[ex].position_volume_milli = r.volume_milli;
            st.nodes[ex].lineage_state = (int)GOV_LINEAGE_ST_SCALED;
            st.nodes[ex].last_mutation_time = r.ts;
         }
      } else if(ent == (int)DEAL_ENTRY_OUT) {
         const int ex = GovLineageV1_FindByPosition(st, r.position_id);
         if(ex < 0) {
            err = "GOV_REPLAY_OUT_ORPHAN";
            return false;
         }
         const long prev = st.nodes[ex].position_volume_milli;
         const int sl = (r.deal_reason == (int)DEAL_REASON_SL) ? 1 : 0;
         const int mt = GovMutationV1_Detect(ent, prev, r.volume_milli, r.profit_cents, sl, 0);
         SGovPositionMutationV1 mu;
         GovLineageDsV1_InitMutation(mu);
         mu.lineage_id = st.nodes[ex].lineage_id;
         mu.position_id = r.position_id;
         mu.mutation_type = mt;
         mu.ts = r.ts;
         mu.delta_profit_cents = r.profit_cents;
         mu.volume_delta_milli = r.volume_milli - prev;
         GovLineageV1_PushMutation(st, mu);
         if(r.profit_cents > 0)
            st.nodes[ex].cumulative_profit_cents = GovReplayLineageV1_SatAdd64(st.nodes[ex].cumulative_profit_cents, r.profit_cents);
         else if(r.profit_cents < 0)
            st.nodes[ex].cumulative_loss_cents = GovReplayLineageV1_SatAdd64(st.nodes[ex].cumulative_loss_cents, -r.profit_cents);
         if(GovMutationV1_IsPartialClose(mt))
            st.nodes[ex].partial_close_count = GovSaturatingAdd32(st.nodes[ex].partial_close_count, 1);
         if(GovMutationV1_IsScaleOut(mt) || r.volume_milli <= 0)
            st.nodes[ex].scale_out_count = GovSaturatingAdd32(st.nodes[ex].scale_out_count, 1);
         st.nodes[ex].position_volume_milli = r.volume_milli;
         st.nodes[ex].last_mutation_time = r.ts;
         if(r.volume_milli <= 0)
            GovLineageV1_Close(st, r.position_id, r.ts);
      }
   }
   return true;
}

inline ulong GovReplayLineageV1_Hash(const SGovLineageRegistryStoreV1 &st)
{
   ulong h = 5381;
   for(int i = 0; i < GOV_LINEAGE_MAX_NODES_V1; i++) {
      if(st.nodes[i].active == 0)
         continue;
      h = ((h << 5) + h) + (ulong)st.nodes[i].lineage_id;
      h = ((h << 5) + h) + st.nodes[i].position_id;
      h = ((h << 5) + h) + (ulong)(uint)st.nodes[i].lifecycle_phase;
      h = ((h << 5) + h) + (ulong)(uint)st.nodes[i].position_volume_milli;
   }
   h = ((h << 5) + h) + (ulong)(uint)st.edge_count;
   h = ((h << 5) + h) + (ulong)(uint)st.mut_count;
   return h;
}

inline bool GovReplayLineageV1_Equals(const SGovLineageRegistryStoreV1 &a, const SGovLineageRegistryStoreV1 &b)
{
   return (GovReplayLineageV1_Hash(a) == GovReplayLineageV1_Hash(b));
}

inline bool GovReplayLineageV1_Verify(const SGovLineageRegistryStoreV1 &st, const ulong expected_hash_low32)
{
   const ulong hh = GovReplayLineageV1_Hash(st);
   return (((uint)hh) == ((uint)expected_hash_low32));
}

#endif // __AURUM_GOV_LINEAGE_REPLAY_V1_MQH__
