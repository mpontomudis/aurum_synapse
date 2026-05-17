//+------------------------------------------------------------------+
//| GovernanceCollapseAwarenessV1.mqh                               |
//| GOVERNANCE_CONSCIOUSNESS_INTELLIGENCE_V1 — collapse awareness    |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CON_CLPAW_V1_MQH__
#define __AURUM_GOV_CON_CLPAW_V1_MQH__

#include "GovernanceConsciousnessDatasetV1.mqh"
#include "../GovernanceCivilizationIntelligenceV1/GovernanceCivilizationDatasetV1.mqh"
#include "../GovernanceTemporalIntelligenceV1/GovernanceTemporalDatasetV1.mqh"
#include "../GovernanceEcologyIntelligenceV1/GovernanceEcologyDatasetV1.mqh"
#include "../GovernanceStrategicIntelligenceV1/GovernanceStrategicDatasetV1.mqh"

bool GovCollapseAwareV1_Compute(const SGovStrategicSummaryV1 &strat, const SGovCivilizationSummaryV1 &civ, const SGovTemporalSummaryV1 &tmp, const SGovEcologySummaryV1 &eco, SGovCollapseAwarenessV1 &out, string &out_err) {
    out_err = "";
    GovConDsV1_InitCollapseAware(out);
    const int traj = GovClampInt32(1000 - strat.collapse_avoidance_score_0_1000, 0, 1000);
    out.collapse_trajectory_awareness_milli = GovClampInt32(traj * 1000000 + eco.collapse_exposure_milli / 2, 0, 1000000000);
    out.survivability_decay_awareness_milli = GovClampInt32(GovSaturatingAdd32((1000 - strat.survivability_horizon_0_1000) * 900000, tmp.decay_composite_milli / 2), 0, 1000000000);
    out.ecological_collapse_awareness_milli = GovClampInt32(GovSaturatingAdd32(eco.collapse_exposure_milli, eco.predation_pressure_milli / 3), 0, 1000000000);
    out.civilization_instability_awareness_milli = GovClampInt32(GovSaturatingAdd32(civ.systemic_collapse_risk_milli, (1000 - civ.civilization_stability_milli / 1000) * 500000), 0, 1000000000);
    out.temporal_degradation_awareness_milli = GovClampInt32(GovSaturatingAdd32(tmp.decay_composite_milli, tmp.era_transition_pressure_milli / 2), 0, 1000000000);
    return true;
}

#endif // __AURUM_GOV_CON_CLPAW_V1_MQH__
