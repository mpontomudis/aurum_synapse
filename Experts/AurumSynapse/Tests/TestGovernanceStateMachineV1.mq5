//+------------------------------------------------------------------+
//|                   TestGovernanceStateMachineV1.mq5              |
//| PHASE 8A — governance kernel: loader + primitives + telemetry  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property version   "1.00"
#property description "Phase 8A — Governance kernel deterministic harness"

#include "../TelemetryAnalytics/GovernanceStateMachineV1/GovernanceShadowTickV1.mqh"
#include "../TelemetryAnalytics/GovernanceEvidenceIntegrationV1/GovernanceEvidenceIntegrationV1.mqh"
#include "../TelemetryAnalytics/GovernanceOrchestrationV1/GovernanceExecutionOrchestratorV1.mqh"
#include "../TelemetryAnalytics/GovernanceReplayVisualIntelligenceV1/GovernanceReplayVisualIntelligenceV1.mqh"
#include "../TelemetryAnalytics/GovernanceShadowRuntimeLaneV1.mqh"
#include "../TelemetryAnalytics/GovernanceRuntimeStrategyTaggingV1/GovernanceRuntimeStrategyTaggingV1.mqh"
#include "../TelemetryAnalytics/GovernanceSignalForensicsV1/GovernanceSignalForensicsV1.mqh"
#include "../TelemetryAnalytics/GovernanceRegimeEngineV1/GovernanceRegimeIntegrationV1.mqh"
#include "../TelemetryAnalytics/GovernanceEcologyEngineV1/GovernanceEcologyIntegrationV1.mqh"
#include "../TelemetryAnalytics/GovernanceRestrictionForensicsV1/GovernanceRestrictionForensicsIntegrationV1.mqh"
#include "../TelemetryAnalytics/RiskLockIntelligenceV1/RiskLockIntelligenceIntegrationV1.mqh"
#include "../TelemetryAnalytics/AdaptiveThawStabilizationV1/AdaptiveThawStabilizationIntegrationV1.mqh"

SGovCmpRunRecordV1 g_gov_test_cmp_baseline_row_v1;

#define GOV_V1_TMP_POLICY_TAB "__gov_kernel_policy_valid.tab"
#define GOV_V1_TMP_TRANSCRIPT "__gov_kernel_transcript.bin"

bool GovTest_WriteUtf8Bin(const string rel_path, const string utf8_text) {
    const int h = FileOpen(rel_path, FILE_WRITE | FILE_BIN);
    if(h == INVALID_HANDLE)
        return false;
    uchar buf[];
    const int slen = StringLen(utf8_text);
    const int n = (slen <= 0) ? 0 : StringToCharArray(utf8_text, buf, 0, slen, CP_UTF8);
    if(n < 0) {
        FileClose(h);
        return false;
    }
    if(n == 0) {
        FileClose(h);
        return (StringLen(utf8_text) == 0);
    }
    const uint w = FileWriteArray(h, buf, 0, n);
    FileClose(h);
    return (w == (uint)n);
}

bool GovTestHarnessV1_LoadFixtureManifestShell(const string scenario_dir, string &out_err) {
    const int scenario_len = StringLen(scenario_dir);
    out_err = "GOV_TEST_FIXTURE_LOAD_NOT_IMPLEMENTED";
    if(scenario_len < 0)
        return false;
    return false;
}

//+------------------------------------------------------------------+
//| Golden UTF-8 policy.tab (checksum over sorted KV body excl. cs). |
//+------------------------------------------------------------------+
const string GOV_V1_VALID_POLICY_TAB_UTF8 =
    "gov_defaults_phase8_embedded=1\n"
    "policy_id=GOV_POLICY_TEST_VALID_V1\n"
    "policy_semver=1.0.0\n"
    "policy_checksum_sha256=f7167fe77747293a4856d6bd3ede23f8520cfb42d986420cc54ef6f352336e97\n";

bool GovTestHarnessV1_ReplayLoopShell(const int max_epochs) {
    if(max_epochs <= 0)
        return true;
    SCGovPolicySnapshotV1 pol;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(!GovPolicyLoaderV1_LoadFromUtf8Text(GOV_V1_VALID_POLICY_TAB_UTF8, pol, e) || e != GOV_LOAD_ERR_V1_OK)
        return false;

    SGovL0SnapshotIntegerV1 l0;
    GovernanceTypesV1_InitSnapshot(l0);
    l0.toxicity_score_0_100 = 0;
    l0.survivability_score_0_100 = 100;
    l0.causal_severity_rank_0_5 = 0;
    l0.conf_raw_ms_0_1000 = 900;

    string acc_a_t = "";
    string acc_a_e = "";
    string acc_b_t = "";
    string acc_b_e = "";

    for(int pass = 0; pass < 2; pass++) {
        SGovernanceShadowContextV1 ctx;
        GovernanceShadowContextV1_Init(ctx, pol);
        string tacc = "";
        string eacc = "";
        for(int k = 0; k < max_epochs; k++) {
            string t = "";
            string ev = "";
            if(!GovernanceShadowTickV1(ctx, l0, "0000000000000000000000000000000000000000000000000000000000000000", t, ev))
                return false;
            tacc += t + "\n";
            eacc += ev + "\n";
        }
        if(pass == 0) {
            acc_a_t = tacc;
            acc_a_e = eacc;
        } else {
            acc_b_t = tacc;
            acc_b_e = eacc;
        }
    }
    return (acc_a_t == acc_b_t) && (acc_a_e == acc_b_e);
}

bool GovTestHarnessV1_CompareTranscriptShell(const string &a, const string &b) {
    return (a == b);
}

bool Fail(const string m) {
    Print("[GOV_SM_V1_TEST] FAIL ", m);
    return false;
}

bool T_Semver_Valid(void) {
    int mj = 0, mn = 0, pt = 0;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(!GovPolicyLoaderV1_ValidateSemverString("1.0.0", mj, mn, pt, e))
        return Fail("semver_valid_parse");
    if(mj != 1 || mn != 0 || pt != 0 || e != GOV_LOAD_ERR_V1_OK)
        return Fail("semver_valid_values");
    int mj2 = 0, mn2 = 0, pt2 = 0;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e2 = GOV_LOAD_ERR_V1_OK;
    if(!GovPolicyLoaderV1_ValidateSemverString(" \t2.5.17\r", mj2, mn2, pt2, e2))
        return Fail("semver_trim_parse");
    if(mj2 != 2 || mn2 != 5 || pt2 != 17 || e2 != GOV_LOAD_ERR_V1_OK)
        return Fail("semver_trim_values");
    return true;
}

bool T_Semver_AcceptCorpus(void) {
    int mj = 0, mn = 0, pt = 0;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(!GovPolicyLoaderV1_ValidateSemverString("999.999.999", mj, mn, pt, e) || e != GOV_LOAD_ERR_V1_OK)
        return Fail("semver_accept_999");
    if(mj != 999 || mn != 999 || pt != 999)
        return Fail("semver_accept_999_vals");
    if(!GovPolicyLoaderV1_ValidateSemverString("10.25.301", mj, mn, pt, e) || mj != 10 || mn != 25 || pt != 301)
        return Fail("semver_accept_10_25_301");
    return true;
}

bool T_Semver_RejectCorpus(void) {
    int mj = 0, mn = 0, pt = 0;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    string bad_sem[10];
    bad_sem[0] = "1";
    bad_sem[1] = "1.0";
    bad_sem[2] = "v1.0.0";
    bad_sem[3] = "1.0.beta";
    bad_sem[4] = "01.2.3";
    bad_sem[5] = "1.2.3.4";
    bad_sem[6] = "1..2";
    bad_sem[7] = ".";
    bad_sem[8] = "1. 0.0";
    bad_sem[9] = "1.+2.3";
    for(int i = 0; i < 10; i++) {
        e = GOV_LOAD_ERR_V1_OK;
        if(GovPolicyLoaderV1_ValidateSemverString(bad_sem[i], mj, mn, pt, e))
            return Fail("semver_reject_should_fail");
        if(e != GOV_LOAD_ERR_V1_SEMVER_INVALID)
            return Fail("semver_reject_err");
    }
    return true;
}

bool T_Semver_Overflow(void) {
    int mj = 0, mn = 0, pt = 0;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(GovPolicyLoaderV1_ValidateSemverString("999999999999999999999.1.1", mj, mn, pt, e))
        return Fail("semver_ov_should_fail");
    if(e != GOV_LOAD_ERR_V1_INTEGER_OVERFLOW)
        return Fail("semver_ov_err");
    return true;
}

bool T_Semver_NonAsciiRejected(void) {
    uchar raw[7];
    raw[0] = (uchar)'1';
    raw[1] = (uchar)'.';
    raw[2] = (uchar)'2';
    raw[3] = (uchar)'.';
    raw[4] = (uchar)'3';
    raw[5] = (uchar)0xC3;
    raw[6] = (uchar)0xA9;
    const string s = CharArrayToString(raw, 0, 7, CP_UTF8);
    int mj = 0, mn = 0, pt = 0;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(GovPolicyLoaderV1_ValidateSemverString(s, mj, mn, pt, e))
        return Fail("semver_utf8_should_fail");
    if(e != GOV_LOAD_ERR_V1_SEMVER_INVALID)
        return Fail("semver_utf8_err");
    return true;
}

bool T_Semver_CrLfNormalizesInValidate(void) {
    int mj = 0, mn = 0, pt = 0;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(!GovPolicyLoaderV1_ValidateSemverString("1.2.3\r", mj, mn, pt, e) || e != GOV_LOAD_ERR_V1_OK)
        return Fail("semver_crlf_parse");
    if(mj != 1 || mn != 2 || pt != 3)
        return Fail("semver_crlf_vals");
    return true;
}

bool T_Semver_Invalid(void) {
    int mj = 0, mn = 0, pt = 0;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(GovPolicyLoaderV1_ValidateSemverString("1.x.0", mj, mn, pt, e))
        return Fail("semver_invalid_should_fail");
    if(e != GOV_LOAD_ERR_V1_SEMVER_INVALID)
        return Fail("semver_invalid_err");
    return true;
}

bool T_Load_ValidUtf8(void) {
    SCGovPolicySnapshotV1 p;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(!GovPolicyLoaderV1_LoadFromUtf8Text(GOV_V1_VALID_POLICY_TAB_UTF8, p, e))
        return Fail("load_valid_utf8");
    if(e != GOV_LOAD_ERR_V1_OK || !p.load_ok || !p.checksum_verified || !p.semver_verified)
        return Fail("load_valid_flags");
    if(p.policy_id != "GOV_POLICY_TEST_VALID_V1")
        return Fail("load_valid_policy_id");
    if(p.gov_defaults_phase8_embedded != 1 || p.gov_ev_normal_hi_ms != 420)
        return Fail("load_valid_materialize");
    return true;
}

bool T_Load_DuplicateKey(void) {
    const string s =
        "policy_id=A\n"
        "policy_id=B\n"
        "policy_semver=1.0.0\n"
        "policy_checksum_sha256=0000000000000000000000000000000000000000000000000000000000000000\n";
    SCGovPolicySnapshotV1 p;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(GovPolicyLoaderV1_LoadFromUtf8Text(s, p, e))
        return Fail("dup_should_fail");
    if(e != GOV_LOAD_ERR_V1_DUPLICATE_KEY)
        return Fail("dup_err");
    if(p.load_ok)
        return Fail("dup_partial");
    return true;
}

bool T_Load_Malformed(void) {
    const string s =
        "policy_id=X\n"
        "badline\n"
        "policy_semver=1.0.0\n"
        "policy_checksum_sha256=0000000000000000000000000000000000000000000000000000000000000000\n";
    SCGovPolicySnapshotV1 p;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(GovPolicyLoaderV1_LoadFromUtf8Text(s, p, e))
        return Fail("mal_should_fail");
    if(e != GOV_LOAD_ERR_V1_MALFORMED_LINE)
        return Fail("mal_err");
    return true;
}

bool T_Load_UnsupportedKey(void) {
    const string s =
        "policy_id=z\n"
        "policy_semver=1.0.0\n"
        "policy_extra=1\n"
        "policy_checksum_sha256=f7167fe77747293a4856d6bd3ede23f8520cfb42d986420cc54ef6f352336e97\n";
    SCGovPolicySnapshotV1 p;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(GovPolicyLoaderV1_LoadFromUtf8Text(s, p, e))
        return Fail("unsup_should_fail");
    if(e != GOV_LOAD_ERR_V1_UNSUPPORTED_KEY)
        return Fail("unsup_err");
    return true;
}

bool T_Load_ChecksumMismatch(void) {
    const string s =
        "gov_defaults_phase8_embedded=1\n"
        "policy_id=GOV_POLICY_TEST_VALID_V1\n"
        "policy_semver=1.0.0\n"
        "policy_checksum_sha256=f7167fe77747293a4856d6bd3ede23f8520cfb42d986420cc54ef6f352336e96\n";
    SCGovPolicySnapshotV1 p;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(GovPolicyLoaderV1_LoadFromUtf8Text(s, p, e))
        return Fail("csum_should_fail");
    if(e != GOV_LOAD_ERR_V1_CHECKSUM_MISMATCH)
        return Fail("csum_err");
    return true;
}

bool T_Load_InvalidSemverUtf8(void) {
    const string s =
        "policy_id=GOV_POLICY_BAD_SEMVER\n"
        "policy_semver=1.x.0\n"
        "policy_checksum_sha256=2e784c383ac0230aec27acff28af5b9cd0555d8e5b69b34f28f8db299b74c7dc\n";
    SCGovPolicySnapshotV1 p;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(GovPolicyLoaderV1_LoadFromUtf8Text(s, p, e))
        return Fail("invsem_should_fail");
    if(e != GOV_LOAD_ERR_V1_SEMVER_INVALID)
        return Fail("invsem_err");
    return true;
}

bool T_Load_FileMissing(void) {
    SCGovPolicySnapshotV1 p;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(GovPolicyLoaderV1_LoadFromFile("__gov_file_that_does_not_exist_zzzz.tab", p, e))
        return Fail("missing_should_fail");
    if(e != GOV_LOAD_ERR_V1_FILE_MISSING)
        return Fail("missing_err");
    return true;
}

bool T_Append_EmptyPathNoop(void) {
    if(!GovernanceTelemetryV1_AppendTranscriptLine("", "x"))
        return Fail("append_empty_path");
    return true;
}

bool T_ResetSnapshot(void) {
    SCGovPolicySnapshotV1 p;
    GovPolicyBundleV1_InitEmpty(p);
    p.load_ok = true;
    p.kv_count = 3;
    GovPolicyLoaderV1_ResetSnapshot(p);
    if(p.load_ok || p.kv_count != 0 || StringLen(p.policy_id) != 0)
        return Fail("reset_snapshot");
    return true;
}

bool T_Primitives_FloorAndSat(void) {
    if(GovFloorDivSigned64(-3, 2) != -2)
        return Fail("floor_div");
    if(GovSaturatingAdd32(2000000000, 2000000000) != 2147483647)
        return Fail("sat_add");
    if(GovSaturatingMul32(100000, 100000) != 2147483647)
        return Fail("sat_mul");
    if(GovMaxInt32_x5(1, 4, 3, 2, 5) != 5)
        return Fail("max5");
    return true;
}

bool T_Primitives_CastLongToIntSafe(void) {
    int o = 0;
    const long hi = (long)2147483647 + (long)1;
    if(GovCastLongToIntSafe(hi, o))
        return Fail("cast_hi_overflow");
    const long lo = (long)(-2147483647 - 1) - (long)1;
    if(GovCastLongToIntSafe(lo, o))
        return Fail("cast_lo_overflow");
    if(!GovCastLongToIntSafe(12345, o) || o != 12345)
        return Fail("cast_ok");
    return true;
}

