//+------------------------------------------------------------------+
//| GovernanceTypesV1.mqh                                           |
//| PHASE 8A — canonical governance runtime types (integer-only)     |
//| Normative: PHASE_8_GOVERNANCE_POLICY_TABLES_V1.md (state_id)    |
//|            PHASE_8A_GOVERNANCE_STATE_MACHINE_IMPLEMENTATION_SPEC |
//| Ownership: single writer = GovernanceStateMachineV1_Step only.   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_TYPES_V1_MQH__
#define __AURUM_GOV_TYPES_V1_MQH__

// Shadow lane default for 8A (telemetry-only). MQL5 preprocessor does not support
// C-style conditional directives in comments (hash-if / hash-error tokens confuse the lexer).
// Misconfiguration is rejected at runtime in GovernanceShadowTickV1.
#ifndef GOVERNANCE_SHADOW_MODE
   #define GOVERNANCE_SHADOW_MODE 1
#endif

#define GOV_V1_RUNTIME_SCHEMA_MAJOR 1
#define GOV_V1_RUNTIME_SCHEMA_MINOR 0

//+------------------------------------------------------------------+
//| GOV_STATE_* wire ordinals MUST match policy table §2.3.2 `state_id`.|
//+------------------------------------------------------------------+
enum ENUM_GOV_STATE_V1 {
    GOV_STATE_INVALID = 0,
    GOV_STATE_NORMAL = 1,
    GOV_STATE_RECOVERY = 2,
    GOV_STATE_CAUTION = 3,
    GOV_STATE_DEFENSIVE = 4,
    GOV_STATE_SURVIVAL = 5,
    GOV_STATE_LOCKDOWN = 6
};

//+------------------------------------------------------------------+
//| REGIME_* ordinals MUST match policy §2.2 `state_id`.            |
//+------------------------------------------------------------------+
enum ENUM_REGIME_STATE_V1 {
    REGIME_V1_INVALID = 0,
    REGIME_V1_STABLE = 1,
    REGIME_V1_UNCERTAIN = 2,
    REGIME_V1_VOLATILE = 3,
    REGIME_V1_TOXIC = 4,
    REGIME_V1_COLLAPSING = 5
};

//+------------------------------------------------------------------+
//| CONF_* ordinals MUST match policy §2.1 `state_id`.              |
//+------------------------------------------------------------------+
enum ENUM_CONF_STATE_V1 {
    CONF_V1_INVALID = 0,
    CONF_V1_HIGH = 1,
    CONF_V1_MEDIUM = 2,
    CONF_V1_LOW = 3,
    CONF_V1_CRITICAL = 4
};

//+------------------------------------------------------------------+
//| Transition reason codes — align with 8A telemetry spec §6.3.   |
//| Full semantics frozen at implementation completion.             |
//+------------------------------------------------------------------+
enum ENUM_GS_TRANSITION_REASON_V1 {
    TR_V1_NONE = 0,
    TR_V1_EVIDENCE_ESCALATE = 1,
    TR_V1_EVIDENCE_DEESCALATE = 2,
    TR_V1_QUARANTINE_MAX = 3,
    TR_V1_RECOVERY_ENTRY = 4,
    TR_V1_RECOVERY_EXIT_TO_DEFENSIVE = 5,
    TR_V1_LOCKDOWN_LATCH = 6,
    TR_V1_SURVIVAL_LATCH = 7,
    TR_V1_REGIME_FORCED = 8,
    TR_V1_CONF_FORCED = 9,
    TR_V1_DWELL_BLOCKED = 10
};

//+------------------------------------------------------------------+
//| Loader / bundle deterministic error taxonomy (fail-closed).     |
//| Codes are stable contract identifiers for replay manifests.     |
//+------------------------------------------------------------------+
enum ENUM_GOV_POLICY_LOAD_ERR_V1 {
    GOV_LOAD_ERR_V1_OK = 0,
    GOV_LOAD_ERR_V1_FILE_MISSING = 1,
    GOV_LOAD_ERR_V1_FILE_IO = 2,
    GOV_LOAD_ERR_V1_INVALID_ENCODING = 3,
    GOV_LOAD_ERR_V1_MALFORMED_LINE = 4,
    GOV_LOAD_ERR_V1_DUPLICATE_KEY = 5,
    GOV_LOAD_ERR_V1_UNSUPPORTED_KEY = 6,
    GOV_LOAD_ERR_V1_INTEGER_OVERFLOW = 7,
    GOV_LOAD_ERR_V1_SEMVER_INVALID = 8,
    GOV_LOAD_ERR_V1_CHECKSUM_FORMAT = 9,
    GOV_LOAD_ERR_V1_CHECKSUM_MISMATCH = 10,
    GOV_LOAD_ERR_V1_MISSING_REQUIRED_KEY = 11,
    GOV_LOAD_ERR_V1_PARTIAL = 12,
    GOV_LOAD_ERR_V1_GOV_PARAMS_INCOMPLETE = 13
};

