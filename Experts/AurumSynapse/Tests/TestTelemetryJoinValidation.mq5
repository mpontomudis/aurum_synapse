//+------------------------------------------------------------------+
//|                                 TestTelemetryJoinValidation.mq5  |
//|     Phase 3B — golden fixture harness (Case_001–010)             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "1.00"
#property description "Phase 3B join validation — read-only, no EA hooks"

#include "../TelemetryAnalytics/JoinValidationPrototype.mqh"

//+------------------------------------------------------------------+
//| TEMP (Case_009 forensic): byte + CSV token diff on mismatch only. |
//+------------------------------------------------------------------+
void JoinVal_ForensicCsvMismatchCase009(const int rowIdx, const string exp, const string act) {
    Print("[JOIN_VALIDATION_FORENSIC] case=Case_009_MultiDealPositionAttribution row=", IntegerToString(rowIdx));
    const int el = StringLen(exp);
    const int al = StringLen(act);
    Print("[JOIN_VALIDATION_FORENSIC] expected_len=", IntegerToString(el), " actual_len=", IntegerToString(al));
    const ushort bom = (ushort)0xFEFF;
    if(el > 0 && (ushort)StringGetCharacter(exp, 0) == bom)
        Print("[JOIN_VALIDATION_FORENSIC] expected_bom=1");
    if(al > 0 && (ushort)StringGetCharacter(act, 0) == bom)
        Print("[JOIN_VALIDATION_FORENSIC] actual_bom=1");
    int firstDiff = -1;
    ushort ec = 0;
    ushort ac = 0;
    const int minch = (el < al ? el : al);
    for(int p = 0; p < minch; p++) {
        const ushort ce = (ushort)StringGetCharacter(exp, p);
        const ushort ca = (ushort)StringGetCharacter(act, p);
        if(ce != ca) {
            firstDiff = p;
            ec = ce;
            ac = ca;
            break;
        }
    }
    if(firstDiff < 0 && el != al)
        firstDiff = minch;
    if(firstDiff >= 0) {
        Print("[JOIN_VALIDATION_FORENSIC] first_diff_index=", IntegerToString(firstDiff));
        Print("[JOIN_VALIDATION_FORENSIC] expected_char_u16=", IntegerToString((int)ec),
              " actual_char_u16=", IntegerToString((int)ac));
        int commas = 0;
        for(int q = 0; q < firstDiff && q < el; q++) {
            if((ushort)StringGetCharacter(exp, q) == (ushort)',')
                commas++;
        }
        Print("[JOIN_VALIDATION_FORENSIC] token_index_0based_prefix_commas=", IntegerToString(commas));
    } else {
        Print("[JOIN_VALIDATION_FORENSIC] first_diff_index=(none) identical_prefix_same_length?");
    }
    string expTok[];
    string actTok[];
    const int ne = StringSplit(exp, ',', expTok);
    const int na = StringSplit(act, ',', actTok);
    Print("[JOIN_VALIDATION_FORENSIC] token_count expected=", IntegerToString(ne), " actual=", IntegerToString(na));
    const int nmin = (ne < na ? ne : na);
    for(int k = 0; k < nmin; k++) {
        if(expTok[k] != actTok[k]) {
            Print("[JOIN_VALIDATION_FORENSIC] first_token_mismatch_index=", IntegerToString(k));
            Print("[JOIN_VALIDATION_FORENSIC] expected_token=", expTok[k]);
            Print("[JOIN_VALIDATION_FORENSIC] actual_token=", actTok[k]);
            return;
        }
    }
    if(ne != na)
        Print("[JOIN_VALIDATION_FORENSIC] first_token_mismatch_index=(prefix_equal_token_count_diff)");
}

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
bool JoinVal_ReadTelemetryBestBackwardParts(const string root, const long d_time_utc,
                                            string &parts[], int &eligibleCountOut) {
    ArrayResize(parts, 0);
    eligibleCountOut = 0;
    string txt = "";
    const string p = root + "telemetry.csv";
    if(!JoinValidation_ReadUtf8FileLf(p, txt))
        return false;
    return JoinValidation_SelectBestBackwardBarFromTelemetryText(txt, d_time_utc, parts, eligibleCountOut);
}

