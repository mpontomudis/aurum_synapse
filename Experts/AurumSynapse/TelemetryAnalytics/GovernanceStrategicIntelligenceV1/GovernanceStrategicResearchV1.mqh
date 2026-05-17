//+------------------------------------------------------------------+
//| GovernanceStrategicResearchV1.mqh                            |
//| Deterministic strategic rankings (generations / endurance).     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRAT_RES_V1_MQH__
#define __AURUM_GOV_STRAT_RES_V1_MQH__

#include "../GovernanceEvolutionIntelligenceV1/GovernanceEvolutionDatasetV1.mqh"

void GovStratResV1_RankEnduranceProxy(const SGovEvolutionGenerationV1 &gens[], const int n, int &ord[]) {
    for(int i = 0; i < n; i++)
        ord[i] = i;
    for(int a = 0; a < n; a++) {
        for(int b = a + 1; b < n; b++) {
            const int ia = ord[a];
            const int ib = ord[b];
            const int sa = GovSaturatingAdd32(gens[ia].resilience_profile_0_1000, gens[ia].survivability_score_0_1000);
            const int sb = GovSaturatingAdd32(gens[ib].resilience_profile_0_1000, gens[ib].survivability_score_0_1000);
            bool swap = false;
            if(sb > sa)
                swap = true;
            else if(sb == sa && gens[ib].generation_id < gens[ia].generation_id)
                swap = true;
            if(swap) {
                const int t = ord[a];
                ord[a] = ord[b];
                ord[b] = t;
            }
        }
    }
}

#endif // __AURUM_GOV_STRAT_RES_V1_MQH__
