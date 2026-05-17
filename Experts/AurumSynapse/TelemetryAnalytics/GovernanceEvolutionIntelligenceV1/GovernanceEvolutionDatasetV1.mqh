//+------------------------------------------------------------------+
//| GovernanceEvolutionDatasetV1.mqh                               |
//| GOVERNANCE_EVOLUTION_INTELLIGENCE_V1 — canonical datasets        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EVO_DS_V1_MQH__
#define __AURUM_GOV_EVO_DS_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

struct SGovEvolutionGenerationV1 {
    int    generation_id;
    int    lineage_id;
    int    parent_generation_id;
    string replay_hash;
    string policy_fingerprint;
    int    governance_health_0_1000;
    int    resilience_profile_0_1000;
    int    survivability_score_0_1000;
    int    containment_quality_0_1000;
    int    collapse_resistance_0_1000;
    int    fatigue_index_0_1000;
    int    brittleness_index_0_1000;
    int    recovery_elasticity_0_1000;
    int    degeneration_velocity_milli;
    int    archetype_class;
    int    lineage_depth;
    int    replay_epoch_count;
};

struct SGovEvolutionLineageV1 {
    int    lineage_id;
    int    root_generation_id;
    int    max_depth;
    int    generation_count;
    int    ordered_generation_ids[];
};

struct SGovEvolutionDriftV1 {
    int drift_quarantine_milli;
    int drift_survivability_milli;
    int drift_containment_milli;
    int drift_fatigue_milli;
    int drift_recovery_milli;
    int drift_collapse_accel_milli;
    int drift_directionality_code;
    int drift_persistence_epochs;
    int degeneracy_indicator_0_1000;
};

struct SGovEvolutionTopologyV1 {
    int primary_cluster_id;
    int degeneration_cluster_id;
    int branch_count;
    int node_count;
    int edge_parent[];
    int edge_child[];
};

struct SGovEvolutionSurvivabilityV1 {
    int improvement_velocity_milli;
    int decay_velocity_milli;
    int inheritance_quality_0_1000;
    int containment_stab_evolution_0_1000;
    int recovery_elasticity_evolution_milli;
    int collapse_interruption_evolution_0_1000;
};

struct SGovDegenerationV1 {
    int degeneration_score_0_1000;
    int degeneration_velocity_milli;
    int degeneration_persistence_0_1000;
    int collapse_susceptibility_0_1000;
};

struct SGovEvolutionSummaryV1 {
    int    lineage_id;
    string replay_hash;
    string policy_fingerprint;
    int    dominant_archetype_class;
    int    max_degeneration_velocity_milli;
    int    mean_survivability_0_1000;
    int    generation_span;
    int    topology_branching_factor_0_1000;
    int    mean_degeneration_score_0_1000;
};

struct SGovEvolutionComparisonV1 {
    int d_max_degeneration_velocity_milli;
    int d_mean_survivability_0_1000;
    int d_generation_span;
    int d_mean_degeneration_score_0_1000;
    int d_topology_branching_factor_0_1000;
};

void GovEvoDsV1_InitGen(SGovEvolutionGenerationV1 &g) {
    g.generation_id = 0;
    g.lineage_id = 0;
    g.parent_generation_id = 0;
    g.replay_hash = "";
    g.policy_fingerprint = "";
    g.governance_health_0_1000 = 0;
    g.resilience_profile_0_1000 = 0;
    g.survivability_score_0_1000 = 0;
    g.containment_quality_0_1000 = 0;
    g.collapse_resistance_0_1000 = 0;
    g.fatigue_index_0_1000 = 0;
    g.brittleness_index_0_1000 = 0;
    g.recovery_elasticity_0_1000 = 0;
    g.degeneration_velocity_milli = 0;
    g.archetype_class = 0;
    g.lineage_depth = 0;
    g.replay_epoch_count = 0;
}

void GovEvoDsV1_InitLineage(SGovEvolutionLineageV1 &l) {
    l.lineage_id = 0;
    l.root_generation_id = 0;
    l.max_depth = 0;
    l.generation_count = 0;
    ArrayResize(l.ordered_generation_ids, 0);
}

void GovEvoDsV1_InitDrift(SGovEvolutionDriftV1 &d) {
    d.drift_quarantine_milli = 0;
    d.drift_survivability_milli = 0;
    d.drift_containment_milli = 0;
    d.drift_fatigue_milli = 0;
    d.drift_recovery_milli = 0;
    d.drift_collapse_accel_milli = 0;
    d.drift_directionality_code = 0;
    d.drift_persistence_epochs = 0;
    d.degeneracy_indicator_0_1000 = 0;
}

void GovEvoDsV1_InitTopo(SGovEvolutionTopologyV1 &t) {
    t.primary_cluster_id = 0;
    t.degeneration_cluster_id = 0;
    t.branch_count = 0;
    t.node_count = 0;
    ArrayResize(t.edge_parent, 0);
    ArrayResize(t.edge_child, 0);
}

void GovEvoDsV1_InitSurvEvo(SGovEvolutionSurvivabilityV1 &s) {
    s.improvement_velocity_milli = 0;
    s.decay_velocity_milli = 0;
    s.inheritance_quality_0_1000 = 0;
    s.containment_stab_evolution_0_1000 = 0;
    s.recovery_elasticity_evolution_milli = 0;
    s.collapse_interruption_evolution_0_1000 = 0;
}

void GovEvoDsV1_InitDeg(SGovDegenerationV1 &d) {
    d.degeneration_score_0_1000 = 0;
    d.degeneration_velocity_milli = 0;
    d.degeneration_persistence_0_1000 = 0;
    d.collapse_susceptibility_0_1000 = 0;
}

void GovEvoDsV1_InitSummary(SGovEvolutionSummaryV1 &s) {
    s.lineage_id = 0;
    s.replay_hash = "";
    s.policy_fingerprint = "";
    s.dominant_archetype_class = 0;
    s.max_degeneration_velocity_milli = 0;
    s.mean_survivability_0_1000 = 0;
    s.generation_span = 0;
    s.topology_branching_factor_0_1000 = 0;
    s.mean_degeneration_score_0_1000 = 0;
}

void GovEvoDsV1_InitCmp(SGovEvolutionComparisonV1 &c) {
    c.d_max_degeneration_velocity_milli = 0;
    c.d_mean_survivability_0_1000 = 0;
    c.d_generation_span = 0;
    c.d_mean_degeneration_score_0_1000 = 0;
    c.d_topology_branching_factor_0_1000 = 0;
}

#endif // __AURUM_GOV_EVO_DS_V1_MQH__