//+------------------------------------------------------------------+
//| L0 read contract — INTEGER SCORES ONLY (0..1000) for governance |
//| ingestion. No floats: producers must publish bounded integers.  |
//| Map: TelemetryAnalytics/GovernanceEvidenceIntegrationV1/        |
//+------------------------------------------------------------------+
struct SGovL0SnapshotIntegerV1 {
    ulong gov_epoch;
    ulong lifecycle_campaign_id;
    int   toxicity_score_0_100;
    int   survivability_score_0_100;
    uchar causal_severity_rank_0_5;
    uchar quarantine_severity_0_4;
    int   conf_published_ms_0_1000;
    int   regime_score_ms_0_1000;
    int   conf_raw_ms_0_1000;
    int   eq_ms_0_1000;
    int   rf_penalty_ms_0_1000;
    uchar fake_recovery_flag_0_1;
    int   deterioration_repetition;
    int   instability_persistence_ms;
    uchar tripwire_lockdown_request_0_1;
    int   campaign_pressure_ms_0_1000;
    int   drawdown_pressure_ms_0_1000;
    int   recovery_instability_ms_0_1000;
    int   execution_degradation_ms_0_1000;
    int   consecutive_toxic_lifecycle;
    ushort causal_flags_bits;
    int   causal_explanation_code;
};

//+------------------------------------------------------------------+
//| Immutable governance evidence bundle (serialization-friendly).   |
//+------------------------------------------------------------------+
struct SGovernanceEvidenceFullV1 {
    SGovL0SnapshotIntegerV1 l0;
    int                     evidence_ms;
    int                     e_tox_ms;
    int                     e_surv_ms;
    int                     e_causal_ms;
    int                     e_conf_ms;
    int                     e_q_ms;
};

//+------------------------------------------------------------------+
//| Governance decision output — integer-only (no float authority).   |
//| risk_mult_milli: effective risk ×1000 (1000 = 1.000).            |
//+------------------------------------------------------------------+
struct SGovernanceDecisionOutputV1 {
    uchar  target_gs;
    int    risk_mult_milli;
    uchar  execution_allowed;
    uchar  recovery_allowed;
    uchar  averaging_allowed;
    int    max_campaign_depth;
    int    throttle_level_ms;
    int    confidence_attn_milli;
    int    causal_explanation_code;
};

//+------------------------------------------------------------------+
//| Append-only governance event types (schema v1).                  |
//+------------------------------------------------------------------+
enum ENUM_GOV_EVENT_TYPE_V1 {
    GOV_EVT_V1_NONE = 0,
    GOV_EVT_V1_STATE_CHANGED = 1,
    GOV_EVT_V1_RISK_THROTTLED = 2,
    GOV_EVT_V1_LOCKDOWN_ENTER = 3,
    GOV_EVT_V1_LOCKDOWN_EXIT = 4,
    GOV_EVT_V1_RECOVERY_ENTER = 5,
    GOV_EVT_V1_RECOVERY_EXIT = 6,
    GOV_EVT_V1_POLICY_BOUND = 7,
    GOV_EVT_V1_EXECUTION_BLOCKED = 8
};

//+------------------------------------------------------------------+
//| Hysteresis latch memory (owned by FSM single-writer state).      |
//+------------------------------------------------------------------+
struct SGovLatchStateV1 {
    uchar latched;
    int   dwell_esc_count;
    int   dwell_deesc_count;
    int   cooldown_remaining_epochs;
    ulong last_update_epoch;
};

//+------------------------------------------------------------------+
//| Telemetry row (numeric + string metadata for serialization).    |
//| Field order for pipe serialization — GovernanceTelemetryV1.     |
//+------------------------------------------------------------------+
struct SGovernanceTelemetryRowV1 {
    ulong  gov_epoch;
    uchar  gs_previous;
    uchar  gs_current;
    ushort transition_reason;
    ushort evidence_ms;
    ushort toxicity_ms;
    ushort survivability_ms;
    ushort confidence_ms;
    uchar  quarantine_severity;
    string policy_id;
    string policy_semver;
    string policy_checksum_sha256_hex;
    string l0_fingerprint_sha256_hex;
};

