//+------------------------------------------------------------------+
//| GovernanceEvolutionComparatorV1.mqh                          |
//| Deterministic deltas between evolution summaries.               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EVO_CMP_V1_MQH__
#define __AURUM_GOV_EVO_CMP_V1_MQH__

#include "GovernanceEvolutionDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

void GovEvoCmpV1_Diff(const SGovEvolutionSummaryV1 &x, const SGovEvolutionSummaryV1 &y, SGovEvolutionComparisonV1 &out) {
    GovEvoDsV1_InitCmp(out);
    out.d_max_degeneration_velocity_milli = GovSaturatingAdd32(x.max_degeneration_velocity_milli, -y.max_degeneration_velocity_milli);
    out.d_mean_survivability_0_1000 = GovSaturatingAdd32(x.mean_survivability_0_1000, -y.mean_survivability_0_1000);
    out.d_generation_span = GovSaturatingAdd32(x.generation_span, -y.generation_span);
    out.d_mean_degeneration_score_0_1000 = GovSaturatingAdd32(x.mean_degeneration_score_0_1000, -y.mean_degeneration_score_0_1000);
    out.d_topology_branching_factor_0_1000 = GovSaturatingAdd32(x.topology_branching_factor_0_1000, -y.topology_branching_factor_0_1000);
}

#endif // __AURUM_GOV_EVO_CMP_V1_MQH__
