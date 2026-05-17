//+------------------------------------------------------------------+
//| GovernanceExecutionOrchestratorV1.mqh                          |
//| LIVE_GOVERNANCE_ORCHESTRATION_V1 — intelligence → contract      |
//| No broker I/O; no order placement.                               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EXEC_ORCHESTRATOR_V1_MQH__
#define __AURUM_GOV_EXEC_ORCHESTRATOR_V1_MQH__

#include "../GovernanceEvidenceIntegrationV1/GovernanceEvidenceIntegrationV1.mqh"
#include "../GovernanceStateMachineV1/GovernanceDecisionV1.mqh"
#include "GovernanceExecutionContractV1.mqh"
#include "GovernanceQuarantineEngineV1.mqh"
#include "GovernanceThrottleEngineV1.mqh"
#include "GovernanceSurvivabilityProtectorV1.mqh"
#include "GovernanceExecutionGateV1.mqh"
#include "GovernanceExecutionTelemetryV1.mqh"
#include "GovernanceTransitionHooksV1.mqh"

bool GovernanceExecutionOrchestratorV1_RunPipelineFromDealsUtf8(SGovernanceShadowContextV1 &ctx,
                                                                SGovernanceCampaignMemoryV1 &mem,
                                                                ENUM_GOV_MARKET_REGIME_V1 &io_prior_regime,
                                                                int &io_dwell_fragile,
                                                                int &io_dwell_toxic,
                                                                const string dealsUtf8Lf,
                                                                const string l0_fingerprint_sha256_hex,
                                                                string &out_telemetry_line,
                                                                string &out_gov_events_lines,
                                                                string &out_attrib_line,
                                                                SGovShadowTickAuxOutV1 &aux,
                                                                SGovernanceExecutionContractV1 &out_contract,
                                                                string &out_gov_exec_line,
                                                                string &out_err) {
    out_err = "";
    out_gov_exec_line = "";
    GovernanceExecutionContractV1_InitFailClosed(out_contract);
    if(!ctx.policy_snapshot.load_ok || !ctx.policy_snapshot.checksum_verified) {
        out_err = "GOV_ORCH_V1_POLICY_NOT_LOADED";
        return false;
    }

    const uchar gs_before = ctx.sm.gs_current;
    const ENUM_GOV_EXEC_QUARANTINE_V1 q_prev = (ENUM_GOV_EXEC_QUARANTINE_V1)mem.last_exec_quarantine_level;
    const uchar surv_em_before = mem.last_survivability_emergency_flag;
    const ulong ep_commit = ctx.next_epoch;

    if(!GovEvidenceIntegrationV1_ShadowTickFromDealsUtf8(ctx, mem, io_prior_regime, io_dwell_fragile, io_dwell_toxic,
                                                        dealsUtf8Lf, l0_fingerprint_sha256_hex,
                                                        out_telemetry_line, out_gov_events_lines, out_attrib_line, aux)) {
        out_err = "GOV_ORCH_V1_SHADOW_TICK_FAILED";
        return false;
    }

    const uchar gs_after = ctx.sm.gs_current;
    SCGovPolicySnapshotV1 pol_local = ctx.policy_snapshot;
    SGovernanceDecisionOutputV1 dec;
    GovDecisionV1_FromPolicy(gs_after, pol_local, aux.causal_explanation_code, dec);

    SGovSurvivabilityProtectOutputV1 prot;
    GovernanceSurvivabilityProtectorV1_Evaluate(gs_after, aux.market_regime_after, aux.surv_state, aux.rt, mem, prot);

    const ENUM_GOV_EXEC_QUARANTINE_V1 q = GovernanceQuarantineEngineV1_Classify(gs_after, aux.market_regime_after,
                                                                                 aux.tox_state, aux.surv_state, mem);

    const int throttle_ms = GovernanceThrottleEngineV1_ComputeIntervalMs(gs_after, aux.market_regime_after, aux.rt, mem,
                                                                           dec.throttle_level_ms);

    const int cd_a = (int)ctx.sm.latch_tox.cooldown_remaining_epochs;
    const int cd_b = (int)ctx.sm.latch_surv.cooldown_remaining_epochs;
    const int cooldown_ep = GovClampInt32((cd_a > cd_b) ? cd_a : cd_b, 0, 1000000);

    uchar ent = 0, rec = 0, avg = 0, hed = 0, exe = 0;
    GovernanceExecutionGateV1_Apply(dec, q, prot, ent, rec, avg, hed, exe);

    const long rprod = (long)dec.risk_mult_milli * (long)prot.risk_compression_milli / 1000;
    const int risk_comp = GovClampInt32(GovSaturateLongToInt32(rprod), 0, 1000000);
    long exp_long = (long)1000000 * (long)risk_comp / 1000;
    int exp_cap = GovClampInt32(GovSaturateLongToInt32(exp_long), 0, 1000000000);
    if(q == GOV_EXEC_QUAR_V1_HARD) {
        const long hard_long = (long)exp_cap * 700 / 1000;
        exp_cap = GovClampInt32(GovSaturateLongToInt32(hard_long), 0, 1000000000);
    }
    if(q == GOV_EXEC_QUAR_V1_TERMINAL)
        exp_cap = 0;

    const int max_depth = GovernanceExecutionGateV1_EffectiveMaxDepth(dec, q, prot);

    out_contract.governance_state = gs_after;
    out_contract.regime_state = (uchar)aux.market_regime_after;
    out_contract.execution_allowed = exe;
    out_contract.entry_allowed = ent;
    out_contract.recovery_allowed = rec;
    out_contract.averaging_allowed = avg;
    out_contract.hedging_allowed = hed;
    out_contract.forced_flatten_required = prot.forced_flatten_required;
    out_contract.risk_multiplier_milli = risk_comp;
    out_contract.exposure_cap_milli = exp_cap;
    out_contract.max_campaign_depth = max_depth;
    out_contract.throttle_interval_ms = throttle_ms;
    out_contract.cooldown_epochs = cooldown_ep;
    out_contract.quarantine_active = (q != GOV_EXEC_QUAR_V1_NONE) ? (uchar)1 : (uchar)0;
    out_contract.survivability_emergency = prot.survivability_emergency;
    out_contract.causal_reason_code = aux.causal_explanation_code;
    out_contract.policy_fingerprint = ctx.policy_snapshot.policy_checksum_sha256_hex;
    out_contract.evidence_fingerprint = aux.evidence_fp8_hex8;
    out_contract.contract_epoch = ep_commit;

    GovernanceTransitionHooksV1_OnPostTick(mem, gs_before, gs_after, q_prev, q, surv_em_before, prot.survivability_emergency,
                                          aux.market_regime_after);
    mem.last_survivability_emergency_flag = prot.survivability_emergency;

    const ulong camp_uuid = aux.rt.lifecycle_id;
    if(!GovernanceExecutionTelemetryV1_FormatLine(out_contract, throttle_ms, q, camp_uuid, out_gov_exec_line)) {
        out_err = "GOV_ORCH_V1_EXEC_TELEMETRY_FORMAT_FAILED";
        return false;
    }
    return true;
}

#endif // __AURUM_GOV_EXEC_ORCHESTRATOR_V1_MQH__
