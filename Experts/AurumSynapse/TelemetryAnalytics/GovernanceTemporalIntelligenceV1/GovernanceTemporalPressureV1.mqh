//+------------------------------------------------------------------+
//| GovernanceTemporalPressureV1.mqh                               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_TMP_PRESS_V1_MQH__
#define __AURUM_GOV_TMP_PRESS_V1_MQH__

#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceDatasetV1.mqh"
#include "GovernanceTemporalDatasetV1.mqh"

bool GovTmpPressV1_Compute(const SGovTemporalEpochV1 &ep[], const int n_ep, const SGovGovernanceAgingV1 &aging, const SGovEraTransitionV1 &era, const SGovResilienceProfileV1 &rp, SGovTemporalPressureV1 &out, string &out_err) {
    out_err = "";
    GovTmpDsV1_InitPress(out);
    if(n_ep < 1 || n_ep > 128) {
        out_err = "GOV_TMP_PRESS_N";
        return false;
    }
    int acc = 0;
    for(int i = 0; i < n_ep; i++)
        acc = GovSaturatingAdd32(acc, ep[i].governance_pressure_milli / GovClampInt32(n_ep, 1, 128));
    out.cumulative_pressure_milli = GovClampInt32(acc + aging.fatigue_accumulation_milli / 4, 0, 1000000000);
    out.delayed_recovery_pressure_milli = GovClampInt32((1000 - GovClampInt32(rp.summary.recovery_elasticity_0_1000, 0, 1000)) * 500 + era.transition_pressure_milli / 3, 0, 1000000000);
    out.governance_saturation_milli = GovClampInt32(rp.summary.quarantine_saturation_0_1000 * 1000 + rp.summary.intervention_density_0_1000 * 500, 0, 1000000000);
    out.temporal_overload_milli = GovClampInt32(aging.temporal_instability_milli / 2 + out.cumulative_pressure_milli / 3, 0, 1000000000);
    out.systemic_pressure_milli = GovClampInt32(out.cumulative_pressure_milli / 2 + out.governance_saturation_milli / 2 + era.era_fragmentation_milli / 4, 0, 1000000000);
    return true;
}

#endif // __AURUM_GOV_TMP_PRESS_V1_MQH__
