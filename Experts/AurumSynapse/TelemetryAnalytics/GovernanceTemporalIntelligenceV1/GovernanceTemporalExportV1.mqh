//+------------------------------------------------------------------+
//| GovernanceTemporalExportV1.mqh                                 |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_TMP_EXP_V1_MQH__
#define __AURUM_GOV_TMP_EXP_V1_MQH__

#include "GovernanceTemporalDatasetV1.mqh"

bool GovTmpExpV1_Bundle(const SGovTemporalSummaryV1 &sum, const SGovTemporalEpochV1 &ep[], const int n_ep, const SGovGovernanceAgingV1 &aging, const SGovContinuityV1 &cont, const SGovCyclePatternV1 &cyc, const SGovEraTransitionV1 &era, const SGovTemporalPressureV1 &press, const SGovTemporalDecayV1 &dec, const SGovTemporalStabilityV1 &stab, int &ix_rank[], string &out, string &out_err) {
    out_err = "";
    out = "===TEMPORAL_BLOCK===\n";
    out += "GOV_TEMPORAL_V1|";
    out += IntegerToString(sum.temporal_window_id);
    out += "|";
    out += sum.replay_hash;
    out += "|";
    out += sum.policy_fingerprint;
    out += "|";
    out += IntegerToString(sum.epoch_count);
    out += "|";
    out += IntegerToString(sum.temporal_stability_milli);
    out += "|";
    out += IntegerToString(sum.long_cycle_survivability_milli);
    out += "|";
    out += IntegerToString(sum.era_transition_pressure_milli);
    out += "|";
    out += IntegerToString(sum.cumulative_temporal_pressure_milli);
    out += "|";
    out += IntegerToString(sum.decay_composite_milli);
    out += "|";
    out += IntegerToString(sum.continuity_strength_milli);
    out += "|";
    out += IntegerToString(sum.aging_entropy_milli);
    out += "\n";
    int sum_surv = 0;
    int sum_cont = 0;
    int sum_pr = 0;
    const int nn = GovClampInt32(n_ep, 0, 128);
    for(int k = 0; k < nn; k++) {
        sum_surv = GovSaturatingAdd32(sum_surv, ep[k].survivability_score_milli);
        sum_cont = GovSaturatingAdd32(sum_cont, ep[k].continuity_score_milli);
        sum_pr = GovSaturatingAdd32(sum_pr, ep[k].governance_pressure_milli);
    }
    out += "EPOCH|";
    out += IntegerToString(nn);
    out += "|";
    out += IntegerToString(sum_surv);
    out += "|";
    out += IntegerToString(sum_cont);
    out += "|";
    out += IntegerToString(sum_pr);
    out += "\n";
    out += "AGING|";
    out += IntegerToString(aging.governance_age_epochs);
    out += "|";
    out += IntegerToString(aging.fatigue_accumulation_milli);
    out += "|";
    out += IntegerToString(aging.survivability_decay_milli);
    out += "|";
    out += IntegerToString(aging.continuity_decay_milli);
    out += "|";
    out += IntegerToString(aging.governance_entropy_milli);
    out += "|";
    out += IntegerToString(aging.temporal_instability_milli);
    out += "\n";
    out += "CONT|";
    out += IntegerToString(cont.continuity_strength_milli);
    out += "|";
    out += IntegerToString(cont.continuity_break_risk_milli);
    out += "|";
    out += IntegerToString(cont.recovery_recurrence_milli);
    out += "|";
    out += IntegerToString(cont.governance_persistence_milli);
    out += "|";
    out += IntegerToString(cont.temporal_alignment_milli);
    out += "\n";
    out += "CYCLE|";
    out += IntegerToString(cyc.cycle_count);
    out += "|";
    out += IntegerToString(cyc.cycle_stability_milli);
    out += "|";
    out += IntegerToString(cyc.cycle_recurrence_milli);
    out += "|";
    out += IntegerToString(cyc.collapse_cycle_milli);
    out += "|";
    out += IntegerToString(cyc.recovery_cycle_milli);
    out += "|";
    out += IntegerToString(cyc.seasonal_instability_milli);
    out += "\n";
    out += "ERA|";
    out += IntegerToString(era.transition_count);
    out += "|";
    out += IntegerToString(era.transition_pressure_milli);
    out += "|";
    out += IntegerToString(era.era_fragmentation_milli);
    out += "|";
    out += IntegerToString(era.regime_shift_milli);
    out += "|";
    out += IntegerToString(era.civilization_shift_milli);
    out += "\n";
    out += "PRESS|";
    out += IntegerToString(press.cumulative_pressure_milli);
    out += "|";
    out += IntegerToString(press.delayed_recovery_pressure_milli);
    out += "|";
    out += IntegerToString(press.governance_saturation_milli);
    out += "|";
    out += IntegerToString(press.temporal_overload_milli);
    out += "|";
    out += IntegerToString(press.systemic_pressure_milli);
    out += "\n";
    out += "DECAY|";
    out += IntegerToString(dec.decay_acceleration_milli);
    out += "|";
    out += IntegerToString(dec.resilience_decay_milli);
    out += "|";
    out += IntegerToString(dec.survivability_decay_milli);
    out += "|";
    out += IntegerToString(dec.civilization_decay_milli);
    out += "|";
    out += IntegerToString(dec.structural_decay_milli);
    out += "\n";
    out += "STAB|";
    out += IntegerToString(stab.temporal_stability_milli);
    out += "|";
    out += IntegerToString(stab.long_horizon_survivability_milli);
    out += "|";
    out += IntegerToString(stab.civilization_continuity_milli);
    out += "|";
    out += IntegerToString(stab.collapse_resistance_milli);
    out += "|";
    out += IntegerToString(stab.governance_endurance_milli);
    out += "\n";
    out += "RANK|";
    const int n_nodes = ArraySize(ep);
    for(int r = 0; r < nn; r++) {
        if(r > 0)
            out += "|";
        const int ix = ix_rank[r];
        if(ix < 0 || ix >= n_nodes) {
            out_err = "GOV_TMP_EXP_RANK";
            return false;
        }
        out += IntegerToString(ep[ix].epoch_id);
    }
    out += "\n";
    return true;
}

#endif // __AURUM_GOV_TMP_EXP_V1_MQH__
