//+------------------------------------------------------------------+
//| GovernanceEvolutionDriftV1.mqh                               |
//| Integer drift vectors across evolution generations.             |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EVO_DRIFT_V1_MQH__
#define __AURUM_GOV_EVO_DRIFT_V1_MQH__

#include "GovernanceEvolutionDatasetV1.mqh"

bool GovEvoDriftV1_Compute(const SGovEvolutionGenerationV1 &gens[], const int n, const SGovDegenerationV1 &deg, SGovEvolutionDriftV1 &out, string &out_err) {
    out_err = "";
    GovEvoDsV1_InitDrift(out);
    if(n < 2)
        return true;
    const int a = 0;
    const int b = n - 1;
    const int denom = GovClampInt32(n - 1, 1, 1000000);
    out.drift_survivability_milli = ((gens[b].survivability_score_0_1000 - gens[a].survivability_score_0_1000) * 1000) / denom;
    out.drift_containment_milli = ((gens[b].containment_quality_0_1000 - gens[a].containment_quality_0_1000) * 1000) / denom;
    out.drift_fatigue_milli = ((gens[b].fatigue_index_0_1000 - gens[a].fatigue_index_0_1000) * 1000) / denom;
    out.drift_recovery_milli = ((gens[b].recovery_elasticity_0_1000 - gens[a].recovery_elasticity_0_1000) * 1000) / denom;
    out.drift_collapse_accel_milli = ((gens[a].collapse_resistance_0_1000 - gens[b].collapse_resistance_0_1000) * 1000) / denom;
    out.drift_quarantine_milli = ((gens[b].archetype_class - gens[a].archetype_class) * 50 * 1000) / denom;
    out.drift_directionality_code = GovClampInt32(gens[b].governance_health_0_1000 - gens[a].governance_health_0_1000, -1000, 1000);
    out.drift_persistence_epochs = GovClampInt32(deg.degeneration_persistence_0_1000 * (gens[a].replay_epoch_count / GovClampInt32(n, 1, 100)), 0, 1000000);
    out.degeneracy_indicator_0_1000 = deg.degeneration_score_0_1000;
    return true;
}

#endif // __AURUM_GOV_EVO_DRIFT_V1_MQH__
