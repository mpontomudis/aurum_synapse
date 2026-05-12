//+------------------------------------------------------------------+
//|                                            TelemetryRotation.mqh |
//|                    T2 segment naming — day + size triggers       |
//+------------------------------------------------------------------+
#ifndef __AURUM_TELEMETRY_ROTATION_MQH__
#define __AURUM_TELEMETRY_ROTATION_MQH__

#include "TelemetryConfig.mqh"

//+------------------------------------------------------------------+
//| YYYYMMDD from GMT                                                |
//+------------------------------------------------------------------+
int TelemetryRotation_YmdFromTime(const datetime t) {
    MqlDateTime dt;
    TimeToStruct(t, dt);
    return dt.year * 10000 + dt.mon * 100 + dt.day;
}

string TelemetryRotation_SanitizeSymbol(const string sym) {
    string r = sym;
    StringReplace(r, ".", "_");
    StringReplace(r, "\\", "_");
    StringReplace(r, "/", "_");
    StringReplace(r, ":", "_");
    StringReplace(r, "*", "_");
    StringReplace(r, "?", "_");
    StringReplace(r, "\"", "_");
    StringReplace(r, "<", "_");
    StringReplace(r, ">", "_");
    StringReplace(r, "|", "_");
    return r;
}

//+------------------------------------------------------------------+
//| Timeframe code: period minutes (deterministic, no enum spaces). |
//+------------------------------------------------------------------+
string TelemetryRotation_TimeframeCode(void) {
    const int ps = (int)PeriodSeconds(_Period);
    const int mins = (ps > 0 ? ps / 60 : 0);
    return IntegerToString(mins);
}

//+------------------------------------------------------------------+
//| Relative path under FILE_COMMON: folder + file name              |
//+------------------------------------------------------------------+
void TelemetryRotation_BuildRelativePath(const string symSan,
                                           const int ymd,
                                           const int seq,
                                           string &outRelPath) {
    string seqs = "";
    if(seq > 0)
        seqs = "_" + IntegerToString(seq);
    outRelPath = TELEMETRY_T2_REL_FOLDER + TELEMETRY_T2_FILE_PREFIX + symSan + "_" +
                 TelemetryRotation_TimeframeCode() + "_" + IntegerToString(ymd) + seqs + ".csv";
}

#endif // __AURUM_TELEMETRY_ROTATION_MQH__
