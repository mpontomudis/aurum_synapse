//+------------------------------------------------------------------+
//| GovernancePositionLineageDatasetV1.mqh                          |
//| PHASE 19 — GOVERNANCE_POSITION_LINEAGE_INTELLIGENCE_V1 — POD    |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_POS_LINEAGE_DS_V1_MQH__
#define __AURUM_GOV_POS_LINEAGE_DS_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

#define GOV_LINEAGE_MAX_NODES_V1        256
#define GOV_LINEAGE_MAX_EDGES_V1        512
#define GOV_LINEAGE_MAX_MUTATIONS_V1    512
#define GOV_LINEAGE_MAX_RECOVERY_V1     128
#define GOV_LINEAGE_MAX_REPLAY_ROWS_V1   512

//+------------------------------------------------------------------+
enum ENUM_GOV_LINEAGE_STATE_V1
{
   GOV_LINEAGE_ST_UNKNOWN = 0,
   GOV_LINEAGE_ST_OPEN = 1,
   GOV_LINEAGE_ST_SCALED = 2,
   GOV_LINEAGE_ST_RECOVERED = 3,
   GOV_LINEAGE_ST_HEDGED = 4,
   GOV_LINEAGE_ST_CLOSING = 5,
   GOV_LINEAGE_ST_CLOSED = 6
};

enum ENUM_GOV_LIFECYCLE_PHASE_V1
{
   GOV_LC_PHASE_NONE = 0,
   GOV_LC_PHASE_OPEN = 1,
   GOV_LC_PHASE_CONTINUATION = 2,
   GOV_LC_PHASE_SCALE_IN = 3,
   GOV_LC_PHASE_SCALE_OUT = 4,
   GOV_LC_PHASE_PARTIAL = 5,
   GOV_LC_PHASE_RECOVERY = 6,
   GOV_LC_PHASE_HEDGE = 7,
   GOV_LC_PHASE_CLOSED = 99
};

enum ENUM_GOV_MUTATION_TYPE_V1
{
   GOV_MUT_NONE = 0,
   GOV_MUT_NEW_ENTRY = 1,
   GOV_MUT_CONTINUATION = 2,
   GOV_MUT_SCALE_IN = 3,
   GOV_MUT_SCALE_OUT = 4,
   GOV_MUT_PARTIAL_CLOSE = 5,
   GOV_MUT_HEDGE = 6,
   GOV_MUT_RECOVERY = 7,
   GOV_MUT_REVERSAL = 8,
   GOV_MUT_TRANSFER_OWNERSHIP = 9
};

enum ENUM_GOV_ANCESTRY_FLAG_V1
{
   GOV_ANC_NONE = 0,
   GOV_ANC_ROOT = 1,
   GOV_ANC_CHILD = 2,
   GOV_ANC_RECOVERY = 4,
   GOV_ANC_HEDGE = 8,
   GOV_ANC_SCALE = 16,
   GOV_ANC_PARTIAL = 32,
   GOV_ANC_TOXIC = 64
};

//+------------------------------------------------------------------+
struct SGovLineageEdgeV1
{
   int    from_node_idx;
   int    to_node_idx;
   uint   edge_flags;
};

//+------------------------------------------------------------------+
struct SGovLineageNodeV1
{
   uint   lineage_id;
   uint   parent_lineage_id;
   uint   root_lineage_id;
   ulong  position_id;
   int    originating_strategy;
   int    current_owner_strategy;
   int    execution_generation;
   int    scale_depth;
   int    recovery_depth;
   int    hedge_depth;
   int    partial_close_count;
   int    scale_in_count;
   int    scale_out_count;
   long   cumulative_profit_cents;
   long   cumulative_loss_cents;
   long   position_volume_milli;
   uint   ancestry_flags;
   int    lineage_state;
   int    lifecycle_phase;
   datetime creation_time;
   datetime close_time;
   datetime last_mutation_time;
   int    parent_node_idx;
   uchar  active;
   uchar  reserved0;
   uchar  reserved1;
   uchar  reserved2;
};

struct SGovPositionLifecycleV1
{
   ulong position_id;
   int   root_node_idx;
   int   head_node_idx;
   int   depth;
   int   mutation_count;
};

struct SGovExecutionGenealogyV1
{
   int dominant_owner_strategy;
   int max_execution_depth;
   int recovery_contamination_score;
   int total_nodes;
   int total_edges;
};

struct SGovLineageSnapshotV1
{
   SGovLineageNodeV1 nodes[GOV_LINEAGE_MAX_NODES_V1];
   int               node_count;
   uint              seq;
};

struct SGovRecoveryChainV1
{
   uint root_lineage_id;
   uint last_lineage_id;
   int  generation_depth;
   int  toxic_score_0_1000;
   long exposure_ratio_micro;
};

struct SGovPositionMutationV1
{
   uint                  lineage_id;
   ulong                 position_id;
   int                   mutation_type;
   datetime              ts;
   long                  delta_profit_cents;
   long                  volume_delta_milli;
};

struct SGovLineageReplayRowV1
{
   ulong    position_id;
   ulong    parent_position_id;
   ulong    deal_ticket;
   int      deal_entry;
   long     volume_milli;
   long     profit_cents;
   int      strategy_id;
   datetime ts;
   int      deal_reason;
};

//+------------------------------------------------------------------+
inline void GovLineageDsV1_InitNode(SGovLineageNodeV1 &n)
{
   n.lineage_id = 0;
   n.parent_lineage_id = 0;
   n.root_lineage_id = 0;
   n.position_id = 0;
   n.originating_strategy = 0;
   n.current_owner_strategy = 0;
   n.execution_generation = 0;
   n.scale_depth = 0;
   n.recovery_depth = 0;
   n.hedge_depth = 0;
   n.partial_close_count = 0;
   n.scale_in_count = 0;
   n.scale_out_count = 0;
   n.cumulative_profit_cents = 0;
   n.cumulative_loss_cents = 0;
   n.position_volume_milli = 0;
   n.ancestry_flags = 0;
   n.lineage_state = (int)GOV_LINEAGE_ST_UNKNOWN;
   n.lifecycle_phase = (int)GOV_LC_PHASE_NONE;
   n.creation_time = 0;
   n.close_time = 0;
   n.last_mutation_time = 0;
   n.parent_node_idx = -1;
   n.active = 0;
   n.reserved0 = 0;
   n.reserved1 = 0;
   n.reserved2 = 0;
}

inline void GovLineageDsV1_InitMutation(SGovPositionMutationV1 &m)
{
   m.lineage_id = 0;
   m.position_id = 0;
   m.mutation_type = (int)GOV_MUT_NONE;
   m.ts = 0;
   m.delta_profit_cents = 0;
   m.volume_delta_milli = 0;
}

inline void GovLineageDsV1_InitSnapshot(SGovLineageSnapshotV1 &s)
{
   s.node_count = 0;
   s.seq = 0;
   for(int i = 0; i < GOV_LINEAGE_MAX_NODES_V1; i++)
      GovLineageDsV1_InitNode(s.nodes[i]);
}

inline bool GovLineageDsV1_NodeValid(const SGovLineageNodeV1 &n)
{
   if(n.active == 0)
      return false;
   if(n.position_id == 0)
      return false;
   if(n.lineage_state < (int)GOV_LINEAGE_ST_UNKNOWN || n.lineage_state > (int)GOV_LINEAGE_ST_CLOSED)
      return false;
   return true;
}

#endif // __AURUM_GOV_POS_LINEAGE_DS_V1_MQH__
