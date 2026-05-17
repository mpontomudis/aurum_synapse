//+------------------------------------------------------------------+
//| GovernanceCatastrophicResistanceV1.mqh                       |
//| Resistance to prolonged stress & systemic destabilization.       |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CAT_RES_V1_MQH__
#define __AURUM_GOV_CAT_RES_V1_MQH__

#include "GovernanceStrategicDatasetV1.mqh"
#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceDatasetV1.mqh"
#include "../GovernanceEvolutionIntelligenceV1/GovernanceEvolutionDatasetV1.mqh"

bool GovStratCatV1_Score(const SGovResilienceProfileV1 &rp, const SGovEvolutionGenerationV1 &gens[], const int n, const SGovDegenerationV1 &dg, SGovCatastrophicResistanceV1 &out, string &out_err) {
    out_err = "";
    GovStratDsV1_InitCat(out);
    int min_surv = 10000;
    int min_clp = 10000;
    for(int i = 0; i < n; i++) {
        if(gens[i].survivability_score_0_1000 < min_surv)
            min_surv = gens[i].survivability_score_0_1000;
        if(gens[i].collapse_resistance_0_1000 < min_clp)
            min_clp = gens[i].collapse_resistance_0_1000;
    }
    if(min_surv > 1000)
        min_surv = rp.summary.survivability_resilience_0_1000;
    if(min_clp > 1000)
        min_clp = rp.summary.collapse_resistance_0_1000;
    int score = 1000;
    score = GovSaturatingAdd32(score, -dg.degeneration_score_0_1000 / 2);
    score = GovSaturatingAdd32(score, GovClampInt32(min_surv / 2, 0, 300));
    score = GovSaturatingAdd32(score, GovClampInt32(min_clp / 3, 0, 300));
    score = GovSaturatingAdd32(score, -GovClampInt32(rp.brittleness.oscillation_index_0_1000 / 4, 0, 200));
    out.catastrophic_resistance_score_0_1000 = GovClampInt32(score, 0, 1000);
    out.collapse_interruption_capacity_0_1000 = GovClampInt32(rp.collapse.resilience_interruption_efficiency_0_1000 + rp.summary.collapse_resistance_0_1000 / 4, 0, 1000);
    out.strategic_survival_capacity_0_1000 = GovClampInt32(rp.summary.governance_health_0_1000 + min_surv / 5, 0, 1000);
    out.systemic_recovery_capacity_0_1000 = GovClampInt32(rp.summary.recovery_elasticity_0_1000 + rp.summary.stabilization_quality_0_1000 / 3, 0, 1000);
    return true;
}

#endif // __AURUM_GOV_CAT_RES_V1_MQH__
