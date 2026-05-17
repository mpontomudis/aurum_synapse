//+------------------------------------------------------------------+
//| GovernanceEcologicalResilienceV1.mqh                          |
//| GOVERNANCE_ECOLOGY_INTELLIGENCE_V1 — ecosystem resilience        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECO_ERES_V1_MQH__
#define __AURUM_GOV_ECO_ERES_V1_MQH__

#include "GovernanceEcologyDatasetV1.mqh"

bool GovEcoResV1_Compute(const SGovEcologyBiodiversityV1 &bio, const SGovEcologyCollapseV1 &cl, const SGovEcologyCoexistenceV1 &cx, const SGovEcologyPressureV1 &press, SGovEcologyResilienceV1 &out, string &out_err) {
    out_err = "";
    GovEcoDsV1_InitEcoRes(out);
    const int resist = GovClampInt32(GovSaturatingAdd32(1000000 - cl.collapse_contagion_milli / 2, -cl.resilience_extinction_milli / 3), 0, 1000000000);
    out.collapse_resistance_milli = resist;
    out.biodiversity_recovery_milli = GovClampInt32(GovSaturatingAdd32(bio.diversity_score_milli / 2, bio.regime_diversity_milli / 4), 0, 1000000000);
    out.ecosystem_recovery_speed_milli = GovClampInt32(GovSaturatingAdd32(cx.recovery_harmony_milli, -press.recovery_resource_scarcity_milli / 2), 0, 1000000000);
    out.ecosystem_resilience_milli = GovClampInt32(GovSaturatingAdd32(resist / 2, GovSaturatingAdd32(out.biodiversity_recovery_milli / 3, cx.coexistence_stability_milli / 4)), 0, 1000000000);
    out.long_horizon_ecological_survivability_milli = GovClampInt32(GovSaturatingAdd32(out.ecosystem_resilience_milli, GovSaturatingAdd32(-press.intervention_exhaustion_milli / 4, out.ecosystem_recovery_speed_milli / 3)), 0, 1000000000);
    return true;
}

#endif // __AURUM_GOV_ECO_ERES_V1_MQH__
