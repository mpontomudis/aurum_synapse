//+------------------------------------------------------------------+
//| GovernanceReplayParserV1.mqh                                   |
//| Forensic UTF-8/LF parsers for frozen GOV_*V1 pipe schemas.       |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REPLAY_PARSER_V1_MQH__
#define __AURUM_GOV_REPLAY_PARSER_V1_MQH__

#include "GovernanceReplayDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernanceTelemetryV1.mqh"
#include "../GovernanceStateMachineV1/GovernanceTelemetryEventsV1.mqh"
#include "../GovernanceEvidenceIntegrationV1/GovernanceEvidenceAttribTelemetryV1.mqh"
#include "../GovernanceOrchestrationV1/GovernanceExecutionTelemetryV1.mqh"

enum ENUM_GOV_REPLAY_LINE_KIND_V1 {
    GOV_REPLAY_LINE_UNKNOWN = 0,
    GOV_REPLAY_LINE_TEL_V1 = 1,
    GOV_REPLAY_LINE_EVT_V1 = 2,
    GOV_REPLAY_LINE_ATTRIB_V1 = 3,
    GOV_REPLAY_LINE_EXEC_V1 = 4
};

void GovernanceReplayParserV1_NormalizeLf(const string in, string &out) {
    out = in;
    StringReplace(out, "\r\n", "\n");
    StringReplace(out, "\r", "\n");
}

bool GovernanceReplayParserV1_ParseU64Dec(const string s, ulong &outv) {
    outv = 0;
    if(StringLen(s) < 1)
        return false;
    const long v = StringToInteger(s);
    if(v < 0)
        return false;
    outv = (ulong)v;
    return true;
}

int GovernanceReplayParserV1_ClassifyLine(const string line) {
    if(StringLen(line) < 1)
        return GOV_REPLAY_LINE_UNKNOWN;
    string parts[];
    const ushort sep = StringGetCharacter("|", 0);
    const int n = StringSplit(line, sep, parts);
    if(n == GOV_TEL_EXPECTED_PIPE_FIELDS)
        return GOV_REPLAY_LINE_TEL_V1;
    if(n == GOV_EVT_V1_EXPECTED_PIPE_FIELDS)
        return GOV_REPLAY_LINE_EVT_V1;
    if(n >= 1 && parts[0] == "GOV_ATTRIB_V1" && n == GOV_ATTRIB_V1_EXPECTED_PIPE_FIELDS)
        return GOV_REPLAY_LINE_ATTRIB_V1;
    if(n >= 1 && parts[0] == "GOV_EXEC_V1" && n == GOV_EXEC_V1_EXPECTED_PIPE_FIELDS)
        return GOV_REPLAY_LINE_EXEC_V1;
    return GOV_REPLAY_LINE_UNKNOWN;
}

