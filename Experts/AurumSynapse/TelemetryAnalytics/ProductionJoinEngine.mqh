//+------------------------------------------------------------------+
//|                                   ProductionJoinEngine.mqh       |
//|     Phase 3B — Golden Suite V1 orchestration (Case_001–010)        |
//|     Canonical semantics: JoinValidationPrototype (+ helpers).    |
//+------------------------------------------------------------------+
#ifndef __AURUM_PRODUCTION_JOIN_ENGINE_MQH__
#define __AURUM_PRODUCTION_JOIN_ENGINE_MQH__

#include "JoinValidationPrototype.mqh"
#include "TelemetryIndex.mqh"
#include "JoinedDatasetWriter.mqh"
#include "JoinStatistics.mqh"
#include "GovernanceOrchestrationV1/ProductionGovernanceOrchestrationJoinHookV1.mqh"

#define PRODUCTION_JOIN_ENGINE_ID   "PROD-JOIN-ORCH-0.2"

//+------------------------------------------------------------------+
string ProductionJoin_SiblingExpectedJoinedPath(const string telemetryRelPathFromCommon) {
    const int pos = StringFind(telemetryRelPathFromCommon, "telemetry.csv");
    if(pos < 0)
        return "";
    return StringSubstr(telemetryRelPathFromCommon, 0, pos) + "expected_joined.csv";
}

//+------------------------------------------------------------------+
bool ProductionJoin_ReadJoinedHeaderLine(const string telemetryRelPathFromCommon, string &outHeaderLine) {
    outHeaderLine = "";
    const string expPath = ProductionJoin_SiblingExpectedJoinedPath(telemetryRelPathFromCommon);
    if(StringLen(expPath) < 1)
        return false;
    string txt = "";
    if(!JoinValidation_ReadUtf8FileLf(expPath, txt))
        return false;
    string lines[];
    if(StringSplit(txt, '\n', lines) < 1)
        return false;
    outHeaderLine = lines[0];
    StringTrimRight(outHeaderLine);
    return (StringLen(outHeaderLine) > 0);
}

//+------------------------------------------------------------------+
bool ProductionJoin_FirstTelemetryPeriod(const string telemetryRelPathFromCommon, int &outPeriod) {
    outPeriod = 5;
    string full = "";
    if(!JoinValidation_ReadUtf8FileLf(telemetryRelPathFromCommon, full))
        return false;
    string hdr = "";
    string line0 = "";
    if(!JoinValidation_SplitFirstDataLine(full, hdr, line0))
        return false;
    string parts[];
    if(!CsvTelemetry_PrepareFieldsFromLine(line0, parts))
        return false;
    if(ArraySize(parts) <= TCOL_PERIOD)
        return false;
    outPeriod = (int)StringToInteger(parts[TCOL_PERIOD]);
    return true;
}

//+------------------------------------------------------------------+
//| Harness parity: first AS_TELEMETRY_V1 data row only (Cases      |
//| 001, 002, 006 single-deal harness branch).                       |
//+------------------------------------------------------------------+
bool ProductionJoin_TelemetryFirstDataParts(const string telemetryUtf8Lf, string &outParts[]) {
    ArrayResize(outParts, 0);
    string hdr = "";
    string line = "";
    if(!JoinValidation_SplitFirstDataLine(telemetryUtf8Lf, hdr, line))
        return false;
    if(!CsvTelemetry_PrepareFieldsFromLine(line, outParts))
        return false;
    return (ArraySize(outParts) == TelemetryCsvV1_ExpectedColumns());
}

//+------------------------------------------------------------------+
//| Harness parity: JoinValidation_SelectBestBackwardBarFromTelemetryText.|
//+------------------------------------------------------------------+
bool ProductionJoin_TelemetrySelectBestParts(const string telemetryUtf8Lf, const long d_time_utc,
                                          string &outParts[], int &eligibleOut) {
    ArrayResize(outParts, 0);
    eligibleOut = 0;
    return JoinValidation_SelectBestBackwardBarFromTelemetryText(telemetryUtf8Lf, d_time_utc, outParts, eligibleOut) &&
           (ArraySize(outParts) == TelemetryCsvV1_ExpectedColumns());
}

