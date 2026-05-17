//+------------------------------------------------------------------+
//| GovernanceAgingEngineV1.mqh                                    |
//| Governance aging via integer EWMA over epochs.                   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_TMP_AGE_ENG_V1_MQH__
#define __AURUM_GOV_TMP_AGE_ENG_V1_MQH__

#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceDatasetV1.mqh"
#include "GovernanceTemporalDatasetV1.mqh"

bool GovAgeEngV1_Compute(const SGovTemporalEpochV1 &ep[], const int n_ep, const SGovResilienceProfileV1 &rp, SGovGovernanceAgingV1 &out, string &out_err) {
    out_err = "";
    GovTmpDsV1_InitAging(out);
    if(n_ep < 1 || n_ep > 128) {
        out_err = "GOV_TMP_AGE_N";
        return false;
    }
    out.governance_age_epochs = n_ep;
    long ew_f = 0;
    long ew_surv = 0;
    long ew_cont = 0;
    long ew_press = 0;
    for(int i = 0; i < n_ep; i++) {
        const long f_in = (long)ep[i].governance_pressure_milli;
        const long s_in = (long)ep[i].survivability_score_milli;
        const long c_in = (long)ep[i].continuity_score_milli;
        const long p_in = (long)ep[i].decay_velocity_milli;
        ew_f = (ew_f * 7L + f_in) / 8L;
        ew_surv = (ew_surv * 7L + s_in) / 8L;
        ew_cont = (ew_cont * 7L + c_in) / 8L;
        ew_press = (ew_press * 7L + p_in) / 8L;
    }
    out.fatigue_accumulation_milli = GovClampInt32((int)ew_f, 0, 1000000000);
    const int rp_fat = GovClampInt32(rp.fatigue.fatigue_composite_0_1000, 0, 1000);
    out.survivability_decay_milli = GovClampInt32(GovSaturatingAdd32((int)(1000000L - ew_surv), rp_fat * 500), 0, 1000000000);
    out.continuity_decay_milli = GovClampInt32(GovSaturatingAdd32((int)(1000000L - ew_cont), rp.summary.degradation_velocity_milli / 10), 0, 1000000000);
    int ent = 0;
    for(int j = 1; j < n_ep; j++) {
        if(ep[j].era_id != ep[j - 1].era_id)
            ent = GovSaturatingAdd32(ent, 100000);
    }
    out.governance_entropy_milli = GovClampInt32(ent + rp.brittleness.oscillation_index_0_1000 * 1000, 0, 1000000000);
    out.temporal_instability_milli = GovClampInt32((int)ew_press + out.governance_entropy_milli / 4, 0, 1000000000);
    return true;
}

#endif // __AURUM_GOV_TMP_AGE_ENG_V1_MQH__
