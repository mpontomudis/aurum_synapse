//+------------------------------------------------------------------+
//|                                 TestTelemetryJoinValidation.mq5  |
//|     Phase 3B — golden fixture harness (Case_001 + Case_002)      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "1.00"
#property description "Phase 3B join validation — read-only, no EA hooks"

#include "../TelemetryAnalytics/JoinValidationPrototype.mqh"

//+------------------------------------------------------------------+
bool JoinVal_FileExistsCommon(const string relPath) {
    return FileIsExist(relPath, FILE_COMMON);
}

//+------------------------------------------------------------------+
bool JoinVal_ReadTelemetryParts(const string root, string &parts[]) {
    ArrayResize(parts, 0);
    string txt = "";
    const string p = root + "telemetry.csv";
    if(!JoinValidation_ReadUtf8FileLf(p, txt))
        return false;
    string hdr, line;
    if(!JoinValidation_SplitFirstDataLine(txt, hdr, line))
        return false;
    if(!CsvTelemetry_PrepareFieldsFromLine(line, parts))
        return false;
    return (ArraySize(parts) == TelemetryCsvV1_ExpectedColumns());
}

//+------------------------------------------------------------------+
bool JoinVal_RunOneCase(const string caseName, const string root, const string joinerBuild, const bool expectOrphan) {
    Print("[JOIN_VALIDATION] CASE=", caseName);
    Print("[JOIN_VALIDATION] fixture_root=", JoinValidation_CommonFixtureAbsoluteRoot());
    Print("[JOIN_VALIDATION] case_root=", root);

    const bool exTel = JoinVal_FileExistsCommon(root + "telemetry.csv");
    const bool exDeal = JoinVal_FileExistsCommon(root + "deals.csv");
    const bool exJoined = JoinVal_FileExistsCommon(root + "expected_joined.csv");
    const bool exVal = JoinVal_FileExistsCommon(root + "expected_validation.json");
    Print("[JOIN_VALIDATION] telemetry_exists=", (exTel ? "true" : "false"));
    Print("[JOIN_VALIDATION] deals_exists=", (exDeal ? "true" : "false"));
    Print("[JOIN_VALIDATION] expected_joined_exists=", (exJoined ? "true" : "false"));
    Print("[JOIN_VALIDATION] expected_validation_exists=", (exVal ? "true" : "false"));

    if(!exTel || !exDeal || !exJoined || !exVal) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=missing_fixture_files");
        return false;
    }

    string parts[];
    if(!JoinVal_ReadTelemetryParts(root, parts)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=telemetry_parse");
        return false;
    }

    string dealsTxt = "";
    if(!JoinValidation_ReadUtf8FileLf(root + "deals.csv", dealsTxt)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=deals_read");
        return false;
    }

    ulong d_ticket = 0;
    ulong d_pos = 0;
    string d_sym = "";
    long d_magic = 0;
    long d_tutc = 0;
    double d_vol = 0.0;
    double d_profit = 0.0;
    int d_type = 0;
    int d_entry = 0;
    double d_price = 0.0;
    double d_comm = 0.0;
    double d_swap = 0.0;
    int d_reason = 0;
    if(!JoinValidation_ParseDealCsv(dealsTxt, d_ticket, d_sym, d_magic, d_tutc, d_vol, d_profit,
                                    d_type, d_entry, d_pos, d_price, d_comm, d_swap, d_reason)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=deal_parse");
        return false;
    }

    string joined = "";
    if(!JoinValidation_BuildJoinedSlimCase001(parts, d_tutc, d_ticket, d_pos, d_magic, d_vol, d_price,
                                              d_profit, d_comm, d_swap, d_type, d_entry, d_reason, joinerBuild, joined)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=join_build");
        return false;
    }

    const bool isOrphan = (StringFind(joined, ",ORPHAN_DEAL,", 0) >= 0);
    if(expectOrphan && !isOrphan) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_orphan_missing");
        Print("[JOIN_VALIDATION] actual  =", joined);
        return false;
    }
    if(!expectOrphan && isOrphan) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=unexpected_orphan");
        Print("[JOIN_VALIDATION] actual  =", joined);
        return false;
    }

    string expJoinedTxt = "";
    if(!JoinValidation_ReadUtf8FileLf(root + "expected_joined.csv", expJoinedTxt)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_read");
        return false;
    }
    string ejHdr, ejData;
    if(!JoinValidation_SplitFirstDataLine(expJoinedTxt, ejHdr, ejData)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_split");
        return false;
    }

    if(joined != ejData) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=line_mismatch");
        Print("[JOIN_VALIDATION] expected=", ejData);
        Print("[JOIN_VALIDATION] actual  =", joined);
        return false;
    }

    if(expectOrphan)
        Print("[JOIN_VALIDATION] STATUS=PASS rows=1 orphan=1");
    else
        Print("[JOIN_VALIDATION] STATUS=PASS rows=1 join=OK");
    return true;
}

//+------------------------------------------------------------------+
int OnInit() {
    if(!JoinVal_RunOneCase("Case_001_BasicJoin", JoinValidation_FixtureCase001Root(), JOIN_VALIDATION_JOINER_BUILD_001, false))
        return INIT_FAILED;
    if(!JoinVal_RunOneCase("Case_002_OrphanDeal", JoinValidation_FixtureCase002Root(), JOIN_VALIDATION_JOINER_BUILD_002, true))
        return INIT_FAILED;
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnTick() {
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
}
