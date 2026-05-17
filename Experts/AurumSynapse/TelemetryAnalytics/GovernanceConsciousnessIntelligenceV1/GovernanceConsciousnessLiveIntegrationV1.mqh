//+------------------------------------------------------------------+
//| GovernanceConsciousnessLiveIntegrationV1.mqh                    |
//| GOVERNANCE_CONSCIOUSNESS_INTELLIGENCE_V1 — live pipeline          |
//| Step 2 (replay timeline) is aligned with GovTmpPipeV1_FromUtf8.   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CON_LIVE_V1_MQH__
#define __AURUM_GOV_CON_LIVE_V1_MQH__

#include "../GovernanceEcologyIntelligenceV1/GovernanceEcologyLiveIntegrationV1.mqh"
#include "../GovernanceTemporalIntelligenceV1/GovernanceTemporalLiveIntegrationV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayParserV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "GovernanceIdentityEngineV1.mqh"
#include "GovernanceCoherenceEngineV1.mqh"
#include "GovernanceMemoryIntegrityV1.mqh"
#include "GovernanceAwarenessEngineV1.mqh"
#include "GovernanceCollapseAwarenessV1.mqh"
#include "GovernanceSelfConsistencyV1.mqh"
#include "GovernanceContinuityAwarenessV1.mqh"
#include "GovernanceConsciousnessExportV1.mqh"

void GovConLiveV1_FillSummary(const SGovResilienceProfileV1 &rp, const SGovIdentityProfileV1 &idp, const SGovCoherenceProfileV1 &coh, const SGovMemoryIntegrityV1 &mem, const SGovAwarenessProfileV1 &aw, const SGovCollapseAwarenessV1 &clp, const SGovSelfConsistencyV1 &sc, const SGovContinuityAwarenessV1 &ca, SGovConsciousnessSummaryV1 &sum) {
    GovConDsV1_InitSummary(sum);
    sum.consciousness_window_id = 1;
    sum.replay_hash = rp.summary.replay_hash;
    sum.policy_fingerprint = rp.summary.policy_fingerprint;
    sum.integrity_index_milli = GovClampInt32(GovSaturatingAdd32(idp.identity_integrity_milli / 2, GovSaturatingAdd32(1000000 - idp.identity_fragmentation_milli / 4, idp.identity_recovery_strength_milli / 4)), 0, 1000000000);
    const int cmean = GovSaturatingAdd32(coh.strategic_coherence_milli / 5, GovSaturatingAdd32(coh.resilience_coherence_milli / 5, GovSaturatingAdd32(coh.temporal_coherence_milli / 5, GovSaturatingAdd32(coh.ecological_coherence_milli / 5, coh.civilization_coherence_milli / 5))));
    sum.coherence_index_milli = GovClampInt32(GovSaturatingAdd32(cmean / 2, GovSaturatingAdd32(-coh.contradiction_pressure_milli / 6, -coh.instability_oscillation_milli / 6)), 0, 1000000000);
    const int amean = GovSaturatingAdd32(aw.survivability_awareness_milli, GovSaturatingAdd32(aw.collapse_awareness_milli, GovSaturatingAdd32(aw.resilience_awareness_milli, GovSaturatingAdd32(aw.ecological_awareness_milli, aw.temporal_awareness_milli)))) / 5;
    sum.awareness_index_milli = GovClampInt32(amean, 0, 1000000000);
    const int mmean = GovSaturatingAdd32(mem.replay_continuity_milli, GovSaturatingAdd32(mem.epoch_continuity_milli, GovSaturatingAdd32(mem.governance_memory_persistence_milli / 2, GovSaturatingAdd32(mem.collapse_memory_retention_milli / 2, mem.recovery_memory_stability_milli)))) / 5;
    sum.memory_index_milli = GovClampInt32(mmean, 0, 1000000000);
    sum.self_consistency_index_milli = GovClampInt32(GovSaturatingAdd32(GovSaturatingAdd32(sc.recovery_consistency_milli / 4, sc.intervention_consistency_milli / 4), GovSaturatingAdd32(sc.containment_consistency_milli / 4, sc.regime_continuity_consistency_milli / 4)) - sc.contradiction_score_milli / 8, 0, 1000000000);
    sum.continuity_index_milli = GovClampInt32(GovSaturatingAdd32(ca.continuity_persistence_milli / 3, GovSaturatingAdd32(ca.long_horizon_awareness_milli / 3, ca.civilization_continuity_awareness_milli / 3)), 0, 1000000000);
    const int pos = GovSaturatingAdd32(sum.integrity_index_milli / 6, GovSaturatingAdd32(sum.coherence_index_milli / 6, GovSaturatingAdd32(sum.awareness_index_milli / 6, GovSaturatingAdd32(sum.memory_index_milli / 6, GovSaturatingAdd32(sum.self_consistency_index_milli / 6, sum.continuity_index_milli / 6)))));
    const int neg = GovSaturatingAdd32(clp.collapse_trajectory_awareness_milli / 10, GovSaturatingAdd32(clp.ecological_collapse_awareness_milli / 12, coh.fragmented_behavior_milli / 10));
    sum.consciousness_stability_milli = GovClampInt32(GovSaturatingAdd32(pos, -neg), 0, 1000000000);
}

