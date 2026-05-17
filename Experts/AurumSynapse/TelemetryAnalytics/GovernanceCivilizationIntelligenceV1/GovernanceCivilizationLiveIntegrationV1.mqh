//+------------------------------------------------------------------+
//| GovernanceCivilizationLiveIntegrationV1.mqh                      |
//| Resilience → evolution → strategic → civilization (observational). |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CIV_LIVE_V1_MQH__
#define __AURUM_GOV_CIV_LIVE_V1_MQH__

#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceLiveIntegrationV1.mqh"
#include "../GovernanceStrategicIntelligenceV1/GovernanceStrategicLiveIntegrationV1.mqh"
#include "../GovernanceEvolutionIntelligenceV1/GovernanceDegenerationEngineV1.mqh"
#include "GovernanceCivilizationDatasetV1.mqh"
#include "GovernanceFederationEngineV1.mqh"
#include "GovernanceHierarchyEngineV1.mqh"
#include "GovernanceDiplomacyEngineV1.mqh"
#include "GovernanceCivilizationMemoryV1.mqh"
#include "GovernanceCivilizationTopologyV1.mqh"
#include "GovernanceCivilizationStabilityV1.mqh"
#include "GovernanceCivilizationCollapseV1.mqh"
#include "GovernanceCivilizationResearchV1.mqh"
#include "GovernanceCivilizationExportV1.mqh"

bool GovCivAggV1_BuildSummary(const SGovResilienceProfileV1 &rp, const SGovStrategicSummaryV1 &strat, const SGovEvolutionSummaryV1 &evo, const SGovCivilizationFederationV1 &fed, const SGovCivilizationHierarchyV1 &hier, const SGovCivilizationDiplomacyV1 &dip, const SGovCivilizationMemoryV1 &mem, const SGovCivilizationTopologyV1 &topo, const SGovCivilizationStabilityV1 &stab, const SGovCivilizationCollapseV1 &clps, const SGovCivilizationNodeV1 &nodes[], const int nn, SGovCivilizationSummaryV1 &sum, string &out_err) {
    out_err = "";
    GovCivDsV1_InitSummary(sum);
    if(nn < 1 || nn > 32) {
        out_err = "GOV_CIV_AGG_N";
        return false;
    }
    sum.civilization_window_id = 1;
    sum.replay_hash = rp.summary.replay_hash;
    sum.policy_fingerprint = rp.summary.policy_fingerprint;
    sum.lineage_id = evo.lineage_id;
    sum.federation_stability_milli = fed.federation_stability_milli;
    sum.hierarchy_stability_milli = hier.hierarchy_stability_milli;
    sum.diplomacy_alignment_milli = dip.diplomacy_alignment_milli;
    sum.topology_stability_milli = topo.topology_stability_milli;
    sum.memory_stable_cycles = mem.stable_cycles;
    sum.civilization_stability_milli = stab.civilization_stability_milli;
    sum.systemic_collapse_risk_milli = clps.systemic_collapse_risk_milli;
    sum.continuity_milli = stab.governance_continuity_milli;
    long acc_rb = 0;
    for(int i = 0; i < nn; i++)
        acc_rb += (long)nodes[i].regime_balance_milli;
    const int div = GovClampInt32(nn, 1, 32);
    sum.regime_balance_milli = GovClampInt32((int)(acc_rb / (long)div), 0, 1000000);
    return true;
}

bool GovCivPipeV1_FromUtf8(const string utf8_lf, SGovResilienceProfileV1 &rp, string &res_blk, SGovEvolutionSummaryV1 &evo_sum, SGovEvolutionGenerationV1 &gens[], string &evo_blk, SGovStrategicSummaryV1 &strat_sum, string &strat_blk, SGovCivilizationSummaryV1 &civ_sum, string &civ_blk, string &out_err) {
    out_err = "";
    GovCivDsV1_InitSummary(civ_sum);
    res_blk = "";
    evo_blk = "";
    strat_blk = "";
    civ_blk = "";
    GovResilDsV1_InitProfile(rp);
    if(!GovResilLiveV1_Run(utf8_lf, rp, res_blk, out_err))
        return false;
    GovEvoDsV1_InitSummary(evo_sum);
    if(!GovStratPipeV1_FromResilienceProfile(rp, evo_sum, gens, evo_blk, strat_sum, strat_blk, out_err))
        return false;
    const int n = ArraySize(gens);
    if(n < 1) {
        out_err = "GOV_CIV_PIPE_NOGEN";
        return false;
    }
    SGovDegenerationV1 dg;
    if(!GovDegV1_FromGenerations(gens, n, dg, out_err))
        return false;
    SGovCivilizationFederationV1 fed;
    if(!GovFedEngV1_Build(evo_sum, strat_sum, rp, fed, out_err))
        return false;
    SGovCivilizationNodeV1 nodes[];
    if(!GovCivDsV1_BuildNodes(gens, n, rp, strat_sum, nodes, out_err))
        return false;
    SGovCivilizationHierarchyV1 hier;
    if(!GovHierEngV1_Build(nodes, n, hier, out_err))
        return false;
    SGovCivilizationDiplomacyV1 dip;
    if(!GovDipEngV1_Compute(rp, strat_sum, dip, out_err))
        return false;
    SGovCivilizationMemoryV1 mem;
    if(!GovCivMemV1_Update(gens, n, dg, mem, out_err))
        return false;
    SGovCivilizationTopologyV1 topo;
    if(!GovCivTopoV1_Build(nodes, n, fed, topo, out_err))
        return false;
    SGovCivilizationStabilityV1 stab;
    if(!GovCivStabV1_Compute(fed, hier, dip, mem, topo, strat_sum, rp, stab, out_err))
        return false;
    SGovCivilizationCollapseV1 clps;
    if(!GovCivClpsV1_Compute(rp, strat_sum, hier, topo, dg, fed, clps, out_err))
        return false;
    if(!GovCivAggV1_BuildSummary(rp, strat_sum, evo_sum, fed, hier, dip, mem, topo, stab, clps, nodes, n, civ_sum, out_err))
        return false;
    int ix_order[32];
    if(!GovCivResV1_RankCivilizations(nodes, n, fed, ix_order, out_err))
        return false;
    if(!GovCivExpV1_Bundle(civ_sum, fed, hier, dip, mem, topo, stab, clps, nodes, ix_order, n, civ_blk, out_err))
        return false;
    return true;
}

bool GovCivLiveV1_Run(const string utf8_lf, SGovCivilizationSummaryV1 &out_sum, string &out_bundle, string &out_err) {
    out_err = "";
    out_bundle = "";
    GovCivDsV1_InitSummary(out_sum);
    SGovResilienceProfileV1 rp;
    string res_blk = "";
    SGovEvolutionSummaryV1 evo_sum;
    SGovEvolutionGenerationV1 gens[];
    string evo_blk = "";
    string strat_blk = "";
    SGovStrategicSummaryV1 strat_sum;
    string civ_blk = "";
    if(!GovCivPipeV1_FromUtf8(utf8_lf, rp, res_blk, evo_sum, gens, evo_blk, strat_sum, strat_blk, out_sum, civ_blk, out_err))
        return false;
    out_bundle = res_blk + "\n===EVO_BLOCK===\n" + evo_blk + "\n===STRAT_BLOCK===\n" + strat_blk + "\n===CIVILIZATION_BLOCK===\n" + civ_blk;
    return true;
}

#endif // __AURUM_GOV_CIV_LIVE_V1_MQH__
