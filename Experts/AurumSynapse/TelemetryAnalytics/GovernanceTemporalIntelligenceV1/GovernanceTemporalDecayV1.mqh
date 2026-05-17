//+------------------------------------------------------------------+
//| GovernanceTemporalDecayV1.mqh                                  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_TMP_DECAY_V1_MQH__
#define __AURUM_GOV_TMP_DECAY_V1_MQH__

#include "../GovernanceCivilizationIntelligenceV1/GovernanceCivilizationDatasetV1.mqh"
#include "../GovernanceStrategicIntelligenceV1/GovernanceStrategicDatasetV1.mqh"
#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceDatasetV1.mqh"
#include "GovernanceTemporalDatasetV1.mqh"

bool GovTmpDecayV1_Compute(const SGovTemporalEpochV1 &ep[], const int n_ep, const SGovCivilizationSummaryV1 &civ, const SGovStrategicSummaryV1 &strat, const SGovResilienceProfileV1 &rp, SGovTemporalDecayV1 &out, string &out_err) {
    out_err = "";
    GovTmpDsV1_InitDecay(out);
    if(n_ep < 1 || n_ep > 128) {
        out_err = "GOV_TMP_DECAY_N";
        return false;
    }
    int vel_acc = 0;
    for(int i = 0; i < n_ep; i++)
        vel_acc = GovSaturatingAdd32(vel_acc, ep[i].decay_velocity_milli);
    const int divn = GovClampInt32(n_ep, 1, 128);
    const int mean_vel = vel_acc / divn;
    int acc2 = 0;
    for(int j = 1; j < n_ep; j++)
        acc2 = GovSaturatingAdd32(acc2, GovSaturatingAdd32(ep[j].decay_velocity_milli, -ep[j - 1].decay_velocity_milli));
    out.decay_acceleration_milli = GovClampInt32(mean_vel + acc2 * 100, 0, 1000000000);
    out.resilience_decay_milli = GovClampInt32(rp.summary.degradation_velocity_milli + mean_vel / 2, 0, 1000000000);
    out.survivability_decay_milli = GovClampInt32((1000 - GovClampInt32(strat.survivability_horizon_0_1000, 0, 1000)) * 500 + mean_vel, 0, 1000000000);
    out.civilization_decay_milli = GovClampInt32(civ.systemic_collapse_risk_milli + (1000000 - GovClampInt32(civ.civilization_stability_milli, 0, 1000000)) / 4, 0, 1000000000);
    out.structural_decay_milli = GovClampInt32(rp.curve.collapse_acceleration_score_0_1000 * 1000 + (1000000 - GovClampInt32(civ.topology_stability_milli, 0, 1000000)) / 10, 0, 1000000000);
    return true;
}

#endif // __AURUM_GOV_TMP_DECAY_V1_MQH__
