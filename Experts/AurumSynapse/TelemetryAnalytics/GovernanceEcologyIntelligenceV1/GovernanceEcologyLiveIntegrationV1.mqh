//+------------------------------------------------------------------+
//| GovernanceEcologyLiveIntegrationV1.mqh                          |
//| GOVERNANCE_ECOLOGY_INTELLIGENCE_V1 — live pipeline               |
//| Temporal stage matches GovTmpLiveV1_Run (GovTmpPipeV1_FromUtf8). |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECO_LIVE_V1_MQH__
#define __AURUM_GOV_ECO_LIVE_V1_MQH__

#include "../GovernanceTemporalIntelligenceV1/GovernanceTemporalLiveIntegrationV1.mqh"
#include "GovernanceEcosystemEngineV1.mqh"
#include "GovernanceSpeciesEngineV1.mqh"
#include "GovernancePredatorPreyV1.mqh"
#include "GovernanceResourcePressureV1.mqh"
#include "GovernanceBiodiversityV1.mqh"
#include "GovernanceEcologicalCollapseV1.mqh"
#include "GovernanceCoexistenceEngineV1.mqh"
#include "GovernanceEcologicalResilienceV1.mqh"
#include "GovernanceEcologyComparatorV1.mqh"
#include "GovernanceEcologyExportV1.mqh"

void GovEcoLiveV1_FillSummary(const SGovResilienceProfileV1 &rp, const int n_ent, const SGovEcologyBiodiversityV1 &bio, const SGovEcologyCollapseV1 &cl, const SGovEcologyCoexistenceV1 &cx, const SGovEcologyResilienceV1 &eres, const SGovEcologyPredPreyV1 &pred, SGovEcologySummaryV1 &sum) {
    GovEcoDsV1_InitSummary(sum);
    sum.ecology_window_id = 1;
    sum.replay_hash = rp.summary.replay_hash;
    sum.policy_fingerprint = rp.summary.policy_fingerprint;
    sum.entity_count = n_ent;
    sum.biodiversity_index_milli = bio.diversity_score_milli;
    sum.collapse_exposure_milli = GovClampInt32(GovSaturatingAdd32(cl.cascading_collapse_milli / 6, GovSaturatingAdd32(cl.collapse_contagion_milli / 6, cl.resilience_extinction_milli / 6)), 0, 1000000000);
    sum.coexistence_quality_milli = GovClampInt32(GovSaturatingAdd32(cx.coexistence_stability_milli / 2, cx.recovery_harmony_milli / 2), 0, 1000000000);
    sum.ecosystem_resilience_milli = eres.ecosystem_resilience_milli;
    sum.predation_pressure_milli = GovClampInt32(GovSaturatingAdd32(pred.survivability_predation_milli, pred.parasitic_load_milli), 0, 1000000000);
    const int pos = GovSaturatingAdd32(eres.long_horizon_ecological_survivability_milli / 3, bio.diversity_score_milli / 4);
    const int neg = GovSaturatingAdd32(sum.collapse_exposure_milli / 4, pred.collapse_propagation_milli / 5);
    sum.ecological_stability_milli = GovClampInt32(GovSaturatingAdd32(pos, -neg), 0, 1000000000);
}

bool GovEcoLiveV1_Run(const string utf8_lf, SGovEcologySummaryV1 &out_sum, string &out_bundle, string &out_err) {
    out_err = "";
    out_bundle = "";
    GovEcoDsV1_InitSummary(out_sum);
    SGovResilienceProfileV1 rp;
    string res_blk = "";
    SGovEvolutionSummaryV1 evo_sum;
    SGovEvolutionGenerationV1 gens[];
    string evo_blk = "";
    SGovStrategicSummaryV1 strat_sum;
    string strat_blk = "";
    SGovCivilizationSummaryV1 civ_sum;
    string civ_blk = "";
    SGovReplayTimelineV1 tl;
    SGovTemporalSummaryV1 tmp_sum;
    string tmp_blk = "";
    if(!GovTmpPipeV1_FromUtf8(utf8_lf, rp, res_blk, evo_sum, gens, evo_blk, strat_sum, strat_blk, civ_sum, civ_blk, tl, tmp_sum, tmp_blk, out_err))
        return false;
    const string tmp_bundle = res_blk + "\n===EVO_BLOCK===\n" + evo_blk + "\n===STRAT_BLOCK===\n" + strat_blk + "\n===CIVILIZATION_BLOCK===\n" + civ_blk + "\n===TEMPORAL_BLOCK===\n" + tmp_blk;
    SGovEcologyEntityV1 ents[];
    int n_ents = 0;
    if(!GovEcoSysV1_Build(tl, rp, evo_sum, strat_sum, civ_sum, tmp_sum, ents, n_ents, out_err))
        return false;
    SGovEcologySpeciesV1 sp[];
    ArrayResize(sp, n_ents);
    for(int k = 0; k < n_ents; k++) {
        if(!GovSpeciesV1_Classify(ents[k], rp, tl, civ_sum, tmp_sum, sp[k], out_err))
            return false;
        ents[k].species_code = sp[k].species_code;
    }
    SGovEcologyPredPreyV1 pred;
    if(!GovPredPreyV1_Analyze(ents, n_ents, pred, out_err))
        return false;
    SGovEcologyPressureV1 press;
    if(!GovResPressureV1_Compute(tl, rp, strat_sum, press, out_err))
        return false;
    SGovEcologyBiodiversityV1 bio;
    if(!GovBiodivV1_Compute(tl, ents, n_ents, sp, n_ents, civ_sum, bio, out_err))
        return false;
    SGovEcologyCollapseV1 cl;
    if(!GovEcoCollapseV1_Analyze(tl, ents, n_ents, bio, pred, cl, out_err))
        return false;
    SGovEcologyCoexistenceV1 cx;
    if(!GovCoexistV1_Compute(ents, n_ents, civ_sum, tmp_sum, cx, out_err))
        return false;
    SGovEcologyResilienceV1 eres;
    if(!GovEcoResV1_Compute(bio, cl, cx, press, eres, out_err))
        return false;
    SGovEcologySummaryV1 sum;
    GovEcoLiveV1_FillSummary(rp, n_ents, bio, cl, cx, eres, pred, sum);
    out_sum = sum;
    SGovEcologyComparisonV1 cmp;
    if(!GovEcoCmpV1_Diff(sum, sum, cmp, out_err))
        return false;
    string eco_inner = "";
    if(!GovEcoExpV1_Bundle(sum, sp, n_ents, pred, bio, cl, cx, eres, cmp, eco_inner, out_err))
        return false;
    out_bundle = tmp_bundle + "\n===ECOLOGY_BLOCK===\n" + eco_inner;
    return true;
}

#endif // __AURUM_GOV_ECO_LIVE_V1_MQH__