//+------------------------------------------------------------------+
//| Single-writer governance state (epoch-local mutation in Step).  |
//+------------------------------------------------------------------+
struct SGovernanceSmStateV1 {
    uchar gs_current;
    uchar gs_previous_wire;
    uchar gs_published_lag1;
    ushort last_transition_reason;
    ulong  last_commit_epoch;
    uchar  reserved_align_0;
    uchar  reserved_align_1;
    SGovLatchStateV1 latch_tox;
    SGovLatchStateV1 latch_surv;
    int    gs_esc_streak;
    int    gs_deesc_streak;
    int    recovery_entry_streak;
    int    recovery_exit_streak;
    uchar  in_recovery_path;
    int    last_risk_mult_milli;
    int    last_throttle_level_ms;
    uchar  last_execution_allowed;
};

void GovernanceTypesV1_InitSnapshot(SGovL0SnapshotIntegerV1 &z) {
    z.gov_epoch = 0;
    z.lifecycle_campaign_id = 0;
    z.toxicity_score_0_100 = 0;
    z.survivability_score_0_100 = 0;
    z.causal_severity_rank_0_5 = 0;
    z.quarantine_severity_0_4 = 0;
    z.conf_published_ms_0_1000 = 0;
    z.regime_score_ms_0_1000 = 0;
    z.conf_raw_ms_0_1000 = 0;
    z.eq_ms_0_1000 = 500;
    z.rf_penalty_ms_0_1000 = 0;
    z.fake_recovery_flag_0_1 = 0;
    z.deterioration_repetition = 0;
    z.instability_persistence_ms = 0;
    z.tripwire_lockdown_request_0_1 = 0;
    z.campaign_pressure_ms_0_1000 = 0;
    z.drawdown_pressure_ms_0_1000 = 0;
    z.recovery_instability_ms_0_1000 = 0;
    z.execution_degradation_ms_0_1000 = 0;
    z.consecutive_toxic_lifecycle = 0;
    z.causal_flags_bits = 0;
    z.causal_explanation_code = 0;
}

void GovernanceTypesV1_InitEvidenceFull(SGovernanceEvidenceFullV1 &z) {
    GovernanceTypesV1_InitSnapshot(z.l0);
    z.evidence_ms = 0;
    z.e_tox_ms = 0;
    z.e_surv_ms = 0;
    z.e_causal_ms = 0;
    z.e_conf_ms = 0;
}

void GovernanceTypesV1_InitDecision(SGovernanceDecisionOutputV1 &z) {
    z.target_gs = (uchar)GOV_STATE_INVALID;
    z.risk_mult_milli = 0;
    z.execution_allowed = 0;
    z.recovery_allowed = 0;
    z.averaging_allowed = 0;
    z.max_campaign_depth = 0;
    z.throttle_level_ms = 0;
    z.confidence_attn_milli = 0;
    z.causal_explanation_code = 0;
}

void GovernanceTypesV1_InitTelemetryRow(SGovernanceTelemetryRowV1 &z) {
    z.gov_epoch = 0;
    z.gs_previous = (uchar)GOV_STATE_INVALID;
    z.gs_current = (uchar)GOV_STATE_INVALID;
    z.transition_reason = TR_V1_NONE;
    z.evidence_ms = 0;
    z.toxicity_ms = 0;
    z.survivability_ms = 0;
    z.confidence_ms = 0;
    z.quarantine_severity = 0;
    z.policy_id = "";
    z.policy_semver = "";
    z.policy_checksum_sha256_hex = "";
    z.l0_fingerprint_sha256_hex = "";
}

void GovernanceTypesV1_InitLatch(SGovLatchStateV1 &z) {
    z.latched = 0;
    z.dwell_esc_count = 0;
    z.dwell_deesc_count = 0;
    z.cooldown_remaining_epochs = 0;
    z.last_update_epoch = 0;
}

void GovernanceTypesV1_InitSmState(SGovernanceSmStateV1 &z) {
    z.gs_current = (uchar)GOV_STATE_NORMAL;
    z.gs_previous_wire = (uchar)GOV_STATE_NORMAL;
    z.gs_published_lag1 = (uchar)GOV_STATE_NORMAL;
    z.last_transition_reason = TR_V1_NONE;
    z.last_commit_epoch = 0;
    z.reserved_align_0 = 0;
    z.reserved_align_1 = 0;
    GovernanceTypesV1_InitLatch(z.latch_tox);
    GovernanceTypesV1_InitLatch(z.latch_surv);
    z.gs_esc_streak = 0;
    z.gs_deesc_streak = 0;
    z.recovery_entry_streak = 0;
    z.recovery_exit_streak = 0;
    z.in_recovery_path = 0;
    z.last_risk_mult_milli = 1000;
    z.last_throttle_level_ms = 0;
    z.last_execution_allowed = 1;
}

#endif // __AURUM_GOV_TYPES_V1_MQH__
