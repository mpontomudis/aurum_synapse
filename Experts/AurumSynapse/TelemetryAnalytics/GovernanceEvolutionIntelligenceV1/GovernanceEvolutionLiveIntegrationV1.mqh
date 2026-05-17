//+------------------------------------------------------------------+
//| GovernanceEvolutionLiveIntegrationV1.mqh                     |
//| … → resilience → evolution → export (observational).            |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EVO_LIVE_V1_MQH__
#define __AURUM_GOV_EVO_LIVE_V1_MQH__

#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceLiveIntegrationV1.mqh"
#include "GovernanceEvolutionDatasetV1.mqh"
#include "GovernanceLineageEngineV1.mqh"
#include "GovernanceDegenerationEngineV1.mqh"
#include "GovernanceEvolutionDriftV1.mqh"
#include "GovernanceEvolutionTopologyV1.mqh"
#include "GovernanceSurvivabilityEvolutionV1.mqh"
#include "GovernanceEvolutionResearchV1.mqh"
#include "GovernanceEvolutionExportV1.mqh"

bool GovEvoAggV1_BuildSummary(const SGovEvolutionGenerationV1 &gens[], const int n, const SGovEvolutionTopologyV1 &tp, const SGovDegenerationV1 &dg, const SGovResilienceProfileV1 &rp,
                              SGovEvolutionSummaryV1 &sum, string &out_err) {
    out_err = "";
    GovEvoDsV1_InitSummary(sum);
    if(n < 1)
        return true;
    sum.lineage_id = gens[0].lineage_id;
    sum.replay_hash = rp.summary.replay_hash;
    sum.policy_fingerprint = rp.summary.policy_fingerprint;
    sum.generation_span = n;
    sum.topology_branching_factor_0_1000 = GovClampInt32(tp.branch_count * 1000, 0, 1000);
    sum.max_degeneration_velocity_milli = dg.degeneration_velocity_milli;
    sum.mean_degeneration_score_0_1000 = dg.degeneration_score_0_1000;
    int surv_acc = 0;
    for(int i = 0; i < n; i++)
        surv_acc = GovSaturatingAdd32(surv_acc, gens[i].survivability_score_0_1000);
    sum.mean_survivability_0_1000 = surv_acc / GovClampInt32(n, 1, 1000000);
    int best_ix = 1;
    if(n > 1) {
        for(int k = 2; k < n; k++) {
            const int rb = gens[k].resilience_profile_0_1000;
            const int ra = gens[best_ix].resilience_profile_0_1000;
            if(rb > ra)
                best_ix = k;
            else if(rb == ra && gens[k].archetype_class < gens[best_ix].archetype_class)
                best_ix = k;
        }
        sum.dominant_archetype_class = gens[best_ix].archetype_class;
    } else
        sum.dominant_archetype_class = gens[0].archetype_class;
    return true;
}

bool GovEvoPipeV1_FromResilienceProfile(const SGovResilienceProfileV1 &rp, SGovEvolutionSummaryV1 &out_sum, SGovEvolutionGenerationV1 &gens[], string &evo_blk, string &out_err) {
    out_err = "";
    evo_blk = "";
    GovEvoDsV1_InitSummary(out_sum);
    SGovEvolutionLineageV1 lin;
    if(!GovLinEngV1_FromResilience(rp, lin, gens, out_err))
        return false;
    const int n = ArraySize(gens);
    SGovDegenerationV1 dg;
    if(!GovDegV1_FromGenerations(gens, n, dg, out_err))
        return false;
    SGovEvolutionDriftV1 dr;
    if(!GovEvoDriftV1_Compute(gens, n, dg, dr, out_err))
        return false;
    SGovEvolutionTopologyV1 tp;
    if(!GovEvoTopoV1_BuildLinear(gens, n, rp.summary.replay_hash, tp, out_err))
        return false;
    SGovEvolutionSurvivabilityV1 sv;
    if(!GovSurvEvoV1_Compute(gens, n, sv, out_err))
        return false;
    if(!GovEvoAggV1_BuildSummary(gens, n, tp, dg, rp, out_sum, out_err))
        return false;
    int ord[32];
    GovEvoResV1_RankByResilience(gens, n, ord);
    if(!GovEvoExpV1_Bundle(out_sum, lin, gens, n, dr, tp, sv, dg, ord, evo_blk, out_err))
        return false;
    return true;
}

bool GovEvoLiveV1_Run(const string utf8_lf, SGovEvolutionSummaryV1 &out_sum, string &out_bundle, string &out_err) {
    out_err = "";
    out_bundle = "";
    GovEvoDsV1_InitSummary(out_sum);
    SGovResilienceProfileV1 rp;
    string res_bundle = "";
    if(!GovResilLiveV1_Run(utf8_lf, rp, res_bundle, out_err))
        return false;
    SGovEvolutionGenerationV1 gens[];
    string evo_blk = "";
    if(!GovEvoPipeV1_FromResilienceProfile(rp, out_sum, gens, evo_blk, out_err))
        return false;
    out_bundle = res_bundle + "\n===EVO_BLOCK===\n" + evo_blk;
    return true;
}

#endif // __AURUM_GOV_EVO_LIVE_V1_MQH__
