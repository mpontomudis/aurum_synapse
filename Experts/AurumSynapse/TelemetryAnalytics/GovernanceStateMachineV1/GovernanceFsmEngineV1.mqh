//+------------------------------------------------------------------+
//| GovernanceFsmEngineV1.mqh                                      |
//| Deterministic GS FSM — policy bands + dwell (Phase-8 aligned).   |
//| Single-writer: mutates `S` only via GovernanceStateMachineV1_Step.|
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_FSM_ENGINE_V1_MQH__
#define __AURUM_GOV_FSM_ENGINE_V1_MQH__

#include "GovernanceTypesV1.mqh"
#include "GovernancePolicyBundleV1.mqh"
#include "GovernancePolicyPrimitivesV1.mqh"

int GovFsmV1_BandLowerBound(const uchar tgt, SCGovPolicySnapshotV1 &p) {
    if(tgt == (uchar)GOV_STATE_LOCKDOWN)
        return p.gov_ev_lockdown_lo_ms;
    if(tgt == (uchar)GOV_STATE_SURVIVAL)
        return p.gov_band_survival_lo_ms;
    if(tgt == (uchar)GOV_STATE_DEFENSIVE)
        return p.gov_band_defensive_lo_ms;
    if(tgt == (uchar)GOV_STATE_CAUTION)
        return p.gov_ev_normal_hi_ms;
    return 0;
}

uchar GovFsmV1_BandTargetFromEvidence(const int ev_ms, SCGovPolicySnapshotV1 &p) {
    const int e = GovClampInt32(ev_ms, 0, 1000);
    if(e >= p.gov_ev_lockdown_lo_ms)
        return (uchar)GOV_STATE_LOCKDOWN;
    if(e >= p.gov_band_survival_lo_ms)
        return (uchar)GOV_STATE_SURVIVAL;
    if(e >= p.gov_band_defensive_lo_ms)
        return (uchar)GOV_STATE_DEFENSIVE;
    if(e >= p.gov_ev_normal_hi_ms)
        return (uchar)GOV_STATE_CAUTION;
    return (uchar)GOV_STATE_NORMAL;
}

uchar GovFsmV1_LowerNeighbor(const uchar gs) {
    if(gs == (uchar)GOV_STATE_LOCKDOWN)
        return (uchar)GOV_STATE_SURVIVAL;
    if(gs == (uchar)GOV_STATE_SURVIVAL)
        return (uchar)GOV_STATE_DEFENSIVE;
    if(gs == (uchar)GOV_STATE_DEFENSIVE)
        return (uchar)GOV_STATE_CAUTION;
    if(gs == (uchar)GOV_STATE_CAUTION)
        return (uchar)GOV_STATE_NORMAL;
    if(gs == (uchar)GOV_STATE_RECOVERY)
        return (uchar)GOV_STATE_DEFENSIVE;
    return gs;
}

int GovFsmV1_CurrentBandLowThreshold(const uchar gs, SCGovPolicySnapshotV1 &p) {
    if(gs == (uchar)GOV_STATE_NORMAL)
        return 0;
    if(gs == (uchar)GOV_STATE_CAUTION)
        return p.gov_ev_normal_hi_ms;
    if(gs == (uchar)GOV_STATE_DEFENSIVE)
        return p.gov_band_defensive_lo_ms;
    if(gs == (uchar)GOV_STATE_SURVIVAL)
        return p.gov_band_survival_lo_ms;
    if(gs == (uchar)GOV_STATE_LOCKDOWN)
        return p.gov_ev_lockdown_lo_ms;
    if(gs == (uchar)GOV_STATE_RECOVERY)
        return p.gov_band_defensive_lo_ms;
    return 0;
}

