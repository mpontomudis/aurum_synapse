//+------------------------------------------------------------------+
//| GovernanceSimulationComparatorV1.mqh                          |
//| Deterministic deltas between policy runs.                        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SIM_CMP_V1_MQH__
#define __AURUM_GOV_SIM_CMP_V1_MQH__

#include "GovernanceSimulationDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

void GovSimCmpV1_Diff(const SGovSimPolicyRunV1 &x, const SGovSimPolicyRunV1 &y, SGovSimComparisonV1 &out) {
    GovSimDsV1_InitCmp(out);
    out.d_governance_health_proxy = GovSaturatingAdd32(x.governance_health_proxy_0_1000, -y.governance_health_proxy_0_1000);
    out.d_incident_count = GovSaturatingAdd32(x.incident_count, -y.incident_count);
    out.d_stability_sum = GovSaturatingAdd32(GovSimDsV1_StabSum(x.stability), -GovSimDsV1_StabSum(y.stability));
    out.d_survivability_robustness = GovSaturatingAdd32(x.stability.survivability_robustness_0_1000, -y.stability.survivability_robustness_0_1000);
}

#endif // __AURUM_GOV_SIM_CMP_V1_MQH__
