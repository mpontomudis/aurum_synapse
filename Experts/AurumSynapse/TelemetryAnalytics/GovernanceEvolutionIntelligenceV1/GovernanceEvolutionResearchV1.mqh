//+------------------------------------------------------------------+
//| GovernanceEvolutionResearchV1.mqh                            |
//| Deterministic rankings over generations (observational).        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EVO_RES_V1_MQH__
#define __AURUM_GOV_EVO_RES_V1_MQH__

#include "GovernanceEvolutionDatasetV1.mqh"

void GovEvoResV1_RankByResilience(const SGovEvolutionGenerationV1 &gens[], const int n, int &ord[]) {
    for(int i = 0; i < n; i++)
        ord[i] = i;
    for(int a = 0; a < n; a++) {
        for(int b = a + 1; b < n; b++) {
            const int ia = ord[a];
            const int ib = ord[b];
            const int ra = gens[ia].resilience_profile_0_1000;
            const int rb = gens[ib].resilience_profile_0_1000;
            bool swap = false;
            if(rb > ra)
                swap = true;
            else if(rb == ra && gens[ib].generation_id < gens[ia].generation_id)
                swap = true;
            if(swap) {
                const int t = ord[a];
                ord[a] = ord[b];
                ord[b] = t;
            }
        }
    }
}

void GovEvoResV1_RankByDegeneration(const SGovEvolutionGenerationV1 &gens[], const int n, int &ord[]) {
    for(int i = 0; i < n; i++)
        ord[i] = i;
    for(int a = 0; a < n; a++) {
        for(int b = a + 1; b < n; b++) {
            const int ia = ord[a];
            const int ib = ord[b];
            const int da = gens[ia].degeneration_velocity_milli;
            const int db = gens[ib].degeneration_velocity_milli;
            bool swap = false;
            if(db > da)
                swap = true;
            else if(db == da && gens[ib].generation_id < gens[ia].generation_id)
                swap = true;
            if(swap) {
                const int t = ord[a];
                ord[a] = ord[b];
                ord[b] = t;
            }
        }
    }
}

#endif // __AURUM_GOV_EVO_RES_V1_MQH__