//+------------------------------------------------------------------+
//| passMode: 0 = first telemetry row only (Case_001);               |
//|           1 = expect ORPHAN_DEAL (Case_002);                     |
//|           2 = backward MAX over all rows, >=2 eligible (Case_003);|
//|           3 = future bar present but rejected (Case_004).        |
//|           4 = missing gap bar absent; future rejected (Case_005).|
//|           5 = duplicate d_ticket in deals.csv (Case_006).        |
//|           6 = future bar in file; UTC edge / static offset doc   |
//|               (Case_010) — same causal scan as mode 3, different |
//|               PASS journal tag.                                   |
//+------------------------------------------------------------------+
bool JoinVal_RunOneCase(const string caseName, const string root, const string joinerBuild, const int passMode) {
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
    if(passMode == 5) {
        int dupTotal = 0;
        int dupIgnored = 0;
        if(!JoinValidation_ParseDealCsvCanonicalDuplicateTicketPolicy(dealsTxt, d_ticket, d_sym, d_magic, d_tutc, d_vol, d_profit,
                                                                      d_type, d_entry, d_pos, d_price, d_comm, d_swap, d_reason,
                                                                      dupTotal, dupIgnored)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=deal_parse_duplicate_canonical");
            return false;
        }
        if(dupTotal != 2 || dupIgnored != 1) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_two_duplicate_deal_rows total=", IntegerToString(dupTotal),
                  " ignored=", IntegerToString(dupIgnored));
            return false;
        }
    } else {
        if(!JoinValidation_ParseDealCsv(dealsTxt, d_ticket, d_sym, d_magic, d_tutc, d_vol, d_profit,
                                        d_type, d_entry, d_pos, d_price, d_comm, d_swap, d_reason)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=deal_parse");
            return false;
        }
    }

    string parts[];
    int eligible = 0;
    if(passMode == 2) {
        if(!JoinVal_ReadTelemetryBestBackwardParts(root, d_tutc, parts, eligible)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=telemetry_parse_multi");
            return false;
        }
        if(eligible < 2) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_multi_eligible count=", IntegerToString(eligible));
            return false;
        }
    } else if(passMode == 3 || passMode == 6) {
        string telTxt = "";
        if(!JoinValidation_ReadUtf8FileLf(root + "telemetry.csv", telTxt)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=telemetry_read_case004");
            return false;
        }
        int dataRows = 0;
        int futureRows = 0;
        if(!JoinValidation_ScanTelemetryCausalStats(telTxt, d_tutc, dataRows, futureRows)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=telemetry_causal_scan");
            return false;
        }
        if(dataRows < 2) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_multi_telemetry_rows rows=", IntegerToString(dataRows));
            return false;
        }
        if(futureRows < 1) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_future_telemetry_row");
            return false;
        }
        if(!JoinVal_ReadTelemetryBestBackwardParts(root, d_tutc, parts, eligible)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=telemetry_parse_multi");
            return false;
        }
        if(eligible != 1) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_single_eligible count=", IntegerToString(eligible));
            return false;
        }
        const long selBar = (long)StringToInteger(parts[TCOL_BAR_UTC]);
        if(selBar >= d_tutc) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=future_leak_or_equal_bar");
            return false;
        }
    } else if(passMode == 4) {
        string telTxt = "";
        if(!JoinValidation_ReadUtf8FileLf(root + "telemetry.csv", telTxt)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=telemetry_read_case005");
            return false;
        }
        // Pinned to Case_005_MissingTelemetryRow/README + expected_validation.json
        const long kMissingGapBarUtc = 1735689900;
        const long kExpectedParentBarUtc = 1735689600;
        bool hasGapRow = false;
        if(!JoinValidation_TelemetryDataRowHasBarUtc(telTxt, kMissingGapBarUtc, hasGapRow)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=telemetry_gap_scan_parse");
            return false;
        }
        if(hasGapRow) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=unexpected_gap_row_present");
            return false;
        }
        int dataRows = 0;
        int futureRows = 0;
        if(!JoinValidation_ScanTelemetryCausalStats(telTxt, d_tutc, dataRows, futureRows)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=telemetry_causal_scan");
            return false;
        }
        if(dataRows < 2) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_multi_telemetry_rows rows=", IntegerToString(dataRows));
            return false;
        }
        if(futureRows < 1) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_future_telemetry_row");
            return false;
        }
        if(!JoinVal_ReadTelemetryBestBackwardParts(root, d_tutc, parts, eligible)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=telemetry_parse_multi");
            return false;
        }
        if(eligible != 1) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_single_eligible count=", IntegerToString(eligible));
            return false;
        }
        const long selBar5 = (long)StringToInteger(parts[TCOL_BAR_UTC]);
        if(selBar5 != kExpectedParentBarUtc) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_parent_bar_mismatch");
            return false;
        }
        if(selBar5 >= d_tutc) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=future_leak_or_equal_bar");
            return false;
        }
    } else {
        if(!JoinVal_ReadTelemetryParts(root, parts)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=telemetry_parse");
            return false;
        }
    }

    string joined = "";
    if(!JoinValidation_BuildJoinedSlimCase001(parts, d_tutc, d_ticket, d_pos, d_magic, d_vol, d_price,
                                              d_profit, d_comm, d_swap, d_type, d_entry, d_reason, joinerBuild, joined)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=join_build");
        return false;
    }

    const bool isOrphan = (StringFind(joined, ",ORPHAN_DEAL,", 0) >= 0);
    if(passMode == 1 && !isOrphan) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_orphan_missing");
        Print("[JOIN_VALIDATION] actual  =", joined);
        return false;
    }
    if(passMode != 1 && isOrphan) {
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

    if(passMode == 1)
        Print("[JOIN_VALIDATION] STATUS=PASS rows=1 orphan=1");
    else if(passMode == 2)
        Print("[JOIN_VALIDATION] STATUS=PASS rows=1 duplicate_resolved=1");
    else if(passMode == 3)
        Print("[JOIN_VALIDATION] STATUS=PASS rows=1 future_leak_prevented=1");
    else if(passMode == 6)
        Print("[JOIN_VALIDATION] STATUS=PASS rows=1 timezone_edge_validated=1");
    else if(passMode == 4)
        Print("[JOIN_VALIDATION] STATUS=PASS rows=1 missing_gap_handled=1");
    else if(passMode == 5)
        Print("[JOIN_VALIDATION] STATUS=PASS rows=1 duplicate_ticket_resolved=1");
    else
        Print("[JOIN_VALIDATION] STATUS=PASS rows=1 join=OK");
    return true;
}

