//+------------------------------------------------------------------+
//| GovernanceResilienceComparatorV1.mqh                          |
//| Deterministic deltas between resilience summaries.               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RESIL_CMP_V1_MQH__
#define __AURUM_GOV_RESIL_CMP_V1_MQH__

#include "GovernanceResilienceDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

void GovResilCmpV1_Diff(const SGovResilienceSummaryV1 &x, const SGovResilienceSummaryV1 &y, SGovResilienceComparisonV1 &out) {
    GovResilDsV1_InitCmp(out);
    out.d_governance_health = GovSaturatingAdd32(x.governance_health_0_1000, -y.governance_health_0_1000);
    out.d_containment_resilience = GovSaturatingAdd32(x.containment_resilience_0_1000, -y.containment_resilience_0_1000);
    out.d_survivability_resilience = GovSaturatingAdd32(x.survivability_resilience_0_1000, -y.survivability_resilience_0_1000);
    out.d_recovery_elasticity = GovSaturatingAdd32(x.recovery_elasticity_0_1000, -y.recovery_elasticity_0_1000);
    out.d_collapse_resistance = GovSaturatingAdd32(x.collapse_resistance_0_1000, -y.collapse_resistance_0_1000);
    out.d_quarantine_saturation = GovSaturatingAdd32(x.quarantine_saturation_0_1000, -y.quarantine_saturation_0_1000);
    out.d_intervention_density = GovSaturatingAdd32(x.intervention_density_0_1000, -y.intervention_density_0_1000);
    out.d_regime_brittleness = GovSaturatingAdd32(x.regime_brittleness_0_1000, -y.regime_brittleness_0_1000);
    out.d_degradation_velocity_milli = GovSaturatingAdd32(x.degradation_velocity_milli, -y.degradation_velocity_milli);
    out.d_resilience_half_life_epochs = GovSaturatingAdd32(x.resilience_half_life_epochs, -y.resilience_half_life_epochs);
    out.d_stabilization_quality = GovSaturatingAdd32(x.stabilization_quality_0_1000, -y.stabilization_quality_0_1000);
}

#endif // __AURUM_GOV_RESIL_CMP_V1_MQH__
