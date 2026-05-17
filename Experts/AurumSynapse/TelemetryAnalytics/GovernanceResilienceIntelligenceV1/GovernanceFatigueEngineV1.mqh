//+------------------------------------------------------------------+
//| GovernanceFatigueEngineV1.mqh                                  |
//| Deterministic governance intervention fatigue (replay-safe).   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_FATIGUE_ENG_V1_MQH__
#define __AURUM_GOV_FATIGUE_ENG_V1_MQH__

#include "GovernanceResilienceDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernanceTypesV1.mqh"

bool GovFatigueV1_Measure(const SGovReplayTimelineV1 &tl, SGovGovernanceFatigueV1 &out, string &out_err) {
    out_err = "";
    GovResilDsV1_InitFatigue(out);
    const int n = ArraySize(tl.epochs);
    if(n < 1)
        return true;
    int ld = 0;
    int thr_esc = 0;
    int flat_n = 0;
    int q_osc = 0;
    int exec0 = 0;
    int rec_bad = 0;
    int prev_th = GOV_REPLAY_V1_UNSET_INT;
    int prev_q = GOV_REPLAY_V1_UNSET_INT;
    int prev_gs = GOV_REPLAY_V1_UNSET_INT;
    for(int i = 0; i < n; i++) {
        const int gs = tl.epochs[i].governance_state;
        if(gs == (int)GOV_STATE_LOCKDOWN)
            ld = GovSaturatingAdd32(ld, 1);
        const int th = tl.epochs[i].throttle_interval_ms;
        if(th != GOV_REPLAY_V1_UNSET_INT && prev_th != GOV_REPLAY_V1_UNSET_INT && th > prev_th)
            thr_esc = GovSaturatingAdd32(thr_esc, 1);
        if(th != GOV_REPLAY_V1_UNSET_INT)
            prev_th = th;
        if(tl.epochs[i].forced_flatten_required == 1)
            flat_n = GovSaturatingAdd32(flat_n, 1);
        const int q = tl.epochs[i].quarantine_state;
        if(q != GOV_REPLAY_V1_UNSET_INT && prev_q != GOV_REPLAY_V1_UNSET_INT && q != prev_q)
            q_osc = GovSaturatingAdd32(q_osc, 1);
        if(q != GOV_REPLAY_V1_UNSET_INT)
            prev_q = q;
        if(tl.epochs[i].execution_allowed == 0)
            exec0 = GovSaturatingAdd32(exec0, 1);
        if(prev_gs == (int)GOV_STATE_RECOVERY && (gs == (int)GOV_STATE_CAUTION || gs == (int)GOV_STATE_DEFENSIVE || gs == (int)GOV_STATE_SURVIVAL))
            rec_bad = GovSaturatingAdd32(rec_bad, 1);
        if(gs != GOV_REPLAY_V1_UNSET_INT)
            prev_gs = gs;
    }
    out.lockdown_density_per_1000 = GovClampInt32((ld * 1000) / n, 0, 1000);
    out.throttle_escalation_persistence_0_1000 = GovClampInt32(thr_esc * 150, 0, 1000);
    out.flatten_accumulation_0_1000 = GovClampInt32(flat_n * 120, 0, 1000);
    out.quarantine_reuse_pressure_0_1000 = GovClampInt32(q_osc * 100, 0, 1000);
    out.execution_suppression_fatigue_per_1000 = GovClampInt32((exec0 * 1000) / n, 0, 1000);
    out.recovery_instability_0_1000 = GovClampInt32(rec_bad * 200, 0, 1000);
    int comp = 0;
    comp = GovSaturatingAdd32(comp, out.lockdown_density_per_1000 / 6);
    comp = GovSaturatingAdd32(comp, out.throttle_escalation_persistence_0_1000 / 6);
    comp = GovSaturatingAdd32(comp, out.flatten_accumulation_0_1000 / 6);
    comp = GovSaturatingAdd32(comp, out.quarantine_reuse_pressure_0_1000 / 6);
    comp = GovSaturatingAdd32(comp, out.execution_suppression_fatigue_per_1000 / 6);
    comp = GovSaturatingAdd32(comp, out.recovery_instability_0_1000 / 6);
    out.fatigue_composite_0_1000 = GovClampInt32(comp, 0, 1000);
    return true;
}

#endif // __AURUM_GOV_FATIGUE_ENG_V1_MQH__