//+------------------------------------------------------------------+
//| Case_007 — three partial closes, same position_id; multi-row     |
//| expected_joined.csv; deals file not pre-sorted.                 |
//+------------------------------------------------------------------+
bool JoinVal_RunCase007_PartialCloseLifecycle(void) {
    const string root = JoinValidation_FixtureCase007Root();
    const string joinerBuild = JOIN_VALIDATION_JOINER_BUILD_007;
    Print("[JOIN_VALIDATION] CASE=Case_007_PartialCloseLifecycle");
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

    string dealsTxt = "";
    if(!JoinValidation_ReadUtf8FileLf(root + "deals.csv", dealsTxt)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=deals_read");
        return false;
    }
    string dealLines[];
    if(!JoinValidation_CollectDealsCsvDataLines(dealsTxt, dealLines)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=deal_lines_collect");
        return false;
    }
    if(ArraySize(dealLines) != 3) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_three_deal_rows count=", IntegerToString(ArraySize(dealLines)));
        return false;
    }
    if(!JoinValidation_AllDealCsvLinesSharePositionId(dealLines)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=lifecycle_position_id_mismatch");
        return false;
    }
    if(!JoinValidation_SortDealCsvDataLinesByTimeThenTicket(dealLines)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=deal_sort");
        return false;
    }

    string colsPos[];
    if(StringSplit(dealLines[0], ',', colsPos) < 9) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=deal_position_parse");
        return false;
    }
    const ulong lifecyclePositionId = (ulong)StringToInteger(colsPos[8]);
    const string posNeedle = "," + IntegerToString((long)lifecyclePositionId) + ",";

    string telTxt = "";
    if(!JoinValidation_ReadUtf8FileLf(root + "telemetry.csv", telTxt)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=telemetry_read_case007");
        return false;
    }

    string expJoinedTxt = "";
    if(!JoinValidation_ReadUtf8FileLf(root + "expected_joined.csv", expJoinedTxt)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_read");
        return false;
    }
    string ejHdr = "";
    string expData[];
    if(!JoinValidation_SplitCsvHeaderAndAllDataLines(expJoinedTxt, ejHdr, expData)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_split_multi");
        return false;
    }
    if(ArraySize(expData) != 3) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_three_joined_rows n=", IntegerToString(ArraySize(expData)));
        return false;
    }

    for(int i = 0; i < 3; i++) {
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
        if(!JoinValidation_ParseDealDataRowColumns(dealLines[i], d_ticket, d_sym, d_magic, d_tutc, d_vol, d_profit,
                                                   d_type, d_entry, d_pos, d_price, d_comm, d_swap, d_reason)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=deal_parse_row idx=", IntegerToString(i));
            return false;
        }
        if(d_pos != lifecyclePositionId) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=lifecycle_position_id_row_mismatch idx=", IntegerToString(i));
            return false;
        }
        string parts[];
        int eligible = 0;
        if(!JoinValidation_SelectBestBackwardBarFromTelemetryText(telTxt, d_tutc, parts, eligible)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=telemetry_select idx=", IntegerToString(i));
            return false;
        }
        string joined = "";
        if(!JoinValidation_BuildJoinedSlimCase001(parts, d_tutc, d_ticket, d_pos, d_magic, d_vol, d_price,
                                                  d_profit, d_comm, d_swap, d_type, d_entry, d_reason, joinerBuild, joined)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=join_build idx=", IntegerToString(i));
            return false;
        }
        if(StringFind(joined, ",ORPHAN_DEAL,", 0) >= 0) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=unexpected_orphan idx=", IntegerToString(i));
            return false;
        }
        if(StringFind(joined, posNeedle, 0) < 0) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=lifecycle_position_missing idx=", IntegerToString(i));
            return false;
        }
        if(joined != expData[i]) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=line_mismatch idx=", IntegerToString(i));
            Print("[JOIN_VALIDATION] expected=", expData[i]);
            Print("[JOIN_VALIDATION] actual  =", joined);
            return false;
        }
    }

    Print("[JOIN_VALIDATION] STATUS=PASS rows=3 partial_close_lifecycle_validated=1");
    return true;
}