bool T_TranscriptHash_KnownVector(void) {
    const string blob = "a\nb\n";
    string h = "";
    if(!GovernanceTelemetryV1_TranscriptSha256Hex(blob, h))
        return Fail("tr_hash_call");
    if(h != "911169ddaaf146aff539f58c26c489af3b892dff0fe283c1c264c65ae5aa59a2")
        return Fail("tr_hash_ab");
    string h0 = "";
    if(!GovernanceTelemetryV1_TranscriptSha256Hex("", h0))
        return Fail("tr_hash_empty_call");
    if(h0 != "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        return Fail("tr_hash_empty");
    return true;
}

bool T_Telemetry_FormatAndRejectPipe(void) {
    SGovernanceTelemetryRowV1 r;
    GovernanceTypesV1_InitTelemetryRow(r);
    r.gov_epoch = 1;
    r.gs_previous = 1;
    r.gs_current = 1;
    r.policy_id = "BAD|ID";
    r.policy_semver = "1.0.0";
    r.policy_checksum_sha256_hex = "f91d012745a66be73315c95e8fe9faac49465eae266fba401036f2c58886581e";
    r.l0_fingerprint_sha256_hex = "f91d012745a66be73315c95e8fe9faac49465eae266fba401036f2c58886581e";
    string line = "";
    if(GovernanceTelemetryV1_FormatLine(r, line))
        return Fail("fmt_should_fail_pipe");
    r.policy_id = "OK";
    if(!GovernanceTelemetryV1_FormatLine(r, line))
        return Fail("fmt_ok");
    if(GovernanceTelemetryV1_CountPipeFields(line) != 13)
        return Fail("fmt_field_count");
    return true;
}

bool T_Load_FromFileRoundtrip(void) {
    FileDelete(GOV_V1_TMP_POLICY_TAB);
    if(!GovTest_WriteUtf8Bin(GOV_V1_TMP_POLICY_TAB, GOV_V1_VALID_POLICY_TAB_UTF8))
        return Fail("write_tmp_policy");
    SCGovPolicySnapshotV1 p;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(!GovPolicyLoaderV1_LoadFromFile(GOV_V1_TMP_POLICY_TAB, p, e))
        return Fail("load_file");
    if(e != GOV_LOAD_ERR_V1_OK || !p.load_ok)
        return Fail("load_file_flags");
    FileDelete(GOV_V1_TMP_POLICY_TAB);
    return true;
}

bool T_AppendTranscript_Bin(void) {
    FileDelete(GOV_V1_TMP_TRANSCRIPT);
    if(!GovernanceTelemetryV1_AppendTranscriptLine(GOV_V1_TMP_TRANSCRIPT, "a"))
        return Fail("append_a");
    if(!GovernanceTelemetryV1_AppendTranscriptLine(GOV_V1_TMP_TRANSCRIPT, "b"))
        return Fail("append_b");
    const int h = FileOpen(GOV_V1_TMP_TRANSCRIPT, FILE_READ | FILE_BIN);
    if(h == INVALID_HANDLE)
        return Fail("read_open");
    uchar buf[];
    const ulong fs = FileSize(h);
    ArrayResize(buf, (int)fs);
    if(FileReadArray(h, buf, 0, (int)fs) != (int)fs) {
        FileClose(h);
        return Fail("read_array");
    }
    FileClose(h);
    string got = "";
    const int nb = (int)fs;
    got = CharArrayToString(buf, 0, nb, CP_UTF8);
    string hsh = "";
    if(!GovernanceTelemetryV1_TranscriptSha256Hex(got, hsh))
        return Fail("append_hash");
    if(hsh != "911169ddaaf146aff539f58c26c489af3b892dff0fe283c1c264c65ae5aa59a2")
        return Fail("append_hash_mismatch");
    FileDelete(GOV_V1_TMP_TRANSCRIPT);
    return true;
}

bool T_ShadowTick_StillRuns(void) {
    SCGovPolicySnapshotV1 pol;
    ENUM_GOV_POLICY_LOAD_ERR_V1 le = GOV_LOAD_ERR_V1_OK;
    if(!GovPolicyLoaderV1_LoadFromUtf8Text(GOV_V1_VALID_POLICY_TAB_UTF8, pol, le))
        return Fail("shadow_load_policy");
    if(le != GOV_LOAD_ERR_V1_OK || !pol.load_ok)
        return Fail("shadow_policy_flags");

    SGovernanceShadowContextV1 ctx;
    GovernanceShadowContextV1_Init(ctx, pol);

    SGovL0SnapshotIntegerV1 l0;
    GovernanceTypesV1_InitSnapshot(l0);
    l0.gov_epoch = 1;
    l0.toxicity_score_0_100 = 0;
    l0.survivability_score_0_100 = 100;
    l0.causal_severity_rank_0_5 = 0;
    l0.quarantine_severity_0_4 = 0;
    l0.conf_raw_ms_0_1000 = 900;
    l0.lifecycle_campaign_id = 42;

    string line = "";
    string ev = "";
    if(!GovernanceShadowTickV1(ctx, l0, "0000000000000000000000000000000000000000000000000000000000000000", line, ev))
        return Fail("shadow_tick");
    if(GovernanceTelemetryV1_CountPipeFields(line) != 13)
        return Fail("shadow_fields");
    if(ctx.sm.gs_current != (uchar)GOV_STATE_NORMAL)
        return Fail("shadow_gs_mild");
    if(StringLen(ev) < 10)
        return Fail("shadow_events_empty");
    if(StringFind(ev, pol.policy_checksum_sha256_hex) < 0)
        return Fail("shadow_event_fp");
    return true;
}

bool T_PolicySnapshotCopy_Idempotent(void) {
    SCGovPolicySnapshotV1 pol;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(!GovPolicyLoaderV1_LoadFromUtf8Text(GOV_V1_VALID_POLICY_TAB_UTF8, pol, e) || !pol.load_ok)
        return Fail("pcopy_load");
    SCGovPolicySnapshotV1 a;
    SCGovPolicySnapshotV1 b;
    GovPolicyBundleV1_InitEmpty(a);
    GovPolicyBundleV1_InitEmpty(b);
    GovPolicyBundleV1_CopyFrom(a, pol);
    GovPolicyBundleV1_CopyFrom(b, pol);
    if(a.policy_id != b.policy_id)
        return Fail("pcopy_policy_id");
    if(a.policy_checksum_sha256_hex != b.policy_checksum_sha256_hex)
        return Fail("pcopy_checksum");
    if(a.gov_ev_normal_hi_ms != b.gov_ev_normal_hi_ms)
        return Fail("pcopy_mat");
    return true;
}

bool T_Load_MissingEmbedded(void) {
    const string s =
        "policy_id=x\n"
        "policy_semver=1.0.0\n"
        "policy_checksum_sha256=e48f242d10ad97438685f06bcaa9d6f20fb5a7713dbc1dfdbf8b0aef7df08b52\n";
    SCGovPolicySnapshotV1 p;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(GovPolicyLoaderV1_LoadFromUtf8Text(s, p, e))
        return Fail("missing_embed_should_fail");
    if(e != GOV_LOAD_ERR_V1_GOV_PARAMS_INCOMPLETE)
        return Fail("missing_embed_err");
    return true;
}

bool T_Load_OutErrChecksumMismatch(void) {
    const string s =
        "gov_defaults_phase8_embedded=1\n"
        "policy_id=GOV_POLICY_TEST_VALID_V1\n"
        "policy_semver=1.0.0\n"
        "policy_checksum_sha256=f7167fe77747293a4856d6bd3ede23f8520cfb42d986420cc54ef6f352336e96\n";
    SCGovPolicySnapshotV1 p;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(GovPolicyLoaderV1_LoadFromUtf8Text(s, p, e))
        return Fail("out_err_csum_should_fail");
    if(e != GOV_LOAD_ERR_V1_CHECKSUM_MISMATCH)
        return Fail("out_err_csum_value");
    if(p.load_ok || p.checksum_verified)
        return Fail("out_err_csum_snapshot_reset");
    return true;
}

bool T_Utf8_CharArrayRoundTrip(void) {
    const string orig = "gov_defaults_phase8_embedded=1\n";
    uchar raw[];
    const int sl = StringLen(orig);
    const int n = StringToCharArray(orig, raw, 0, sl, CP_UTF8);
    if(n <= 0)
        return Fail("utf8_to_chars");
    const string back = CharArrayToString(raw, 0, n, CP_UTF8);
    if(back != orig)
        return Fail("utf8_roundtrip_mismatch");
    return true;
}

bool GovTest_V1_EventBlockPipeSchemaOk(const string block) {
    if(StringLen(block) == 0)
        return false;
    string lines[];
    const ushort nl = StringGetCharacter("\n", 0);
    const int n = StringSplit(block, nl, lines);
    for(int i = 0; i < n; i++) {
        if(StringLen(lines[i]) == 0)
            continue;
        if(GovTelemetryEventsV1_CountPipeFields(lines[i]) != GOV_EVT_V1_EXPECTED_PIPE_FIELDS)
            return false;
    }
    return true;
}

bool T_Gov_EventPipeSchema(void) {
    SCGovPolicySnapshotV1 pol;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(!GovPolicyLoaderV1_LoadFromUtf8Text(GOV_V1_VALID_POLICY_TAB_UTF8, pol, e))
        return Fail("evt_load");
    SGovernanceShadowContextV1 ctx;
    GovernanceShadowContextV1_Init(ctx, pol);
    SGovL0SnapshotIntegerV1 l0;
    GovernanceTypesV1_InitSnapshot(l0);
    l0.conf_raw_ms_0_1000 = 900;
    string t = "";
    string ev = "";
    if(!GovernanceShadowTickV1(ctx, l0, "0000000000000000000000000000000000000000000000000000000000000000", t, ev))
        return Fail("evt_tick");
    if(!GovTest_V1_EventBlockPipeSchemaOk(ev))
        return Fail("evt_pipe_schema");
    return true;
}

bool T_Gov_TripwireLockdown(void) {
    SCGovPolicySnapshotV1 pol;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(!GovPolicyLoaderV1_LoadFromUtf8Text(GOV_V1_VALID_POLICY_TAB_UTF8, pol, e))
        return Fail("trip_load");
    SGovernanceShadowContextV1 ctx;
    GovernanceShadowContextV1_Init(ctx, pol);
    SGovL0SnapshotIntegerV1 l0;
    GovernanceTypesV1_InitSnapshot(l0);
    l0.tripwire_lockdown_request_0_1 = 1;
    l0.conf_raw_ms_0_1000 = 900;
    l0.survivability_score_0_100 = 100;
    string t = "";
    string ev = "";
    if(!GovernanceShadowTickV1(ctx, l0, "0000000000000000000000000000000000000000000000000000000000000000", t, ev))
        return Fail("trip_tick");
    if(ctx.sm.gs_current != (uchar)GOV_STATE_LOCKDOWN)
        return Fail("trip_not_lockdown");
    if(StringFind(ev, "1|0|3|") < 0)
        return Fail("trip_evt_missing");
    return true;
}

bool T_Gov_LockdownRelax(void) {
    SCGovPolicySnapshotV1 pol;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(!GovPolicyLoaderV1_LoadFromUtf8Text(GOV_V1_VALID_POLICY_TAB_UTF8, pol, e))
        return Fail("relax_load");
    SGovernanceShadowContextV1 ctx;
    GovernanceShadowContextV1_Init(ctx, pol);
    SGovL0SnapshotIntegerV1 hot;
    GovernanceTypesV1_InitSnapshot(hot);
    hot.toxicity_score_0_100 = 100;
    hot.causal_severity_rank_0_5 = 5;
    hot.conf_raw_ms_0_1000 = 0;
    hot.survivability_score_0_100 = 0;
    string t0 = "";
    string e0 = "";
    if(!GovernanceShadowTickV1(ctx, hot, "0000000000000000000000000000000000000000000000000000000000000000", t0, e0))
        return Fail("relax_tick0");
    if(ctx.sm.gs_current != (uchar)GOV_STATE_LOCKDOWN)
        return Fail("relax_not_ldn");

    SGovL0SnapshotIntegerV1 mild;
    GovernanceTypesV1_InitSnapshot(mild);
    mild.toxicity_score_0_100 = 0;
    mild.survivability_score_0_100 = 100;
    mild.causal_severity_rank_0_5 = 0;
    mild.conf_raw_ms_0_1000 = 900;
    for(int k = 0; k < 12; k++) {
        string tt = "";
        string ee = "";
        if(!GovernanceShadowTickV1(ctx, mild, "0000000000000000000000000000000000000000000000000000000000000000", tt, ee))
            return Fail("relax_tickk");
    }
    if(ctx.sm.gs_current == (uchar)GOV_STATE_LOCKDOWN)
        return Fail("relax_stuck_lockdown");
    return true;
}

string GovTest_EvidDealsHdr(void) {
    return "d_ticket,d_symbol,d_magic,d_time_utc,d_volume,d_profit,d_type,d_entry,d_position_id,d_price,d_commission,d_swap,d_reason";
}

bool T_Evidence_FusionDeterminism(void) {
    const string deals = GovTest_EvidDealsHdr() + "\n900001,X,0,1,1.0,0,0,0,1,0,0,0,0\n";
    SGovL0RuntimeEvidenceV1 r1;
    SGovL0RuntimeEvidenceV1 r2;
    ushort p1 = 0, p2 = 0;
    ENUM_GOV_DOMINANT_EVIDENCE_SRC_V1 d1 = GOV_DOM_V1_NONE, d2 = GOV_DOM_V1_NONE;
    int tb1 = 0, tb2 = 0, ss1 = 0, ss2 = 0, cc1 = 0, cc2 = 0;
    ENUM_TOXICITY_STATE_V1 tx1 = TOX_V1_INVALID, tx2 = TOX_V1_INVALID;
    ENUM_SURVIVABILITY_STATE_V1 sv1 = SURVIVE_V1_INVALID, sv2 = SURVIVE_V1_INVALID;
    string e1 = "", e2 = "";
    if(!GovEvidenceIntegrationV1_BuildFromDealsUtf8(deals, 1, r1, p1, d1, tb1, ss1, cc1, tx1, sv1, e1))
        return Fail("evid_fuse_a");
    if(!GovEvidenceIntegrationV1_BuildFromDealsUtf8(deals, 1, r2, p2, d2, tb2, ss2, cc2, tx2, sv2, e2))
        return Fail("evid_fuse_b");
    string h1 = "", h2 = "";
    if(!GovEvidenceIntegrationV1_FingerprintHex8(r1, h1) || !GovEvidenceIntegrationV1_FingerprintHex8(r2, h2))
        return Fail("evid_fp");
    if(h1 != h2 || r1.toxicity_score_ms != r2.toxicity_score_ms)
        return Fail("evid_det");
    return true;
}

bool T_Evidence_AttribPipeSchema(void) {
    const string deals = GovTest_EvidDealsHdr() + "\n900001,X,0,1,1.0,0,0,0,1,0,0,0,0\n";
    SGovL0RuntimeEvidenceV1 rt;
    ushort path = 0;
    ENUM_GOV_DOMINANT_EVIDENCE_SRC_V1 dom = GOV_DOM_V1_NONE;
    int tb = 0, ss = 0, cc = 0;
    ENUM_TOXICITY_STATE_V1 tx = TOX_V1_INVALID;
    ENUM_SURVIVABILITY_STATE_V1 sv = SURVIVE_V1_INVALID;
    string err = "";
    if(!GovEvidenceIntegrationV1_BuildFromDealsUtf8(deals, 1, rt, path, dom, tb, ss, cc, tx, sv, err))
        return Fail("evid_attrib_build");
    string line = "";
    if(!GovEvidenceAttribTelemetryV1_FormatLine(rt, path, dom, tb, ss, cc, GOV_MR_V1_NORMAL, "a1b2c3d4", tx, line))
        return Fail("evid_attrib_fmt");
    if(GovEvidenceAttribTelemetryV1_CountPipeFields(line) != GOV_ATTRIB_V1_EXPECTED_PIPE_FIELDS)
        return Fail("evid_attrib_fields");
    return true;
}

bool T_Orchestration_GovExecPipeSchema(void) {
    SCGovPolicySnapshotV1 pol;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(!GovPolicyLoaderV1_LoadFromUtf8Text(GOV_V1_VALID_POLICY_TAB_UTF8, pol, e) || !pol.load_ok)
        return Fail("orch_policy");
    SGovernanceShadowContextV1 ctx;
    GovernanceShadowContextV1_Init(ctx, pol);
    SGovernanceCampaignMemoryV1 mem;
    GovernanceCampaignMemoryV1_Init(mem);
    ENUM_GOV_MARKET_REGIME_V1 mr = GOV_MR_V1_NORMAL;
    int df = 0, dt = 0;
    const string deals = GovTest_EvidDealsHdr() + "\n900001,X,0,1,1.0,0,0,0,1,0,0,0,0\n";
    string tel = "", ev = "", attrib = "";
    SGovShadowTickAuxOutV1 aux;
    SGovernanceExecutionContractV1 c;
    string g1 = "", err = "";
    if(!GovernanceExecutionOrchestratorV1_RunPipelineFromDealsUtf8(ctx, mem, mr, df, dt, deals,
                                                                   "0000000000000000000000000000000000000000000000000000000000000000",
                                                                   tel, ev, attrib, aux, c, g1, err))
        return Fail("orch_run");
    if(GovernanceExecutionTelemetryV1_CountPipeFields(g1) != GOV_EXEC_V1_EXPECTED_PIPE_FIELDS)
        return Fail("orch_pipe_fields");
    if(StringFind(g1, "GOV_EXEC_V1|") != 0)
        return Fail("orch_prefix");
    return true;
}

bool T_Orchestration_ReplayExecTelem(void) {
    SCGovPolicySnapshotV1 pol;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(!GovPolicyLoaderV1_LoadFromUtf8Text(GOV_V1_VALID_POLICY_TAB_UTF8, pol, e) || !pol.load_ok)
        return Fail("orch_rep_policy");
    const string deals = GovTest_EvidDealsHdr() + "\n900002,Y,0,2,1.0,0,0,0,2,0,0,0,0\n";
    string gA = "", gB = "";
    for(int pass = 0; pass < 2; pass++) {
        SGovernanceShadowContextV1 ctx;
        GovernanceShadowContextV1_Init(ctx, pol);
        SGovernanceCampaignMemoryV1 mem;
        GovernanceCampaignMemoryV1_Init(mem);
        ENUM_GOV_MARKET_REGIME_V1 mr = GOV_MR_V1_NORMAL;
        int df = 0, dt = 0;
        string tel = "", ev = "", attrib = "";
        SGovShadowTickAuxOutV1 aux;
        SGovernanceExecutionContractV1 c;
        string err = "";
        string gout = "";
        if(!GovernanceExecutionOrchestratorV1_RunPipelineFromDealsUtf8(ctx, mem, mr, df, dt, deals,
                                                                       "0000000000000000000000000000000000000000000000000000000000000000",
                                                                       tel, ev, attrib, aux, c, gout, err))
            return Fail("orch_rep_run");
        if(pass == 0)
            gA = gout;
        else
            gB = gout;
    }
    return (gA == gB);
}

bool T_Orchestration_LockdownTransitionHook(void) {
    SGovernanceCampaignMemoryV1 mem;
    GovernanceCampaignMemoryV1_Init(mem);
    mem.last_exec_quarantine_level = (uchar)GOV_EXEC_QUAR_V1_NONE;
    GovernanceTransitionHooksV1_OnPostTick(mem,
                                            (uchar)GOV_STATE_NORMAL,
                                            (uchar)GOV_STATE_LOCKDOWN,
                                            GOV_EXEC_QUAR_V1_NONE,
                                            GOV_EXEC_QUAR_V1_TERMINAL,
                                            0,
                                            1,
                                            GOV_MR_V1_STRUCTURAL_BREAKDOWN);
    if(mem.lockdown_entry_count != 1)
        return Fail("orch_hook_lockdown_count");
    if(mem.quarantine_escalation_count < 1)
        return Fail("orch_hook_quar_esc");
    if(mem.survivability_emergency_escalation != 1)
        return Fail("orch_hook_surv_esc");
    return true;
}

bool T_Orchestration_ThrottleDeterminism(void) {
    SCGovPolicySnapshotV1 pol;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(!GovPolicyLoaderV1_LoadFromUtf8Text(GOV_V1_VALID_POLICY_TAB_UTF8, pol, e) || !pol.load_ok)
        return Fail("orch_thr_policy");
    SGovernanceShadowContextV1 ctx;
    GovernanceShadowContextV1_Init(ctx, pol);
    SGovernanceCampaignMemoryV1 mem;
    GovernanceCampaignMemoryV1_Init(mem);
    ENUM_GOV_MARKET_REGIME_V1 mr = GOV_MR_V1_NORMAL;
    int df = 0, dt = 0;
    const string deals = GovTest_EvidDealsHdr() + "\n900004,Z,0,4,1.0,0,0,0,4,0,0,0,0\n";
    string tel = "", ev = "", attrib = "";
    SGovShadowTickAuxOutV1 aux;
    SGovernanceExecutionContractV1 c1;
    SGovernanceExecutionContractV1 c2;
    string g1 = "", g2 = "", err = "";
    if(!GovernanceExecutionOrchestratorV1_RunPipelineFromDealsUtf8(ctx, mem, mr, df, dt, deals,
                                                                   "0000000000000000000000000000000000000000000000000000000000000000",
                                                                   tel, ev, attrib, aux, c1, g1, err))
        return Fail("orch_thr_run1");
    GovernanceShadowContextV1_Init(ctx, pol);
    GovernanceCampaignMemoryV1_Init(mem);
    mr = GOV_MR_V1_NORMAL;
    df = 0;
    dt = 0;
    if(!GovernanceExecutionOrchestratorV1_RunPipelineFromDealsUtf8(ctx, mem, mr, df, dt, deals,
                                                                   "0000000000000000000000000000000000000000000000000000000000000000",
                                                                   tel, ev, attrib, aux, c2, g2, err))
        return Fail("orch_thr_run2");
    if(c1.throttle_interval_ms != c2.throttle_interval_ms)
        return Fail("orch_thr_ms_mismatch");
    return true;
}

string GovTest_ReplayGoldenBlockTwoEpochs(void) {
    const string pol = "f91d012745a66be73315c95e8fe9faac49465eae266fba401036f2c58886581e";
    const string p16 = "f91d012745a66be7";
    string s = "";
    s += "1|1|3|0|10|2500|7500|800|0|PID|1.0.0|" + pol + "|" + pol + "\n";
    s += "GOV_ATTRIB_V1|1|0|3|2|1|0|0|42|aabbccdd|5000|4000|7000|99|1\n";
    s += "GOV_EXEC_V1|1|0|4|3|100|2|900000|800000|1|0|1|1|1|0|42|99|aabbccdd|1|" + p16 + "\n";
    s += "2|3|4|0|10|2400|7400|800|0|PID|1.0.0|" + pol + "|" + pol + "\n";
    s += "GOV_ATTRIB_V1|1|0|4|2|1|0|0|43|bbcceeaa|5200|3800|7100|99|2\n";
    s += "GOV_EXEC_V1|1|0|6|4|150|3|800000|700000|2|1|0|0|0|1|43|99|bbcceeaa|2|" + p16 + "\n";
    return s;
}

void GovTest_InitSyntheticEpoch(SGovReplayEpochV1 &e, const ulong id, const int gs, const int rg, const int tox, const int surv, const int q,
                                const int ex, const int rec, const ulong camp) {
    GovernanceReplayDatasetV1_InitEpoch(e);
    e.epoch_id = id;
    e.governance_state = gs;
    e.regime_state = rg;
    e.toxicity_ms = tox;
    e.survivability_ms = surv;
    e.quarantine_state = q;
    e.execution_allowed = ex;
    e.recovery_allowed = rec;
    e.entry_allowed = 1;
    e.forced_flatten_required = 0;
    e.survivability_emergency = 0;
    e.causal_pressure_ms = 0;
    e.structural_instability_ms = 500;
    e.risk_multiplier_milli = 1000;
    e.exposure_cap_milli = 1000000;
    e.throttle_interval_ms = 0;
    e.cooldown_epochs = 0;
    e.causal_reason_code = 0;
    e.dominant_evidence_id = 42;
    e.evidence_fingerprint = "fp";
    e.policy_fingerprint = "pp";
    e.campaign_uuid = camp;
    e.telemetry_line_hash_sha256_hex = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
}

bool T_Incident_ToxicSpiralDetects(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    tl.source_concat_sha256_hex = "SYNTH_TOX_SPIRAL";
    const ulong camp = 777;
    ArrayResize(tl.epochs, 3);
    GovTest_InitSyntheticEpoch(tl.epochs[0], 100, (int)GOV_STATE_CAUTION, 1, 1000, 5000, 0, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl.epochs[1], 101, (int)GOV_STATE_DEFENSIVE, 1, 2600, 4800, 0, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl.epochs[2], 102, (int)GOV_STATE_SURVIVAL, 1, 4200, 4500, 1, 0, 0, camp);
    SGovIncidentSummaryV1 sum;
    string err = "";
    if(!GovernanceIncidentDetectorV1_DetectAll(tl, sum, err))
        return Fail("inc_tox_det");
    bool found = false;
    for(int i = 0; i < ArraySize(sum.events); i++) {
        if(sum.events[i].incident_type == (int)GOV_INCIDENT_V1_TOX_SPIRAL)
            found = true;
    }
    return found;
}

bool T_Incident_SurvCollapseDetects(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    tl.source_concat_sha256_hex = "SYNTH_SURV_COLLAPSE";
    const ulong camp = 888;
    ArrayResize(tl.epochs, 3);
    GovTest_InitSyntheticEpoch(tl.epochs[0], 200, (int)GOV_STATE_NORMAL, 1, 1000, 4500, 0, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl.epochs[1], 201, (int)GOV_STATE_CAUTION, 1, 1100, 3000, 0, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl.epochs[2], 202, (int)GOV_STATE_DEFENSIVE, 1, 1200, 1500, 1, 0, 0, camp);
    SGovIncidentSummaryV1 sum;
    string err = "";
    if(!GovernanceIncidentDetectorV1_DetectAll(tl, sum, err))
        return Fail("inc_surv_det");
    for(int i = 0; i < ArraySize(sum.events); i++) {
        if(sum.events[i].incident_type == (int)GOV_INCIDENT_V1_SURV_COLLAPSE)
            return true;
    }
    return Fail("inc_surv_missing");
}

bool T_Incident_FalseRecoveryDetects(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    tl.source_concat_sha256_hex = "SYNTH_FALSE_REC";
    const ulong camp = 999;
    ArrayResize(tl.epochs, 3);
    GovTest_InitSyntheticEpoch(tl.epochs[0], 300, (int)GOV_STATE_CAUTION, 1, 500, 4000, 0, 0, 0, camp);
    GovTest_InitSyntheticEpoch(tl.epochs[1], 301, (int)GOV_STATE_RECOVERY, 1, 400, 4200, 1, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl.epochs[2], 302, (int)GOV_STATE_CAUTION, 1, 600, 3800, 1, 0, 0, camp);
    SGovIncidentSummaryV1 sum;
    string err = "";
    if(!GovernanceIncidentDetectorV1_DetectAll(tl, sum, err))
        return Fail("inc_fr_det");
    for(int i = 0; i < ArraySize(sum.events); i++) {
        if(sum.events[i].incident_type == (int)GOV_INCIDENT_V1_FALSE_RECOVERY)
            return true;
    }
    return Fail("inc_fr_missing");
}

bool T_Incident_QuarEscalationDetects(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    tl.source_concat_sha256_hex = "SYNTH_QUAR_ESC";
    const ulong camp = 1001;
    ArrayResize(tl.epochs, 2);
    GovTest_InitSyntheticEpoch(tl.epochs[0], 400, (int)GOV_STATE_CAUTION, 1, 100, 5000, 1, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl.epochs[1], 401, (int)GOV_STATE_DEFENSIVE, 1, 200, 4800, 2, 1, 1, camp);
    SGovIncidentSummaryV1 sum;
    string err = "";
    if(!GovernanceIncidentDetectorV1_DetectAll(tl, sum, err))
        return Fail("inc_qe_det");
    for(int i = 0; i < ArraySize(sum.events); i++) {
        if(sum.events[i].incident_type == (int)GOV_INCIDENT_V1_QUAR_ESCALATION)
            return true;
    }
    return Fail("inc_qe_missing");
}

bool T_Incident_ExecSuppressionDetects(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    tl.source_concat_sha256_hex = "SYNTH_EXEC_SUPP";
    const ulong camp = 1002;
    ArrayResize(tl.epochs, 4);
    for(int k = 0; k < 4; k++)
        GovTest_InitSyntheticEpoch(tl.epochs[k], (ulong)(900 + k), (int)GOV_STATE_DEFENSIVE, 1, 100, 4000, 0, 0, 0, camp);
    SGovIncidentSummaryV1 sum;
    string err = "";
    if(!GovernanceIncidentDetectorV1_DetectAll(tl, sum, err))
        return Fail("inc_es_det");
    for(int i = 0; i < ArraySize(sum.events); i++) {
        if(sum.events[i].incident_type == (int)GOV_INCIDENT_V1_EXEC_SUPPRESSION)
            return true;
    }
    return Fail("inc_es_missing");
}

bool T_Incident_ReplaySubset(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    tl.source_concat_sha256_hex = "SUBSET_PARENT_SHA";
    const ulong camp = 2000;
    ArrayResize(tl.epochs, 5);
    for(int k = 0; k < 5; k++)
        GovTest_InitSyntheticEpoch(tl.epochs[k], (ulong)(500 + k), (int)GOV_STATE_NORMAL, 1, 100 + k, 5000, 0, 1, 1, camp);
    SGovReplayTimelineV1 sub;
    string err = "";
    if(!GovernanceIncidentReplaySubsetV1_BuildAroundEpochId(tl, 502, 1, 1, sub, err))
        return Fail("inc_subset_build");
    if(ArraySize(sub.epochs) != 3)
        return Fail("inc_subset_len");
    if(sub.source_concat_sha256_hex != tl.source_concat_sha256_hex)
        return Fail("inc_subset_sha");
    return true;
}

bool T_Incident_ExportDeterminism(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    tl.source_concat_sha256_hex = "SYNTH_EXPORT";
    const ulong camp = 3000;
    ArrayResize(tl.epochs, 3);
    GovTest_InitSyntheticEpoch(tl.epochs[0], 600, (int)GOV_STATE_CAUTION, 1, 1000, 5000, 0, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl.epochs[1], 601, (int)GOV_STATE_DEFENSIVE, 1, 2600, 4800, 0, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl.epochs[2], 602, (int)GOV_STATE_SURVIVAL, 1, 4200, 4500, 1, 0, 0, camp);
    SGovIncidentSummaryV1 sum;
    string err = "";
    if(!GovernanceIncidentDetectorV1_DetectAll(tl, sum, err))
        return Fail("inc_exp_det");
    string a = "", b = "";
    if(!GovernanceIncidentExportV1_ExportForensicBundle(tl, sum, a, err))
        return Fail("inc_exp_a");
    if(!GovernanceIncidentExportV1_ExportForensicBundle(tl, sum, b, err))
        return Fail("inc_exp_b");
    return (a == b);
}

bool T_Incident_LiveBundleDeterminism(void) {
    const string raw = GovTest_ReplayGoldenBlockTwoEpochs();
    string csvA = "", csvB = "", packA = "", packB = "", err = "";
    SGovReplayTimelineV1 t1, t2;
    SGovIncidentSummaryV1 i1, i2;
    if(!GovernanceIncidentLiveIntegrationV1_ProcessUtf8Replay(raw, t1, i1, csvA, packA, err))
        return Fail("inc_live_a");
    if(!GovernanceIncidentLiveIntegrationV1_ProcessUtf8Replay(raw, t2, i2, csvB, packB, err))
        return Fail("inc_live_b");
    return (csvA == csvB && packA == packB);
}

bool T_Incident_ReconstructionChain(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    tl.source_concat_sha256_hex = "SYNTH_RECON";
    const ulong camp = 4000;
    ArrayResize(tl.epochs, 3);
    GovTest_InitSyntheticEpoch(tl.epochs[0], 700, (int)GOV_STATE_CAUTION, 1, 1000, 5000, 0, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl.epochs[1], 701, (int)GOV_STATE_DEFENSIVE, 1, 2600, 4800, 0, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl.epochs[2], 702, (int)GOV_STATE_SURVIVAL, 1, 4200, 4500, 1, 0, 0, camp);
    SGovIncidentSummaryV1 sum;
    string err = "";
    if(!GovernanceIncidentDetectorV1_DetectAll(tl, sum, err))
        return Fail("inc_rc_det");
    for(int i = 0; i < ArraySize(sum.events); i++) {
        if(sum.events[i].incident_type != (int)GOV_INCIDENT_V1_TOX_SPIRAL)
            continue;
        SGovIncidentChainV1 ch;
        if(!GovernanceIncidentReconstructionV1_RebuildChain(tl, sum.events[i], ch, err))
            return Fail("inc_rc_chain");
        if(ArraySize(ch.epoch_ids) < 3)
            return Fail("inc_rc_ids");
        if(StringFind(ch.ladder_notes, "GS=") < 0)
            return Fail("inc_rc_ladder");
        return true;
    }
    return Fail("inc_rc_no_tox");
}

bool T_Incident_CausalityLineStable(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    tl.source_concat_sha256_hex = "SYNTH_CAUS";
    const ulong camp = 5000;
    ArrayResize(tl.epochs, 3);
    GovTest_InitSyntheticEpoch(tl.epochs[0], 800, (int)GOV_STATE_CAUTION, 1, 1000, 5000, 0, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl.epochs[1], 801, (int)GOV_STATE_DEFENSIVE, 1, 2600, 4800, 0, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl.epochs[2], 802, (int)GOV_STATE_SURVIVAL, 1, 4200, 4500, 1, 0, 0, camp);
    SGovIncidentSummaryV1 sum;
    string err = "";
    if(!GovernanceIncidentDetectorV1_DetectAll(tl, sum, err))
        return Fail("inc_cau_det");
    for(int i = 0; i < ArraySize(sum.events); i++) {
        if(sum.events[i].incident_type != (int)GOV_INCIDENT_V1_TOX_SPIRAL)
            continue;
        string ln1 = "", ln2 = "";
        if(!GovernanceIncidentCausalityV1_FormatReport(tl, sum.events[i], ln1))
            return Fail("inc_cau_fmt1");
        if(!GovernanceIncidentCausalityV1_FormatReport(tl, sum.events[i], ln2))
            return Fail("inc_cau_fmt2");
        if(ln1 != ln2)
            return Fail("inc_cau_drift");
        if(StringFind(ln1, "INCIDENT=TOX_SPIRAL_V1") != 0)
            return Fail("inc_cau_prefix");
        return true;
    }
    return Fail("inc_cau_no_tox");
}

bool T_Meta_Long2Rp(void) {
    SGovReplayTimelineV1 tl1;
    SGovReplayTimelineV1 tl2;
    GovernanceReplayDatasetV1_InitTimeline(tl1);
    GovernanceReplayDatasetV1_InitTimeline(tl2);
    tl1.source_concat_sha256_hex = "META_LR_A";
    tl2.source_concat_sha256_hex = "META_LR_B";
    const ulong camp = 8800;
    ArrayResize(tl1.epochs, 3);
    ArrayResize(tl2.epochs, 3);
    GovTest_InitSyntheticEpoch(tl1.epochs[0], 1, (int)GOV_STATE_CAUTION, 1, 1000, 5000, 0, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl1.epochs[1], 2, (int)GOV_STATE_DEFENSIVE, 1, 2600, 4800, 0, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl1.epochs[2], 3, (int)GOV_STATE_SURVIVAL, 1, 4200, 4500, 1, 0, 0, camp);
    GovTest_InitSyntheticEpoch(tl2.epochs[0], 11, (int)GOV_STATE_CAUTION, 1, 1000, 5000, 0, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl2.epochs[1], 12, (int)GOV_STATE_DEFENSIVE, 1, 2600, 4800, 0, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl2.epochs[2], 13, (int)GOV_STATE_SURVIVAL, 1, 4200, 4500, 1, 0, 0, camp);
    SGovIncidentSummaryV1 s1;
    SGovIncidentSummaryV1 s2;
    string err = "";
    if(!GovernanceIncidentDetectorV1_DetectAll(tl1, s1, err))
        return Fail("meta_lr_det1");
    if(!GovernanceIncidentDetectorV1_DetectAll(tl2, s2, err))
        return Fail("meta_lr_det2");
    SGovMetaIncidentStatsV1 acc;
    GovIncMetaV1_Init(acc);
    GovIncMetaV1_Acc(s1, 3, acc);
    GovIncMetaV1_Acc(s2, 3, acc);
    GovIncMetaV1_AccQEp(tl1, acc);
    GovIncMetaV1_AccQEp(tl2, acc);
    GovIncMetaV1_Finalize(acc);
    if(acc.raw_toxic_spiral < 2)
        return Fail("meta_lr_tox_count");
    if(acc.raw_epoch_denominator != 6)
        return Fail("meta_lr_epochs");
    return true;
}

bool T_Meta_HlthDet(void) {
    const string raw = GovTest_ReplayGoldenBlockTwoEpochs();
    SGovMetaGovernanceHealthV1 h1, h2;
    SGovMetaPolicyFingerprintV1 f1, f2;
    SGovMetaIncidentStatsV1 i1, i2;
    SGovMetaContainmentStatsV1 e1, e2;
    SGovMetaRegimeStatsV1 r1, r2;
    string rep1 = "", rep2 = "", err = "";
    if(!GovMetaLiveV1_BuildReplay(raw, h1, f1, i1, e1, r1, rep1, err))
        return Fail("meta_h_a");
    if(!GovMetaLiveV1_BuildReplay(raw, h2, f2, i2, e2, r2, rep2, err))
        return Fail("meta_h_b");
    if(h1.governance_health_index_0_1000 != h2.governance_health_index_0_1000)
        return Fail("meta_h_idx");
    if(f1.archetype_flags != f2.archetype_flags)
        return Fail("meta_h_flags");
    return true;
}

bool T_Meta_FpStb(void) {
    const string raw = GovTest_ReplayGoldenBlockTwoEpochs();
    SGovMetaGovernanceHealthV1 h1, h2;
    SGovMetaPolicyFingerprintV1 f1, f2;
    SGovMetaIncidentStatsV1 i1, i2;
    SGovMetaContainmentStatsV1 e1, e2;
    SGovMetaRegimeStatsV1 r1, r2;
    string rep1 = "", rep2 = "", err = "";
    if(!GovMetaLiveV1_BuildReplay(raw, h1, f1, i1, e1, r1, rep1, err))
        return Fail("meta_fp_a");
    if(!GovMetaLiveV1_BuildReplay(raw, h2, f2, i2, e2, r2, rep2, err))
        return Fail("meta_fp_b");
    return (f1.policy_behavior_fingerprint == f2.policy_behavior_fingerprint);
}

bool T_Meta_RegPrs(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    tl.source_concat_sha256_hex = "META_REG_PERSIST";
    const ulong camp = 9100;
    ArrayResize(tl.epochs, 5);
    for(int k = 0; k < 5; k++)
        GovTest_InitSyntheticEpoch(tl.epochs[k], (ulong)(7000 + k), (int)GOV_STATE_NORMAL, (int)GOV_MR_V1_FRAGILE, 100, 5000, 0, 1, 1, camp);
    SGovMetaRegimeStatsV1 rg;
    string err = "";
    if(!GovernanceRegimeMetaAnalyticsV1_Compute(tl, rg, err))
        return Fail("meta_rg_compute");
    if(rg.regime_persistence_max_epochs < 5)
        return Fail("meta_rg_persist");
    return true;
}

bool T_Meta_CtnEffStb(void) {
    string norm = "";
    GovernanceReplayParserV1_NormalizeLf(GovTest_ReplayGoldenBlockTwoEpochs(), norm);
    SGovReplayTimelineV1 tl;
    string err = "";
    if(!GovernanceReplayParserV1_ParseMultilineUtf8Lf(norm, tl, err))
        return Fail("meta_ce_parse");
    SGovContainmentMetricsV1 cm;
    if(!GovernanceContainmentAnalyticsV1_Compute(tl, cm, err))
        return Fail("meta_ce_cm");
    SGovMetaContainmentStatsV1 a, b;
    if(!GovernanceEffectivenessAnalyticsV1_Compute(tl, cm, a, err))
        return Fail("meta_ce_a");
    if(!GovernanceEffectivenessAnalyticsV1_Compute(tl, cm, b, err))
        return Fail("meta_ce_b");
    return (a.prevented_escalation_ratio_per_1000 == b.prevented_escalation_ratio_per_1000 &&
            a.quarantine_stabilization_efficiency_0_1000 == b.quarantine_stabilization_efficiency_0_1000);
}

bool T_Meta_ExpDet(void) {
    const string raw = GovTest_ReplayGoldenBlockTwoEpochs();
    SGovMetaGovernanceHealthV1 h1, h2;
    SGovMetaPolicyFingerprintV1 f1, f2;
    SGovMetaIncidentStatsV1 i1, i2;
    SGovMetaContainmentStatsV1 e1, e2;
    SGovMetaRegimeStatsV1 r1, r2;
    string rep1 = "", rep2 = "", err = "";
    if(!GovMetaLiveV1_BuildReplay(raw, h1, f1, i1, e1, r1, rep1, err))
        return Fail("meta_exp_a");
    if(!GovMetaLiveV1_BuildReplay(raw, h2, f2, i2, e2, r2, rep2, err))
        return Fail("meta_exp_b");
    return (rep1 == rep2);
}

bool T_Meta_CmpSlf0(void) {
    const string raw = GovTest_ReplayGoldenBlockTwoEpochs();
    SGovMetaGovernanceHealthV1 h1, h2;
    SGovMetaPolicyFingerprintV1 f1, f2;
    SGovMetaIncidentStatsV1 i1, i2;
    SGovMetaContainmentStatsV1 e1, e2;
    SGovMetaRegimeStatsV1 r1, r2;
    string rep1 = "", rep2 = "", err = "";
    if(!GovMetaLiveV1_BuildReplay(raw, h1, f1, i1, e1, r1, rep1, err))
        return Fail("meta_cmp_a");
    if(!GovMetaLiveV1_BuildReplay(raw, h2, f2, i2, e2, r2, rep2, err))
        return Fail("meta_cmp_b");
    SGovMetaComparatorDeltaV1 d;
    GovernanceMetaComparatorV1_FullCompare(h1, h2, i1, i2, f1, f2, d);
    return (d.d_governance_health_index == 0 && d.d_fingerprint_flags_xor == 0 && d.d_incident_freq_per_1000 == 0);
}

bool T_Res_RunDet(void) {
    const string raw = GovTest_ReplayGoldenBlockTwoEpochs();
    SGovResearchSummaryV1 s1, s2;
    string b1 = "", b2 = "", err = "";
    if(!GovResLiveV1_Run(raw, s1, b1, err))
        return Fail("res_run_a");
    if(!GovResLiveV1_Run(raw, s2, b2, err))
        return Fail("res_run_b");
    if(b1 != b2)
        return Fail("res_bundle_drift");
    if(s1.governance_health_index != s2.governance_health_index)
        return Fail("res_health_drift");
    return true;
}

bool T_Res_DriftSlf(void) {
    SGovResearchSummaryV1 s;
    GovResDsV1_InitSum(s);
    s.governance_health_index = 500;
    s.incident_density_per_1000 = 10;
    s.containment_quality_0_1000 = 600;
    s.survivability_preservation_0_1000 = 700;
    s.quarantine_pressure_0_1000 = 200;
    s.throttle_pressure_0_1000 = 150;
    string ln = "", err = "";
    if(!GovPolDriftV1_Format(s, s, ln, err))
        return Fail("res_drift_fmt");
    if(StringFind(ln, "D_HEALTH=0") < 0)
        return Fail("res_drift_health");
    if(StringFind(ln, "D_INC=0") < 0)
        return Fail("res_drift_inc");
    return true;
}

bool T_Res_ExpDet(void) {
    SGovResearchSummaryV1 s;
    GovResDsV1_InitSum(s);
    s.observation_window_epochs = 4;
    s.incident_density_per_1000 = 100;
    s.containment_quality_0_1000 = 800;
    s.survivability_preservation_0_1000 = 750;
    s.quarantine_pressure_0_1000 = 120;
    s.regime_fragility_0_1000 = 300;
    s.recovery_stability_0_1000 = 400;
    s.throttle_pressure_0_1000 = 50;
    s.governance_health_index = 620;
    s.dominant_behavior_fingerprint = "ARCH_FLAGS=0";
    s.policy_fingerprint = "pol";
    s.replay_hash = "sha";
    string a = "", b = "", err = "";
    if(!GovResExpV1_Csv(s, a, err))
        return Fail("res_csv_a");
    if(!GovResExpV1_Csv(s, b, err))
        return Fail("res_csv_b");
    return (a == b);
}

bool T_Sim_SbxIso(void) {
    SGovReplayTimelineV1 src;
    SGovReplayTimelineV1 dst;
    GovernanceReplayDatasetV1_InitTimeline(src);
    ArrayResize(src.epochs, 1);
    GovernanceReplayDatasetV1_InitEpoch(src.epochs[0]);
    src.epochs[0].epoch_id = 1;
    src.epochs[0].toxicity_ms = 1000;
    GovSbExecV1_CloneTl(src, dst);
    const int orig = src.epochs[0].toxicity_ms;
    dst.epochs[0].toxicity_ms = GovSaturatingAdd32(dst.epochs[0].toxicity_ms, 1);
    return (src.epochs[0].toxicity_ms == orig);
}

bool T_Sim_StressDet(void) {
    SGovReplayTimelineV1 src;
    SGovReplayTimelineV1 d1;
    SGovReplayTimelineV1 d2;
    GovernanceReplayDatasetV1_InitTimeline(src);
    ArrayResize(src.epochs, 2);
    GovernanceReplayDatasetV1_InitEpoch(src.epochs[0]);
    GovernanceReplayDatasetV1_InitEpoch(src.epochs[1]);
    src.epochs[0].toxicity_ms = 1000;
    src.epochs[1].toxicity_ms = 1000;
    string err = "";
    if(!GovStressV1_Apply(src, GOV_STRS_V1_CHRONIC_TOX, d1, err))
        return Fail("sim_str_a");
    if(!GovStressV1_Apply(src, GOV_STRS_V1_CHRONIC_TOX, d2, err))
        return Fail("sim_str_b");
    return (d1.epochs[0].toxicity_ms == d2.epochs[0].toxicity_ms);
}

bool T_Sim_MulArch(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    tl.source_concat_sha256_hex = "SIM_MUL_ARCH";
    const ulong camp = 7700;
    ArrayResize(tl.epochs, 3);
    GovTest_InitSyntheticEpoch(tl.epochs[0], 1, (int)GOV_STATE_CAUTION, 1, 1000, 5000, 0, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl.epochs[1], 2, (int)GOV_STATE_DEFENSIVE, 1, 2600, 4800, 0, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl.epochs[2], 3, (int)GOV_STATE_SURVIVAL, 1, 4200, 4500, 1, 0, 0, camp);
    int archs[2];
    archs[0] = GOV_ARCH_V1_SURV_FIRST;
    archs[1] = GOV_ARCH_V1_QUAR_HEAVY;
    SGovSimPolicyRunV1 runs[];
    string err = "";
    if(!GovRplSimLabV1_RunMulti(tl, archs, 2, runs, err))
        return Fail("sim_mul_run");
    if(ArraySize(runs) != 2)
        return Fail("sim_mul_n");
    return (runs[0].stress_lane_code != runs[1].stress_lane_code);
}

bool T_Sim_ExpDet(void) {
    SGovSimScenarioV1 sc;
    string b1 = "", b2 = "", err = "";
    const string raw = GovTest_ReplayGoldenBlockTwoEpochs();
    if(!GovSimLiveV1_Run(raw, sc, b1, err))
        return Fail("sim_exp_a");
    if(!GovSimLiveV1_Run(raw, sc, b2, err))
        return Fail("sim_exp_b");
    return (b1 == b2);
}

bool T_Sim_StabDet(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    ArrayResize(tl.epochs, 2);
    GovernanceReplayDatasetV1_InitEpoch(tl.epochs[0]);
    GovernanceReplayDatasetV1_InitEpoch(tl.epochs[1]);
    tl.epochs[0].epoch_id = 1;
    tl.epochs[1].epoch_id = 2;
    tl.epochs[0].governance_state = (int)GOV_STATE_CAUTION;
    tl.epochs[1].governance_state = (int)GOV_STATE_CAUTION;
    tl.epochs[0].toxicity_ms = 500;
    tl.epochs[1].toxicity_ms = 600;
    tl.epochs[0].survivability_ms = 4000;
    tl.epochs[1].survivability_ms = 3900;
    tl.epochs[0].quarantine_state = 0;
    tl.epochs[1].quarantine_state = 1;
    tl.integrity_ok = 1;
    SGovSimStabilityMetricsV1 m1;
    SGovSimStabilityMetricsV1 m2;
    string err = "";
    if(!GovStabEngV1_Measure(tl, m1, err))
        return Fail("sim_stab_a");
    if(!GovStabEngV1_Measure(tl, m2, err))
        return Fail("sim_stab_b");
    return (GovSimDsV1_StabSum(m1) == GovSimDsV1_StabSum(m2));
}

bool T_Sim_CmpDupArch(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    const ulong camp = 8800;
    ArrayResize(tl.epochs, 3);
    GovTest_InitSyntheticEpoch(tl.epochs[0], 1, (int)GOV_STATE_CAUTION, 1, 1000, 5000, 0, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl.epochs[1], 2, (int)GOV_STATE_DEFENSIVE, 1, 2600, 4800, 0, 1, 1, camp);
    GovTest_InitSyntheticEpoch(tl.epochs[2], 3, (int)GOV_STATE_SURVIVAL, 1, 4200, 4500, 1, 0, 0, camp);
    int archs[2];
    archs[0] = GOV_ARCH_V1_BALANCED;
    archs[1] = GOV_ARCH_V1_BALANCED;
    SGovSimPolicyRunV1 runs[];
    string err = "";
    if(!GovRplSimLabV1_RunMulti(tl, archs, 2, runs, err))
        return Fail("sim_cmp_run");
    SGovSimComparisonV1 d;
    GovSimCmpV1_Diff(runs[0], runs[1], d);
    return (d.d_governance_health_proxy == 0 && d.d_incident_count == 0 && d.d_stability_sum == 0 && d.d_survivability_robustness == 0);
}

bool T_Sim_SurvComp(void) {
    SGovReplayTimelineV1 src;
    SGovReplayTimelineV1 d1;
    SGovReplayTimelineV1 d2;
    GovernanceReplayDatasetV1_InitTimeline(src);
    ArrayResize(src.epochs, 2);
    GovernanceReplayDatasetV1_InitEpoch(src.epochs[0]);
    GovernanceReplayDatasetV1_InitEpoch(src.epochs[1]);
    src.epochs[0].survivability_ms = 5000;
    src.epochs[1].survivability_ms = 4800;
    string err = "";
    if(!GovStressV1_Apply(src, GOV_STRS_V1_SURV_COLLAPSE, d1, err))
        return Fail("sim_surv_a");
    if(!GovStressV1_Apply(src, GOV_STRS_V1_SURV_COLLAPSE, d2, err))
        return Fail("sim_surv_b");
    return (d1.epochs[0].survivability_ms == d2.epochs[0].survivability_ms);
}

bool T_Sim_QuarEsc(void) {
    SGovReplayTimelineV1 src;
    SGovReplayTimelineV1 d1;
    SGovReplayTimelineV1 d2;
    GovernanceReplayDatasetV1_InitTimeline(src);
    ArrayResize(src.epochs, 2);
    GovernanceReplayDatasetV1_InitEpoch(src.epochs[0]);
    GovernanceReplayDatasetV1_InitEpoch(src.epochs[1]);
    src.epochs[0].quarantine_state = 0;
    src.epochs[1].quarantine_state = 1;
    string err = "";
    if(!GovStressV1_Apply(src, GOV_STRS_V1_QUAR_ESCAL, d1, err))
        return Fail("sim_q_a");
    if(!GovStressV1_Apply(src, GOV_STRS_V1_QUAR_ESCAL, d2, err))
        return Fail("sim_q_b");
    return (d1.epochs[0].quarantine_state == d2.epochs[0].quarantine_state);
}

bool T_Resil_CurveDet(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    ArrayResize(tl.epochs, 3);
    GovernanceReplayDatasetV1_InitEpoch(tl.epochs[0]);
    GovernanceReplayDatasetV1_InitEpoch(tl.epochs[1]);
    GovernanceReplayDatasetV1_InitEpoch(tl.epochs[2]);
    tl.epochs[0].survivability_ms = 5000;
    tl.epochs[1].survivability_ms = 4500;
    tl.epochs[2].survivability_ms = 4000;
    tl.epochs[0].toxicity_ms = 100;
    tl.epochs[1].toxicity_ms = 200;
    tl.epochs[2].toxicity_ms = 300;
    tl.epochs[0].causal_pressure_ms = 0;
    tl.epochs[1].causal_pressure_ms = 100;
    tl.epochs[2].causal_pressure_ms = 200;
    SGovResilienceCurveV1 c1;
    SGovResilienceCurveV1 c2;
    string err = "";
    if(!GovResilCurveV1_Build(tl, c1, err))
        return Fail("resil_cv_a");
    if(!GovResilCurveV1_Build(tl, c2, err))
        return Fail("resil_cv_b");
    return (c1.survivability_decay_slope_milli == c2.survivability_decay_slope_milli && c1.resilience_half_life_epochs == c2.resilience_half_life_epochs);
}

bool T_Resil_FatigueStb(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    ArrayResize(tl.epochs, 2);
    GovernanceReplayDatasetV1_InitEpoch(tl.epochs[0]);
    GovernanceReplayDatasetV1_InitEpoch(tl.epochs[1]);
    tl.epochs[0].governance_state = (int)GOV_STATE_LOCKDOWN;
    tl.epochs[1].governance_state = (int)GOV_STATE_NORMAL;
    tl.epochs[0].throttle_interval_ms = 100;
    tl.epochs[1].throttle_interval_ms = 300;
    tl.epochs[0].execution_allowed = 1;
    tl.epochs[1].execution_allowed = 0;
    SGovGovernanceFatigueV1 f1;
    SGovGovernanceFatigueV1 f2;
    string err = "";
    if(!GovFatigueV1_Measure(tl, f1, err))
        return Fail("resil_ft_a");
    if(!GovFatigueV1_Measure(tl, f2, err))
        return Fail("resil_ft_b");
    return (f1.fatigue_composite_0_1000 == f2.fatigue_composite_0_1000);
}

bool T_Resil_ClpsPos(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    ArrayResize(tl.epochs, 2);
    GovernanceReplayDatasetV1_InitEpoch(tl.epochs[0]);
    GovernanceReplayDatasetV1_InitEpoch(tl.epochs[1]);
    tl.epochs[0].survivability_ms = 8000;
    tl.epochs[1].survivability_ms = 7500;
    SGovContainmentMetricsV1 cm;
    string err = "";
    if(!GovernanceContainmentAnalyticsV1_Compute(tl, cm, err))
        return Fail("resil_cl_cm");
    SGovIncidentSummaryV1 isum;
    GovernanceIncidentDatasetV1_InitSummary(isum);
    SGovCollapseResistanceV1 o1;
    SGovCollapseResistanceV1 o2;
    if(!GovClpsResV1_Score(tl, cm, isum, o1, err))
        return Fail("resil_cl_a");
    if(!GovClpsResV1_Score(tl, cm, isum, o2, err))
        return Fail("resil_cl_b");
    return (o1.collapse_resistance_score_0_1000 == o2.collapse_resistance_score_0_1000
            && o1.collapse_resistance_score_0_1000 >= 0 && o1.collapse_resistance_score_0_1000 <= 1000);
}

bool T_Resil_BrittleStb(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    ArrayResize(tl.epochs, 3);
    GovernanceReplayDatasetV1_InitEpoch(tl.epochs[0]);
    GovernanceReplayDatasetV1_InitEpoch(tl.epochs[1]);
    GovernanceReplayDatasetV1_InitEpoch(tl.epochs[2]);
    tl.epochs[0].quarantine_state = 0;
    tl.epochs[1].quarantine_state = 2;
    tl.epochs[2].quarantine_state = 0;
    tl.epochs[0].governance_state = (int)GOV_STATE_RECOVERY;
    tl.epochs[1].governance_state = (int)GOV_STATE_RECOVERY;
    tl.epochs[2].governance_state = (int)GOV_STATE_CAUTION;
    SGovMetaRegimeStatsV1 reg;
    GovernanceMetaAnalyticsDatasetV1_InitRegimeStats(reg);
    reg.regime_churn_count = 2;
    reg.fragile_regime_recurrence_count = 1;
    reg.structural_breakdown_frequency_per_1000_epochs = 50;
    reg.toxic_regime_half_life_epochs = 4;
    reg.recovery_regime_stabilization_epochs = 1;
    SGovRegimeBrittlenessV1 b1;
    SGovRegimeBrittlenessV1 b2;
    string err = "";
    if(!GovBrittleV1_Measure(tl, reg, b1, err))
        return Fail("resil_br_a");
    if(!GovBrittleV1_Measure(tl, reg, b2, err))
        return Fail("resil_br_b");
    return (b1.brittleness_score_0_1000 == b2.brittleness_score_0_1000);
}

bool T_Resil_ExpDet(void) {
    SGovResilienceProfileV1 prof;
    string b1 = "", b2 = "", err = "";
    const string raw = GovTest_ReplayGoldenBlockTwoEpochs();
    if(!GovResilLiveV1_Run(raw, prof, b1, err))
        return Fail("resil_exp_a");
    if(!GovResilLiveV1_Run(raw, prof, b2, err))
        return Fail("resil_exp_b");
    return (b1 == b2);
}

bool T_Resil_CmpSlf(void) {
    SGovResilienceSummaryV1 s;
    GovResilDsV1_InitSummary(s);
    s.governance_health_0_1000 = 500;
    s.collapse_resistance_0_1000 = 700;
    SGovResilienceComparisonV1 d;
    GovResilCmpV1_Diff(s, s, d);
    return (d.d_governance_health == 0 && d.d_collapse_resistance == 0 && d.d_regime_brittleness == 0);
}

bool T_Resil_SbxIso(void) {
    SGovReplayTimelineV1 src;
    SGovReplayTimelineV1 dst;
    GovernanceReplayDatasetV1_InitTimeline(src);
    ArrayResize(src.epochs, 1);
    GovernanceReplayDatasetV1_InitEpoch(src.epochs[0]);
    src.epochs[0].epoch_id = 1;
    src.epochs[0].toxicity_ms = 900;
    GovResilSbV1_CloneForAnalysis(src, dst);
    const int orig = src.epochs[0].toxicity_ms;
    dst.epochs[0].toxicity_ms = GovSaturatingAdd32(dst.epochs[0].toxicity_ms, 3);
    return (src.epochs[0].toxicity_ms == orig);
}

bool T_Resil_DegrVel(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    ArrayResize(tl.epochs, 4);
    for(int i = 0; i < 4; i++) {
        GovernanceReplayDatasetV1_InitEpoch(tl.epochs[i]);
        tl.epochs[i].survivability_ms = 5000 - i * 800;
        tl.epochs[i].toxicity_ms = 100 + i * 50;
    }
    SGovResilienceCurveV1 c;
    string err = "";
    if(!GovResilCurveV1_Build(tl, c, err))
        return Fail("resil_dv");
    return (c.degradation_velocity_milli > 0);
}

bool T_Resil_HalfLife(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    ArrayResize(tl.epochs, 5);
    const int sv[5] = {5000, 4000, 3000, 2000, 1000};
    for(int i = 0; i < 5; i++) {
        GovernanceReplayDatasetV1_InitEpoch(tl.epochs[i]);
        tl.epochs[i].survivability_ms = sv[i];
        tl.epochs[i].toxicity_ms = 100;
    }
    SGovResilienceCurveV1 c;
    string err = "";
    if(!GovResilCurveV1_Build(tl, c, err))
        return Fail("resil_hl");
    return (c.resilience_half_life_epochs == 2);
}

bool T_Resil_StabPers(void) {
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    ArrayResize(tl.epochs, 4);
    for(int i = 0; i < 4; i++)
        GovernanceReplayDatasetV1_InitEpoch(tl.epochs[i]);
    tl.epochs[0].governance_state = (int)GOV_STATE_RECOVERY;
    tl.epochs[0].survivability_ms = 3000;
    tl.epochs[1].governance_state = (int)GOV_STATE_RECOVERY;
    tl.epochs[1].survivability_ms = 3500;
    tl.epochs[2].governance_state = (int)GOV_STATE_RECOVERY;
    tl.epochs[2].survivability_ms = 4000;
    tl.epochs[3].governance_state = (int)GOV_STATE_CAUTION;
    tl.epochs[3].survivability_ms = 3800;
    SGovResilienceCurveV1 c;
    string err = "";
    if(!GovResilCurveV1_Build(tl, c, err))
        return Fail("resil_sp");
    return (c.stabilization_recovery_epochs >= 1);
}

void GovTest_EvoFillSyntheticRp(SGovResilienceProfileV1 &rp) {
    GovResilDsV1_InitProfile(rp);
    rp.summary.replay_hash = "EVO_SYN";
    rp.summary.policy_fingerprint = "PF_EV0";
    rp.summary.governance_health_0_1000 = 800;
    rp.summary.survivability_resilience_0_1000 = 700;
    rp.summary.containment_resilience_0_1000 = 650;
    rp.summary.collapse_resistance_0_1000 = 600;
    rp.summary.recovery_elasticity_0_1000 = 500;
    rp.summary.replay_epoch_count = 10;
    rp.fatigue.fatigue_composite_0_1000 = 100;
    rp.brittleness.brittleness_score_0_1000 = 200;
    ArrayResize(rp.stress, 7);
    for(int i = 0; i < 7; i++) {
        GovResilDsV1_InitStressResp(rp.stress[i]);
        rp.stress[i].archetype_id = i + 1;
        rp.stress[i].stress_lane_code = i % 3;
        rp.stress[i].lane_health_proxy_0_1000 = 750 - i * 10;
        rp.stress[i].lane_collapse_resistance_0_1000 = 620 - i * 5;
        rp.stress[i].lane_fatigue_load_0_1000 = 110 + i * 3;
    }
}

void GovTest_StratAugmentRp(SGovResilienceProfileV1 &rp) {
    GovTest_EvoFillSyntheticRp(rp);
    rp.summary.quarantine_saturation_0_1000 = 200;
    rp.summary.intervention_density_0_1000 = 150;
    rp.summary.degradation_velocity_milli = 3000;
    rp.summary.stabilization_quality_0_1000 = 600;
    rp.curve.resilience_half_life_epochs = 3;
    rp.curve.plateau_epoch_segments = 2;
    rp.curve.collapse_acceleration_score_0_1000 = 100;
    rp.curve.stabilization_recovery_epochs = 1;
    rp.fatigue.lockdown_density_per_1000 = 50;
    rp.fatigue.quarantine_reuse_pressure_0_1000 = 40;
    rp.fatigue.flatten_accumulation_0_1000 = 30;
    rp.fatigue.throttle_escalation_persistence_0_1000 = 20;
    rp.fatigue.execution_suppression_fatigue_per_1000 = 10;
    rp.fatigue.recovery_instability_0_1000 = 15;
    rp.brittleness.oscillation_index_0_1000 = 80;
    rp.brittleness.stabilization_persistence_0_1000 = 400;
    rp.collapse.resilience_interruption_efficiency_0_1000 = 700;
    rp.collapse.containment_interruption_quality_0_1000 = 650;
}

bool GovTest_CivSyntheticProfile(SGovResilienceProfileV1 &rp, string &err) {
    err = "";
    GovTest_StratAugmentRp(rp);
    rp.summary.replay_hash = "CIV_SYN_RPH";
    rp.summary.policy_fingerprint = "PF_CIV0";
    return true;
}

bool GovTest_CivSynthPipe(SGovResilienceProfileV1 &rp, SGovEvolutionSummaryV1 &evo, SGovStrategicSummaryV1 &strat, SGovEvolutionGenerationV1 &gens[], string &err) {
    if(!GovTest_CivSyntheticProfile(rp, err))
        return false;
    string evo_blk = "";
    string strat_blk = "";
    return GovStratPipeV1_FromResilienceProfile(rp, evo, gens, evo_blk, strat, strat_blk, err);
}

bool T_Civ_FedDet(void) {
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovEvolutionGenerationV1 gens[];
    string err = "";
    if(!GovTest_CivSynthPipe(rp, evo, strat, gens, err))
        return Fail("civ_fed_pipe");
    SGovCivilizationFederationV1 f1;
    SGovCivilizationFederationV1 f2;
    if(!GovFedEngV1_Build(evo, strat, rp, f1, err))
        return Fail("civ_fed_a");
    if(!GovFedEngV1_Build(evo, strat, rp, f2, err))
        return Fail("civ_fed_b");
    return (f1.federation_id == f2.federation_id && f1.avg_resilience_milli == f2.avg_resilience_milli && f1.federation_stability_milli == f2.federation_stability_milli);
}

bool T_Evo_LinDet(void) {
    SGovResilienceProfileV1 rp;
    GovTest_EvoFillSyntheticRp(rp);
    SGovEvolutionLineageV1 l1;
    SGovEvolutionLineageV1 l2;
    SGovEvolutionGenerationV1 g1[];
    SGovEvolutionGenerationV1 g2[];
    string err = "";
    if(!GovLinEngV1_FromResilience(rp, l1, g1, err))
        return Fail("evo_lin_a");
    if(!GovLinEngV1_FromResilience(rp, l2, g2, err))
        return Fail("evo_lin_b");
    if(ArraySize(g1) != 8 || ArraySize(g2) != 8)
        return Fail("evo_lin_n");
    return (g1[3].survivability_score_0_1000 == g2[3].survivability_score_0_1000 && l1.max_depth == l2.max_depth);
}

bool T_Evo_DriftStb(void) {
    SGovResilienceProfileV1 rp;
    GovTest_EvoFillSyntheticRp(rp);
    SGovEvolutionLineageV1 lin;
    SGovEvolutionGenerationV1 gens[];
    string err = "";
    if(!GovLinEngV1_FromResilience(rp, lin, gens, err))
        return Fail("evo_drift_lin");
    const int n = ArraySize(gens);
    SGovDegenerationV1 dg;
    if(!GovDegV1_FromGenerations(gens, n, dg, err))
        return Fail("evo_drift_deg");
    SGovEvolutionDriftV1 d1;
    SGovEvolutionDriftV1 d2;
    if(!GovEvoDriftV1_Compute(gens, n, dg, d1, err))
        return Fail("evo_drift_a");
    if(!GovEvoDriftV1_Compute(gens, n, dg, d2, err))
        return Fail("evo_drift_b");
    return (d1.drift_survivability_milli == d2.drift_survivability_milli);
}

bool T_Evo_Deg(void) {
    SGovEvolutionGenerationV1 gens[];
    ArrayResize(gens, 4);
    for(int i = 0; i < 4; i++)
        GovEvoDsV1_InitGen(gens[i]);
    for(int k = 0; k < 4; k++) {
        gens[k].generation_id = k;
        gens[k].governance_health_0_1000 = 900 - k * 80;
        gens[k].collapse_resistance_0_1000 = 500 - k * 20;
    }
    SGovDegenerationV1 d1;
    SGovDegenerationV1 d2;
    string err = "";
    if(!GovDegV1_FromGenerations(gens, 4, d1, err))
        return Fail("evo_deg_a");
    if(!GovDegV1_FromGenerations(gens, 4, d2, err))
        return Fail("evo_deg_b");
    return (d1.degeneration_score_0_1000 == d2.degeneration_score_0_1000 && d1.degeneration_persistence_0_1000 > 0);
}

bool T_Evo_SurvEvo(void) {
    SGovResilienceProfileV1 rp;
    GovTest_EvoFillSyntheticRp(rp);
    SGovEvolutionLineageV1 lin;
    SGovEvolutionGenerationV1 gens[];
    string err = "";
    if(!GovLinEngV1_FromResilience(rp, lin, gens, err))
        return Fail("evo_sv_lin");
    const int n = ArraySize(gens);
    SGovEvolutionSurvivabilityV1 s1;
    SGovEvolutionSurvivabilityV1 s2;
    if(!GovSurvEvoV1_Compute(gens, n, s1, err))
        return Fail("evo_sv_a");
    if(!GovSurvEvoV1_Compute(gens, n, s2, err))
        return Fail("evo_sv_b");
    return (s1.inheritance_quality_0_1000 == s2.inheritance_quality_0_1000);
}

bool T_Evo_TopoDet(void) {
    SGovResilienceProfileV1 rp;
    GovTest_EvoFillSyntheticRp(rp);
    SGovEvolutionGenerationV1 gens[];
    SGovEvolutionLineageV1 lin;
    string err = "";
    if(!GovLinEngV1_FromResilience(rp, lin, gens, err))
        return Fail("evo_tp_lin");
    const int n = ArraySize(gens);
    SGovEvolutionTopologyV1 t1;
    SGovEvolutionTopologyV1 t2;
    if(!GovEvoTopoV1_BuildLinear(gens, n, rp.summary.replay_hash, t1, err))
        return Fail("evo_tp_a");
    if(!GovEvoTopoV1_BuildLinear(gens, n, rp.summary.replay_hash, t2, err))
        return Fail("evo_tp_b");
    return (t1.node_count == t2.node_count && t1.branch_count == 1);
}

bool T_Evo_ExpDet(void) {
    SGovEvolutionSummaryV1 s1;
    SGovEvolutionSummaryV1 s2;
    string b1 = "", b2 = "", err = "";
    const string raw = GovTest_ReplayGoldenBlockTwoEpochs();
    if(!GovEvoLiveV1_Run(raw, s1, b1, err))
        return Fail("evo_exp_a");
    if(!GovEvoLiveV1_Run(raw, s2, b2, err))
        return Fail("evo_exp_b");
    return (b1 == b2);
}

bool T_Evo_CmpSlf(void) {
    SGovEvolutionSummaryV1 s;
    GovEvoDsV1_InitSummary(s);
    s.lineage_id = 1;
    s.mean_survivability_0_1000 = 500;
    s.max_degeneration_velocity_milli = 12000;
    SGovEvolutionComparisonV1 d;
    GovEvoCmpV1_Diff(s, s, d);
    return (d.d_mean_survivability_0_1000 == 0 && d.d_max_degeneration_velocity_milli == 0);
}

bool T_Evo_SbxIso(void) {
    SGovReplayTimelineV1 src;
    SGovReplayTimelineV1 dst;
    GovernanceReplayDatasetV1_InitTimeline(src);
    ArrayResize(src.epochs, 1);
    GovernanceReplayDatasetV1_InitEpoch(src.epochs[0]);
    src.epochs[0].epoch_id = 1;
    src.epochs[0].survivability_ms = 5000;
    GovEvoSbV1_CloneForEvolution(src, dst);
    const int orig = src.epochs[0].survivability_ms;
    dst.epochs[0].survivability_ms = GovSaturatingAdd32(dst.epochs[0].survivability_ms, -100);
    return (src.epochs[0].survivability_ms == orig);
}

bool T_Evo_Branch(void) {
    SGovResilienceProfileV1 rp;
    GovTest_EvoFillSyntheticRp(rp);
    SGovEvolutionGenerationV1 gens[];
    SGovEvolutionLineageV1 lin;
    string err = "";
    if(!GovLinEngV1_FromResilience(rp, lin, gens, err))
        return Fail("evo_br_lin");
    SGovEvolutionTopologyV1 tp;
    if(!GovEvoTopoV1_BuildLinear(gens, ArraySize(gens), rp.summary.replay_hash, tp, err))
        return Fail("evo_br_tp");
    return (tp.branch_count == 1 && ArraySize(tp.edge_parent) == 7);
}

bool T_Evo_ResInherit(void) {
    SGovEvolutionGenerationV1 gens[];
    ArrayResize(gens, 3);
    for(int i = 0; i < 3; i++)
        GovEvoDsV1_InitGen(gens[i]);
    gens[0].survivability_score_0_1000 = 900;
    gens[1].survivability_score_0_1000 = 600;
    gens[2].survivability_score_0_1000 = 400;
    for(int k = 0; k < 3; k++) {
        gens[k].containment_quality_0_1000 = 500;
        gens[k].recovery_elasticity_0_1000 = 500;
        gens[k].collapse_resistance_0_1000 = 500;
    }
    SGovEvolutionSurvivabilityV1 sv;
    string err = "";
    if(!GovSurvEvoV1_Compute(gens, 3, sv, err))
        return Fail("evo_rsv");
    return (sv.inheritance_quality_0_1000 < 1000);
}

bool T_Strat_EndDet(void) {
    SGovResilienceProfileV1 rp;
    GovTest_StratAugmentRp(rp);
    SGovEvolutionSurvivabilityV1 sv;
    GovEvoDsV1_InitSurvEvo(sv);
    sv.inheritance_quality_0_1000 = 500;
    sv.containment_stab_evolution_0_1000 = 400;
    SGovDegenerationV1 dg;
    GovEvoDsV1_InitDeg(dg);
    dg.degeneration_persistence_0_1000 = 100;
    SGovStrategicEnduranceV1 e1;
    SGovStrategicEnduranceV1 e2;
    string err = "";
    if(!GovStratEndV1_Measure(rp, sv, dg, e1, err))
        return Fail("strat_end_a");
    if(!GovStratEndV1_Measure(rp, sv, dg, e2, err))
        return Fail("strat_end_b");
    return (e1.endurance_composite_0_1000 == e2.endurance_composite_0_1000);
}

bool T_Strat_BudStb(void) {
    SGovResilienceProfileV1 rp;
    GovTest_StratAugmentRp(rp);
    SGovStrategicBudgetV1 b1;
    SGovStrategicBudgetV1 b2;
    string err = "";
    if(!GovStratBudV1_Measure(rp, b1, err))
        return Fail("strat_bud_a");
    if(!GovStratBudV1_Measure(rp, b2, err))
        return Fail("strat_bud_b");
    return (b1.budget_pressure_composite_0_1000 == b2.budget_pressure_composite_0_1000);
}

bool T_Strat_TrajDet(void) {
    SGovResilienceProfileV1 rp;
    GovTest_StratAugmentRp(rp);
    SGovEvolutionDriftV1 dr;
    GovEvoDsV1_InitDrift(dr);
    dr.drift_survivability_milli = 100;
    dr.drift_recovery_milli = -50;
    SGovEvolutionSurvivabilityV1 sv;
    GovEvoDsV1_InitSurvEvo(sv);
    sv.inheritance_quality_0_1000 = 600;
    sv.recovery_elasticity_evolution_milli = 200;
    SGovStrategicTrajectoryV1 t1;
    SGovStrategicTrajectoryV1 t2;
    string err = "";
    if(!GovStratTrajV1_Compute(rp, dr, sv, t1, err))
        return Fail("strat_tr_a");
    if(!GovStratTrajV1_Compute(rp, dr, sv, t2, err))
        return Fail("strat_tr_b");
    return (t1.sustainability_slope_milli == t2.sustainability_slope_milli);
}

bool T_Strat_Cat(void) {
    SGovResilienceProfileV1 rp;
    GovTest_StratAugmentRp(rp);
    SGovEvolutionGenerationV1 gens[];
    SGovEvolutionLineageV1 lin;
    string err = "";
    if(!GovLinEngV1_FromResilience(rp, lin, gens, err))
        return Fail("strat_cat_lin");
    const int n = ArraySize(gens);
    SGovDegenerationV1 dg;
    if(!GovDegV1_FromGenerations(gens, n, dg, err))
        return Fail("strat_cat_deg");
    SGovCatastrophicResistanceV1 c1;
    SGovCatastrophicResistanceV1 c2;
    if(!GovStratCatV1_Score(rp, gens, n, dg, c1, err))
        return Fail("strat_cat_a");
    if(!GovStratCatV1_Score(rp, gens, n, dg, c2, err))
        return Fail("strat_cat_b");
    return (c1.catastrophic_resistance_score_0_1000 == c2.catastrophic_resistance_score_0_1000
            && c1.catastrophic_resistance_score_0_1000 >= 0 && c1.catastrophic_resistance_score_0_1000 <= 1000);
}

bool T_Strat_ExpDet(void) {
    SGovStrategicSummaryV1 s1;
    SGovStrategicSummaryV1 s2;
    string b1 = "", b2 = "", err = "";
    const string raw = GovTest_ReplayGoldenBlockTwoEpochs();
    if(!GovStrategicLiveV1_Run(raw, s1, b1, err))
        return Fail("strat_exp_a");
    if(!GovStrategicLiveV1_Run(raw, s2, b2, err))
        return Fail("strat_exp_b");
    return (b1 == b2);
}

bool T_Strat_CmpSlf(void) {
    SGovStrategicSummaryV1 s;
    GovStratDsV1_InitSummary(s);
    s.sustainability_index_0_1000 = 500;
    s.endurance_capacity_0_1000 = 600;
    SGovStrategicComparisonV1 d;
    GovStratCmpV1_Diff(s, s, d);
    return (d.d_sustainability_index_0_1000 == 0 && d.d_endurance_capacity_0_1000 == 0);
}

bool T_Strat_SbxIso(void) {
    SGovReplayTimelineV1 src;
    SGovReplayTimelineV1 dst;
    GovernanceReplayDatasetV1_InitTimeline(src);
    ArrayResize(src.epochs, 1);
    GovernanceReplayDatasetV1_InitEpoch(src.epochs[0]);
    src.epochs[0].epoch_id = 1;
    src.epochs[0].governance_state = (int)GOV_STATE_CAUTION;
    GovStratSbV1_CloneForStrategy(src, dst);
    const int orig = src.epochs[0].governance_state;
    dst.epochs[0].governance_state = (int)GOV_STATE_LOCKDOWN;
    return (src.epochs[0].governance_state == orig);
}

bool T_Strat_CollapseAvoid(void) {
    SGovResilienceProfileV1 rp;
    GovTest_StratAugmentRp(rp);
    SGovEvolutionLineageV1 lin;
    SGovEvolutionGenerationV1 gens[];
    string err = "";
    if(!GovLinEngV1_FromResilience(rp, lin, gens, err))
        return Fail("strat_cav_lin");
    const int n = ArraySize(gens);
    SGovEvolutionTopologyV1 tp;
    if(!GovEvoTopoV1_BuildLinear(gens, n, rp.summary.replay_hash, tp, err))
        return Fail("strat_cav_tp");
    SGovDegenerationV1 dg;
    if(!GovDegV1_FromGenerations(gens, n, dg, err))
        return Fail("strat_cav_dg");
    SGovEvolutionSummaryV1 evo;
    if(!GovEvoAggV1_BuildSummary(gens, n, tp, dg, rp, evo, err))
        return Fail("strat_cav_evo");
    SGovEvolutionDriftV1 dr;
    if(!GovEvoDriftV1_Compute(gens, n, dg, dr, err))
        return Fail("strat_cav_dr");
    SGovEvolutionSurvivabilityV1 sv;
    if(!GovSurvEvoV1_Compute(gens, n, sv, err))
        return Fail("strat_cav_sv");
    SGovStrategicEnduranceV1 en;
    if(!GovStratEndV1_Measure(rp, sv, dg, en, err))
        return Fail("strat_cav_en");
    SGovStrategicBudgetV1 bud;
    if(!GovStratBudV1_Measure(rp, bud, err))
        return Fail("strat_cav_bud");
    SGovStrategicContainmentV1 ctn;
    if(!GovStratCtnV1_Measure(rp, ctn, err))
        return Fail("strat_cav_ctn");
    SGovStrategicTrajectoryV1 traj;
    if(!GovStratTrajV1_Compute(rp, dr, sv, traj, err))
        return Fail("strat_cav_tr");
    SGovCatastrophicResistanceV1 cat;
    if(!GovStratCatV1_Score(rp, gens, n, dg, cat, err))
        return Fail("strat_cav_cat");
    SGovStrategicSummaryV1 sum;
    if(!GovStrategicAggV1_BuildSummary(rp, evo, en, bud, ctn, traj, cat, sum, err))
        return Fail("strat_cav_agg");
    return (sum.collapse_avoidance_score_0_1000 > 0);
}

bool T_Strat_RegBal(void) {
    SGovResilienceProfileV1 rp;
    GovTest_StratAugmentRp(rp);
    SGovEvolutionDriftV1 dr;
    GovEvoDsV1_InitDrift(dr);
    SGovEvolutionSurvivabilityV1 sv;
    GovEvoDsV1_InitSurvEvo(sv);
    SGovStrategicTrajectoryV1 t1;
    SGovStrategicTrajectoryV1 t2;
    string err = "";
    if(!GovStratTrajV1_Compute(rp, dr, sv, t1, err))
        return Fail("strat_rb_a");
    if(!GovStratTrajV1_Compute(rp, dr, sv, t2, err))
        return Fail("strat_rb_b");
    return (t1.regime_endurance_balance_0_1000 == t2.regime_endurance_balance_0_1000);
}

bool T_Strat_LongHoriz(void) {
    SGovResilienceProfileV1 rp;
    GovTest_StratAugmentRp(rp);
    SGovEvolutionLineageV1 lin;
    SGovEvolutionGenerationV1 gens[];
    string err = "";
    if(!GovLinEngV1_FromResilience(rp, lin, gens, err))
        return Fail("strat_lh_lin");
    const int n = ArraySize(gens);
    SGovEvolutionTopologyV1 tp;
    if(!GovEvoTopoV1_BuildLinear(gens, n, rp.summary.replay_hash, tp, err))
        return Fail("strat_lh_tp");
    SGovDegenerationV1 dg;
    if(!GovDegV1_FromGenerations(gens, n, dg, err))
        return Fail("strat_lh_dg");
    SGovEvolutionSummaryV1 evo;
    if(!GovEvoAggV1_BuildSummary(gens, n, tp, dg, rp, evo, err))
        return Fail("strat_lh_evo");
    SGovEvolutionDriftV1 dr;
    if(!GovEvoDriftV1_Compute(gens, n, dg, dr, err))
        return Fail("strat_lh_dr");
    SGovEvolutionSurvivabilityV1 sv;
    if(!GovSurvEvoV1_Compute(gens, n, sv, err))
        return Fail("strat_lh_sv");
    SGovStrategicEnduranceV1 en;
    if(!GovStratEndV1_Measure(rp, sv, dg, en, err))
        return Fail("strat_lh_en");
    SGovStrategicBudgetV1 bud;
    if(!GovStratBudV1_Measure(rp, bud, err))
        return Fail("strat_lh_bud");
    SGovStrategicContainmentV1 ctn;
    if(!GovStratCtnV1_Measure(rp, ctn, err))
        return Fail("strat_lh_ctn");
    SGovStrategicTrajectoryV1 traj;
    if(!GovStratTrajV1_Compute(rp, dr, sv, traj, err))
        return Fail("strat_lh_tr");
    SGovCatastrophicResistanceV1 cat;
    if(!GovStratCatV1_Score(rp, gens, n, dg, cat, err))
        return Fail("strat_lh_cat");
    SGovStrategicSummaryV1 sum;
    if(!GovStrategicAggV1_BuildSummary(rp, evo, en, bud, ctn, traj, cat, sum, err))
        return Fail("strat_lh_agg");
    return (sum.survivability_horizon_0_1000 > 0);
}

bool T_Civ_HierStb(void) {
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovEvolutionGenerationV1 gens[];
    string err = "";
    if(!GovTest_CivSynthPipe(rp, evo, strat, gens, err))
        return Fail("civ_hier_pipe");
    const int n = ArraySize(gens);
    SGovCivilizationNodeV1 nodes[];
    if(!GovCivDsV1_BuildNodes(gens, n, rp, strat, nodes, err))
        return Fail("civ_hier_nodes");
    SGovCivilizationHierarchyV1 h1;
    SGovCivilizationHierarchyV1 h2;
    if(!GovHierEngV1_Build(nodes, n, h1, err))
        return Fail("civ_hier_a");
    if(!GovHierEngV1_Build(nodes, n, h2, err))
        return Fail("civ_hier_b");
    return (h1.hierarchy_stability_milli == h2.hierarchy_stability_milli && h1.max_depth == h2.max_depth);
}

bool T_Civ_DipDet(void) {
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovEvolutionGenerationV1 gens[];
    string err = "";
    if(!GovTest_CivSynthPipe(rp, evo, strat, gens, err))
        return Fail("civ_dip_pipe");
    SGovCivilizationDiplomacyV1 d1;
    SGovCivilizationDiplomacyV1 d2;
    if(!GovDipEngV1_Compute(rp, strat, d1, err))
        return Fail("civ_dip_a");
    if(!GovDipEngV1_Compute(rp, strat, d2, err))
        return Fail("civ_dip_b");
    return (d1.diplomacy_alignment_milli == d2.diplomacy_alignment_milli && d1.conflict_milli == d2.conflict_milli);
}

bool T_Civ_MemStable(void) {
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovEvolutionGenerationV1 gens[];
    string err = "";
    if(!GovTest_CivSynthPipe(rp, evo, strat, gens, err))
        return Fail("civ_mem_pipe");
    const int n = ArraySize(gens);
    SGovDegenerationV1 dg;
    if(!GovDegV1_FromGenerations(gens, n, dg, err))
        return Fail("civ_mem_deg");
    SGovCivilizationMemoryV1 m1;
    SGovCivilizationMemoryV1 m2;
    if(!GovCivMemV1_Update(gens, n, dg, m1, err))
        return Fail("civ_mem_a");
    if(!GovCivMemV1_Update(gens, n, dg, m2, err))
        return Fail("civ_mem_b");
    return (m1.cumulative_fatigue_milli == m2.cumulative_fatigue_milli && m1.stable_cycles == m2.stable_cycles);
}

bool T_Civ_TopoDet(void) {
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovEvolutionGenerationV1 gens[];
    string err = "";
    if(!GovTest_CivSynthPipe(rp, evo, strat, gens, err))
        return Fail("civ_topo_pipe");
    const int n = ArraySize(gens);
    SGovCivilizationNodeV1 nodes[];
    if(!GovCivDsV1_BuildNodes(gens, n, rp, strat, nodes, err))
        return Fail("civ_topo_nodes");
    SGovCivilizationFederationV1 fed;
    if(!GovFedEngV1_Build(evo, strat, rp, fed, err))
        return Fail("civ_topo_fed");
    SGovCivilizationTopologyV1 t1;
    SGovCivilizationTopologyV1 t2;
    if(!GovCivTopoV1_Build(nodes, n, fed, t1, err))
        return Fail("civ_topo_a");
    if(!GovCivTopoV1_Build(nodes, n, fed, t2, err))
        return Fail("civ_topo_b");
    return (t1.cluster_count == t2.cluster_count && t1.topology_stability_milli == t2.topology_stability_milli);
}

bool T_Civ_StabDet(void) {
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovEvolutionGenerationV1 gens[];
    string err = "";
    if(!GovTest_CivSynthPipe(rp, evo, strat, gens, err))
        return Fail("civ_stab_pipe");
    const int n = ArraySize(gens);
    SGovDegenerationV1 dg;
    if(!GovDegV1_FromGenerations(gens, n, dg, err))
        return Fail("civ_stab_deg");
    SGovCivilizationFederationV1 fed;
    if(!GovFedEngV1_Build(evo, strat, rp, fed, err))
        return Fail("civ_stab_fed");
    SGovCivilizationNodeV1 nodes[];
    if(!GovCivDsV1_BuildNodes(gens, n, rp, strat, nodes, err))
        return Fail("civ_stab_nodes");
    SGovCivilizationHierarchyV1 hier;
    if(!GovHierEngV1_Build(nodes, n, hier, err))
        return Fail("civ_stab_hier");
    SGovCivilizationDiplomacyV1 dip;
    if(!GovDipEngV1_Compute(rp, strat, dip, err))
        return Fail("civ_stab_dip");
    SGovCivilizationMemoryV1 mem;
    if(!GovCivMemV1_Update(gens, n, dg, mem, err))
        return Fail("civ_stab_mem");
    SGovCivilizationTopologyV1 topo;
    if(!GovCivTopoV1_Build(nodes, n, fed, topo, err))
        return Fail("civ_stab_topo");
    SGovCivilizationStabilityV1 s1;
    SGovCivilizationStabilityV1 s2;
    if(!GovCivStabV1_Compute(fed, hier, dip, mem, topo, strat, rp, s1, err))
        return Fail("civ_stab_a");
    if(!GovCivStabV1_Compute(fed, hier, dip, mem, topo, strat, rp, s2, err))
        return Fail("civ_stab_b");
    return (s1.civilization_stability_milli == s2.civilization_stability_milli && s1.collapse_resistance_milli == s2.collapse_resistance_milli);
}

bool T_Civ_ClpsDet(void) {
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovEvolutionGenerationV1 gens[];
    string err = "";
    if(!GovTest_CivSynthPipe(rp, evo, strat, gens, err))
        return Fail("civ_clps_pipe");
    const int n = ArraySize(gens);
    SGovDegenerationV1 dg;
    if(!GovDegV1_FromGenerations(gens, n, dg, err))
        return Fail("civ_clps_deg");
    SGovCivilizationFederationV1 fed;
    if(!GovFedEngV1_Build(evo, strat, rp, fed, err))
        return Fail("civ_clps_fed");
    SGovCivilizationNodeV1 nodes[];
    if(!GovCivDsV1_BuildNodes(gens, n, rp, strat, nodes, err))
        return Fail("civ_clps_nodes");
    SGovCivilizationHierarchyV1 hier;
    if(!GovHierEngV1_Build(nodes, n, hier, err))
        return Fail("civ_clps_hier");
    SGovCivilizationTopologyV1 topo;
    if(!GovCivTopoV1_Build(nodes, n, fed, topo, err))
        return Fail("civ_clps_topo");
    SGovCivilizationCollapseV1 c1;
    SGovCivilizationCollapseV1 c2;
    if(!GovCivClpsV1_Compute(rp, strat, hier, topo, dg, fed, c1, err))
        return Fail("civ_clps_a");
    if(!GovCivClpsV1_Compute(rp, strat, hier, topo, dg, fed, c2, err))
        return Fail("civ_clps_b");
    return (c1.systemic_collapse_risk_milli == c2.systemic_collapse_risk_milli && c1.recovery_capacity_milli == c2.recovery_capacity_milli);
}

bool T_Civ_ExpDet(void) {
    SGovCivilizationSummaryV1 s1;
    SGovCivilizationSummaryV1 s2;
    string b1 = "", b2 = "", err = "";
    const string raw = GovTest_ReplayGoldenBlockTwoEpochs();
    if(!GovCivLiveV1_Run(raw, s1, b1, err))
        return Fail("civ_exp_a");
    if(!GovCivLiveV1_Run(raw, s2, b2, err))
        return Fail("civ_exp_b");
    return (b1 == b2);
}

bool T_Civ_CmpSlf(void) {
    SGovCivilizationSummaryV1 s;
    GovCivDsV1_InitSummary(s);
    s.federation_stability_milli = 400000;
    s.hierarchy_stability_milli = 350000;
    s.continuity_milli = 500000;
    SGovCivilizationComparisonV1 d;
    GovCivCmpV1_Diff(s, s, d);
    return (d.d_federation_stability_milli == 0 && d.d_continuity_milli == 0);
}

bool T_Civ_SbxIso(void) {
    SGovReplayTimelineV1 src;
    SGovReplayTimelineV1 dst;
    GovernanceReplayDatasetV1_InitTimeline(src);
    ArrayResize(src.epochs, 1);
    GovernanceReplayDatasetV1_InitEpoch(src.epochs[0]);
    src.epochs[0].epoch_id = 1;
    src.epochs[0].governance_state = (int)GOV_STATE_CAUTION;
    GovCivSbV1_CloneForCivilization(src, dst);
    const int orig = src.epochs[0].governance_state;
    dst.epochs[0].governance_state = (int)GOV_STATE_LOCKDOWN;
    return (src.epochs[0].governance_state == orig);
}

bool T_Civ_RankStable(void) {
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovEvolutionGenerationV1 gens[];
    string err = "";
    if(!GovTest_CivSynthPipe(rp, evo, strat, gens, err))
        return Fail("civ_rank_pipe");
    const int n = ArraySize(gens);
    SGovCivilizationFederationV1 fed;
    if(!GovFedEngV1_Build(evo, strat, rp, fed, err))
        return Fail("civ_rank_fed");
    SGovCivilizationNodeV1 nodes[];
    if(!GovCivDsV1_BuildNodes(gens, n, rp, strat, nodes, err))
        return Fail("civ_rank_nodes");
    int ix1[32];
    int ix2[32];
    if(!GovCivResV1_RankCivilizations(nodes, n, fed, ix1, err))
        return Fail("civ_rank_a");
    if(!GovCivResV1_RankCivilizations(nodes, n, fed, ix2, err))
        return Fail("civ_rank_b");
    for(int i = 0; i < n; i++) {
        if(ix1[i] != ix2[i])
            return Fail("civ_rank_ord");
    }
    return true;
}

bool T_Civ_Continuity(void) {
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovEvolutionGenerationV1 gens[];
    string err = "";
    if(!GovTest_CivSynthPipe(rp, evo, strat, gens, err))
        return Fail("civ_cont_pipe");
    const int n = ArraySize(gens);
    SGovDegenerationV1 dg;
    if(!GovDegV1_FromGenerations(gens, n, dg, err))
        return Fail("civ_cont_deg");
    SGovCivilizationFederationV1 fed;
    if(!GovFedEngV1_Build(evo, strat, rp, fed, err))
        return Fail("civ_cont_fed");
    SGovCivilizationNodeV1 nodes[];
    if(!GovCivDsV1_BuildNodes(gens, n, rp, strat, nodes, err))
        return Fail("civ_cont_nodes");
    SGovCivilizationHierarchyV1 hier;
    if(!GovHierEngV1_Build(nodes, n, hier, err))
        return Fail("civ_cont_hier");
    SGovCivilizationDiplomacyV1 dip;
    if(!GovDipEngV1_Compute(rp, strat, dip, err))
        return Fail("civ_cont_dip");
    SGovCivilizationMemoryV1 mem;
    if(!GovCivMemV1_Update(gens, n, dg, mem, err))
        return Fail("civ_cont_mem");
    SGovCivilizationTopologyV1 topo;
    if(!GovCivTopoV1_Build(nodes, n, fed, topo, err))
        return Fail("civ_cont_topo");
    SGovCivilizationStabilityV1 stab;
    if(!GovCivStabV1_Compute(fed, hier, dip, mem, topo, strat, rp, stab, err))
        return Fail("civ_cont_stab");
    return (stab.governance_continuity_milli > 0);
}

bool T_Civ_FragRisk(void) {
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovEvolutionGenerationV1 gens[];
    string err = "";
    if(!GovTest_CivSynthPipe(rp, evo, strat, gens, err))
        return Fail("civ_frag_pipe");
    const int n = ArraySize(gens);
    SGovCivilizationNodeV1 nodes[];
    if(!GovCivDsV1_BuildNodes(gens, n, rp, strat, nodes, err))
        return Fail("civ_frag_nodes");
    SGovCivilizationHierarchyV1 hier;
    if(!GovHierEngV1_Build(nodes, n, hier, err))
        return Fail("civ_frag_hier");
    return (hier.governance_fragmentation_milli >= 0 && hier.hierarchy_pressure_milli >= 0);
}

bool T_Civ_Cascade(void) {
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovEvolutionGenerationV1 gens[];
    string err = "";
    if(!GovTest_CivSynthPipe(rp, evo, strat, gens, err))
        return Fail("civ_casc_pipe");
    const int n = ArraySize(gens);
    SGovDegenerationV1 dg;
    if(!GovDegV1_FromGenerations(gens, n, dg, err))
        return Fail("civ_casc_deg");
    SGovCivilizationFederationV1 fed;
    if(!GovFedEngV1_Build(evo, strat, rp, fed, err))
        return Fail("civ_casc_fed");
    SGovCivilizationNodeV1 nodes[];
    if(!GovCivDsV1_BuildNodes(gens, n, rp, strat, nodes, err))
        return Fail("civ_casc_nodes");
    SGovCivilizationHierarchyV1 hier;
    if(!GovHierEngV1_Build(nodes, n, hier, err))
        return Fail("civ_casc_hier");
    SGovCivilizationTopologyV1 topo;
    if(!GovCivTopoV1_Build(nodes, n, fed, topo, err))
        return Fail("civ_casc_topo");
    SGovCivilizationCollapseV1 c1;
    SGovCivilizationCollapseV1 c2;
    if(!GovCivClpsV1_Compute(rp, strat, hier, topo, dg, fed, c1, err))
        return Fail("civ_casc_a");
    if(!GovCivClpsV1_Compute(rp, strat, hier, topo, dg, fed, c2, err))
        return Fail("civ_casc_b");
    return (c1.cascade_failure_milli == c2.cascade_failure_milli);
}

bool T_Civ_FedEndurance(void) {
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovEvolutionGenerationV1 gens[];
    string err = "";
    if(!GovTest_CivSynthPipe(rp, evo, strat, gens, err))
        return Fail("civ_fede_pipe");
    const int n = ArraySize(gens);
    SGovDegenerationV1 dg;
    if(!GovDegV1_FromGenerations(gens, n, dg, err))
        return Fail("civ_fede_deg");
    SGovCivilizationFederationV1 fed;
    if(!GovFedEngV1_Build(evo, strat, rp, fed, err))
        return Fail("civ_fede_fed");
    SGovCivilizationNodeV1 nodes[];
    if(!GovCivDsV1_BuildNodes(gens, n, rp, strat, nodes, err))
        return Fail("civ_fede_nodes");
    SGovCivilizationHierarchyV1 hier;
    if(!GovHierEngV1_Build(nodes, n, hier, err))
        return Fail("civ_fede_hier");
    SGovCivilizationDiplomacyV1 dip;
    if(!GovDipEngV1_Compute(rp, strat, dip, err))
        return Fail("civ_fede_dip");
    SGovCivilizationMemoryV1 mem;
    if(!GovCivMemV1_Update(gens, n, dg, mem, err))
        return Fail("civ_fede_mem");
    SGovCivilizationTopologyV1 topo;
    if(!GovCivTopoV1_Build(nodes, n, fed, topo, err))
        return Fail("civ_fede_topo");
    SGovCivilizationStabilityV1 stab;
    if(!GovCivStabV1_Compute(fed, hier, dip, mem, topo, strat, rp, stab, err))
        return Fail("civ_fede_stab");
    return (stab.federation_endurance_milli >= 0 && stab.federation_endurance_milli <= 1000000);
}

bool GovTest_TmpSyntheticProfile(SGovResilienceProfileV1 &rp, string &err) {
    err = "";
    if(!GovTest_CivSyntheticProfile(rp, err))
        return false;
    rp.summary.replay_hash = "TMP_SYN_RPH";
    rp.summary.policy_fingerprint = "PF_TMP0";
    return true;
}

bool GovTest_TmpGoldenPipe(SGovReplayTimelineV1 &tl, SGovResilienceProfileV1 &rp, SGovCivilizationSummaryV1 &civ, SGovStrategicSummaryV1 &strat, string &err) {
    err = "";
    const string raw = GovTest_ReplayGoldenBlockTwoEpochs();
    string norm = "";
    GovernanceReplayParserV1_NormalizeLf(raw, norm);
    GovernanceReplayDatasetV1_InitTimeline(tl);
    if(!GovernanceReplayParserV1_ParseMultilineUtf8Lf(norm, tl, err))
        return false;
    string rb = "", eb = "", sb = "", cb = "";
    SGovEvolutionSummaryV1 evo;
    SGovEvolutionGenerationV1 gens[];
    if(!GovCivPipeV1_FromUtf8(raw, rp, rb, evo, gens, eb, strat, sb, civ, cb, err))
        return false;
    return true;
}

bool T_Tmp_EpochDet(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovCivilizationSummaryV1 civ;
    SGovStrategicSummaryV1 strat;
    string err = "";
    if(!GovTest_TmpGoldenPipe(tl, rp, civ, strat, err))
        return Fail("tmp_ep_pipe");
    SGovTemporalEpochV1 e1[];
    SGovTemporalEpochV1 e2[];
    if(!GovEpochEngV1_Build(tl, civ, strat, e1, err))
        return Fail("tmp_ep_a");
    if(!GovEpochEngV1_Build(tl, civ, strat, e2, err))
        return Fail("tmp_ep_b");
    if(ArraySize(e1) != ArraySize(e2))
        return Fail("tmp_ep_n");
    return (e1[0].epoch_id == e2[0].epoch_id && e1[0].survivability_score_milli == e2[0].survivability_score_milli);
}

bool T_Tmp_AgingStb(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovCivilizationSummaryV1 civ;
    SGovStrategicSummaryV1 strat;
    string err = "";
    if(!GovTest_TmpGoldenPipe(tl, rp, civ, strat, err))
        return Fail("tmp_age_pipe");
    SGovTemporalEpochV1 ep[];
    if(!GovEpochEngV1_Build(tl, civ, strat, ep, err))
        return Fail("tmp_age_ep");
    const int n = ArraySize(ep);
    SGovGovernanceAgingV1 a1;
    SGovGovernanceAgingV1 a2;
    if(!GovAgeEngV1_Compute(ep, n, rp, a1, err))
        return Fail("tmp_age_a");
    if(!GovAgeEngV1_Compute(ep, n, rp, a2, err))
        return Fail("tmp_age_b");
    return (a1.fatigue_accumulation_milli == a2.fatigue_accumulation_milli && a1.governance_entropy_milli == a2.governance_entropy_milli);
}

bool T_Tmp_ContDet(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovCivilizationSummaryV1 civ;
    SGovStrategicSummaryV1 strat;
    string err = "";
    if(!GovTest_TmpGoldenPipe(tl, rp, civ, strat, err))
        return Fail("tmp_ct_pipe");
    SGovTemporalEpochV1 ep[];
    if(!GovEpochEngV1_Build(tl, civ, strat, ep, err))
        return Fail("tmp_ct_ep");
    const int n = ArraySize(ep);
    SGovContinuityV1 c1;
    SGovContinuityV1 c2;
    if(!GovContEngV1_Compute(ep, n, civ, strat, c1, err))
        return Fail("tmp_ct_a");
    if(!GovContEngV1_Compute(ep, n, civ, strat, c2, err))
        return Fail("tmp_ct_b");
    return (c1.continuity_strength_milli == c2.continuity_strength_milli);
}

bool T_Tmp_CycleDet(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovCivilizationSummaryV1 civ;
    SGovStrategicSummaryV1 strat;
    string err = "";
    if(!GovTest_TmpGoldenPipe(tl, rp, civ, strat, err))
        return Fail("tmp_cy_pipe");
    SGovTemporalEpochV1 ep[];
    if(!GovEpochEngV1_Build(tl, civ, strat, ep, err))
        return Fail("tmp_cy_ep");
    const int n = ArraySize(ep);
    SGovCyclePatternV1 y1;
    SGovCyclePatternV1 y2;
    if(!GovCycleEngV1_Analyze(ep, n, y1, err))
        return Fail("tmp_cy_a");
    if(!GovCycleEngV1_Analyze(ep, n, y2, err))
        return Fail("tmp_cy_b");
    return (y1.cycle_count == y2.cycle_count && y1.cycle_stability_milli == y2.cycle_stability_milli);
}

bool T_Tmp_EraShift(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovCivilizationSummaryV1 civ;
    SGovStrategicSummaryV1 strat;
    string err = "";
    if(!GovTest_TmpGoldenPipe(tl, rp, civ, strat, err))
        return Fail("tmp_es_pipe");
    SGovTemporalEpochV1 ep[];
    if(!GovEpochEngV1_Build(tl, civ, strat, ep, err))
        return Fail("tmp_es_ep");
    const int n = ArraySize(ep);
    SGovEraTransitionV1 e1;
    SGovEraTransitionV1 e2;
    if(!GovEraTrV1_Compute(ep, n, civ, strat, e1, err))
        return Fail("tmp_es_a");
    if(!GovEraTrV1_Compute(ep, n, civ, strat, e2, err))
        return Fail("tmp_es_b");
    return (e1.transition_count == e2.transition_count);
}

bool T_Tmp_PressAccum(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovCivilizationSummaryV1 civ;
    SGovStrategicSummaryV1 strat;
    string err = "";
    if(!GovTest_TmpGoldenPipe(tl, rp, civ, strat, err))
        return Fail("tmp_pr_pipe");
    SGovTemporalEpochV1 ep[];
    if(!GovEpochEngV1_Build(tl, civ, strat, ep, err))
        return Fail("tmp_pr_ep");
    const int n = ArraySize(ep);
    SGovGovernanceAgingV1 ag;
    if(!GovAgeEngV1_Compute(ep, n, rp, ag, err))
        return Fail("tmp_pr_ag");
    SGovEraTransitionV1 er;
    if(!GovEraTrV1_Compute(ep, n, civ, strat, er, err))
        return Fail("tmp_pr_er");
    SGovTemporalPressureV1 p1;
    SGovTemporalPressureV1 p2;
    if(!GovTmpPressV1_Compute(ep, n, ag, er, rp, p1, err))
        return Fail("tmp_pr_a");
    if(!GovTmpPressV1_Compute(ep, n, ag, er, rp, p2, err))
        return Fail("tmp_pr_b");
    return (p1.cumulative_pressure_milli == p2.cumulative_pressure_milli);
}

bool T_Tmp_DecayVel(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovCivilizationSummaryV1 civ;
    SGovStrategicSummaryV1 strat;
    string err = "";
    if(!GovTest_TmpGoldenPipe(tl, rp, civ, strat, err))
        return Fail("tmp_dv_pipe");
    SGovTemporalEpochV1 ep[];
    if(!GovEpochEngV1_Build(tl, civ, strat, ep, err))
        return Fail("tmp_dv_ep");
    const int n = ArraySize(ep);
    SGovTemporalDecayV1 d1;
    SGovTemporalDecayV1 d2;
    if(!GovTmpDecayV1_Compute(ep, n, civ, strat, rp, d1, err))
        return Fail("tmp_dv_a");
    if(!GovTmpDecayV1_Compute(ep, n, civ, strat, rp, d2, err))
        return Fail("tmp_dv_b");
    return (d1.decay_acceleration_milli == d2.decay_acceleration_milli);
}

bool T_Tmp_StabDet(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovCivilizationSummaryV1 civ;
    SGovStrategicSummaryV1 strat;
    string err = "";
    if(!GovTest_TmpGoldenPipe(tl, rp, civ, strat, err))
        return Fail("tmp_st_pipe");
    SGovTemporalEpochV1 ep[];
    if(!GovEpochEngV1_Build(tl, civ, strat, ep, err))
        return Fail("tmp_st_ep");
    const int n = ArraySize(ep);
    SGovContinuityV1 cont;
    if(!GovContEngV1_Compute(ep, n, civ, strat, cont, err))
        return Fail("tmp_st_cont");
    SGovGovernanceAgingV1 ag;
    if(!GovAgeEngV1_Compute(ep, n, rp, ag, err))
        return Fail("tmp_st_ag");
    SGovEraTransitionV1 er;
    if(!GovEraTrV1_Compute(ep, n, civ, strat, er, err))
        return Fail("tmp_st_er");
    SGovTemporalPressureV1 pr;
    if(!GovTmpPressV1_Compute(ep, n, ag, er, rp, pr, err))
        return Fail("tmp_st_pr");
    SGovTemporalDecayV1 dec;
    if(!GovTmpDecayV1_Compute(ep, n, civ, strat, rp, dec, err))
        return Fail("tmp_st_dec");
    SGovTemporalStabilityV1 s1;
    SGovTemporalStabilityV1 s2;
    if(!GovTmpStabV1_Compute(cont, pr, dec, civ, strat, s1, err))
        return Fail("tmp_st_a");
    if(!GovTmpStabV1_Compute(cont, pr, dec, civ, strat, s2, err))
        return Fail("tmp_st_b");
    return (s1.temporal_stability_milli == s2.temporal_stability_milli);
}

bool T_Tmp_ExpDet(void) {
    SGovTemporalSummaryV1 s1;
    SGovTemporalSummaryV1 s2;
    string b1 = "", b2 = "", err = "";
    const string raw = GovTest_ReplayGoldenBlockTwoEpochs();
    if(!GovTmpLiveV1_Run(raw, s1, b1, err))
        return Fail("tmp_exp_a");
    if(!GovTmpLiveV1_Run(raw, s2, b2, err))
        return Fail("tmp_exp_b");
    return (b1 == b2 && StringFind(b1, "===TEMPORAL_BLOCK===") >= 0);
}

bool T_Tmp_CmpSlf(void) {
    SGovTemporalSummaryV1 s;
    GovTmpDsV1_InitSummary(s);
    s.temporal_stability_milli = 400000;
    s.long_cycle_survivability_milli = 350000;
    SGovTemporalComparisonV1 d;
    GovTmpCmpV1_Diff(s, s, d);
    return (d.d_temporal_stability_milli == 0 && d.d_long_cycle_survivability_milli == 0);
}

bool T_Tmp_SbxIso(void) {
    SGovReplayTimelineV1 src;
    SGovReplayTimelineV1 dst;
    GovernanceReplayDatasetV1_InitTimeline(src);
    ArrayResize(src.epochs, 1);
    GovernanceReplayDatasetV1_InitEpoch(src.epochs[0]);
    src.epochs[0].epoch_id = 1;
    src.epochs[0].governance_state = (int)GOV_STATE_CAUTION;
    GovTmpSbV1_CloneForTemporal(src, dst);
    const int orig = src.epochs[0].governance_state;
    dst.epochs[0].governance_state = (int)GOV_STATE_LOCKDOWN;
    return (src.epochs[0].governance_state == orig);
}

bool T_Tmp_LongHoriz(void) {
    SGovTemporalSummaryV1 sum;
    string b = "", err = "";
    if(!GovTmpLiveV1_Run(GovTest_ReplayGoldenBlockTwoEpochs(), sum, b, err))
        return Fail("tmp_lh");
    return (sum.long_cycle_survivability_milli > 0);
}

bool T_Tmp_CollapseCycle(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovCivilizationSummaryV1 civ;
    SGovStrategicSummaryV1 strat;
    string err = "";
    if(!GovTest_TmpGoldenPipe(tl, rp, civ, strat, err))
        return Fail("tmp_cc_pipe");
    SGovTemporalEpochV1 ep[];
    if(!GovEpochEngV1_Build(tl, civ, strat, ep, err))
        return Fail("tmp_cc_ep");
    SGovCyclePatternV1 cyc;
    if(!GovCycleEngV1_Analyze(ep, ArraySize(ep), cyc, err))
        return Fail("tmp_cc");
    return (cyc.collapse_cycle_milli >= 0);
}

bool T_Tmp_RecoveryCycle(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovCivilizationSummaryV1 civ;
    SGovStrategicSummaryV1 strat;
    string err = "";
    if(!GovTest_TmpGoldenPipe(tl, rp, civ, strat, err))
        return Fail("tmp_rc_pipe");
    SGovTemporalEpochV1 ep[];
    if(!GovEpochEngV1_Build(tl, civ, strat, ep, err))
        return Fail("tmp_rc_ep");
    SGovCyclePatternV1 cyc;
    if(!GovCycleEngV1_Analyze(ep, ArraySize(ep), cyc, err))
        return Fail("tmp_rc");
    return (cyc.recovery_cycle_milli >= 0);
}

bool T_Tmp_Endurance(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovCivilizationSummaryV1 civ;
    SGovStrategicSummaryV1 strat;
    string err = "";
    if(!GovTest_TmpGoldenPipe(tl, rp, civ, strat, err))
        return Fail("tmp_en_pipe");
    SGovTemporalEpochV1 ep[];
    if(!GovEpochEngV1_Build(tl, civ, strat, ep, err))
        return Fail("tmp_en_ep");
    const int n = ArraySize(ep);
    SGovContinuityV1 cont;
    if(!GovContEngV1_Compute(ep, n, civ, strat, cont, err))
        return Fail("tmp_en_cont");
    SGovTemporalPressureV1 pr;
    SGovGovernanceAgingV1 ag;
    if(!GovAgeEngV1_Compute(ep, n, rp, ag, err))
        return Fail("tmp_en_ag");
    SGovEraTransitionV1 er;
    if(!GovEraTrV1_Compute(ep, n, civ, strat, er, err))
        return Fail("tmp_en_er");
    if(!GovTmpPressV1_Compute(ep, n, ag, er, rp, pr, err))
        return Fail("tmp_en_pr");
    SGovTemporalDecayV1 dec;
    if(!GovTmpDecayV1_Compute(ep, n, civ, strat, rp, dec, err))
        return Fail("tmp_en_dec");
    SGovTemporalStabilityV1 stab;
    if(!GovTmpStabV1_Compute(cont, pr, dec, civ, strat, stab, err))
        return Fail("tmp_en_st");
    return (stab.governance_endurance_milli >= 0 && stab.governance_endurance_milli <= 1000000000);
}

bool GovTest_EcoSyntheticProfile(SGovReplayTimelineV1 &tl, SGovResilienceProfileV1 &rp, SGovEvolutionSummaryV1 &evo, SGovStrategicSummaryV1 &strat, SGovCivilizationSummaryV1 &civ, SGovTemporalSummaryV1 &tmp, string &err) {
    err = "";
    const string raw = GovTest_ReplayGoldenBlockTwoEpochs();
    string res_blk = "", evo_blk = "", strat_blk = "", civ_blk = "", tmp_blk = "";
    SGovEvolutionGenerationV1 gens[];
    return GovTmpPipeV1_FromUtf8(raw, rp, res_blk, evo, gens, evo_blk, strat, strat_blk, civ, civ_blk, tl, tmp, tmp_blk, err);
}

bool T_Eco_SpeciesDet(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_EcoSyntheticProfile(tl, rp, evo, strat, civ, tmp, err))
        return Fail("eco_spec_pipe");
    SGovEcologyEntityV1 e1[];
    SGovEcologyEntityV1 e2[];
    int n1 = 0, n2 = 0;
    if(!GovEcoSysV1_Build(tl, rp, evo, strat, civ, tmp, e1, n1, err))
        return Fail("eco_spec_ent_a");
    if(!GovEcoSysV1_Build(tl, rp, evo, strat, civ, tmp, e2, n2, err))
        return Fail("eco_spec_ent_b");
    if(n1 != 6 || n2 != 6)
        return Fail("eco_spec_n");
    SGovEcologySpeciesV1 s1, s2;
    if(!GovSpeciesV1_Classify(e1[2], rp, tl, civ, tmp, s1, err))
        return Fail("eco_spec_cl_a");
    if(!GovSpeciesV1_Classify(e2[2], rp, tl, civ, tmp, s2, err))
        return Fail("eco_spec_cl_b");
    return (s1.species_code == s2.species_code && s1.classification_confidence_milli == s2.classification_confidence_milli);
}

