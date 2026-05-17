//+------------------------------------------------------------------+
//| GovernanceExecutionGenealogyEngineV1.mqh                         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EXEC_GENE_V1_MQH__
#define __AURUM_GOV_EXEC_GENE_V1_MQH__

#include "GovernancePositionLineageRegistryV1.mqh"

inline bool GovGeneV1_AttachChild(SGovLineageRegistryStoreV1 &st,
                                 const int parent_idx,
                                 const ulong position_id,
                                 const int owner_strategy,
                                 const datetime ts,
                                 const uint flags)
{
   const int ch = GovLineageV1_RegisterChild(st, parent_idx, position_id, owner_strategy, ts, flags);
   return (ch >= 0);
}

inline void GovGeneV1_UpdateOwnership(SGovLineageRegistryStoreV1 &st, const int node_idx, const int new_owner_strategy, const datetime ts)
{
   if(node_idx < 0 || node_idx >= GOV_LINEAGE_MAX_NODES_V1)
      return;
   if(st.nodes[node_idx].active == 0)
      return;
   st.nodes[node_idx].current_owner_strategy = GovClampInt32(new_owner_strategy, 0, 7);
   st.nodes[node_idx].last_mutation_time = ts;
}

inline void GovGeneV1_UpdateLifecycle(SGovLineageRegistryStoreV1 &st,
                                       const int node_idx,
                                       const int new_phase,
                                       const int new_state,
                                       const datetime ts)
{
   if(node_idx < 0 || node_idx >= GOV_LINEAGE_MAX_NODES_V1)
      return;
   if(st.nodes[node_idx].active == 0)
      return;
   st.nodes[node_idx].lifecycle_phase = new_phase;
   st.nodes[node_idx].lineage_state = new_state;
   st.nodes[node_idx].last_mutation_time = ts;
}

inline void GovGeneV1_Finalize(SGovLineageRegistryStoreV1 &st, const ulong position_id, const datetime ts)
{
   GovLineageV1_Close(st, position_id, ts);
}

inline void GovGeneV1_ComputeExposureTree(const SGovLineageRegistryStoreV1 &st, SGovExecutionGenealogyV1 &out)
{
   out.dominant_owner_strategy = 0;
   out.max_execution_depth = 0;
   out.recovery_contamination_score = 0;
   out.total_nodes = 0;
   out.total_edges = st.edge_count;
   int owner_counts[8];
   for(int o = 0; o < 8; o++)
      owner_counts[o] = 0;
   for(int i = 0; i < GOV_LINEAGE_MAX_NODES_V1; i++) {
      if(st.nodes[i].active == 0)
         continue;
      out.total_nodes = GovSaturatingAdd32(out.total_nodes, 1);
      const int ow = GovClampInt32(st.nodes[i].current_owner_strategy, 0, 7);
      owner_counts[ow] = GovSaturatingAdd32(owner_counts[ow], 1);
      if(st.nodes[i].execution_generation > out.max_execution_depth)
         out.max_execution_depth = st.nodes[i].execution_generation;
      if((st.nodes[i].ancestry_flags & (uint)GOV_ANC_RECOVERY) != 0)
         out.recovery_contamination_score = GovSaturatingAdd32(out.recovery_contamination_score, 1);
   }
   int best = 0;
   for(int k = 1; k < 8; k++) {
      if(owner_counts[k] > owner_counts[best])
         best = k;
   }
   out.dominant_owner_strategy = best;
}

#include "GovernanceLineageReplayReconstructionV1.mqh"

inline bool GovGeneV1_Reconstruct(SGovLineageRegistryStoreV1 &st, SGovLineageReplayRowV1 &rows[], const int n, string &err)
{
   return GovReplayLineageV1_Rebuild(st, rows, n, err);
}

#endif // __AURUM_GOV_EXEC_GENE_V1_MQH__