//+------------------------------------------------------------------+
//| Case_008 — five deals same position_id; slim row + lifecycle    |
//| suffix columns; deals.csv not pre-sorted.                        |
//+------------------------------------------------------------------+
bool JoinVal_RunCase008_PositionRollup(void) {
    const string root = JoinValidation_FixtureCase008Root();
    const string joinerBuild = JOIN_VALIDATION_JOINER_BUILD_008;
    Print("[JOIN_VALIDATION] CASE=Case_008_PositionRollup");
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

    string dealsTxt = "";
    if(!JoinValidation_ReadUtf8FileLf(root + "deals.csv", dealsTxt)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=deals_read");
        return false;
    }
    string dealLines[];
    if(!JoinValidation_CollectDealsCsvDataLines(dealsTxt, dealLines)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=deal_lines_collect");
        return false;
    }
    if(ArraySize(dealLines) != 5) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_five_deal_rows count=", IntegerToString(ArraySize(dealLines)));
        return false;
    }
    if(!JoinValidation_AllDealCsvLinesSharePositionId(dealLines)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=lifecycle_position_id_mismatch");
        return false;
    }
    if(!JoinValidation_SortDealCsvDataLinesByTimeThenTicket(dealLines)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=deal_sort");
        return false;
    }

    string colsPos[];
    if(StringSplit(dealLines[0], ',', colsPos) < 9) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=deal_position_parse");
        return false;
    }
    const ulong lifecycleGroupId = (ulong)StringToInteger(colsPos[8]);
    const string posNeedle = "," + IntegerToString((long)lifecycleGroupId) + ",";

    string telTxt = "";
    if(!JoinValidation_ReadUtf8FileLf(root + "telemetry.csv", telTxt)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=telemetry_read_case008");
        return false;
    }

    string expJoinedTxt = "";
    if(!JoinValidation_ReadUtf8FileLf(root + "expected_joined.csv", expJoinedTxt)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_read");
        return false;
    }
    string ejHdr = "";
    string expData[];
    if(!JoinValidation_SplitCsvHeaderAndAllDataLines(expJoinedTxt, ejHdr, expData)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_split_multi");
        return false;
    }
    if(ArraySize(expData) != 5) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_five_joined_rows n=", IntegerToString(ArraySize(expData)));
        return false;
    }

    for(int i = 0; i < 5; i++) {
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
        if(!JoinValidation_ParseDealDataRowColumns(dealLines[i], d_ticket, d_sym, d_magic, d_tutc, d_vol, d_profit,
                                                   d_type, d_entry, d_pos, d_price, d_comm, d_swap, d_reason)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=deal_parse_row idx=", IntegerToString(i));
            return false;
        }
        if(d_pos != lifecycleGroupId) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=lifecycle_position_id_row_mismatch idx=", IntegerToString(i));
            return false;
        }
        string parts[];
        int eligible = 0;
        if(!JoinValidation_SelectBestBackwardBarFromTelemetryText(telTxt, d_tutc, parts, eligible)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=telemetry_select idx=", IntegerToString(i));
            return false;
        }
        string joined = "";
        if(!JoinValidation_BuildJoinedSlimCase001(parts, d_tutc, d_ticket, d_pos, d_magic, d_vol, d_price,
                                                  d_profit, d_comm, d_swap, d_type, d_entry, d_reason, joinerBuild, joined)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=join_build idx=", IntegerToString(i));
            return false;
        }
        if(StringFind(joined, ",ORPHAN_DEAL,", 0) >= 0) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=unexpected_orphan idx=", IntegerToString(i));
            return false;
        }
        if(StringFind(joined, posNeedle, 0) < 0) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=lifecycle_position_missing idx=", IntegerToString(i));
            return false;
        }
        JoinValidation_AppendLifecycleRollupSuffix(joined, lifecycleGroupId, i);
        if(joined != expData[i]) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=line_mismatch idx=", IntegerToString(i));
            Print("[JOIN_VALIDATION] expected=", expData[i]);
            Print("[JOIN_VALIDATION] actual  =", joined);
            return false;
        }
    }

    Print("[JOIN_VALIDATION] STATUS=PASS rows=5 position_rollup_validated=1");
    return true;
}

