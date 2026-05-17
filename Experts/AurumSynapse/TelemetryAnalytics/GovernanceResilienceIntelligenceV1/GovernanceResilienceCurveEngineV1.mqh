//+------------------------------------------------------------------+
//| GovernanceResilienceCurveEngineV1.mqh                          |
//| Longitudinal resilience curves — integer slopes / half-life.    |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RESILIENCE_CURVE_V1_MQH__
#define __AURUM_GOV_RESILIENCE_CURVE_V1_MQH__

#include "GovernanceResilienceDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernanceTypesV1.mqh"

bool GovResilCurveV1_Build(const SGovReplayTimelineV1 &tl, SGovResilienceCurveV1 &out, string &out_err) {
    out_err = "";
    GovResilDsV1_InitCurve(out);
    const int n = ArraySize(tl.epochs);
    if(n < 2) {
        out.resilience_half_life_epochs = (n == 1) ? 0 : 0;
        return true;
    }
    int s0 = GOV_REPLAY_V1_UNSET_INT;
    int s1 = GOV_REPLAY_V1_UNSET_INT;
    int t0 = GOV_REPLAY_V1_UNSET_INT;
    int t1 = GOV_REPLAY_V1_UNSET_INT;
    int qmax = 0;
    int prev_tox = GOV_REPLAY_V1_UNSET_INT;
    int plateau_seg = 0;
    int stab_rec = 0;
    int prev_sv = GOV_REPLAY_V1_UNSET_INT;
    for(int i = 0; i < n; i++) {
        const int sv = tl.epochs[i].survivability_ms;
        const int tx = tl.epochs[i].toxicity_ms;
        const int qs = tl.epochs[i].quarantine_state == GOV_REPLAY_V1_UNSET_INT ? 0 : tl.epochs[i].quarantine_state;
        if(qs > qmax)
            qmax = qs;
        if(tx != GOV_REPLAY_V1_UNSET_INT) {
            if(prev_tox != GOV_REPLAY_V1_UNSET_INT && tx == prev_tox)
                plateau_seg = GovSaturatingAdd32(plateau_seg, 1);
            prev_tox = tx;
        }
        const int gs = tl.epochs[i].governance_state;
        if(gs == (int)GOV_STATE_RECOVERY && sv != GOV_REPLAY_V1_UNSET_INT && prev_sv != GOV_REPLAY_V1_UNSET_INT && sv > prev_sv)
            stab_rec = GovSaturatingAdd32(stab_rec, 1);
        if(sv != GOV_REPLAY_V1_UNSET_INT)
            prev_sv = sv;
    }
    s0 = tl.epochs[0].survivability_ms;
    s1 = tl.epochs[n - 1].survivability_ms;
    t0 = tl.epochs[0].toxicity_ms;
    t1 = tl.epochs[n - 1].toxicity_ms;
    const int denom = GovClampInt32(n - 1, 1, 1000000);
    if(s0 != GOV_REPLAY_V1_UNSET_INT && s1 != GOV_REPLAY_V1_UNSET_INT)
        out.survivability_decay_slope_milli = ((s1 - s0) * 1000) / denom;
    if(t0 != GOV_REPLAY_V1_UNSET_INT && t1 != GOV_REPLAY_V1_UNSET_INT)
        out.toxicity_rise_slope_milli = ((t1 - t0) * 1000) / denom;
    int p0 = tl.epochs[0].causal_pressure_ms;
    int p1 = tl.epochs[n - 1].causal_pressure_ms;
    if(p0 != GOV_REPLAY_V1_UNSET_INT && p1 != GOV_REPLAY_V1_UNSET_INT)
        out.containment_pressure_slope_milli = ((p1 - p0) * 1000) / denom;
    out.quarantine_saturation_peak = GovClampInt32(qmax, 0, 1000);
    out.plateau_epoch_segments = GovClampInt32(plateau_seg, 0, 1000000);
    out.stabilization_recovery_epochs = GovClampInt32(stab_rec, 0, 1000000);
    out.degradation_velocity_milli = GovClampInt32(-out.survivability_decay_slope_milli, 0, 10000000);
    const int accel = GovClampInt32(out.toxicity_rise_slope_milli - out.survivability_decay_slope_milli, 0, 10000000);
    out.collapse_acceleration_score_0_1000 = GovClampInt32(accel / 10, 0, 1000);
    out.recovery_curve_quality_0_1000 = GovClampInt32(stab_rec * 200 + (1000 - out.collapse_acceleration_score_0_1000) / 2, 0, 1000);
    int half_ix = 0;
    if(s0 != GOV_REPLAY_V1_UNSET_INT && s1 != GOV_REPLAY_V1_UNSET_INT) {
        const int mid = (s0 + s1) / 2;
        half_ix = n - 1;
        for(int j = 0; j < n; j++) {
            const int sj = tl.epochs[j].survivability_ms;
            if(sj != GOV_REPLAY_V1_UNSET_INT && sj <= mid) {
                half_ix = j;
                break;
            }
        }
    }
    out.resilience_half_life_epochs = GovClampInt32(half_ix, 0, n);
    return true;
}

#endif // __AURUM_GOV_RESILIENCE_CURVE_V1_MQH__
