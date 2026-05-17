//+------------------------------------------------------------------+
//| GovernanceDiplomacyEngineV1.mqh                                |
//| Deterministic cooperation / conflict scoring.                     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CIV_DIP_ENG_V1_MQH__
#define __AURUM_GOV_CIV_DIP_ENG_V1_MQH__

#include "GovernanceCivilizationDatasetV1.mqh"

bool GovDipEngV1_Compute(const SGovResilienceProfileV1 &rp, const SGovStrategicSummaryV1 &strat, SGovCivilizationDiplomacyV1 &out, string &out_err) {
    out_err = "";
    GovCivDsV1_InitDip(out);
    const int surv = GovClampInt32(rp.summary.survivability_resilience_0_1000, 0, 1000);
    const int sust = GovClampInt32(strat.sustainability_index_0_1000, 0, 1000);
    out.diplomacy_alignment_milli = GovClampInt32((surv + sust) * 500, 0, 1000000);
    const int rec_r = GovClampInt32(rp.summary.recovery_elasticity_0_1000, 0, 1000);
    const int rec_s = GovClampInt32(strat.recovery_sustainability_0_1000, 0, 1000);
    out.cooperation_milli = GovClampInt32((rec_r + rec_s) * 500, 0, 1000000);
    const int fat = GovClampInt32(rp.fatigue.fatigue_composite_0_1000, 0, 1000);
    const int ivn = GovClampInt32(rp.summary.intervention_density_0_1000, 0, 1000);
    out.conflict_milli = GovClampInt32((fat + ivn) * 500, 0, 1000000);
    const int ctn_r = GovClampInt32(rp.summary.containment_resilience_0_1000, 0, 1000);
    const int ctn_s = GovClampInt32(strat.strategic_containment_quality_0_1000, 0, 1000);
    out.containment_coordination_milli = GovClampInt32((ctn_r + ctn_s) * 500, 0, 1000000);
    const int ri = GovClampInt32(rp.collapse.resilience_interruption_efficiency_0_1000, 0, 1000);
    const int en = GovClampInt32(strat.endurance_capacity_0_1000, 0, 1000);
    out.recovery_assistance_milli = GovClampInt32((ri + en) * 300, 0, 1000000);
    return true;
}

#endif // __AURUM_GOV_CIV_DIP_ENG_V1_MQH__