//+------------------------------------------------------------------+
//| Case_009 — same position_id, per-deal backward bar attribution  |
//| (mixed telemetry contexts); lifecycle suffix like Case_008.      |
//+------------------------------------------------------------------+
bool JoinVal_RunCase009_MultiDealPositionAttribution(void) {
    const string root = JoinValidation_FixtureCase009Root();
    const string joinerBuild = JOIN_VALIDATION_JOINER_BUILD_009;
    Print("[JOIN_VALIDATION] CASE=Case_009_MultiDealPositionAttribution");
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

    string dealsTxt = "";
    if(!JoinValidation_ReadUtf8FileLf(root + "deals.csv", dealsTxt)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=deals_read");
        return false;
    }
    string dealLines[];
    if(!JoinValidation_CollectDealsCsvDataLines(dealsTxt, dealLines)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=deal_lines_collect");
        return false;
    }
    if(ArraySize(dealLines) != 5) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_five_deal_rows count=", IntegerToString(ArraySize(dealLines)));
        return false;
    }
    if(!JoinValidation_AllDealCsvLinesSharePositionId(dealLines)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=lifecycle_position_id_mismatch");
        return false;
    }
    if(!JoinValidation_SortDealCsvDataLinesByTimeThenTicket(dealLines)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=deal_sort");
        return false;
    }

    string colsPos[];
    if(StringSplit(dealLines[0], ',', colsPos) < 9) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=deal_position_parse");
        return false;
    }
    const ulong lifecycleGroupId = (ulong)StringToInteger(colsPos[8]);
    const string posNeedle = "," + IntegerToString((long)lifecycleGroupId) + ",";

    string telTxt = "";
    if(!JoinValidation_ReadUtf8FileLf(root + "telemetry.csv", telTxt)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=telemetry_read_case009");
        return false;
    }

    string expJoinedTxt = "";
    if(!JoinValidation_ReadUtf8FileLf(root + "expected_joined.csv", expJoinedTxt)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_read");
        return false;
    }
    string ejHdr = "";
    string expData[];
    if(!JoinValidation_SplitCsvHeaderAndAllDataLines(expJoinedTxt, ejHdr, expData)) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_split_multi");
        return false;
    }
    if(ArraySize(expData) != 5) {
        Print("[JOIN_VALIDATION] STATUS=FAIL reason=expected_five_joined_rows n=", IntegerToString(ArraySize(expData)));
        return false;
    }

    for(int i = 0; i < 5; i++) {
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
        if(!JoinValidation_ParseDealDataRowColumns(dealLines[i], d_ticket, d_sym, d_magic, d_tutc, d_vol, d_profit,
                                                   d_type, d_entry, d_pos, d_price, d_comm, d_swap, d_reason)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=deal_parse_row idx=", IntegerToString(i));
            return false;
        }
        if(d_pos != lifecycleGroupId) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=lifecycle_position_id_row_mismatch idx=", IntegerToString(i));
            return false;
        }
        string parts[];
        int eligible = 0;
        if(!JoinValidation_SelectBestBackwardBarFromTelemetryText(telTxt, d_tutc, parts, eligible)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=telemetry_select idx=", IntegerToString(i));
            return false;
        }
        string joined = "";
        if(!JoinValidation_BuildJoinedSlimCase001(parts, d_tutc, d_ticket, d_pos, d_magic, d_vol, d_price,
                                                  d_profit, d_comm, d_swap, d_type, d_entry, d_reason, joinerBuild, joined)) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=join_build idx=", IntegerToString(i));
            return false;
        }
        if(StringFind(joined, ",ORPHAN_DEAL,", 0) >= 0) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=unexpected_orphan idx=", IntegerToString(i));
            return false;
        }
        if(StringFind(joined, posNeedle, 0) < 0) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=lifecycle_position_missing idx=", IntegerToString(i));
            return false;
        }
        JoinValidation_AppendLifecycleRollupSuffix(joined, lifecycleGroupId, i);
        if(joined != expData[i]) {
            Print("[JOIN_VALIDATION] STATUS=FAIL reason=line_mismatch idx=", IntegerToString(i));
            Print("[JOIN_VALIDATION] expected=", expData[i]);
            Print("[JOIN_VALIDATION] actual  =", joined);
            JoinVal_ForensicCsvMismatchCase009(i, expData[i], joined);
            return false;
        }
    }

    Print("[JOIN_VALIDATION] STATUS=PASS rows=5 multi_deal_attribution_validated=1");
    return true;
}