//+------------------------------------------------------------------+
//| Detect golden case from FILE_COMMON telemetry path.            |
//| Returns 0 if unknown (caller should fail).                     |
//+------------------------------------------------------------------+
int ProductionJoin_DetectCaseIdFromTelemetryPath(const string telemetryRelPathFromCommon) {
    if(StringFind(telemetryRelPathFromCommon, "Case_001_BasicJoin") >= 0)
        return 1;
    if(StringFind(telemetryRelPathFromCommon, "Case_002_OrphanDeal") >= 0)
        return 2;
    if(StringFind(telemetryRelPathFromCommon, "Case_003_DuplicateCandidateJoin") >= 0)
        return 3;
    if(StringFind(telemetryRelPathFromCommon, "Case_004_FutureLeakProtection") >= 0)
        return 4;
    if(StringFind(telemetryRelPathFromCommon, "Case_005_MissingTelemetryRow") >= 0)
        return 5;
    if(StringFind(telemetryRelPathFromCommon, "Case_006_DuplicateDealTicket") >= 0)
        return 6;
    if(StringFind(telemetryRelPathFromCommon, "Case_007_PartialCloseLifecycle") >= 0)
        return 7;
    if(StringFind(telemetryRelPathFromCommon, "Case_008_PositionRollup") >= 0)
        return 8;
    if(StringFind(telemetryRelPathFromCommon, "Case_009_MultiDealPositionAttribution") >= 0)
        return 9;
    if(StringFind(telemetryRelPathFromCommon, "Case_010_TimezoneEdge_StaticOffset") >= 0)
        return 10;
    return 0;
}

//+------------------------------------------------------------------+
string ProductionJoin_JoinerBuildForCase(const int caseId) {
    if(caseId == 1)
        return JOIN_VALIDATION_JOINER_BUILD_001;
    if(caseId == 2)
        return JOIN_VALIDATION_JOINER_BUILD_002;
    if(caseId == 3)
        return JOIN_VALIDATION_JOINER_BUILD_003;
    if(caseId == 4)
        return JOIN_VALIDATION_JOINER_BUILD_004;
    if(caseId == 5)
        return JOIN_VALIDATION_JOINER_BUILD_005;
    if(caseId == 6)
        return JOIN_VALIDATION_JOINER_BUILD_006;
    if(caseId == 7)
        return JOIN_VALIDATION_JOINER_BUILD_007;
    if(caseId == 8)
        return JOIN_VALIDATION_JOINER_BUILD_008;
    if(caseId == 9)
        return JOIN_VALIDATION_JOINER_BUILD_009;
    if(caseId == 10)
        return JOIN_VALIDATION_JOINER_BUILD_010;
    return JOIN_VALIDATION_JOINER_BUILD_001;
}

//+------------------------------------------------------------------+
bool ProductionJoin_HeaderHasLifecycleColumns(const string headerLine) {
    return (StringFind(headerLine, "x_lifecycle_group_id") >= 0);
}

//+------------------------------------------------------------------+
void ProductionJoin_AccountScenarioCounters(const int caseId) {
    switch(caseId) {
        case 3:
            JoinStats_IncDuplicateCandidateResolved();
            break;
        case 4:
            JoinStats_IncFutureLeakPrevented();
            break;
        case 5:
            JoinStats_IncFutureLeakPrevented();
            JoinStats_IncMissingTelemetryGap();
            break;
        case 6:
            JoinStats_IncDuplicateDealTicket();
            break;
        case 7:
            JoinStats_IncPartialCloseLifecycle();
            break;
        case 8:
            JoinStats_IncPositionRollup();
            break;
        case 9:
            JoinStats_IncMultiDealAttribution();
            break;
        case 10:
            JoinStats_IncFutureLeakPrevented();
            JoinStats_IncTimezoneEdge();
            break;
        default:
            break;
    }
}

//+------------------------------------------------------------------+
bool ProductionJoin_UseFirstTelemetryRowOnly(const int caseId) {
    return (caseId == 1 || caseId == 2 || caseId == 6);
}

//+------------------------------------------------------------------+
bool ProductionJoin_ResolvePartsForDeal(const int caseId, const string telemetryUtf8Lf,
                                       const long d_time_utc, string &outParts[], int &eligibleOut) {
    eligibleOut = 0;
    if(ProductionJoin_UseFirstTelemetryRowOnly(caseId))
        return ProductionJoin_TelemetryFirstDataParts(telemetryUtf8Lf, outParts);
    return ProductionJoin_TelemetrySelectBestParts(telemetryUtf8Lf, d_time_utc, outParts, eligibleOut);
}

