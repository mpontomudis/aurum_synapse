//+------------------------------------------------------------------+
//| GovernancePolicyBundleV1.mqh                                  |
//| Immutable policy snapshot (runtime read-only after load).        |
//| Normative: PHASE_8_GOVERNANCE_POLICY_TABLES_V1.md §1, §9        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_POLICY_BUNDLE_V1_MQH__
#define __AURUM_GOV_POLICY_BUNDLE_V1_MQH__

#define GOV_V1_POLICY_TABLE_RESERVED_ROWS 16
#define GOV_V1_POLICY_MAX_KV 128
#define GOV_V1_POLICY_MAX_KEY_LEN 96
#define GOV_V1_POLICY_MAX_VAL_LEN 512
#define GOV_V1_POLICY_MAX_FILE_BYTES (256 * 1024)
#define GOV_V1_GS_SLOT_COUNT 6

struct SCGovPolicyTableRowReservedV1 {
    int  row_id;
    int  lo_ms;
    int  hi_ms;
    int  aux0;
    int  aux1;
};

struct SCGovPolicySnapshotV1 {
    bool   load_ok;
    bool   checksum_verified;
    bool   semver_verified;
    uchar  reserved_flags_0;
    uchar  reserved_flags_1;
    string policy_id;
    string policy_semver;
    string policy_checksum_sha256_hex;
    int    semver_major;
    int    semver_minor;
    int    semver_patch;
    int    table_reserved_row_count;
    int    kv_count;
    string kv_key[GOV_V1_POLICY_MAX_KV];
    string kv_val[GOV_V1_POLICY_MAX_KV];
    SCGovPolicyTableRowReservedV1 cutoff_placeholder[GOV_V1_POLICY_TABLE_RESERVED_ROWS];

    uchar gov_defaults_phase8_embedded;
    int   gov_ev_normal_hi_ms;
    int   gov_ev_caution_hi_ms;
    int   gov_ev_defensive_hi_ms;
    int   gov_ev_survival_hi_ms;
    int   gov_ev_lockdown_lo_ms;
    int   gov_band_defensive_lo_ms;
    int   gov_band_survival_lo_ms;
    int   gov_hyst_gs_ms;
    int   gov_dwell_gs_esc;
    int   gov_dwell_gs_deesc;
    int   gov_dwell_recovery_entry;
    int   gov_dwell_recovery_exit;
    int   gov_recovery_regime_max_ms;
    int   gov_recovery_conf_min_ms;
    int   gov_tox_latch_on_ge;
    int   gov_tox_latch_off_le;
    int   gov_tox_dwell_esc;
    int   gov_tox_dwell_deesc;
    int   gov_tox_cooldown_lock;
    int   gov_surv_latch_on_le;
    int   gov_surv_latch_off_ge;
    int   gov_surv_dwell_esc;
    int   gov_surv_dwell_deesc;
    int   gov_conf_alpha_num;
    int   gov_conf_alpha_den;
    int   gov_conf_stab_delta_ms;
    int   gov_conf_publish_dwell;
    int   gov_gs_risk_milli[GOV_V1_GS_SLOT_COUNT];
    uchar gov_gs_exec_allowed[GOV_V1_GS_SLOT_COUNT];
    uchar gov_gs_recovery_allowed[GOV_V1_GS_SLOT_COUNT];
    uchar gov_gs_avg_allowed[GOV_V1_GS_SLOT_COUNT];
    int   gov_gs_max_campaign_depth[GOV_V1_GS_SLOT_COUNT];
    int   gov_gs_throttle_ms[GOV_V1_GS_SLOT_COUNT];
    int   gov_gs_conf_attn_milli[GOV_V1_GS_SLOT_COUNT];
};

