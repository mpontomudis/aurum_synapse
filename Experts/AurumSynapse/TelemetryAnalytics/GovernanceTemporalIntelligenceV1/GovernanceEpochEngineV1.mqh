//+------------------------------------------------------------------+
//| GovernanceEpochEngineV1.mqh                                    |
//| Epoch-level temporal features from replay + summaries.          |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_TMP_EPOCH_ENG_V1_MQH__
#define __AURUM_GOV_TMP_EPOCH_ENG_V1_MQH__

#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceCivilizationIntelligenceV1/GovernanceCivilizationDatasetV1.mqh"
#include "../GovernanceStrategicIntelligenceV1/GovernanceStrategicDatasetV1.mqh"
#include "GovernanceTemporalDatasetV1.mqh"

int GovTmpEpochIdToInt(const ulong id) {
    const ulong m = 2147483647UL;
    return (int)(id % m);
}

bool GovEpochEngV1_Build(SGovReplayTimelineV1 &tl, const SGovCivilizationSummaryV1 &civ, const SGovStrategicSummaryV1 &strat, SGovTemporalEpochV1 &ep[], string &out_err) {
    out_err = "";
    const int n_raw = ArraySize(tl.epochs);
    const int cap = GovClampInt32(n_raw, 0, 128);
    ArrayResize(ep, cap);
    for(int i = 0; i < cap; i++)
        GovTmpDsV1_InitEpoch(ep[i]);
    if(cap < 1) {
        out_err = "GOV_TMP_EPOCH_EMPTY";
        return false;
    }
    const int civ_cont = GovClampInt32(civ.continuity_milli / 1000, 0, 1000);
    const int strat_surv = GovClampInt32(strat.survivability_horizon_0_1000, 0, 1000);
    for(int k = 0; k < cap; k++) {
        ep[k].epoch_id = GovTmpEpochIdToInt(tl.epochs[k].epoch_id);
        ep[k].era_id = GovClampInt32(tl.epochs[k].governance_state, 0, 1000000);
        if(k > 0) {
            const ulong d = (tl.epochs[k].epoch_id >= tl.epochs[k - 1].epoch_id) ? (tl.epochs[k].epoch_id - tl.epochs[k - 1].epoch_id) : 1UL;
            ep[k].epoch_duration = GovClampInt32((int)(d % 1000000UL), 1, 1000000);
        } else
            ep[k].epoch_duration = 1;
        const int surv_ms = GovClampInt32(tl.epochs[k].survivability_ms, 0, 100000);
        ep[k].survivability_score_milli = GovClampInt32(surv_ms * 10 + strat_surv, 0, 1000000);
        ep[k].continuity_score_milli = GovClampInt32(civ_cont * 1000 + k * 1000, 0, 1000000);
        const int tox = GovClampInt32(tl.epochs[k].toxicity_ms, 0, 100000);
        const int inst = GovClampInt32(tl.epochs[k].structural_instability_ms, 0, 100000);
        int cp = tl.epochs[k].causal_pressure_ms;
        if(cp < 0)
            cp = 0;
        cp = GovClampInt32(cp, 0, 1000000);
        ep[k].governance_pressure_milli = GovClampInt32(tox * 5 + inst * 3 + cp / 10, 0, 1000000);
        ep[k].decay_velocity_milli = GovClampInt32(ep[k].governance_pressure_milli / 4 + strat.degradation_stability_0_1000 * 100, 0, 1000000);
        const int rec = GovClampInt32(tl.epochs[k].recovery_allowed, 0, 1);
        ep[k].recovery_strength_milli = GovClampInt32(rec * 500000 + GovClampInt32(tl.epochs[k].survivability_emergency, 0, 1) * 100000, 0, 1000000);
        ep[k].collapse_risk_milli = GovClampInt32((1000 - GovClampInt32(strat.collapse_avoidance_score_0_1000, 0, 1000)) * 500 + tox * 2, 0, 1000000);
    }
    return true;
}

#endif // __AURUM_GOV_TMP_EPOCH_ENG_V1_MQH__
