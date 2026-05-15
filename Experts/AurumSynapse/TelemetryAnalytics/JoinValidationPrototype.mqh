//+------------------------------------------------------------------+
//|                                    JoinValidationPrototype.mqh   |
//|     Phase 3B — deterministic join validation prototype (read-only)|
//+------------------------------------------------------------------+
#ifndef __AURUM_JOIN_VALIDATION_PROTOTYPE_MQH__
#define __AURUM_JOIN_VALIDATION_PROTOTYPE_MQH__

#include "CsvTelemetryReader.mqh"
#include "AnalyticsTypes.mqh"
#include "QualityAnalytics.mqh"
#include "RegimeLabels.mqh"
#include "../Telemetry/TelemetryContracts.mqh"
#include "../Core/Constants.mqh"

#ifndef TCOL_REJECT_CODE
#define TCOL_REJECT_CODE         60
#endif
#ifndef TCOL_COOLDOWN_FLAG
#define TCOL_COOLDOWN_FLAG       62
#endif

#define JOIN_VALIDATION_JOIN_SEMANTIC   "J1-DEALTIME-BACKWARD-BAR"
#define JOIN_VALIDATION_JOINER_BUILD_001 "CASE001-PROTO-1"
#define JOIN_VALIDATION_JOINER_BUILD_002 "CASE002-PROTO-1"
#define JOIN_VALIDATION_JOINER_BUILD_003 "CASE003-PROTO-1"
#define JOIN_VALIDATION_JOINER_BUILD_004 "CASE004-PROTO-1"
#define JOIN_VALIDATION_JOINER_BUILD_005 "CASE005-PROTO-1"
#define JOIN_VALIDATION_JOINER_BUILD_006 "CASE006-PROTO-1"
#define JOIN_VALIDATION_JOINER_BUILD_007 "CASE007-PROTO-1"
#define JOIN_VALIDATION_JOINER_BUILD_008 "CASE008-PROTO-1"
#define JOIN_VALIDATION_JOINER_BUILD_009 "CASE009-PROTO-1"
#define JOIN_VALIDATION_JOINER_BUILD_010 "CASE010-PROTO-1"

//+------------------------------------------------------------------+
//| Relative path under Common\Files\ (FILE_COMMON). No agent path.   |
//+------------------------------------------------------------------+
string JoinValidation_CommonFixtureRoot(void) {
    return "AurumSynapse\\TelemetryFixtures\\";
}

//+------------------------------------------------------------------+
//| Diagnostics only — OS path to Common\Files\<CommonFixtureRoot>   |
//+------------------------------------------------------------------+
string JoinValidation_CommonFixtureAbsoluteRoot(void) {
    return TerminalInfoString(TERMINAL_COMMONDATA_PATH) + "\\Files\\" + JoinValidation_CommonFixtureRoot();
}

//+------------------------------------------------------------------+
//| Case_001 relative prefix (FILE_COMMON).                            |
//+------------------------------------------------------------------+
string JoinValidation_FixtureCase001Root(void) {
    return JoinValidation_CommonFixtureRoot() + "Case_001_BasicJoin\\";
}

//+------------------------------------------------------------------+
//| Case_002 relative prefix (FILE_COMMON).                          |
//+------------------------------------------------------------------+
string JoinValidation_FixtureCase002Root(void) {
    return JoinValidation_CommonFixtureRoot() + "Case_002_OrphanDeal\\";
}

//+------------------------------------------------------------------+
//| Case_003 relative prefix (FILE_COMMON).                          |
//+------------------------------------------------------------------+
string JoinValidation_FixtureCase003Root(void) {
    return JoinValidation_CommonFixtureRoot() + "Case_003_DuplicateCandidateJoin\\";
}

//+------------------------------------------------------------------+
//| Case_004 relative prefix (FILE_COMMON).                          |
//+------------------------------------------------------------------+
string JoinValidation_FixtureCase004Root(void) {
    return JoinValidation_CommonFixtureRoot() + "Case_004_FutureLeakProtection\\";
}

//+------------------------------------------------------------------+
//| Case_005 relative prefix (FILE_COMMON).                          |
//+------------------------------------------------------------------+
string JoinValidation_FixtureCase005Root(void) {
    return JoinValidation_CommonFixtureRoot() + "Case_005_MissingTelemetryRow\\";
}

