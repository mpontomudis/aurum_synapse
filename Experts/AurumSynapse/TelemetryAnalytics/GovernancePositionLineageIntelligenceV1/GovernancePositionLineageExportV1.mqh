//+------------------------------------------------------------------+
//| GovernancePositionLineageExportV1.mqh                           |
//| LF-only deterministic text (no CRLF injection).                |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_LINEAGE_EXP_V1_MQH__
#define __AURUM_GOV_LINEAGE_EXP_V1_MQH__

#include "GovernanceExecutionGenealogyEngineV1.mqh"

#define GOV_LINEAGE_BLK_POS        "===POSITION_LINEAGE==="
#define GOV_LINEAGE_BLK_GENE      "===EXECUTION_GENEALOGY==="
#define GOV_LINEAGE_BLK_REC        "===RECOVERY_CHAINS==="
#define GOV_LINEAGE_BLK_MUT        "===POSITION_MUTATIONS==="
#define GOV_LINEAGE_BLK_OWN        "===STRATEGY_OWNERSHIP==="
#define GOV_LINEAGE_BLK_TOX       "===LINEAGE_TOXICITY==="

inline void GovLineageExpV1_AppendLf(string &dst, const string chunk)
{
   string c = chunk;
   StringReplace(c, "\r\n", "\n");
   StringReplace(c, "\r", "\n");
   dst += c;
}

inline string GovLineageExpV1_Report(const SGovLineageRegistryStoreV1 &st)
{
   string o = "";
   GovLineageExpV1_AppendLf(o, GOV_LINEAGE_BLK_POS + "\n");
   for(int i = 0; i < GOV_LINEAGE_MAX_NODES_V1; i++) {
      if(st.nodes[i].active == 0)
         continue;
      GovLineageExpV1_AppendLf(o, "lid=" + IntegerToString((int)st.nodes[i].lineage_id) + ",pos=" + IntegerToString((int)st.nodes[i].position_id) + ",root=" + IntegerToString((int)st.nodes[i].root_lineage_id) + ",orig=" + IntegerToString(st.nodes[i].originating_strategy) + ",own=" + IntegerToString(st.nodes[i].current_owner_strategy) + ",volm=" + IntegerToString((int)st.nodes[i].position_volume_milli) + "\n");
   }
   GovLineageExpV1_AppendLf(o, GOV_LINEAGE_BLK_GENE + "\n");
   GovLineageExpV1_AppendLf(o, "edges=" + IntegerToString(st.edge_count) + ",mut=" + IntegerToString(st.mut_count) + "\n");
   GovLineageExpV1_AppendLf(o, GOV_LINEAGE_BLK_REC + "\n");
   GovLineageExpV1_AppendLf(o, "recoveries_tel=" + IntegerToString(st.tel.recoveries) + "\n");
   GovLineageExpV1_AppendLf(o, GOV_LINEAGE_BLK_MUT + "\n");
   for(int j = 0; j < GOV_LINEAGE_MAX_MUTATIONS_V1; j++) {
      const SGovPositionMutationV1 m = st.mutations[j];
      if(m.mutation_type == (int)GOV_MUT_NONE)
         continue;
      GovLineageExpV1_AppendLf(o, "lid=" + IntegerToString((int)m.lineage_id) + ",mt=" + IntegerToString(m.mutation_type) + ",dv=" + IntegerToString((int)m.volume_delta_milli) + "\n");
   }
   GovLineageExpV1_AppendLf(o, GOV_LINEAGE_BLK_OWN + "\n");
   SGovExecutionGenealogyV1 g;
   GovGeneV1_ComputeExposureTree(st, g);
   GovLineageExpV1_AppendLf(o, "dom_owner=" + IntegerToString(g.dominant_owner_strategy) + ",depth=" + IntegerToString(g.max_execution_depth) + "\n");
   GovLineageExpV1_AppendLf(o, GOV_LINEAGE_BLK_TOX + "\n");
   GovLineageExpV1_AppendLf(o, "recov_contam=" + IntegerToString(g.recovery_contamination_score) + "\n");
   return o;
}

inline string GovLineageExpV1_Csv(const SGovLineageRegistryStoreV1 &st)
{
   string o = "lid,pos,orig,owner,volm,pc,lc\n";
   for(int i = 0; i < GOV_LINEAGE_MAX_NODES_V1; i++) {
      if(st.nodes[i].active == 0)
         continue;
      o += IntegerToString((int)st.nodes[i].lineage_id) + "," + IntegerToString((int)st.nodes[i].position_id) + "," +
           IntegerToString(st.nodes[i].originating_strategy) + "," + IntegerToString(st.nodes[i].current_owner_strategy) + "," +
           IntegerToString((int)st.nodes[i].position_volume_milli) + "," + IntegerToString((int)st.nodes[i].cumulative_profit_cents) + "," +
           IntegerToString((int)st.nodes[i].cumulative_loss_cents) + "\n";
   }
   return o;
}

inline bool GovLineageExpV1_Bundle(const SGovLineageRegistryStoreV1 &st, string &dst)
{
   dst = "";
   GovLineageExpV1_AppendLf(dst, GovLineageExpV1_Report(st));
   GovLineageExpV1_AppendLf(dst, GovLineageExpV1_Csv(st));
   return true;
}

#endif // __AURUM_GOV_LINEAGE_EXP_V1_MQH__