void GovPolicyBundleV1_InitEmpty(SCGovPolicySnapshotV1 &p) {
    p.load_ok = false;
    p.checksum_verified = false;
    p.semver_verified = false;
    p.reserved_flags_0 = 0;
    p.reserved_flags_1 = 0;
    p.policy_id = "";
    p.policy_semver = "";
    p.policy_checksum_sha256_hex = "";
    p.semver_major = 0;
    p.semver_minor = 0;
    p.semver_patch = 0;
    p.table_reserved_row_count = 0;
    p.kv_count = 0;
    for(int k = 0; k < GOV_V1_POLICY_MAX_KV; k++) {
        p.kv_key[k] = "";
        p.kv_val[k] = "";
    }
    for(int i = 0; i < GOV_V1_POLICY_TABLE_RESERVED_ROWS; i++) {
        p.cutoff_placeholder[i].row_id = 0;
        p.cutoff_placeholder[i].lo_ms = 0;
        p.cutoff_placeholder[i].hi_ms = 0;
        p.cutoff_placeholder[i].aux0 = 0;
        p.cutoff_placeholder[i].aux1 = 0;
    }
    p.gov_defaults_phase8_embedded = 0;
    p.gov_ev_normal_hi_ms = 0;
    p.gov_ev_caution_hi_ms = 0;
    p.gov_ev_defensive_hi_ms = 0;
    p.gov_ev_survival_hi_ms = 0;
    p.gov_ev_lockdown_lo_ms = 0;
    p.gov_band_defensive_lo_ms = 0;
    p.gov_band_survival_lo_ms = 0;
    p.gov_hyst_gs_ms = 0;
    p.gov_dwell_gs_esc = 0;
    p.gov_dwell_gs_deesc = 0;
    p.gov_dwell_recovery_entry = 0;
    p.gov_dwell_recovery_exit = 0;
    p.gov_recovery_regime_max_ms = 0;
    p.gov_recovery_conf_min_ms = 0;
    p.gov_tox_latch_on_ge = 0;
    p.gov_tox_latch_off_le = 0;
    p.gov_tox_dwell_esc = 0;
    p.gov_tox_dwell_deesc = 0;
    p.gov_tox_cooldown_lock = 0;
    p.gov_surv_latch_on_le = 0;
    p.gov_surv_latch_off_ge = 0;
    p.gov_surv_dwell_esc = 0;
    p.gov_surv_dwell_deesc = 0;
    p.gov_conf_alpha_num = 0;
    p.gov_conf_alpha_den = 0;
    p.gov_conf_stab_delta_ms = 0;
    p.gov_conf_publish_dwell = 0;
    for(int j = 0; j < GOV_V1_GS_SLOT_COUNT; j++) {
        p.gov_gs_risk_milli[j] = 0;
        p.gov_gs_exec_allowed[j] = 0;
        p.gov_gs_recovery_allowed[j] = 0;
        p.gov_gs_avg_allowed[j] = 0;
        p.gov_gs_max_campaign_depth[j] = 0;
        p.gov_gs_throttle_ms[j] = 0;
        p.gov_gs_conf_attn_milli[j] = 0;
    }
}