//+------------------------------------------------------------------+
//| Case_006 relative prefix (FILE_COMMON).                          |
//+------------------------------------------------------------------+
string JoinValidation_FixtureCase006Root(void) {
    return JoinValidation_CommonFixtureRoot() + "Case_006_DuplicateDealTicket\\";
}

//+------------------------------------------------------------------+
//| Case_007 relative prefix (FILE_COMMON).                          |
//+------------------------------------------------------------------+
string JoinValidation_FixtureCase007Root(void) {
    return JoinValidation_CommonFixtureRoot() + "Case_007_PartialCloseLifecycle\\";
}

//+------------------------------------------------------------------+
//| Case_008 relative prefix (FILE_COMMON).                          |
//+------------------------------------------------------------------+
string JoinValidation_FixtureCase008Root(void) {
    return JoinValidation_CommonFixtureRoot() + "Case_008_PositionRollup\\";
}

//+------------------------------------------------------------------+
//| Case_009 relative prefix (FILE_COMMON).                          |
//+------------------------------------------------------------------+
string JoinValidation_FixtureCase009Root(void) {
    return JoinValidation_CommonFixtureRoot() + "Case_009_MultiDealPositionAttribution\\";
}

//+------------------------------------------------------------------+
//| Case_010 relative prefix (FILE_COMMON).                          |
//+------------------------------------------------------------------+
string JoinValidation_FixtureCase010Root(void) {
    return JoinValidation_CommonFixtureRoot() + "Case_010_TimezoneEdge_StaticOffset\\";
}

//+------------------------------------------------------------------+
//| Read UTF-8 text; strip CR. Path is relative to Common\Files\.     |
//+------------------------------------------------------------------+
bool JoinValidation_ReadUtf8FileLf(const string relPathFromCommonFiles, string &outText) {
    outText = "";
    const int fh = FileOpen(relPathFromCommonFiles, FILE_READ | FILE_BIN | FILE_ANSI | FILE_COMMON);
    if(fh == INVALID_HANDLE)
        return false;
    while(!FileIsEnding(fh)) {
        uchar chunk[4096];
        const uint n = FileReadArray(fh, chunk, 0, 4096);
        if(n < 1)
            break;
        for(uint i = 0; i < n; i++) {
            if(chunk[i] == (uchar)'\r')
                continue;
            outText += CharToString(chunk[i]);
        }
    }
    FileClose(fh);
    return true;
}

