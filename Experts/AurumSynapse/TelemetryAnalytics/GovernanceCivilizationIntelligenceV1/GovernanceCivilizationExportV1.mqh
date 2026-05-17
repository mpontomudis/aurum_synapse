//+------------------------------------------------------------------+
//| GovernanceCivilizationExportV1.mqh                             |
//| Deterministic UTF-8 / LF bundle (numeric fields via IntegerToString). |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CIV_EXP_V1_MQH__
#define __AURUM_GOV_CIV_EXP_V1_MQH__

#include "GovernanceCivilizationDatasetV1.mqh"

bool GovCivExpV1_Bundle(const SGovCivilizationSummaryV1 &sum, const SGovCivilizationFederationV1 &fed, const SGovCivilizationHierarchyV1 &hier, const SGovCivilizationDiplomacyV1 &dip, const SGovCivilizationMemoryV1 &mem, const SGovCivilizationTopologyV1 &topo,
                        const SGovCivilizationStabilityV1 &stab, const SGovCivilizationCollapseV1 &clps, const SGovCivilizationNodeV1 &nodes[], int &rnk_ix[], const int rank_n, string &out, string &out_err) {
    out_err = "";
    out = "===CIVILIZATION_BLOCK===\n";
    out += "GOV_CIV_V1|";
    out += IntegerToString(sum.civilization_window_id);
    out += "|";
    out += sum.replay_hash;
    out += "|";
    out += sum.policy_fingerprint;
    out += "|";
    out += IntegerToString(sum.lineage_id);
    out += "|";
    out += IntegerToString(sum.federation_stability_milli);
    out += "|";
    out += IntegerToString(sum.hierarchy_stability_milli);
    out += "|";
    out += IntegerToString(sum.diplomacy_alignment_milli);
    out += "|";
    out += IntegerToString(sum.topology_stability_milli);
    out += "|";
    out += IntegerToString(sum.memory_stable_cycles);
    out += "|";
    out += IntegerToString(sum.civilization_stability_milli);
    out += "|";
    out += IntegerToString(sum.systemic_collapse_risk_milli);
    out += "|";
    out += IntegerToString(sum.continuity_milli);
    out += "|";
    out += IntegerToString(sum.regime_balance_milli);
    out += "\n";
    out += "FED|";
    out += IntegerToString(fed.federation_id);
    out += "|";
    out += IntegerToString(fed.member_count);
    out += "|";
    out += IntegerToString(fed.avg_resilience_milli);
    out += "|";
    out += IntegerToString(fed.avg_survivability_milli);
    out += "|";
    out += IntegerToString(fed.federation_stability_milli);
    out += "|";
    out += IntegerToString(fed.federation_collapse_risk_milli);
    out += "\n";
    out += "HIER|";
    out += IntegerToString(hier.root_node_id);
    out += "|";
    out += IntegerToString(hier.max_depth);
    out += "|";
    out += IntegerToString(hier.hierarchy_pressure_milli);
    out += "|";
    out += IntegerToString(hier.governance_fragmentation_milli);
    out += "|";
    out += IntegerToString(hier.hierarchy_stability_milli);
    out += "\n";
    out += "DIP|";
    out += IntegerToString(dip.diplomacy_alignment_milli);
    out += "|";
    out += IntegerToString(dip.cooperation_milli);
    out += "|";
    out += IntegerToString(dip.conflict_milli);
    out += "|";
    out += IntegerToString(dip.containment_coordination_milli);
    out += "|";
    out += IntegerToString(dip.recovery_assistance_milli);
    out += "\n";
    out += "MEM|";
    out += IntegerToString(mem.civilization_cycles);
    out += "|";
    out += IntegerToString(mem.collapse_cycles);
    out += "|";
    out += IntegerToString(mem.recovery_cycles);
    out += "|";
    out += IntegerToString(mem.stable_cycles);
    out += "|";
    out += IntegerToString(mem.cumulative_fatigue_milli);
    out += "|";
    out += IntegerToString(mem.cumulative_resilience_milli);
    out += "\n";
    out += "TOPO|";
    out += IntegerToString(topo.node_count);
    out += "|";
    out += IntegerToString(topo.edge_count);
    out += "|";
    out += IntegerToString(topo.cluster_count);
    out += "|";
    out += IntegerToString(topo.dominant_cluster_id);
    out += "|";
    out += IntegerToString(topo.topology_stability_milli);
    out += "\n";
    out += "STAB|";
    out += IntegerToString(stab.civilization_stability_milli);
    out += "|";
    out += IntegerToString(stab.multi_lineage_survivability_milli);
    out += "|";
    out += IntegerToString(stab.governance_continuity_milli);
    out += "|";
    out += IntegerToString(stab.collapse_resistance_milli);
    out += "|";
    out += IntegerToString(stab.federation_endurance_milli);
    out += "\n";
    out += "CLPS|";
    out += IntegerToString(clps.systemic_collapse_risk_milli);
    out += "|";
    out += IntegerToString(clps.fragmentation_risk_milli);
    out += "|";
    out += IntegerToString(clps.coordination_failure_milli);
    out += "|";
    out += IntegerToString(clps.cascade_failure_milli);
    out += "|";
    out += IntegerToString(clps.recovery_capacity_milli);
    out += "\n";
    out += "RANK|";
    const int rn = GovClampInt32(rank_n, 0, 32);
    const int n_nodes = ArraySize(nodes);
    for(int k = 0; k < rn; k++) {
        if(k > 0)
            out += "|";
        const int ix = rnk_ix[k];
        if(ix < 0 || ix >= n_nodes) {
            out_err = "GOV_CIV_EXP_RANK_IX";
            return false;
        }
        out += IntegerToString(nodes[ix].civilization_id);
    }
    out += "\n";
    return true;
}

#endif // __AURUM_GOV_CIV_EXP_V1_MQH__
