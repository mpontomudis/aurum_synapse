//+------------------------------------------------------------------+
//| GovernancePositionLineageRegistryV1.mqh                         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_POS_LINEAGE_REG_V1_MQH__
#define __AURUM_GOV_POS_LINEAGE_REG_V1_MQH__

#include "GovernancePositionLineageDatasetV1.mqh"
#include "GovernancePositionLifecycleTelemetryV1.mqh"

struct SGovLineageRegistryStoreV1
{
   SGovLineageNodeV1       nodes[GOV_LINEAGE_MAX_NODES_V1];
   SGovLineageEdgeV1       edges[GOV_LINEAGE_MAX_EDGES_V1];
   SGovPositionMutationV1  mutations[GOV_LINEAGE_MAX_MUTATIONS_V1];
   int                     edge_count;
   int                     mut_widx;
   int                     mut_count;
   uint                    next_lineage_id;
   int                     ring_alloc;
   SGovLineageTelemetryV1  tel;
};

inline void GovLineageV1_Reset(SGovLineageRegistryStoreV1 &st)
{
   st.edge_count = 0;
   st.mut_widx = 0;
   st.mut_count = 0;
   st.next_lineage_id = 1;
   st.ring_alloc = 0;
   GovLineageTelV1_Init(st.tel);
   for(int i = 0; i < GOV_LINEAGE_MAX_NODES_V1; i++)
      GovLineageDsV1_InitNode(st.nodes[i]);
   for(int e = 0; e < GOV_LINEAGE_MAX_EDGES_V1; e++) {
      st.edges[e].from_node_idx = -1;
      st.edges[e].to_node_idx = -1;
      st.edges[e].edge_flags = 0;
   }
   for(int m = 0; m < GOV_LINEAGE_MAX_MUTATIONS_V1; m++)
      GovLineageDsV1_InitMutation(st.mutations[m]);
}

inline int GovLineageV1_FindByPosition(const SGovLineageRegistryStoreV1 &st, const ulong position_id)
{
   if(position_id == 0)
      return -1;
   for(int i = 0; i < GOV_LINEAGE_MAX_NODES_V1; i++) {
      if(st.nodes[i].active != 0 && st.nodes[i].position_id == position_id)
         return i;
   }
   return -1;
}

inline int GovLineageV1_FindByLineage(const SGovLineageRegistryStoreV1 &st, const uint lineage_id)
{
   if(lineage_id == 0)
      return -1;
   for(int i = 0; i < GOV_LINEAGE_MAX_NODES_V1; i++) {
      if(st.nodes[i].active != 0 && st.nodes[i].lineage_id == lineage_id)
         return i;
   }
   return -1;
}

inline int GovLineageV1_AllocSlot(SGovLineageRegistryStoreV1 &st)
{
   for(int i = 0; i < GOV_LINEAGE_MAX_NODES_V1; i++) {
      if(st.nodes[i].active == 0)
         return i;
   }
   const int slot = st.ring_alloc % GOV_LINEAGE_MAX_NODES_V1;
   st.ring_alloc = GovSaturatingAdd32(st.ring_alloc, 1);
   st.tel.overflow_events = GovSaturatingAdd32(st.tel.overflow_events, 1);
   GovLineageDsV1_InitNode(st.nodes[slot]);
   return slot;
}

inline bool GovLineageV1_PushMutation(SGovLineageRegistryStoreV1 &st, const SGovPositionMutationV1 &m)
{
   st.mutations[st.mut_widx] = m;
   st.mut_widx = (st.mut_widx + 1) % GOV_LINEAGE_MAX_MUTATIONS_V1;
   st.mut_count = GovSaturatingAdd32(st.mut_count, 1);
   return true;
}

inline bool GovLineageV1_AddEdge(SGovLineageRegistryStoreV1 &st, const int from_idx, const int to_idx, const uint flags)
{
   if(st.edge_count >= GOV_LINEAGE_MAX_EDGES_V1)
      return false;
   st.edges[st.edge_count].from_node_idx = from_idx;
   st.edges[st.edge_count].to_node_idx = to_idx;
   st.edges[st.edge_count].edge_flags = flags;
   st.edge_count++;
   return true;
}