bool GovernanceReplayParserV1_ParseMultilineUtf8Lf(const string utf8_lf,
                                                   SGovReplayTimelineV1 &out_timeline,
                                                   string &out_err) {
    out_err = "";
    GovernanceReplayDatasetV1_InitTimeline(out_timeline);
    string norm = "";
    GovernanceReplayParserV1_NormalizeLf(utf8_lf, norm);
    if(!GovCryptoV1_Sha256Utf8StringToHexLower(norm, out_timeline.source_concat_sha256_hex))
        return false;

    string lines[];
    const int nlines = StringSplit(norm, '\n', lines);
    ulong carry_epoch = 0;
    for(int li = 0; li < nlines; li++) {
        string ln = lines[li];
        StringTrimLeft(ln);
        StringTrimRight(ln);
        if(StringLen(ln) < 1)
            continue;
        string parts[];
        const ushort sep = StringGetCharacter("|", 0);
        const int nf = StringSplit(ln, sep, parts);
        const int kind = GovernanceReplayParserV1_ClassifyLine(ln);
        SGovReplayEpochV1 patch;
        GovernanceReplayDatasetV1_InitEpoch(patch);
        ulong ep = 0;
        if(kind == GOV_REPLAY_LINE_UNKNOWN) {
            out_timeline.integrity_ok = 0;
            out_timeline.integrity_detail = "GOV_REPLAY_PARSE_UNKNOWN_LINE";
            out_err = out_timeline.integrity_detail;
            return false;
        }
        if(kind == GOV_REPLAY_LINE_TEL_V1) {
            if(!GovernanceReplayParserV1_ParseU64Dec(parts[0], ep))
                return false;
            carry_epoch = ep;
            patch.epoch_id = ep;
            patch.governance_state = (int)StringToInteger(parts[2]);
            patch.toxicity_ms = (int)StringToInteger(parts[5]);
            patch.survivability_ms = (int)StringToInteger(parts[6]);
            patch.policy_fingerprint = parts[11];
        } else if(kind == GOV_REPLAY_LINE_EVT_V1) {
            if(!GovernanceReplayParserV1_ParseU64Dec(parts[3], ep))
                return false;
            carry_epoch = ep;
            patch.epoch_id = ep;
            if(!GovernanceReplayParserV1_ParseU64Dec(parts[4], patch.campaign_uuid))
                patch.campaign_uuid = 0;
            patch.governance_state = (int)StringToInteger(parts[7]);
            patch.causal_pressure_ms = (int)StringToInteger(parts[11]);
            patch.toxicity_ms = (int)StringToInteger(parts[9]);
            patch.survivability_ms = (int)StringToInteger(parts[10]);
            patch.causal_reason_code = (int)StringToInteger(parts[14]);
            patch.risk_multiplier_milli = (int)StringToInteger(parts[17]);
            patch.throttle_interval_ms = (int)StringToInteger(parts[18]);
            patch.policy_fingerprint = parts[5];
        } else if(kind == GOV_REPLAY_LINE_ATTRIB_V1) {
            if(carry_epoch == 0) {
                out_timeline.integrity_ok = 0;
                out_timeline.integrity_detail = "GOV_REPLAY_PARSE_ATTRIB_ORPHAN";
                out_err = out_timeline.integrity_detail;
                return false;
            }
            patch.epoch_id = carry_epoch;
            patch.regime_state = (int)StringToInteger(parts[3]);
            patch.dominant_evidence_id = (int)StringToInteger(parts[4]);
            patch.causal_reason_code = (int)StringToInteger(parts[8]);
            patch.toxicity_ms = (int)StringToInteger(parts[10]);
            patch.survivability_ms = (int)StringToInteger(parts[11]);
            patch.structural_instability_ms = (int)StringToInteger(parts[12]);
            if(!GovernanceReplayParserV1_ParseU64Dec(parts[13], patch.campaign_uuid))
                patch.campaign_uuid = 0;
            patch.evidence_fingerprint = parts[9];
        } else if(kind == GOV_REPLAY_LINE_EXEC_V1) {
            if(!GovernanceReplayParserV1_ParseU64Dec(parts[18], ep))
                return false;
            carry_epoch = ep;
            patch.epoch_id = ep;
            patch.governance_state = (int)StringToInteger(parts[3]);
            patch.regime_state = (int)StringToInteger(parts[4]);
            patch.throttle_interval_ms = (int)StringToInteger(parts[5]);
            patch.cooldown_epochs = (int)StringToInteger(parts[6]);
            patch.exposure_cap_milli = (int)StringToInteger(parts[7]);
            patch.risk_multiplier_milli = (int)StringToInteger(parts[8]);
            patch.quarantine_state = (int)StringToInteger(parts[9]);
            patch.survivability_emergency = (int)StringToInteger(parts[10]);
            patch.execution_allowed = (int)StringToInteger(parts[11]);
            patch.entry_allowed = (int)StringToInteger(parts[12]);
            patch.recovery_allowed = (int)StringToInteger(parts[13]);
            patch.forced_flatten_required = (int)StringToInteger(parts[14]);
            patch.causal_reason_code = (int)StringToInteger(parts[15]);
            if(!GovernanceReplayParserV1_ParseU64Dec(parts[16], patch.campaign_uuid))
                patch.campaign_uuid = 0;
            patch.evidence_fingerprint = parts[17];
            patch.policy_fingerprint = parts[19];
        }
        if(!GovernanceReplayDatasetV1_AppendOrMergeEpoch(out_timeline, patch, ln, out_err))
            return false;
    }
    GovernanceReplayDatasetV1_SortEpochsByIdDeterministic(out_timeline);
    if(!GovernanceReplayDatasetV1_BuildCampaignRollups(out_timeline, out_err))
        return false;
    return true;
}

#endif // __AURUM_GOV_REPLAY_PARSER_V1_MQH__
