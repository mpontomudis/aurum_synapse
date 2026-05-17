//+------------------------------------------------------------------+
//| GovernanceStateMachineV1.mqh                                   |
//| L1 GS FSM — single writer; deterministic transitions + telemetry.  |
//| Normative: PHASE_8_GOVERNANCE_POLICY_TABLES_V1.md §2.3, §3       |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STATE_MACHINE_V1_MQH__
#define __AURUM_GOV_STATE_MACHINE_V1_MQH__

#include "GovernanceTypesV1.mqh"
#include "GovernancePolicyBundleV1.mqh"
#include "GovernanceEvidenceV1.mqh"
#include "GovernanceRegimeV1.mqh"
#include "GovernanceQuarantineV1.mqh"
#include "GovernanceConfidenceV1.mqh"
#include "GovernanceTelemetryV1.mqh"
#include "GovernanceHysteresisV1.mqh"
#include "GovernanceFsmEngineV1.mqh"
#include "GovernanceDecisionV1.mqh"
#include "GovernanceTelemetryEventsV1.mqh"

//+------------------------------------------------------------------+
struct SGovernanceEpochScratchV1 {
    SRegimeEvalOutputV1       reg;
    SQuarantineEvalOutputV1 quar;
    SConfidenceEvalOutputV1 conf;
    SEvidenceOutputV1         ev;
    SGovernanceEvidenceFullV1 ev_full;
    SGovernanceDecisionOutputV1 decision;
    string                    l0_fingerprint_sha256_hex;
};

void GovernanceStateMachineV1_InitScratch(SGovernanceEpochScratchV1 &z) {
    GovernanceRegimeV1_InitOutput(z.reg);
    GovernanceQuarantineV1_InitOutput(z.quar);
    GovernanceConfidenceV1_InitOutput(z.conf);
    GovernanceEvidenceV1_InitOutput(z.ev);
    GovernanceTypesV1_InitEvidenceFull(z.ev_full);
    GovernanceTypesV1_InitDecision(z.decision);
    z.l0_fingerprint_sha256_hex = "";
}

bool GovernanceStateMachineV1_Init(SGovernanceSmStateV1 &S) {
    GovernanceTypesV1_InitSmState(S);
    return true;
}

bool GovernanceStateMachineV1_Reset(SGovernanceSmStateV1 &S) {
    GovernanceTypesV1_InitSmState(S);
    return true;
}

