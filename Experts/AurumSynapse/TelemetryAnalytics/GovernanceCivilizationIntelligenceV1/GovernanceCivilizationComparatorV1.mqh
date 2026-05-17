//+------------------------------------------------------------------+
//| GovernanceCivilizationComparatorV1.mqh                         |
//| Field-by-field summary deltas.                                  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CIV_CMP_V1_MQH__
#define __AURUM_GOV_CIV_CMP_V1_MQH__

#include "GovernanceCivilizationDatasetV1.mqh"

void GovCivCmpV1_Diff(const SGovCivilizationSummaryV1 &x, const SGovCivilizationSummaryV1 &y, SGovCivilizationComparisonV1 &out) {
    GovCivDsV1_InitCmp(out);
    out.d_federation_stability_milli = GovSaturatingAdd32(x.federation_stability_milli, -y.federation_stability_milli);
    out.d_hierarchy_stability_milli = GovSaturatingAdd32(x.hierarchy_stability_milli, -y.hierarchy_stability_milli);
    out.d_diplomacy_alignment_milli = GovSaturatingAdd32(x.diplomacy_alignment_milli, -y.diplomacy_alignment_milli);
    out.d_topology_stability_milli = GovSaturatingAdd32(x.topology_stability_milli, -y.topology_stability_milli);
    out.d_memory_stable_cycles = GovSaturatingAdd32(x.memory_stable_cycles, -y.memory_stable_cycles);
    out.d_civilization_stability_milli = GovSaturatingAdd32(x.civilization_stability_milli, -y.civilization_stability_milli);
    out.d_systemic_collapse_risk_milli = GovSaturatingAdd32(x.systemic_collapse_risk_milli, -y.systemic_collapse_risk_milli);
    out.d_continuity_milli = GovSaturatingAdd32(x.continuity_milli, -y.continuity_milli);
    out.d_regime_balance_milli = GovSaturatingAdd32(x.regime_balance_milli, -y.regime_balance_milli);
}

#endif // __AURUM_GOV_CIV_CMP_V1_MQH__
