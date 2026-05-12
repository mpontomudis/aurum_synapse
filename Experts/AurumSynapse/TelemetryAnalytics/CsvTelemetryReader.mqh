//+------------------------------------------------------------------+
//|                                          CsvTelemetryReader.mqh  |
//|     Parse AS_TELEMETRY_V1 CSV lines (FILE_COMMON read-only).    |
//|     Column count + order = TelemetryWriter (single source).     |
//+------------------------------------------------------------------+
#ifndef __AURUM_CSV_TELEMETRY_READER_MQH__
#define __AURUM_CSV_TELEMETRY_READER_MQH__

#include "AnalyticsConfig.mqh"
#include "AnalyticsTypes.mqh"
#include "../Telemetry/TelemetryVersion.mqh"
#include "../Telemetry/TelemetryWriter.mqh"

//--- Delimiter: comma (must match TelemetryWriter `out += ","`)
#define TELEMETRY_CSV_FIELD_SEP        ((ushort)',')

//+------------------------------------------------------------------+
//| Read one physical line (newline-delimited). Uses FILE_BIN-style |
//| byte reads so .csv is never interpreted as CSV field mode.      |
//| CRLF: consumes optional LF after CR; lone CR ends line.          |
//| Returns false only when EOF with no bytes read for a new line.   |
//+------------------------------------------------------------------+
bool CsvTelemetry_ReadPhysicalLine(const int fh, string &outLine) {
    outLine = "";
    int len = 0;
    while(len < ANALYTICS_MAX_LINE_CHARS) {
        uchar b[1];
        const uint n = FileReadArray(fh, b, 0, 1);
        if(n != 1)
            return (StringLen(outLine) > 0);
        len++;
        const uchar c = b[0];
        if(c == '\n')
            return true;
        if(c == '\r') {
            uchar b2[1];
            if(FileReadArray(fh, b2, 0, 1) == 1 && b2[0] != (uchar)'\n')
                FileSeek(fh, -1, SEEK_CUR);
            return true;
        }
        outLine += CharToString(b[0]);
    }
    return (StringLen(outLine) > 0);
}

static bool g_csvForensicFirstRejectDone = false;
static string g_csvParseFailStage = "";

//+------------------------------------------------------------------+
//| Mute built-in first-reject prints (e.g. analytics uses its own).  |
//+------------------------------------------------------------------+
void CsvTelemetry_ForensicSuppressBuiltinOncePrints(void) {
    g_csvForensicFirstRejectDone = true;
}

//+------------------------------------------------------------------+
void CsvTelemetry_ForensicResetBuiltinOncePrints(void) {
    g_csvForensicFirstRejectDone = false;
}

//+------------------------------------------------------------------+
string CsvTelemetry_LastParseFailStage(void) {
    return g_csvParseFailStage;
}

//+------------------------------------------------------------------+
//| First rejected row only — full raw line + tokenization snapshot. |
//+------------------------------------------------------------------+
void CsvTelemetry_ForensicFirstRejectOnce(const string rawLine,
                                          const string &tok[],
                                          const int tokCount,
                                          const string stage) {
    if(g_csvForensicFirstRejectDone)
        return;
    g_csvForensicFirstRejectDone = true;

    const int expectedCols = TelemetryCsvV1_ExpectedColumns();
    string c0 = "";
    string c1 = "";
    string c2 = "";
    string c3 = "";
    string c4 = "";
    if(tokCount > 0)
        c0 = tok[0];
    if(tokCount > 1)
        c1 = tok[1];
    if(tokCount > 2)
        c2 = tok[2];
    if(tokCount > 3)
        c3 = tok[3];
    if(tokCount > 4)
        c4 = tok[4];

    string schemaTrim = c0;
    StringTrimLeft(schemaTrim);
    StringTrimRight(schemaTrim);

    Print("[TelemetryCSV forensic ONCE] stage=", stage);
    Print("RAW=", rawLine);
    Print("TOKENS=", IntegerToString(tokCount));
    Print("COL0=", c0);
    Print("COL1=", c1);
    Print("COL2=", c2);
    Print("COL3=", c3);
    Print("COL4=", c4);
    Print("EXPECTED_COLS=", IntegerToString(expectedCols));
    Print("StringSplit delimiter ushort=", (int)TELEMETRY_CSV_FIELD_SEP, " (comma ASCII 44)");
    Print("SCHEMA_COL0_trimmed=", schemaTrim);
}

