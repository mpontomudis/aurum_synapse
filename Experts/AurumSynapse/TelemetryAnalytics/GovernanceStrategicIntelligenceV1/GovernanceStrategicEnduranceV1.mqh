//+------------------------------------------------------------------+
//| GovernanceStrategicEnduranceV1.mqh                            |
//| Long-horizon governance endurance (integer composite).          |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRAT_END_V1_MQH__
#define __AURUM_GOV_STRAT_END_V1_MQH__

#include "GovernanceStrategicDatasetV1.mqh"
#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceDatasetV1.mqh"
#include "../GovernanceEvolutionIntelligenceV1/GovernanceEvolutionDatasetV1.mqh"

bool GovStratEndV1_Measure(const SGovResilienceProfileV1 &rp, const SGovEvolutionSurvivabilityV1 &sv, const SGovDegenerationV1 &dg, SGovStrategicEnduranceV1 &out, string &out_err) {
    out_err = "";
    GovStratDsV1_InitEnd(out);
    out.survivability_persistence_0_1000 = GovClampInt32(rp.summary.survivability_resilience_0_1000 + rp.curve.resilience_half_life_epochs * 20, 0, 1000);
    out.recovery_endurance_0_1000 = GovClampInt32(rp.summary.recovery_elasticity_0_1000 + sv.containment_stab_evolution_0_1000 / 4, 0, 1000);
    out.containment_sustainability_0_1000 = GovClampInt32(rp.summary.containment_resilience_0_1000 + rp.curve.stabilization_recovery_epochs * 25, 0, 1000);
    out.fatigue_endurance_0_1000 = GovClampInt32(1000 - rp.fatigue.fatigue_composite_0_1000, 0, 1000);
    out.intervention_longevity_0_1000 = GovClampInt32(1000 - GovClampInt32(rp.summary.intervention_density_0_1000, 0, 1000), 0, 1000);
    out.catastrophic_resistance_endurance_0_1000 = GovClampInt32(rp.summary.collapse_resistance_0_1000 + rp.collapse.resilience_interruption_efficiency_0_1000 / 4, 0, 1000);
    out.degradation_persistence_0_1000 = GovClampInt32(dg.degeneration_persistence_0_1000, 0, 1000);
    int comp = 0;
    comp = GovSaturatingAdd32(comp, out.survivability_persistence_0_1000 / 7);
    comp = GovSaturatingAdd32(comp, out.recovery_endurance_0_1000 / 7);
    comp = GovSaturatingAdd32(comp, out.containment_sustainability_0_1000 / 7);
    comp = GovSaturatingAdd32(comp, out.fatigue_endurance_0_1000 / 7);
    comp = GovSaturatingAdd32(comp, out.intervention_longevity_0_1000 / 7);
    comp = GovSaturatingAdd32(comp, out.catastrophic_resistance_endurance_0_1000 / 7);
    comp = GovSaturatingAdd32(comp, out.degradation_persistence_0_1000 / 7);
    out.endurance_composite_0_1000 = GovClampInt32(comp, 0, 1000);
    return true;
}

#endif // __AURUM_GOV_STRAT_END_V1_MQH__
