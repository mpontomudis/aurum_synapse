//+------------------------------------------------------------------+
//| GovernanceStrategicComparatorV1.mqh                          |
//| Deterministic deltas between strategic summaries.               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRAT_CMP_V1_MQH__
#define __AURUM_GOV_STRAT_CMP_V1_MQH__

#include "GovernanceStrategicDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

void GovStratCmpV1_Diff(const SGovStrategicSummaryV1 &x, const SGovStrategicSummaryV1 &y, SGovStrategicComparisonV1 &out) {
    GovStratDsV1_InitCmp(out);
    out.d_sustainability_index_0_1000 = GovSaturatingAdd32(x.sustainability_index_0_1000, -y.sustainability_index_0_1000);
    out.d_endurance_capacity_0_1000 = GovSaturatingAdd32(x.endurance_capacity_0_1000, -y.endurance_capacity_0_1000);
    out.d_intervention_budget_score_0_1000 = GovSaturatingAdd32(x.intervention_budget_score_0_1000, -y.intervention_budget_score_0_1000);
    out.d_catastrophic_resistance_0_1000 = GovSaturatingAdd32(x.catastrophic_resistance_0_1000, -y.catastrophic_resistance_0_1000);
    out.d_collapse_avoidance_score_0_1000 = GovSaturatingAdd32(x.collapse_avoidance_score_0_1000, -y.collapse_avoidance_score_0_1000);
    out.d_survivability_horizon_0_1000 = GovSaturatingAdd32(x.survivability_horizon_0_1000, -y.survivability_horizon_0_1000);
}

#endif // __AURUM_GOV_STRAT_CMP_V1_MQH__