//+------------------------------------------------------------------+
//| Expected logical column count = split(TelemetryWriter header).   |
//+------------------------------------------------------------------+
int TelemetryCsvV1_ExpectedColumns(void) {
    static int s_cached = 0;
    if(s_cached > 0)
        return s_cached;
    const string hdr = TelemetryWriter_CsvHeaderLine();
    string tmp[];
    const int n = StringSplit(hdr, TELEMETRY_CSV_FIELD_SEP, tmp);
    s_cached = n;
    return s_cached;
}

//+------------------------------------------------------------------+
bool CsvTelemetry_IsNullIntToken(const string s) {
    return (s == IntegerToString(TELEMETRY_NULL_INT));
}

bool CsvTelemetry_IsNullDoubleToken(const string s) {
    if(s == "")
        return true;
    const double v = StringToDouble(s);
    if(v != v)
        return true;
    if(v <= -1.0e99)
        return true;
    return false;
}

double CsvTelemetry_ParseDouble(const string s, bool &isNull) {
    isNull = CsvTelemetry_IsNullDoubleToken(s);
    if(isNull)
        return 0.0;
    return StringToDouble(s);
}

int CsvTelemetry_ParseInt(const string s, bool &isNull) {
    isNull = (s == "" || CsvTelemetry_IsNullIntToken(s));
    if(isNull)
        return 0;
    return (int)StringToInteger(s);
}

//+------------------------------------------------------------------+
void CsvTelemetry_TrimString(string &s) {
    StringTrimLeft(s);
    StringTrimRight(s);
}

//+------------------------------------------------------------------+
void CsvTelemetry_TrimParts(string &parts[]) {
    const int n = ArraySize(parts);
    for(int i = 0; i < n; i++) {
        CsvTelemetry_TrimString(parts[i]);
        StringReplace(parts[i], "\r", "");
        StringReplace(parts[i], "\n", "");
    }
}

//+------------------------------------------------------------------+
//| If TimeToString(bar_time) contains commas, naive split inflates   |
//| token count. Merge tokens [2 .. 2+extra-1] back into bar_time.   |
//| Writer order: schema, bar_utc, bar_time, symbol, ...             |
//+------------------------------------------------------------------+
bool CsvTelemetry_NormalizeColumnCount(string &raw[], const int need, string &out[]) {
    const int n = ArraySize(raw);
    if(n < need)
        return false;
    const int extra = n - need;
    if(extra == 0) {
        ArrayResize(out, need);
        for(int i = 0; i < need; i++)
            out[i] = raw[i];
        return true;
    }
    ArrayResize(out, need);
    out[0] = raw[0];
    out[1] = raw[1];
    string bt = raw[2];
    for(int j = 0; j < extra; j++)
        bt += "," + raw[3 + j];
    out[2] = bt;
    for(int k = 3; k < need; k++)
        out[k] = raw[k + extra];
    return true;
}

