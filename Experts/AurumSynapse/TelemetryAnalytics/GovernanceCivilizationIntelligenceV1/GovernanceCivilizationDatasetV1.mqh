//+------------------------------------------------------------------+
//| GovernanceCivilizationDatasetV1.mqh                            |
//| GOVERNANCE_CIVILIZATION_INTELLIGENCE_V1 — datasets               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CIV_DS_V1_MQH__
#define __AURUM_GOV_CIV_DS_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "../GovernanceEvolutionIntelligenceV1/GovernanceEvolutionDatasetV1.mqh"
#include "../GovernanceStrategicIntelligenceV1/GovernanceStrategicDatasetV1.mqh"
#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceDatasetV1.mqh"

struct SGovCivilizationNodeV1 {
    int civilization_id;
    int lineage_root_generation;
    int resilience_score_milli;
    int strategic_score_milli;
    int survivability_score_milli;
    int fatigue_score_milli;
    int collapse_risk_milli;
    int regime_balance_milli;
    int diplomacy_weight_milli;
    int federation_weight_milli;
    int hierarchy_level;
    int active_flag;
};

struct SGovCivilizationFederationV1 {
    int federation_id;
    int member_count;
    int avg_resilience_milli;
    int avg_survivability_milli;
    int federation_stability_milli;
    int federation_collapse_risk_milli;
};

struct SGovCivilizationHierarchyV1 {
    int root_node_id;
    int max_depth;
    int hierarchy_pressure_milli;
    int governance_fragmentation_milli;
    int hierarchy_stability_milli;
};

struct SGovCivilizationDiplomacyV1 {
    int diplomacy_alignment_milli;
    int cooperation_milli;
    int conflict_milli;
    int containment_coordination_milli;
    int recovery_assistance_milli;
};

struct SGovCivilizationMemoryV1 {
    int civilization_cycles;
    int collapse_cycles;
    int recovery_cycles;
    int stable_cycles;
    int cumulative_fatigue_milli;
    int cumulative_resilience_milli;
};

struct SGovCivilizationTopologyV1 {
    int node_count;
    int edge_count;
    int cluster_count;
    int dominant_cluster_id;
    int topology_stability_milli;
};

struct SGovCivilizationCollapseV1 {
    int systemic_collapse_risk_milli;
    int fragmentation_risk_milli;
    int coordination_failure_milli;
    int cascade_failure_milli;
    int recovery_capacity_milli;
};

struct SGovCivilizationStabilityV1 {
    int civilization_stability_milli;
    int multi_lineage_survivability_milli;
    int governance_continuity_milli;
    int collapse_resistance_milli;
    int federation_endurance_milli;
};

struct SGovCivilizationSummaryV1 {
    int civilization_window_id;
    string replay_hash;
    string policy_fingerprint;
    int lineage_id;
    int federation_stability_milli;
    int hierarchy_stability_milli;
    int diplomacy_alignment_milli;
    int topology_stability_milli;
    int memory_stable_cycles;
    int civilization_stability_milli;
    int systemic_collapse_risk_milli;
    int continuity_milli;
    int regime_balance_milli;
};

struct SGovCivilizationComparisonV1 {
    int d_federation_stability_milli;
    int d_hierarchy_stability_milli;
    int d_diplomacy_alignment_milli;
    int d_topology_stability_milli;
    int d_memory_stable_cycles;
    int d_civilization_stability_milli;
    int d_systemic_collapse_risk_milli;
    int d_continuity_milli;
    int d_regime_balance_milli;
};

void GovCivDsV1_InitNode(SGovCivilizationNodeV1 &n) {
    n.civilization_id = 0;
    n.lineage_root_generation = 0;
    n.resilience_score_milli = 0;
    n.strategic_score_milli = 0;
    n.survivability_score_milli = 0;
    n.fatigue_score_milli = 0;
    n.collapse_risk_milli = 0;
    n.regime_balance_milli = 0;
    n.diplomacy_weight_milli = 0;
    n.federation_weight_milli = 0;
    n.hierarchy_level = 0;
    n.active_flag = 0;
}

void GovCivDsV1_InitFed(SGovCivilizationFederationV1 &f) {
    f.federation_id = 0;
    f.member_count = 0;
    f.avg_resilience_milli = 0;
    f.avg_survivability_milli = 0;
    f.federation_stability_milli = 0;
    f.federation_collapse_risk_milli = 0;
}

void GovCivDsV1_InitHier(SGovCivilizationHierarchyV1 &h) {
    h.root_node_id = 0;
    h.max_depth = 0;
    h.hierarchy_pressure_milli = 0;
    h.governance_fragmentation_milli = 0;
    h.hierarchy_stability_milli = 0;
}

void GovCivDsV1_InitDip(SGovCivilizationDiplomacyV1 &d) {
    d.diplomacy_alignment_milli = 0;
    d.cooperation_milli = 0;
    d.conflict_milli = 0;
    d.containment_coordination_milli = 0;
    d.recovery_assistance_milli = 0;
}