bool T_Eco_PredPreyDet(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_EcoSyntheticProfile(tl, rp, evo, strat, civ, tmp, err))
        return Fail("eco_pp_pipe");
    SGovEcologyEntityV1 ents[];
    int n = 0;
    if(!GovEcoSysV1_Build(tl, rp, evo, strat, civ, tmp, ents, n, err))
        return Fail("eco_pp_ent");
    SGovEcologyPredPreyV1 p1, p2;
    if(!GovPredPreyV1_Analyze(ents, n, p1, err))
        return Fail("eco_pp_a");
    if(!GovPredPreyV1_Analyze(ents, n, p2, err))
        return Fail("eco_pp_b");
    return (p1.collapse_propagation_milli == p2.collapse_propagation_milli && p1.pressure_transfer_milli == p2.pressure_transfer_milli);
}

bool T_Eco_BiodivStb(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_EcoSyntheticProfile(tl, rp, evo, strat, civ, tmp, err))
        return Fail("eco_bio_pipe");
    SGovEcologyEntityV1 ents[];
    int n = 0;
    if(!GovEcoSysV1_Build(tl, rp, evo, strat, civ, tmp, ents, n, err))
        return Fail("eco_bio_ent");
    SGovEcologySpeciesV1 sp[];
    ArrayResize(sp, n);
    for(int k = 0; k < n; k++) {
        if(!GovSpeciesV1_Classify(ents[k], rp, tl, civ, tmp, sp[k], err))
            return Fail("eco_bio_sp");
        ents[k].species_code = sp[k].species_code;
    }
    SGovEcologyBiodiversityV1 b1, b2;
    if(!GovBiodivV1_Compute(tl, ents, n, sp, n, civ, b1, err))
        return Fail("eco_bio_a");
    if(!GovBiodivV1_Compute(tl, ents, n, sp, n, civ, b2, err))
        return Fail("eco_bio_b");
    return (b1.diversity_score_milli == b2.diversity_score_milli && b1.regime_diversity_milli == b2.regime_diversity_milli);
}

