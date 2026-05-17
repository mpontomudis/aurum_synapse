//+------------------------------------------------------------------+
//| GovernanceExecutionTelemetryV1.mqh                            |
//| GOV_EXEC_V1 append-only execution governance telemetry.         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EXEC_TELEMETRY_V1_MQH__
#define __AURUM_GOV_EXEC_TELEMETRY_V1_MQH__

#include "../GovernanceStateMachineV1/GovernanceTelemetryV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "GovernanceExecutionContractV1.mqh"
#include "GovernanceQuarantineEngineV1.mqh"

#define GOV_EXEC_V1_SCHEMA_MAJOR 1
#define GOV_EXEC_V1_SCHEMA_MINOR 0
#define GOV_EXEC_V1_EXPECTED_PIPE_FIELDS 20

int GovernanceExecutionTelemetryV1_CountPipeFields(const string line) {
    if(StringLen(line) == 0)
        return 0;
    string parts[];
    const ushort sep = StringGetCharacter("|", 0);
    return StringSplit(line, sep, parts);
}

string GovernanceExecutionTelemetryV1_PolicyFingerprintPrefix16(const string sha256_hex_lower) {
    if(StringLen(sha256_hex_lower) < 16)
        return "";
    return StringSubstr(sha256_hex_lower, 0, 16);
}

bool GovernanceExecutionTelemetryV1_FormatLine(const SGovernanceExecutionContractV1 &c,
                                              const int throttle_ms,
                                              const ENUM_GOV_EXEC_QUARANTINE_V1 q,
                                              const ulong campaign_uuid,
                                              string &out_line) {
    out_line = "";
    if(GovTelemetryV1_StringHasForbiddenDelims(c.policy_fingerprint) ||
       GovTelemetryV1_StringHasForbiddenDelims(c.evidence_fingerprint))
        return false;
    const string pol16 = GovernanceExecutionTelemetryV1_PolicyFingerprintPrefix16(c.policy_fingerprint);
    if(StringLen(pol16) != 16)
        return false;
    out_line = "GOV_EXEC_V1";
    out_line += "|" + IntegerToString(GOV_EXEC_V1_SCHEMA_MAJOR);
    out_line += "|" + IntegerToString(GOV_EXEC_V1_SCHEMA_MINOR);
    out_line += "|" + IntegerToString((int)c.governance_state);
    out_line += "|" + IntegerToString((int)c.regime_state);
    out_line += "|" + IntegerToString(GovClampInt32(throttle_ms, 0, 1000000));
    out_line += "|" + IntegerToString(GovClampInt32(c.cooldown_epochs, 0, 1000000));
    out_line += "|" + IntegerToString(GovClampInt32(c.exposure_cap_milli, 0, 1000000000));
    out_line += "|" + IntegerToString(GovClampInt32(c.risk_multiplier_milli, 0, 1000000));
    out_line += "|" + IntegerToString((int)q);
    out_line += "|" + IntegerToString((int)c.survivability_emergency);
    out_line += "|" + IntegerToString((int)c.execution_allowed);
    out_line += "|" + IntegerToString((int)c.entry_allowed);
    out_line += "|" + IntegerToString((int)c.recovery_allowed);
    out_line += "|" + IntegerToString((int)c.forced_flatten_required);
    out_line += "|" + IntegerToString(GovClampInt32(c.causal_reason_code, -1000000, 1000000));
    out_line += "|" + GovernanceTelemetryV1_FormatU64Dec(campaign_uuid);
    out_line += "|" + c.evidence_fingerprint;
    out_line += "|" + IntegerToString((long)c.contract_epoch);
    out_line += "|" + pol16;
    if(GovernanceExecutionTelemetryV1_CountPipeFields(out_line) != GOV_EXEC_V1_EXPECTED_PIPE_FIELDS)
        return false;
    return true;
}

bool GovernanceExecutionTelemetryV1_AppendUtf8LfCommon(const string relPathFromCommonFiles, const string lineUtf8NoCrLf) {
    if(StringLen(relPathFromCommonFiles) == 0)
        return true;
    string w = lineUtf8NoCrLf;
    GovernanceTelemetryV1_StripLineBreaks(w);
    uchar body[];
    const string payload = w + "\n";
    const int plen = StringLen(payload);
    const int n = (plen <= 0) ? 0 : StringToCharArray(payload, body, 0, plen, CP_UTF8);
    if(n <= 0)
        return false;
    const int h = FileOpen(relPathFromCommonFiles, FILE_READ | FILE_WRITE | FILE_BIN | FILE_COMMON);
    if(h == INVALID_HANDLE)
        return false;
    FileSeek(h, 0, SEEK_END);
    const uint wb = FileWriteArray(h, body, 0, n);
    FileClose(h);
    return (wb == (uint)n);
}

#endif // __AURUM_GOV_EXEC_TELEMETRY_V1_MQH__
