//+------------------------------------------------------------------+
//| GovernanceCycleEngineV1.mqh                                   |
//| Deterministic cycle heuristics from epoch state runs.           |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_TMP_CYCLE_ENG_V1_MQH__
#define __AURUM_GOV_TMP_CYCLE_ENG_V1_MQH__

#include "GovernanceTemporalDatasetV1.mqh"

bool GovCycleEngV1_Analyze(const SGovTemporalEpochV1 &ep[], const int n_ep, SGovCyclePatternV1 &out, string &out_err) {
    out_err = "";
    GovTmpDsV1_InitCycle(out);
    if(n_ep < 1 || n_ep > 128) {
        out_err = "GOV_TMP_CYCLE_N";
        return false;
    }
    int osc = 0;
    int clp_run = 0;
    int rec_run = 0;
    int max_osc = 0;
    for(int i = 1; i < n_ep; i++) {
        if(ep[i].era_id != ep[i - 1].era_id)
            osc = GovSaturatingAdd32(osc, 1);
        if(ep[i].collapse_risk_milli > ep[i - 1].collapse_risk_milli)
            clp_run = GovSaturatingAdd32(clp_run, 1);
        if(ep[i].recovery_strength_milli > ep[i - 1].recovery_strength_milli)
            rec_run = GovSaturatingAdd32(rec_run, 1);
        if(osc > max_osc)
            max_osc = osc;
    }
    out.cycle_count = GovClampInt32(osc + 1, 1, 1000000);
    out.cycle_stability_milli = GovClampInt32(1000000 - max_osc * 100000, 0, 1000000000);
    out.cycle_recurrence_milli = GovClampInt32(osc * 200000 + clp_run * 50000, 0, 1000000000);
    out.collapse_cycle_milli = GovClampInt32(clp_run * 150000, 0, 1000000000);
    out.recovery_cycle_milli = GovClampInt32(rec_run * 150000, 0, 1000000000);
    out.seasonal_instability_milli = GovClampInt32(max_osc * 120000 + (n_ep > 2 ? GovClampInt32((ep[1].era_id - ep[0].era_id) * (ep[1].era_id - ep[0].era_id), 0, 1000000) : 0), 0, 1000000000);
    return true;
}

#endif // __AURUM_GOV_TMP_CYCLE_ENG_V1_MQH__
