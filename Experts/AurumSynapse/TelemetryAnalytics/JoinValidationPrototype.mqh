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

#endif // __AURUM_JOIN_VALIDATION_PROTOTYPE_MQH__
