//+------------------------------------------------------------------+
//| GovernancePredatorPreyV1.mqh                                    |
//| GOVERNANCE_ECOLOGY_INTELLIGENCE_V1 — pressure predator/prey      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECO_PREDPREY_V1_MQH__
#define __AURUM_GOV_ECO_PREDPREY_V1_MQH__

#include "GovernanceEcologyDatasetV1.mqh"

struct SGovEcologyPredPreyV1 {
    int collapse_propagation_milli;
    int pressure_transfer_milli;
    int recovery_suppression_milli;
    int survivability_predation_milli;
    int parasitic_load_milli;
};

void GovEcoPredPreyDsV1_Init(SGovEcologyPredPreyV1 &p) {
    p.collapse_propagation_milli = 0;
    p.pressure_transfer_milli = 0;
    p.recovery_suppression_milli = 0;
    p.survivability_predation_milli = 0;
    p.parasitic_load_milli = 0;
}

bool GovPredPreyV1_Analyze(const SGovEcologyEntityV1 &ents[], const int n, SGovEcologyPredPreyV1 &out, string &out_err) {
    out_err = "";
    GovEcoPredPreyDsV1_Init(out);
    const int nn = GovClampInt32(n, 0, 64);
    if(nn < 2)
        return true;
    int pmax = 0, pmin = 1000000000;
    int cmax = 0, smin = 1000000000;
    int rmin = 1000000000;
    for(int k = 0; k < nn; k++) {
        pmax = MathMax(pmax, ents[k].pressure_milli);
        pmin = MathMin(pmin, ents[k].pressure_milli);
        cmax = MathMax(cmax, ents[k].collapse_exposure_milli);
        smin = MathMin(smin, ents[k].survivability_milli);
        rmin = MathMin(rmin, ents[k].recovery_coexistence_milli);
    }
    out.pressure_transfer_milli = GovClampInt32(GovSaturatingAdd32(pmax, -pmin), 0, 1000000000);
    out.collapse_propagation_milli = GovClampInt32(GovSaturatingAdd32(cmax, out.pressure_transfer_milli / 4), 0, 1000000000);
    out.survivability_predation_milli = GovClampInt32(GovSaturatingAdd32(pmax / 2, -smin / 2), 0, 1000000000);
    out.recovery_suppression_milli = GovClampInt32(GovSaturatingAdd32(out.pressure_transfer_milli / 2, -rmin / 2), 0, 1000000000);
    int parasitic = 0;
    for(int i = 0; i < nn; i++) {
        for(int j = 0; j < nn; j++) {
            if(i == j)
                continue;
            if(ents[i].pressure_milli > ents[j].pressure_milli && ents[i].survivability_milli < ents[j].survivability_milli / 2)
                parasitic = GovSaturatingAdd32(parasitic, GovSaturatingAdd32(ents[i].pressure_milli / 100, ents[j].collapse_exposure_milli / 200));
        }
    }
    out.parasitic_load_milli = GovClampInt32(parasitic, 0, 1000000000);
    return true;
}

#endif // __AURUM_GOV_ECO_PREDPREY_V1_MQH__
