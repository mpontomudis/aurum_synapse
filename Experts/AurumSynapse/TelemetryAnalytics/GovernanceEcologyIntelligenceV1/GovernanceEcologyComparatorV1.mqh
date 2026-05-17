//+------------------------------------------------------------------+
//| GovernanceEcologyComparatorV1.mqh                               |
//| GOVERNANCE_ECOLOGY_INTELLIGENCE_V1 — deterministic diff          |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECO_CMP_V1_MQH__
#define __AURUM_GOV_ECO_CMP_V1_MQH__

#include "GovernanceEcologyDatasetV1.mqh"

bool GovEcoCmpV1_Diff(const SGovEcologySummaryV1 &a, const SGovEcologySummaryV1 &b, SGovEcologyComparisonV1 &out, string &out_err) {
    out_err = "";
    GovEcoDsV1_InitCmp(out);
    out.d_ecological_stability_milli = GovSaturatingAdd32(a.ecological_stability_milli, -b.ecological_stability_milli);
    out.d_biodiversity_index_milli = GovSaturatingAdd32(a.biodiversity_index_milli, -b.biodiversity_index_milli);
    out.d_collapse_exposure_milli = GovSaturatingAdd32(a.collapse_exposure_milli, -b.collapse_exposure_milli);
    out.d_coexistence_quality_milli = GovSaturatingAdd32(a.coexistence_quality_milli, -b.coexistence_quality_milli);
    out.d_ecosystem_resilience_milli = GovSaturatingAdd32(a.ecosystem_resilience_milli, -b.ecosystem_resilience_milli);
    out.d_predation_pressure_milli = GovSaturatingAdd32(a.predation_pressure_milli, -b.predation_pressure_milli);
    return true;
}

#endif // __AURUM_GOV_ECO_CMP_V1_MQH__