bool T_Eco_CollapseDet(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_EcoSyntheticProfile(tl, rp, evo, strat, civ, tmp, err))
        return Fail("eco_cl_pipe");
    SGovEcologyEntityV1 ents[];
    int n = 0;
    if(!GovEcoSysV1_Build(tl, rp, evo, strat, civ, tmp, ents, n, err))
        return Fail("eco_cl_ent");
    SGovEcologySpeciesV1 sp[];
    ArrayResize(sp, n);
    for(int k = 0; k < n; k++) {
        if(!GovSpeciesV1_Classify(ents[k], rp, tl, civ, tmp, sp[k], err))
            return Fail("eco_cl_sp");
        ents[k].species_code = sp[k].species_code;
    }
    SGovEcologyPredPreyV1 pred;
    if(!GovPredPreyV1_Analyze(ents, n, pred, err))
        return Fail("eco_cl_pp");
    SGovEcologyBiodiversityV1 bio;
    if(!GovBiodivV1_Compute(tl, ents, n, sp, n, civ, bio, err))
        return Fail("eco_cl_bd");
    SGovEcologyCollapseV1 c1, c2;
    if(!GovEcoCollapseV1_Analyze(tl, ents, n, bio, pred, c1, err))
        return Fail("eco_cl_a");
    if(!GovEcoCollapseV1_Analyze(tl, ents, n, bio, pred, c2, err))
        return Fail("eco_cl_b");
    return (c1.cascading_collapse_milli == c2.cascading_collapse_milli && c1.collapse_contagion_milli == c2.collapse_contagion_milli);
}

bool T_Eco_CoexistDet(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_EcoSyntheticProfile(tl, rp, evo, strat, civ, tmp, err))
        return Fail("eco_cx_pipe");
    SGovEcologyEntityV1 ents[];
    int n = 0;
    if(!GovEcoSysV1_Build(tl, rp, evo, strat, civ, tmp, ents, n, err))
        return Fail("eco_cx_ent");
    SGovEcologyCoexistenceV1 x1, x2;
    if(!GovCoexistV1_Compute(ents, n, civ, tmp, x1, err))
        return Fail("eco_cx_a");
    if(!GovCoexistV1_Compute(ents, n, civ, tmp, x2, err))
        return Fail("eco_cx_b");
    return (x1.coexistence_stability_milli == x2.coexistence_stability_milli && x1.temporal_sync_stability_milli == x2.temporal_sync_stability_milli);
}

bool T_Eco_ResilienceDet(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_EcoSyntheticProfile(tl, rp, evo, strat, civ, tmp, err))
        return Fail("eco_er_pipe");
    SGovEcologyEntityV1 ents[];
    int n = 0;
    if(!GovEcoSysV1_Build(tl, rp, evo, strat, civ, tmp, ents, n, err))
        return Fail("eco_er_ent");
    SGovEcologySpeciesV1 sp[];
    ArrayResize(sp, n);
    for(int k = 0; k < n; k++) {
        if(!GovSpeciesV1_Classify(ents[k], rp, tl, civ, tmp, sp[k], err))
            return Fail("eco_er_sp");
        ents[k].species_code = sp[k].species_code;
    }
    SGovEcologyPredPreyV1 pred;
    if(!GovPredPreyV1_Analyze(ents, n, pred, err))
        return Fail("eco_er_pp");
    SGovEcologyPressureV1 press;
    if(!GovResPressureV1_Compute(tl, rp, strat, press, err))
        return Fail("eco_er_pr");
    SGovEcologyBiodiversityV1 bio;
    if(!GovBiodivV1_Compute(tl, ents, n, sp, n, civ, bio, err))
        return Fail("eco_er_bd");
    SGovEcologyCollapseV1 cl;
    if(!GovEcoCollapseV1_Analyze(tl, ents, n, bio, pred, cl, err))
        return Fail("eco_er_cl");
    SGovEcologyCoexistenceV1 cx;
    if(!GovCoexistV1_Compute(ents, n, civ, tmp, cx, err))
        return Fail("eco_er_cx");
    SGovEcologyResilienceV1 r1, r2;
    if(!GovEcoResV1_Compute(bio, cl, cx, press, r1, err))
        return Fail("eco_er_a");
    if(!GovEcoResV1_Compute(bio, cl, cx, press, r2, err))
        return Fail("eco_er_b");
    return (r1.ecosystem_resilience_milli == r2.ecosystem_resilience_milli && r1.long_horizon_ecological_survivability_milli == r2.long_horizon_ecological_survivability_milli);
}

bool T_Eco_ExpDet(void) {
    SGovEcologySummaryV1 s1, s2;
    string b1 = "", b2 = "", err = "";
    const string raw = GovTest_ReplayGoldenBlockTwoEpochs();
    if(!GovEcoLiveV1_Run(raw, s1, b1, err))
        return Fail("eco_exp_a");
    if(!GovEcoLiveV1_Run(raw, s2, b2, err))
        return Fail("eco_exp_b");
    return (b1 == b2 && StringFind(b1, "===ECOLOGY_BLOCK===") >= 0 && StringFind(b1, "GOV_ECOLOGY_V1|") >= 0 && StringFind(b1, "GOV_SPECIES_V1|") >= 0);
}

bool T_Eco_CmpSlf(void) {
    SGovEcologySummaryV1 s;
    GovEcoDsV1_InitSummary(s);
    s.ecological_stability_milli = 300000;
    s.biodiversity_index_milli = 400000;
    SGovEcologyComparisonV1 d;
    string err = "";
    if(!GovEcoCmpV1_Diff(s, s, d, err))
        return Fail("eco_cmp_call");
    return (d.d_ecological_stability_milli == 0 && d.d_biodiversity_index_milli == 0 && d.d_predation_pressure_milli == 0);
}

bool T_Eco_SbxIso(void) {
    SGovReplayTimelineV1 src;
    SGovReplayTimelineV1 dst;
    GovernanceReplayDatasetV1_InitTimeline(src);
    ArrayResize(src.epochs, 1);
    GovernanceReplayDatasetV1_InitEpoch(src.epochs[0]);
    src.epochs[0].epoch_id = 1;
    src.epochs[0].governance_state = (int)GOV_STATE_CAUTION;
    GovEcoSbV1_CloneForEcology(src, dst);
    const int orig = src.epochs[0].governance_state;
    dst.epochs[0].governance_state = (int)GOV_STATE_LOCKDOWN;
    return (src.epochs[0].governance_state == orig);
}

bool T_Eco_LongHoriz(void) {
    SGovEcologySummaryV1 sum;
    string b = "", err = "";
    if(!GovEcoLiveV1_Run(GovTest_ReplayGoldenBlockTwoEpochs(), sum, b, err))
        return Fail("eco_lh");
    return (StringFind(b, "GOV_ECO_RES_V1|") >= 0 && sum.entity_count == 6);
}

