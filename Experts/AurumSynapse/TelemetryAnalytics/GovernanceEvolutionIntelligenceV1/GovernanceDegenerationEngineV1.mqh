//+------------------------------------------------------------------+
//| GovernanceDegenerationEngineV1.mqh                          |
//| Deterministic degeneration along generation chain.              |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_DEG_ENG_V1_MQH__
#define __AURUM_GOV_DEG_ENG_V1_MQH__

#include "GovernanceEvolutionDatasetV1.mqh"

bool GovDegV1_FromGenerations(const SGovEvolutionGenerationV1 &gens[], const int n, SGovDegenerationV1 &out, string &out_err) {
    out_err = "";
    GovEvoDsV1_InitDeg(out);
    if(n < 2)
        return true;
    int persist = 0;
    int vmax = 0;
    int collapse_sum = 0;
    for(int k = 1; k < n; k++) {
        if(gens[k].governance_health_0_1000 < gens[k - 1].governance_health_0_1000)
            persist = GovSaturatingAdd32(persist, 1);
        if(gens[k].degeneration_velocity_milli > vmax)
            vmax = gens[k].degeneration_velocity_milli;
        collapse_sum = GovSaturatingAdd32(collapse_sum, gens[k].collapse_resistance_0_1000);
    }
    out.degeneration_velocity_milli = vmax;
    out.degeneration_persistence_0_1000 = GovClampInt32(persist * 140, 0, 1000);
    const int mean_cl = collapse_sum / GovClampInt32(n - 1, 1, 1000000);
    out.collapse_susceptibility_0_1000 = GovClampInt32(1000 - mean_cl, 0, 1000);
    out.degeneration_score_0_1000 = GovClampInt32(out.degeneration_persistence_0_1000 / 2 + vmax / 10000 + out.collapse_susceptibility_0_1000 / 4, 0, 1000);
    return true;
}

#endif // __AURUM_GOV_DEG_ENG_V1_MQH__
