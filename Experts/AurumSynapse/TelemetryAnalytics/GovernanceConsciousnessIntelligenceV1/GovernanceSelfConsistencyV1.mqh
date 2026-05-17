//+------------------------------------------------------------------+
//| GovernanceSelfConsistencyV1.mqh                                 |
//| GOVERNANCE_CONSCIOUSNESS_INTELLIGENCE_V1 — self-consistency        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CON_SC_V1_MQH__
#define __AURUM_GOV_CON_SC_V1_MQH__

#include "GovernanceConsciousnessDatasetV1.mqh"
#include "../GovernanceStrategicIntelligenceV1/GovernanceStrategicDatasetV1.mqh"
#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceDatasetV1.mqh"
#include "../GovernanceCivilizationIntelligenceV1/GovernanceCivilizationDatasetV1.mqh"

bool GovSelfConsV1_Compute(const SGovStrategicSummaryV1 &strat, const SGovResilienceProfileV1 &rp, const SGovCivilizationSummaryV1 &civ, SGovSelfConsistencyV1 &out, string &out_err) {
    out_err = "";
    GovConDsV1_InitSelfCons(out);
    const int ir = GovClampInt32(strat.intervention_budget_score_0_1000 - rp.summary.intervention_density_0_1000, -1000, 1000);
    const int cr = GovClampInt32(strat.strategic_containment_quality_0_1000 - rp.summary.containment_resilience_0_1000, -1000, 1000);
    const int rr = GovClampInt32(strat.recovery_sustainability_0_1000 - rp.summary.recovery_elasticity_0_1000, -1000, 1000);
    out.contradiction_score_milli = GovClampInt32(MathAbs(ir) * 200000 + MathAbs(cr) * 220000 + MathAbs(rr) * 180000, 0, 1000000000);
    out.recovery_consistency_milli = GovClampInt32(1000000 - MathAbs(rr) * 500, 0, 1000000000);
    out.intervention_consistency_milli = GovClampInt32(1000000 - MathAbs(ir) * 500, 0, 1000000000);
    out.containment_consistency_milli = GovClampInt32(1000000 - MathAbs(cr) * 500, 0, 1000000000);
    const int reg = GovClampInt32(strat.regime_endurance_balance_0_1000 - GovClampInt32(civ.regime_balance_milli / 1000, 0, 1000), -1000, 1000);
    out.regime_continuity_consistency_milli = GovClampInt32(1000000 - MathAbs(reg) * 600, 0, 1000000000);
    return true;
}

#endif // __AURUM_GOV_CON_SC_V1_MQH__
