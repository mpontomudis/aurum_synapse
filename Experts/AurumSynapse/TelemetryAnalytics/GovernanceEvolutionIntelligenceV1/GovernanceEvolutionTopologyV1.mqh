//+------------------------------------------------------------------+
//| GovernanceEvolutionTopologyV1.mqh                            |
//| Deterministic linear topology (branch_count=1 baseline).        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EVO_TOPO_V1_MQH__
#define __AURUM_GOV_EVO_TOPO_V1_MQH__

#include "GovernanceEvolutionDatasetV1.mqh"

bool GovEvoTopoV1_BuildLinear(const SGovEvolutionGenerationV1 &gens[], const int n, const string replay_hash, SGovEvolutionTopologyV1 &out, string &out_err) {
    out_err = "";
    GovEvoDsV1_InitTopo(out);
    if(n < 1)
        return true;
    out.node_count = n;
    out.branch_count = 1;
    int hsum = 0;
    const int slen = StringLen(replay_hash);
    for(int i = 0; i < slen && i < 64; i++)
        hsum = GovSaturatingAdd32(hsum, (int)StringGetCharacter(replay_hash, i));
    out.primary_cluster_id = GovClampInt32(hsum % 997, 0, 1000000);
    int dmax = 0;
    for(int k = 1; k < n; k++)
        if(gens[k].degeneration_velocity_milli > dmax)
            dmax = gens[k].degeneration_velocity_milli;
    out.degeneration_cluster_id = GovClampInt32(dmax % 101, 0, 1000000);
    if(n < 2)
        return true;
    ArrayResize(out.edge_parent, n - 1);
    ArrayResize(out.edge_child, n - 1);
    for(int e = 0; e < n - 1; e++) {
        out.edge_parent[e] = e;
        out.edge_child[e] = e + 1;
    }
    return true;
}

#endif // __AURUM_GOV_EVO_TOPO_V1_MQH__