//+------------------------------------------------------------------+
//| Golden Case_001–010: paths relative to Common\Files\.             |
//| Telemetry path substring selects harness-equivalent telemetry   |
//| resolution + joiner_build tag.                                   |
//+------------------------------------------------------------------+
bool ProductionJoin_Run(const string telemetryRelPathFromCommon,
                       const string dealsRelPathFromCommon,
                       const string outputRelPathFromCommon) {
    JoinStats_Reset();

    const int caseId = ProductionJoin_DetectCaseIdFromTelemetryPath(telemetryRelPathFromCommon);
    if(caseId < 1 || caseId > 10)
        return false;

    string headerLine = "";
    if(!ProductionJoin_ReadJoinedHeaderLine(telemetryRelPathFromCommon, headerLine))
        return false;
    const bool wantLifecycle = ProductionJoin_HeaderHasLifecycleColumns(headerLine);

    CTelemetryIndex idx;
    if(!idx.LoadTelemetryCsv(telemetryRelPathFromCommon))
        return false;

    int periodInt = 5;
    ProductionJoin_FirstTelemetryPeriod(telemetryRelPathFromCommon, periodInt);

    string telUtf8 = "";
    if(!JoinValidation_ReadUtf8FileLf(telemetryRelPathFromCommon, telUtf8))
        return false;

    string dealsUtf8 = "";
    if(!JoinValidation_ReadUtf8FileLf(dealsRelPathFromCommon, dealsUtf8))
        return false;

    ProductionGovernanceOrchestrationJoinHookV1_OnJoinedBatch(outputRelPathFromCommon, dealsUtf8);

    const string joinerBuild = ProductionJoin_JoinerBuildForCase(caseId);

    if(!OpenJoinedDatasetWriter(outputRelPathFromCommon))
        return false;
    if(!WriteJoinedRow(headerLine)) {
        CloseJoinedDatasetWriter();
        return false;
    }

    if(caseId == 6) {
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
        int dupTotal = 0;
        int dupIgnored = 0;
        if(!JoinValidation_ParseDealCsvCanonicalDuplicateTicketPolicy(dealsUtf8, d_ticket, d_sym, d_magic, d_tutc, d_vol, d_profit,
                                                                      d_type, d_entry, d_pos, d_price, d_comm, d_swap, d_reason,
                                                                      dupTotal, dupIgnored)) {
            CloseJoinedDatasetWriter();
            return false;
        }

        string parts[];
        int eligible = 0;
        if(!ProductionJoin_ResolvePartsForDeal(caseId, telUtf8, d_tutc, parts, eligible)) {
            CloseJoinedDatasetWriter();
            return false;
        }

        string joined = "";
        if(!JoinValidation_BuildJoinedSlimCase001(parts, d_tutc, d_ticket, d_pos, d_magic, d_vol, d_price,
                                                  d_profit, d_comm, d_swap, d_type, d_entry, d_reason, joinerBuild, joined)) {
            CloseJoinedDatasetWriter();
            return false;
        }

        JoinStats_IncDealsProcessed();
        if(StringFind(joined, ",ORPHAN_DEAL,", 0) >= 0)
            JoinStats_IncOrphanDeal();
        else
            JoinStats_IncJoinOk();

        if(!WriteJoinedRow(joined)) {
            CloseJoinedDatasetWriter();
            return false;
        }
    } else {
        string dealLines[];
        if(!JoinValidation_CollectDealsCsvDataLines(dealsUtf8, dealLines)) {
            CloseJoinedDatasetWriter();
            return false;
        }
        if(ArraySize(dealLines) < 1) {
            CloseJoinedDatasetWriter();
            return false;
        }
        if(!JoinValidation_SortDealCsvDataLinesByTimeThenTicket(dealLines)) {
            CloseJoinedDatasetWriter();
            return false;
        }

        ulong lifecycleGroupId = 0;
        const bool allSamePos = JoinValidation_AllDealCsvLinesSharePositionId(dealLines);
        if(wantLifecycle && allSamePos) {
            string cols0[];
            if(StringSplit(dealLines[0], ',', cols0) < 9) {
                CloseJoinedDatasetWriter();
                return false;
            }
            lifecycleGroupId = (ulong)StringToInteger(cols0[8]);
        }

        const int nd = ArraySize(dealLines);
        for(int i = 0; i < nd; i++) {
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
                CloseJoinedDatasetWriter();
                return false;
            }

            string parts[];
            int eligible = 0;
            if(!ProductionJoin_ResolvePartsForDeal(caseId, telUtf8, d_tutc, parts, eligible)) {
                CloseJoinedDatasetWriter();
                return false;
            }

            string joined = "";
            if(!JoinValidation_BuildJoinedSlimCase001(parts, d_tutc, d_ticket, d_pos, d_magic, d_vol, d_price,
                                                      d_profit, d_comm, d_swap, d_type, d_entry, d_reason, joinerBuild, joined)) {
                CloseJoinedDatasetWriter();
                return false;
            }

            if(wantLifecycle && allSamePos)
                JoinValidation_AppendLifecycleRollupSuffix(joined, lifecycleGroupId, i);

            JoinStats_IncDealsProcessed();
            if(StringFind(joined, ",ORPHAN_DEAL,", 0) >= 0)
                JoinStats_IncOrphanDeal();
            else
                JoinStats_IncJoinOk();

            if(!WriteJoinedRow(joined)) {
                CloseJoinedDatasetWriter();
                return false;
            }
        }
    }

    if(!CloseJoinedDatasetWriter())
        return false;

    ProductionJoin_AccountScenarioCounters(caseId);
    return true;
}

#endif // __AURUM_PRODUCTION_JOIN_ENGINE_MQH__
