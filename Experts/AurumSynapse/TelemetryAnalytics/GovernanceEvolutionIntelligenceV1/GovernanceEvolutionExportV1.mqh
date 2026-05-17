//+------------------------------------------------------------------+
//| GovernanceEvolutionExportV1.mqh                              |
//| UTF-8/LF deterministic evolution bundles.                       |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EVO_EXP_V1_MQH__
#define __AURUM_GOV_EVO_EXP_V1_MQH__

#include "GovernanceEvolutionDatasetV1.mqh"

bool GovEvoExpV1_Bundle(const SGovEvolutionSummaryV1 &sum, const SGovEvolutionLineageV1 &lin, const SGovEvolutionGenerationV1 &gens[], const int n, const SGovEvolutionDriftV1 &dr,
                        const SGovEvolutionTopologyV1 &tp, const SGovEvolutionSurvivabilityV1 &sv, const SGovDegenerationV1 &dg, int &rank_ord[], string &out, string &out_err) {
    out_err = "";
    out = "===GOV_EVOLUTION_V1===\n";
    out += "schema,GOV_EVOLUTION_V1\n";
    out += "SUM,lid," + IntegerToString(sum.lineage_id);
    out += ",rh," + sum.replay_hash;
    out += ",pf," + sum.policy_fingerprint;
    out += ",dom_arch," + IntegerToString(sum.dominant_archetype_class);
    out += ",mdv," + IntegerToString(sum.max_degeneration_velocity_milli);
    out += ",msv," + IntegerToString(sum.mean_survivability_0_1000);
    out += ",gspan," + IntegerToString(sum.generation_span);
    out += ",tbf," + IntegerToString(sum.topology_branching_factor_0_1000);
    out += ",mds," + IntegerToString(sum.mean_degeneration_score_0_1000);
    out += "\n";
    out += "LIN,lid," + IntegerToString(lin.lineage_id);
    out += ",root," + IntegerToString(lin.root_generation_id);
    out += ",depth," + IntegerToString(lin.max_depth);
    out += ",gc," + IntegerToString(lin.generation_count);
    out += ",ord";
    for(int i = 0; i < lin.generation_count; i++)
        out += "," + IntegerToString(lin.ordered_generation_ids[i]);
    out += "\n";
    for(int i = 0; i < n; i++) {
        const int ix = rank_ord[i];
        const SGovEvolutionGenerationV1 g = gens[ix];
        out += "GENRANK," + IntegerToString(i);
        out += ",gid," + IntegerToString(g.generation_id);
        out += ",pid," + IntegerToString(g.parent_generation_id);
        out += ",arch," + IntegerToString(g.archetype_class);
        out += ",gh," + IntegerToString(g.governance_health_0_1000);
        out += ",rp," + IntegerToString(g.resilience_profile_0_1000);
        out += ",sv," + IntegerToString(g.survivability_score_0_1000);
        out += ",dv," + IntegerToString(g.degeneration_velocity_milli);
        out += "\n";
    }
    out += "DRIFT,dq," + IntegerToString(dr.drift_quarantine_milli);
    out += ",dsv," + IntegerToString(dr.drift_survivability_milli);
    out += ",dct," + IntegerToString(dr.drift_containment_milli);
    out += ",dfa," + IntegerToString(dr.drift_fatigue_milli);
    out += ",drc," + IntegerToString(dr.drift_recovery_milli);
    out += ",dca," + IntegerToString(dr.drift_collapse_accel_milli);
    out += ",dir," + IntegerToString(dr.drift_directionality_code);
    out += ",dpe," + IntegerToString(dr.drift_persistence_epochs);
    out += ",dgi," + IntegerToString(dr.degeneracy_indicator_0_1000);
    out += "\n";
    out += "TOPO,pc," + IntegerToString(tp.primary_cluster_id);
    out += ",dc," + IntegerToString(tp.degeneration_cluster_id);
    out += ",br," + IntegerToString(tp.branch_count);
    out += ",nc," + IntegerToString(tp.node_count);
    out += ",ep";
    const int ne = ArraySize(tp.edge_parent);
    for(int e = 0; e < ne; e++)
        out += "," + IntegerToString(tp.edge_parent[e]) + ">" + IntegerToString(tp.edge_child[e]);
    out += "\n";
    out += "SURVEVO,iv," + IntegerToString(sv.improvement_velocity_milli);
    out += ",dv," + IntegerToString(sv.decay_velocity_milli);
    out += ",iq," + IntegerToString(sv.inheritance_quality_0_1000);
    out += ",cse," + IntegerToString(sv.containment_stab_evolution_0_1000);
    out += ",ree," + IntegerToString(sv.recovery_elasticity_evolution_milli);
    out += ",cie," + IntegerToString(sv.collapse_interruption_evolution_0_1000);
    out += "\n";
    out += "DEG,sc," + IntegerToString(dg.degeneration_score_0_1000);
    out += ",vel," + IntegerToString(dg.degeneration_velocity_milli);
    out += ",per," + IntegerToString(dg.degeneration_persistence_0_1000);
    out += ",csu," + IntegerToString(dg.collapse_susceptibility_0_1000);
    out += "\n";
    return true;
}

#endif // __AURUM_GOV_EVO_EXP_V1_MQH__
