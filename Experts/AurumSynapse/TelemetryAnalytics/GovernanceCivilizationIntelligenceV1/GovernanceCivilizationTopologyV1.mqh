//+------------------------------------------------------------------+
//| GovernanceCivilizationTopologyV1.mqh                           |
//| Linear edge topology + fixed-bucket clusters (no allocation).   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CIV_TOPO_V1_MQH__
#define __AURUM_GOV_CIV_TOPO_V1_MQH__

#include "GovernanceCivilizationDatasetV1.mqh"

bool GovCivTopoV1_Build(const SGovCivilizationNodeV1 &nodes[], const int n, const SGovCivilizationFederationV1 &fed, SGovCivilizationTopologyV1 &out, string &out_err) {
    out_err = "";
    GovCivDsV1_InitTopo(out);
    if(n < 1 || n > 32) {
        out_err = "GOV_CIV_TOPO_N";
        return false;
    }
    out.node_count = n;
    out.edge_count = (n > 1) ? GovSaturatingAdd32(n, -1) : 0;
    int seed = GovSaturatingAdd32(fed.federation_id * 1103515245, fed.member_count * 17);
    seed = GovSaturatingAdd32(seed, n * 3);
    for(int k = 0; k < n && k < 8; k++)
        seed = GovSaturatingAdd32(seed, nodes[k].civilization_id * (k + 1));
    seed = GovClampInt32(seed, -2000000000, 2000000000);
    if(seed < 0)
        seed = -seed;
    out.cluster_count = GovClampInt32(1 + (seed % 4), 1, 8);
    out.dominant_cluster_id = GovClampInt32((seed >> 3) % out.cluster_count, 0, out.cluster_count - 1);
    int sum_res = 0;
    for(int i = 0; i < n; i++)
        sum_res = GovSaturatingAdd32(sum_res, nodes[i].resilience_score_milli / 1000);
    const int avg_k = sum_res / GovClampInt32(n, 1, 32);
    const int spread = GovClampInt32(fed.avg_survivability_milli / 1000 - avg_k, -1000, 1000);
    int abs_sp = spread;
    if(abs_sp < 0)
        abs_sp = -abs_sp;
    const int dens = GovClampInt32((out.edge_count * 1000) / GovClampInt32(out.cluster_count, 1, 32), 0, 1000000);
    out.topology_stability_milli = GovClampInt32(1000000 - dens / 4 - abs_sp * 100, 0, 1000000);
    return true;
}

#endif // __AURUM_GOV_CIV_TOPO_V1_MQH__