//+------------------------------------------------------------------+
int OnInit() {
    if(!JoinVal_RunOneCase("Case_001_BasicJoin", JoinValidation_FixtureCase001Root(), JOIN_VALIDATION_JOINER_BUILD_001, 0))
        return INIT_FAILED;
    if(!JoinVal_RunOneCase("Case_002_OrphanDeal", JoinValidation_FixtureCase002Root(), JOIN_VALIDATION_JOINER_BUILD_002, 1))
        return INIT_FAILED;
    if(!JoinVal_RunOneCase("Case_003_DuplicateCandidateJoin", JoinValidation_FixtureCase003Root(), JOIN_VALIDATION_JOINER_BUILD_003, 2))
        return INIT_FAILED;
    if(!JoinVal_RunOneCase("Case_004_FutureLeakProtection", JoinValidation_FixtureCase004Root(), JOIN_VALIDATION_JOINER_BUILD_004, 3))
        return INIT_FAILED;
    if(!JoinVal_RunOneCase("Case_005_MissingTelemetryRow", JoinValidation_FixtureCase005Root(), JOIN_VALIDATION_JOINER_BUILD_005, 4))
        return INIT_FAILED;
    if(!JoinVal_RunOneCase("Case_006_DuplicateDealTicket", JoinValidation_FixtureCase006Root(), JOIN_VALIDATION_JOINER_BUILD_006, 5))
        return INIT_FAILED;
    if(!JoinVal_RunCase007_PartialCloseLifecycle())
        return INIT_FAILED;
    if(!JoinVal_RunCase008_PositionRollup())
        return INIT_FAILED;
    if(!JoinVal_RunCase009_MultiDealPositionAttribution())
        return INIT_FAILED;
    if(!JoinVal_RunOneCase("Case_010_TimezoneEdge_StaticOffset", JoinValidation_FixtureCase010Root(), JOIN_VALIDATION_JOINER_BUILD_010, 6))
        return INIT_FAILED;
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnTick() {
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
}
