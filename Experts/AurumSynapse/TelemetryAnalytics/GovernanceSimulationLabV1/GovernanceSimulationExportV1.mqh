//+------------------------------------------------------------------+
//| GovernanceSimulationExportV1.mqh                              |
//| UTF-8/LF simulation bundles.                                     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SIM_EXP_V1_MQH__
#define __AURUM_GOV_SIM_EXP_V1_MQH__

#include "GovernanceSimulationDatasetV1.mqh"

bool GovSimExpV1_Bundle(const SGovSimPolicyRunV1 &runs[], const int n, int &rank_ord[], string &out, string &out_err) {
    out_err = "";
    out = "===GOV_SIM_LAB_V1===\n";
    out += "schema,GOV_SIM_LAB_V1\n";
    for(int i = 0; i < n; i++) {
        const int ix = rank_ord[i];
        const SGovSimPolicyRunV1 r = runs[ix];
        out += "RUN," + IntegerToString(i);
        out += ",arch," + IntegerToString(r.archetype_id);
        out += ",stress," + IntegerToString(r.stress_lane_code);
        out += ",health," + IntegerToString(r.governance_health_proxy_0_1000);
        out += ",inc," + IntegerToString(r.incident_count);
        out += ",stab," + IntegerToString(GovSimDsV1_StabSum(r.stability));
        out += "\n";
    }
    return true;
}

#endif // __AURUM_GOV_SIM_EXP_V1_MQH__
