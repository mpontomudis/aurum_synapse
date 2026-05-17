//+------------------------------------------------------------------+
//| GovernanceTelemetryEventsV1.mqh                                |
//| Append-only governance event rows — UTF-8, ASCII `|`, LF suffix. |
//| Canonical field order is normative for replay manifests.         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_TELEMETRY_EVENTS_V1_MQH__
#define __AURUM_GOV_TELEMETRY_EVENTS_V1_MQH__

#include "GovernanceTypesV1.mqh"
#include "GovernanceEvidenceV1.mqh"
#include "GovernanceTelemetryV1.mqh"

#define GOV_EVT_V1_SCHEMA_MAJOR 1
#define GOV_EVT_V1_SCHEMA_MINOR 0
#define GOV_EVT_V1_EXPECTED_PIPE_FIELDS 19

//+------------------------------------------------------------------+
int GovTelemetryEventsV1_CountPipeFields(const string line) {
    if(StringLen(line) == 0)
        return 0;
    string parts[];
    const ushort sep = StringGetCharacter("|", 0);
    return StringSplit(line, sep, parts);
}

//+------------------------------------------------------------------+
bool GovTelemetryEventsV1_FormatLine(const ENUM_GOV_EVENT_TYPE_V1 evt,
                                     const ulong gov_epoch,
                                     const ulong lifecycle_campaign_id,
                                     const string policy_checksum_sha256_hex_lower,
                                     const uchar gs_old,
                                     const uchar gs_new,
                                     SEvidenceOutputV1 &ev,
                                     const int causal_explanation_code,
                                     const int causal_flags_bits,
                                     const ushort transition_reason,
                                     const int risk_mult_milli,
                                     const int throttle_level_ms,
                                     string &out_line) {
    out_line = "";
    if(GovTelemetryV1_StringHasForbiddenDelims(policy_checksum_sha256_hex_lower))
        return false;

    out_line = IntegerToString(GOV_EVT_V1_SCHEMA_MAJOR);
    out_line += "|" + IntegerToString(GOV_EVT_V1_SCHEMA_MINOR);
    out_line += "|" + IntegerToString((int)evt);
    out_line += "|" + GovernanceTelemetryV1_FormatU64Dec(gov_epoch);
    out_line += "|" + GovernanceTelemetryV1_FormatU64Dec(lifecycle_campaign_id);
    out_line += "|" + policy_checksum_sha256_hex_lower;
    out_line += "|" + IntegerToString((int)gs_old);
    out_line += "|" + IntegerToString((int)gs_new);
    out_line += "|" + IntegerToString(GovClampInt32(ev.evidence_ms, 0, 1000000));
    out_line += "|" + IntegerToString(GovClampInt32(ev.e_tox_ms, 0, 1000000));
    out_line += "|" + IntegerToString(GovClampInt32(ev.e_surv_ms, 0, 1000000));
    out_line += "|" + IntegerToString(GovClampInt32(ev.e_causal_ms, 0, 1000000));
    out_line += "|" + IntegerToString(GovClampInt32(ev.e_conf_ms, 0, 1000000));
    out_line += "|" + IntegerToString(GovClampInt32(ev.e_q_ms, 0, 1000000));
    out_line += "|" + IntegerToString(causal_explanation_code);
    out_line += "|" + IntegerToString(GovClampInt32(causal_flags_bits, 0, 65535));
    out_line += "|" + IntegerToString((int)transition_reason);
    out_line += "|" + IntegerToString(GovClampInt32(risk_mult_milli, 0, 1000000));
    out_line += "|" + IntegerToString(GovClampInt32(throttle_level_ms, 0, 1000000));

    if(GovTelemetryEventsV1_CountPipeFields(out_line) != GOV_EVT_V1_EXPECTED_PIPE_FIELDS)
        return false;
    return true;
}

//+------------------------------------------------------------------+
bool GovTelemetryEventsV1_Append(string &accum, const string one_line) {
    if(StringLen(one_line) == 0)
        return false;
    if(GovTelemetryEventsV1_CountPipeFields(one_line) != GOV_EVT_V1_EXPECTED_PIPE_FIELDS)
        return false;
    if(StringLen(accum) > 0)
        accum += "\n";
    accum += one_line;
    return true;
}

#endif // __AURUM_GOV_TELEMETRY_EVENTS_V1_MQH__
