//+------------------------------------------------------------------+
//| GovernanceStrategicContainmentV1.mqh                         |
//| Strategic containment quality over replay horizon.              |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRAT_CTN_V1_MQH__
#define __AURUM_GOV_STRAT_CTN_V1_MQH__

#include "GovernanceStrategicDatasetV1.mqh"
#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceDatasetV1.mqh"

bool GovStratCtnV1_Measure(const SGovResilienceProfileV1 &rp, SGovStrategicContainmentV1 &out, string &out_err) {
    out_err = "";
    GovStratDsV1_InitCtn(out);
    out.long_cycle_stability_0_1000 = GovClampInt32(rp.summary.containment_resilience_0_1000 + rp.curve.plateau_epoch_segments * 5, 0, 1000);
    out.escalation_interruption_eff_0_1000 = GovClampInt32(rp.collapse.resilience_interruption_efficiency_0_1000, 0, 1000);
    out.containment_pacing_quality_0_1000 = GovClampInt32(1000 - GovClampInt32(rp.curve.collapse_acceleration_score_0_1000, 0, 1000), 0, 1000);
    out.strategic_lockdown_efficiency_0_1000 = GovClampInt32(1000 - rp.fatigue.lockdown_density_per_1000 * 2, 0, 1000);
    out.catastrophic_interrupt_quality_0_1000 = GovClampInt32(rp.collapse.containment_interruption_quality_0_1000, 0, 1000);
    out.containment_sustain_horizon_0_1000 = GovClampInt32(rp.curve.resilience_half_life_epochs * 40 + rp.summary.stabilization_quality_0_1000 / 2, 0, 1000);
    return true;
}

#endif // __AURUM_GOV_STRAT_CTN_V1_MQH__
