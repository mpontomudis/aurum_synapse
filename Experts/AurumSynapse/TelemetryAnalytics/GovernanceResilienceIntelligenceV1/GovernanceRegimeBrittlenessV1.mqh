//+------------------------------------------------------------------+
//| GovernanceRegimeBrittlenessV1.mqh                            |
//| Regime churn / fragile persistence — deterministic scores.       |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_BRITTLE_V1_MQH__
#define __AURUM_GOV_BRITTLE_V1_MQH__

#include "GovernanceResilienceDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceMetaAnalyticsV1/GovernanceMetaAnalyticsDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernanceTypesV1.mqh"

bool GovBrittleV1_Measure(const SGovReplayTimelineV1 &tl, const SGovMetaRegimeStatsV1 &reg, SGovRegimeBrittlenessV1 &out, string &out_err) {
    out_err = "";
    GovResilDsV1_InitBrittle(out);
    const int n = ArraySize(tl.epochs);
    int q_osc = 0;
    int rg_osc = 0;
    int prev_q = GOV_REPLAY_V1_UNSET_INT;
    int prev_rg = GOV_REPLAY_V1_UNSET_INT;
    int stab_run = 0;
    int max_stab = 0;
    int prev_gs = GOV_REPLAY_V1_UNSET_INT;
    for(int i = 0; i < n; i++) {
        const int q = tl.epochs[i].quarantine_state;
        if(q != GOV_REPLAY_V1_UNSET_INT && prev_q != GOV_REPLAY_V1_UNSET_INT && q != prev_q)
            q_osc = GovSaturatingAdd32(q_osc, 1);
        if(q != GOV_REPLAY_V1_UNSET_INT)
            prev_q = q;
        const int rg = tl.epochs[i].regime_state;
        if(rg != GOV_REPLAY_V1_UNSET_INT && prev_rg != GOV_REPLAY_V1_UNSET_INT && rg != prev_rg)
            rg_osc = GovSaturatingAdd32(rg_osc, 1);
        if(rg != GOV_REPLAY_V1_UNSET_INT)
            prev_rg = rg;
        const int gs = tl.epochs[i].governance_state;
        if(gs == (int)GOV_STATE_RECOVERY) {
            if(prev_gs == (int)GOV_STATE_RECOVERY)
                stab_run = GovSaturatingAdd32(stab_run, 1);
            else
                stab_run = 1;
            if(stab_run > max_stab)
                max_stab = stab_run;
        } else
            stab_run = 0;
        if(gs != GOV_REPLAY_V1_UNSET_INT)
            prev_gs = gs;
    }
    out.oscillation_index_0_1000 = GovClampInt32(q_osc * 90 + rg_osc * 70, 0, 1000);
    out.regime_half_life_epochs = GovClampInt32(reg.toxic_regime_half_life_epochs, 0, 1000000);
    out.stabilization_persistence_0_1000 = GovClampInt32(max_stab * 200 + reg.recovery_regime_stabilization_epochs * 40, 0, 1000);
    int brittle = 0;
    brittle = GovSaturatingAdd32(brittle, GovClampInt32(reg.regime_churn_count * 80, 0, 400));
    brittle = GovSaturatingAdd32(brittle, GovClampInt32(reg.fragile_regime_recurrence_count * 100, 0, 400));
    brittle = GovSaturatingAdd32(brittle, GovClampInt32(reg.structural_breakdown_frequency_per_1000_epochs, 0, 300));
    brittle = GovSaturatingAdd32(brittle, out.oscillation_index_0_1000 / 4);
    out.brittleness_score_0_1000 = GovClampInt32(brittle, 0, 1000);
    return true;
}

#endif // __AURUM_GOV_BRITTLE_V1_MQH__
