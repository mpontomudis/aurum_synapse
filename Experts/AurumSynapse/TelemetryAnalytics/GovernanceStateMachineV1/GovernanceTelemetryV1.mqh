//+------------------------------------------------------------------+
//| GovernanceTelemetryV1.mqh                                      |
//| Governance transcript kernel — byte-stable, append-only.         |
//| Normative: PHASE_8A_GOVERNANCE_STATE_MACHINE_IMPLEMENTATION_SPEC  |
//|            §6 (field order frozen)                               |
//| Serialization: UTF-8 via StringToCharArray(CP_UTF8); fields      |
//| separated by ASCII `|` (0x7C); one LF (0x0A) per appended row. |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_TELEMETRY_V1_MQH__
#define __AURUM_GOV_TELEMETRY_V1_MQH__

#include "GovernanceTypesV1.mqh"
#include "GovernanceCryptoV1.mqh"

//+------------------------------------------------------------------+
//| Decimal string for ulong — portable (no LongToString dependency).|
//+------------------------------------------------------------------+
string GovernanceTelemetryV1_FormatU64Dec(const ulong v) {
    return StringFormat("%I64u", v);
}

#define GOV_TEL_EXPECTED_PIPE_FIELDS 13

#define GOV_TEL_FIELD_1_GOV_EPOCH 1
#define GOV_TEL_FIELD_2_GS_PREV 2
#define GOV_TEL_FIELD_3_GS_CUR 3
#define GOV_TEL_FIELD_4_TRANS_REASON 4
#define GOV_TEL_FIELD_5_EVIDENCE_MS 5
#define GOV_TEL_FIELD_6_TOX_MS 6
#define GOV_TEL_FIELD_7_SURV_MS 7
#define GOV_TEL_FIELD_8_CONF_MS 8
#define GOV_TEL_FIELD_9_QUAR_SEV 9
#define GOV_TEL_FIELD_10_POLICY_ID 10
#define GOV_TEL_FIELD_11_POLICY_SEMVER 11
#define GOV_TEL_FIELD_12_POLICY_CHECKSUM 12
#define GOV_TEL_FIELD_13_L0_FP 13

//+------------------------------------------------------------------+
//| Reject delimiter / newline leakage into string fields (replay).   |
//+------------------------------------------------------------------+
bool GovTelemetryV1_StringHasForbiddenDelims(const string s) {
    if(StringFind(s, "|") >= 0)
        return true;
    if(StringFind(s, "\n") >= 0)
        return true;
    if(StringFind(s, "\r") >= 0)
        return true;
    return false;
}

//+------------------------------------------------------------------+
//| Count fields split by ASCII '|' (must equal 13 for v1 row).      |
//+------------------------------------------------------------------+
int GovernanceTelemetryV1_CountPipeFields(const string line) {
    if(StringLen(line) == 0)
        return 0;
    string parts[];
    const ushort sep = StringGetCharacter("|", 0);
    return StringSplit(line, sep, parts);
}

//+------------------------------------------------------------------+
//| FormatLine — deterministic `|` join; UTF-8 encoding at write time.|
//+------------------------------------------------------------------+
bool GovernanceTelemetryV1_FormatLine(SGovernanceTelemetryRowV1 &row, string &out_line) {
    out_line = "";
    if(GovTelemetryV1_StringHasForbiddenDelims(row.policy_id) ||
       GovTelemetryV1_StringHasForbiddenDelims(row.policy_semver) ||
       GovTelemetryV1_StringHasForbiddenDelims(row.policy_checksum_sha256_hex) ||
       GovTelemetryV1_StringHasForbiddenDelims(row.l0_fingerprint_sha256_hex))
        return false;

    out_line = GovernanceTelemetryV1_FormatU64Dec(row.gov_epoch);
    out_line += "|" + IntegerToString((int)row.gs_previous);
    out_line += "|" + IntegerToString((int)row.gs_current);
    out_line += "|" + IntegerToString((int)row.transition_reason);
    out_line += "|" + IntegerToString((int)row.evidence_ms);
    out_line += "|" + IntegerToString((int)row.toxicity_ms);
    out_line += "|" + IntegerToString((int)row.survivability_ms);
    out_line += "|" + IntegerToString((int)row.confidence_ms);
    out_line += "|" + IntegerToString((int)row.quarantine_severity);
    out_line += "|" + row.policy_id;
    out_line += "|" + row.policy_semver;
    out_line += "|" + row.policy_checksum_sha256_hex;
    out_line += "|" + row.l0_fingerprint_sha256_hex;

    if(GovernanceTelemetryV1_CountPipeFields(out_line) != GOV_TEL_EXPECTED_PIPE_FIELDS)
        return false;
    return true;
}

//+------------------------------------------------------------------+
//| Strip CR/LF from a single logical line before append.            |
//+------------------------------------------------------------------+
void GovernanceTelemetryV1_StripLineBreaks(string &line) {
    StringReplace(line, "\r\n", "");
    StringReplace(line, "\n", "");
    StringReplace(line, "\r", "");
}

//+------------------------------------------------------------------+
//| Append one transcript row: UTF-8 bytes of (line + '\n').       |
//| Empty path → success, no I/O (explicit no-op contract).          |
//+------------------------------------------------------------------+
bool GovernanceTelemetryV1_AppendTranscriptLine(const string file_path, const string line) {
    if(StringLen(file_path) == 0)
        return true;
    string w = line;
    GovernanceTelemetryV1_StripLineBreaks(w);
    uchar body[];
    const string payload = w + "\n";
    const int plen = StringLen(payload);
    const int n = (plen <= 0) ? 0 : StringToCharArray(payload, body, 0, plen, CP_UTF8);
    if(n <= 0)
        return false;
    const int h = FileOpen(file_path, FILE_READ | FILE_WRITE | FILE_BIN);
    if(h == INVALID_HANDLE)
        return false;
    FileSeek(h, 0, SEEK_END);
    const uint wb = FileWriteArray(h, body, 0, n);
    FileClose(h);
    return (wb == (uint)n);
}

//+------------------------------------------------------------------+
//| SHA-256 over normalized UTF-8 transcript blob (caller concat).   |
//| Normalization: CRLF→LF, lone CR→LF (deterministic line endings).|
//+------------------------------------------------------------------+
bool GovernanceTelemetryV1_TranscriptSha256Hex(const string utf8_concat, string &out_hex_lower) {
    string t = utf8_concat;
    StringReplace(t, "\r\n", "\n");
    StringReplace(t, "\r", "\n");
    return GovCryptoV1_Sha256Utf8StringToHexLower(t, out_hex_lower);
}

#endif // __AURUM_GOV_TELEMETRY_V1_MQH__
