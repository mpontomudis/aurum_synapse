//+------------------------------------------------------------------+
//| GovernanceSpeciesEngineV1.mqh                                   |
//| GOVERNANCE_ECOLOGY_INTELLIGENCE_V1 — species classification      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECO_SPECIES_V1_MQH__
#define __AURUM_GOV_ECO_SPECIES_V1_MQH__

#include "GovernanceEcologyDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceDatasetV1.mqh"
#include "../GovernanceCivilizationIntelligenceV1/GovernanceCivilizationDatasetV1.mqh"
#include "../GovernanceTemporalIntelligenceV1/GovernanceTemporalDatasetV1.mqh"

enum ENUM_GOV_SPECIES_V1 {
    GOV_SPECIES_BALANCED = 0,
    GOV_SPECIES_PREDATORY = 1,
    GOV_SPECIES_PARASITIC = 2,
    GOV_SPECIES_RESILIENT = 3,
    GOV_SPECIES_COLLAPSING = 4,
    GOV_SPECIES_REGENERATIVE = 5,
    GOV_SPECIES_FRAGILE = 6
};

int GovSpeciesV1_ReplayCollapseHistoryScore(const SGovReplayTimelineV1 &tl) {
    const int n = GovClampInt32(ArraySize(tl.epochs), 0, GOV_REPLAY_V1_MAX_EPOCHS);
    if(n <= 0)
        return 0;
    int bad = 0;
    for(int k = 0; k < n; k++) {
        const int surv = GovClampInt32(tl.epochs[k].survivability_ms, 0, 100000);
        const int tox = GovClampInt32(tl.epochs[k].toxicity_ms, 0, 100000);
        const int inst = GovClampInt32(tl.epochs[k].structural_instability_ms, 0, 100000);
        if(surv < 2000 || tox > 8000 || inst > 8000 || tl.epochs[k].recovery_allowed == 0)
            bad++;
    }
    return GovClampInt32((bad * 1000) / n, 0, 1000);
}

bool GovSpeciesV1_Classify(const SGovEcologyEntityV1 &ent, const SGovResilienceProfileV1 &rp, const SGovReplayTimelineV1 &tl, const SGovCivilizationSummaryV1 &civ, const SGovTemporalSummaryV1 &tmp, SGovEcologySpeciesV1 &out_sp, string &out_err) {
    out_err = "";
    GovEcoDsV1_InitSpecies(out_sp);
    out_sp.entity_id = ent.ecosystem_id;
    const int ch = GovSpeciesV1_ReplayCollapseHistoryScore(tl);
    const int cont = GovClampInt32(rp.summary.containment_resilience_0_1000, 0, 1000);
    const int res = GovClampInt32(rp.summary.collapse_resistance_0_1000, 0, 1000);
    const int rc = GovClampInt32(ent.recovery_coexistence_milli / 1000, 0, 1000);
    const int ce = GovClampInt32(ent.collapse_exposure_milli / 1000, 0, 1000);
    const int pr = GovClampInt32(ent.pressure_milli / 1000, 0, 1000);
    const int sv = GovClampInt32(ent.survivability_milli / 1000, 0, 1000);
    const int ad = GovClampInt32(ent.adaptation_pressure_milli / 1000, 0, 1000);
    const int civ_st = GovClampInt32(civ.civilization_stability_milli / 1000, 0, 1000);
    const int tmp_decay = GovClampInt32(tmp.decay_composite_milli / 10000, 0, 1000);

    int code = (int)GOV_SPECIES_BALANCED;
    int conf = 500000;
    int margin = 0;

    if(ce >= 700 || ch >= 700) {
        code = (int)GOV_SPECIES_COLLAPSING;
        conf = GovClampInt32(GovSaturatingAdd32(ce * 1000, ch * 500), 0, 1000000000);
        margin = GovSaturatingAdd32(ce, -600);
    } else if(sv >= 700 && pr <= 300 && cont >= 500) {
        code = (int)GOV_SPECIES_RESILIENT;
        conf = GovClampInt32(sv * 1000 + cont * 500, 0, 1000000000);
        margin = GovSaturatingAdd32(sv, -pr);
    } else if(pr >= 750 && ad >= 600) {
        code = (int)GOV_SPECIES_PREDATORY;
        conf = GovClampInt32(pr * 800 + ad * 600, 0, 1000000000);
        margin = GovSaturatingAdd32(pr, -700);
    } else if(rc <= 200 && pr >= 500) {
        code = (int)GOV_SPECIES_PARASITIC;
        conf = GovClampInt32((1000 - rc) * 800 + pr * 400, 0, 1000000000);
        margin = GovSaturatingAdd32(pr, -450);
    } else if(rc >= 600 && ce <= 300 && res >= 550) {
        code = (int)GOV_SPECIES_REGENERATIVE;
        conf = GovClampInt32(rc * 900 + res * 400, 0, 1000000000);
        margin = GovSaturatingAdd32(rc, -500);
    } else if(sv <= 300 || ce >= 500 || tmp_decay >= 600) {
        code = (int)GOV_SPECIES_FRAGILE;
        conf = GovClampInt32((1000 - sv) * 700 + ce * 500 + tmp_decay * 300, 0, 1000000000);
        margin = GovSaturatingAdd32(500, -ce);
    } else {
        code = (int)GOV_SPECIES_BALANCED;
        conf = GovClampInt32(400000 + civ_st * 200 + (1000 - MathAbs(sv - pr)) * 100, 0, 1000000000);
        margin = GovSaturatingAdd32(100, -MathAbs(sv - pr) / 10);
    }

    out_sp.species_code = code;
    out_sp.classification_confidence_milli = GovClampInt32(conf, 0, 1000000000);
    out_sp.threshold_margin_milli = GovClampInt32(margin * 1000, -1000000000, 1000000000);
    return true;
}

#endif // __AURUM_GOV_ECO_SPECIES_V1_MQH__
