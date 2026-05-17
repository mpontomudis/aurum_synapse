//+------------------------------------------------------------------+
//| GovernanceRegimeMetaAnalyticsV1.mqh                             |
//| Deterministic regime accounting over replay epochs.              |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REGIME_META_ANALYTICS_V1_MQH__
#define __AURUM_GOV_REGIME_META_ANALYTICS_V1_MQH__

#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceEvidenceIntegrationV1/GovernanceRegimeClassifierV1.mqh"
#include "../GovernanceStateMachineV1/GovernanceTypesV1.mqh"
#include "GovernanceMetaAnalyticsDatasetV1.mqh"

bool GovernanceRegimeMetaAnalyticsV1_Compute(const SGovReplayTimelineV1 &t, SGovMetaRegimeStatsV1 &out, string &out_err) {
    out_err = "";
    GovernanceMetaAnalyticsDatasetV1_InitRegimeStats(out);
    const int n = ArraySize(t.epochs);
    if(n < 1)
        return true;
    int prev_rg = GOV_REPLAY_V1_UNSET_INT;
    int run_len = 0;
    int max_run = 0;
    int churn = 0;
    int struct_hits = 0;
    int fragile_enters = 0;
    int recovery_epochs = 0;
    int max_tox = 0;
    int peak_ix = 0;
    for(int i = 0; i < n; i++) {
        const int rg = t.epochs[i].regime_state;
        if(rg != GOV_REPLAY_V1_UNSET_INT) {
            if(prev_rg != GOV_REPLAY_V1_UNSET_INT && rg != prev_rg)
                churn = GovSaturatingAdd32(churn, 1);
            if(prev_rg != GOV_REPLAY_V1_UNSET_INT && rg == (int)GOV_MR_V1_FRAGILE && prev_rg != (int)GOV_MR_V1_FRAGILE)
                fragile_enters = GovSaturatingAdd32(fragile_enters, 1);
            if(rg == (int)GOV_MR_V1_STRUCTURAL_BREAKDOWN)
                struct_hits = GovSaturatingAdd32(struct_hits, 1);
            if(rg == (int)GOV_MR_V1_RECOVERY_WINDOW)
                recovery_epochs = GovSaturatingAdd32(recovery_epochs, 1);
            if(prev_rg == GOV_REPLAY_V1_UNSET_INT || rg == prev_rg)
                run_len = GovSaturatingAdd32(run_len, 1);
            else
                run_len = 1;
            if(run_len > max_run)
                max_run = run_len;
            prev_rg = rg;
        }
        const int tx = t.epochs[i].toxicity_ms;
        if(tx != GOV_REPLAY_V1_UNSET_INT && tx > max_tox) {
            max_tox = tx;
            peak_ix = i;
        }
    }
    out.regime_persistence_max_epochs = max_run;
    out.regime_churn_count = churn;
    out.structural_breakdown_frequency_per_1000_epochs = GovernanceMetaAnalyticsDatasetV1_RatePer1000(struct_hits, n);
    out.fragile_regime_recurrence_count = fragile_enters;
    int half_life = 0;
    if(max_tox > 0) {
        const int half = max_tox / 2;
        for(int j = peak_ix; j < n; j++) {
            const int tx2 = t.epochs[j].toxicity_ms;
            if(tx2 != GOV_REPLAY_V1_UNSET_INT && tx2 <= half) {
                half_life = j - peak_ix;
                break;
            }
        }
        if(half_life == 0 && peak_ix < n - 1)
            half_life = n - peak_ix;
    }
    out.toxic_regime_half_life_epochs = half_life;
    out.recovery_regime_stabilization_epochs = recovery_epochs;
    out.recovery_stabilization_score_0_1000 = GovClampInt32(recovery_epochs * 1000 / GovClampInt32(n, 1, 1000000), 0, 1000);
    return true;
}

bool GovernanceRegimeMetaAnalyticsV1_LockdownRuns(const SGovReplayTimelineV1 &t, int &out_avg_lockdown_epochs, string &out_err) {
    out_err = "";
    out_avg_lockdown_epochs = 0;
    const int n = ArraySize(t.epochs);
    int runs = 0;
    int sum = 0;
    int cur = 0;
    for(int i = 0; i < n; i++) {
        const int gs = t.epochs[i].governance_state;
        if(gs == (int)GOV_STATE_LOCKDOWN) {
            cur = GovSaturatingAdd32(cur, 1);
        } else {
            if(cur > 0) {
                runs = GovSaturatingAdd32(runs, 1);
                sum = GovSaturatingAdd32(sum, cur);
            }
            cur = 0;
        }
    }
    if(cur > 0) {
        runs = GovSaturatingAdd32(runs, 1);
        sum = GovSaturatingAdd32(sum, cur);
    }
    if(runs > 0)
        out_avg_lockdown_epochs = sum / runs;
    return true;
}

#endif // __AURUM_GOV_REGIME_META_ANALYTICS_V1_MQH__
