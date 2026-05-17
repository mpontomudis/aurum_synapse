//+------------------------------------------------------------------+
//| GovernanceContinuityEngineV1.mqh                               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_TMP_CONT_ENG_V1_MQH__
#define __AURUM_GOV_TMP_CONT_ENG_V1_MQH__

#include "../GovernanceCivilizationIntelligenceV1/GovernanceCivilizationDatasetV1.mqh"
#include "../GovernanceStrategicIntelligenceV1/GovernanceStrategicDatasetV1.mqh"
#include "GovernanceTemporalDatasetV1.mqh"

bool GovContEngV1_Compute(const SGovTemporalEpochV1 &ep[], const int n_ep, const SGovCivilizationSummaryV1 &civ, const SGovStrategicSummaryV1 &strat, SGovContinuityV1 &out, string &out_err) {
    out_err = "";
    GovTmpDsV1_InitCont(out);
    if(n_ep < 1 || n_ep > 128) {
        out_err = "GOV_TMP_CONT_N";
        return false;
    }
    int sum_cont = 0;
    int sum_rec = 0;
    for(int i = 0; i < n_ep; i++) {
        sum_cont = GovSaturatingAdd32(sum_cont, ep[i].continuity_score_milli / 1000);
        sum_rec = GovSaturatingAdd32(sum_rec, ep[i].recovery_strength_milli / 1000);
    }
    const int divn = GovClampInt32(n_ep, 1, 128);
    out.continuity_strength_milli = GovClampInt32(civ.continuity_milli + (sum_cont * 1000) / divn, 0, 1000000000);
    out.continuity_break_risk_milli = GovClampInt32(civ.systemic_collapse_risk_milli / 2 + (1000 - GovClampInt32(strat.collapse_avoidance_score_0_1000, 0, 1000)) * 500, 0, 1000000000);
    out.recovery_recurrence_milli = GovClampInt32((sum_rec * 1000) / divn + strat.recovery_sustainability_0_1000 * 500, 0, 1000000000);
    out.governance_persistence_milli = GovClampInt32(strat.endurance_capacity_0_1000 * 1000 + civ.civilization_stability_milli / 4, 0, 1000000000);
    out.temporal_alignment_milli = GovClampInt32(strat.sustainability_index_0_1000 * 500 + civ.diplomacy_alignment_milli / 4, 0, 1000000000);
    return true;
}

#endif // __AURUM_GOV_TMP_CONT_ENG_V1_MQH__
