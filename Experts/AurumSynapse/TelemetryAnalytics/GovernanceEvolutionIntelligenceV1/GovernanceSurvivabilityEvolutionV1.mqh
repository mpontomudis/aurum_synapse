//+------------------------------------------------------------------+
//| GovernanceSurvivabilityEvolutionV1.mqh                       |
//| Longitudinal survivability deltas (deterministic).              |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SURV_EVO_V1_MQH__
#define __AURUM_GOV_SURV_EVO_V1_MQH__

#include "GovernanceEvolutionDatasetV1.mqh"

bool GovSurvEvoV1_Compute(const SGovEvolutionGenerationV1 &gens[], const int n, SGovEvolutionSurvivabilityV1 &out, string &out_err) {
    out_err = "";
    GovEvoDsV1_InitSurvEvo(out);
    if(n < 2)
        return true;
    int best_improve = 0;
    int worst_decay = 0;
    int csum = 0;
    int rsum = 0;
    int clsum = 0;
    for(int k = 1; k < n; k++) {
        const int ds = GovSaturatingAdd32(gens[k].survivability_score_0_1000, -gens[k - 1].survivability_score_0_1000);
        const int dc = GovSaturatingAdd32(gens[k].containment_quality_0_1000, -gens[k - 1].containment_quality_0_1000);
        const int dr = GovSaturatingAdd32(gens[k].recovery_elasticity_0_1000, -gens[k - 1].recovery_elasticity_0_1000);
        const int dcl = GovSaturatingAdd32(gens[k].collapse_resistance_0_1000, -gens[k - 1].collapse_resistance_0_1000);
        if(ds > best_improve)
            best_improve = ds;
        if(ds < worst_decay)
            worst_decay = ds;
        csum = GovSaturatingAdd32(csum, dc);
        rsum = GovSaturatingAdd32(rsum, dr);
        clsum = GovSaturatingAdd32(clsum, dcl);
    }
    const int denom = GovClampInt32(n - 1, 1, 1000000);
    out.improvement_velocity_milli = GovClampInt32(best_improve * 1000, 0, 10000000);
    out.decay_velocity_milli = GovClampInt32(-worst_decay * 1000, 0, 10000000);
    const int surv_drop = GovSaturatingAdd32(gens[0].survivability_score_0_1000, -gens[n - 1].survivability_score_0_1000);
    out.inheritance_quality_0_1000 = GovClampInt32(1000 - GovClampInt32(surv_drop, 0, 1000), 0, 1000);
    out.containment_stab_evolution_0_1000 = GovClampInt32(500 + (csum * 1000) / (denom * 10), 0, 1000);
    out.recovery_elasticity_evolution_milli = (rsum * 1000) / denom;
    out.collapse_interruption_evolution_0_1000 = GovClampInt32(500 + (clsum * 1000) / (denom * 10), 0, 1000);
    return true;
}

#endif // __AURUM_GOV_SURV_EVO_V1_MQH__
