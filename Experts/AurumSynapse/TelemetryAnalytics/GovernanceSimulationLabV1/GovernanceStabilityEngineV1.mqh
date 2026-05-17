//+------------------------------------------------------------------+
//| GovernanceStabilityEngineV1.mqh                               |
//| Integer stability metrics from replay + containment.            |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STABILITY_ENG_V1_MQH__
#define __AURUM_GOV_STABILITY_ENG_V1_MQH__

#include "GovernanceSimulationDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceContainmentAnalyticsV1.mqh"
#include "../GovernanceMetaAnalyticsV1/GovernanceRegimeMetaAnalyticsV1.mqh"
#include "../GovernanceMetaAnalyticsV1/GovernanceMetaAnalyticsDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

bool GovStabEngV1_Measure(const SGovReplayTimelineV1 &tl, SGovSimStabilityMetricsV1 &out, string &out_err) {
    out_err = "";
    GovSimDsV1_InitStab(out);
    SGovContainmentMetricsV1 cm;
    if(!GovernanceContainmentAnalyticsV1_Compute(tl, cm, out_err))
        return false;
    SGovMetaRegimeStatsV1 rg;
    if(!GovernanceRegimeMetaAnalyticsV1_Compute(tl, rg, out_err))
        return false;
    out.replay_stability_0_1000 = (tl.integrity_ok != 0) ? 1000 : 400;
    const int n = ArraySize(tl.epochs);
    int gs_run = 0;
    int prev_gs = GOV_REPLAY_V1_UNSET_INT;
    for(int i = 0; i < n; i++) {
        const int g = tl.epochs[i].governance_state;
        if(g != GOV_REPLAY_V1_UNSET_INT) {
            if(prev_gs == GOV_REPLAY_V1_UNSET_INT || g == prev_gs)
                gs_run = GovSaturatingAdd32(gs_run, 1);
            else
                gs_run = 1;
            prev_gs = g;
        }
    }
    out.governance_consistency_0_1000 = GovClampInt32(gs_run * 200, 0, 1000);
    out.containment_resilience_0_1000 = GovClampInt32(cm.survivability_preservation_score_0_1000, 0, 1000);
    int min_sv = GOV_REPLAY_V1_UNSET_INT;
    for(int j = 0; j < n; j++) {
        const int sv = tl.epochs[j].survivability_ms;
        if(sv != GOV_REPLAY_V1_UNSET_INT) {
            if(min_sv == GOV_REPLAY_V1_UNSET_INT || sv < min_sv)
                min_sv = sv;
        }
    }
    out.survivability_robustness_0_1000 = (min_sv != GOV_REPLAY_V1_UNSET_INT) ? GovClampInt32(min_sv / 5, 0, 1000) : 0;
    int q_osc = 0;
    int pq = GOV_REPLAY_V1_UNSET_INT;
    for(int k = 0; k < n; k++) {
        const int q = tl.epochs[k].quarantine_state;
        if(q != GOV_REPLAY_V1_UNSET_INT && pq != GOV_REPLAY_V1_UNSET_INT && q != pq)
            q_osc = GovSaturatingAdd32(q_osc, 1);
        if(q != GOV_REPLAY_V1_UNSET_INT)
            pq = q;
    }
    out.quarantine_oscillation_0_1000 = GovClampInt32(1000 - q_osc * 80, 0, 1000);
    out.regime_churn_stability_0_1000 = GovClampInt32(1000 - rg.regime_churn_count * 50, 0, 1000);
    out.flatten_containment_efficiency_0_1000 = GovClampInt32(1000 - cm.forced_flatten_count * 100, 0, 1000);
    out.intervention_coherence_0_1000 = GovClampInt32(cm.prevented_escalation_epochs * 120 + cm.toxic_interrupt_epochs * 40, 0, 1000);
    return true;
}

int GovStabEngV1_HealthProxy(const SGovSimStabilityMetricsV1 &m) {
    return GovClampInt32(GovSimDsV1_StabSum(m) / 8, 0, 1000);
}

#endif // __AURUM_GOV_STABILITY_ENG_V1_MQH__
