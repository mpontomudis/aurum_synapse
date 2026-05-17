//+------------------------------------------------------------------+
//| GovernancePolicyBehaviorFingerprintV1.mqh                     |
//| Deterministic archetype flags from replay epoch aggregates.      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_POLICY_BEHAVIOR_FINGERPRINT_V1_MQH__
#define __AURUM_GOV_POLICY_BEHAVIOR_FINGERPRINT_V1_MQH__

#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceContainmentAnalyticsV1.mqh"
#include "GovernanceMetaAnalyticsDatasetV1.mqh"

bool GovernancePolicyBehaviorFingerprintV1_Compute(const SGovReplayTimelineV1 &t, const SGovContainmentMetricsV1 &cm, SGovMetaPolicyFingerprintV1 &out, string &out_err) {
    out_err = "";
    GovernanceMetaAnalyticsDatasetV1_InitFingerprint(out);
    const int n = ArraySize(t.epochs);
    int surv_min = GOV_REPLAY_V1_UNSET_INT;
    string best_fp = "";
    for(int i = 0; i < n; i++) {
        const SGovReplayEpochV1 e = t.epochs[i];
        if(e.survivability_ms != GOV_REPLAY_V1_UNSET_INT) {
            if(surv_min == GOV_REPLAY_V1_UNSET_INT || e.survivability_ms < surv_min)
                surv_min = e.survivability_ms;
        }
        const string p = e.policy_fingerprint;
        if(StringLen(p) > 0 && (StringLen(best_fp) == 0 || p > best_fp))
            best_fp = p;
    }
    out.dominant_policy_fingerprint = best_fp;
    int flags = 0;
    if(cm.quarantine_hard_epoch_hits * 3 >= n && n > 0)
        flags |= GOV_META_V1_FLAG_ARCH_QUARANTINE_HEAVY;
    if(cm.throttle_containment_score_0_1000 >= 600)
        flags |= GOV_META_V1_FLAG_ARCH_THROTTLE_HEAVY;
    if(cm.forced_flatten_count * 5 >= n && n > 0)
        flags |= GOV_META_V1_FLAG_ARCH_FLATTEN_AGGRESSIVE;
    if(surv_min != GOV_REPLAY_V1_UNSET_INT && surv_min >= 4000)
        flags |= GOV_META_V1_FLAG_ARCH_SURVIVABILITY_FIRST;
    if(cm.prevented_escalation_epochs * 4 >= n && n > 0)
        flags |= GOV_META_V1_FLAG_ARCH_AGGRESSIVE_CONTAIN;
    int rec_deny = 0;
    for(int j = 0; j < n; j++) {
        if(t.epochs[j].recovery_allowed == 0)
            rec_deny = GovSaturatingAdd32(rec_deny, 1);
    }
    if(rec_deny * 3 >= n && n > 0)
        flags |= GOV_META_V1_FLAG_ARCH_RECOVERY_CONSERV;
    out.archetype_flags = flags;
    out.archetype_primary_code = 0;
    int best_w = -1;
    int cand_code[6];
    int cand_w[6];
    cand_code[0] = 1;
    cand_code[1] = 2;
    cand_code[2] = 4;
    cand_code[3] = 8;
    cand_code[4] = 16;
    cand_code[5] = 32;
    cand_w[0] = (flags & GOV_META_V1_FLAG_ARCH_AGGRESSIVE_CONTAIN) != 0 ? 5 : 0;
    cand_w[1] = (flags & GOV_META_V1_FLAG_ARCH_SURVIVABILITY_FIRST) != 0 ? 4 : 0;
    cand_w[2] = (flags & GOV_META_V1_FLAG_ARCH_QUARANTINE_HEAVY) != 0 ? 6 : 0;
    cand_w[3] = (flags & GOV_META_V1_FLAG_ARCH_THROTTLE_HEAVY) != 0 ? 3 : 0;
    cand_w[4] = (flags & GOV_META_V1_FLAG_ARCH_RECOVERY_CONSERV) != 0 ? 4 : 0;
    cand_w[5] = (flags & GOV_META_V1_FLAG_ARCH_FLATTEN_AGGRESSIVE) != 0 ? 5 : 0;
    for(int k = 0; k < 6; k++) {
        if(cand_w[k] > best_w) {
            best_w = cand_w[k];
            out.archetype_primary_code = cand_code[k];
        }
    }
    out.policy_behavior_fingerprint = "ARCH_FLAGS=" + IntegerToString(flags);
    out.policy_behavior_fingerprint += "|PRIMARY=" + IntegerToString(out.archetype_primary_code);
    out.policy_behavior_fingerprint += "|DOM_FP=" + best_fp;
    return true;
}

#endif // __AURUM_GOV_POLICY_BEHAVIOR_FINGERPRINT_V1_MQH__
