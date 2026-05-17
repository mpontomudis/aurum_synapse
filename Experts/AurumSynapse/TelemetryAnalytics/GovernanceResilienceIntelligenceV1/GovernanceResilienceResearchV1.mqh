//+------------------------------------------------------------------+
//| GovernanceResilienceResearchV1.mqh                           |
//| Deterministic rankings over stress-lane responses.              |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RESIL_RES_V1_MQH__
#define __AURUM_GOV_RESIL_RES_V1_MQH__

#include "GovernanceResilienceDatasetV1.mqh"

void GovResilResV1_RankByCollapse(SGovResilienceStressResponseV1 &sr[], const int n, int &ord[]) {
    for(int i = 0; i < n; i++)
        ord[i] = i;
    for(int a = 0; a < n; a++) {
        for(int b = a + 1; b < n; b++) {
            const int ia = ord[a];
            const int ib = ord[b];
            const int ca = sr[ia].lane_collapse_resistance_0_1000;
            const int cb = sr[ib].lane_collapse_resistance_0_1000;
            bool swap = false;
            if(cb > ca)
                swap = true;
            else if(cb == ca && sr[ib].archetype_id < sr[ia].archetype_id)
                swap = true;
            if(swap) {
                const int t = ord[a];
                ord[a] = ord[b];
                ord[b] = t;
            }
        }
    }
}

void GovResilResV1_RankByFatigue(SGovResilienceStressResponseV1 &sr[], const int n, int &ord[]) {
    for(int i = 0; i < n; i++)
        ord[i] = i;
    for(int a = 0; a < n; a++) {
        for(int b = a + 1; b < n; b++) {
            const int ia = ord[a];
            const int ib = ord[b];
            const int fa = sr[ia].lane_fatigue_load_0_1000;
            const int fb = sr[ib].lane_fatigue_load_0_1000;
            bool swap = false;
            if(fa > fb)
                swap = true;
            else if(fa == fb && sr[ib].archetype_id < sr[ia].archetype_id)
                swap = true;
            if(swap) {
                const int t = ord[a];
                ord[a] = ord[b];
                ord[b] = t;
            }
        }
    }
}

#endif // __AURUM_GOV_RESIL_RES_V1_MQH__
