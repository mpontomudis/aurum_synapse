//+------------------------------------------------------------------+
//| GovernanceLineageEngineV1.mqh                                 |
//| Deterministic genealogy: baseline + stress-lane generations.   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_LIN_ENG_V1_MQH__
#define __AURUM_GOV_LIN_ENG_V1_MQH__

#include "GovernanceEvolutionDatasetV1.mqh"
#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceDatasetV1.mqh"

bool GovLinEngV1_FromResilience(const SGovResilienceProfileV1 &rp, SGovEvolutionLineageV1 &lin, SGovEvolutionGenerationV1 &gens[], string &out_err) {
    out_err = "";
    GovEvoDsV1_InitLineage(lin);
    const int ns = ArraySize(rp.stress);
    if(ns != 7) {
        out_err = "EVO_LIN_STRESS_N";
        return false;
    }
    const int NG = 8;
    ArrayResize(gens, NG);
    const int lid = 1;
    lin.lineage_id = lid;
    lin.root_generation_id = 0;
    lin.generation_count = NG;
    lin.max_depth = NG - 1;
    ArrayResize(lin.ordered_generation_ids, NG);
    for(int i = 0; i < NG; i++)
        lin.ordered_generation_ids[i] = i;
    for(int k = 0; k < NG; k++)
        GovEvoDsV1_InitGen(gens[k]);
    gens[0].generation_id = 0;
    gens[0].lineage_id = lid;
    gens[0].parent_generation_id = 0;
    gens[0].replay_hash = rp.summary.replay_hash;
    gens[0].policy_fingerprint = rp.summary.policy_fingerprint;
    gens[0].governance_health_0_1000 = rp.summary.governance_health_0_1000;
    gens[0].resilience_profile_0_1000 = GovClampInt32((rp.summary.containment_resilience_0_1000 + rp.summary.survivability_resilience_0_1000
                                                       + rp.summary.collapse_resistance_0_1000) / 3, 0, 1000);
    gens[0].survivability_score_0_1000 = rp.summary.survivability_resilience_0_1000;
    gens[0].containment_quality_0_1000 = rp.summary.containment_resilience_0_1000;
    gens[0].collapse_resistance_0_1000 = rp.summary.collapse_resistance_0_1000;
    gens[0].fatigue_index_0_1000 = rp.fatigue.fatigue_composite_0_1000;
    gens[0].brittleness_index_0_1000 = rp.brittleness.brittleness_score_0_1000;
    gens[0].recovery_elasticity_0_1000 = rp.summary.recovery_elasticity_0_1000;
    gens[0].degeneration_velocity_milli = 0;
    gens[0].archetype_class = 0;
    gens[0].lineage_depth = 0;
    gens[0].replay_epoch_count = rp.summary.replay_epoch_count;
    for(int g = 1; g < NG; g++) {
        const int ix = g - 1;
        const SGovResilienceStressResponseV1 sr = rp.stress[ix];
        GovEvoDsV1_InitGen(gens[g]);
        gens[g].generation_id = g;
        gens[g].lineage_id = lid;
        gens[g].parent_generation_id = g - 1;
        gens[g].replay_hash = rp.summary.replay_hash;
        gens[g].policy_fingerprint = rp.summary.policy_fingerprint;
        gens[g].governance_health_0_1000 = sr.lane_health_proxy_0_1000;
        gens[g].resilience_profile_0_1000 = GovClampInt32((sr.lane_health_proxy_0_1000 + sr.lane_collapse_resistance_0_1000) / 2, 0, 1000);
        gens[g].survivability_score_0_1000 = GovClampInt32(sr.lane_health_proxy_0_1000 * 8 / 10 + sr.lane_collapse_resistance_0_1000 * 2 / 10, 0, 1000);
        gens[g].containment_quality_0_1000 = GovClampInt32(sr.lane_collapse_resistance_0_1000, 0, 1000);
        gens[g].collapse_resistance_0_1000 = sr.lane_collapse_resistance_0_1000;
        gens[g].fatigue_index_0_1000 = sr.lane_fatigue_load_0_1000;
        gens[g].brittleness_index_0_1000 = GovClampInt32(rp.brittleness.brittleness_score_0_1000 + ((sr.stress_lane_code * 17) % 200), 0, 1000);
        gens[g].recovery_elasticity_0_1000 = GovClampInt32(rp.summary.recovery_elasticity_0_1000 - GovClampInt32(ix * 15, 0, 400), 0, 1000);
        gens[g].degeneration_velocity_milli = GovClampInt32((gens[g - 1].governance_health_0_1000 - gens[g].governance_health_0_1000) * 1000, 0, 10000000);
        gens[g].archetype_class = sr.archetype_id;
        gens[g].lineage_depth = g;
        gens[g].replay_epoch_count = rp.summary.replay_epoch_count;
    }
    return true;
}

#endif // __AURUM_GOV_LIN_ENG_V1_MQH__
