//+------------------------------------------------------------------+
//| GovernanceShadowTickV1.mqh                                     |
//| PHASE 8A — SHADOW orchestrator (telemetry-only).                 |
//| Normative evaluation order: regime → quarantine → confidence      |
//|   EWMA → evidence → L1 FSM.                                      |
//| NO execution hooks, NO order/risk mutation.                        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SHADOW_TICK_V1_MQH__
#define __AURUM_GOV_SHADOW_TICK_V1_MQH__

#include "GovernanceTypesV1.mqh"
#include "GovernancePolicyBundleV1.mqh"
#include "GovernancePolicyLoaderV1.mqh"
#include "GovernanceRegimeV1.mqh"
#include "GovernanceQuarantineV1.mqh"
#include "GovernanceConfidenceV1.mqh"
#include "GovernanceEvidenceV1.mqh"
#include "GovernanceStateMachineV1.mqh"
#include "GovernanceTelemetryEventsV1.mqh"

struct SGovernanceShadowContextV1 {
    int                            schema_major;
    int                            schema_minor;
    ulong                          next_epoch;
    SGovernanceSmStateV1           sm;
    SCGovPolicySnapshotV1          policy_snapshot;
    uchar                          lag1_quarantine_severity;
    ushort                         lag1_evidence_ms;
    int                            conf_ewma_ms;
    int                            conf_pub_ms;
    int                            conf_publish_dwell_ctr;
    string                         last_policy_checksum_sha256_hex;
};

void GovernanceShadowContextV1_Init(SGovernanceShadowContextV1 &ctx,
                                      SCGovPolicySnapshotV1 &src_policy) {
    GovPolicyBundleV1_InitEmpty(ctx.policy_snapshot);
    GovPolicyBundleV1_CopyFrom(ctx.policy_snapshot, src_policy);
    ctx.schema_major = GOV_V1_RUNTIME_SCHEMA_MAJOR;
    ctx.schema_minor = GOV_V1_RUNTIME_SCHEMA_MINOR;
    ctx.next_epoch = 1;
    GovernanceStateMachineV1_Init(ctx.sm);
    ctx.lag1_quarantine_severity = 0;
    ctx.lag1_evidence_ms = 0;
    ctx.conf_ewma_ms = -1;
    ctx.conf_pub_ms = 0;
    ctx.conf_publish_dwell_ctr = 0;
    ctx.last_policy_checksum_sha256_hex = "";
}

void GovernanceShadowContextV1_Reset(SGovernanceShadowContextV1 &ctx,
                                     SCGovPolicySnapshotV1 &src_policy) {
    GovernanceShadowContextV1_Init(ctx, src_policy);
}

//+------------------------------------------------------------------+
bool GovernanceShadowTickV1(SGovernanceShadowContextV1 &ctx,
                              SGovL0SnapshotIntegerV1 &l0_in,
                              const string l0_fingerprint_sha256_hex,
                              string &out_telemetry_line,
                              string &out_gov_events_lines) {
    if(GOVERNANCE_SHADOW_MODE != 1)
        return false;
    out_gov_events_lines = "";
    if(!ctx.policy_snapshot.load_ok || !ctx.policy_snapshot.checksum_verified)
        return false;

    const ulong ep = ctx.next_epoch;

    SGovernanceEpochScratchV1 scratch;
    GovernanceStateMachineV1_InitScratch(scratch);
    scratch.l0_fingerprint_sha256_hex = l0_fingerprint_sha256_hex;

    SRegimeEvalInputV1 rin;
    rin.l0 = l0_in;
    if(!GovernanceRegimeV1_EvaluateShell(rin, ctx.policy_snapshot, scratch.reg))
        return false;

    SQuarantineEvalInputV1 qin;
    qin.l0 = l0_in;
    qin.gs_wire_hint = ctx.sm.gs_current;
    if(!GovernanceQuarantineV1_EvaluateShell(qin, ctx.policy_snapshot, scratch.quar))
        return false;

    if(!GovernanceConfidenceV1_StepEwmaPublish(ctx.policy_snapshot,
                                              l0_in.conf_raw_ms_0_1000,
                                              ctx.conf_ewma_ms,
                                              ctx.conf_pub_ms,
                                              ctx.conf_publish_dwell_ctr,
                                              scratch.conf))
        return false;

    SEvidenceInputV1 ein;
    ein.l0 = l0_in;
    ein.conf_published_ms_0_1000 = scratch.conf.conf_published_ms;
    ein.quarantine_severity_0_4 = scratch.quar.severity;
    if(!GovernanceEvidenceV1_Compute(ein, ctx.policy_snapshot, scratch.ev))
        return false;

    string accum = "";
    if(ctx.last_policy_checksum_sha256_hex != ctx.policy_snapshot.policy_checksum_sha256_hex) {
        SEvidenceOutputV1 zev;
        GovernanceEvidenceV1_InitOutput(zev);
        string pln = "";
        if(!GovTelemetryEventsV1_FormatLine(GOV_EVT_V1_POLICY_BOUND,
                                            ep,
                                            l0_in.lifecycle_campaign_id,
                                            ctx.policy_snapshot.policy_checksum_sha256_hex,
                                            ctx.sm.gs_current,
                                            ctx.sm.gs_current,
                                            zev,
                                            0,
                                            0,
                                            TR_V1_NONE,
                                            ctx.sm.last_risk_mult_milli,
                                            ctx.sm.last_throttle_level_ms,
                                            pln))
            return false;
        if(!GovTelemetryEventsV1_Append(accum, pln))
            return false;
        ctx.last_policy_checksum_sha256_hex = ctx.policy_snapshot.policy_checksum_sha256_hex;
    }

    SGovernanceTelemetryRowV1 row;
    ENUM_GS_TRANSITION_REASON_V1 tr = TR_V1_NONE;
    string step_ev = "";
    if(!GovernanceStateMachineV1_Step(ep,
                                       l0_in,
                                       ctx.policy_snapshot,
                                       scratch,
                                       ctx.sm,
                                       row,
                                       tr,
                                       step_ev))
        return false;

    if(StringLen(step_ev) > 0) {
        if(StringLen(accum) > 0)
            accum += "\n";
        accum += step_ev;
    }
    out_gov_events_lines = accum;

    if(!GovernanceTelemetryV1_FormatLine(row, out_telemetry_line))
        return false;

    ctx.sm.gs_published_lag1 = ctx.sm.gs_current;
    ctx.lag1_quarantine_severity = scratch.quar.severity;
    ctx.lag1_evidence_ms = (ushort)GovClampInt32(scratch.ev.evidence_ms, 0, 1000);

    ctx.next_epoch = ep + 1;
    return true;
}

#endif // __AURUM_GOV_SHADOW_TICK_V1_MQH__
