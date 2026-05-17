//+------------------------------------------------------------------+
//| GovernanceTemporalStabilityV1.mqh                              |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_TMP_STAB_V1_MQH__
#define __AURUM_GOV_TMP_STAB_V1_MQH__

#include "../GovernanceCivilizationIntelligenceV1/GovernanceCivilizationDatasetV1.mqh"
#include "../GovernanceStrategicIntelligenceV1/GovernanceStrategicDatasetV1.mqh"
#include "GovernanceTemporalDatasetV1.mqh"

bool GovTmpStabV1_Compute(const SGovContinuityV1 &cont, const SGovTemporalPressureV1 &press, const SGovTemporalDecayV1 &dec, const SGovCivilizationSummaryV1 &civ, const SGovStrategicSummaryV1 &strat, SGovTemporalStabilityV1 &out, string &out_err) {
    out_err = "";
    GovTmpDsV1_InitStab(out);
    const int cont_part = GovClampInt32(cont.continuity_strength_milli / 5, 0, 200000);
    const int press_rel = GovClampInt32(1000000 - press.systemic_pressure_milli / 4, 0, 1000000);
    const int dec_rel = GovClampInt32(1000000 - dec.decay_acceleration_milli / 4, 0, 1000000);
    int comp = GovSaturatingAdd32(cont_part, press_rel / 5);
    comp = GovSaturatingAdd32(comp, dec_rel / 5);
    out.temporal_stability_milli = GovClampInt32(comp, 0, 1000000000);
    out.long_horizon_survivability_milli = GovClampInt32(strat.survivability_horizon_0_1000 * 1000 + civ.continuity_milli / 4, 0, 1000000000);
    out.civilization_continuity_milli = GovClampInt32(civ.continuity_milli + cont.governance_persistence_milli / 4, 0, 1000000000);
    out.collapse_resistance_milli = GovClampInt32(strat.collapse_avoidance_score_0_1000 * 1000 + (1000000 - civ.systemic_collapse_risk_milli) / 4, 0, 1000000000);
    out.governance_endurance_milli = GovClampInt32(strat.endurance_capacity_0_1000 * 1000 + civ.regime_balance_milli / 4, 0, 1000000000);
    return true;
}

#endif // __AURUM_GOV_TMP_STAB_V1_MQH__
