//+------------------------------------------------------------------+
//| GovernanceEvidenceAttribTelemetryV1.mqh                         |
//| Parallel append-only attribution rows (does NOT alter GOV_EVT).|
//| Record prefix: GOV_ATTRIB_V1 — fixed pipe field count.         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EVID_ATTRIB_TEL_V1_MQH__
#define __AURUM_GOV_EVID_ATTRIB_TEL_V1_MQH__

#include "../GovernanceStateMachineV1/GovernanceTelemetryV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "GovernanceL0RuntimeEvidenceV1.mqh"
#include "GovernanceEvidenceIntegrationTypesV1.mqh"
#include "GovernanceRegimeClassifierV1.mqh"

#define GOV_ATTRIB_V1_SCHEMA_MAJOR 1
#define GOV_ATTRIB_V1_SCHEMA_MINOR 0
#define GOV_ATTRIB_V1_EXPECTED_PIPE_FIELDS 15

int GovEvidenceAttribTelemetryV1_CountPipeFields(const string line) {
    if(StringLen(line) == 0)
        return 0;
    string parts[];
    const ushort sep = StringGetCharacter("|", 0);
    return StringSplit(line, sep, parts);
}

//+------------------------------------------------------------------+
//| GOV_ATTRIB_V1|maj|min|regime|dom|fusion|toxbits|sv|causal|fp|   |
//| toxm|survm|strucm|camp_u64_dec                                 |
//+------------------------------------------------------------------+
bool GovEvidenceAttribTelemetryV1_FormatLine(const SGovL0RuntimeEvidenceV1 &rt,
                                             const ushort fusion_path,
                                             const ENUM_GOV_DOMINANT_EVIDENCE_SRC_V1 dom,
                                             const int tox_bits,
                                             const int surv_src,
                                             const int causal_code,
                                             const ENUM_GOV_MARKET_REGIME_V1 regime,
                                             const string fp8_lower,
                                             const ENUM_TOXICITY_STATE_V1 tx_st,
                                             string &out_line) {
    out_line = "";
    if(GovTelemetryV1_StringHasForbiddenDelims(fp8_lower))
        return false;
    out_line = "GOV_ATTRIB_V1";
    out_line += "|" + IntegerToString(GOV_ATTRIB_V1_SCHEMA_MAJOR);
    out_line += "|" + IntegerToString(GOV_ATTRIB_V1_SCHEMA_MINOR);
    out_line += "|" + IntegerToString((int)regime);
    out_line += "|" + IntegerToString((int)dom);
    out_line += "|" + IntegerToString((int)fusion_path);
    out_line += "|" + IntegerToString(tox_bits);
    out_line += "|" + IntegerToString(surv_src);
    out_line += "|" + IntegerToString(causal_code);
    out_line += "|" + fp8_lower;
    out_line += "|" + IntegerToString(GovClampInt32(rt.toxicity_score_ms, 0, 1000000));
    out_line += "|" + IntegerToString(GovClampInt32(rt.survivability_score_ms, 0, 1000000));
    out_line += "|" + IntegerToString(GovClampInt32(rt.structural_instability_ms, 0, 1000000));
    out_line += "|" + GovernanceTelemetryV1_FormatU64Dec(rt.lifecycle_id);
    out_line += "|" + IntegerToString((int)tx_st);
    if(GovEvidenceAttribTelemetryV1_CountPipeFields(out_line) != GOV_ATTRIB_V1_EXPECTED_PIPE_FIELDS)
        return false;
    return true;
}

#endif // __AURUM_GOV_EVID_ATTRIB_TEL_V1_MQH__