//+------------------------------------------------------------------+
bool GovernanceStateMachineV1_Step(const ulong gov_epoch,
                                   SGovL0SnapshotIntegerV1 &l0,
                                   SCGovPolicySnapshotV1 &pol,
                                   SGovernanceEpochScratchV1 &scratch,
                                   SGovernanceSmStateV1 &S,
                                   SGovernanceTelemetryRowV1 &out_row,
                                   ENUM_GS_TRANSITION_REASON_V1 &out_reason,
                                   string &out_gov_events_lines) {
    out_gov_events_lines = "";
    GovernanceTypesV1_InitTelemetryRow(out_row);
    out_reason = TR_V1_NONE;

    if(!pol.load_ok || !pol.checksum_verified || !pol.semver_verified) {
        out_row.gov_epoch = gov_epoch;
        return false;
    }

    const uchar gs_before_fsm = S.gs_current;

    GovHysteresisV1_BinaryScoreLatchStep(gov_epoch,
                                         S.latch_tox,
                                         GovClampInt32(l0.toxicity_score_0_100, 0, 100),
                                         GovClampInt32(pol.gov_tox_latch_on_ge, 0, 100),
                                         GovClampInt32(pol.gov_tox_latch_off_le, 0, 100),
                                         GovClampInt32(pol.gov_tox_dwell_esc, 0, 1000000),
                                         GovClampInt32(pol.gov_tox_dwell_deesc, 0, 1000000),
                                         GovClampInt32(pol.gov_tox_cooldown_lock, 0, 1000000));

    const int surv = GovClampInt32(l0.survivability_score_0_100, 0, 100);
    const int surv_stress = 100 - surv;
    const int surv_on_ge = 100 - GovClampInt32(pol.gov_surv_latch_on_le, 0, 100);
    const int surv_off_le = 100 - GovClampInt32(pol.gov_surv_latch_off_ge, 0, 100);
    GovHysteresisV1_BinaryScoreLatchStep(gov_epoch,
                                         S.latch_surv,
                                         surv_stress,
                                         surv_on_ge,
                                         surv_off_le,
                                         GovClampInt32(pol.gov_surv_dwell_esc, 0, 1000000),
                                         GovClampInt32(pol.gov_surv_dwell_deesc, 0, 1000000),
                                         0);

    const uchar trip = (l0.tripwire_lockdown_request_0_1 != 0) ? (uchar)1 : (uchar)0;
    const int regime_ms = GovClampInt32(l0.regime_score_ms_0_1000, 0, 1000);
    GovFsmV1_Step(gov_epoch,
                  pol,
                  scratch.ev.evidence_ms,
                  scratch.conf.conf_published_ms,
                  regime_ms,
                  scratch.quar.severity,
                  trip,
                  S,
                  out_reason);

    scratch.ev_full.l0 = l0;
    scratch.ev_full.evidence_ms = scratch.ev.evidence_ms;
    scratch.ev_full.e_tox_ms = scratch.ev.e_tox_ms;
    scratch.ev_full.e_surv_ms = scratch.ev.e_surv_ms;
    scratch.ev_full.e_causal_ms = scratch.ev.e_causal_ms;
    scratch.ev_full.e_conf_ms = scratch.ev.e_conf_ms;

    GovDecisionV1_FromPolicy(S.gs_current,
                           pol,
                           l0.causal_explanation_code,
                           scratch.decision);

    out_row.gov_epoch = gov_epoch;
    out_row.gs_previous = S.gs_published_lag1;
    out_row.gs_current = S.gs_current;
    out_row.transition_reason = (ushort)out_reason;
    out_row.evidence_ms = (ushort)GovClampInt32(scratch.ev.evidence_ms, 0, 1000);
    out_row.toxicity_ms = (ushort)GovClampInt32(scratch.ev.e_tox_ms, 0, 1000);
    out_row.survivability_ms = (ushort)GovClampInt32(scratch.ev.e_surv_ms, 0, 1000);
    out_row.confidence_ms = (ushort)GovClampInt32(scratch.ev.e_conf_ms, 0, 1000);
    out_row.quarantine_severity = scratch.quar.severity;
    out_row.policy_id = pol.policy_id;
    out_row.policy_semver = pol.policy_semver;
    out_row.policy_checksum_sha256_hex = pol.policy_checksum_sha256_hex;
    out_row.l0_fingerprint_sha256_hex = scratch.l0_fingerprint_sha256_hex;

    S.gs_previous_wire = gs_before_fsm;
    S.last_transition_reason = (ushort)out_reason;
    S.last_commit_epoch = gov_epoch;

    const uchar gs_after = S.gs_current;
    const ushort cflags = l0.causal_flags_bits;
    const int cexp = l0.causal_explanation_code;

    string ln = "";

    if(gs_after != gs_before_fsm) {
        if(!GovTelemetryEventsV1_FormatLine(GOV_EVT_V1_STATE_CHANGED,
                                            gov_epoch,
                                            l0.lifecycle_campaign_id,
                                            pol.policy_checksum_sha256_hex,
                                            gs_before_fsm,
                                            gs_after,
                                            scratch.ev,
                                            cexp,
                                            (int)cflags,
                                            (ushort)out_reason,
                                            scratch.decision.risk_mult_milli,
                                            scratch.decision.throttle_level_ms,
                                            ln))
            return false;
        if(!GovTelemetryEventsV1_Append(out_gov_events_lines, ln))
            return false;

        if(gs_after == (uchar)GOV_STATE_LOCKDOWN && gs_before_fsm != (uchar)GOV_STATE_LOCKDOWN) {
            if(!GovTelemetryEventsV1_FormatLine(GOV_EVT_V1_LOCKDOWN_ENTER,
                                                gov_epoch,
                                                l0.lifecycle_campaign_id,
                                                pol.policy_checksum_sha256_hex,
                                                gs_before_fsm,
                                                gs_after,
                                                scratch.ev,
                                                cexp,
                                                (int)cflags,
                                                (ushort)out_reason,
                                                scratch.decision.risk_mult_milli,
                                                scratch.decision.throttle_level_ms,
                                                ln))
                return false;
            if(!GovTelemetryEventsV1_Append(out_gov_events_lines, ln))
                return false;
        }
        if(gs_before_fsm == (uchar)GOV_STATE_LOCKDOWN && gs_after != (uchar)GOV_STATE_LOCKDOWN) {
            if(!GovTelemetryEventsV1_FormatLine(GOV_EVT_V1_LOCKDOWN_EXIT,
                                                gov_epoch,
                                                l0.lifecycle_campaign_id,
                                                pol.policy_checksum_sha256_hex,
                                                gs_before_fsm,
                                                gs_after,
                                                scratch.ev,
                                                cexp,
                                                (int)cflags,
                                                (ushort)out_reason,
                                                scratch.decision.risk_mult_milli,
                                                scratch.decision.throttle_level_ms,
                                                ln))
                return false;
            if(!GovTelemetryEventsV1_Append(out_gov_events_lines, ln))
                return false;
        }
        if(gs_after == (uchar)GOV_STATE_RECOVERY && gs_before_fsm != (uchar)GOV_STATE_RECOVERY) {
            if(!GovTelemetryEventsV1_FormatLine(GOV_EVT_V1_RECOVERY_ENTER,
                                                gov_epoch,
                                                l0.lifecycle_campaign_id,
                                                pol.policy_checksum_sha256_hex,
                                                gs_before_fsm,
                                                gs_after,
                                                scratch.ev,
                                                cexp,
                                                (int)cflags,
                                                (ushort)out_reason,
                                                scratch.decision.risk_mult_milli,
                                                scratch.decision.throttle_level_ms,
                                                ln))
                return false;
            if(!GovTelemetryEventsV1_Append(out_gov_events_lines, ln))
                return false;
        }
        if(gs_before_fsm == (uchar)GOV_STATE_RECOVERY && gs_after != (uchar)GOV_STATE_RECOVERY) {
            if(!GovTelemetryEventsV1_FormatLine(GOV_EVT_V1_RECOVERY_EXIT,
                                                gov_epoch,
                                                l0.lifecycle_campaign_id,
                                                pol.policy_checksum_sha256_hex,
                                                gs_before_fsm,
                                                gs_after,
                                                scratch.ev,
                                                cexp,
                                                (int)cflags,
                                                (ushort)out_reason,
                                                scratch.decision.risk_mult_milli,
                                                scratch.decision.throttle_level_ms,
                                                ln))
                return false;
            if(!GovTelemetryEventsV1_Append(out_gov_events_lines, ln))
                return false;
        }
    }

    if(scratch.decision.risk_mult_milli < S.last_risk_mult_milli ||
       scratch.decision.throttle_level_ms > S.last_throttle_level_ms) {
        if(!GovTelemetryEventsV1_FormatLine(GOV_EVT_V1_RISK_THROTTLED,
                                            gov_epoch,
                                            l0.lifecycle_campaign_id,
                                            pol.policy_checksum_sha256_hex,
                                            gs_after,
                                            gs_after,
                                            scratch.ev,
                                            cexp,
                                            (int)cflags,
                                            (ushort)out_reason,
                                            scratch.decision.risk_mult_milli,
                                            scratch.decision.throttle_level_ms,
                                            ln))
            return false;
        if(!GovTelemetryEventsV1_Append(out_gov_events_lines, ln))
            return false;
    }

    if(S.last_execution_allowed != 0 && scratch.decision.execution_allowed == 0) {
        if(!GovTelemetryEventsV1_FormatLine(GOV_EVT_V1_EXECUTION_BLOCKED,
                                            gov_epoch,
                                            l0.lifecycle_campaign_id,
                                            pol.policy_checksum_sha256_hex,
                                            gs_after,
                                            gs_after,
                                            scratch.ev,
                                            cexp,
                                            (int)cflags,
                                            (ushort)out_reason,
                                            scratch.decision.risk_mult_milli,
                                            scratch.decision.throttle_level_ms,
                                            ln))
            return false;
        if(!GovTelemetryEventsV1_Append(out_gov_events_lines, ln))
            return false;
    }

    S.last_risk_mult_milli = scratch.decision.risk_mult_milli;
    S.last_throttle_level_ms = scratch.decision.throttle_level_ms;
    S.last_execution_allowed = scratch.decision.execution_allowed;

    return true;
}

#endif // __AURUM_GOV_STATE_MACHINE_V1_MQH__
