//+------------------------------------------------------------------+
//| GovernanceCivilizationStabilityV1.mqh                          |
//| Composite civilization stability (observational).               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CIV_STAB_V1_MQH__
#define __AURUM_GOV_CIV_STAB_V1_MQH__

#include "GovernanceCivilizationDatasetV1.mqh"

bool GovCivStabV1_Compute(const SGovCivilizationFederationV1 &fed, const SGovCivilizationHierarchyV1 &hier, const SGovCivilizationDiplomacyV1 &dip, const SGovCivilizationMemoryV1 &mem, const SGovCivilizationTopologyV1 &topo,
                          const SGovStrategicSummaryV1 &strat, const SGovResilienceProfileV1 &rp, SGovCivilizationStabilityV1 &out, string &out_err) {
    out_err = "";
    GovCivDsV1_InitStab(out);
    const int fed_part = GovClampInt32(fed.federation_stability_milli / 4, 0, 250000);
    const int hier_part = GovClampInt32(hier.hierarchy_stability_milli / 4, 0, 250000);
    const int dip_part = GovClampInt32(dip.diplomacy_alignment_milli / 4, 0, 250000);
    const int topo_part = GovClampInt32(topo.topology_stability_milli / 4, 0, 250000);
    int comp = GovSaturatingAdd32(fed_part, hier_part);
    comp = GovSaturatingAdd32(comp, dip_part);
    comp = GovSaturatingAdd32(comp, topo_part);
    out.civilization_stability_milli = GovClampInt32(comp, 0, 1000000);
    const int surv_r = GovClampInt32(rp.summary.survivability_resilience_0_1000, 0, 1000);
    const int surv_s = GovClampInt32(strat.survivability_horizon_0_1000, 0, 1000);
    out.multi_lineage_survivability_milli = GovClampInt32((surv_r + surv_s) * 500, 0, 1000000);
    const int mem_st = GovClampInt32(mem.stable_cycles * 100000, 0, 500000);
    const int deg_vel = GovClampInt32(rp.summary.degradation_velocity_milli / 10, 0, 100000);
    out.governance_continuity_milli = GovClampInt32(mem_st + (1000000 - deg_vel) / 2, 0, 1000000);
    const int clp_r = GovClampInt32(rp.summary.collapse_resistance_0_1000, 0, 1000);
    const int clp_s = GovClampInt32(strat.collapse_avoidance_score_0_1000, 0, 1000);
    out.collapse_resistance_milli = GovClampInt32((clp_r + clp_s) * 500, 0, 1000000);
    const int fed_end = GovSaturatingAdd32(fed.federation_stability_milli / 2, (1000000 - fed.federation_collapse_risk_milli) / 2);
    out.federation_endurance_milli = GovClampInt32(fed_end, 0, 1000000);
    return true;
}

#endif // __AURUM_GOV_CIV_STAB_V1_MQH__