bool GovConLiveV1_Run(const string utf8_lf, SGovConsciousnessSummaryV1 &out_sum, string &out_bundle, string &out_err) {
    out_err = "";
    out_bundle = "";
    GovConDsV1_InitSummary(out_sum);
    SGovEcologySummaryV1 eco_sum;
    string eco_bundle = "";
    if(!GovEcoLiveV1_Run(utf8_lf, eco_sum, eco_bundle, out_err))
        return false;
    string norm = "";
    GovernanceReplayParserV1_NormalizeLf(utf8_lf, norm);
    SGovReplayTimelineV1 tl_parse;
    GovernanceReplayDatasetV1_InitTimeline(tl_parse);
    if(!GovernanceReplayParserV1_ParseMultilineUtf8Lf(norm, tl_parse, out_err))
        return false;
    SGovResilienceProfileV1 rp;
    string res_blk = "";
    SGovEvolutionSummaryV1 evo_sum;
    SGovEvolutionGenerationV1 gens[];
    string evo_blk = "";
    SGovStrategicSummaryV1 strat_sum;
    string strat_blk = "";
    SGovCivilizationSummaryV1 civ_sum;
    string civ_blk = "";
    SGovReplayTimelineV1 tl_pipe;
    SGovTemporalSummaryV1 tmp_sum;
    string tmp_blk = "";
    if(!GovTmpPipeV1_FromUtf8(utf8_lf, rp, res_blk, evo_sum, gens, evo_blk, strat_sum, strat_blk, civ_sum, civ_blk, tl_pipe, tmp_sum, tmp_blk, out_err))
        return false;
    SGovIdentityProfileV1 idp;
    if(!GovIdentityV1_Build(tl_parse, rp, evo_sum, civ_sum, tmp_sum, eco_sum, idp, out_err))
        return false;
    SGovCoherenceProfileV1 coh;
    if(!GovCoherenceV1_Compute(strat_sum, rp, tmp_sum, eco_sum, civ_sum, coh, out_err))
        return false;
    SGovMemoryIntegrityV1 mem;
    if(!GovMemIntV1_Analyze(tl_parse, rp, mem, out_err))
        return false;
    SGovAwarenessProfileV1 aw;
    if(!GovAwareV1_Compute(tl_parse, rp, tmp_sum, eco_sum, aw, out_err))
        return false;
    SGovCollapseAwarenessV1 clp;
    if(!GovCollapseAwareV1_Compute(strat_sum, civ_sum, tmp_sum, eco_sum, clp, out_err))
        return false;
    SGovSelfConsistencyV1 sc;
    if(!GovSelfConsV1_Compute(strat_sum, rp, civ_sum, sc, out_err))
        return false;
    SGovContinuityAwarenessV1 ca;
    if(!GovContAwareV1_Compute(tl_parse, tmp_sum, civ_sum, ca, out_err))
        return false;
    SGovConsciousnessSummaryV1 sum;
    GovConLiveV1_FillSummary(rp, idp, coh, mem, aw, clp, sc, ca, sum);
    out_sum = sum;
    string con_inner = "";
    if(!GovConExpV1_Bundle(sum, idp, coh, mem, aw, clp, sc, ca, con_inner, out_err))
        return false;
    out_bundle = eco_bundle + "\n===CONSCIOUSNESS_BLOCK===\n" + con_inner;
    return true;
}

#endif // __AURUM_GOV_CON_LIVE_V1_MQH__
