//+------------------------------------------------------------------+
//| GovernanceEraTransitionV1.mqh                                 |
//| Era / regime transition pressure from epoch stream.              |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_TMP_ERA_TR_V1_MQH__
#define __AURUM_GOV_TMP_ERA_TR_V1_MQH__

#include "../GovernanceCivilizationIntelligenceV1/GovernanceCivilizationDatasetV1.mqh"
#include "../GovernanceStrategicIntelligenceV1/GovernanceStrategicDatasetV1.mqh"
#include "GovernanceTemporalDatasetV1.mqh"

bool GovEraTrV1_Compute(const SGovTemporalEpochV1 &ep[], const int n_ep, const SGovCivilizationSummaryV1 &civ, const SGovStrategicSummaryV1 &strat, SGovEraTransitionV1 &out, string &out_err) {
    out_err = "";
    GovTmpDsV1_InitEraTr(out);
    if(n_ep < 1 || n_ep > 128) {
        out_err = "GOV_TMP_ERA_N";
        return false;
    }
    int tr = 0;
    int press = 0;
    for(int i = 1; i < n_ep; i++) {
        if(ep[i].era_id != ep[i - 1].era_id) {
            tr = GovSaturatingAdd32(tr, 1);
            int d = GovSaturatingAdd32(ep[i].survivability_score_milli, -ep[i - 1].survivability_score_milli);
            if(d < 0)
                d = -d;
            press = GovSaturatingAdd32(press, GovClampInt32(d / 100, 0, 100000));
        }
    }
    out.transition_count = tr;
    out.transition_pressure_milli = GovClampInt32(press * 1000 + civ.systemic_collapse_risk_milli / 4, 0, 1000000000);
    out.era_fragmentation_milli = GovClampInt32(tr * 200000 + (1000000 - GovClampInt32(civ.hierarchy_stability_milli, 0, 1000000)) / 4, 0, 1000000000);
    out.regime_shift_milli = GovClampInt32(tr * 250000 + strat.regime_endurance_balance_0_1000 * 500, 0, 1000000000);
    out.civilization_shift_milli = GovClampInt32(tr * 180000 + civ.federation_stability_milli / 5, 0, 1000000000);
    return true;
}

#endif // __AURUM_GOV_TMP_ERA_TR_V1_MQH__