inline int GovLineageV1_RegisterRoot(SGovLineageRegistryStoreV1 &st,
                                    const ulong position_id,
                                    const int originating_strategy,
                                    const datetime ts)
{
   if(position_id == 0)
      return -1;
   const int ex = GovLineageV1_FindByPosition(st, position_id);
   if(ex >= 0)
      return ex;
   const int slot = GovLineageV1_AllocSlot(st);
   GovLineageDsV1_InitNode(st.nodes[slot]);
   st.nodes[slot].active = 1;
   st.nodes[slot].position_id = position_id;
   st.nodes[slot].originating_strategy = GovClampInt32(originating_strategy, 0, 7);
   st.nodes[slot].current_owner_strategy = st.nodes[slot].originating_strategy;
   st.nodes[slot].creation_time = ts;
   st.nodes[slot].last_mutation_time = ts;
   st.nodes[slot].lineage_state = (int)GOV_LINEAGE_ST_OPEN;
   st.nodes[slot].lifecycle_phase = (int)GOV_LC_PHASE_OPEN;
   st.nodes[slot].parent_node_idx = -1;
   st.nodes[slot].execution_generation = 1;
   st.nodes[slot].ancestry_flags = (uint)GOV_ANC_ROOT;
   if(st.next_lineage_id == 0)
      st.next_lineage_id = 1;
   st.nodes[slot].lineage_id = st.next_lineage_id;
   st.next_lineage_id++;
   if(st.next_lineage_id == 0)
      st.next_lineage_id = 1;
   st.nodes[slot].root_lineage_id = st.nodes[slot].lineage_id;
   st.nodes[slot].parent_lineage_id = 0;
   st.tel.total_roots = GovSaturatingAdd32(st.tel.total_roots, 1);
   return slot;
}

inline int GovLineageV1_RegisterChild(SGovLineageRegistryStoreV1 &st,
                                     const int parent_node_idx,
                                     const ulong position_id,
                                     const int owner_strategy,
                                     const datetime ts,
                                     const uint extra_ancestry_flags)
{
   if(parent_node_idx < 0 || parent_node_idx >= GOV_LINEAGE_MAX_NODES_V1)
      return -1;
   if(st.nodes[parent_node_idx].active == 0) {
      st.tel.invalid_parent_links = GovSaturatingAdd32(st.tel.invalid_parent_links, 1);
      return -1;
   }
   const int slot = GovLineageV1_AllocSlot(st);
   GovLineageDsV1_InitNode(st.nodes[slot]);
   st.nodes[slot].active = 1;
   st.nodes[slot].position_id = position_id;
   st.nodes[slot].originating_strategy = st.nodes[parent_node_idx].originating_strategy;
   st.nodes[slot].current_owner_strategy = GovClampInt32(owner_strategy, 0, 7);
   st.nodes[slot].parent_node_idx = parent_node_idx;
   st.nodes[slot].creation_time = ts;
   st.nodes[slot].last_mutation_time = ts;
   st.nodes[slot].execution_generation = GovSaturatingAdd32(st.nodes[parent_node_idx].execution_generation, 1);
   st.nodes[slot].lineage_state = (int)GOV_LINEAGE_ST_OPEN;
   st.nodes[slot].lifecycle_phase = (int)GOV_LC_PHASE_SCALE_IN;
   st.nodes[slot].root_lineage_id = st.nodes[parent_node_idx].root_lineage_id;
   if(st.next_lineage_id == 0)
      st.next_lineage_id = 1;
   st.nodes[slot].lineage_id = st.next_lineage_id;
   st.next_lineage_id++;
   if(st.next_lineage_id == 0)
      st.next_lineage_id = 1;
   st.nodes[slot].parent_lineage_id = st.nodes[parent_node_idx].lineage_id;
   st.nodes[slot].ancestry_flags = (uint)GOV_ANC_CHILD | extra_ancestry_flags;
   GovLineageV1_AddEdge(st, parent_node_idx, slot, extra_ancestry_flags);
   st.tel.total_children = GovSaturatingAdd32(st.tel.total_children, 1);
   return slot;
}

inline bool GovLineageV1_Close(SGovLineageRegistryStoreV1 &st, const ulong position_id, const datetime ts)
{
   const int ix = GovLineageV1_FindByPosition(st, position_id);
   if(ix < 0) {
      st.tel.orphan_lineage = GovSaturatingAdd32(st.tel.orphan_lineage, 1);
      return false;
   }
   st.nodes[ix].lineage_state = (int)GOV_LINEAGE_ST_CLOSED;
   st.nodes[ix].lifecycle_phase = (int)GOV_LC_PHASE_CLOSED;
   st.nodes[ix].close_time = ts;
   st.nodes[ix].last_mutation_time = ts;
   st.nodes[ix].active = 0;
   return true;
}

#endif // __AURUM_GOV_POS_LINEAGE_REG_V1_MQH__
