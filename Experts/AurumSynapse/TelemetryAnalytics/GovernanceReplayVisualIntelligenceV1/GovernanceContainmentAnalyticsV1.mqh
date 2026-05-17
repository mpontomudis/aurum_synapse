//+------------------------------------------------------------------+
//| GovernanceContainmentAnalyticsV1.mqh                         |
//| Integer-first containment metrics over replay epochs.          |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CONTAINMENT_ANALYTICS_V1_MQH__
#define __AURUM_GOV_CONTAINMENT_ANALYTICS_V1_MQH__

#include "GovernanceReplayDatasetV1.mqh"

struct SGovContainmentMetricsV1 {
    int prevented_escalation_epochs;
    int exposure_compression_sum_milli;
    int survivability_preservation_score_0_1000;
    int toxic_interrupt_epochs;
    int quarantine_hard_epoch_hits;
    int forced_flatten_count;
    int throttle_containment_score_0_1000;
};

void GovernanceContainmentAnalyticsV1_Init(SGovContainmentMetricsV1 &m) {
    m.prevented_escalation_epochs = 0;
    m.exposure_compression_sum_milli = 0;
    m.survivability_preservation_score_0_1000 = 0;
    m.toxic_interrupt_epochs = 0;
    m.quarantine_hard_epoch_hits = 0;
    m.forced_flatten_count = 0;
    m.throttle_containment_score_0_1000 = 0;
}

bool GovernanceContainmentAnalyticsV1_Compute(const SGovReplayTimelineV1 &t, SGovContainmentMetricsV1 &out, string &out_err) {
    out_err = "";
    GovernanceContainmentAnalyticsV1_Init(out);
    const int n = ArraySize(t.epochs);
    int prev_ex = GOV_REPLAY_V1_UNSET_INT;
    long thr_acc = 0;
    int thr_n = 0;
    int min_surv = GOV_REPLAY_V1_UNSET_INT;
    for(int i = 0; i < n; i++) {
        const int ex = t.epochs[i].execution_allowed;
        if(prev_ex == 1 && ex == 0)
            out.prevented_escalation_epochs = GovSaturatingAdd32(out.prevented_escalation_epochs, 1);
        prev_ex = ex;
        const int cap = t.epochs[i].exposure_cap_milli;
        if(cap != GOV_REPLAY_V1_UNSET_INT)
            out.exposure_compression_sum_milli = GovSaturatingAdd32(out.exposure_compression_sum_milli,
                                                                    GovClampInt32(1000000 - GovClampInt32(cap, 0, 1000000), 0, 1000000));
        const int qs = t.epochs[i].quarantine_state;
        if(qs >= 1)
            out.toxic_interrupt_epochs = GovSaturatingAdd32(out.toxic_interrupt_epochs, 1);
        if(qs >= 2)
            out.quarantine_hard_epoch_hits = GovSaturatingAdd32(out.quarantine_hard_epoch_hits, 1);
        if(t.epochs[i].forced_flatten_required == 1)
            out.forced_flatten_count = GovSaturatingAdd32(out.forced_flatten_count, 1);
        const int th = t.epochs[i].throttle_interval_ms;
        if(th != GOV_REPLAY_V1_UNSET_INT) {
            thr_acc += (long)th;
            thr_n++;
        }
        const int sv = t.epochs[i].survivability_ms;
        if(sv != GOV_REPLAY_V1_UNSET_INT) {
            if(min_surv == GOV_REPLAY_V1_UNSET_INT || sv < min_surv)
                min_surv = sv;
        }
    }
    if(min_surv != GOV_REPLAY_V1_UNSET_INT)
        out.survivability_preservation_score_0_1000 = GovClampInt32(min_surv * 10, 0, 1000);
    if(thr_n > 0) {
        const long avg_long = thr_acc / (long)thr_n;
        const int avg = GovSaturateLongToInt32(avg_long);
        out.throttle_containment_score_0_1000 = GovClampInt32(avg / 10, 0, 1000);
    }
    return true;
}

#endif // __AURUM_GOV_CONTAINMENT_ANALYTICS_V1_MQH__
