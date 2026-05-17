//+------------------------------------------------------------------+
//| GovernanceEcologicalCollapseV1.mqh                              |
//| GOVERNANCE_ECOLOGY_INTELLIGENCE_V1 — collapse propagation        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECO_COLLAPSE_V1_MQH__
#define __AURUM_GOV_ECO_COLLAPSE_V1_MQH__

#include "GovernanceEcologyDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "GovernancePredatorPreyV1.mqh"

bool GovEcoCollapseV1_Analyze(const SGovReplayTimelineV1 &tl, const SGovEcologyEntityV1 &ents[], const int n_ent, const SGovEcologyBiodiversityV1 &bio, const SGovEcologyPredPreyV1 &pred, SGovEcologyCollapseV1 &out, string &out_err) {
    out_err = "";
    GovEcoDsV1_InitCollapse(out);
    const int ne = GovClampInt32(n_ent, 0, 64);
    if(ne <= 0)
        return true;
    int sum_ce = 0;
    int mx_ce = 0;
    int mn_sv = 1000000000;
    for(int k = 0; k < ne; k++) {
        sum_ce = GovSaturatingAdd32(sum_ce, ents[k].collapse_exposure_milli);
        mx_ce = MathMax(mx_ce, ents[k].collapse_exposure_milli);
        mn_sv = MathMin(mn_sv, ents[k].survivability_milli);
    }
    const int avg_ce = sum_ce / ne;
    out.cascading_collapse_milli = GovClampInt32(GovSaturatingAdd32(pred.collapse_propagation_milli, GovSaturatingAdd32(mx_ce, -avg_ce)), 0, 1000000000);
    const int n = GovClampInt32(ArraySize(tl.epochs), 0, GOV_REPLAY_V1_MAX_EPOCHS);
    int sync_bad = 0;
    for(int i = 1; i < n; i++) {
        const int t0 = GovClampInt32(tl.epochs[i - 1].toxicity_ms, 0, 100000);
        const int t1 = GovClampInt32(tl.epochs[i].toxicity_ms, 0, 100000);
        if(t0 > 5000 && t1 > 5000)
            sync_bad++;
    }
    out.synchronized_failure_milli = GovClampInt32((n > 1) ? (sync_bad * 1000000) / (n - 1) : 0, 0, 1000000000);
    out.ecosystem_instability_milli = GovClampInt32(GovSaturatingAdd32(bio.ecosystem_concentration_risk_milli, (1000000 - bio.diversity_score_milli) / 2), 0, 1000000000);
    out.biodiversity_collapse_milli = GovClampInt32(GovSaturatingAdd32((1000000 - bio.diversity_score_milli) / 2, bio.ecosystem_concentration_risk_milli), 0, 1000000000);
    out.resilience_extinction_milli = GovClampInt32(GovSaturatingAdd32((1000000 - mn_sv), avg_ce / 2), 0, 1000000000);
    out.collapse_contagion_milli = GovClampInt32(GovSaturatingAdd32(pred.pressure_transfer_milli / 2, out.cascading_collapse_milli / 2), 0, 1000000000);
    return true;
}

#endif // __AURUM_GOV_ECO_COLLAPSE_V1_MQH__
