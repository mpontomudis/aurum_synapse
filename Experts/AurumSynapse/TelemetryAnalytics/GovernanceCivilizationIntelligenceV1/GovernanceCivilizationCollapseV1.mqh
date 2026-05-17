//+------------------------------------------------------------------+
//| GovernanceCivilizationCollapseV1.mqh                           |
//| Systemic / cascade collapse observability.                        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CIV_CLPS_V1_MQH__
#define __AURUM_GOV_CIV_CLPS_V1_MQH__

#include "GovernanceCivilizationDatasetV1.mqh"

bool GovCivClpsV1_Compute(const SGovResilienceProfileV1 &rp, const SGovStrategicSummaryV1 &strat, const SGovCivilizationHierarchyV1 &hier, const SGovCivilizationTopologyV1 &topo, const SGovDegenerationV1 &dg,
                          const SGovCivilizationFederationV1 &fed, SGovCivilizationCollapseV1 &out, string &out_err) {
    out_err = "";
    GovCivDsV1_InitClps(out);
    const int dg_sc = GovClampInt32(dg.degeneration_score_0_1000, 0, 1000);
    const int dg_vel = GovClampInt32(dg.degeneration_velocity_milli / 1000, 0, 100000);
    out.systemic_collapse_risk_milli = GovClampInt32(dg_sc * 1000 + dg_vel * 10, 0, 1000000);
    out.fragmentation_risk_milli = GovClampInt32(hier.governance_fragmentation_milli + topo.cluster_count * 5000, 0, 1000000);
    const int ivn = GovClampInt32(rp.summary.intervention_density_0_1000, 0, 1000);
    const int bud = GovClampInt32(strat.intervention_budget_score_0_1000, 0, 1000);
    out.coordination_failure_milli = GovClampInt32((ivn + bud) * 500, 0, 1000000);
    out.cascade_failure_milli = GovClampInt32(GovSaturatingAdd32(fed.federation_collapse_risk_milli / 2, out.systemic_collapse_risk_milli / 3), 0, 1000000);
    const int rec = GovClampInt32(rp.summary.recovery_elasticity_0_1000, 0, 1000);
    const int cat = GovClampInt32(strat.catastrophic_resistance_0_1000, 0, 1000);
    out.recovery_capacity_milli = GovClampInt32((rec + cat) * 500, 0, 1000000);
    return true;
}

#endif // __AURUM_GOV_CIV_CLPS_V1_MQH__
