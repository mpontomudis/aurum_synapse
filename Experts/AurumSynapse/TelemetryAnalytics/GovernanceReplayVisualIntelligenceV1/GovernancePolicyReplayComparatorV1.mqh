//+------------------------------------------------------------------+
//| GovernancePolicyReplayComparatorV1.mqh                        |
//| Deterministic forensic deltas between two replay timelines.     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_POLICY_REPLAY_COMPARATOR_V1_MQH__
#define __AURUM_GOV_POLICY_REPLAY_COMPARATOR_V1_MQH__

#include "GovernanceReplayDatasetV1.mqh"

struct SGovPolicyReplayDeltaV1 {
    int epoch_count_delta;
    int gs_transition_delta;
    int avg_throttle_delta_milli;
    int quarantine_hard_delta;
    int forced_flatten_delta;
    int execution_denied_delta;
};

void GovernancePolicyReplayComparatorV1_InitDelta(SGovPolicyReplayDeltaV1 &d) {
    d.epoch_count_delta = 0;
    d.gs_transition_delta = 0;
    d.avg_throttle_delta_milli = 0;
    d.quarantine_hard_delta = 0;
    d.forced_flatten_delta = 0;
    d.execution_denied_delta = 0;
}

int GovPolicyReplayComparatorV1_CountGsTransitions(const SGovReplayTimelineV1 &t) {
    int c = 0;
    int prev = GOV_REPLAY_V1_UNSET_INT;
    const int n = ArraySize(t.epochs);
    for(int i = 0; i < n; i++) {
        const int g = t.epochs[i].governance_state;
        if(g == GOV_REPLAY_V1_UNSET_INT)
            continue;
        if(prev != GOV_REPLAY_V1_UNSET_INT && g != prev)
            c = GovSaturatingAdd32(c, 1);
        prev = g;
    }
    return c;
}

int GovPolicyReplayComparatorV1_AvgThrottle(const SGovReplayTimelineV1 &t) {
    long acc = 0;
    int k = 0;
    const int n = ArraySize(t.epochs);
    for(int i = 0; i < n; i++) {
        const int th = t.epochs[i].throttle_interval_ms;
        if(th == GOV_REPLAY_V1_UNSET_INT)
            continue;
        acc += (long)th;
        k++;
    }
    if(k <= 0)
        return 0;
    return (int)(acc / (long)k);
}

int GovPolicyReplayComparatorV1_CountExecDenied(const SGovReplayTimelineV1 &t) {
    int c = 0;
    const int n = ArraySize(t.epochs);
    for(int i = 0; i < n; i++) {
        if(t.epochs[i].execution_allowed == 0)
            c = GovSaturatingAdd32(c, 1);
    }
    return c;
}

int GovPolicyReplayComparatorV1_CountQuarHard(const SGovReplayTimelineV1 &t) {
    int c = 0;
    const int n = ArraySize(t.epochs);
    for(int i = 0; i < n; i++) {
        if(t.epochs[i].quarantine_state >= 2)
            c = GovSaturatingAdd32(c, 1);
    }
    return c;
}

int GovPolicyReplayComparatorV1_CountFlatten(const SGovReplayTimelineV1 &t) {
    int c = 0;
    const int n = ArraySize(t.epochs);
    for(int i = 0; i < n; i++) {
        if(t.epochs[i].forced_flatten_required == 1)
            c = GovSaturatingAdd32(c, 1);
    }
    return c;
}

bool GovernancePolicyReplayComparatorV1_Compare(const SGovReplayTimelineV1 &a,
                                               const SGovReplayTimelineV1 &b,
                                               SGovPolicyReplayDeltaV1 &out_delta,
                                               string &out_report) {
    GovernancePolicyReplayComparatorV1_InitDelta(out_delta);
    out_report = "GOV_POL_DELTA_V1";
    out_delta.epoch_count_delta = ArraySize(a.epochs) - ArraySize(b.epochs);
    out_delta.gs_transition_delta = GovPolicyReplayComparatorV1_CountGsTransitions(a) -
                                    GovPolicyReplayComparatorV1_CountGsTransitions(b);
    out_delta.avg_throttle_delta_milli = GovPolicyReplayComparatorV1_AvgThrottle(a) -
                                         GovPolicyReplayComparatorV1_AvgThrottle(b);
    out_delta.quarantine_hard_delta = GovPolicyReplayComparatorV1_CountQuarHard(a) -
                                     GovPolicyReplayComparatorV1_CountQuarHard(b);
    out_delta.forced_flatten_delta = GovPolicyReplayComparatorV1_CountFlatten(a) -
                                    GovPolicyReplayComparatorV1_CountFlatten(b);
    out_delta.execution_denied_delta = GovPolicyReplayComparatorV1_CountExecDenied(a) -
                                      GovPolicyReplayComparatorV1_CountExecDenied(b);
    out_report += "|epochs=" + IntegerToString(out_delta.epoch_count_delta);
    out_report += "|gs_tr=" + IntegerToString(out_delta.gs_transition_delta);
    out_report += "|thr_avg=" + IntegerToString(out_delta.avg_throttle_delta_milli);
    out_report += "|q_hard=" + IntegerToString(out_delta.quarantine_hard_delta);
    out_report += "|ff=" + IntegerToString(out_delta.forced_flatten_delta);
    out_report += "|ex_den=" + IntegerToString(out_delta.execution_denied_delta);
    return true;
}

#endif // __AURUM_GOV_POLICY_REPLAY_COMPARATOR_V1_MQH__