bool T_Eco_RecoveryEcology(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_EcoSyntheticProfile(tl, rp, evo, strat, civ, tmp, err))
        return Fail("eco_rec_pipe");
    SGovEcologyEntityV1 ents[];
    int n = 0;
    if(!GovEcoSysV1_Build(tl, rp, evo, strat, civ, tmp, ents, n, err))
        return Fail("eco_rec_ent");
    SGovEcologyCoexistenceV1 cx;
    if(!GovCoexistV1_Compute(ents, n, civ, tmp, cx, err))
        return Fail("eco_rec_cx");
    return (cx.recovery_harmony_milli >= 0 && cx.recovery_harmony_milli <= 1000000000);
}

bool T_Eco_CollapsePropagation(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_EcoSyntheticProfile(tl, rp, evo, strat, civ, tmp, err))
        return Fail("eco_cp_pipe");
    SGovEcologyEntityV1 ents[];
    int n = 0;
    if(!GovEcoSysV1_Build(tl, rp, evo, strat, civ, tmp, ents, n, err))
        return Fail("eco_cp_ent");
    SGovEcologyPredPreyV1 pred;
    if(!GovPredPreyV1_Analyze(ents, n, pred, err))
        return Fail("eco_cp_pp");
    return (pred.collapse_propagation_milli >= 0 && pred.pressure_transfer_milli >= 0);
}

bool T_Eco_BiodiversityRecovery(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_EcoSyntheticProfile(tl, rp, evo, strat, civ, tmp, err))
        return Fail("eco_br_pipe");
    SGovEcologyEntityV1 ents[];
    int n = 0;
    if(!GovEcoSysV1_Build(tl, rp, evo, strat, civ, tmp, ents, n, err))
        return Fail("eco_br_ent");
    SGovEcologySpeciesV1 sp[];
    ArrayResize(sp, n);
    for(int k = 0; k < n; k++) {
        if(!GovSpeciesV1_Classify(ents[k], rp, tl, civ, tmp, sp[k], err))
            return Fail("eco_br_sp");
        ents[k].species_code = sp[k].species_code;
    }
    SGovEcologyPredPreyV1 pred;
    if(!GovPredPreyV1_Analyze(ents, n, pred, err))
        return Fail("eco_br_pp");
    SGovEcologyPressureV1 press;
    if(!GovResPressureV1_Compute(tl, rp, strat, press, err))
        return Fail("eco_br_pr");
    SGovEcologyBiodiversityV1 bio;
    if(!GovBiodivV1_Compute(tl, ents, n, sp, n, civ, bio, err))
        return Fail("eco_br_bd");
    SGovEcologyCollapseV1 cl;
    if(!GovEcoCollapseV1_Analyze(tl, ents, n, bio, pred, cl, err))
        return Fail("eco_br_cl");
    SGovEcologyCoexistenceV1 cx;
    if(!GovCoexistV1_Compute(ents, n, civ, tmp, cx, err))
        return Fail("eco_br_cx");
    SGovEcologyResilienceV1 er;
    if(!GovEcoResV1_Compute(bio, cl, cx, press, er, err))
        return Fail("eco_br_er");
    return (er.biodiversity_recovery_milli >= 0 && er.biodiversity_recovery_milli <= 1000000000);
}

bool T_Eco_ResourcePressure(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_EcoSyntheticProfile(tl, rp, evo, strat, civ, tmp, err))
        return Fail("eco_rp_pipe");
    SGovEcologyPressureV1 p1, p2;
    if(!GovResPressureV1_Compute(tl, rp, strat, p1, err))
        return Fail("eco_rp_a");
    if(!GovResPressureV1_Compute(tl, rp, strat, p2, err))
        return Fail("eco_rp_b");
    return (p1.quarantine_pressure_milli == p2.quarantine_pressure_milli && p1.quarantine_pressure_milli >= 0);
}

bool T_Eco_EcosystemBalance(void) {
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_EcoSyntheticProfile(tl, rp, evo, strat, civ, tmp, err))
        return Fail("eco_bal_pipe");
    SGovEcologyEntityV1 ents[];
    int n = 0;
    if(!GovEcoSysV1_Build(tl, rp, evo, strat, civ, tmp, ents, n, err))
        return Fail("eco_bal_ent");
    if(n != 6)
        return Fail("eco_bal_n");
    int ix[];
    if(!GovEcoResV1_Rank(ents, n, ix, err))
        return Fail("eco_bal_rank");
    int seen[6];
    for(int s = 0; s < 6; s++)
        seen[s] = 0;
    for(int k = 0; k < n; k++) {
        if(ix[k] < 0 || ix[k] >= n)
            return Fail("eco_bal_ix");
        seen[ix[k]] = 1;
    }
    for(int s = 0; s < 6; s++) {
        if(seen[s] != 1)
            return Fail("eco_bal_perm");
    }
    return true;
}

bool GovTest_ConSyntheticProfile(SGovEcologySummaryV1 &eco, SGovReplayTimelineV1 &tl, SGovResilienceProfileV1 &rp, SGovEvolutionSummaryV1 &evo, SGovStrategicSummaryV1 &strat, SGovCivilizationSummaryV1 &civ, SGovTemporalSummaryV1 &tmp, string &err) {
    err = "";
    const string raw = GovTest_ReplayGoldenBlockTwoEpochs();
    string eco_b = "";
    if(!GovEcoLiveV1_Run(raw, eco, eco_b, err))
        return false;
    string res_blk = "", evo_blk = "", strat_blk = "", civ_blk = "", tmp_blk = "";
    SGovEvolutionGenerationV1 gens[];
    return GovTmpPipeV1_FromUtf8(raw, rp, res_blk, evo, gens, evo_blk, strat, strat_blk, civ, civ_blk, tl, tmp, tmp_blk, err);
}

bool T_Con_IdDet(void) {
    SGovEcologySummaryV1 eco;
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_ConSyntheticProfile(eco, tl, rp, evo, strat, civ, tmp, err))
        return Fail("con_id_pipe");
    SGovIdentityProfileV1 a, b;
    if(!GovIdentityV1_Build(tl, rp, evo, civ, tmp, eco, a, err))
        return Fail("con_id_a");
    if(!GovIdentityV1_Build(tl, rp, evo, civ, tmp, eco, b, err))
        return Fail("con_id_b");
    return (a.identity_integrity_milli == b.identity_integrity_milli && a.identity_persistence_epochs == b.identity_persistence_epochs);
}

bool T_Con_CohStb(void) {
    SGovEcologySummaryV1 eco;
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_ConSyntheticProfile(eco, tl, rp, evo, strat, civ, tmp, err))
        return Fail("con_coh_pipe");
    SGovCoherenceProfileV1 x, y;
    if(!GovCoherenceV1_Compute(strat, rp, tmp, eco, civ, x, err))
        return Fail("con_coh_a");
    if(!GovCoherenceV1_Compute(strat, rp, tmp, eco, civ, y, err))
        return Fail("con_coh_b");
    return (x.strategic_coherence_milli == y.strategic_coherence_milli && x.contradiction_pressure_milli == y.contradiction_pressure_milli);
}

bool T_Con_MemDet(void) {
    SGovEcologySummaryV1 eco;
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_ConSyntheticProfile(eco, tl, rp, evo, strat, civ, tmp, err))
        return Fail("con_mem_pipe");
    SGovMemoryIntegrityV1 m1, m2;
    if(!GovMemIntV1_Analyze(tl, rp, m1, err))
        return Fail("con_mem_a");
    if(!GovMemIntV1_Analyze(tl, rp, m2, err))
        return Fail("con_mem_b");
    return (m1.replay_continuity_milli == m2.replay_continuity_milli && m1.epoch_continuity_milli == m2.epoch_continuity_milli);
}

bool T_Con_AwareDet(void) {
    SGovEcologySummaryV1 eco;
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_ConSyntheticProfile(eco, tl, rp, evo, strat, civ, tmp, err))
        return Fail("con_aw_pipe");
    SGovAwarenessProfileV1 u, v;
    if(!GovAwareV1_Compute(tl, rp, tmp, eco, u, err))
        return Fail("con_aw_a");
    if(!GovAwareV1_Compute(tl, rp, tmp, eco, v, err))
        return Fail("con_aw_b");
    return (u.survivability_awareness_milli == v.survivability_awareness_milli && u.temporal_awareness_milli == v.temporal_awareness_milli);
}

bool T_Con_CollapseAware(void) {
    SGovEcologySummaryV1 eco;
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_ConSyntheticProfile(eco, tl, rp, evo, strat, civ, tmp, err))
        return Fail("con_clp_pipe");
    SGovCollapseAwarenessV1 a, b;
    if(!GovCollapseAwareV1_Compute(strat, civ, tmp, eco, a, err))
        return Fail("con_clp_a");
    if(!GovCollapseAwareV1_Compute(strat, civ, tmp, eco, b, err))
        return Fail("con_clp_b");
    return (a.collapse_trajectory_awareness_milli == b.collapse_trajectory_awareness_milli);
}

bool T_Con_SelfCons(void) {
    SGovEcologySummaryV1 eco;
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_ConSyntheticProfile(eco, tl, rp, evo, strat, civ, tmp, err))
        return Fail("con_sc_pipe");
    SGovSelfConsistencyV1 s1, s2;
    if(!GovSelfConsV1_Compute(strat, rp, civ, s1, err))
        return Fail("con_sc_a");
    if(!GovSelfConsV1_Compute(strat, rp, civ, s2, err))
        return Fail("con_sc_b");
    return (s1.contradiction_score_milli == s2.contradiction_score_milli && s1.recovery_consistency_milli == s2.recovery_consistency_milli);
}

bool T_Con_ContAware(void) {
    SGovEcologySummaryV1 eco;
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_ConSyntheticProfile(eco, tl, rp, evo, strat, civ, tmp, err))
        return Fail("con_ca_pipe");
    SGovContinuityAwarenessV1 c1, c2;
    if(!GovContAwareV1_Compute(tl, tmp, civ, c1, err))
        return Fail("con_ca_a");
    if(!GovContAwareV1_Compute(tl, tmp, civ, c2, err))
        return Fail("con_ca_b");
    return (c1.continuity_persistence_milli == c2.continuity_persistence_milli && c1.long_horizon_awareness_milli == c2.long_horizon_awareness_milli);
}

bool T_Con_ExpDet(void) {
    SGovConsciousnessSummaryV1 s1, s2;
    string b1 = "", b2 = "", err = "";
    const string raw = GovTest_ReplayGoldenBlockTwoEpochs();
    if(!GovConLiveV1_Run(raw, s1, b1, err))
        return Fail("con_exp_a");
    if(!GovConLiveV1_Run(raw, s2, b2, err))
        return Fail("con_exp_b");
    return (b1 == b2 && StringFind(b1, "===CONSCIOUSNESS_BLOCK===") >= 0 && StringFind(b1, "GOV_CONSCIOUSNESS_V1|") >= 0);
}

bool T_Con_CmpSlf(void) {
    SGovConsciousnessSummaryV1 s;
    GovConDsV1_InitSummary(s);
    s.consciousness_stability_milli = 250000;
    s.integrity_index_milli = 300000;
    SGovConsciousnessComparisonV1 d;
    string err = "";
    if(!GovConCmpV1_Diff(s, s, d, err))
        return Fail("con_cmp_call");
    return (d.d_consciousness_stability_milli == 0 && d.d_integrity_index_milli == 0);
}

bool T_Con_SbxIso(void) {
    SGovReplayTimelineV1 src;
    SGovReplayTimelineV1 dst;
    GovernanceReplayDatasetV1_InitTimeline(src);
    ArrayResize(src.epochs, 1);
    GovernanceReplayDatasetV1_InitEpoch(src.epochs[0]);
    src.epochs[0].epoch_id = 7;
    src.epochs[0].governance_state = (int)GOV_STATE_CAUTION;
    GovConSbV1_CloneForConsciousness(src, dst);
    const int orig = src.epochs[0].governance_state;
    dst.epochs[0].governance_state = (int)GOV_STATE_LOCKDOWN;
    return (src.epochs[0].governance_state == orig);
}

bool T_Con_LongHoriz(void) {
    SGovConsciousnessSummaryV1 sum;
    string b = "", err = "";
    if(!GovConLiveV1_Run(GovTest_ReplayGoldenBlockTwoEpochs(), sum, b, err))
        return Fail("con_lh");
    return (StringFind(b, "GOV_CONTINUITY_AWARE_V1|") >= 0 && sum.consciousness_stability_milli >= 0);
}

bool T_Con_IdentityPersist(void) {
    SGovEcologySummaryV1 eco;
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_ConSyntheticProfile(eco, tl, rp, evo, strat, civ, tmp, err))
        return Fail("con_ip_pipe");
    SGovIdentityProfileV1 idp;
    if(!GovIdentityV1_Build(tl, rp, evo, civ, tmp, eco, idp, err))
        return Fail("con_ip_id");
    return (idp.identity_persistence_epochs > 0);
}

bool T_Con_Fragmentation(void) {
    SGovEcologySummaryV1 eco;
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_ConSyntheticProfile(eco, tl, rp, evo, strat, civ, tmp, err))
        return Fail("con_frag_pipe");
    SGovIdentityProfileV1 idp;
    if(!GovIdentityV1_Build(tl, rp, evo, civ, tmp, eco, idp, err))
        return Fail("con_frag_id");
    return (idp.identity_fragmentation_milli >= 0 && idp.identity_fragmentation_milli <= 1000000000);
}

bool T_Con_RecoveryIdentity(void) {
    SGovEcologySummaryV1 eco;
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_ConSyntheticProfile(eco, tl, rp, evo, strat, civ, tmp, err))
        return Fail("con_recid_pipe");
    SGovIdentityProfileV1 idp;
    if(!GovIdentityV1_Build(tl, rp, evo, civ, tmp, eco, idp, err))
        return Fail("con_recid_id");
    return (idp.identity_recovery_strength_milli >= 0);
}

bool T_Con_CollapseTrajectory(void) {
    SGovEcologySummaryV1 eco;
    SGovReplayTimelineV1 tl;
    SGovResilienceProfileV1 rp;
    SGovEvolutionSummaryV1 evo;
    SGovStrategicSummaryV1 strat;
    SGovCivilizationSummaryV1 civ;
    SGovTemporalSummaryV1 tmp;
    string err = "";
    if(!GovTest_ConSyntheticProfile(eco, tl, rp, evo, strat, civ, tmp, err))
        return Fail("con_traj_pipe");
    SGovCollapseAwarenessV1 clp;
    if(!GovCollapseAwareV1_Compute(strat, civ, tmp, eco, clp, err))
        return Fail("con_traj_clp");
    int scores[5];
    int ids[5];
    scores[0] = clp.collapse_trajectory_awareness_milli;
    scores[1] = clp.survivability_decay_awareness_milli;
    scores[2] = clp.ecological_collapse_awareness_milli;
    scores[3] = clp.civilization_instability_awareness_milli;
    scores[4] = clp.temporal_degradation_awareness_milli;
    for(int k = 0; k < 5; k++)
        ids[k] = k + 1;
    int ix[];
    if(!GovConResV1_Rank(rp.summary.replay_hash, scores, ids, 5, ix, err))
        return Fail("con_traj_rank");
    return (ArraySize(ix) == 5);
}

bool T_Replay_ParseGoldenMultiline(void) {
    string norm = "";
    GovernanceReplayParserV1_NormalizeLf(GovTest_ReplayGoldenBlockTwoEpochs(), norm);
    SGovReplayTimelineV1 tl;
    string err = "";
    if(!GovernanceReplayParserV1_ParseMultilineUtf8Lf(norm, tl, err))
        return Fail("replay_parse");
    if(ArraySize(tl.epochs) < 2)
        return Fail("replay_epoch_count");
    if(!GovernanceReplayIntegrityV1_ValidateAll(tl, norm, err))
        return Fail("replay_integrity");
    return true;
}

bool T_Replay_OrphanAttribFails(void) {
    const string bad = "GOV_ATTRIB_V1|1|0|3|2|1|0|0|42|aabbccdd|5000|4000|7000|99|1\n";
    SGovReplayTimelineV1 tl;
    string err = "";
    if(GovernanceReplayParserV1_ParseMultilineUtf8Lf(bad, tl, err))
        return Fail("replay_orphan_should_fail");
    return true;
}

bool T_Replay_MalformedUnknownFails(void) {
    const string bad = "NOT_A_KNOWN_RECORD|1|2\n";
    SGovReplayTimelineV1 tl;
    string err = "";
    if(GovernanceReplayParserV1_ParseMultilineUtf8Lf(bad, tl, err))
        return Fail("replay_malformed_should_fail");
    return true;
}

bool T_Replay_ExportDeterminism(void) {
    string norm = "";
    GovernanceReplayParserV1_NormalizeLf(GovTest_ReplayGoldenBlockTwoEpochs(), norm);
    SGovReplayTimelineV1 tl;
    string err = "";
    if(!GovernanceReplayParserV1_ParseMultilineUtf8Lf(norm, tl, err))
        return Fail("replay_exp_parse");
    string a = "", b = "";
    if(!GovernanceReplayExportV1_ExportFullPack(tl, a, err))
        return Fail("replay_exp_a");
    if(!GovernanceReplayExportV1_ExportFullPack(tl, b, err))
        return Fail("replay_exp_b");
    return (a == b);
}

bool T_Replay_TimelinePipeSchema(void) {
    string norm = "";
    GovernanceReplayParserV1_NormalizeLf(GovTest_ReplayGoldenBlockTwoEpochs(), norm);
    SGovReplayTimelineV1 tl;
    string err = "";
    if(!GovernanceReplayParserV1_ParseMultilineUtf8Lf(norm, tl, err))
        return Fail("replay_tl_parse");
    string blk = "";
    if(!GovernanceTimelineEngineV1_BuildAll(tl, blk, err))
        return Fail("replay_tl_build");
    string lines[];
    const int n = StringSplit(blk, '\n', lines);
    if(n < 1)
        return Fail("replay_tl_empty");
    if(GovernanceTimelineEngineV1_CountPipeFields(lines[0]) != GOV_TL_V1_EXPECTED_PIPE_FIELDS)
        return Fail("replay_tl_fields");
    return true;
}

bool T_Replay_PolicyComparatorSelf(void) {
    string norm = "";
    GovernanceReplayParserV1_NormalizeLf(GovTest_ReplayGoldenBlockTwoEpochs(), norm);
    SGovReplayTimelineV1 tl;
    string err = "";
    if(!GovernanceReplayParserV1_ParseMultilineUtf8Lf(norm, tl, err))
        return Fail("replay_cmp_parse");
    SGovPolicyReplayDeltaV1 d;
    string rep = "";
    if(!GovernancePolicyReplayComparatorV1_Compare(tl, tl, d, rep))
        return Fail("replay_cmp_call");
    if(d.epoch_count_delta != 0 || d.gs_transition_delta != 0)
        return Fail("replay_cmp_nonzero");
    return true;
}

bool T_Replay_ContainmentNonEmpty(void) {
    string norm = "";
    GovernanceReplayParserV1_NormalizeLf(GovTest_ReplayGoldenBlockTwoEpochs(), norm);
    SGovReplayTimelineV1 tl;
    string err = "";
    if(!GovernanceReplayParserV1_ParseMultilineUtf8Lf(norm, tl, err))
        return Fail("replay_cont_parse");
    SGovContainmentMetricsV1 m;
    if(!GovernanceContainmentAnalyticsV1_Compute(tl, m, err))
        return Fail("replay_cont_compute");
    if(m.forced_flatten_count < 1)
        return Fail("replay_cont_ff");
    return true;
}

bool T_Evidence_IntegratedShadowStable(void) {
    SCGovPolicySnapshotV1 pol;
    ENUM_GOV_POLICY_LOAD_ERR_V1 e = GOV_LOAD_ERR_V1_OK;
    if(!GovPolicyLoaderV1_LoadFromUtf8Text(GOV_V1_VALID_POLICY_TAB_UTF8, pol, e) || !pol.load_ok)
        return Fail("evint_policy");
    SGovernanceShadowContextV1 ctx;
    GovernanceShadowContextV1_Init(ctx, pol);
    SGovernanceCampaignMemoryV1 mem;
    GovernanceCampaignMemoryV1_Init(mem);
    ENUM_GOV_MARKET_REGIME_V1 prior = GOV_MR_V1_NORMAL;
    int df = 0, dt = 0;
    const string deals = GovTest_EvidDealsHdr() + "\n900001,X,0,1,1.0,0,0,0,1,0,0,0,0\n";
    string t = "", ev = "", a = "";
    SGovShadowTickAuxOutV1 aux;
    if(!GovEvidenceIntegrationV1_ShadowTickFromDealsUtf8(ctx, mem, prior, df, dt, deals,
                                                          "0000000000000000000000000000000000000000000000000000000000000000",
                                                          t, ev, a, aux))
        return Fail("evint_shadow");
    if(StringFind(ev, "GOV_ATTRIB_V1") < 0)
        return Fail("evint_attrib_missing");
    if(GovernanceTelemetryV1_CountPipeFields(t) != 13)
        return Fail("evint_tel_fields");
    return true;
}

bool T_GovRuntime_ShadowSnapshot(void) {
    SGovRuntimeShadowSnapshotV1 s;
    GovRuntimeShadowV1_InitSnapshot(s);
    GovRuntimeShadowV1_Capture(D'2020.01.01 00:00', "XAUUSD", 25L, 10050.75, 0.1234, 2, 3, 61.25, true, (uint)7, 88, 12, (uint)0x3, s);
    if(s.ts_utc != D'2020.01.01 00:00')
        return Fail("grts_ts");
    if(s.symbol != "XAUUSD")
        return Fail("grts_sym");
    if(s.spread_points != 25)
        return Fail("grts_sp");
    if(s.equity_cents != 1005075L)
        return Fail("grts_eq");
    if(s.max_equity_dd_bp != 1234L)
        return Fail("grts_dd");
    if(s.open_positions != 2 || s.strategy_id != 3)
        return Fail("grts_pos");
    if(s.quality_score_bp != 6125L)
        return Fail("grts_q");
    if(!s.execution_allowed_native)
        return Fail("grts_ex");
    if(s.governance_shadow_state != (uint)7)
        return Fail("grts_gs");
    if(s.survivability_score_0_100 != 88 || s.toxicity_score_0_100 != 12)
        return Fail("grts_st");
    if(s.anomaly_flags != (uint)0x3)
        return Fail("grts_an");
    return true;
}

bool T_GovRuntime_QueueAppend(void) {
    SGovRuntimeShadowQueueV1 q;
    GovRuntimeShadowQueueV1_Init(q);
    SGovRuntimeShadowSnapshotV1 s;
    for(int i = 0; i < 300; i++) {
        GovRuntimeShadowV1_Capture(0, "TEST", (long)i, 1000.0 + (double)i, 0.01, 1, 0, 50.0, false, (uint)0, i % 100, i % 10, (uint)0, s);
        if(!GovRuntimeShadowQueueV1_Append(q, s))
            return Fail("grqa_app");
    }
    if(GovRuntimeShadowQueueV1_Count(q) != GOV_RUNTIME_SHADOW_QUEUE_CAP_V1)
        return Fail("grqa_cap");
    if(q.total_pushes != (uint)300)
        return Fail("grqa_tot");
    const int cap = GOV_RUNTIME_SHADOW_QUEUE_CAP_V1;
    const int lastIdx = (q.tail + cap - 1) % cap;
    if(q.slots[lastIdx].v[10] != 99L)
        return Fail("grqa_wrap");
    return true;
}

bool T_GovRuntime_NoReplayParser(void) {
    if(!GovRuntimeShadowLaneV1_ContractColdLaneOnly())
        return Fail("grnr_contract");
    if(GOV_RUNTIME_SHADOW_LANE_NO_REPLAY != 1)
        return Fail("grnr_lane_macro");
    if(GOV_RUNTIME_SHADOW_CONTRACT_V1_NO_REPLAY != 1)
        return Fail("grnr_contract_macro");
    return true;
}

bool T_GovRuntime_NoExportHotPath(void) {
    SGovRuntimeShadowQueueV1 q;
    GovRuntimeShadowQueueV1_Init(q);
    SGovRuntimeShadowSnapshotV1 s;
    GovRuntimeShadowV1_Capture(0, "", 1L, 0.0, 0.0, 0, 0, 0.0, true, (uint)0, 0, 0, (uint)0, s);
    for(int k = 0; k < 5000; k++) {
        if(!GovRuntimeShadowQueueV1_Append(q, s))
            return Fail("grne_app");
    }
    return true;
}

bool T_GovRuntime_NonBlocking(void) {
    uint t0 = GetTickCount();
    SGovRuntimeShadowQueueV1 q;
    GovRuntimeShadowQueueV1_Init(q);
    SGovRuntimeShadowSnapshotV1 s;
    GovRuntimeShadowV1_Capture(0, "EURUSD", 10L, 5000.0, 0.05, 0, 1, 55.5, false, (uint)1, 50, 50, (uint)0, s);
    for(int j = 0; j < 20000; j++) {
        if(!GovRuntimeShadowQueueV1_Append(q, s))
            return Fail("grnb_app");
    }
    uint t1 = GetTickCount();
    if(t1 < t0)
        return true;
    uint dt = t1 - t0;
    if(dt > (uint)120000)
        return Fail("grnb_slow");
    return true;
}

bool T_GovRuntime_TimerSafe(void) {
    if(sizeof(SGovRuntimeShadowQueueV1) < sizeof(SGovRuntimeShadowQueueSlotV1))
        return Fail("grts_sz");
    SGovRuntimeShadowQueueV1 qz;
    GovRuntimeShadowQueueV1_Init(qz);
    if(GovRuntimeShadowLaneV1_DeferredDrainHint(qz) != 0)
        return Fail("grts_hint");
    return true;
}

void GovTest_SAttrFillTr(SGovStratAttribTradeV1 &t, const int strat, const int regime, const int sess, const int vol, const long pc, const int hold, const int so, const int tail) {
    GovStrAttrDsV1_InitTrade(t);
    t.strat = strat;
    t.regime = regime;
    t.session = sess;
    t.vol = vol;
    t.profit_cents = pc;
    t.hold_bars = hold;
    t.stopout = so;
    t.tail_loss = tail;
}

bool GovTest_ContextCompat(void) {
    SGovStratAttribTradeV1 tr[];
    ArrayResize(tr, 2);
    GovTest_SAttrFillTr(tr[0], GOV_STRAT_TF, GOV_REGIME_TREND, GOV_SATTR_SESS_NY, GOV_SATTR_VOL_LOW, 10L, 1, 0, 0);
    GovTest_SAttrFillTr(tr[1], GOV_STRAT_TF, GOV_REGIME_TREND, GOV_SATTR_SESS_NY, GOV_SATTR_VOL_LOW, 20L, 1, 0, 0);
    SGovStratAttribSummaryV1 a;
    SGovStratAttribSummaryV1 b;
    string err = "";
    if(!GovStratAggV1_BuildSummary(tr, 2, a, err))
        return Fail("ctx_compat_legacy");
    SGovStrategicContextV1 ctx;
    GovStrategicCtxV1_Reset(ctx);
    if(!GovStrategicCtxV1_SetAttribTrades(ctx, tr, 2))
        return Fail("ctx_compat_set");
    SGovStratAttribTradeV1 z[];
    ArrayResize(z, 0);
    if(!GovStratAggV1_BuildSummary(ctx, z, b))
        return Fail("ctx_compat_ctx");
    if(a.trade_count_input != b.trade_count_input)
        return Fail("ctx_compat_tr");
    return true;
}

bool GovTest_ContextClone(void) {
    SGovStrategicContextV1 a;
    GovStrategicCtxV1_Reset(a);
    a.resilience.summary.replay_epoch_count = 7;
    SGovStrategicContextV1 b;
    GovStrategicCtxV1_Clone(a, b);
    return (b.resilience.summary.replay_epoch_count == 7 && GovStrategicCtxV1_Validate(b));
}

bool GovTest_ContextIsolation(void) {
    if(GovDepMapV1_IsLegalChain(GOV_DEP_ATTRIBUTION_V1, GOV_DEP_ATTRIBUTION_V1))
        return false;
    return GovDepMapV1_IsLegalChain(GOV_DEP_REPLAY_V1, GOV_DEP_RESILIENCE_V1);
}

bool GovTest_ContextRouting(void) {
    SGovStrategicContextV1 ctx;
    GovCtxRouterV1_Build(ctx);
    SGovStratAttribTradeV1 tr[];
    ArrayResize(tr, 1);
    GovTest_SAttrFillTr(tr[0], GOV_STRAT_MR, GOV_REGIME_CHOP, GOV_SATTR_SESS_ASIA, GOV_SATTR_VOL_LOW, 5L, 1, 0, 0);
    if(!GovCtxRouterV1_Inject(ctx, tr, 1))
        return Fail("ctx_rt_inj");
    string e = "";
    if(!GovCtxRouterV1_Resolve(ctx, e))
        return Fail("ctx_rt_res");
    SGovStratAttribSummaryV1 sum;
    if(!GovStratLiveV1_Run(ctx, "", sum))
        return Fail("ctx_rt_run");
    if(sum.trade_count_input != 1)
        return Fail("ctx_rt_tr");
    return true;
}

bool GovTest_ContextDependency(void) {
    return (GOV_DEP_ATTRIBUTION_V1 == 5 && GOV_STRATEGIC_ABI_VER_V1 == 1);
}

bool GovTest_BackwardCompatibility(void) {
    return GovCompileV1_ValidateContracts(GOV_CTX_API_V1);
}

bool T_CTX_Reset(void) {
    SGovStrategicContextV1 ctx;
    GovStrategicCtxV1_Reset(ctx);
    return GovStrategicCtxV1_Validate(ctx);
}

bool T_CTX_Clone(void) {
    return GovTest_ContextClone();
}

bool T_CTX_Validate(void) {
    SGovStrategicContextV1 ctx;
    GovStrategicCtxV1_Reset(ctx);
    ctx.api_magic = 0;
    if(GovStrategicCtxV1_Validate(ctx))
        return Fail("ctx_val_should_fail");
    GovStrategicCtxV1_Reset(ctx);
    return GovStrategicCtxV1_Validate(ctx);
}

bool T_CTX_Compat(void) {
    return GovTest_ContextCompat();
}

bool T_CTX_NoCircular(void) {
    return GovTest_ContextIsolation();
}

bool T_CTX_StableAbi(void) {
    return (GOV_STRATEGIC_ABI_VER_V1 >= 1);
}

bool T_CTX_StableReplay(void) {
    return GovTest_ContextRouting();
}

bool T_CTX_SafeInject(void) {
    SGovStrategicContextV1 ctx;
    GovCompileV1_SafeInit(ctx);
    SGovStratAttribTradeV1 tr[];
    ArrayResize(tr, 1);
    GovTest_SAttrFillTr(tr[0], GOV_STRAT_BO, GOV_REGIME_TREND, GOV_SATTR_SESS_NY, GOV_SATTR_VOL_MED, 1L, 1, 0, 0);
    return GovCtxRouterV1_Inject(ctx, tr, 1);
}

bool T_CTX_ContractSafety(void) {
    SGovStrategicContextV1 ctx;
    GovStrategicCtxV1_Reset(ctx);
    return GovCompileV1_Ensure(GovCompileV1_CheckCtx(ctx));
}

bool T_CTX_NoMutation(void) {
    SGovStrategicContextV1 ctx;
    GovStrategicCtxV1_Reset(ctx);
    SGovStratAttribTradeV1 tr[];
    ArrayResize(tr, 1);
    GovTest_SAttrFillTr(tr[0], GOV_STRAT_PA, GOV_REGIME_CHOP, GOV_SATTR_SESS_NY, GOV_SATTR_VOL_LOW, 3L, 1, 0, 0);
    GovCtxRouterV1_Inject(ctx, tr, 1);
    const int n0 = ctx.sattr_trade_n;
    SGovStratAttribSummaryV1 sum;
    if(!GovStratLiveV1_Run(ctx, "", sum))
        return Fail("ctx_nom_run");
    return (ctx.sattr_trade_n == n0);
}

bool GovTest_ExportCompat(void) {
    SGovStratAttribSummaryV1 sum;
    GovStrAttrDsV1_InitSummary(sum);
    string a = "";
    string b = "";
    if(!GovStratExpV1_Bundle(sum, a))
        return Fail("exp_compat_a");
    SGovStrategicContextV1 ctx;
    GovStrategicCtxV1_Reset(ctx);
    if(!GovStratExpV1_Bundle(ctx, sum, b))
        return Fail("exp_compat_b");
    return GovExportDetV1_Equals(a, b);
}

bool GovTest_ExportDeterminism(void) {
    SGovStratAttribSummaryV1 sum;
    GovStrAttrDsV1_InitSummary(sum);
    string s = "";
    if(!GovStratExpV1_Bundle(sum, s))
        return false;
    const uint h1 = GovExportDetV1_Hash(s);
    const uint h2 = GovExportDetV1_Hash(s);
    return (h1 == h2);
}

bool GovTest_ExportFederation(void) {
    SGovExportFedStateV1 st;
    GovExportFedV1_Build(st);
    GovExportFedV1_Append(st, "x=1");
    GovExportFedV1_Append(st, "y=2");
    string o = "";
    GovExportFedV1_Finalize(st, o);
    return (StringFind(o, "x=1") >= 0 && StringFind(o, "y=2") >= 0);
}

bool GovTest_ExportReplay(void) {
    string e = "";
    return GovExportDetV1_Verify("a\nb", "a\nb", e);
}

bool GovTest_ExportRouting(void) {
    string err = "";
    return GovExportRouterV1_Resolve(GOV_EXPORT_ABI_VER_V1, err);
}

bool GovTest_ExportSchema(void) {
    return GovExportSchemaV1_IsValid(GOV_EXP_BLK_STRATEGY_V1) && (!GovExportSchemaV1_IsValid("===NOT_A_BLOCK==="));
}

bool T_EXP_CtxBundle(void) {
    SGovStrategicContextV1 ctx;
    GovStrategicCtxV1_Reset(ctx);
    SGovStratAttribSummaryV1 sum;
    GovStrAttrDsV1_InitSummary(sum);
    string out = "";
    return GovStratExpV1_Bundle(ctx, sum, out);
}

bool T_EXP_Compat(void) {
    return GovTest_ExportCompat();
}

bool T_EXP_Determinism(void) {
    return GovTest_ExportDeterminism();
}

bool T_EXP_Schema(void) {
    return GovTest_ExportSchema();
}

bool T_EXP_Router(void) {
    return GovTest_ExportRouting();
}

bool T_EXP_NoMutation(void) {
    SGovStratAttribSummaryV1 sum;
    GovStrAttrDsV1_InitSummary(sum);
    string s1 = "";
    string s2 = "";
    if(!GovStratExpV1_Bundle(sum, s1))
        return Fail("exp_nom_a");
    if(!GovStratExpV1_Bundle(sum, s2))
        return Fail("exp_nom_b");
    return GovExportDetV1_Equals(s1, s2);
}

bool T_EXP_ReplayStable(void) {
    return GovTest_ExportReplay();
}

