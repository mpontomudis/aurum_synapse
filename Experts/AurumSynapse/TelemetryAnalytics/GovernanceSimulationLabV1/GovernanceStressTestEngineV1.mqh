//+------------------------------------------------------------------+
//| GovernanceStressTestEngineV1.mqh                              |
//| Deterministic replay transforms (sandbox dst only).            |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRESS_TEST_V1_MQH__
#define __AURUM_GOV_STRESS_TEST_V1_MQH__

#include "GovernanceSimulationDatasetV1.mqh"
#include "GovernanceSandboxExecutionV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "../GovernanceStateMachineV1/GovernanceTypesV1.mqh"
#include "../GovernanceEvidenceIntegrationV1/GovernanceRegimeClassifierV1.mqh"

bool GovStressV1_Apply(const SGovReplayTimelineV1 &src, const int code, SGovReplayTimelineV1 &dst, string &out_err) {
    out_err = "";
    GovSbExecV1_CloneTl(src, dst);
    if(code == GOV_STRS_V1_NONE)
        return true;
    const int n = ArraySize(dst.epochs);
    for(int i = 0; i < n; i++) {
        if(code == GOV_STRS_V1_CHRONIC_TOX) {
            if(dst.epochs[i].toxicity_ms != GOV_REPLAY_V1_UNSET_INT) {
                const int bump = GovClampInt32(dst.epochs[i].toxicity_ms / 4 + 100, 0, 100000);
                dst.epochs[i].toxicity_ms = GovSaturatingAdd32(dst.epochs[i].toxicity_ms, bump);
            }
        } else if(code == GOV_STRS_V1_SURV_COLLAPSE) {
            if(dst.epochs[i].survivability_ms != GOV_REPLAY_V1_UNSET_INT)
                dst.epochs[i].survivability_ms = GovClampInt32(dst.epochs[i].survivability_ms - 600, 0, 1000000);
        } else if(code == GOV_STRS_V1_LOCKDOWN_CHURN) {
            if(i % 2 == 0)
                dst.epochs[i].governance_state = (int)GOV_STATE_LOCKDOWN;
            else
                dst.epochs[i].governance_state = (int)GOV_STATE_NORMAL;
        } else if(code == GOV_STRS_V1_FRAGILE_PERSIST) {
            dst.epochs[i].regime_state = (int)GOV_MR_V1_FRAGILE;
        } else if(code == GOV_STRS_V1_QUAR_ESCAL) {
            const int q = dst.epochs[i].quarantine_state == GOV_REPLAY_V1_UNSET_INT ? 0 : dst.epochs[i].quarantine_state;
            dst.epochs[i].quarantine_state = GovClampInt32(q + 1, 0, 10);
        } else if(code == GOV_STRS_V1_EXEC_SUPP) {
            dst.epochs[i].execution_allowed = 0;
        } else if(code == GOV_STRS_V1_STRUCT_BREAK) {
            dst.epochs[i].regime_state = (int)GOV_MR_V1_STRUCTURAL_BREAKDOWN;
        } else if(code == GOV_STRS_V1_FLAT_BURST) {
            if(i % 3 == 0)
                dst.epochs[i].forced_flatten_required = 1;
        }
    }
    dst.integrity_ok = 1;
    dst.integrity_detail = "SANDBOX_STRESS";
    return true;
}

#endif // __AURUM_GOV_STRESS_TEST_V1_MQH__
