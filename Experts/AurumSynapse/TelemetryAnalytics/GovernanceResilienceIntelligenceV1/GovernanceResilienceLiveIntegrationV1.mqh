//+------------------------------------------------------------------+
//| GovernanceResilienceLiveIntegrationV1.mqh                     |
//| replay → meta → research → simulation → resilience → export.   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RESIL_LIVE_V1_MQH__
#define __AURUM_GOV_RESIL_LIVE_V1_MQH__

#include "../GovernanceAutonomousResearchV1/GovernanceResearchLiveIntegrationV1.mqh"
#include "../GovernanceSimulationLabV1/GovernanceReplaySimulationLabV1.mqh"
#include "../GovernanceSimulationLabV1/GovernanceStressTestEngineV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceContainmentAnalyticsV1.mqh"
#include "GovernanceResilienceDatasetV1.mqh"
#include "GovernanceResilienceCurveEngineV1.mqh"
#include "GovernanceFatigueEngineV1.mqh"
#include "GovernanceCollapseResistanceV1.mqh"
#include "GovernanceRegimeBrittlenessV1.mqh"
#include "GovernanceResilienceResearchV1.mqh"
#include "GovernanceResilienceExportV1.mqh"

bool GovResilLiveV1_Run(const string utf8_lf, SGovResilienceProfileV1 &out_prof, string &out_bundle, string &out_err) {
    out_err = "";
    out_bundle = "";
    GovResilDsV1_InitProfile(out_prof);
    SGovMetaGovernanceHealthV1 h;
    SGovMetaPolicyFingerprintV1 fp;
    SGovMetaIncidentStatsV1 inc;
    SGovMetaContainmentStatsV1 eff;
    SGovMetaRegimeStatsV1 reg;
    string meta_blk = "";
    if(!GovMetaLiveV1_BuildReplay(utf8_lf, h, fp, inc, eff, reg, meta_blk, out_err))
        return false;
    string norm = "";
    GovernanceReplayParserV1_NormalizeLf(utf8_lf, norm);
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    if(!GovernanceReplayParserV1_ParseMultilineUtf8Lf(norm, tl, out_err))
        return false;
    SGovIncidentSummaryV1 isum;
    string e2 = "";
    if(!GovernanceIncidentDetectorV1_DetectAll(tl, isum, e2)) {
        out_err = e2;
        return false;
    }
    SGovResearchSummaryV1 res_sum;
    GovResDsV1_InitSum(res_sum);
    if(!GovResSumV1_Build(tl, h, inc, eff, fp, res_sum, out_err))
        return false;
    if(!GovResObsV1_Scan(tl, inc, isum, res_sum, out_err))
        return false;
    string res_blk = "";
    if(!GovResExpV1_Bundle(res_sum, "", meta_blk, res_blk, out_err))
        return false;
    int archs[7];
    archs[0] = GOV_ARCH_V1_SURV_FIRST;
    archs[1] = GOV_ARCH_V1_AGGR_CONT;
    archs[2] = GOV_ARCH_V1_QUAR_HEAVY;
    archs[3] = GOV_ARCH_V1_THR_HEAVY;
    archs[4] = GOV_ARCH_V1_REC_CONSERV;
    archs[5] = GOV_ARCH_V1_FLAT_AGGR;
    archs[6] = GOV_ARCH_V1_BALANCED;
    SGovSimPolicyRunV1 sim_runs[];
    if(!GovRplSimLabV1_RunMulti(tl, archs, 7, sim_runs, out_err))
        return false;
    SGovContainmentMetricsV1 cm;
    if(!GovernanceContainmentAnalyticsV1_Compute(tl, cm, out_err))
        return false;
    SGovResilienceCurveV1 curve;
    if(!GovResilCurveV1_Build(tl, curve, out_err))
        return false;
    SGovGovernanceFatigueV1 fatigue;
    if(!GovFatigueV1_Measure(tl, fatigue, out_err))
        return false;
    SGovCollapseResistanceV1 clps;
    if(!GovClpsResV1_Score(tl, cm, isum, clps, out_err))
        return false;
    SGovRegimeBrittlenessV1 brittle;
    if(!GovBrittleV1_Measure(tl, reg, brittle, out_err))
        return false;
    const int n = ArraySize(tl.epochs);
    SGovResilienceSummaryV1 summ;
    GovResilDsV1_InitSummary(summ);
    summ.resilience_window_id = 1;
    summ.replay_hash = tl.source_concat_sha256_hex;
    summ.policy_fingerprint = fp.dominant_policy_fingerprint;
    summ.governance_health_0_1000 = h.governance_health_index_0_1000;
    summ.containment_resilience_0_1000 = h.containment_quality_0_1000;
    summ.survivability_resilience_0_1000 = h.survivability_preservation_0_1000;
    summ.recovery_elasticity_0_1000 = h.recovery_stabilization_0_1000;
    summ.collapse_resistance_0_1000 = clps.collapse_resistance_score_0_1000;
    summ.quarantine_saturation_0_1000 = GovClampInt32(curve.quarantine_saturation_peak * 100, 0, 1000);
    summ.intervention_density_0_1000 = GovClampInt32((cm.prevented_escalation_epochs + cm.forced_flatten_count) * 1000 / GovClampInt32(n, 1, 1000000), 0, 1000);
    summ.regime_brittleness_0_1000 = brittle.brittleness_score_0_1000;
    summ.degradation_velocity_milli = curve.degradation_velocity_milli;
    summ.resilience_half_life_epochs = curve.resilience_half_life_epochs;
    summ.stabilization_quality_0_1000 = curve.recovery_curve_quality_0_1000;
    summ.replay_epoch_count = n;
    ArrayResize(out_prof.stress, 7);
    for(int a = 0; a < 7; a++) {
        const int stress = sim_runs[a].stress_lane_code;
        SGovReplayTimelineV1 lane;
        if(!GovStressV1_Apply(tl, stress, lane, out_err))
            return false;
        SGovContainmentMetricsV1 cm_l;
        if(!GovernanceContainmentAnalyticsV1_Compute(lane, cm_l, out_err))
            return false;
        SGovIncidentSummaryV1 is_l;
        string e3 = "";
        if(!GovernanceIncidentDetectorV1_DetectAll(lane, is_l, e3)) {
            out_err = e3;
            return false;
        }
        SGovCollapseResistanceV1 cl_l;
        if(!GovClpsResV1_Score(lane, cm_l, is_l, cl_l, out_err))
            return false;
        SGovGovernanceFatigueV1 fat_l;
        if(!GovFatigueV1_Measure(lane, fat_l, out_err))
            return false;
        GovResilDsV1_InitStressResp(out_prof.stress[a]);
        out_prof.stress[a].archetype_id = sim_runs[a].archetype_id;
        out_prof.stress[a].stress_lane_code = stress;
        out_prof.stress[a].lane_health_proxy_0_1000 = sim_runs[a].governance_health_proxy_0_1000;
        out_prof.stress[a].lane_collapse_resistance_0_1000 = cl_l.collapse_resistance_score_0_1000;
        out_prof.stress[a].lane_fatigue_load_0_1000 = fat_l.fatigue_composite_0_1000;
    }
    int ord[16];
    GovResilResV1_RankByCollapse(out_prof.stress, 7, ord);
    string resil_blk = "";
    if(!GovResilExpV1_Bundle(summ, curve, fatigue, brittle, clps, out_prof.stress, 7, ord, resil_blk, out_err))
        return false;
    out_prof.summary = summ;
    out_prof.curve = curve;
    out_prof.fatigue = fatigue;
    out_prof.collapse = clps;
    out_prof.brittleness = brittle;
    out_bundle = res_blk + "\n===RESIL_BLOCK===\n" + resil_blk;
    return true;
}

#endif // __AURUM_GOV_RESIL_LIVE_V1_MQH__