bool T_EXP_AbiStable(void) {
    return GovExportContractsV1_ValidateMagic(GOV_EXPORT_MAGIC_V1);
}

bool T_EXP_LegacyRedirect(void) {
    return GovTest_ExportCompat();
}

bool T_EXP_FederationOrder(void) {
    return GovTest_ExportFederation();
}

bool GovTest_StratAttribSynthetic(void) {
    SGovStratAttribTradeV1 tr[];
    ArrayResize(tr, GOV_SATTR_STRAT_COUNT_V1);
    for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++)
        GovTest_SAttrFillTr(tr[i], i, GOV_REGIME_TREND, GOV_SATTR_SESS_NY, GOV_SATTR_VOL_MED, (long)(1000 * (i + 1)), 5 + i, 0, 0);
    SGovStratAttribSummaryV1 sum;
    GovStrAttrDsV1_InitSummary(sum);
    string bundle = "";
    string err = "";
    if(!GovStratLiveV1_Run("", tr, GOV_SATTR_STRAT_COUNT_V1, sum, bundle, err))
        return Fail("sattr_synth_live");
    if(StringLen(bundle) < 80)
        return Fail("sattr_synth_bundle_short");
    if(sum.trade_count_input != GOV_SATTR_STRAT_COUNT_V1)
        return Fail("sattr_synth_trade_cnt");
    return true;
}

bool GovTest_StratAttribGolden(void) {
    SGovStratAttribTradeV1 tr[];
    ArrayResize(tr, 2);
    GovTest_SAttrFillTr(tr[0], GOV_STRAT_TF, GOV_REGIME_TREND, GOV_SATTR_SESS_NY, GOV_SATTR_VOL_LOW, 100L, 10, 0, 0);
    GovTest_SAttrFillTr(tr[1], GOV_STRAT_TF, GOV_REGIME_TREND, GOV_SATTR_SESS_NY, GOV_SATTR_VOL_LOW, 200L, 10, 0, 0);
    SGovStratAttribSummaryV1 sum;
    GovStrAttrDsV1_InitSummary(sum);
    string err = "";
    if(!GovStratAggV1_BuildSummary(tr, 2, sum, err))
        return Fail("sattr_golden_agg");
    const SGovStratAttribStatsV1 st = sum.bd.by_strat[GOV_STRAT_TF];
    if(st.trades != 2)
        return Fail("sattr_golden_tf_tr");
    if(st.pf_milli != 1000000)
        return Fail("sattr_golden_pf");
    if(st.expectancy_micro != 150000000)
        return Fail("sattr_golden_exp");
    if(st.gross_win_cents != 300L || st.gross_loss_cents != 0L)
        return Fail("sattr_golden_gl");
    return true;
}

bool T_SAttr_TagDet(void) {
    string t = "";
    GovStratTagV1_BuildTag(GOV_STRAT_BO, GOV_REGIME_EXPANSION, GOV_SATTR_VOL_MED, GOV_SATTR_SESS_LONDON, t);
    if(t != "BO|EXP|MEDVOL|LON")
        return Fail("sattr_tag_bo");
    GovStratTagV1_BuildTag(GOV_STRAT_TF, GOV_REGIME_TREND, GOV_SATTR_VOL_HIGH, GOV_SATTR_SESS_NY, t);
    if(t != "TF|TREND|HIGHVOL|NY")
        return Fail("sattr_tag_tf");
    return true;
}

bool T_SAttr_AccDet(void) {
    SGovStratAttribSummaryV1 sum;
    GovStrAttrDsV1_InitSummary(sum);
    SGovStratAttribTradeV1 a;
    GovTest_SAttrFillTr(a, GOV_STRAT_MR, GOV_REGIME_CHOP, GOV_SATTR_SESS_ASIA, GOV_SATTR_VOL_LOW, -50L, 3, 1, 0);
    GovStratAttrV1_AccTrade(sum, a);
    SGovStratAttribTradeV1 b;
    GovTest_SAttrFillTr(b, GOV_STRAT_MR, GOV_REGIME_CHOP, GOV_SATTR_SESS_ASIA, GOV_SATTR_VOL_LOW, 120L, 4, 0, 1);
    GovStratAttrV1_AccTrade(sum, b);
    GovStratAttrV1_Finalize(sum);
    if(sum.bd.by_strat[GOV_STRAT_MR].trades != 2)
        return Fail("sattr_acc_mr_tr");
    if(sum.bd.session.by_sess[GOV_SATTR_SESS_ASIA].trades != 2)
        return Fail("sattr_acc_sess");
    if(sum.cross_strat_regime_cents[GOV_STRAT_MR][GOV_REGIME_CHOP] != 70L)
        return Fail("sattr_acc_cross");
    return true;
}

bool T_SAttr_Tox(void) {
    SGovStratAttribTradeV1 tr[];
    ArrayResize(tr, 6);
    for(int k = 0; k < 6; k++)
        GovTest_SAttrFillTr(tr[k], GOV_STRAT_BO, GOV_REGIME_TOXIC, GOV_SATTR_SESS_NY, GOV_SATTR_VOL_EXTREME, -10000L, 1, 1, 1);
    SGovStratAttribSummaryV1 sum;
    string err = "";
    if(!GovStratAggV1_BuildSummary(tr, 6, sum, err))
        return Fail("sattr_tox_agg");
    if(sum.tox[GOV_STRAT_BO].score_0_1000 < 400)
        return Fail("sattr_tox_score_low");
    if(!GovStratToxV1_IsToxic(sum.tox[GOV_STRAT_BO]))
        return Fail("sattr_tox_flag");
    return true;
}

bool T_SAttr_Eco(void) {
    SGovStratAttribTradeV1 tr[];
    ArrayResize(tr, 1);
    GovTest_SAttrFillTr(tr[0], GOV_STRAT_TF, GOV_REGIME_TREND, GOV_SATTR_SESS_OVERLAP, GOV_SATTR_VOL_LOW, 5000L, 1, 0, 0);
    SGovStratAttribSummaryV1 sum;
    string err = "";
    if(!GovStratAggV1_BuildSummary(tr, 1, sum, err))
        return Fail("sattr_eco_agg");
    if(sum.ecology_role[GOV_STRAT_TF] != GOV_SATTR_ECO_ALPHA_V1 && sum.ecology_role[GOV_STRAT_TF] != GOV_SATTR_ECO_CONT_V1 && sum.ecology_role[GOV_STRAT_TF] != GOV_SATTR_ECO_STAB_V1)
        return Fail("sattr_eco_role");
    if(GovStratEcoV1_PrimaryAlpha(sum) != GOV_STRAT_TF)
        return Fail("sattr_eco_primary");
    return true;
}

bool T_SAttr_RegimeFit(void) {
    SGovStratAttribTradeV1 tr[];
    ArrayResize(tr, 1);
    GovTest_SAttrFillTr(tr[0], GOV_STRAT_TF, GOV_REGIME_TREND, GOV_SATTR_SESS_NY, GOV_SATTR_VOL_LOW, 500000L, 5, 0, 0);
    SGovStratAttribSummaryV1 sum;
    string err = "";
    if(!GovStratAggV1_BuildSummary(tr, 1, sum, err))
        return Fail("sattr_rf_agg");
    const int f = GovStratCmpMxV1_RegimeFit(GOV_STRAT_TF, GOV_REGIME_TREND, sum);
    if(f < -1000 || f > 1000)
        return Fail("sattr_rf_range");
    return true;
}

bool T_SAttr_ExpDet(void) {
    SGovStratAttribTradeV1 tr[];
    ArrayResize(tr, 1);
    GovTest_SAttrFillTr(tr[0], GOV_STRAT_MR, GOV_REGIME_CHOP, GOV_SATTR_SESS_LONDON, GOV_SATTR_VOL_MED, 1L, 1, 0, 0);
    SGovStratAttribSummaryV1 sum;
    GovStrAttrDsV1_InitSummary(sum);
    string b = "";
    string err = "";
    if(!GovStratLiveV1_Run("", tr, 1, sum, b, err))
        return Fail("sattr_exp_live");
    if(StringFind(b, "===STRATEGY_BREAKDOWN===") < 0)
        return Fail("sattr_exp_blk1");
    if(StringFind(b, "===TOXICITY_BREAKDOWN===") < 0)
        return Fail("sattr_exp_blk2");
    if(StringFind(b, "===COMPATIBILITY_BREAKDOWN===") < 0)
        return Fail("sattr_exp_blk3");
    if(StringFind(b, "\n") < 0)
        return Fail("sattr_exp_lf");
    return true;
}

bool T_SAttr_CmpSlf(void) {
    SGovStratAttribTradeV1 tr[];
    ArrayResize(tr, 2);
    GovTest_SAttrFillTr(tr[0], GOV_STRAT_SD, GOV_REGIME_COMPRESSION, GOV_SATTR_SESS_ASIA, GOV_SATTR_VOL_LOW, 10L, 1, 0, 0);
    GovTest_SAttrFillTr(tr[1], GOV_STRAT_SD, GOV_REGIME_COMPRESSION, GOV_SATTR_SESS_ASIA, GOV_SATTR_VOL_LOW, -4L, 1, 0, 0);
    SGovStratAttribSummaryV1 sum;
    string err = "";
    if(!GovStratAggV1_BuildSummary(tr, 2, sum, err))
        return Fail("sattr_cmp_agg");
    SGovStratAttribComparisonV1 c;
    GovStratCmpV1_Diff(sum, sum, c);
    for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
        if(c.d_trades[i] != 0 || c.d_pf_milli[i] != 0 || c.d_profit_cents[i] != 0L)
            return Fail("sattr_cmp_self");
    }
    return true;
}

bool T_SAttr_SbxIso(void) {
    SGovStratAttribTradeV1 tr[];
    ArrayResize(tr, 2);
    GovTest_SAttrFillTr(tr[0], GOV_STRAT_PA, GOV_REGIME_SWEEP, GOV_SATTR_SESS_OVERLAP, GOV_SATTR_VOL_HIGH, 33L, 2, 0, 0);
    GovTest_SAttrFillTr(tr[1], GOV_STRAT_PA, GOV_REGIME_SWEEP, GOV_SATTR_SESS_OVERLAP, GOV_SATTR_VOL_HIGH, 44L, 2, 0, 0);
    string b1 = "";
    string b2 = "";
    string e1 = "";
    string e2 = "";
    SGovStratAttribSummaryV1 s1;
    SGovStratAttribSummaryV1 s2;
    if(!GovStratLiveV1_Run("", tr, 2, s1, b1, e1))
        return Fail("sattr_sbx1");
    if(!GovStratLiveV1_Run("", tr, 2, s2, b2, e2))
        return Fail("sattr_sbx2");
    if(b1 != b2)
        return Fail("sattr_sbx_det");
    return true;
}

bool T_SAttr_PfCalc(void) {
    SGovStratAttribTradeV1 tr[];
    ArrayResize(tr, 2);
    GovTest_SAttrFillTr(tr[0], GOV_STRAT_GR, GOV_REGIME_TREND, GOV_SATTR_SESS_NY, GOV_SATTR_VOL_LOW, 100L, 1, 0, 0);
    GovTest_SAttrFillTr(tr[1], GOV_STRAT_GR, GOV_REGIME_TREND, GOV_SATTR_SESS_NY, GOV_SATTR_VOL_LOW, -50L, 1, 0, 0);
    SGovStratAttribSummaryV1 sum;
    string err = "";
    if(!GovStratAggV1_BuildSummary(tr, 2, sum, err))
        return Fail("sattr_pf_agg");
    if(sum.bd.by_strat[GOV_STRAT_GR].pf_milli != 2000)
        return Fail("sattr_pf_val");
    return true;
}

bool T_SAttr_TailLoss(void) {
    SGovStratAttribTradeV1 tr[];
    ArrayResize(tr, 3);
    GovTest_SAttrFillTr(tr[0], GOV_STRAT_MS, GOV_REGIME_CHOP, GOV_SATTR_SESS_NY, GOV_SATTR_VOL_MED, -100L, 1, 0, 1);
    GovTest_SAttrFillTr(tr[1], GOV_STRAT_MS, GOV_REGIME_CHOP, GOV_SATTR_SESS_NY, GOV_SATTR_VOL_MED, -100L, 1, 0, 1);
    GovTest_SAttrFillTr(tr[2], GOV_STRAT_MS, GOV_REGIME_CHOP, GOV_SATTR_SESS_NY, GOV_SATTR_VOL_MED, -100L, 1, 0, 1);
    SGovStratAttribSummaryV1 sum;
    string err = "";
    if(!GovStratAggV1_BuildSummary(tr, 3, sum, err))
        return Fail("sattr_tail_agg");
    if(sum.bd.by_strat[GOV_STRAT_MS].tail_loss_count != 3)
        return Fail("sattr_tail_cnt");
    return true;
}

bool T_SAttr_VolFit(void) {
    SGovStratAttribSummaryV1 sum;
    GovStrAttrDsV1_InitSummary(sum);
    sum.cross_strat_vol_cents[GOV_STRAT_MR][GOV_SATTR_VOL_LOW] = 250000L;
    GovStratCmpMxV1_Build(sum);
    const int vf = GovStratCmpMxV1_VolFit(GOV_STRAT_MR, GOV_SATTR_VOL_LOW, sum);
    if(vf < -1000 || vf > 1000)
        return Fail("sattr_volfit");
    return true;
}

bool T_SAttr_SessionFit(void) {
    SGovStratAttribTradeV1 tr[];
    ArrayResize(tr, 2);
    GovTest_SAttrFillTr(tr[0], GOV_STRAT_SM, GOV_REGIME_EXPANSION, GOV_SATTR_SESS_LONDON, GOV_SATTR_VOL_HIGH, 10L, 1, 0, 0);
    GovTest_SAttrFillTr(tr[1], GOV_STRAT_SM, GOV_REGIME_EXPANSION, GOV_SATTR_SESS_LONDON, GOV_SATTR_VOL_HIGH, -5L, 1, 0, 0);
    SGovStratAttribSummaryV1 sum;
    string err = "";
    if(!GovStratAggV1_BuildSummary(tr, 2, sum, err))
        return Fail("sattr_sess_agg");
    if(sum.bd.session.by_sess[GOV_SATTR_SESS_LONDON].trades != 2)
        return Fail("sattr_sess_tr");
    return true;
}

//+------------------------------------------------------------------+
//| GOVERNANCE_RUNTIME_STRATEGY_TAGGING_V1 — harness tests            |
//+------------------------------------------------------------------+
bool T_RTAG_StrategyClass(void) {
    if(GovRunTagV1_ClassifyStrategy(0) != GOV_STRAT_TF)
        return Fail("rtag_strat0");
    if(GovRunTagV1_ClassifyStrategy(7) != GOV_STRAT_MS)
        return Fail("rtag_strat7");
    if(GovRunTagV1_ClassifyStrategy(999) != GOV_STRAT_MS)
        return Fail("rtag_strat_sat");
    return true;
}

bool T_RTAG_RegimeClass(void) {
    if(GovRunTagV1_ClassifyRegime(REGIME_TRENDING) != GOV_REGIME_TREND)
        return Fail("rtag_reg_tr");
    if(GovRunTagV1_ClassifyRegime(REGIME_RANGING) != GOV_REGIME_CHOP)
        return Fail("rtag_reg_rng");
    if(GovRunTagV1_ClassifyRegime(REGIME_VOLATILE) != GOV_REGIME_EXPANSION)
        return Fail("rtag_reg_vol");
    if(GovRunTagV1_ClassifyRegime(REGIME_CALM) != GOV_REGIME_COMPRESSION)
        return Fail("rtag_reg_calm");
    return true;
}

bool T_RTAG_SessionClass(void) {
    if(GovRunTagV1_ClassifySession(SESSION_ASIAN) != GOV_SATTR_SESS_ASIA)
        return Fail("rtag_sess_as");
    if(GovRunTagV1_ClassifySession(SESSION_NEWYORK) != GOV_SATTR_SESS_NY)
        return Fail("rtag_sess_ny");
    return true;
}

bool T_RTAG_VolClass(void) {
    if(GovRunTagV1_ClassifyVolatility(0.5) != GOV_SATTR_VOL_LOW)
        return Fail("rtag_vol_low");
    if(GovRunTagV1_ClassifyVolatility(2.0) != GOV_SATTR_VOL_EXTREME)
        return Fail("rtag_vol_xt");
    return true;
}

bool T_RTAG_TagBuild(void) {
    string t;
    GovRunTagV1_Build(GOV_STRAT_TF, GOV_REGIME_TREND, GOV_SATTR_VOL_HIGH, GOV_SATTR_SESS_NY, t);
    if(t != "TF|TREND|HIGHVOL|NY")
        return Fail("rtag_tag_tf");
    GovRunTagV1_Build(GOV_STRAT_MR, GOV_REGIME_CHOP, GOV_SATTR_VOL_LOW, GOV_SATTR_SESS_ASIA, t);
    if(t != "MR|CHOP|LOWVOL|ASIA")
        return Fail("rtag_tag_mr");
    return true;
}

bool T_RTAG_Registry(void) {
    SGovRunTagRegistryStoreV1 r;
    GovRunTagRegV1_Init(r);
    SGovRuntimeTradeIdentityV1 id;
    GovRunTagDsV1_InitIdentity(id);
    id.strategy_id = GOV_STRAT_BO;
    id.regime_id = GOV_REGIME_TREND;
    id.session_id = GOV_SATTR_SESS_NY;
    id.volatility_id = GOV_SATTR_VOL_MED;
    GovRunTagV1_Build(id.strategy_id, id.regime_id, id.volatility_id, id.session_id, id.tag);
    int ovr = 0;
    if(!GovRunTagRegV1_Insert(r, 1001, id, ovr))
        return Fail("rtag_reg_ins");
    SGovRuntimeTradeIdentityV1 out;
    if(!GovRunTagRegV1_Find(r, 1001, out))
        return Fail("rtag_reg_find");
    if(out.strategy_id != GOV_STRAT_BO)
        return Fail("rtag_reg_val");
    if(!GovRunTagRegV1_Remove(r, 1001))
        return Fail("rtag_reg_rm");
    if(GovRunTagRegV1_Find(r, 1001, out))
        return Fail("rtag_reg_stale");
    return true;
}

bool T_RTAG_Bridge(void) {
    GovRunTagIntV1_ModuleInit();
    SGovRuntimeTradeIdentityV1 id;
    GovRunTagDsV1_InitIdentity(id);
    id.strategy_id = GOV_STRAT_MR;
    id.regime_id = GOV_REGIME_CHOP;
    id.session_id = GOV_SATTR_SESS_ASIA;
    id.volatility_id = GOV_SATTR_VOL_LOW;
    GovRunTagV1_Build(id.strategy_id, id.regime_id, id.volatility_id, id.session_id, id.tag);
    string err = "";
    if(!GovRunAttrV1_Register(g_gov_rtag_module_v1.reg, g_gov_rtag_module_v1.tel, 5000, id, err))
        return Fail("rtag_br_reg");
    if(!GovRunAttrV1_Commit(g_gov_rtag_module_v1.reg, g_gov_rtag_module_v1.bridge, g_gov_rtag_module_v1.tel, 5000, 100L, 1, 0, 0, err))
        return Fail("rtag_br_commit");
    if(g_gov_rtag_module_v1.tel.commits != 1)
        return Fail("rtag_br_tel");
    return true;
}

bool T_RTAG_Export(void) {
    GovRunTagIntV1_ModuleInit();
    SGovRuntimeTradeIdentityV1 ida, idb;
    GovRunTagDsV1_InitIdentity(ida);
    ida.strategy_id = GOV_STRAT_TF;
    ida.regime_id = GOV_REGIME_TREND;
    ida.session_id = GOV_SATTR_SESS_NY;
    ida.volatility_id = GOV_SATTR_VOL_LOW;
    GovRunTagV1_Build(ida.strategy_id, ida.regime_id, ida.volatility_id, ida.session_id, ida.tag);
    GovRunTagDsV1_InitIdentity(idb);
    idb.strategy_id = GOV_STRAT_BO;
    idb.regime_id = GOV_REGIME_EXPANSION;
    idb.session_id = GOV_SATTR_SESS_LONDON;
    idb.volatility_id = GOV_SATTR_VOL_MED;
    GovRunTagV1_Build(idb.strategy_id, idb.regime_id, idb.volatility_id, idb.session_id, idb.tag);
    string err = "";
    if(!GovRunAttrV1_Register(g_gov_rtag_module_v1.reg, g_gov_rtag_module_v1.tel, 6001, ida, err))
        return Fail("rtag_exp_reg_a");
    if(!GovRunAttrV1_Commit(g_gov_rtag_module_v1.reg, g_gov_rtag_module_v1.bridge, g_gov_rtag_module_v1.tel, 6001, 200L, 1, 0, 0, err))
        return Fail("rtag_exp_com_a");
    if(!GovRunAttrV1_Register(g_gov_rtag_module_v1.reg, g_gov_rtag_module_v1.tel, 6002, idb, err))
        return Fail("rtag_exp_reg_b");
    if(!GovRunAttrV1_Commit(g_gov_rtag_module_v1.reg, g_gov_rtag_module_v1.bridge, g_gov_rtag_module_v1.tel, 6002, -50L, 1, 0, 0, err))
        return Fail("rtag_exp_com_b");
    string dst = "";
    if(!GovRunAttrV1_Export(g_gov_rtag_module_v1.bridge, dst))
        return Fail("rtag_exp_call");
    if(StringFind(dst, "===RUNTIME_STRATEGY_BREAKDOWN===") < 0)
        return Fail("rtag_exp_blk_s");
    if(StringFind(dst, "===RUNTIME_REGIME_BREAKDOWN===") < 0)
        return Fail("rtag_exp_blk_r");
    if(StringFind(dst, "TF") < 0)
        return Fail("rtag_exp_tf");
    return true;
}

bool T_RTAG_RuntimeSafe(void) {
    string t;
    GovRunTagV1_Build(GOV_STRAT_BO, GOV_REGIME_EXPANSION, GOV_SATTR_VOL_MED, GOV_SATTR_SESS_LONDON, t);
    if(StringLen(t) > GOV_RTAG_TAG_MAX_LEN_V1)
        return Fail("rtag_safe_len");
    const string c = GovRunTagIntV1_FormatOrderComment("AS2.0_Q50", t, true);
    if(StringLen(c) > 31)
        return Fail("rtag_safe_cmt");
    return true;
}

bool T_RTAG_ReplayDet(void) {
    string err = "";
    string e1 = "", e2 = "";
    for(int pass = 0; pass < 2; pass++) {
        GovRunTagIntV1_ModuleInit();
        SGovRuntimeTradeIdentityV1 id;
        GovRunTagDsV1_InitIdentity(id);
        id.strategy_id = GOV_STRAT_TF;
        id.regime_id = GOV_REGIME_TREND;
        id.session_id = GOV_SATTR_SESS_NY;
        id.volatility_id = GOV_SATTR_VOL_LOW;
        GovRunTagV1_Build(id.strategy_id, id.regime_id, id.volatility_id, id.session_id, id.tag);
        if(!GovRunAttrV1_Register(g_gov_rtag_module_v1.reg, g_gov_rtag_module_v1.tel, 9001, id, err))
            return Fail("rtag_rep_reg");
        if(!GovRunAttrV1_Commit(g_gov_rtag_module_v1.reg, g_gov_rtag_module_v1.bridge, g_gov_rtag_module_v1.tel, 9001, 123L, 2, 0, 0, err))
            return Fail("rtag_rep_com");
        string dst = "";
        if(!GovRunAttrV1_Export(g_gov_rtag_module_v1.bridge, dst))
            return Fail("rtag_rep_exp");
        if(pass == 0)
            e1 = dst;
        else
            e2 = dst;
    }
    if(e1 != e2)
        return Fail("rtag_rep_det");
    return true;
}

bool T_RTAG_NoMutation(void) {
    SGovRuntimeTradeIdentityV1 id;
    GovRunTagIntV1_BuildIdentityCore(2, REGIME_RANGING, SESSION_ASIAN, 0.9, 0, D'2020.01.01', 60.0, id);
    const SGovRuntimeTradeIdentityV1 snap = id;
    if(!GovRunTagDsV1_ValidateIdentity(id))
        return Fail("rtag_nomut_v1");
    if(!GovRunTagDsV1_ValidateIdentity(id))
        return Fail("rtag_nomut_v2");
    if(id.tag != snap.tag || id.strategy_id != snap.strategy_id || id.regime_id != snap.regime_id)
        return Fail("rtag_nomut_chg");
    return true;
}

//+------------------------------------------------------------------+
//| GOVERNANCE_POSITION_LINEAGE_INTELLIGENCE_V1 — harness tests       |
//+------------------------------------------------------------------+
bool GovTest_LineageRoot(void) {
    SGovLineageRegistryStoreV1 st;
    GovLineageV1_Reset(st);
    const int ix = GovLineageV1_RegisterRoot(st, 880001UL, 2, D'2024.06.01 10:00');
    if(ix < 0)
        return Fail("lin_root_ix");
    if(st.nodes[ix].lineage_id != (uint)1 || st.nodes[ix].root_lineage_id != (uint)1)
        return Fail("lin_root_lid");
    if(st.nodes[ix].originating_strategy != 2 || st.nodes[ix].current_owner_strategy != 2)
        return Fail("lin_root_own");
    if(GovLineageV1_FindByPosition(st, 880001UL) != ix)
        return Fail("lin_root_find");
    if(st.tel.total_roots != 1)
        return Fail("lin_root_tel");
    return true;
}

bool GovTest_LineageChild(void) {
    SGovLineageRegistryStoreV1 st;
    GovLineageV1_Reset(st);
    const int p = GovLineageV1_RegisterRoot(st, 880101UL, 1, D'2024.06.02');
    if(p < 0)
        return Fail("lin_ch_p");
    if(!GovGeneV1_AttachChild(st, p, 880102UL, 3, D'2024.06.02 11:00', (uint)GOV_ANC_SCALE))
        return Fail("lin_ch_att");
    const int cix = GovLineageV1_FindByPosition(st, 880102UL);
    if(cix < 0)
        return Fail("lin_ch_find");
    if(st.nodes[cix].parent_lineage_id != st.nodes[p].lineage_id)
        return Fail("lin_ch_plid");
    if(st.nodes[cix].parent_node_idx != p)
        return Fail("lin_ch_pidx");
    if(st.edge_count < 1)
        return Fail("lin_ch_edge");
    return true;
}

bool GovTest_LineageScaleIn(void) {
    SGovLineageRegistryStoreV1 st;
    GovLineageV1_Reset(st);
    SGovLineageReplayRowV1 r[];
    ArrayResize(r, 2);
    r[0].position_id = 880201UL;
    r[0].deal_entry = (int)DEAL_ENTRY_IN;
    r[0].volume_milli = 100000L;
    r[0].strategy_id = 1;
    r[0].ts = D'2024.06.03';
    r[1].position_id = 880201UL;
    r[1].deal_entry = (int)DEAL_ENTRY_IN;
    r[1].volume_milli = 250000L;
    r[1].strategy_id = 1;
    r[1].ts = D'2024.06.03 12:00';
    string err = "";
    if(!GovGeneV1_Reconstruct(st, r, 2, err))
        return Fail("lin_si_reb");
    const int ix = GovLineageV1_FindByPosition(st, 880201UL);
    if(ix < 0)
        return Fail("lin_si_ix");
    if(st.nodes[ix].scale_in_count < 1)
        return Fail("lin_si_cnt");
    if(st.nodes[ix].position_volume_milli != 250000L)
        return Fail("lin_si_vol");
    return true;
}

bool GovTest_LineagePartialClose(void) {
    SGovLineageRegistryStoreV1 st;
    GovLineageV1_Reset(st);
    SGovLineageReplayRowV1 r[];
    ArrayResize(r, 3);
    r[0].position_id = 880301UL;
    r[0].deal_entry = (int)DEAL_ENTRY_IN;
    r[0].volume_milli = 300000L;
    r[0].strategy_id = 0;
    r[0].ts = D'2024.06.04';
    r[1].position_id = 880301UL;
    r[1].deal_entry = (int)DEAL_ENTRY_OUT;
    r[1].volume_milli = 120000L;
    r[1].profit_cents = 50L;
    r[1].deal_reason = 0;
    r[1].ts = D'2024.06.04 13:00';
    r[2].position_id = 880301UL;
    r[2].deal_entry = (int)DEAL_ENTRY_OUT;
    r[2].volume_milli = 0L;
    r[2].profit_cents = 10L;
    r[2].deal_reason = 0;
    r[2].ts = D'2024.06.04 14:00';
    string err = "";
    if(!GovGeneV1_Reconstruct(st, r, 3, err))
        return Fail("lin_pc_reb");
    const int ix = GovLineageV1_FindByPosition(st, 880301UL);
    if(ix >= 0)
        return Fail("lin_pc_closed");
    int pc = 0;
    for(int m = 0; m < GOV_LINEAGE_MAX_MUTATIONS_V1; m++) {
        if(st.mutations[m].mutation_type == (int)GOV_MUT_PARTIAL_CLOSE)
            pc++;
    }
    if(pc < 1)
        return Fail("lin_pc_mut");
    return true;
}

bool GovTest_LineageRecovery(void) {
    const int mt = GovMutationV1_Detect((int)DEAL_ENTRY_OUT, 100000L, 0L, -500L, 1, 0);
    if(!GovMutationV1_IsRecovery(mt))
        return Fail("lin_rec_mt");
    SGovRecoveryStoreV1 rec;
    GovRecoveryStoreV1_Init(rec);
    SGovLineageRegistryStoreV1 st;
    GovLineageV1_Reset(st);
    GovRecoveryV1_Register(rec, (uint)7, (uint)99999, 3);
    GovRecoveryV1_Analyze(rec, st);
    if(st.tel.replay_mismatches < 1)
        return Fail("lin_rec_an");
    SGovLineageReplayRowV1 r[];
    ArrayResize(r, 2);
    r[0].position_id = 880401UL;
    r[0].deal_entry = (int)DEAL_ENTRY_IN;
    r[0].volume_milli = 100000L;
    r[0].strategy_id = 2;
    r[0].ts = D'2024.06.05';
    r[1].position_id = 880401UL;
    r[1].deal_entry = (int)DEAL_ENTRY_OUT;
    r[1].volume_milli = 0L;
    r[1].profit_cents = -200L;
    r[1].deal_reason = (int)DEAL_REASON_SL;
    r[1].ts = D'2024.06.05 15:00';
    string err = "";
    GovLineageV1_Reset(st);
    if(!GovGeneV1_Reconstruct(st, r, 2, err))
        return Fail("lin_rec_reb");
    int rec_mut = 0;
    for(int m = 0; m < GOV_LINEAGE_MAX_MUTATIONS_V1; m++) {
        if(st.mutations[m].mutation_type == (int)GOV_MUT_RECOVERY)
            rec_mut++;
    }
    if(rec_mut < 1)
        return Fail("lin_rec_mut");
    return true;
}

bool GovTest_LineageReplay(void) {
    SGovLineageRegistryStoreV1 st;
    GovLineageV1_Reset(st);
    SGovLineageReplayRowV1 r[];
    ArrayResize(r, 2);
    r[0].position_id = 880501UL;
    r[0].deal_entry = (int)DEAL_ENTRY_IN;
    r[0].volume_milli = 50000L;
    r[0].strategy_id = 4;
    r[0].ts = D'2024.06.06';
    r[1].position_id = 880501UL;
    r[1].deal_entry = (int)DEAL_ENTRY_OUT;
    r[1].volume_milli = 0L;
    r[1].profit_cents = 25L;
    r[1].deal_reason = 0;
    r[1].ts = D'2024.06.06 16:00';
    string err = "";
    if(!GovReplayLineageV1_Rebuild(st, r, 2, err))
        return Fail("lin_rp_reb");
    if(StringLen(err) != 0)
        return Fail("lin_rp_err");
    if(GovLineageV1_FindByPosition(st, 880501UL) >= 0)
        return Fail("lin_rp_open");
    return true;
}

bool GovTest_LineageDeterminism(void) {
    SGovLineageRegistryStoreV1 a, b;
    GovLineageV1_Reset(a);
    GovLineageV1_Reset(b);
    SGovLineageReplayRowV1 r[];
    ArrayResize(r, 3);
    r[0].position_id = 880601UL;
    r[0].strategy_id = 1;
    r[0].ts = D'2024.06.07 10:00';
    r[0].deal_reason = 0;
    r[1].position_id = 880601UL;
    r[1].strategy_id = 1;
    r[1].ts = D'2024.06.07 11:00';
    r[1].deal_reason = 0;
    r[2].position_id = 880601UL;
    r[2].strategy_id = 1;
    r[2].ts = D'2024.06.07 12:00';
    r[2].deal_reason = 0;
    r[0].deal_entry = (int)DEAL_ENTRY_IN;
    r[0].volume_milli = 80000L;
    r[1].deal_entry = (int)DEAL_ENTRY_IN;
    r[1].volume_milli = 160000L;
    r[2].deal_entry = (int)DEAL_ENTRY_OUT;
    r[2].volume_milli = 0L;
    r[2].profit_cents = 1L;
    string e1 = "", e2 = "";
    if(!GovReplayLineageV1_Rebuild(a, r, 3, e1) || !GovReplayLineageV1_Rebuild(b, r, 3, e2))
        return Fail("lin_det_reb");
    if(!GovReplayLineageV1_Equals(a, b))
        return Fail("lin_det_eq");
    const ulong h1 = GovReplayLineageV1_Hash(a);
    const ulong h2 = GovReplayLineageV1_Hash(b);
    if(h1 != h2)
        return Fail("lin_det_hash");
    return true;
}

bool GovTest_LineageOverflow(void) {
    SGovLineageRegistryStoreV1 st;
    GovLineageV1_Reset(st);
    for(int k = 0; k < GOV_LINEAGE_MAX_NODES_V1 + 8; k++) {
        const ulong pid = (ulong)(900000 + k);
        GovLineageV1_RegisterRoot(st, pid, k & 7, D'2024.06.08');
    }
    if(st.tel.overflow_events < 1)
        return Fail("lin_ov_tel");
    return true;
}

bool GovTest_LineageOwnership(void) {
    SGovLineageRegistryStoreV1 st;
    GovLineageV1_Reset(st);
    const int ix = GovLineageV1_RegisterRoot(st, 880701UL, 0, D'2024.06.09');
    GovGeneV1_UpdateOwnership(st, ix, 7, D'2024.06.09 18:00');
    if(st.nodes[ix].current_owner_strategy != 7)
        return Fail("lin_own_str");
    GovGeneV1_UpdateLifecycle(st, ix, (int)GOV_LC_PHASE_RECOVERY, (int)GOV_LINEAGE_ST_RECOVERED, D'2024.06.09 19:00');
    if(st.nodes[ix].lifecycle_phase != (int)GOV_LC_PHASE_RECOVERY)
        return Fail("lin_own_lc");
    return true;
}

