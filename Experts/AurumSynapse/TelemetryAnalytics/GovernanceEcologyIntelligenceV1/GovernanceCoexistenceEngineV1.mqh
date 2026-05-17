//+------------------------------------------------------------------+
//| GovernanceCoexistenceEngineV1.mqh                               |
//| GOVERNANCE_ECOLOGY_INTELLIGENCE_V1 — coexistence metrics         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECO_COEXIST_V1_MQH__
#define __AURUM_GOV_ECO_COEXIST_V1_MQH__

#include "GovernanceEcologyDatasetV1.mqh"
#include "../GovernanceCivilizationIntelligenceV1/GovernanceCivilizationDatasetV1.mqh"
#include "../GovernanceTemporalIntelligenceV1/GovernanceTemporalDatasetV1.mqh"

bool GovCoexistV1_Compute(const SGovEcologyEntityV1 &ents[], const int n_ent, const SGovCivilizationSummaryV1 &civ, const SGovTemporalSummaryV1 &tmp, SGovEcologyCoexistenceV1 &out, string &out_err) {
    out_err = "";
    GovEcoDsV1_InitCoexist(out);
    const int ne = GovClampInt32(n_ent, 0, 64);
    if(ne <= 0)
        return true;
    long sum = 0;
    int mn = ents[0].recovery_coexistence_milli;
    int mx = ents[0].recovery_coexistence_milli;
    for(int k = 0; k < ne; k++) {
        sum += (long)ents[k].recovery_coexistence_milli;
        mn = MathMin(mn, ents[k].recovery_coexistence_milli);
        mx = MathMax(mx, ents[k].recovery_coexistence_milli);
    }
    const int mean = (int)(sum / (long)ne);
    int var_acc = 0;
    for(int k = 0; k < ne; k++) {
        const int d = GovSaturatingAdd32(ents[k].recovery_coexistence_milli, -mean);
        var_acc = GovSaturatingAdd32(var_acc, MathAbs(d));
    }
    const int spread = GovSaturatingAdd32(mx, -mn);
    out.coexistence_stability_milli = GovClampInt32(1000000 - var_acc / ne, 0, 1000000000);
    out.recovery_harmony_milli = GovClampInt32(GovSaturatingAdd32(mean, -spread / 4), 0, 1000000000);
    out.regime_compatibility_milli = GovClampInt32(GovSaturatingAdd32(civ.regime_balance_milli, civ.continuity_milli / 2), 0, 1000000000);
    out.intervention_interference_milli = GovClampInt32(GovSaturatingAdd32((1000 - civ.diplomacy_alignment_milli / 1000) * 800000, (1000 - civ.topology_stability_milli / 1000) * 400000), 0, 1000000000);
    out.temporal_sync_stability_milli = GovClampInt32(GovSaturatingAdd32(tmp.continuity_strength_milli, 1000000 - tmp.era_transition_pressure_milli), 0, 1000000000);
    return true;
}

#endif // __AURUM_GOV_ECO_COEXIST_V1_MQH__
