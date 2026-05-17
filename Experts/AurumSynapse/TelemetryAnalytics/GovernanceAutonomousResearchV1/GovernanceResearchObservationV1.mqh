//+------------------------------------------------------------------+
//| GovernanceResearchObservationV1.mqh                            |
//| Deterministic observation rows (threshold rules only).           |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RESEARCH_OBSERVATION_V1_MQH__
#define __AURUM_GOV_RESEARCH_OBSERVATION_V1_MQH__

#include "GovernanceResearchDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceMetaAnalyticsV1/GovernanceMetaAnalyticsDatasetV1.mqh"
#include "../GovernanceIncidentIntelligenceV1/GovernanceIncidentDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "../GovernanceEvidenceIntegrationV1/GovernanceRegimeClassifierV1.mqh"
#include "../GovernanceStateMachineV1/GovernanceTypesV1.mqh"

void GovResObsV1_Push(SGovResearchSummaryV1 &s, const int code, const int inten, const string det) {
    const int n = ArraySize(s.obs);
    ArrayResize(s.obs, n + 1);
    s.obs[n].code = code;
    s.obs[n].intensity_0_1000 = GovClampInt32(inten, 0, 1000);
    s.obs[n].detail = det;
}

bool GovResObsV1_Scan(const SGovReplayTimelineV1 &tl, const SGovMetaIncidentStatsV1 &inc, const SGovIncidentSummaryV1 &isum, SGovResearchSummaryV1 &s, string &out_err) {
    out_err = "";
    ArrayResize(s.obs, 0);
    const int ne = ArraySize(tl.epochs);
    if(inc.toxic_spiral_frequency_per_1000_epochs >= 200)
        GovResObsV1_Push(s, GOV_RES_OBS_V1_TOX_RECUR, inc.toxic_spiral_frequency_per_1000_epochs, "TOX_RECUR");
    int ld_ep = 0;
    for(int i = 0; i < ne; i++) {
        if(tl.epochs[i].governance_state == (int)GOV_STATE_LOCKDOWN)
            ld_ep = GovSaturatingAdd32(ld_ep, 1);
    }
    if(ld_ep * 10 >= GovClampInt32(ne, 1, 1000000) * 3)
        GovResObsV1_Push(s, GOV_RES_OBS_V1_LOCK_CHURN, GovClampInt32(ld_ep * 1000 / GovClampInt32(ne, 1, 1000000), 0, 1000), "LOCK_CHURN");
    int frag_ep = 0;
    for(int j = 0; j < ne; j++) {
        if(tl.epochs[j].regime_state == (int)GOV_MR_V1_FRAGILE)
            frag_ep = GovSaturatingAdd32(frag_ep, 1);
    }
    if(frag_ep * 2 >= ne && ne > 0)
        GovResObsV1_Push(s, GOV_RES_OBS_V1_FRAG_PERSIST, GovClampInt32(frag_ep * 1000 / ne, 0, 1000), "FRAG_PERSIST");
    if(inc.containment_success_rate_0_1000 < 400 && inc.raw_incident_total > 0)
        GovResObsV1_Push(s, GOV_RES_OBS_V1_CTN_DEGRADE, 1000 - inc.containment_success_rate_0_1000, "CTN_DEG");
    int surv_drop = 0;
    int prev_sv = GOV_REPLAY_V1_UNSET_INT;
    for(int k = 0; k < ne; k++) {
        const int sv = tl.epochs[k].survivability_ms;
        if(sv != GOV_REPLAY_V1_UNSET_INT && prev_sv != GOV_REPLAY_V1_UNSET_INT && sv < prev_sv - 500)
            surv_drop = GovSaturatingAdd32(surv_drop, 1);
        if(sv != GOV_REPLAY_V1_UNSET_INT)
            prev_sv = sv;
    }
    if(surv_drop >= 2)
        GovResObsV1_Push(s, GOV_RES_OBS_V1_SURV_DECAY, GovClampInt32(surv_drop * 200, 0, 1000), "SURV_DECAY");
    if(inc.quarantine_frequency_per_1000_epochs >= 600)
        GovResObsV1_Push(s, GOV_RES_OBS_V1_QUAR_SAT, inc.quarantine_frequency_per_1000_epochs, "QUAR_SAT");
    int sc = 0;
    const int ni = ArraySize(isum.events);
    for(int t = 0; t < ni; t++) {
        if(isum.events[t].incident_type == (int)GOV_INCIDENT_V1_SURV_COLLAPSE)
            sc = GovSaturatingAdd32(sc, 1);
    }
    if(sc >= 2)
        GovResObsV1_Push(s, GOV_RES_OBS_V1_SURV_COLL_REP, GovClampInt32(sc * 300, 0, 1000), "SURV_COLL_RECUR");
    return true;
}

#endif // __AURUM_GOV_RESEARCH_OBSERVATION_V1_MQH__