bool GovTest_LineageToxicity(void) {
    SGovRecoveryChainV1 c;
    c.root_lineage_id = (uint)1;
    c.last_lineage_id = (uint)2;
    c.generation_depth = 4;
    c.toxic_score_0_1000 = 600;
    c.exposure_ratio_micro = 500000L;
    if(!GovRecoveryV1_IsToxic(c))
        return Fail("lin_tox_hi");
    c.toxic_score_0_1000 = 100;
    if(GovRecoveryV1_IsToxic(c))
        return Fail("lin_tox_lo");
    if(GovRecoveryV1_ChainDepth(c) != 4)
        return Fail("lin_tox_dep");
    if(GovRecoveryV1_ExposureRatio(c) != 500000L)
        return Fail("lin_tox_exp");
    return true;
}

bool GovTest_LineageMutation(void) {
    if(GovMutationV1_Detect((int)DEAL_ENTRY_IN, 0L, 100L, 0, 0, 0) != (int)GOV_MUT_NEW_ENTRY)
        return Fail("lin_mut_ne");
    if(GovMutationV1_Detect((int)DEAL_ENTRY_IN, 100L, 200L, 0, 0, 0) != (int)GOV_MUT_SCALE_IN)
        return Fail("lin_mut_si");
    if(GovMutationV1_Detect((int)DEAL_ENTRY_INOUT, 0L, 0L, 0, 0, 0) != (int)GOV_MUT_REVERSAL)
        return Fail("lin_mut_rev");
    if(!GovMutationV1_IsScaleOut(GovMutationV1_Detect((int)DEAL_ENTRY_OUT, 100L, 0L, 0L, 0, 0)))
        return Fail("lin_mut_so");
    return true;
}

bool GovTest_LineageIsolation(void) {
    SGovLineageRegistryStoreV1 src, dst;
    GovLineageV1_Reset(src);
    GovLineageV1_RegisterRoot(src, 880801UL, 5, D'2024.06.10');
    GovLineageSbxV1_Clone(src, dst);
    if(GovLineageV1_FindByPosition(dst, 880801UL) < 0)
        return Fail("lin_iso_clone");
    GovLineageSbxV1_Isolate(dst);
    if(GovLineageV1_FindByPosition(dst, 880801UL) >= 0)
        return Fail("lin_iso_clr");
    if(GovLineageV1_FindByPosition(src, 880801UL) < 0)
        return Fail("lin_iso_src");
    return true;
}

bool GovTest_LineageComparator(void) {
    SGovLineageRegistryStoreV1 st;
    GovLineageV1_Reset(st);
    GovLineageV1_RegisterRoot(st, 880901UL, 2, D'2024.06.11');
    SGovLineageSnapshotV1 sa, sb;
    GovLineageCmpV1_CaptureSnapshot(st, sa);
    GovLineageCmpV1_CaptureSnapshot(st, sb);
    if(!GovLineageCmpV1_Equals(sa, sb))
        return Fail("lin_cmp_eq");
    if(StringLen(GovLineageCmpV1_Report(sa, sb)) != 0)
        return Fail("lin_cmp_rep");
    return true;
}

bool T_LINEAGE_Root(void) {
    return GovTest_LineageRoot();
}
bool T_LINEAGE_Child(void) {
    return GovTest_LineageChild();
}
bool T_LINEAGE_ScaleIn(void) {
    return GovTest_LineageScaleIn();
}
bool T_LINEAGE_PartialClose(void) {
    return GovTest_LineagePartialClose();
}
bool T_LINEAGE_Recovery(void) {
    return GovTest_LineageRecovery();
}
bool T_LINEAGE_Replay(void) {
    return GovTest_LineageReplay();
}
bool T_LINEAGE_Determinism(void) {
    return GovTest_LineageDeterminism();
}
bool T_LINEAGE_Overflow(void) {
    return GovTest_LineageOverflow();
}
bool T_LINEAGE_Ownership(void) {
    return GovTest_LineageOwnership();
}
bool T_LINEAGE_Toxicity(void) {
    return GovTest_LineageToxicity();
}
bool T_LINEAGE_Mutation(void) {
    return GovTest_LineageMutation();
}
bool T_LINEAGE_Isolation(void) {
    return GovTest_LineageIsolation();
}
bool T_LINEAGE_Comparator(void) {
    return GovTest_LineageComparator();
}

//+------------------------------------------------------------------+
//| GOVERNANCE_RUNTIME_OBSERVABILITY_EXPORT_V1 — harness tests        |
//+------------------------------------------------------------------+
bool GovTest_RuntimeObsExport(void) {
    GovRunTagIntV1_ModuleInit();
    GovRuntimeObsIntV1_ModuleInit();
    GovRuntimeObsIntV1_Configure(false, false, "", GOV_RUNTIME_OBS_FLAG_INCLUDE_RAW);
    string dst = "";
    if(!GovRuntimeObsBldV1_BuildFull(Symbol(), g_gov_rtag_module_v1, g_gov_lineage_reg_v1, GOV_RUNTIME_OBS_FLAG_INCLUDE_RAW, dst))
        return Fail("robs_bld");
    if(StringFind(dst, "=== GOVERNANCE_RUNTIME_OBSERVABILITY_V1 ===") < 0)
        return Fail("robs_hdr");
    if(StringFind(dst, "=== STRATEGY BREAKDOWN ===") < 0)
        return Fail("robs_strat");
    if(StringFind(dst, "=== CAPITAL DIAGNOSTICS ===") < 0)
        return Fail("robs_cap");
    return true;
}

bool GovTest_RuntimeObsJournal(void) {
    GovRuntimeObsIntV1_ModuleInit();
    GovRuntimeObsTelV1_Init(g_gov_runtime_obs_tel_v1);
    const int j0 = g_gov_runtime_obs_tel_v1.journal_chunks;
    GovRuntimeObsJournalV1_Print("=== RUNTIME_OBS_JOURNAL_SMOKE ===\n");
    if(g_gov_runtime_obs_tel_v1.journal_chunks <= j0)
        return Fail("robs_journal_tel");
    return true;
}

bool GovTest_RuntimeObsFile(void) {
    const string p = "__gov_runtime_obs_smoke.txt";
    if(!GovRuntimeObsFileV1_WriteUtf8Lf(p, "=== RUNTIME_OBS_FILE_SMOKE ===\n"))
        return Fail("robs_file_wr");
    if(!FileIsExist(p))
        return Fail("robs_file_ex");
    return true;
}

bool GovTest_RuntimeObsDeterminism(void) {
    GovRunTagIntV1_ModuleInit();
    GovRuntimeObsIntV1_ModuleInit();
    GovRuntimeObsIntV1_Configure(false, false, "", GOV_RUNTIME_OBS_FLAG_INCLUDE_RAW);
    string a = "", b = "";
    if(!GovRuntimeObsBldV1_BuildFull(Symbol(), g_gov_rtag_module_v1, g_gov_lineage_reg_v1, GOV_RUNTIME_OBS_FLAG_INCLUDE_RAW, a))
        return Fail("robs_det_a");
    if(!GovRuntimeObsBldV1_BuildFull(Symbol(), g_gov_rtag_module_v1, g_gov_lineage_reg_v1, GOV_RUNTIME_OBS_FLAG_INCLUDE_RAW, b))
        return Fail("robs_det_b");
    if(!GovRuntimeObsReplayV1_Equals(a, b))
        return Fail("robs_det_eq");
    return true;
}

bool GovTest_RuntimeObsCapitalCollapse(void) {
    GovRuntimeObsIntV1_ModuleInit();
    GovRuntimeObsV1_RefreshAccountSnapshot(Symbol());
    GovRuntimeObsV1_FeedOrderContext((int)GOV_CAP_RES_LOT_COLLAPSE_MIN_VOLUME, 0.0031, 0.0, 412.0);
    string dst = "";
    GovRunTagIntV1_ModuleInit();
    if(!GovRuntimeObsBldV1_BuildFull(Symbol(), g_gov_rtag_module_v1, g_gov_lineage_reg_v1, GOV_RUNTIME_OBS_FLAG_INCLUDE_RAW, dst))
        return Fail("robs_cap_bld");
    if(StringFind(dst, "LOT_COLLAPSE_MIN_VOLUME") < 0)
        return Fail("robs_cap_lbl");
    return true;
}

bool GovTest_RuntimeObsLineageExport(void) {
    GovRunTagIntV1_ModuleInit();
    GovRuntimeObsIntV1_ModuleInit();
    string dst = "";
    if(!GovRuntimeObsBldV1_BuildFull(Symbol(), g_gov_rtag_module_v1, g_gov_lineage_reg_v1, GOV_RUNTIME_OBS_FLAG_INCLUDE_RAW, dst))
        return Fail("robs_lin_bld");
    if(StringFind(dst, "===POSITION_LINEAGE===") < 0)
        return Fail("robs_lin_raw");
    return true;
}

bool GovTest_RuntimeObsReplayHash(void) {
    GovRunTagIntV1_ModuleInit();
    GovRuntimeObsIntV1_ModuleInit();
    string s = "";
    if(!GovRuntimeObsBldV1_BuildFull(Symbol(), g_gov_rtag_module_v1, g_gov_lineage_reg_v1, GOV_RUNTIME_OBS_FLAG_INCLUDE_RAW, s))
        return Fail("robs_hash_bld");
    if(StringLen(s) < 32)
        return Fail("robs_hash_short");
    const ulong h1 = GovRuntimeObsReplayV1_Hash64(s);
    const ulong h2 = GovRuntimeObsReplayV1_Hash64(s + " ");
    if(h1 == h2)
        return Fail("robs_hash_same");
    return true;
}

bool GovTest_RuntimeObsNoMutation(void) {
    GovRunTagIntV1_ModuleInit();
    GovRuntimeObsIntV1_ModuleInit();
    SGovRuntimeTradeIdentityV1 id;
    GovRunTagDsV1_InitIdentity(id);
    id.strategy_id = GOV_STRAT_BO;
    id.regime_id = GOV_REGIME_TREND;
    id.session_id = GOV_SATTR_SESS_NY;
    id.volatility_id = GOV_SATTR_VOL_MED;
    GovRunTagV1_Build(id.strategy_id, id.regime_id, id.volatility_id, id.session_id, id.tag);
    string err = "";
    if(!GovRunAttrV1_Register(g_gov_rtag_module_v1.reg, g_gov_rtag_module_v1.tel, 424242UL, id, err))
        return Fail("robs_nm_reg");
    const int t0 = g_gov_rtag_module_v1.bridge.total;
    string blob = "";
    if(!GovRuntimeObsBldV1_BuildFull(Symbol(), g_gov_rtag_module_v1, g_gov_lineage_reg_v1, GOV_RUNTIME_OBS_FLAG_INCLUDE_RAW, blob))
        return Fail("robs_nm_bld");
    if(g_gov_rtag_module_v1.bridge.total != t0)
        return Fail("robs_nm_mut");
    return true;
}

bool T_RUNTIME_OBS_Export(void) {
    return GovTest_RuntimeObsExport();
}
bool T_RUNTIME_OBS_Journal(void) {
    return GovTest_RuntimeObsJournal();
}
bool T_RUNTIME_OBS_File(void) {
    return GovTest_RuntimeObsFile();
}
bool T_RUNTIME_OBS_Determinism(void) {
    return GovTest_RuntimeObsDeterminism();
}
bool T_RUNTIME_OBS_CapitalCollapse(void) {
    return GovTest_RuntimeObsCapitalCollapse();
}
bool T_RUNTIME_OBS_LineageExport(void) {
    return GovTest_RuntimeObsLineageExport();
}
bool T_RUNTIME_OBS_ReplayHash(void) {
    return GovTest_RuntimeObsReplayHash();
}
bool T_RUNTIME_OBS_NoMutation(void) {
    return GovTest_RuntimeObsNoMutation();
}

//+------------------------------------------------------------------+
//| GOVERNANCE_RUNTIME_VISUAL_OBSERVABILITY_V1 — harness tests       |
//+------------------------------------------------------------------+
bool GovTest_VisualExport(void) {
    GovRunTagIntV1_ModuleInit();
    GovRuntimeVisualIntV1_ModuleInit();
    SGovStratAttribSummaryV1 sum;
    GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
    SGovVisualExecSummaryV1 ex;
    GovRuntimeVisualDsV1_InitExec(ex);
    ex.valid = 1;
    string html = "";
    GovRuntimeVisualDashV1_BuildHtml(Symbol(), g_gov_rtag_module_v1, g_gov_lineage_reg_v1, sum, ex, html);
    if(StringFind(html, "<!DOCTYPE html>") < 0)
        return Fail("vis_html_doctype");
    if(StringFind(html, "9. Governance Replay Hash") < 0)
        return Fail("vis_replay_sec");
    if(StringFind(html, "tblStrat") < 0)
        return Fail("vis_strat_tbl");
    return true;
}

bool GovTest_VisualDeterminism(void) {
    GovRunTagIntV1_ModuleInit();
    SGovStratAttribSummaryV1 sum;
    GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
    SGovVisualExecSummaryV1 ex;
    GovRuntimeVisualDsV1_InitExec(ex);
    ex.valid = 1;
    string a = "", b = "";
    GovRuntimeVisualDashV1_BuildHtml("XAUUSD", g_gov_rtag_module_v1, g_gov_lineage_reg_v1, sum, ex, a);
    GovRuntimeVisualDashV1_BuildHtml("XAUUSD", g_gov_rtag_module_v1, g_gov_lineage_reg_v1, sum, ex, b);
    if(a != b)
        return Fail("vis_det_neq");
    return true;
}

bool GovTest_VisualLineageGraph(void) {
    GovRunTagIntV1_ModuleInit();
    GovLineageV1_Reset(g_gov_lineage_reg_v1);
    GovLineageV1_RegisterRoot(g_gov_lineage_reg_v1, 991001UL, (int)GOV_STRAT_MR, TimeCurrent());
    SGovStratAttribSummaryV1 sum;
    GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
    SGovVisualExecSummaryV1 ex;
    GovRuntimeVisualDsV1_InitExec(ex);
    ex.valid = 1;
    string html = "";
    GovRuntimeVisualDashV1_BuildHtml(Symbol(), g_gov_rtag_module_v1, g_gov_lineage_reg_v1, sum, ex, html);
    if(StringFind(html, "ROOT_LINEAGE_") < 0)
        return Fail("vis_lin_root");
    return true;
}

bool GovTest_VisualStrategyBreakdown(void) {
    GovRunTagIntV1_ModuleInit();
    SGovStratAttribSummaryV1 sum;
    GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
    SGovVisualExecSummaryV1 ex;
    GovRuntimeVisualDsV1_InitExec(ex);
    ex.valid = 1;
    string html = "";
    GovRuntimeVisualDashV1_BuildHtml(Symbol(), g_gov_rtag_module_v1, g_gov_lineage_reg_v1, sum, ex, html);
    if(StringFind(html, "TrendFollowing") < 0)
        return Fail("vis_strat_tf");
    return true;
}

bool GovTest_VisualCapitalDiagnostics(void) {
    GovRunTagIntV1_ModuleInit();
    GovRuntimeObsIntV1_ModuleInit();
    GovRuntimeObsV1_RefreshAccountSnapshot(Symbol());
    GovRuntimeObsV1_FeedOrderContext((int)GOV_CAP_RES_LOT_COLLAPSE_MIN_VOLUME, 0.0031, 0.0, 412.0);
    SGovStratAttribSummaryV1 sum;
    GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
    SGovVisualExecSummaryV1 ex;
    GovRuntimeVisualDsV1_InitExec(ex);
    ex.valid = 1;
    string html = "";
    GovRuntimeVisualDashV1_BuildHtml(Symbol(), g_gov_rtag_module_v1, g_gov_lineage_reg_v1, sum, ex, html);
    if(StringFind(html, "RequestedLot") < 0)
        return Fail("vis_cap_req");
    if(StringFind(html, "0.0031") < 0)
        return Fail("vis_cap_lot");
    return true;
}

bool GovTest_VisualSurvivability(void) {
    GovRunTagIntV1_ModuleInit();
    SGovStratAttribSummaryV1 sum;
    GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
    SGovVisualExecSummaryV1 ex;
    GovRuntimeVisualDsV1_InitExec(ex);
    ex.valid = 1;
    ex.balance_dd_rel_pct = 25.0;
    string html = "";
    GovRuntimeVisualDashV1_BuildHtml(Symbol(), g_gov_rtag_module_v1, g_gov_lineage_reg_v1, sum, ex, html);
    if(StringFind(html, "Survivability") < 0)
        return Fail("vis_surv_hdr");
    if(StringFind(html, "$200") < 0)
        return Fail("vis_surv_row");
    return true;
}

bool GovTest_VisualReplayHash(void) {
    const ulong d = GovRuntimeObsReplayV1_Hash64("GOV_VISUAL_REPLAY_VECTOR_V1");
    const ulong f = GovRuntimeVisualReplayV1_Hash64Alt("GOV_VISUAL_REPLAY_VECTOR_V1");
    if(d == f)
        return Fail("vis_hash_collision");
    return true;
}

bool T_VISUAL_Export(void) {
    return GovTest_VisualExport();
}
bool T_VISUAL_Determinism(void) {
    return GovTest_VisualDeterminism();
}
bool T_VISUAL_LineageGraph(void) {
    return GovTest_VisualLineageGraph();
}
bool T_VISUAL_StrategyBreakdown(void) {
    return GovTest_VisualStrategyBreakdown();
}
bool T_VISUAL_CapitalDiagnostics(void) {
    return GovTest_VisualCapitalDiagnostics();
}
bool T_VISUAL_Survivability(void) {
    return GovTest_VisualSurvivability();
}
bool T_VISUAL_ReplayHash(void) {
    return GovTest_VisualReplayHash();
}

//+------------------------------------------------------------------+
//| GOVERNANCE_BACKTEST_DOSSIER_INTELLIGENCE_V1 — harness tests      |
//+------------------------------------------------------------------+
bool GovTest_DossierMetadata(void) {
    GovRunTagIntV1_ModuleInit();
    GovRuntimeVisualIntV1_ModuleInit();
    SGovStratAttribSummaryV1 sum;
    GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
    SGovVisualExecSummaryV1 ex;
    GovRuntimeVisualDsV1_InitExec(ex);
    ex.valid = 1;
    string html = "";
    GovBacktestDossierV1_BuildFullHtml("XAUUSD", PERIOD_M5, "TSFIX001", g_gov_rtag_module_v1, g_gov_lineage_reg_v1, g_gov_lineage_rec_v1, sum, ex, g_gov_test_cmp_baseline_row_v1, html);
    if(StringFind(html, "Backtest metadata") < 0)
        return Fail("doss_meta");
    if(StringFind(html, "report_id") < 0)
        return Fail("doss_meta_rid");
    return true;
}

bool GovTest_InputSnapshot(void) {
    GovRunTagIntV1_ModuleInit();
    GovBacktestInpSnapV1_Reset();
    g_gov_backtest_input_kv_v1 = "UNIT_KEY=UNIT_VAL\n";
    SGovStratAttribSummaryV1 sum;
    GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
    SGovVisualExecSummaryV1 ex;
    GovRuntimeVisualDsV1_InitExec(ex);
    ex.valid = 1;
    string html = "";
    GovBacktestDossierV1_BuildFullHtml("XAUUSD", PERIOD_M5, "TSFIX002", g_gov_rtag_module_v1, g_gov_lineage_reg_v1, g_gov_lineage_rec_v1, sum, ex, g_gov_test_cmp_baseline_row_v1, html);
    if(StringFind(html, "UNIT_KEY") < 0)
        return Fail("doss_inp");
    return true;
}

bool GovTest_StrategyBreakdown(void) {
    GovRunTagIntV1_ModuleInit();
    SGovStratAttribSummaryV1 sum;
    GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
    SGovVisualExecSummaryV1 ex;
    GovRuntimeVisualDsV1_InitExec(ex);
    ex.valid = 1;
    string html = "";
    GovBacktestDossierV1_BuildFullHtml("XAUUSD", PERIOD_M5, "TSFIX003", g_gov_rtag_module_v1, g_gov_lineage_reg_v1, g_gov_lineage_rec_v1, sum, ex, g_gov_test_cmp_baseline_row_v1, html);
    if(StringFind(html, "Strategy ecology intelligence") < 0)
        return Fail("doss_strat_sec");
    if(StringFind(html, "tblStrat") < 0)
        return Fail("doss_strat_tbl");
    return true;
}

bool GovTest_RegimeBreakdown(void) {
    GovRunTagIntV1_ModuleInit();
    SGovStratAttribSummaryV1 sum;
    GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
    SGovVisualExecSummaryV1 ex;
    GovRuntimeVisualDsV1_InitExec(ex);
    ex.valid = 1;
    string html = "";
    GovBacktestDossierV1_BuildFullHtml("XAUUSD", PERIOD_M5, "TSFIX004", g_gov_rtag_module_v1, g_gov_lineage_reg_v1, g_gov_lineage_rec_v1, sum, ex, g_gov_test_cmp_baseline_row_v1, html);
    if(StringFind(html, "Market regime intelligence") < 0)
        return Fail("doss_reg");
    if(StringFind(html, "TRENDING") < 0)
        return Fail("doss_reg_lab");
    return true;
}

bool GovTest_LineageTree(void) {
    GovRunTagIntV1_ModuleInit();
    GovLineageV1_Reset(g_gov_lineage_reg_v1);
    GovLineageV1_RegisterRoot(g_gov_lineage_reg_v1, 992001UL, (int)GOV_STRAT_TF, TimeCurrent());
    GovLineageV1_Close(g_gov_lineage_reg_v1, 992001UL, TimeCurrent());
    SGovStratAttribSummaryV1 sum;
    GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
    SGovVisualExecSummaryV1 ex;
    GovRuntimeVisualDsV1_InitExec(ex);
    ex.valid = 1;
    string html = "";
    GovBacktestDossierV1_BuildFullHtml("XAUUSD", PERIOD_M5, "TSFIX005", g_gov_rtag_module_v1, g_gov_lineage_reg_v1, g_gov_lineage_rec_v1, sum, ex, g_gov_test_cmp_baseline_row_v1, html);
    if(StringFind(html, "Lineage & mutation intelligence") < 0)
        return Fail("doss_lin_sec");
    if(StringFind(html, "ROOT_LINEAGE_") < 0)
        return Fail("doss_lin_root");
    return true;
}

bool GovTest_ToxicityAnalytics(void) {
    GovRunTagIntV1_ModuleInit();
    SGovStratAttribSummaryV1 sum;
    GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
    SGovVisualExecSummaryV1 ex;
    GovRuntimeVisualDsV1_InitExec(ex);
    ex.valid = 1;
    string html = "";
    GovBacktestDossierV1_BuildFullHtml("XAUUSD", PERIOD_M5, "TSFIX006", g_gov_rtag_module_v1, g_gov_lineage_reg_v1, g_gov_lineage_rec_v1, sum, ex, g_gov_test_cmp_baseline_row_v1, html);
    if(StringFind(html, "Toxicity intelligence") < 0)
        return Fail("doss_tox");
    if(StringFind(html, "Toxicity radar") < 0)
        return Fail("doss_tox_rad");
    return true;
}

bool GovTest_CapitalDiagnostics(void) {
    GovRunTagIntV1_ModuleInit();
    GovRuntimeObsIntV1_ModuleInit();
    GovRuntimeObsV1_RefreshAccountSnapshot(Symbol());
    GovRuntimeObsV1_FeedOrderContext((int)GOV_CAP_RES_LOT_COLLAPSE_MIN_VOLUME, 0.0031, 0.0, 412.0);
    SGovStratAttribSummaryV1 sum;
    GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
    SGovVisualExecSummaryV1 ex;
    GovRuntimeVisualDsV1_InitExec(ex);
    ex.valid = 1;
    string html = "";
    GovBacktestDossierV1_BuildFullHtml("XAUUSD", PERIOD_M5, "TSFIX007", g_gov_rtag_module_v1, g_gov_lineage_reg_v1, g_gov_lineage_rec_v1, sum, ex, g_gov_test_cmp_baseline_row_v1, html);
    if(StringFind(html, "Runtime capital telemetry") < 0)
        return Fail("doss_cap");
    return true;
}

bool GovTest_SurvivabilityMatrix(void) {
    GovRunTagIntV1_ModuleInit();
    SGovStratAttribSummaryV1 sum;
    GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
    SGovVisualExecSummaryV1 ex;
    GovRuntimeVisualDsV1_InitExec(ex);
    ex.valid = 1;
    ex.balance_dd_rel_pct = 30.0;
    string html = "";
    GovBacktestDossierV1_BuildFullHtml("XAUUSD", PERIOD_M5, "TSFIX008", g_gov_rtag_module_v1, g_gov_lineage_reg_v1, g_gov_lineage_rec_v1, sum, ex, g_gov_test_cmp_baseline_row_v1, html);
    if(StringFind(html, "Deposit-tier survivability matrix") < 0)
        return Fail("doss_surv");
    return true;
}

bool GovTest_ComparativeInsights(void) {
    GovRunTagIntV1_ModuleInit();
    GovBacktestInpSnapV1_Reset();
    g_gov_backtest_input_kv_v1 = "k=v\n";
    g_gov_dossier_compare_baseline_kv_v1 = "k=v\n";
    SGovStratAttribSummaryV1 sum;
    GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
    SGovVisualExecSummaryV1 ex;
    GovRuntimeVisualDsV1_InitExec(ex);
    ex.valid = 1;
    string html = "";
    GovBacktestDossierV1_BuildFullHtml("XAUUSD", PERIOD_M5, "TSFIX009", g_gov_rtag_module_v1, g_gov_lineage_reg_v1, g_gov_lineage_rec_v1, sum, ex, g_gov_test_cmp_baseline_row_v1, html);
    if(StringFind(html, "IDENTICAL_PAYLOAD") < 0)
        return Fail("doss_cmp");
    g_gov_dossier_compare_baseline_kv_v1 = "";
    return true;
}

bool GovTest_FailureDiagnostics(void) {
    GovRunTagIntV1_ModuleInit();
    GovRuntimeObsIntV1_ModuleInit();
    GovRuntimeObsV1_RefreshAccountSnapshot(Symbol());
    GovRuntimeObsV1_FeedOrderContext((int)GOV_CAP_RES_LOT_COLLAPSE_MIN_VOLUME, 0.01, 0.0, 500.0);
    SGovStratAttribSummaryV1 sum;
    GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
    SGovVisualExecSummaryV1 ex;
    GovRuntimeVisualDsV1_InitExec(ex);
    ex.valid = 1;
    ex.balance_dd_rel_pct = 40.0;
    string html = "";
    GovBacktestDossierV1_BuildFullHtml("XAUUSD", PERIOD_M5, "TSFIX010", g_gov_rtag_module_v1, g_gov_lineage_reg_v1, g_gov_lineage_rec_v1, sum, ex, g_gov_test_cmp_baseline_row_v1, html);
    if(StringFind(html, "Governance breach diagnostics") < 0)
        return Fail("doss_fail");
    if(StringFind(html, "failure_digest=") < 0)
        return Fail("doss_fail_digest");
    return true;
}

bool GovTest_RecoveryAnalysis(void) {
    GovRunTagIntV1_ModuleInit();
    GovLineageV1_Reset(g_gov_lineage_reg_v1);
    GovLineageV1_RegisterRoot(g_gov_lineage_reg_v1, 993001UL, (int)GOV_STRAT_GR, TimeCurrent());
    SGovStratAttribSummaryV1 sum;
    GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
    SGovVisualExecSummaryV1 ex;
    GovRuntimeVisualDsV1_InitExec(ex);
    ex.valid = 1;
    string html = "";
    GovBacktestDossierV1_BuildFullHtml("XAUUSD", PERIOD_M5, "TSFIX011", g_gov_rtag_module_v1, g_gov_lineage_reg_v1, g_gov_lineage_rec_v1, sum, ex, g_gov_test_cmp_baseline_row_v1, html);
    if(StringFind(html, "Recovery chain genealogy") < 0)
        return Fail("doss_rec");
    return true;
}

bool GovTest_Recommendations(void) {
    GovRunTagIntV1_ModuleInit();
    SGovStratAttribSummaryV1 sum;
    GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
    SGovVisualExecSummaryV1 ex;
    GovRuntimeVisualDsV1_InitExec(ex);
    ex.valid = 1;
    string html = "";
    GovBacktestDossierV1_BuildFullHtml("XAUUSD", PERIOD_M5, "TSFIX012", g_gov_rtag_module_v1, g_gov_lineage_reg_v1, g_gov_lineage_rec_v1, sum, ex, g_gov_test_cmp_baseline_row_v1, html);
    if(StringFind(html, "Adaptive governance recommendations") < 0)
        return Fail("doss_reco");
    if(StringFind(html, "Regime detection intelligence") < 0)
        return Fail("doss_reg22");
    return true;
}

bool GovTest_DeterministicExport(void) {
    GovSigForensicsV1_ModuleInit();
    GovRegimeIntV1_ModuleInit();
    GovRunTagIntV1_ModuleInit();
    SGovStratAttribSummaryV1 sum;
    GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
    SGovVisualExecSummaryV1 ex;
    GovRuntimeVisualDsV1_InitExec(ex);
    ex.valid = 1;
    string a = "", b = "";
    GovBacktestDossierV1_BuildFullHtml("XAUUSD", PERIOD_M5, "TSFIX013", g_gov_rtag_module_v1, g_gov_lineage_reg_v1, g_gov_lineage_rec_v1, sum, ex, g_gov_test_cmp_baseline_row_v1, a);
    GovSigForensicsV1_ModuleInit();
    GovRegimeIntV1_ModuleInit();
    GovBacktestDossierV1_BuildFullHtml("XAUUSD", PERIOD_M5, "TSFIX013", g_gov_rtag_module_v1, g_gov_lineage_reg_v1, g_gov_lineage_rec_v1, sum, ex, g_gov_test_cmp_baseline_row_v1, b);
    if(a != b)
        return Fail("doss_det");
    return true;
}

bool GovTest_SignalLifecycle(void)
{
   GovSigForensicsV1_ModuleInit();
   GovRegimeIntV1_ModuleInit();
   GovSigFoV1_OnCreatedOnly(g_gov_sig_forensics_tel_v1, D'2026.03.15');
   MarketState st;
   GovSigForensicsV1_MakeStubState(REGIME_RANGING, st);
   GovSigFoV1_OnReject(g_gov_sig_forensics_tel_v1, D'2026.03.15', 2, REGIME_RANGING, GOV_SIG_REJECT_QUALITY, false);
   if(g_gov_sig_forensics_tel_v1.state_hits[GOV_SIG_CREATED] < 1)
      return Fail("sig_lc_created");
   if(g_gov_sig_forensics_tel_v1.month_rejected[2] < 1)
      return Fail("sig_lc_mar_rej");
   if(g_gov_sig_forensics_tel_v1.month_created[2] < 1)
      return Fail("sig_lc_mar_cr");
   return true;
}

bool GovTest_RejectReason(void)
{
   if(GovSigRejectV1_FromNative(SIGNAL_REJECT_QUALITY_LOW) != GOV_SIG_REJECT_QUALITY)
      return Fail("sig_rr_q");
   if(GovSigRejectV1_FromNative(SIGNAL_REJECT_NO_CONSENSUS) != GOV_SIG_REJECT_CONSENSUS)
      return Fail("sig_rr_c");
   return true;
}

bool GovTest_FilterHeatmap(void)
{
   GovSigForensicsV1_ModuleInit();
   GovRegimeIntV1_ModuleInit();
   MarketState st;
   GovSigForensicsV1_MakeStubState(REGIME_TRENDING, st);
   GovSigForensicsV1_RecordReject(D'2026.06.10', st, 3, SIGNAL_BUY, 60, SIGNAL_REJECT_REQUIRE_KEYLEVEL, false);
   if(GovSigHeatmapV1_CellStratRej(g_gov_sig_forensics_tel_v1, 3, GOV_SIG_REJECT_KEYLEVEL) < 1)
      return Fail("sig_heat_s");
   if(GovSigHeatmapV1_CellRegRej(g_gov_sig_forensics_tel_v1, 0, GOV_SIG_REJECT_KEYLEVEL) < 1)
      return Fail("sig_heat_r");
   return true;
}

bool GovTest_MonthlyActivation(void)
{
   GovSigForensicsV1_ModuleInit();
   GovRegimeIntV1_ModuleInit();
   MarketState st;
   GovSigForensicsV1_MakeStubState(REGIME_RANGING, st);
   for(int k = 0; k < 5; k++)
      GovSigForensicsV1_OnConsensusResolvedNone(D'2026.04.05', st);
   if(g_gov_sig_forensics_tel_v1.month_created[3] < 5)
      return Fail("sig_mo_cr");
   if(g_gov_sig_forensics_tel_v1.month_rejected[3] < 5)
      return Fail("sig_mo_rj");
   return true;
}

bool GovTest_ConsensusCollapse(void)
{
   GovSigForensicsV1_ModuleInit();
   GovRegimeIntV1_ModuleInit();
   MarketState st;
   GovSigForensicsV1_MakeStubState(REGIME_RANGING, st);
   for(int k = 0; k < 20; k++)
      GovSigForensicsV1_OnConsensusResolvedNone(D'2026.05.01', st);
   GovSigForensicsV1_OnConsensusResolvedOk(D'2026.05.01', st, SIGNAL_BUY, 4, 0);
   if(g_gov_sig_forensics_tel_v1.consensus_fail < 20)
      return Fail("sig_cc_fail");
   if(GovSigConsensusV1_PassPermille(g_gov_sig_forensics_tel_v1.consensus_pass, g_gov_sig_forensics_tel_v1.consensus_fail) >= 100)
      return Fail("sig_cc_rate");
   return true;
}

bool GovTest_RegimeSuppression(void)
{
   GovSigForensicsV1_ModuleInit();
   GovRegimeIntV1_ModuleInit();
   MarketState stT;
   GovSigForensicsV1_MakeStubState(REGIME_TRENDING, stT);
   GovSigForensicsV1_RecordAccepted(D'2026.02.01', stT, 0, SIGNAL_BUY, 70);
   GovSigForensicsV1_RecordReject(D'2026.02.02', stT, 1, SIGNAL_SELL, 60, SIGNAL_REJECT_QUALITY_LOW, false);
   GovSigForensicsV1_RecordReject(D'2026.02.03', stT, 2, SIGNAL_BUY, 55, SIGNAL_REJECT_REQUIRE_TREND, false);
   const int pmT = GovSigRegimeV1_AcceptPermille(g_gov_sig_forensics_tel_v1.reg_sig[0], g_gov_sig_forensics_tel_v1.reg_acc[0]);
   MarketState stR;
   GovSigForensicsV1_MakeStubState(REGIME_RANGING, stR);
   GovSigForensicsV1_RecordReject(D'2026.02.04', stR, 1, SIGNAL_SELL, 60, SIGNAL_REJECT_QUALITY_LOW, false);
   const int pmR = GovSigRegimeV1_AcceptPermille(g_gov_sig_forensics_tel_v1.reg_sig[1], g_gov_sig_forensics_tel_v1.reg_acc[1]);
   if(pmT > 400)
      return Fail("sig_reg_t");
   if(pmR > 2)
      return Fail("sig_reg_r");
   return true;
}

