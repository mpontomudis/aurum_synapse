//+------------------------------------------------------------------+
//| GovernanceTemporalLiveIntegrationV1.mqh                        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_TMP_LIVE_V1_MQH__
#define __AURUM_GOV_TMP_LIVE_V1_MQH__

#include "../GovernanceCivilizationIntelligenceV1/GovernanceCivilizationLiveIntegrationV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayParserV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "GovernanceTemporalDatasetV1.mqh"
#include "GovernanceEpochEngineV1.mqh"
#include "GovernanceAgingEngineV1.mqh"
#include "GovernanceContinuityEngineV1.mqh"
#include "GovernanceCycleEngineV1.mqh"
#include "GovernanceEraTransitionV1.mqh"
#include "GovernanceTemporalPressureV1.mqh"
#include "GovernanceTemporalDecayV1.mqh"
#include "GovernanceTemporalStabilityV1.mqh"
#include "GovernanceTemporalResearchV1.mqh"
#include "GovernanceTemporalExportV1.mqh"

bool GovTmpAggV1_BuildSummary(const SGovResilienceProfileV1 &rp, const SGovTemporalStabilityV1 &stab, const SGovEraTransitionV1 &era, const SGovTemporalPressureV1 &press, const SGovTemporalDecayV1 &dec, const SGovContinuityV1 &cont, const SGovGovernanceAgingV1 &aging, const int n_ep, SGovTemporalSummaryV1 &sum, string &out_err) {
    out_err = "";
    GovTmpDsV1_InitSummary(sum);
    sum.temporal_window_id = 1;
    sum.replay_hash = rp.summary.replay_hash;
    sum.policy_fingerprint = rp.summary.policy_fingerprint;
    sum.epoch_count = n_ep;
    sum.temporal_stability_milli = stab.temporal_stability_milli;
    sum.long_cycle_survivability_milli = stab.long_horizon_survivability_milli;
    sum.era_transition_pressure_milli = era.transition_pressure_milli;
    sum.cumulative_temporal_pressure_milli = press.cumulative_pressure_milli;
    const int dc = GovSaturatingAdd32(dec.decay_acceleration_milli / 5, dec.resilience_decay_milli / 5);
    sum.decay_composite_milli = GovClampInt32(GovSaturatingAdd32(dc, GovSaturatingAdd32(dec.survivability_decay_milli / 5, dec.civilization_decay_milli / 5)), 0, 1000000000);
    sum.continuity_strength_milli = cont.continuity_strength_milli;
    sum.aging_entropy_milli = aging.governance_entropy_milli;
    return true;
}

bool GovTmpPipeV1_FromUtf8(const string utf8_lf, SGovResilienceProfileV1 &rp, string &res_blk, SGovEvolutionSummaryV1 &evo_sum, SGovEvolutionGenerationV1 &gens[], string &evo_blk, SGovStrategicSummaryV1 &strat_sum, string &strat_blk, SGovCivilizationSummaryV1 &civ_sum, string &civ_blk, SGovReplayTimelineV1 &tl, SGovTemporalSummaryV1 &tmp_sum, string &tmp_blk, string &out_err) {
    out_err = "";
    GovTmpDsV1_InitSummary(tmp_sum);
    res_blk = "";
    evo_blk = "";
    strat_blk = "";
    civ_blk = "";
    tmp_blk = "";
    if(!GovCivPipeV1_FromUtf8(utf8_lf, rp, res_blk, evo_sum, gens, evo_blk, strat_sum, strat_blk, civ_sum, civ_blk, out_err))
        return false;
    string norm = "";
    GovernanceReplayParserV1_NormalizeLf(utf8_lf, norm);
    GovernanceReplayDatasetV1_InitTimeline(tl);
    if(!GovernanceReplayParserV1_ParseMultilineUtf8Lf(norm, tl, out_err))
        return false;
    SGovTemporalEpochV1 ep[];
    if(!GovEpochEngV1_Build(tl, civ_sum, strat_sum, ep, out_err))
        return false;
    const int n_ep = ArraySize(ep);
    SGovGovernanceAgingV1 aging;
    if(!GovAgeEngV1_Compute(ep, n_ep, rp, aging, out_err))
        return false;
    SGovContinuityV1 cont;
    if(!GovContEngV1_Compute(ep, n_ep, civ_sum, strat_sum, cont, out_err))
        return false;
    SGovCyclePatternV1 cyc;
    if(!GovCycleEngV1_Analyze(ep, n_ep, cyc, out_err))
        return false;
    SGovEraTransitionV1 era;
    if(!GovEraTrV1_Compute(ep, n_ep, civ_sum, strat_sum, era, out_err))
        return false;
    SGovTemporalPressureV1 press;
    if(!GovTmpPressV1_Compute(ep, n_ep, aging, era, rp, press, out_err))
        return false;
    SGovTemporalDecayV1 dec;
    if(!GovTmpDecayV1_Compute(ep, n_ep, civ_sum, strat_sum, rp, dec, out_err))
        return false;
    SGovTemporalStabilityV1 stab;
    if(!GovTmpStabV1_Compute(cont, press, dec, civ_sum, strat_sum, stab, out_err))
        return false;
    if(!GovTmpAggV1_BuildSummary(rp, stab, era, press, dec, cont, aging, n_ep, tmp_sum, out_err))
        return false;
    int ix_rank[128];
    if(!GovTmpResV1_RankEpochs(ep, n_ep, ix_rank, out_err))
        return false;
    if(!GovTmpExpV1_Bundle(tmp_sum, ep, n_ep, aging, cont, cyc, era, press, dec, stab, ix_rank, tmp_blk, out_err))
        return false;
    return true;
}

bool GovTmpLiveV1_Run(const string utf8_lf, SGovTemporalSummaryV1 &out_sum, string &out_bundle, string &out_err) {
    out_err = "";
    out_bundle = "";
    GovTmpDsV1_InitSummary(out_sum);
    SGovResilienceProfileV1 rp;
    string res_blk = "";
    SGovEvolutionSummaryV1 evo_sum;
    SGovEvolutionGenerationV1 gens[];
    string evo_blk = "";
    string strat_blk = "";
    SGovStrategicSummaryV1 strat_sum;
    SGovCivilizationSummaryV1 civ_sum;
    string civ_blk = "";
    SGovReplayTimelineV1 tl;
    string tmp_blk = "";
    if(!GovTmpPipeV1_FromUtf8(utf8_lf, rp, res_blk, evo_sum, gens, evo_blk, strat_sum, strat_blk, civ_sum, civ_blk, tl, out_sum, tmp_blk, out_err))
        return false;
    out_bundle = res_blk + "\n===EVO_BLOCK===\n" + evo_blk + "\n===STRAT_BLOCK===\n" + strat_blk + "\n===CIVILIZATION_BLOCK===\n" + civ_blk + "\n===TEMPORAL_BLOCK===\n" + tmp_blk;
    return true;
}

#endif // __AURUM_GOV_TMP_LIVE_V1_MQH__
