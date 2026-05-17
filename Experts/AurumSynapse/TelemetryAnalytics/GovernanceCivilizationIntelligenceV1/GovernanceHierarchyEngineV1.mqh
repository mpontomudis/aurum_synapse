//+------------------------------------------------------------------+
//| GovernanceHierarchyEngineV1.mqh                                 |
//| Hierarchy pressure / fragmentation (integer heuristics).        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CIV_HIER_ENG_V1_MQH__
#define __AURUM_GOV_CIV_HIER_ENG_V1_MQH__

#include "GovernanceCivilizationDatasetV1.mqh"

bool GovHierEngV1_Build(const SGovCivilizationNodeV1 &nodes[], const int n, SGovCivilizationHierarchyV1 &out, string &out_err) {
    out_err = "";
    GovCivDsV1_InitHier(out);
    if(n < 1 || n > 32) {
        out_err = "GOV_CIV_HIER_N";
        return false;
    }
    out.root_node_id = nodes[0].civilization_id;
    int maxd = 0;
    int minr = nodes[0].resilience_score_milli;
    int maxr = nodes[0].resilience_score_milli;
    int minst = nodes[0].strategic_score_milli;
    int maxst = nodes[0].strategic_score_milli;
    for(int i = 0; i < n; i++) {
        if(nodes[i].hierarchy_level > maxd)
            maxd = nodes[i].hierarchy_level;
        if(nodes[i].resilience_score_milli < minr)
            minr = nodes[i].resilience_score_milli;
        if(nodes[i].resilience_score_milli > maxr)
            maxr = nodes[i].resilience_score_milli;
        if(nodes[i].strategic_score_milli < minst)
            minst = nodes[i].strategic_score_milli;
        if(nodes[i].strategic_score_milli > maxst)
            maxst = nodes[i].strategic_score_milli;
    }
    out.max_depth = maxd;
    out.hierarchy_pressure_milli = GovClampInt32((maxr - minr) * 1000 / GovClampInt32(n, 1, 32), 0, 1000000);
    const int frag = GovSaturatingAdd32(maxst - minst, (maxd * 100000) / GovClampInt32(n, 1, 32));
    out.governance_fragmentation_milli = GovClampInt32(frag, 0, 1000000);
    const int press = GovSaturatingAdd32(out.hierarchy_pressure_milli / 2, out.governance_fragmentation_milli / 2);
    out.hierarchy_stability_milli = GovClampInt32(1000000 - press, 0, 1000000);
    return true;
}

#endif // __AURUM_GOV_CIV_HIER_ENG_V1_MQH__
