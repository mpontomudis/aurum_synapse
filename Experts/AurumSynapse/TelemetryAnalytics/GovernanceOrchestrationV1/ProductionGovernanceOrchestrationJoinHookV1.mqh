//+------------------------------------------------------------------+
//| ProductionGovernanceOrchestrationJoinHookV1.mqh                 |
//| Wires LIVE_GOVERNANCE_ORCHESTRATION_V1 into ProductionJoin_Run. |
//| Append-only GOV_EXEC_V1 beside joined output (FILE_COMMON).     |
//+------------------------------------------------------------------+
#ifndef __AURUM_PROD_GOV_ORCH_JOIN_HOOK_V1_MQH__
#define __AURUM_PROD_GOV_ORCH_JOIN_HOOK_V1_MQH__

#include "GovernanceExecutionOrchestratorV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyLoaderV1.mqh"

const string GOV_ORCH_V1_EMBEDDED_POLICY_TAB_UTF8 =
    "gov_defaults_phase8_embedded=1\n"
    "policy_id=GOV_POLICY_TEST_VALID_V1\n"
    "policy_semver=1.0.0\n"
    "policy_checksum_sha256=f7167fe77747293a4856d6bd3ede23f8520cfb42d986420cc54ef6f352336e97\n";

void ProductionGovernanceOrchestrationJoinHookV1_OnJoinedBatch(const string outputJoinedRelPathFromCommon,
                                                              const string dealsUtf8Lf) {
    if(StringLen(outputJoinedRelPathFromCommon) < 1 || StringLen(dealsUtf8Lf) < 1)
        return;
    SCGovPolicySnapshotV1 pol;
    ENUM_GOV_POLICY_LOAD_ERR_V1 le = GOV_LOAD_ERR_V1_OK;
    if(!GovPolicyLoaderV1_LoadFromUtf8Text(GOV_ORCH_V1_EMBEDDED_POLICY_TAB_UTF8, pol, le) || le != GOV_LOAD_ERR_V1_OK)
        return;
    if(!pol.load_ok || !pol.checksum_verified)
        return;

    SGovernanceShadowContextV1 ctx;
    GovernanceShadowContextV1_Init(ctx, pol);
    SGovernanceCampaignMemoryV1 mem;
    GovernanceCampaignMemoryV1_Init(mem);
    ENUM_GOV_MARKET_REGIME_V1 mr = GOV_MR_V1_NORMAL;
    int df = 0;
    int dt = 0;
    string tel = "";
    string ev = "";
    string attrib = "";
    SGovShadowTickAuxOutV1 aux;
    SGovernanceExecutionContractV1 contract;
    string gexec = "";
    string err = "";
    if(!GovernanceExecutionOrchestratorV1_RunPipelineFromDealsUtf8(ctx, mem, mr, df, dt, dealsUtf8Lf,
                                                                    "0000000000000000000000000000000000000000000000000000000000000000",
                                                                    tel, ev, attrib, aux, contract, gexec, err))
        return;
    const string logRel = outputJoinedRelPathFromCommon + ".gov_exec_v1.log";
    GovernanceExecutionTelemetryV1_AppendUtf8LfCommon(logRel, gexec);
}

#endif // __AURUM_PROD_GOV_ORCH_JOIN_HOOK_V1_MQH__