void GovCivDsV1_InitMem(SGovCivilizationMemoryV1 &m) {
    m.civilization_cycles = 0;
    m.collapse_cycles = 0;
    m.recovery_cycles = 0;
    m.stable_cycles = 0;
    m.cumulative_fatigue_milli = 0;
    m.cumulative_resilience_milli = 0;
}

void GovCivDsV1_InitTopo(SGovCivilizationTopologyV1 &t) {
    t.node_count = 0;
    t.edge_count = 0;
    t.cluster_count = 0;
    t.dominant_cluster_id = 0;
    t.topology_stability_milli = 0;
}

void GovCivDsV1_InitClps(SGovCivilizationCollapseV1 &c) {
    c.systemic_collapse_risk_milli = 0;
    c.fragmentation_risk_milli = 0;
    c.coordination_failure_milli = 0;
    c.cascade_failure_milli = 0;
    c.recovery_capacity_milli = 0;
}

void GovCivDsV1_InitStab(SGovCivilizationStabilityV1 &s) {
    s.civilization_stability_milli = 0;
    s.multi_lineage_survivability_milli = 0;
    s.governance_continuity_milli = 0;
    s.collapse_resistance_milli = 0;
    s.federation_endurance_milli = 0;
}

void GovCivDsV1_InitSummary(SGovCivilizationSummaryV1 &s) {
    s.civilization_window_id = 0;
    s.replay_hash = "";
    s.policy_fingerprint = "";
    s.lineage_id = 0;
    s.federation_stability_milli = 0;
    s.hierarchy_stability_milli = 0;
    s.diplomacy_alignment_milli = 0;
    s.topology_stability_milli = 0;
    s.memory_stable_cycles = 0;
    s.civilization_stability_milli = 0;
    s.systemic_collapse_risk_milli = 0;
    s.continuity_milli = 0;
    s.regime_balance_milli = 0;
}

void GovCivDsV1_InitCmp(SGovCivilizationComparisonV1 &c) {
    c.d_federation_stability_milli = 0;
    c.d_hierarchy_stability_milli = 0;
    c.d_diplomacy_alignment_milli = 0;
    c.d_topology_stability_milli = 0;
    c.d_memory_stable_cycles = 0;
    c.d_civilization_stability_milli = 0;
    c.d_systemic_collapse_risk_milli = 0;
    c.d_continuity_milli = 0;
    c.d_regime_balance_milli = 0;
}

bool GovCivDsV1_BuildNodes(const SGovEvolutionGenerationV1 &gens[], const int n, const SGovResilienceProfileV1 &rp, const SGovStrategicSummaryV1 &strat, SGovCivilizationNodeV1 &nodes[], string &out_err) {
    out_err = "";
    if(n < 1 || n > 32) {
        out_err = "GOV_CIV_DS_NODES_RANGE";
        return false;
    }
    ArrayResize(nodes, n);
    const int stress_n = ArraySize(rp.stress);
    const int strat_sust = GovClampInt32(strat.sustainability_index_0_1000, 0, 1000);
    const int root_gen = gens[0].generation_id;
    for(int i = 0; i < n; i++) {
        GovCivDsV1_InitNode(nodes[i]);
        nodes[i].civilization_id = GovSaturatingAdd32(gens[i].generation_id, 1);
        nodes[i].lineage_root_generation = root_gen;
        nodes[i].resilience_score_milli = GovClampInt32(gens[i].resilience_profile_0_1000 * 1000, 0, 1000000);
        nodes[i].strategic_score_milli = GovClampInt32(gens[i].governance_health_0_1000 * 1000 + strat_sust * 100, 0, 2000000);
        nodes[i].survivability_score_milli = GovClampInt32(gens[i].survivability_score_0_1000 * 1000, 0, 1000000);
        nodes[i].fatigue_score_milli = GovClampInt32(gens[i].fatigue_index_0_1000 * 1000, 0, 1000000);
        const int clp_res = GovClampInt32(gens[i].collapse_resistance_0_1000, 0, 1000);
        nodes[i].collapse_risk_milli = GovClampInt32((1000 - clp_res) * 1000, 0, 1000000);
        const int brit = GovClampInt32(gens[i].brittleness_index_0_1000, 0, 1000);
        nodes[i].regime_balance_milli = GovClampInt32((1000 - brit) * 1000, 0, 1000000);
        int lane = gens[i].archetype_class % 5;
        if(stress_n > 0) {
            const int ix = GovClampInt32(i % stress_n, 0, stress_n - 1);
            lane = GovClampInt32(rp.stress[ix].stress_lane_code, 0, 1000);
        }
        nodes[i].diplomacy_weight_milli = GovClampInt32(lane * 100000 + gens[i].containment_quality_0_1000 * 100, 0, 1000000);
        nodes[i].federation_weight_milli = GovClampInt32(1000000 / GovClampInt32(n, 1, 32), 0, 1000000);
        nodes[i].hierarchy_level = GovClampInt32(gens[i].lineage_depth, 0, 1000000);
        nodes[i].active_flag = 1;
    }
    return true;
}

#endif // __AURUM_GOV_CIV_DS_V1_MQH__
