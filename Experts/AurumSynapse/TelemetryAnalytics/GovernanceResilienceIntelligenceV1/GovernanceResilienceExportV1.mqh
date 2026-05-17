//+------------------------------------------------------------------+
//| GovernanceResilienceExportV1.mqh                             |
//| UTF-8/LF deterministic resilience bundles.                        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RESIL_EXP_V1_MQH__
#define __AURUM_GOV_RESIL_EXP_V1_MQH__

#include "GovernanceResilienceDatasetV1.mqh"

bool GovResilExpV1_Bundle(const SGovResilienceSummaryV1 &s, const SGovResilienceCurveV1 &c, const SGovGovernanceFatigueV1 &f, const SGovRegimeBrittlenessV1 &b,
                           const SGovCollapseResistanceV1 &k, const SGovResilienceStressResponseV1 &sr[], const int sr_n, int &rank_ord[], string &out, string &out_err) {
    out_err = "";
    out = "===GOV_RESILIENCE_V1===\n";
    out += "schema,GOV_RESILIENCE_V1\n";
    out += "SUM," + IntegerToString(s.resilience_window_id);
    out += "," + s.replay_hash;
    out += "," + s.policy_fingerprint;
    out += ",gh," + IntegerToString(s.governance_health_0_1000);
    out += ",cr," + IntegerToString(s.containment_resilience_0_1000);
    out += ",sr," + IntegerToString(s.survivability_resilience_0_1000);
    out += ",re," + IntegerToString(s.recovery_elasticity_0_1000);
    out += ",clp," + IntegerToString(s.collapse_resistance_0_1000);
    out += ",qs," + IntegerToString(s.quarantine_saturation_0_1000);
    out += ",id," + IntegerToString(s.intervention_density_0_1000);
    out += ",rb," + IntegerToString(s.regime_brittleness_0_1000);
    out += ",dv," + IntegerToString(s.degradation_velocity_milli);
    out += ",hl," + IntegerToString(s.resilience_half_life_epochs);
    out += ",sq," + IntegerToString(s.stabilization_quality_0_1000);
    out += ",n," + IntegerToString(s.replay_epoch_count);
    out += "\n";
    out += "CURVE,sdsl," + IntegerToString(c.survivability_decay_slope_milli);
    out += ",trsl," + IntegerToString(c.toxicity_rise_slope_milli);
    out += ",cpsl," + IntegerToString(c.containment_pressure_slope_milli);
    out += ",qpk," + IntegerToString(c.quarantine_saturation_peak);
    out += ",pls," + IntegerToString(c.plateau_epoch_segments);
    out += ",sre," + IntegerToString(c.stabilization_recovery_epochs);
    out += ",cas," + IntegerToString(c.collapse_acceleration_score_0_1000);
    out += ",rcq," + IntegerToString(c.recovery_curve_quality_0_1000);
    out += ",dvm," + IntegerToString(c.degradation_velocity_milli);
    out += ",hle," + IntegerToString(c.resilience_half_life_epochs);
    out += "\n";
    out += "FATIGUE,ld," + IntegerToString(f.lockdown_density_per_1000);
    out += ",thr," + IntegerToString(f.throttle_escalation_persistence_0_1000);
    out += ",flt," + IntegerToString(f.flatten_accumulation_0_1000);
    out += ",qrp," + IntegerToString(f.quarantine_reuse_pressure_0_1000);
    out += ",exf," + IntegerToString(f.execution_suppression_fatigue_per_1000);
    out += ",rin," + IntegerToString(f.recovery_instability_0_1000);
    out += ",cmp," + IntegerToString(f.fatigue_composite_0_1000);
    out += "\n";
    out += "BRITTLE,bs," + IntegerToString(b.brittleness_score_0_1000);
    out += ",oi," + IntegerToString(b.oscillation_index_0_1000);
    out += ",rh," + IntegerToString(b.regime_half_life_epochs);
    out += ",sp," + IntegerToString(b.stabilization_persistence_0_1000);
    out += "\n";
    out += "CLPS,cs," + IntegerToString(k.collapse_resistance_score_0_1000);
    out += ",rie," + IntegerToString(k.resilience_interruption_efficiency_0_1000);
    out += ",sil," + IntegerToString(k.stabilization_interruption_latency_epochs);
    out += ",ciq," + IntegerToString(k.containment_interruption_quality_0_1000);
    out += "\n";
    for(int i = 0; i < sr_n; i++) {
        const int ix = rank_ord[i];
        out += "SRANK," + IntegerToString(i);
        out += ",arch," + IntegerToString(sr[ix].archetype_id);
        out += ",str," + IntegerToString(sr[ix].stress_lane_code);
        out += ",h," + IntegerToString(sr[ix].lane_health_proxy_0_1000);
        out += ",clp," + IntegerToString(sr[ix].lane_collapse_resistance_0_1000);
        out += ",fat," + IntegerToString(sr[ix].lane_fatigue_load_0_1000);
        out += "\n";
    }
    return true;
}

#endif // __AURUM_GOV_RESIL_EXP_V1_MQH__
