//+------------------------------------------------------------------+
//| GovernancePositionLineageComparatorV1.mqh                        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_LINEAGE_CMP_V1_MQH__
#define __AURUM_GOV_LINEAGE_CMP_V1_MQH__

#include "GovernancePositionLineageDatasetV1.mqh"
#include "GovernanceLineageReplayReconstructionV1.mqh"

inline void GovLineageCmpV1_CaptureSnapshot(const SGovLineageRegistryStoreV1 &st, SGovLineageSnapshotV1 &snap)
{
   GovLineageDsV1_InitSnapshot(snap);
   for(int i = 0; i < GOV_LINEAGE_MAX_NODES_V1; i++) {
      if(st.nodes[i].active == 0)
         continue;
      if(snap.node_count >= GOV_LINEAGE_MAX_NODES_V1)
         break;
      snap.nodes[snap.node_count] = st.nodes[i];
      snap.node_count = GovSaturatingAdd32(snap.node_count, 1);
   }
   snap.seq++;
}

inline bool GovLineageCmpV1_Equals(const SGovLineageSnapshotV1 &a, const SGovLineageSnapshotV1 &b)
{
   if(a.node_count != b.node_count)
      return false;
   for(int i = 0; i < a.node_count; i++) {
      if(a.nodes[i].lineage_id != b.nodes[i].lineage_id)
         return false;
      if(a.nodes[i].position_id != b.nodes[i].position_id)
         return false;
      if(a.nodes[i].position_volume_milli != b.nodes[i].position_volume_milli)
         return false;
   }
   return true;
}

inline string GovLineageCmpV1_Diff(const SGovLineageSnapshotV1 &a, const SGovLineageSnapshotV1 &b)
{
   string o = "";
   if(a.node_count != b.node_count)
      o += "node_count:" + IntegerToString(a.node_count) + "!=" + IntegerToString(b.node_count) + "\n";
   const int n = MathMin(a.node_count, b.node_count);
   for(int i = 0; i < n; i++) {
      if(a.nodes[i].lineage_id != b.nodes[i].lineage_id)
         o += "lid_mismatch@" + IntegerToString(i) + "\n";
   }
   return o;
}

inline string GovLineageCmpV1_Report(const SGovLineageSnapshotV1 &a, const SGovLineageSnapshotV1 &b)
{
   return GovLineageCmpV1_Diff(a, b);
}

#endif // __AURUM_GOV_LINEAGE_CMP_V1_MQH__
