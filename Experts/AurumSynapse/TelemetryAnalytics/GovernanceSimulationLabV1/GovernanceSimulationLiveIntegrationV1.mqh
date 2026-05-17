//+------------------------------------------------------------------+
//| GovernanceSimulationLiveIntegrationV1.mqh                      |
//| research → multi-arch simulation → export (observational).     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SIM_LIVE_V1_MQH__
#define __AURUM_GOV_SIM_LIVE_V1_MQH__

#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayParserV1.mqh"
#include "../GovernanceAutonomousResearchV1/GovernanceResearchLiveIntegrationV1.mqh"
#include "GovernanceSimulationDatasetV1.mqh"
#include "GovernanceReplaySimulationLabV1.mqh"
#include "GovernanceSimulationResearchV1.mqh"
#include "GovernanceSimulationExportV1.mqh"

bool GovSimLiveV1_Run(const string utf8_lf, SGovSimScenarioV1 &sc, string &out_bundle, string &out_err) {
    out_err = "";
    out_bundle = "";
    SGovResearchSummaryV1 res_sum;
    string res_blk = "";
    if(!GovResLiveV1_Run(utf8_lf, res_sum, res_blk, out_err))
        return false;
    string norm = "";
    GovernanceReplayParserV1_NormalizeLf(utf8_lf, norm);
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    if(!GovernanceReplayParserV1_ParseMultilineUtf8Lf(norm, tl, out_err))
        return false;
    GovSimDsV1_InitScen(sc);
    sc.scenario_id = 1;
    sc.replay_source_hash = tl.source_concat_sha256_hex;
    sc.scenario_epoch_count = ArraySize(tl.epochs);
    sc.deterministic_seed = (ulong)0x53594E415050;
    sc.replay_window_hash = tl.source_concat_sha256_hex;
    sc.policy_fingerprint = res_sum.policy_fingerprint;
    int archs[7];
    archs[0] = GOV_ARCH_V1_SURV_FIRST;
    archs[1] = GOV_ARCH_V1_AGGR_CONT;
    archs[2] = GOV_ARCH_V1_QUAR_HEAVY;
    archs[3] = GOV_ARCH_V1_THR_HEAVY;
    archs[4] = GOV_ARCH_V1_REC_CONSERV;
    archs[5] = GOV_ARCH_V1_FLAT_AGGR;
    archs[6] = GOV_ARCH_V1_BALANCED;
    SGovSimPolicyRunV1 runs[];
    if(!GovRplSimLabV1_RunMulti(tl, archs, 7, runs, out_err))
        return false;
    int ord[16];
    GovSimResV1_RankHealth(runs, 7, ord);
    string sim_blk = "";
    if(!GovSimExpV1_Bundle(runs, 7, ord, sim_blk, out_err))
        return false;
    out_bundle = res_blk + "\n===SIM_BLOCK===\n" + sim_blk;
    return true;
}

#endif // __AURUM_GOV_SIM_LIVE_V1_MQH__
