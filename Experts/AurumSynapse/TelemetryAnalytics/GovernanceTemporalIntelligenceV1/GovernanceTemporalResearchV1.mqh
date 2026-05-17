//+------------------------------------------------------------------+
//| GovernanceTemporalResearchV1.mqh                               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_TMP_RES_V1_MQH__
#define __AURUM_GOV_TMP_RES_V1_MQH__

#include "GovernanceTemporalDatasetV1.mqh"

bool GovTmpResV1_IxBetterEp(const SGovTemporalEpochV1 &ep[], const int ia, const int ib) {
    if(ep[ia].survivability_score_milli != ep[ib].survivability_score_milli)
        return (ep[ia].survivability_score_milli > ep[ib].survivability_score_milli);
    if(ep[ia].continuity_score_milli != ep[ib].continuity_score_milli)
        return (ep[ia].continuity_score_milli > ep[ib].continuity_score_milli);
    const int end_a = GovSaturatingAdd32(ep[ia].continuity_score_milli, -ep[ia].decay_velocity_milli / 4);
    const int end_b = GovSaturatingAdd32(ep[ib].continuity_score_milli, -ep[ib].decay_velocity_milli / 4);
    if(end_a != end_b)
        return (end_a > end_b);
    const int res_a = GovClampInt32(1000000 - ep[ia].collapse_risk_milli, 0, 1000000);
    const int res_b = GovClampInt32(1000000 - ep[ib].collapse_risk_milli, 0, 1000000);
    if(res_a != res_b)
        return (res_a > res_b);
    return (ep[ia].epoch_id < ep[ib].epoch_id);
}

bool GovTmpResV1_RankEpochs(const SGovTemporalEpochV1 &ep[], const int n_ep, int &ix_rank[], string &out_err) {
    out_err = "";
    if(n_ep < 1 || n_ep > 128) {
        out_err = "GOV_TMP_RES_N";
        return false;
    }
    for(int i = 0; i < n_ep; i++)
        ix_rank[i] = i;
    for(int i = 0; i < n_ep; i++) {
        int best = i;
        for(int j = i + 1; j < n_ep; j++) {
            if(GovTmpResV1_IxBetterEp(ep, ix_rank[j], ix_rank[best]))
                best = j;
        }
        const int t = ix_rank[i];
        ix_rank[i] = ix_rank[best];
        ix_rank[best] = t;
    }
    return true;
}

#endif // __AURUM_GOV_TMP_RES_V1_MQH__
