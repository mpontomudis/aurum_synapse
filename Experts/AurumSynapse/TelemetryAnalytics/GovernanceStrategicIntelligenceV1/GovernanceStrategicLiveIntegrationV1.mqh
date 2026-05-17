//+------------------------------------------------------------------+
//| GovernanceStrategicLiveIntegrationV1.mqh                      |
//| … → evolution → strategic export (observational).               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRATEGIC_LIVEINT_V1_MQH__
#define __AURUM_GOV_STRATEGIC_LIVEINT_V1_MQH__

#include "../GovernanceEvolutionIntelligenceV1/GovernanceEvolutionLiveIntegrationV1.mqh"
#include "../GovernanceEvolutionIntelligenceV1/GovernanceDegenerationEngineV1.mqh"
#include "../GovernanceEvolutionIntelligenceV1/GovernanceEvolutionDriftV1.mqh"
#include "../GovernanceEvolutionIntelligenceV1/GovernanceEvolutionTopologyV1.mqh"
#include "../GovernanceEvolutionIntelligenceV1/GovernanceSurvivabilityEvolutionV1.mqh"
#include "GovernanceStrategicDatasetV1.mqh"
#include "GovernanceStrategicEnduranceV1.mqh"
#include "GovernanceInterventionBudgetV1.mqh"
#include "GovernanceStrategicContainmentV1.mqh"
#include "GovernanceSustainabilityTrajectoryV1.mqh"
#include "GovernanceCatastrophicResistanceV1.mqh"
#include "GovernanceStrategicResearchV1.mqh"
#include "GovernanceStrategicExportV1.mqh"

bool GovStrategicAggV1_BuildSummary(const SGovResilienceProfileV1 &rp, const SGovEvolutionSummaryV1 &evo, const SGovStrategicEnduranceV1 &en, const SGovStrategicBudgetV1 &bud, const SGovStrategicContainmentV1 &ctn,
                                    const SGovStrategicTrajectoryV1 &tr, const SGovCatastrophicResistanceV1 &cat, SGovStrategicSummaryV1 &sum, string &out_err) {
    out_err = "";
    GovStratDsV1_InitSummary(sum);
    sum.strategic_window_id = 1;
    sum.replay_hash = rp.summary.replay_hash;
    sum.policy_fingerprint = rp.summary.policy_fingerprint;
    sum.lineage_id = evo.lineage_id;
    sum.governance_health_0_1000 = rp.summary.governance_health_0_1000;
    sum.survivability_horizon_0_1000 = GovClampInt32(rp.curve.resilience_half_life_epochs * 80 + rp.summary.survivability_resilience_0_1000 / 2, 0, 1000);
    sum.endurance_capacity_0_1000 = en.endurance_composite_0_1000;
    sum.intervention_budget_score_0_1000 = bud.budget_pressure_composite_0_1000;
    sum.strategic_containment_quality_0_1000 = GovClampInt32((ctn.long_cycle_stability_0_1000 + ctn.containment_pacing_quality_0_1000) / 2, 0, 1000);
    sum.sustainability_index_0_1000 = GovClampInt32((tr.degradation_stabilization_0_1000 + tr.recovery_sustainability_traj_0_1000 + tr.fatigue_stabilization_0_1000) / 3, 0, 1000);
    sum.catastrophic_resistance_0_1000 = cat.catastrophic_resistance_score_0_1000;
    sum.degradation_stability_0_1000 = tr.degradation_stabilization_0_1000;
    sum.regime_endurance_balance_0_1000 = tr.regime_endurance_balance_0_1000;
    sum.collapse_avoidance_score_0_1000 = GovClampInt32(1000 - tr.collapse_trajectory_risk_0_1000 / 2 + rp.summary.collapse_resistance_0_1000 / 4, 0, 1000);
    sum.recovery_sustainability_0_1000 = tr.recovery_sustainability_traj_0_1000;
    sum.fatigue_sustainability_0_1000 = tr.fatigue_stabilization_0_1000;
    sum.strategic_epoch_count = rp.summary.replay_epoch_count;
    return true;
}

bool GovStratPipeV1_FromResilienceProfile(const SGovResilienceProfileV1 &rp, SGovEvolutionSummaryV1 &evo_out, SGovEvolutionGenerationV1 &gens_out[], string &evo_blk_out, SGovStrategicSummaryV1 &strat_out, string &strat_blk_out, string &out_err) {
    out_err = "";
    GovStratDsV1_InitSummary(strat_out);
    evo_blk_out = "";
    GovEvoDsV1_InitSummary(evo_out);
    if(!GovEvoPipeV1_FromResilienceProfile(rp, evo_out, gens_out, evo_blk_out, out_err))
        return false;
    const int n = ArraySize(gens_out);
    SGovDegenerationV1 dg;
    if(!GovDegV1_FromGenerations(gens_out, n, dg, out_err))
        return false;
    SGovEvolutionDriftV1 dr;
    if(!GovEvoDriftV1_Compute(gens_out, n, dg, dr, out_err))
        return false;
    SGovEvolutionTopologyV1 tp;
    if(!GovEvoTopoV1_BuildLinear(gens_out, n, rp.summary.replay_hash, tp, out_err))
        return false;
    SGovEvolutionSurvivabilityV1 sv;
    if(!GovSurvEvoV1_Compute(gens_out, n, sv, out_err))
        return false;
    SGovStrategicEnduranceV1 en;
    if(!GovStratEndV1_Measure(rp, sv, dg, en, out_err))
        return false;
    SGovStrategicBudgetV1 bud;
    if(!GovStratBudV1_Measure(rp, bud, out_err))
        return false;
    SGovStrategicContainmentV1 ctn;
    if(!GovStratCtnV1_Measure(rp, ctn, out_err))
        return false;
    SGovStrategicTrajectoryV1 traj;
    if(!GovStratTrajV1_Compute(rp, dr, sv, traj, out_err))
        return false;
    SGovCatastrophicResistanceV1 cat;
    if(!GovStratCatV1_Score(rp, gens_out, n, dg, cat, out_err))
        return false;
    if(!GovStrategicAggV1_BuildSummary(rp, evo_out, en, bud, ctn, traj, cat, strat_out, out_err))
        return false;
    int ord[32];
    GovStratResV1_RankEnduranceProxy(gens_out, n, ord);
    strat_blk_out = "";
    if(!GovStrategicExpV1_Bundle(strat_out, en, bud, ctn, traj, cat, gens_out, n, ord, strat_blk_out, out_err))
        return false;
    return true;
}

bool GovStrategicLiveV1_Run(const string utf8_lf, SGovStrategicSummaryV1 &out_sum, string &out_bundle, string &out_err) {
    out_err = "";
    out_bundle = "";
    GovStratDsV1_InitSummary(out_sum);
    SGovResilienceProfileV1 rp;
    string res_blk = "";
    if(!GovResilLiveV1_Run(utf8_lf, rp, res_blk, out_err))
        return false;
    SGovEvolutionSummaryV1 evo_sum;
    SGovEvolutionGenerationV1 gens[];
    string evo_blk = "";
    string strat_blk = "";
    if(!GovStratPipeV1_FromResilienceProfile(rp, evo_sum, gens, evo_blk, out_sum, strat_blk, out_err))
        return false;
    out_bundle = res_blk + "\n===EVO_BLOCK===\n" + evo_blk + "\n===STRAT_BLOCK===\n" + strat_blk;
    return true;
}

#endif // __AURUM_GOV_STRATEGIC_LIVEINT_V1_MQH__