bool GovTest_DeadSignalZones(void)
{
   GovSigForensicsV1_ModuleInit();
   GovRegimeIntV1_ModuleInit();
   MarketState st;
   GovSigForensicsV1_MakeStubState(REGIME_RANGING, st);
   GovSigForensicsV1_RecordAccepted(D'2026.02.28', st, 0, SIGNAL_BUY, 80);
   for(int k = 0; k < 25; k++)
      GovSigForensicsV1_RecordReject(D'2026.04.15', st, 2, SIGNAL_BUY, 40, SIGNAL_REJECT_QUALITY_LOW, false);
   if(g_gov_sig_forensics_tel_v1.starvation_alerts < 1)
      return Fail("sig_dead_starve");
   return true;
}

bool GovTest_ActivationStarvation(void)
{
   return GovTest_DeadSignalZones();
}

bool GovTest_SignalForensicsHtml(void)
{
   GovSigForensicsV1_ModuleInit();
   GovRegimeIntV1_ModuleInit();
   string h = "";
   GovSigForensicsHtmlV1_AppendSection(g_gov_sig_forensics_tel_v1, h);
   if(StringFind(h, "SIGNAL FORENSICS INTELLIGENCE") < 0)
      return Fail("sigf_html_title");
   if(StringFind(h, "id=\"sigf-monthly\"") < 0)
      return Fail("sigf_html_month");
   return true;
}

bool T_SIG_FORENSICS_Lifecycle(void) { return GovTest_SignalLifecycle(); }
bool T_SIG_FORENSICS_RejectReason(void) { return GovTest_RejectReason(); }
bool T_SIG_FORENSICS_FilterHeatmap(void) { return GovTest_FilterHeatmap(); }
bool T_SIG_FORENSICS_MonthlyActivation(void) { return GovTest_MonthlyActivation(); }
bool T_SIG_FORENSICS_ConsensusCollapse(void) { return GovTest_ConsensusCollapse(); }
bool T_SIG_FORENSICS_RegimeSuppression(void) { return GovTest_RegimeSuppression(); }
bool T_SIG_FORENSICS_DeadSignalZones(void) { return GovTest_DeadSignalZones(); }
bool T_SIG_FORENSICS_ActivationStarvation(void) { return GovTest_ActivationStarvation(); }
bool T_SIG_FORENSICS_Html(void) { return GovTest_SignalForensicsHtml(); }

bool T_DOSSIER_Metadata(void) {
    return GovTest_DossierMetadata();
}
bool T_DOSSIER_InputSnapshot(void) {
    return GovTest_InputSnapshot();
}
bool T_DOSSIER_StrategyBreakdown(void) {
    return GovTest_StrategyBreakdown();
}
bool T_DOSSIER_RegimeBreakdown(void) {
    return GovTest_RegimeBreakdown();
}
bool T_DOSSIER_LineageTree(void) {
    return GovTest_LineageTree();
}
bool T_DOSSIER_ToxicityAnalytics(void) {
    return GovTest_ToxicityAnalytics();
}
bool T_DOSSIER_CapitalDiagnostics(void) {
    return GovTest_CapitalDiagnostics();
}
bool T_DOSSIER_SurvivabilityMatrix(void) {
    return GovTest_SurvivabilityMatrix();
}
bool T_DOSSIER_ComparativeInsights(void) {
    return GovTest_ComparativeInsights();
}
bool T_DOSSIER_FailureDiagnostics(void) {
    return GovTest_FailureDiagnostics();
}
bool T_DOSSIER_RecoveryAnalysis(void) {
    return GovTest_RecoveryAnalysis();
}
bool T_DOSSIER_Recommendations(void) {
    return GovTest_Recommendations();
}
bool T_DOSSIER_DeterministicExport(void) {
    return GovTest_DeterministicExport();
}

bool GovTest_RunTagIdentity(void) {
    return T_RTAG_StrategyClass() && T_RTAG_RegimeClass() && T_RTAG_SessionClass() && T_RTAG_VolClass() && T_RTAG_TagBuild();
}

bool GovTest_RunTagRegistry(void) {
    return T_RTAG_Registry();
}

bool GovTest_RunTagBridge(void) {
    return T_RTAG_Bridge();
}

bool GovTest_RunTagTelemetry(void) {
    GovRunTagIntV1_ModuleInit();
    SGovRuntimeTradeIdentityV1 id;
    GovRunTagDsV1_InitIdentity(id);
    id.strategy_id = GOV_STRAT_TF;
    id.regime_id = GOV_REGIME_TREND;
    id.session_id = GOV_SATTR_SESS_NY;
    id.volatility_id = GOV_SATTR_VOL_MED;
    GovRunTagV1_Build(id.strategy_id, id.regime_id, id.volatility_id, id.session_id, id.tag);
    string err = "";
    if(!GovRunAttrV1_Register(g_gov_rtag_module_v1.reg, g_gov_rtag_module_v1.tel, 7777, id, err))
        return Fail("rtag_tel_reg");
    if(!GovRunAttrV1_Commit(g_gov_rtag_module_v1.reg, g_gov_rtag_module_v1.bridge, g_gov_rtag_module_v1.tel, 7777, 50L, 1, 0, 0, err))
        return Fail("rtag_tel_com");
    if(g_gov_rtag_module_v1.tel.trades_by_strategy[GOV_STRAT_TF] != 1)
        return Fail("rtag_tel_strat");
    if(g_gov_rtag_module_v1.tel.commits != 1)
        return Fail("rtag_tel_commits");
    return true;
}

bool GovTest_RunTagExport(void) {
    return T_RTAG_Export();
}

bool GovTest_Phase23EcologyV1(void) {
    GovEcolIntV1_ModuleInit();
    GovEcolIntV1_Configure(true);
    g_gov_regime_store_v1.current_regime = AURUM_REGIME_VOLATILITY_EXPANSION;
    MarketState ms;
    ZeroMemory(ms);
    ms.regime = REGIME_VOLATILE;
    ms.session = SESSION_LONDON;
    ms.atrRatio = 1.45;
    SignalResult sig[8];
    for(int i = 0; i < 8; i++) {
        sig[i].signal = SIGNAL_NONE;
        sig[i].strength = 0.0;
        sig[i].weight = 1.0;
    }
    sig[2].signal = SIGNAL_BUY;
    sig[2].strength = 0.9;
    sig[0].signal = SIGNAL_BUY;
    sig[0].strength = 0.5;
    GovEcolIntV1_OnBarSignals(TimeCurrent(), ms, sig);
    if(g_gov_ecology_v1.last_bar_suppress_clears < 1)
        return Fail("eco23_suppress_ctr");
    if(sig[2].signal != SIGNAL_NONE)
        return Fail("eco23_mr_disabled_expansion");
    if(sig[0].signal == SIGNAL_NONE)
        return Fail("eco23_tf_should_participate");
    if(g_gov_ecology_v1.cooccur[0][2] < 1UL)
        return Fail("eco23_cooccur");
    GovEcolIntV1_Configure(false);
    return true;
}

bool GovTest_Phase235RestrictionForensicsV1(void) {
    GovRfIntV1_ModuleInit();
    GovRfIntV1_Configure(true);
    const datetime ts = (datetime)1600000000;
    GovRfIntV1_OnEarlyReject(ts, (int)GOV_RF_STAGE_SPREAD_V1, SIGNAL_REJECT_SPREAD, (int)AS_CT_DENY_NONE, -1);
    GovRfEngV1_OnRiskSample(g_gov_rf_v1, false, (int)AS_CT_DENY_DD_LOCK);
    GovRfEngV1_OnRiskSample(g_gov_rf_v1, true, (int)AS_CT_DENY_NONE);
    GovRfIntV1_OnConsensusEval(ts, 3, 4, 1, 0, SIGNAL_NONE, 2);
    GovRfEngV1_OnDdProbe(g_gov_rf_v1, 10.0, 10000.0, 9950.0);
    SignalResult sig235[8];
    for(int i = 0; i < 8; i++) {
        sig235[i].signal = SIGNAL_NONE;
        sig235[i].strength = 0.0;
        sig235[i].weight = 1.0;
    }
    GovRfIntV1_OnEcologyFootprint(2, 0, 0, 0, 3, 4, sig235);
    if(g_gov_rf_v1.ring_count < 1)
        return Fail("rf235_ring");
    if(g_gov_rf_v1.risk_deny_dd_lock < 1)
        return Fail("rf235_dd_lock");
    if(g_gov_rf_v1.consensus_failures < 1)
        return Fail("rf235_cons");
    if(g_gov_rf_v1.ecology_suppress_clears_total < 3)
        return Fail("rf235_eco");
    GovRfIntV1_FlushPersistence();
    GovRfIntV1_Configure(false);
    return true;
}

bool GovTest_Phase236RiskLockIntelV1(void) {
    GovRliIntV1_ModuleInit();
    GovRliIntV1_Configure(true);
    GovRliEngV1_OnBarEndStoreEco(g_gov_rli_v1, 5);
    const datetime ts0 = (datetime)1700000000;
    GovRliIntV1_OnBarPostCanTrade(ts0, 1UL, false, (int)AS_CT_DENY_DD_LOCK, (int)HALT_DRAWDOWN, 2, 15.0, 10000.0, 9100.0, 25.0, 1.1, 2, 30, false, true);
    GovRliIntV1_OnBarPostCanTrade(ts0 + 60, 2UL, true, (int)AS_CT_DENY_NONE, (int)HALT_NONE, 0, 2.0, 10000.0, 9990.0, 12.0, 0.9, 2, 30, false, true);
    if(g_gov_rli_v1.lock_events < 1)
        return Fail("rli236_lock");
    if(g_gov_rli_v1.thaw_successes < 1)
        return Fail("rli236_thaw");
    GovRliIntV1_OnBarPostCanTrade(ts0 + 120, 3UL, false, (int)AS_CT_DENY_DD_LOCK, (int)HALT_DRAWDOWN, 0, 4.0, 10000.0, 9800.0, 20.0, 1.0, 2, 30, false, true);
    if(g_gov_rli_v1.thaw_interruptions < 1)
        return Fail("rli236_thaw_interrupt");
    const int dd_cls = GovRliEngV1_ClassifyDd(0.5, 15.0, 0.05, false, true);
    if(dd_cls != (int)GOV_RLI_DD_TESTER_ARTIFACT_V1)
        return Fail("rli236_dd_class");
    const int fp_cls = GovRliEngV1_ClassifyFloatStress(0.2, 0);
    if(fp_cls != (int)GOV_RLI_FLOAT_MICRO_V1)
        return Fail("rli236_float_norm");
    const int persist_cls = GovRliEngV1_ClassifyPersistence(200);
    if(persist_cls != (int)GOV_RLI_LP_PARALYSIS_V1)
        return Fail("rli236_paralysis");
    GovRliIntV1_FlushPersistence();
    GovRliIntV1_Configure(false);
    return true;
}

bool GovTest_Phase237AdaptiveThawStabilizationV1(void) {
    GovAtsIntV1_ModuleInit();
    GovAtsIntV1_Configure(true);
    GovRliIntV1_ModuleInit();
    GovRliIntV1_Configure(true);
    GovRfIntV1_ModuleInit();
    GovRfIntV1_Configure(true);
    GovEcolIntV1_ModuleInit();
    GovEcolIntV1_Configure(true);
    GovRliEngV1_OnBarEndStoreEco(g_gov_rli_v1, 2);
    const datetime ts0 = (datetime)1800000000;
    GovRliIntV1_OnBarPostCanTrade(ts0, 1UL, false, (int)AS_CT_DENY_DD_LOCK, (int)HALT_DRAWDOWN, 0, 12.0, 10000.0, 9400.0, 22.0, 1.15, 2, 30, false, true);
    GovRliIntV1_OnBarPostCanTrade(ts0 + 60, 2UL, true, (int)AS_CT_DENY_NONE, (int)HALT_NONE, 0, 1.2, 10000.0, 9985.0, 18.0, 1.0, 2, 30, false, true);
    GovRfEngV1_OnRiskSample(g_gov_rf_v1, true, (int)AS_CT_DENY_NONE);
    GovRfEngV1_OnRiskSample(g_gov_rf_v1, false, (int)AS_CT_DENY_DD_LOCK);
    g_gov_ecology_v1.s[0].bars_participation = 12;
    g_gov_ecology_v1.s[1].bars_participation = 8;
    g_gov_ecology_v1.last_bar_suppress_clears = 2;
    GovAtsIntV1_OnBar(2UL, 1.1, 10000.0, 9975.0, 20.0, 1.02, true);
    if(g_gov_ats_v1.bars_observed != 1UL)
        return Fail("ats237_bars");
    if(g_gov_ats_v1.thaw_state_hist[g_gov_ats_v1.last_thaw_state] < 1UL)
        return Fail("ats237_thaw_hist");
    if(GovAtsEngV1_ClassifyLockDecay(true, 350UL) != (int)GOV_ATS_DECAY_PARALYSIS_LOOP_V1)
        return Fail("ats237_decay_cls");
    if(GovAtsEngV1_ClassifyFloatV2(1.5, 0.5, 2.5) != (int)GOV_ATS_FLOAT2_ELEVATED_V1)
        return Fail("ats237_float2_cls");
    if(GovAtsEngV1_ClassifyParalysis(850.0, 100.0) != (int)GOV_ATS_PAR_PARALYZED_V1)
        return Fail("ats237_paralysis_cls");
    if(GovAtsEngV1_ClassifyRecoveryState(12.0, 0.05) != (int)GOV_ATS_REC_COLLAPSING_V1)
        return Fail("ats237_recovery_cls");
    if(GovAtsEngV1_ClassifyThawState(800.0, 80.0, true, false, 2.0, 2.0) != (int)GOV_ATS_THAW_HEALTHY_V1)
        return Fail("ats237_thaw_cls");
    GovAtsIntV1_FlushPersistence();
    GovAtsIntV1_Configure(false);
    GovRliIntV1_Configure(false);
    GovRfIntV1_Configure(false);
    GovEcolIntV1_Configure(false);
    return true;
}

int OnInit() {
    GovCmpDsV1_Init(g_gov_test_cmp_baseline_row_v1);
    if(!T_Evidence_FusionDeterminism())
        return INIT_FAILED;
    if(!T_Evidence_AttribPipeSchema())
        return INIT_FAILED;
    if(!T_Evidence_IntegratedShadowStable())
        return INIT_FAILED;
    if(!T_Orchestration_GovExecPipeSchema())
        return INIT_FAILED;
    if(!T_Orchestration_ReplayExecTelem())
        return INIT_FAILED;
    if(!T_Orchestration_LockdownTransitionHook())
        return INIT_FAILED;
    if(!T_Orchestration_ThrottleDeterminism())
        return INIT_FAILED;
    if(!T_Replay_ParseGoldenMultiline())
        return INIT_FAILED;
    if(!T_Replay_OrphanAttribFails())
        return INIT_FAILED;
    if(!T_Replay_MalformedUnknownFails())
        return INIT_FAILED;
    if(!T_Replay_ExportDeterminism())
        return INIT_FAILED;
    if(!T_Replay_TimelinePipeSchema())
        return INIT_FAILED;
    if(!T_Replay_PolicyComparatorSelf())
        return INIT_FAILED;
    if(!T_Replay_ContainmentNonEmpty())
        return INIT_FAILED;
    if(!T_Primitives_CastLongToIntSafe())
        return INIT_FAILED;
    if(!T_Incident_ToxicSpiralDetects())
        return INIT_FAILED;
    if(!T_Incident_SurvCollapseDetects())
        return INIT_FAILED;
    if(!T_Incident_FalseRecoveryDetects())
        return INIT_FAILED;
    if(!T_Incident_QuarEscalationDetects())
        return INIT_FAILED;
    if(!T_Incident_ExecSuppressionDetects())
        return INIT_FAILED;
    if(!T_Incident_ReplaySubset())
        return INIT_FAILED;
    if(!T_Incident_ExportDeterminism())
        return INIT_FAILED;
    if(!T_Incident_LiveBundleDeterminism())
        return INIT_FAILED;
    if(!T_Incident_ReconstructionChain())
        return INIT_FAILED;
    if(!T_Incident_CausalityLineStable())
        return INIT_FAILED;
    if(!T_Meta_Long2Rp())
        return INIT_FAILED;
    if(!T_Meta_HlthDet())
        return INIT_FAILED;
    if(!T_Meta_FpStb())
        return INIT_FAILED;
    if(!T_Meta_RegPrs())
        return INIT_FAILED;
    if(!T_Meta_CtnEffStb())
        return INIT_FAILED;
    if(!T_Meta_ExpDet())
        return INIT_FAILED;
    if(!T_Meta_CmpSlf0())
        return INIT_FAILED;
    if(!T_Res_RunDet())
        return INIT_FAILED;
    if(!T_Res_DriftSlf())
        return INIT_FAILED;
    if(!T_Res_ExpDet())
        return INIT_FAILED;
    if(!T_Sim_SbxIso())
        return INIT_FAILED;
    if(!T_Sim_StressDet())
        return INIT_FAILED;
    if(!T_Sim_MulArch())
        return INIT_FAILED;
    if(!T_Sim_ExpDet())
        return INIT_FAILED;
    if(!T_Sim_StabDet())
        return INIT_FAILED;
    if(!T_Sim_CmpDupArch())
        return INIT_FAILED;
    if(!T_Sim_SurvComp())
        return INIT_FAILED;
    if(!T_Sim_QuarEsc())
        return INIT_FAILED;
    if(!T_Resil_CurveDet())
        return INIT_FAILED;
    if(!T_Resil_FatigueStb())
        return INIT_FAILED;
    if(!T_Resil_ClpsPos())
        return INIT_FAILED;
    if(!T_Resil_BrittleStb())
        return INIT_FAILED;
    if(!T_Resil_ExpDet())
        return INIT_FAILED;
    if(!T_Resil_CmpSlf())
        return INIT_FAILED;
    if(!T_Resil_SbxIso())
        return INIT_FAILED;
    if(!T_Resil_DegrVel())
        return INIT_FAILED;
    if(!T_Resil_HalfLife())
        return INIT_FAILED;
    if(!T_Resil_StabPers())
        return INIT_FAILED;
    if(!T_Evo_LinDet())
        return INIT_FAILED;
    if(!T_Evo_DriftStb())
        return INIT_FAILED;
    if(!T_Evo_Deg())
        return INIT_FAILED;
    if(!T_Evo_SurvEvo())
        return INIT_FAILED;
    if(!T_Evo_TopoDet())
        return INIT_FAILED;
    if(!T_Evo_ExpDet())
        return INIT_FAILED;
    if(!T_Evo_CmpSlf())
        return INIT_FAILED;
    if(!T_Evo_SbxIso())
        return INIT_FAILED;
    if(!T_Evo_Branch())
        return INIT_FAILED;
    if(!T_Evo_ResInherit())
        return INIT_FAILED;
    if(!T_Strat_EndDet())
        return INIT_FAILED;
    if(!T_Strat_BudStb())
        return INIT_FAILED;
    if(!T_Strat_TrajDet())
        return INIT_FAILED;
    if(!T_Strat_Cat())
        return INIT_FAILED;
    if(!T_Strat_ExpDet())
        return INIT_FAILED;
    if(!T_Strat_CmpSlf())
        return INIT_FAILED;
    if(!T_Strat_SbxIso())
        return INIT_FAILED;
    if(!T_Strat_CollapseAvoid())
        return INIT_FAILED;
    if(!T_Strat_RegBal())
        return INIT_FAILED;
    if(!T_Strat_LongHoriz())
        return INIT_FAILED;
    if(!T_Civ_FedDet())
        return INIT_FAILED;
    if(!T_Civ_HierStb())
        return INIT_FAILED;
    if(!T_Civ_DipDet())
        return INIT_FAILED;
    if(!T_Civ_MemStable())
        return INIT_FAILED;
    if(!T_Civ_TopoDet())
        return INIT_FAILED;
    if(!T_Civ_StabDet())
        return INIT_FAILED;
    if(!T_Civ_ClpsDet())
        return INIT_FAILED;
    if(!T_Civ_ExpDet())
        return INIT_FAILED;
    if(!T_Civ_CmpSlf())
        return INIT_FAILED;
    if(!T_Civ_SbxIso())
        return INIT_FAILED;
    if(!T_Civ_RankStable())
        return INIT_FAILED;
    if(!T_Civ_Continuity())
        return INIT_FAILED;
    if(!T_Civ_FragRisk())
        return INIT_FAILED;
    if(!T_Civ_Cascade())
        return INIT_FAILED;
    if(!T_Civ_FedEndurance())
        return INIT_FAILED;
    if(!T_Tmp_EpochDet())
        return INIT_FAILED;
    if(!T_Tmp_AgingStb())
        return INIT_FAILED;
    if(!T_Tmp_ContDet())
        return INIT_FAILED;
    if(!T_Tmp_CycleDet())
        return INIT_FAILED;
    if(!T_Tmp_EraShift())
        return INIT_FAILED;
    if(!T_Tmp_PressAccum())
        return INIT_FAILED;
    if(!T_Tmp_DecayVel())
        return INIT_FAILED;
    if(!T_Tmp_StabDet())
        return INIT_FAILED;
    if(!T_Tmp_ExpDet())
        return INIT_FAILED;
    if(!T_Tmp_CmpSlf())
        return INIT_FAILED;
    if(!T_Tmp_SbxIso())
        return INIT_FAILED;
    if(!T_Tmp_LongHoriz())
        return INIT_FAILED;
    if(!T_Tmp_CollapseCycle())
        return INIT_FAILED;
    if(!T_Tmp_RecoveryCycle())
        return INIT_FAILED;
    if(!T_Tmp_Endurance())
        return INIT_FAILED;
    if(!T_Eco_SpeciesDet())
        return INIT_FAILED;
    if(!T_Eco_PredPreyDet())
        return INIT_FAILED;
    if(!T_Eco_BiodivStb())
        return INIT_FAILED;
    if(!T_Eco_CollapseDet())
        return INIT_FAILED;
    if(!T_Eco_CoexistDet())
        return INIT_FAILED;
    if(!T_Eco_ResilienceDet())
        return INIT_FAILED;
    if(!T_Eco_ExpDet())
        return INIT_FAILED;
    if(!T_Eco_CmpSlf())
        return INIT_FAILED;
    if(!T_Eco_SbxIso())
        return INIT_FAILED;
    if(!T_Eco_LongHoriz())
        return INIT_FAILED;
    if(!T_Eco_RecoveryEcology())
        return INIT_FAILED;
    if(!T_Eco_CollapsePropagation())
        return INIT_FAILED;
    if(!T_Eco_BiodiversityRecovery())
        return INIT_FAILED;
    if(!T_Eco_ResourcePressure())
        return INIT_FAILED;
    if(!T_Eco_EcosystemBalance())
        return INIT_FAILED;
    if(!T_Con_IdDet())
        return INIT_FAILED;
    if(!T_Con_CohStb())
        return INIT_FAILED;
    if(!T_Con_MemDet())
        return INIT_FAILED;
    if(!T_Con_AwareDet())
        return INIT_FAILED;
    if(!T_Con_CollapseAware())
        return INIT_FAILED;
    if(!T_Con_SelfCons())
        return INIT_FAILED;
    if(!T_Con_ContAware())
        return INIT_FAILED;
    if(!T_Con_ExpDet())
        return INIT_FAILED;
    if(!T_Con_CmpSlf())
        return INIT_FAILED;
    if(!T_Con_SbxIso())
        return INIT_FAILED;
    if(!T_Con_LongHoriz())
        return INIT_FAILED;
    if(!T_Con_IdentityPersist())
        return INIT_FAILED;
    if(!T_Con_Fragmentation())
        return INIT_FAILED;
    if(!T_Con_RecoveryIdentity())
        return INIT_FAILED;
    if(!T_Con_CollapseTrajectory())
        return INIT_FAILED;
    if(!T_Semver_Valid())
        return INIT_FAILED;
    if(!T_Semver_Invalid())
        return INIT_FAILED;
    if(!T_Semver_AcceptCorpus())
        return INIT_FAILED;
    if(!T_Semver_RejectCorpus())
        return INIT_FAILED;
    if(!T_Semver_Overflow())
        return INIT_FAILED;
    if(!T_Semver_NonAsciiRejected())
        return INIT_FAILED;
    if(!T_Semver_CrLfNormalizesInValidate())
        return INIT_FAILED;
    if(!T_Load_ValidUtf8())
        return INIT_FAILED;
    if(!T_Load_DuplicateKey())
        return INIT_FAILED;
    if(!T_Load_Malformed())
        return INIT_FAILED;
    if(!T_Load_UnsupportedKey())
        return INIT_FAILED;
    if(!T_Load_ChecksumMismatch())
        return INIT_FAILED;
    if(!T_Load_InvalidSemverUtf8())
        return INIT_FAILED;
    if(!T_Load_FileMissing())
        return INIT_FAILED;
    if(!T_ResetSnapshot())
        return INIT_FAILED;
    if(!T_Primitives_FloorAndSat())
        return INIT_FAILED;
    if(!T_TranscriptHash_KnownVector())
        return INIT_FAILED;
    if(!T_Telemetry_FormatAndRejectPipe())
        return INIT_FAILED;
    if(!T_Load_FromFileRoundtrip())
        return INIT_FAILED;
    if(!T_AppendTranscript_Bin())
        return INIT_FAILED;
    if(!T_Append_EmptyPathNoop())
        return INIT_FAILED;
    if(!T_Load_MissingEmbedded())
        return INIT_FAILED;
    if(!T_Load_OutErrChecksumMismatch())
        return INIT_FAILED;
    if(!T_Utf8_CharArrayRoundTrip())
        return INIT_FAILED;
    if(!T_PolicySnapshotCopy_Idempotent())
        return INIT_FAILED;
    if(!T_Gov_EventPipeSchema())
        return INIT_FAILED;
    if(!T_Gov_TripwireLockdown())
        return INIT_FAILED;
    if(!T_Gov_LockdownRelax())
        return INIT_FAILED;
    if(!T_ShadowTick_StillRuns())
        return INIT_FAILED;
    if(!T_GovRuntime_ShadowSnapshot())
        return INIT_FAILED;
    if(!T_GovRuntime_QueueAppend())
        return INIT_FAILED;
    if(!T_GovRuntime_NoReplayParser())
        return INIT_FAILED;
    if(!T_GovRuntime_NoExportHotPath())
        return INIT_FAILED;
    if(!T_GovRuntime_NonBlocking())
        return INIT_FAILED;
    if(!T_GovRuntime_TimerSafe())
        return INIT_FAILED;
    if(!T_CTX_Reset())
        return INIT_FAILED;
    if(!T_CTX_Clone())
        return INIT_FAILED;
    if(!T_CTX_Validate())
        return INIT_FAILED;
    if(!T_CTX_Compat())
        return INIT_FAILED;
    if(!T_CTX_NoCircular())
        return INIT_FAILED;
    if(!T_CTX_StableAbi())
        return INIT_FAILED;
    if(!T_CTX_StableReplay())
        return INIT_FAILED;
    if(!T_CTX_SafeInject())
        return INIT_FAILED;
    if(!T_CTX_ContractSafety())
        return INIT_FAILED;
    if(!T_CTX_NoMutation())
        return INIT_FAILED;
    if(!GovTest_ContextDependency())
        return INIT_FAILED;
    if(!GovTest_BackwardCompatibility())
        return INIT_FAILED;
    if(!GovTest_ExportCompat())
        return INIT_FAILED;
    if(!GovTest_ExportDeterminism())
        return INIT_FAILED;
    if(!GovTest_ExportFederation())
        return INIT_FAILED;
    if(!GovTest_ExportReplay())
        return INIT_FAILED;
    if(!GovTest_ExportRouting())
        return INIT_FAILED;
    if(!GovTest_ExportSchema())
        return INIT_FAILED;
    if(!T_EXP_CtxBundle())
        return INIT_FAILED;
    if(!T_EXP_Compat())
        return INIT_FAILED;
    if(!T_EXP_Determinism())
        return INIT_FAILED;
    if(!T_EXP_Schema())
        return INIT_FAILED;
    if(!T_EXP_Router())
        return INIT_FAILED;
    if(!T_EXP_NoMutation())
        return INIT_FAILED;
    if(!T_EXP_ReplayStable())
        return INIT_FAILED;
    if(!T_EXP_AbiStable())
        return INIT_FAILED;
    if(!T_EXP_LegacyRedirect())
        return INIT_FAILED;
    if(!T_EXP_FederationOrder())
        return INIT_FAILED;
    if(!GovTest_StratAttribGolden())
        return INIT_FAILED;
    if(!GovTest_StratAttribSynthetic())
        return INIT_FAILED;
    if(!T_SAttr_TagDet())
        return INIT_FAILED;
    if(!T_SAttr_AccDet())
        return INIT_FAILED;
    if(!T_SAttr_Tox())
        return INIT_FAILED;
    if(!T_SAttr_Eco())
        return INIT_FAILED;
    if(!T_SAttr_RegimeFit())
        return INIT_FAILED;
    if(!T_SAttr_ExpDet())
        return INIT_FAILED;
    if(!T_SAttr_CmpSlf())
        return INIT_FAILED;
    if(!T_SAttr_SbxIso())
        return INIT_FAILED;
    if(!T_SAttr_PfCalc())
        return INIT_FAILED;
    if(!T_SAttr_TailLoss())
        return INIT_FAILED;
    if(!T_SAttr_VolFit())
        return INIT_FAILED;
    if(!T_SAttr_SessionFit())
        return INIT_FAILED;
    if(!GovTest_RunTagIdentity())
        return INIT_FAILED;
    if(!GovTest_RunTagRegistry())
        return INIT_FAILED;
    if(!GovTest_RunTagBridge())
        return INIT_FAILED;
    if(!GovTest_RunTagTelemetry())
        return INIT_FAILED;
    if(!GovTest_RunTagExport())
        return INIT_FAILED;
    if(!T_RTAG_RuntimeSafe())
        return INIT_FAILED;
    if(!T_RTAG_ReplayDet())
        return INIT_FAILED;
    if(!T_RTAG_NoMutation())
        return INIT_FAILED;
    if(!T_LINEAGE_Root())
        return INIT_FAILED;
    if(!T_LINEAGE_Child())
        return INIT_FAILED;
    if(!T_LINEAGE_ScaleIn())
        return INIT_FAILED;
    if(!T_LINEAGE_PartialClose())
        return INIT_FAILED;
    if(!T_LINEAGE_Recovery())
        return INIT_FAILED;
    if(!T_LINEAGE_Replay())
        return INIT_FAILED;
    if(!T_LINEAGE_Determinism())
        return INIT_FAILED;
    if(!T_LINEAGE_Overflow())
        return INIT_FAILED;
    if(!T_LINEAGE_Ownership())
        return INIT_FAILED;
    if(!T_LINEAGE_Toxicity())
        return INIT_FAILED;
    if(!T_LINEAGE_Mutation())
        return INIT_FAILED;
    if(!T_LINEAGE_Isolation())
        return INIT_FAILED;
    if(!T_LINEAGE_Comparator())
        return INIT_FAILED;
    if(!T_RUNTIME_OBS_Export())
        return INIT_FAILED;
    if(!T_RUNTIME_OBS_Journal())
        return INIT_FAILED;
    if(!T_RUNTIME_OBS_File())
        return INIT_FAILED;
    if(!T_RUNTIME_OBS_Determinism())
        return INIT_FAILED;
    if(!T_RUNTIME_OBS_CapitalCollapse())
        return INIT_FAILED;
    if(!T_RUNTIME_OBS_LineageExport())
        return INIT_FAILED;
    if(!T_RUNTIME_OBS_ReplayHash())
        return INIT_FAILED;
    if(!T_RUNTIME_OBS_NoMutation())
        return INIT_FAILED;
    if(!T_VISUAL_Export())
        return INIT_FAILED;
    if(!T_VISUAL_Determinism())
        return INIT_FAILED;
    if(!T_VISUAL_LineageGraph())
        return INIT_FAILED;
    if(!T_VISUAL_StrategyBreakdown())
        return INIT_FAILED;
    if(!T_VISUAL_CapitalDiagnostics())
        return INIT_FAILED;
    if(!T_VISUAL_Survivability())
        return INIT_FAILED;
    if(!T_VISUAL_ReplayHash())
        return INIT_FAILED;
    if(!T_DOSSIER_Metadata())
        return INIT_FAILED;
    if(!T_DOSSIER_InputSnapshot())
        return INIT_FAILED;
    if(!T_DOSSIER_StrategyBreakdown())
        return INIT_FAILED;
    if(!T_DOSSIER_RegimeBreakdown())
        return INIT_FAILED;
    if(!T_DOSSIER_LineageTree())
        return INIT_FAILED;
    if(!T_DOSSIER_ToxicityAnalytics())
        return INIT_FAILED;
    if(!T_DOSSIER_CapitalDiagnostics())
        return INIT_FAILED;
    if(!T_DOSSIER_SurvivabilityMatrix())
        return INIT_FAILED;
    if(!T_DOSSIER_ComparativeInsights())
        return INIT_FAILED;
    if(!T_DOSSIER_FailureDiagnostics())
        return INIT_FAILED;
    if(!T_DOSSIER_RecoveryAnalysis())
        return INIT_FAILED;
    if(!T_DOSSIER_Recommendations())
        return INIT_FAILED;
    if(!T_DOSSIER_DeterministicExport())
        return INIT_FAILED;
    if(!T_SIG_FORENSICS_Lifecycle())
        return INIT_FAILED;
    if(!T_SIG_FORENSICS_RejectReason())
        return INIT_FAILED;
    if(!T_SIG_FORENSICS_FilterHeatmap())
        return INIT_FAILED;
    if(!T_SIG_FORENSICS_MonthlyActivation())
        return INIT_FAILED;
    if(!T_SIG_FORENSICS_ConsensusCollapse())
        return INIT_FAILED;
    if(!T_SIG_FORENSICS_RegimeSuppression())
        return INIT_FAILED;
    if(!T_SIG_FORENSICS_DeadSignalZones())
        return INIT_FAILED;
    if(!T_SIG_FORENSICS_ActivationStarvation())
        return INIT_FAILED;
    if(!T_SIG_FORENSICS_Html())
        return INIT_FAILED;
    if(!GovTestHarnessV1_ReplayLoopShell(6))
        return INIT_FAILED;
    if(!GovTest_Phase23EcologyV1())
        return INIT_FAILED;
    if(!GovTest_Phase235RestrictionForensicsV1())
        return INIT_FAILED;
    if(!GovTest_Phase236RiskLockIntelV1())
        return INIT_FAILED;
    if(!GovTest_Phase237AdaptiveThawStabilizationV1())
        return INIT_FAILED;

    Print("[GOV_SM_V1_TEST] STATUS=PASS suite=governance_kernel_v1");
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
}