bool GovFsmV1_Step(const ulong gov_epoch,
                   SCGovPolicySnapshotV1 &pol,
                   const int evidence_ms,
                   const int conf_published_ms,
                   const int regime_score_ms,
                   const uchar quarantine_severity,
                   const uchar tripwire_lockdown,
                   SGovernanceSmStateV1 &S,
                   ENUM_GS_TRANSITION_REASON_V1 &out_reason) {
    out_reason = TR_V1_NONE;
    const uchar prev = S.gs_current;

    if(tripwire_lockdown != 0) {
        if(S.gs_current != (uchar)GOV_STATE_LOCKDOWN) {
            S.gs_current = (uchar)GOV_STATE_LOCKDOWN;
            out_reason = TR_V1_LOCKDOWN_LATCH;
            S.gs_esc_streak = 0;
            S.gs_deesc_streak = 0;
            S.recovery_entry_streak = 0;
            S.recovery_exit_streak = 0;
            S.in_recovery_path = 0;
            return (S.gs_current != prev);
        }
    }

    if(S.gs_current == (uchar)GOV_STATE_RECOVERY) {
        const int rec_stable_below = GovClampInt32(pol.gov_band_defensive_lo_ms, 0, 1000);
        if(evidence_ms < rec_stable_below)
            S.recovery_exit_streak = GovSaturatingAdd32(S.recovery_exit_streak, 1);
        else
            S.recovery_exit_streak = 0;
        if(S.recovery_exit_streak >= pol.gov_dwell_recovery_exit) {
            S.gs_current = (uchar)GOV_STATE_DEFENSIVE;
            S.in_recovery_path = 0;
            S.recovery_exit_streak = 0;
            out_reason = TR_V1_RECOVERY_EXIT_TO_DEFENSIVE;
            return (S.gs_current != prev);
        }
        const uchar band = GovFsmV1_BandTargetFromEvidence(evidence_ms, pol);
        if(band == (uchar)GOV_STATE_LOCKDOWN) {
            S.gs_current = (uchar)GOV_STATE_LOCKDOWN;
            S.in_recovery_path = 0;
            out_reason = TR_V1_EVIDENCE_ESCALATE;
            return (S.gs_current != prev);
        }
        return false;
    }

    const uchar tgt = GovFsmV1_BandTargetFromEvidence(evidence_ms, pol);

    if((prev == (uchar)GOV_STATE_SURVIVAL || prev == (uchar)GOV_STATE_LOCKDOWN) && S.in_recovery_path == 0) {
        if(quarantine_severity == 0 &&
           regime_score_ms < pol.gov_recovery_regime_max_ms &&
           conf_published_ms >= pol.gov_recovery_conf_min_ms) {
            S.recovery_entry_streak = GovSaturatingAdd32(S.recovery_entry_streak, 1);
        } else
            S.recovery_entry_streak = 0;
        if(S.recovery_entry_streak >= pol.gov_dwell_recovery_entry) {
            S.gs_current = (uchar)GOV_STATE_RECOVERY;
            S.in_recovery_path = 1;
            S.recovery_entry_streak = 0;
            S.gs_esc_streak = 0;
            S.gs_deesc_streak = 0;
            out_reason = TR_V1_RECOVERY_ENTRY;
            return (S.gs_current != prev);
        }
    }

    if(tgt > S.gs_current) {
        const int need = GovFsmV1_BandLowerBound(tgt, pol);
        if(evidence_ms >= need)
            S.gs_esc_streak = GovSaturatingAdd32(S.gs_esc_streak, 1);
        else
            S.gs_esc_streak = 0;
        if(S.gs_esc_streak >= pol.gov_dwell_gs_esc) {
            S.gs_current = tgt;
            S.gs_esc_streak = 0;
            S.gs_deesc_streak = 0;
            out_reason = TR_V1_EVIDENCE_ESCALATE;
            return (S.gs_current != prev);
        }
    } else
        S.gs_esc_streak = 0;

    const int lo = GovFsmV1_CurrentBandLowThreshold(S.gs_current, pol);
    const int hyst = GovClampInt32(pol.gov_hyst_gs_ms, 0, 1000);
    const int thr = lo - hyst;
    if(evidence_ms < thr)
        S.gs_deesc_streak = GovSaturatingAdd32(S.gs_deesc_streak, 1);
    else
        S.gs_deesc_streak = 0;
    if(S.gs_deesc_streak >= pol.gov_dwell_gs_deesc) {
        const uchar down = GovFsmV1_LowerNeighbor(S.gs_current);
        if(down != S.gs_current) {
            S.gs_current = down;
            S.gs_deesc_streak = 0;
            out_reason = TR_V1_EVIDENCE_DEESCALATE;
            return (S.gs_current != prev);
        }
    }

    return false;
}

#endif // __AURUM_GOV_FSM_ENGINE_V1_MQH__