//+------------------------------------------------------------------+
bool CsvTelemetry_PrepareFieldsFromLine(const string lineIn, string &outParts[]) {
    ArrayResize(outParts, 0);
    string line = lineIn;
    CsvTelemetry_TrimString(line);
    if(line == "")
        return false;
    if((int)StringGetCharacter(line, 0) == 0xFEFF)
        line = StringSubstr(line, 1);
    string raw[];
    const int n = StringSplit(line, TELEMETRY_CSV_FIELD_SEP, raw);
    if(n < 1) {
        CsvTelemetry_ForensicFirstRejectOnce(line, raw, n, "prepare_empty_split");
        return false;
    }
    CsvTelemetry_TrimParts(raw);
    const int need = TelemetryCsvV1_ExpectedColumns();
    if(n < need) {
        CsvTelemetry_ForensicFirstRejectOnce(line, raw, n, "prepare_n_lt_expected");
        return false;
    }
    if(!CsvTelemetry_NormalizeColumnCount(raw, need, outParts)) {
        CsvTelemetry_ForensicFirstRejectOnce(line, raw, n, "prepare_normalize_failed");
        return false;
    }
    return true;
}

//+------------------------------------------------------------------+
bool CsvTelemetry_ParseDataRow(string &parts[], TelemetryCsvRow &row, const string rawLine) {
    ZeroMemory(row);
    row.valid = false;
    g_csvParseFailStage = "";
    const int need = TelemetryCsvV1_ExpectedColumns();
    if(ArraySize(parts) != need) {
        g_csvParseFailStage = "parse_size_mismatch";
        CsvTelemetry_ForensicFirstRejectOnce(rawLine, parts, ArraySize(parts), "parse_size_mismatch");
        return false;
    }
    CsvTelemetry_TrimString(parts[0]);
    if(parts[0] != TELEMETRY_SCHEMA_ID_ASCII) {
        g_csvParseFailStage = "parse_schema_mismatch";
        CsvTelemetry_ForensicFirstRejectOnce(rawLine, parts, ArraySize(parts), "parse_schema_mismatch");
        return false;
    }

    row.adx = CsvTelemetry_ParseDouble(parts[TCOL_ADX], row.null_adx);
    row.volatility_ratio = CsvTelemetry_ParseDouble(parts[TCOL_VOL_RATIO], row.null_vol);
    row.bb_width = CsvTelemetry_ParseDouble(parts[TCOL_BB_WIDTH], row.null_bb);
    row.spread_points = CsvTelemetry_ParseDouble(parts[TCOL_SPREAD_PTS], row.null_spread);
    row.session_code = CsvTelemetry_ParseInt(parts[TCOL_SESSION], row.null_session);
    row.hour_wit = CsvTelemetry_ParseInt(parts[TCOL_HOUR_WIT], row.null_hour);
    row.quality = CsvTelemetry_ParseDouble(parts[TCOL_QUALITY], row.null_quality);
    row.consensus_code = CsvTelemetry_ParseInt(parts[TCOL_CONSENSUS], row.null_consensus);
    row.consensus_strength = CsvTelemetry_ParseDouble(parts[TCOL_CONSENSUS_STRENGTH], row.null_consensus_strength);
    row.agreement_pct = CsvTelemetry_ParseDouble(parts[TCOL_AGREEMENT_PCT], row.null_agreement);
    row.risk_halt_flag = CsvTelemetry_ParseInt(parts[TCOL_RISK_HALT], row.null_risk_halt);

    for(int i = 0; i < TELEMETRY_STRATEGY_SLOTS; i++) {
        row.strategy_signal[i] = CsvTelemetry_ParseInt(parts[TCOL_STR_SIG(i)], row.null_str_sig[i]);
        row.strategy_strength[i] = CsvTelemetry_ParseDouble(parts[TCOL_STR_STRENGTH(i)], row.null_str_strength[i]);
        row.strategy_active[i] = CsvTelemetry_ParseInt(parts[TCOL_STR_ACTIVE(i)], row.null_str_active[i]);
    }

    row.valid = true;
    return true;
}

//+------------------------------------------------------------------+
bool CsvTelemetry_IsHeaderRow(string &parts[]) {
    if(ArraySize(parts) < 1)
        return false;
    string a = parts[0];
    CsvTelemetry_TrimString(a);
    return (a == "schema");
}

#endif // __AURUM_CSV_TELEMETRY_READER_MQH__