//+------------------------------------------------------------------+
//| Explicit snapshot copy (MQL5: structs with strings are not       |
//| assignable with `=`). Deterministic field-wise copy.             |
//+------------------------------------------------------------------+
void GovPolicyBundleV1_CopyFrom(SCGovPolicySnapshotV1 &dst, SCGovPolicySnapshotV1 &src) {
    dst.load_ok = src.load_ok;
    dst.checksum_verified = src.checksum_verified;
    dst.semver_verified = src.semver_verified;
    dst.reserved_flags_0 = src.reserved_flags_0;
    dst.reserved_flags_1 = src.reserved_flags_1;
    dst.policy_id = src.policy_id;
    dst.policy_semver = src.policy_semver;
    dst.policy_checksum_sha256_hex = src.policy_checksum_sha256_hex;
    dst.semver_major = src.semver_major;
    dst.semver_minor = src.semver_minor;
    dst.semver_patch = src.semver_patch;
    dst.table_reserved_row_count = src.table_reserved_row_count;
    dst.kv_count = src.kv_count;
    for(int k = 0; k < GOV_V1_POLICY_MAX_KV; k++) {
        dst.kv_key[k] = src.kv_key[k];
        dst.kv_val[k] = src.kv_val[k];
    }
    for(int i = 0; i < GOV_V1_POLICY_TABLE_RESERVED_ROWS; i++) {
        dst.cutoff_placeholder[i].row_id = src.cutoff_placeholder[i].row_id;
        dst.cutoff_placeholder[i].lo_ms = src.cutoff_placeholder[i].lo_ms;
        dst.cutoff_placeholder[i].hi_ms = src.cutoff_placeholder[i].hi_ms;
        dst.cutoff_placeholder[i].aux0 = src.cutoff_placeholder[i].aux0;
        dst.cutoff_placeholder[i].aux1 = src.cutoff_placeholder[i].aux1;
    }
    dst.gov_defaults_phase8_embedded = src.gov_defaults_phase8_embedded;
    dst.gov_ev_normal_hi_ms = src.gov_ev_normal_hi_ms;
    dst.gov_ev_caution_hi_ms = src.gov_ev_caution_hi_ms;
    dst.gov_ev_defensive_hi_ms = src.gov_ev_defensive_hi_ms;
    dst.gov_ev_survival_hi_ms = src.gov_ev_survival_hi_ms;
    dst.gov_ev_lockdown_lo_ms = src.gov_ev_lockdown_lo_ms;
    dst.gov_band_defensive_lo_ms = src.gov_band_defensive_lo_ms;
    dst.gov_band_survival_lo_ms = src.gov_band_survival_lo_ms;
    dst.gov_hyst_gs_ms = src.gov_hyst_gs_ms;
    dst.gov_dwell_gs_esc = src.gov_dwell_gs_esc;
    dst.gov_dwell_gs_deesc = src.gov_dwell_gs_deesc;
    dst.gov_dwell_recovery_entry = src.gov_dwell_recovery_entry;
    dst.gov_dwell_recovery_exit = src.gov_dwell_recovery_exit;
    dst.gov_recovery_regime_max_ms = src.gov_recovery_regime_max_ms;
    dst.gov_recovery_conf_min_ms = src.gov_recovery_conf_min_ms;
    dst.gov_tox_latch_on_ge = src.gov_tox_latch_on_ge;
    dst.gov_tox_latch_off_le = src.gov_tox_latch_off_le;
    dst.gov_tox_dwell_esc = src.gov_tox_dwell_esc;
    dst.gov_tox_dwell_deesc = src.gov_tox_dwell_deesc;
    dst.gov_tox_cooldown_lock = src.gov_tox_cooldown_lock;
    dst.gov_surv_latch_on_le = src.gov_surv_latch_on_le;
    dst.gov_surv_latch_off_ge = src.gov_surv_latch_off_ge;
    dst.gov_surv_dwell_esc = src.gov_surv_dwell_esc;
    dst.gov_surv_dwell_deesc = src.gov_surv_dwell_deesc;
    dst.gov_conf_alpha_num = src.gov_conf_alpha_num;
    dst.gov_conf_alpha_den = src.gov_conf_alpha_den;
    dst.gov_conf_stab_delta_ms = src.gov_conf_stab_delta_ms;
    dst.gov_conf_publish_dwell = src.gov_conf_publish_dwell;
    for(int j = 0; j < GOV_V1_GS_SLOT_COUNT; j++) {
        dst.gov_gs_risk_milli[j] = src.gov_gs_risk_milli[j];
        dst.gov_gs_exec_allowed[j] = src.gov_gs_exec_allowed[j];
        dst.gov_gs_recovery_allowed[j] = src.gov_gs_recovery_allowed[j];
        dst.gov_gs_avg_allowed[j] = src.gov_gs_avg_allowed[j];
        dst.gov_gs_max_campaign_depth[j] = src.gov_gs_max_campaign_depth[j];
        dst.gov_gs_throttle_ms[j] = src.gov_gs_throttle_ms[j];
        dst.gov_gs_conf_attn_milli[j] = src.gov_gs_conf_attn_milli[j];
    }
}

#endif // __AURUM_GOV_POLICY_BUNDLE_V1_MQH__
