//+------------------------------------------------------------------+
//| GovernanceInterventionBudgetV1.mqh                           |
//| Intervention sustainability pressure (observational costs).     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_INT_BUD_V1_MQH__
#define __AURUM_GOV_INT_BUD_V1_MQH__

#include "GovernanceStrategicDatasetV1.mqh"
#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceDatasetV1.mqh"

bool GovStratBudV1_Measure(const SGovResilienceProfileV1 &rp, SGovStrategicBudgetV1 &out, string &out_err) {
    out_err = "";
    GovStratDsV1_InitBud(out);
    out.quarantine_expenditure_density_0_1000 = GovClampInt32(rp.summary.quarantine_saturation_0_1000 + rp.fatigue.quarantine_reuse_pressure_0_1000 / 2, 0, 1000);
    out.flatten_expenditure_accum_0_1000 = GovClampInt32(rp.fatigue.flatten_accumulation_0_1000, 0, 1000);
    out.throttle_escalation_cost_0_1000 = GovClampInt32(rp.fatigue.throttle_escalation_persistence_0_1000, 0, 1000);
    out.execution_suppression_cost_0_1000 = GovClampInt32(rp.fatigue.execution_suppression_fatigue_per_1000, 0, 1000);
    out.recovery_pacing_cost_0_1000 = GovClampInt32(rp.fatigue.recovery_instability_0_1000 + (1000 - rp.summary.recovery_elasticity_0_1000) / 2, 0, 1000);
    out.containment_resource_persistence_0_1000 = GovClampInt32(rp.summary.containment_resilience_0_1000 - rp.summary.intervention_density_0_1000 / 4, 0, 1000);
    int press = 0;
    press = GovSaturatingAdd32(press, out.quarantine_expenditure_density_0_1000 / 6);
    press = GovSaturatingAdd32(press, out.flatten_expenditure_accum_0_1000 / 6);
    press = GovSaturatingAdd32(press, out.throttle_escalation_cost_0_1000 / 6);
    press = GovSaturatingAdd32(press, out.execution_suppression_cost_0_1000 / 6);
    press = GovSaturatingAdd32(press, out.recovery_pacing_cost_0_1000 / 6);
    press = GovSaturatingAdd32(press, (1000 - out.containment_resource_persistence_0_1000) / 6);
    out.budget_pressure_composite_0_1000 = GovClampInt32(press, 0, 1000);
    return true;
}

#endif // __AURUM_GOV_INT_BUD_V1_MQH__