//+------------------------------------------------------------------+
bool JoinValidation_SplitFirstDataLine(const string text, string &headerLine, string &dataLine) {
    headerLine = "";
    dataLine = "";
    string lines[];
    const int n = StringSplit(text, '\n', lines);
    if(n < 2)
        return false;
    headerLine = lines[0];
    for(int i = 1; i < n; i++) {
        string s = lines[i];
        StringTrimLeft(s);
        StringTrimRight(s);
        if(s == "")
            continue;
        dataLine = s;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
void JoinValidation_CopyParts(const string &src[], string &dst[]) {
    const int n = ArraySize(src);
    ArrayResize(dst, n);
    for(int i = 0; i < n; i++)
        dst[i] = src[i];
}

//+------------------------------------------------------------------+
//| Telemetry → best backward bar for one deal time.                |
//| Stage 1 (causal filter): reject any row with bar_utc > d_time_utc |
//| — future bars are never candidates, regardless of distance,      |
//| spread, quality, or CSV row order.                               |
//| Stage 2 (deterministic tie): among remaining rows,             |
//| eligible := bar_utc <= d_time_utc; select MAX(bar_utc).          |
//| Telemetry gaps: only rows that **exist** in the CSV compete —   |
//| no interpolation, no synthetic bars for missing timestamps,     |
//| no forward fill from a future bar; large latency is acceptable.   |
//| Full-file scan — order-independent for distinct bar_utc values.  |
//+------------------------------------------------------------------+
bool JoinValidation_SelectBestBackwardBarFromTelemetryText(const string telemetryUtf8Lf,
                                                            const long d_time_utc,
                                                            string &outParts[],
                                                            int &outEligibleCount) {
    outEligibleCount = 0;
    ArrayResize(outParts, 0);
    const int need = TelemetryCsvV1_ExpectedColumns();
    string lines[];
    const int n = StringSplit(telemetryUtf8Lf, '\n', lines);
    if(n < 2)
        return false;
    long bestBarUtc = 0;
    bool haveBest = false;
    for(int i = 1; i < n; i++) {
        string s = lines[i];
        StringTrimLeft(s);
        StringTrimRight(s);
        if(s == "")
            continue;
        string rowParts[];
        if(!CsvTelemetry_PrepareFieldsFromLine(s, rowParts))
            return false;
        if(ArraySize(rowParts) != need)
            return false;
        const long barUtc = (long)StringToInteger(rowParts[TCOL_BAR_UTC]);
        if(barUtc <= d_time_utc) {
            outEligibleCount++;
            if(!haveBest || barUtc > bestBarUtc) {
                haveBest = true;
                bestBarUtc = barUtc;
                JoinValidation_CopyParts(rowParts, outParts);
            }
        }
    }
    return (haveBest && ArraySize(outParts) == need);
}

//+------------------------------------------------------------------+
//| Count telemetry data rows and rows with bar_utc > d_time_utc    |
//| (strictly future — illegal for join). Harness diagnostics.      |
//+------------------------------------------------------------------+
bool JoinValidation_ScanTelemetryCausalStats(const string telemetryUtf8Lf, const long d_time_utc,
                                             int &outDataRows, int &outStrictFutureRows) {
    outDataRows = 0;
    outStrictFutureRows = 0;
    const int need = TelemetryCsvV1_ExpectedColumns();
    string lines[];
    const int n = StringSplit(telemetryUtf8Lf, '\n', lines);
    if(n < 2)
        return false;
    for(int i = 1; i < n; i++) {
        string s = lines[i];
        StringTrimLeft(s);
        StringTrimRight(s);
        if(s == "")
            continue;
        string rowParts[];
        if(!CsvTelemetry_PrepareFieldsFromLine(s, rowParts))
            return false;
        if(ArraySize(rowParts) != need)
            return false;
        const long barUtc = (long)StringToInteger(rowParts[TCOL_BAR_UTC]);
        outDataRows++;
        if(barUtc > d_time_utc)
            outStrictFutureRows++;
    }
    return true;
}

//+------------------------------------------------------------------+
//| True iff some telemetry **data** line has bar_utc == barUtc.    |
//| (Harness: assert a documented gap timestamp is absent.)         |
//+------------------------------------------------------------------+
bool JoinValidation_TelemetryDataRowHasBarUtc(const string telemetryUtf8Lf, const long barUtc, bool &outHas) {
    outHas = false;
    const int need = TelemetryCsvV1_ExpectedColumns();
    string lines[];
    const int n = StringSplit(telemetryUtf8Lf, '\n', lines);
    if(n < 2)
        return false;
    for(int i = 1; i < n; i++) {
        string s = lines[i];
        StringTrimLeft(s);
        StringTrimRight(s);
        if(s == "")
            continue;
        string rowParts[];
        if(!CsvTelemetry_PrepareFieldsFromLine(s, rowParts))
            return false;
        if(ArraySize(rowParts) != need)
            return false;
        const long bu = (long)StringToInteger(rowParts[TCOL_BAR_UTC]);
        if(bu == barUtc) {
            outHas = true;
            return true;
        }
    }
    return true;
}

//+------------------------------------------------------------------+
bool JoinValidation_ParseDealCsv(const string text,
                                   ulong &outTicket,
                                   string &outSymbol,
                                   long &outMagic,
                                   long &outTimeUtc,
                                   double &outVolume,
                                   double &outProfit,
                                   int &outType,
                                   int &outEntry,
                                   ulong &outPositionId,
                                   double &outPrice,
                                   double &outCommission,
                                   double &outSwap,
                                   int &outReason) {
    string hdr, row;
    if(!JoinValidation_SplitFirstDataLine(text, hdr, row))
        return false;
    string cols[];
    const int c = StringSplit(row, ',', cols);
    if(c < 13)
        return false;
    outTicket = (ulong)StringToInteger(cols[0]);
    outSymbol = cols[1];
    outMagic = (long)StringToInteger(cols[2]);
    outTimeUtc = (long)StringToInteger(cols[3]);
    outVolume = StringToDouble(cols[4]);
    outProfit = StringToDouble(cols[5]);
    outType = (int)StringToInteger(cols[6]);
    outEntry = (int)StringToInteger(cols[7]);
    outPositionId = (ulong)StringToInteger(cols[8]);
    outPrice = StringToDouble(cols[9]);
    outCommission = StringToDouble(cols[10]);
    outSwap = StringToDouble(cols[11]);
    outReason = (int)StringToInteger(cols[12]);
    return true;
}

//+------------------------------------------------------------------+
//| Parse one deals.csv **data** line (13 columns).                  |
//+------------------------------------------------------------------+
bool JoinValidation_ParseDealDataRowColumns(const string rowCsv,
                                            ulong &outTicket,
                                            string &outSymbol,
                                            long &outMagic,
                                            long &outTimeUtc,
                                            double &outVolume,
                                            double &outProfit,
                                            int &outType,
                                            int &outEntry,
                                            ulong &outPositionId,
                                            double &outPrice,
                                            double &outCommission,
                                            double &outSwap,
                                            int &outReason) {
    string cols[];
    const int c = StringSplit(rowCsv, ',', cols);
    if(c < 13)
        return false;
    outTicket = (ulong)StringToInteger(cols[0]);
    outSymbol = cols[1];
    outMagic = (long)StringToInteger(cols[2]);
    outTimeUtc = (long)StringToInteger(cols[3]);
    outVolume = StringToDouble(cols[4]);
    outProfit = StringToDouble(cols[5]);
    outType = (int)StringToInteger(cols[6]);
    outEntry = (int)StringToInteger(cols[7]);
    outPositionId = (ulong)StringToInteger(cols[8]);
    outPrice = StringToDouble(cols[9]);
    outCommission = StringToDouble(cols[10]);
    outSwap = StringToDouble(cols[11]);
    outReason = (int)StringToInteger(cols[12]);
    return true;
}

//+------------------------------------------------------------------+
//| Duplicate d_ticket in deals.csv: pick **one** canonical row for |
//| join validation — no random drop, no silent ambiguity.          |
//| Preconditions (Case_006 harness): ≥2 data rows; **all** rows share |
//| the same d_ticket (duplicate import / export corruption model). |
//| Canonical order: (1) minimum d_time_utc; (2) tie → lexical      |
//| `StringCompare` on full raw UTF-8 data line; (3) tie → smallest  |
//| physical line index (earlier row in file).                      |
//| No synthetic deals; ignored rows are not joined in this harness. |
//+------------------------------------------------------------------+
bool JoinValidation_ParseDealCsvCanonicalDuplicateTicketPolicy(const string dealsUtf8Lf,
                                                               ulong &outTicket,
                                                               string &outSymbol,
                                                               long &outMagic,
                                                               long &outTimeUtc,
                                                               double &outVolume,
                                                               double &outProfit,
                                                               int &outType,
                                                               int &outEntry,
                                                               ulong &outPositionId,
                                                               double &outPrice,
                                                               double &outCommission,
                                                               double &outSwap,
                                                               int &outReason,
                                                               int &outTotalDataRows,
                                                               int &outRowsIgnoredAfterCanonical) {
    outTotalDataRows = 0;
    outRowsIgnoredAfterCanonical = 0;
    string lines[];
    const int n = StringSplit(dealsUtf8Lf, '\n', lines);
    if(n < 2)
        return false;
    string dataLines[];
    for(int i = 1; i < n; i++) {
        string s = lines[i];
        StringTrimLeft(s);
        StringTrimRight(s);
        if(s == "")
            continue;
        const int m = ArraySize(dataLines);
        ArrayResize(dataLines, m + 1);
        dataLines[m] = s;
    }
    outTotalDataRows = ArraySize(dataLines);
    if(outTotalDataRows < 2)
        return false;

    ulong ticket0 = 0;
    long t0 = 0;
    if(!JoinValidation_ParseDealDataRowColumns(dataLines[0], ticket0, outSymbol, outMagic, t0,
                                               outVolume, outProfit, outType, outEntry, outPositionId,
                                               outPrice, outCommission, outSwap, outReason))
        return false;
    outTicket = ticket0;
    outTimeUtc = t0;

    for(int j = 1; j < outTotalDataRows; j++) {
        ulong tj = 0;
        string sj = "";
        long mj = 0, utj = 0;
        double vj = 0.0, prj = 0.0, pricej = 0.0, cmj = 0.0, swj = 0.0;
        int tyj = 0, enj = 0, rej = 0;
        ulong posj = 0;
        if(!JoinValidation_ParseDealDataRowColumns(dataLines[j], tj, sj, mj, utj,
                                                   vj, prj, tyj, enj, posj, pricej, cmj, swj, rej))
            return false;
        if(tj != ticket0)
            return false;
    }

    int bestIdx = 0;
    long bestUtc = outTimeUtc;
    for(int k = 1; k < outTotalDataRows; k++) {
        ulong tk = 0;
        string sk = "";
        long mk = 0, utk = 0;
        double vk = 0.0, prk = 0.0, pricek = 0.0, cmk = 0.0, swk = 0.0;
        int tyk = 0, enk = 0, rek = 0;
        ulong posk = 0;
        if(!JoinValidation_ParseDealDataRowColumns(dataLines[k], tk, sk, mk, utk,
                                                   vk, prk, tyk, enk, posk, pricek, cmk, swk, rek))
            return false;
        if(utk < bestUtc) {
            bestIdx = k;
            bestUtc = utk;
        } else if(utk == bestUtc) {
            const int cmp = StringCompare(dataLines[k], dataLines[bestIdx]);
            if(cmp < 0) {
                bestIdx = k;
                bestUtc = utk;
            } else if(cmp == 0 && k < bestIdx) {
                bestIdx = k;
                bestUtc = utk;
            }
        }
    }

    if(!JoinValidation_ParseDealDataRowColumns(dataLines[bestIdx], outTicket, outSymbol, outMagic, outTimeUtc,
                                               outVolume, outProfit, outType, outEntry, outPositionId,
                                               outPrice, outCommission, outSwap, outReason))
        return false;
    outRowsIgnoredAfterCanonical = outTotalDataRows - 1;
    return true;
}

//+------------------------------------------------------------------+
//| d_time_utc (col 3) and d_ticket (col 0) from one deals.csv row. |
//+------------------------------------------------------------------+
bool JoinValidation_DealCsvDataLineTimeAndTicket(const string rowCsv, long &outTimeUtc, ulong &outTicket) {
    string cols[];
    if(StringSplit(rowCsv, ',', cols) < 4)
        return false;
    outTicket = (ulong)StringToInteger(cols[0]);
    outTimeUtc = (long)StringToInteger(cols[3]);
    return true;
}

//+------------------------------------------------------------------+
//| True iff lineA should sort **after** lineB (ascending key).      |
//+------------------------------------------------------------------+
bool JoinValidation_DealCsvDataLineGreaterTimeThenTicket(const string lineA, const string lineB) {
    long ta = 0, tb = 0;
    ulong ka = 0, kb = 0;
    if(!JoinValidation_DealCsvDataLineTimeAndTicket(lineA, ta, ka))
        return false;
    if(!JoinValidation_DealCsvDataLineTimeAndTicket(lineB, tb, kb))
        return false;
    if(ta > tb)
        return true;
    if(ta < tb)
        return false;
    return (ka > kb);
}

//+------------------------------------------------------------------+
//| All non-empty deals.csv data lines (excluding header).           |
//+------------------------------------------------------------------+
bool JoinValidation_CollectDealsCsvDataLines(const string dealsUtf8Lf, string &outDataLines[]) {
    ArrayResize(outDataLines, 0);
    string lines[];
    const int n = StringSplit(dealsUtf8Lf, '\n', lines);
    if(n < 2)
        return false;
    for(int i = 1; i < n; i++) {
        string s = lines[i];
        StringTrimLeft(s);
        StringTrimRight(s);
        if(s == "")
            continue;
        const int m = ArraySize(outDataLines);
        ArrayResize(outDataLines, m + 1);
        outDataLines[m] = s;
    }
    return (ArraySize(outDataLines) > 0);
}

//+------------------------------------------------------------------+
//| Deterministic deal batch order: `d_time_utc` ASC, `d_ticket` ASC.|
//| Bubble sort — stable for equal keys relative to post-sort adjacency.|
//+------------------------------------------------------------------+
bool JoinValidation_SortDealCsvDataLinesByTimeThenTicket(string &ioLines[]) {
    const int n = ArraySize(ioLines);
    if(n < 2)
        return true;
    for(int i = 0; i < n; i++) {
        long t = 0;
        ulong k = 0;
        if(!JoinValidation_DealCsvDataLineTimeAndTicket(ioLines[i], t, k))
            return false;
    }
    for(int a = 0; a < n - 1; a++) {
        for(int b = 0; b < n - 1 - a; b++) {
            if(JoinValidation_DealCsvDataLineGreaterTimeThenTicket(ioLines[b], ioLines[b + 1])) {
                const string tmp = ioLines[b];
                ioLines[b] = ioLines[b + 1];
                ioLines[b + 1] = tmp;
            }
        }
    }
    return true;
}

//+------------------------------------------------------------------+
//| Lifecycle root for Case_007: all rows share `d_position_id`.   |
//+------------------------------------------------------------------+
bool JoinValidation_AllDealCsvLinesSharePositionId(const string &lines[]) {
    const int n = ArraySize(lines);
    if(n < 1)
        return false;
    string cols0[];
    if(StringSplit(lines[0], ',', cols0) < 9)
        return false;
    const ulong p0 = (ulong)StringToInteger(cols0[8]);
    for(int i = 1; i < n; i++) {
        string cols[];
        if(StringSplit(lines[i], ',', cols) < 9)
            return false;
        if((ulong)StringToInteger(cols[8]) != p0)
            return false;
    }
    return true;
}

//+------------------------------------------------------------------+
//| First line = header; every other non-empty line = data row.      |
//+------------------------------------------------------------------+
bool JoinValidation_SplitCsvHeaderAndAllDataLines(const string text, string &outHeader, string &outDataLines[]) {
    ArrayResize(outDataLines, 0);
    outHeader = "";
    string lines[];
    const int n = StringSplit(text, '\n', lines);
    if(n < 2)
        return false;
    string h = lines[0];
    StringTrimRight(h);
    outHeader = h;
    for(int i = 1; i < n; i++) {
        string s = lines[i];
        StringTrimLeft(s);
        StringTrimRight(s);
        if(s == "")
            continue;
        const int m = ArraySize(outDataLines);
        ArrayResize(outDataLines, m + 1);
        outDataLines[m] = s;
    }
    return (ArraySize(outDataLines) > 0);
}

//+------------------------------------------------------------------+
int JoinValidation_ActiveSlotMask(const string &parts[]) {
    int mask = 0;
    for(int slot = 0; slot < TELEMETRY_STRATEGY_SLOTS; slot++) {
        bool na = false;
        const int act = CsvTelemetry_ParseInt(parts[TCOL_STR_ACTIVE(slot)], na);
        if(na || act == 0)
            continue;
        mask |= (1 << slot);
    }
    return mask;
}

//+------------------------------------------------------------------+
void JoinValidation_LeaderSlotDeterministic(const string &parts[], const int activeMask,
                                            int &outSlot, int &outSig, double &outStr) {
    outSlot = TELEMETRY_NULL_INT;
    outSig = 0;
    outStr = 0.0;
    if(activeMask == 0)
        return;
    double bestStr = -1.0e100;
    for(int slot = 0; slot < TELEMETRY_STRATEGY_SLOTS; slot++) {
        if((activeMask & (1 << slot)) == 0)
            continue;
        bool nst = false;
        const double st = CsvTelemetry_ParseDouble(parts[TCOL_STR_STRENGTH(slot)], nst);
        if(nst)
            continue;
        if(st > bestStr + 1.0e-12)
            bestStr = st;
    }
    int bestSlot = TELEMETRY_NULL_INT;
    for(int slot2 = 0; slot2 < TELEMETRY_STRATEGY_SLOTS; slot2++) {
        if((activeMask & (1 << slot2)) == 0)
            continue;
        bool nst2 = false;
        const double st2 = CsvTelemetry_ParseDouble(parts[TCOL_STR_STRENGTH(slot2)], nst2);
        if(nst2)
            continue;
        if(MathAbs(st2 - bestStr) > 1.0e-12)
            continue;
        if(bestSlot == TELEMETRY_NULL_INT || slot2 < bestSlot)
            bestSlot = slot2;
    }
    if(bestSlot == TELEMETRY_NULL_INT)
        return;
    bool ns = false, nst3 = false;
    outSlot = bestSlot;
    outSig = CsvTelemetry_ParseInt(parts[TCOL_STR_SIG(bestSlot)], ns);
    outStr = CsvTelemetry_ParseDouble(parts[TCOL_STR_STRENGTH(bestSlot)], nst3);
}

//+------------------------------------------------------------------+
string JoinValidation_Dstr8(const double v) {
    return DoubleToString(v, 8);
}

//+------------------------------------------------------------------+
//| JOINED_SLIM: backward-only max(bar_utc <= deal_time).            |
//| If no eligible bar: ORPHAN_DEAL, j_bar_utc=0, j_bar_latency_sec=0,|
//| telemetry-derived fields use TELEMETRY_NULL_* / empty t_symbol.  |
//+------------------------------------------------------------------+
bool JoinValidation_BuildJoinedSlimCase001(string &parts[],
                                         const long d_time_utc,
                                         const ulong d_ticket,
                                         const ulong d_position_id,
                                         const long d_magic,
                                         const double d_volume,
                                         const double d_price,
                                         const double d_profit,
                                         const double d_commission,
                                         const double d_swap,
                                         const int d_type,
                                         const int d_entry,
                                         const int d_reason,
                                         const string joiner_build,
                                         string &outLine) {
    outLine = "";
    const int need = TelemetryCsvV1_ExpectedColumns();
    if(ArraySize(parts) != need)
        return false;
    const long barUtc = (long)StringToInteger(parts[TCOL_BAR_UTC]);
    const bool eligible = (barUtc <= d_time_utc);
    const double xNet = d_profit + d_commission + d_swap;
    const string nullD = JoinValidation_Dstr8(TELEMETRY_NULL_DOUBLE);
    const string nullI = IntegerToString(TELEMETRY_NULL_INT);

    outLine = "AS_JOINED_V1,1,0,";
    outLine += JOIN_VALIDATION_JOIN_SEMANTIC;
    outLine += ",";
    outLine += IntegerToString((long)d_ticket);
    outLine += ",";
    outLine += IntegerToString((long)d_position_id);
    outLine += ",";
    outLine += IntegerToString(d_magic);
    outLine += ",";
    outLine += IntegerToString(d_time_utc);
    outLine += ",";

    if(!eligible) {
        outLine += "0,ORPHAN_DEAL,0,";
        outLine += IntegerToString(d_entry);
        outLine += ",,";
        outLine += nullI;
        outLine += ",0,";
        outLine += nullI;
        outLine += ",";
        outLine += nullI;
        outLine += ",";
        outLine += nullD;
        outLine += ",";
        outLine += nullD;
        outLine += ",";
        outLine += nullD;
        outLine += ",";
        outLine += nullD;
        outLine += ",";
        outLine += nullI;
        outLine += ",";
        outLine += nullD;
        outLine += ",";
        outLine += nullD;
        outLine += ",";
        outLine += nullI;
        outLine += ",";
        outLine += nullI;
        outLine += ",";
        outLine += nullI;
        outLine += ",0,";
        outLine += nullI;
        outLine += ",0,";
        outLine += nullD;
        outLine += ",";
        outLine += IntegerToString((int)REGIME_PROXY_UNKNOWN);
        outLine += ",";
        outLine += IntegerToString((int)QUALITY_BIN_NULL);
        outLine += ",";
        outLine += IntegerToString(d_type);
        outLine += ",";
        outLine += JoinValidation_Dstr8(d_volume);
        outLine += ",";
        outLine += JoinValidation_Dstr8(d_price);
        outLine += ",";
        outLine += JoinValidation_Dstr8(d_profit);
        outLine += ",";
        outLine += JoinValidation_Dstr8(d_commission);
        outLine += ",";
        outLine += JoinValidation_Dstr8(d_swap);
        outLine += ",";
        outLine += IntegerToString(d_reason);
        outLine += ",";
        outLine += JoinValidation_Dstr8(xNet);
        outLine += ",";
        outLine += TELEMETRY_SCHEMA_ID_ASCII;
        outLine += ",";
        outLine += joiner_build;
        return true;
    }

    string work[];
    JoinValidation_CopyParts(parts, work);
    TelemetryCsvRow row;
    if(!CsvTelemetry_ParseDataRow(work, row))
        return false;

    const string j_status = "OK";
    const long j_bar = barUtc;
    const long latency = d_time_utc - j_bar;
    if(latency < 0)
        return false;

    const int mask = JoinValidation_ActiveSlotMask(parts);
    int ls = TELEMETRY_NULL_INT;
    int lsig = 0;
    double lstr = 0.0;
    JoinValidation_LeaderSlotDeterministic(parts, mask, ls, lsig, lstr);

    const ENUM_REGIME_PROXY rp = RegimeProxy_Classify(row);
    const ENUM_QUALITY_BIN qb = QualityAnalytics_ClassifyBin(row);

    outLine += IntegerToString(j_bar);
    outLine += ",";
    outLine += j_status;
    outLine += ",";
    outLine += IntegerToString(latency);
    outLine += ",";
    outLine += IntegerToString(d_entry);
    outLine += ",";
    outLine += parts[TCOL_SYMBOL];
    outLine += ",";
    outLine += parts[TCOL_PERIOD];
    outLine += ",";
    outLine += IntegerToString(barUtc);
    outLine += ",";
    outLine += parts[TCOL_SESSION];
    outLine += ",";
    outLine += parts[TCOL_HOUR_WIT];
    outLine += ",";
    outLine += parts[TCOL_SPREAD_PTS];
    outLine += ",";
    outLine += parts[TCOL_ADX];
    outLine += ",";
    outLine += parts[TCOL_VOL_RATIO];
    outLine += ",";
    outLine += parts[TCOL_QUALITY];
    outLine += ",";
    outLine += parts[TCOL_CONSENSUS];
    outLine += ",";
    outLine += parts[TCOL_CONSENSUS_STRENGTH];
    outLine += ",";
    outLine += parts[TCOL_AGREEMENT_PCT];
    outLine += ",";
    outLine += parts[TCOL_REJECT_CODE];
    outLine += ",";
    outLine += parts[TCOL_RISK_HALT];
    outLine += ",";
    outLine += parts[TCOL_COOLDOWN_FLAG];
    outLine += ",";
    outLine += IntegerToString(mask);
    outLine += ",";
    outLine += IntegerToString(ls);
    outLine += ",";
    outLine += IntegerToString(lsig);
    outLine += ",";
    outLine += JoinValidation_Dstr8(lstr);
    outLine += ",";
    outLine += IntegerToString((int)rp);
    outLine += ",";
    outLine += IntegerToString((int)qb);
    outLine += ",";
    outLine += IntegerToString(d_type);
    outLine += ",";
    outLine += JoinValidation_Dstr8(d_volume);
    outLine += ",";
    outLine += JoinValidation_Dstr8(d_price);
    outLine += ",";
    outLine += JoinValidation_Dstr8(d_profit);
    outLine += ",";
    outLine += JoinValidation_Dstr8(d_commission);
    outLine += ",";
    outLine += JoinValidation_Dstr8(d_swap);
    outLine += ",";
    outLine += IntegerToString(d_reason);
    outLine += ",";
    outLine += JoinValidation_Dstr8(xNet);
    outLine += ",";
    outLine += TELEMETRY_SCHEMA_ID_ASCII;
    outLine += ",";
    outLine += joiner_build;
    return true;
}

//+------------------------------------------------------------------+
//| Case_008+: append deterministic lifecycle rollup annotations     |
//| after the slim join row (same bytes as Case001 + two columns). |
//| `x_lifecycle_group_id` = frozen position campaign id (here      |
//| `d_position_id`); `x_lifecycle_seq` = 0-based order within the   |
//| canonical sort `(d_time_utc ASC, d_ticket ASC)`.               |
//+------------------------------------------------------------------+
void JoinValidation_AppendLifecycleRollupSuffix(string &ioJoinedLine,
                                                const ulong lifecycle_group_id,
                                                const int lifecycle_seq) {
    ioJoinedLine += ",";
    ioJoinedLine += IntegerToString((long)lifecycle_group_id);
    ioJoinedLine += ",";
    ioJoinedLine += IntegerToString(lifecycle_seq);
}

#endif // __AURUM_JOIN_VALIDATION_PROTOTYPE_MQH__
