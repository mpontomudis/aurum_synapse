//+------------------------------------------------------------------+
//| GovernanceSimulationResearchV1.mqh                            |
//| Deterministic rankings (no ML).                                  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SIM_RES_V1_MQH__
#define __AURUM_GOV_SIM_RES_V1_MQH__

#include "GovernanceSimulationDatasetV1.mqh"

void GovSimResV1_RankHealth(SGovSimPolicyRunV1 &runs[], const int n, int &order_out[]) {
    for(int i = 0; i < n; i++)
        order_out[i] = i;
    for(int a = 0; a < n; a++) {
        for(int b = a + 1; b < n; b++) {
            const int ia = order_out[a];
            const int ib = order_out[b];
            const int ha = runs[ia].governance_health_proxy_0_1000;
            const int hb = runs[ib].governance_health_proxy_0_1000;
            bool swap = false;
            if(hb > ha)
                swap = true;
            else if(hb == ha && runs[ib].archetype_id < runs[ia].archetype_id)
                swap = true;
            if(swap) {
                const int t = order_out[a];
                order_out[a] = order_out[b];
                order_out[b] = t;
            }
        }
    }
}

#endif // __AURUM_GOV_SIM_RES_V1_MQH__
