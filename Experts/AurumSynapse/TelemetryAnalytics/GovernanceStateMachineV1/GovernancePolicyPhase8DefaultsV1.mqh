//+------------------------------------------------------------------+
//| GovernancePolicyPhase8DefaultsV1.mqh                           |
//| Integer tables mirroring PHASE_8_GOVERNANCE_POLICY_TABLES_V1   |
//| (embedded defaults path only — explicit opt-in via policy.tab).  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_POLICY_PHASE8_DEFAULTS_V1_MQH__
#define __AURUM_GOV_POLICY_PHASE8_DEFAULTS_V1_MQH__

#include "GovernanceTypesV1.mqh"
#include "GovernancePolicyBundleV1.mqh"

//+------------------------------------------------------------------+
//| Apply frozen Phase-8 numeric defaults into snapshot fields.      |
//| Call only when policy explicitly enables embedded defaults.      |
//+------------------------------------------------------------------+
void GovPolicyPhase8DefaultsV1_Apply(SCGovPolicySnapshotV1 &p) {
    // Evidence cutoffs (policy §2.3.2 hi edges; ladder uses max band).
    p.gov_ev_normal_hi_ms = 420;
    p.gov_ev_caution_hi_ms = 780;
    p.gov_ev_defensive_hi_ms = 920;
    p.gov_ev_survival_hi_ms = 1001;
    p.gov_ev_lockdown_lo_ms = 920;
    p.gov_band_defensive_lo_ms = 600;
    p.gov_band_survival_lo_ms = 780;

    p.gov_hyst_gs_ms = 80;
    p.gov_dwell_gs_esc = 1;
    p.gov_dwell_gs_deesc = 3;
    p.gov_dwell_recovery_entry = 5;
    p.gov_dwell_recovery_exit = 3;
    p.gov_recovery_regime_max_ms = 650;
    p.gov_recovery_conf_min_ms = 450;

    p.gov_tox_latch_on_ge = 70;
    p.gov_tox_latch_off_le = 55;
    p.gov_tox_dwell_esc = 2;
    p.gov_tox_dwell_deesc = 4;
    p.gov_tox_cooldown_lock = 1;

    p.gov_surv_latch_on_le = 45;
    p.gov_surv_latch_off_ge = 58;
    p.gov_surv_dwell_esc = 2;
    p.gov_surv_dwell_deesc = 5;

    p.gov_conf_alpha_num = 1;
    p.gov_conf_alpha_den = 4;
    p.gov_conf_stab_delta_ms = 25;
    p.gov_conf_publish_dwell = 1;

    // Risk multiplier (milli = value × 1000) per GS wire ordinal index [GS-1].
    // Simplified from policy §5 u_gs knot at minimum combined stress (shadow).
    p.gov_gs_risk_milli[(int)GOV_STATE_NORMAL - 1] = 1000;
    p.gov_gs_risk_milli[(int)GOV_STATE_CAUTION - 1] = 950;
    p.gov_gs_risk_milli[(int)GOV_STATE_DEFENSIVE - 1] = 780;
    p.gov_gs_risk_milli[(int)GOV_STATE_SURVIVAL - 1] = 500;
    p.gov_gs_risk_milli[(int)GOV_STATE_LOCKDOWN - 1] = 150;
    p.gov_gs_risk_milli[(int)GOV_STATE_RECOVERY - 1] = 900;

    for(int i = 0; i < 6; i++) {
        p.gov_gs_exec_allowed[i] = 1;
        p.gov_gs_recovery_allowed[i] = 1;
        p.gov_gs_avg_allowed[i] = 1;
        p.gov_gs_max_campaign_depth[i] = 8;
        p.gov_gs_throttle_ms[i] = 0;
        p.gov_gs_conf_attn_milli[i] = 1000;
    }
    p.gov_gs_exec_allowed[(int)GOV_STATE_LOCKDOWN - 1] = 0;
    p.gov_gs_recovery_allowed[(int)GOV_STATE_LOCKDOWN - 1] = 0;
    p.gov_gs_avg_allowed[(int)GOV_STATE_LOCKDOWN - 1] = 0;
    p.gov_gs_recovery_allowed[(int)GOV_STATE_SURVIVAL - 1] = 0;
}

#endif // __AURUM_GOV_POLICY_PHASE8_DEFAULTS_V1_MQH__
