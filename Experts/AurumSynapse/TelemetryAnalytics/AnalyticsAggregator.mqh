//+------------------------------------------------------------------+
//|                                         AnalyticsAggregator.mqh  |
//|     Scan telemetry CSVs (FILE_COMMON) → shadow summary.         |
//+------------------------------------------------------------------+
#ifndef __AURUM_ANALYTICS_AGGREGATOR_MQH__
#define __AURUM_ANALYTICS_AGGREGATOR_MQH__

#include "AnalyticsConfig.mqh"
#include "CsvTelemetryReader.mqh"
#include "RegimeAnalytics.mqh"
#include "SessionAnalytics.mqh"
#include "QualityAnalytics.mqh"
#include "StrategyFitness.mqh"

static bool g_analyticsForensicPrinted = false;
static int g_analyticsFileOpenDiagSerial = 0;

//+------------------------------------------------------------------+
string AnalyticsAggregator_ForensicTokenAt(const string &tok[], const int i) {
    if(i < 0 || i >= ArraySize(tok))
        return "";
    return tok[i];
}

//+------------------------------------------------------------------+
void AnalyticsAggregator_ForensicPrintOnce(const string stage,
                                           const string rawLine,
                                           const string &tokSrc[],
                                           const int tokenCount,
                                           const int normalizedCols,
                                           const string schemaToken) {
    // TEMP: every call logs ENTER before one-shot guard (proves invocation vs UI truncation).
    Print("[ANALYTICS_FORENSIC_ENTER]");
    if(g_analyticsForensicPrinted)
        return;
    g_analyticsForensicPrinted = true;

    const int expected = TelemetryCsvV1_ExpectedColumns();
    Print("[ANALYTICS_FORENSIC]");
    Print("stage=", stage);
    Print("raw_line=", rawLine);
    Print("token_count=", IntegerToString(tokenCount));
    Print("expected_cols=", IntegerToString(expected));
    Print("normalized_cols=", IntegerToString(normalizedCols));
    Print("schema_token=", schemaToken);
    Print("token0=", AnalyticsAggregator_ForensicTokenAt(tokSrc, 0));
    Print("token1=", AnalyticsAggregator_ForensicTokenAt(tokSrc, 1));
    Print("token2=", AnalyticsAggregator_ForensicTokenAt(tokSrc, 2));
    Print("token3=", AnalyticsAggregator_ForensicTokenAt(tokSrc, 3));
    Print("token4=", AnalyticsAggregator_ForensicTokenAt(tokSrc, 4));
    Print("token5=", AnalyticsAggregator_ForensicTokenAt(tokSrc, 5));
    Print("token6=", AnalyticsAggregator_ForensicTokenAt(tokSrc, 6));
    Print("token7=", AnalyticsAggregator_ForensicTokenAt(tokSrc, 7));
    Print("token8=", AnalyticsAggregator_ForensicTokenAt(tokSrc, 8));
    Print("token9=", AnalyticsAggregator_ForensicTokenAt(tokSrc, 9));
}

//+------------------------------------------------------------------+
void AnalyticsAggregator_SortPaths(string &paths[]) {
    const int n = ArraySize(paths);
    for(int i = 0; i < n - 1; i++) {
        for(int j = i + 1; j < n; j++) {
            if(paths[i] > paths[j]) {
                const string t = paths[i];
                paths[i] = paths[j];
                paths[j] = t;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| FileFindFirst/Next return file NAME only (no path). Build rel.   |
//| path under FILE_COMMON root: AurumSynapse\telemetry\<name>.csv  |
//+------------------------------------------------------------------+
string AnalyticsAggregator_CommonRelPathFromFindName(const string fnFromFind) {
    if(StringLen(fnFromFind) < 1)
        return fnFromFind;
    if(StringFind(fnFromFind, "AurumSynapse\\") == 0 || StringFind(fnFromFind, "AurumSynapse/") == 0)
        return fnFromFind;
    if(StringFind(fnFromFind, ":") >= 0)
        return fnFromFind;
    return ANALYTICS_TELEMETRY_FOLDER + fnFromFind;
}

//+------------------------------------------------------------------+
void AnalyticsAggregator_CollectCsvPaths(string &paths[]) {
    ArrayResize(paths, 0);
    string fn = "";
    Print("[ANALYTICS_FILEFIND] glob=", ANALYTICS_TELEMETRY_FILE_GLOB, " FILE_COMMON");
    const long handle = FileFindFirst(ANALYTICS_TELEMETRY_FILE_GLOB, fn, FILE_COMMON);
    if(handle == INVALID_HANDLE) {
        Print("[ANALYTICS_FILEFIND] FileFindFirst INVALID_HANDLE GetLastError=", IntegerToString(GetLastError()));
        return;
    }
    int idx = 0;
    Print("[ANALYTICS_FILEFIND] FileFindFirst name=", fn);
    while(true) {
        const int n = ArraySize(paths);
        ArrayResize(paths, n + 1);
        paths[n] = AnalyticsAggregator_CommonRelPathFromFindName(fn);
        if(idx < 3)
            Print("[ANALYTICS_FILEFIND] idx=", IntegerToString(idx), " raw_name=", fn, " stored_relPath=", paths[n]);
        idx++;
        if(!FileFindNext(handle, fn))
            break;
        if(idx < 3)
            Print("[ANALYTICS_FILEFIND] FileFindNext name=", fn);
    }
    FileFindClose(handle);
    AnalyticsAggregator_SortPaths(paths);
    Print("[ANALYTICS_FILEFIND] total_matched=", IntegerToString(ArraySize(paths)));
}

//+------------------------------------------------------------------+
void AnalyticsAggregator_ProcessFile(const string relPath,
                                     RegimeAnalyticsState &reg,
                                     SessionAnalyticsState &ses,
                                     QualityAnalyticsState &qual,
                                     StrategyFitnessState &fit,
                                     ulong &totalBars,
                                     ulong &parseErrors,
                                     ulong &skippedHeader) {
    g_analyticsFileOpenDiagSerial++;
    const bool loudDiag = (g_analyticsFileOpenDiagSerial <= 1);
    const bool existsPre = FileIsExist(relPath, FILE_COMMON);
    if(loudDiag) {
        Print("[ANALYTICS_FILEOPEN] relPath=", relPath);
        Print("[ANALYTICS_FILEOPEN] flags=FILE_READ|FILE_BIN|FILE_ANSI|FILE_COMMON");
        Print("[ANALYTICS_FILEOPEN] FileIsExist=", existsPre ? "true" : "false");
    }
    ResetLastError();
    const int fh = FileOpen(relPath, FILE_READ | FILE_BIN | FILE_ANSI | FILE_COMMON);
    const int errPost = (int)GetLastError();
    if(loudDiag)
        Print("[ANALYTICS_FILEOPEN] GetLastError=", IntegerToString(errPost));
    if(fh == INVALID_HANDLE) {
        Print("[ANALYTICS_FILEOPEN] FAIL serial=", IntegerToString(g_analyticsFileOpenDiagSerial),
              " relPath=", relPath, " FileIsExist=", existsPre ? "true" : "false",
              " GetLastError=", IntegerToString(errPost));
        Print("[ANALYTICS_REJECT_STAGE] stage=file_open");
        parseErrors++;
        return;
    }
    while(true) {
        string line;
        if(!CsvTelemetry_ReadPhysicalLine(fh, line))
            break;
        StringTrimLeft(line);
        StringTrimRight(line);
        if(StringLen(line) == 0)
            continue;
        if((int)StringGetCharacter(line, 0) == 0xFEFF)
            line = StringSubstr(line, 1);
        string parts[];
        if(!CsvTelemetry_PrepareFieldsFromLine(line, parts)) {
            string work = line;
            CsvTelemetry_TrimString(work);
            string raw[];
            const int nRaw = StringSplit(work, TELEMETRY_CSV_FIELD_SEP, raw);
            CsvTelemetry_TrimParts(raw);
            const int needCols = TelemetryCsvV1_ExpectedColumns();
            string normTmp[];
            int normN = 0;
            if(nRaw >= needCols && CsvTelemetry_NormalizeColumnCount(raw, needCols, normTmp))
                normN = ArraySize(normTmp);
            string stg = "prepare_normalize_failed";
            if(nRaw < 1)
                stg = "prepare_empty_split";
            else if(nRaw < needCols)
                stg = "prepare_n_lt_expected";
            string sch = "";
            if(nRaw > 0)
                sch = raw[0];
            AnalyticsAggregator_ForensicPrintOnce(stg, line, raw, nRaw, normN, sch);
            Print("[ANALYTICS_REJECT_STAGE] stage=prepare");
            parseErrors++;
            continue;
        }
        if(CsvTelemetry_IsHeaderRow(parts)) {
            skippedHeader++;
            continue;
        }
        TelemetryCsvRow row;
        if(!CsvTelemetry_ParseDataRow(parts, row, line)) {
            string stg = CsvTelemetry_LastParseFailStage();
            if(stg == "")
                stg = "parse_unknown";
            const int pc = ArraySize(parts);
            string sch = "";
            if(pc > 0)
                sch = parts[0];
            AnalyticsAggregator_ForensicPrintOnce(stg, line, parts, pc, pc, sch);
            Print("[ANALYTICS_REJECT_STAGE] stage=parse");
            parseErrors++;
            continue;
        }
        totalBars++;
        const ENUM_REGIME_PROXY rp = RegimeProxy_Classify(row);
        RegimeAnalytics_Feed(reg, row, rp);
        SessionAnalytics_Feed(ses, row);
        QualityAnalytics_Feed(qual, row);
        StrategyFitness_Feed(fit, row, rp);
    }
    FileClose(fh);
}

//+------------------------------------------------------------------+
int AnalyticsAggregator_MaxRegimeBars(const RegimeAnalyticsState &reg) {
    int best = 0;
    ulong bestN = 0;
    for(int i = 0; i < REGIME_PROXY_COUNT; i++) {
        if(reg.bars[i] > bestN) {
            bestN = reg.bars[i];
            best = i;
        }
    }
    return best;
}

//+------------------------------------------------------------------+
void AnalyticsAggregator_Run(string &report,
                               ulong &outTotalBars,
                               ulong &outParseErrors) {
    CsvTelemetry_ForensicSuppressBuiltinOncePrints();
    g_analyticsForensicPrinted = false;
    g_analyticsFileOpenDiagSerial = 0;
    outTotalBars = 0;
    outParseErrors = 0;
    ulong skippedHeader = 0;

    RegimeAnalyticsState reg;
    SessionAnalyticsState ses;
    QualityAnalyticsState qual;
    StrategyFitnessState fit;
    RegimeAnalytics_Reset(reg);
    SessionAnalytics_Reset(ses);
    QualityAnalytics_Reset(qual);
    StrategyFitness_Reset(fit);

    string paths[];
    AnalyticsAggregator_CollectCsvPaths(paths);
    const int nfiles = ArraySize(paths);

    report = "=== PHASE 3A — SHADOW TELEMETRY ANALYTICS (Stream A) ===\n";
    report += "Source: FILE_COMMON glob ";
    report += ANALYTICS_TELEMETRY_FILE_GLOB;
    report += "\n";
    report += "Files matched: ";
    report += IntegerToString(nfiles);
    report += "\n";

    for(int f = 0; f < nfiles; f++) {
        report += "  + ";
        report += paths[f];
        report += "\n";
        AnalyticsAggregator_ProcessFile(paths[f], reg, ses, qual, fit, outTotalBars, outParseErrors, skippedHeader);
    }

    report += "\n--- Totals ---\n";
    report += "Data rows (bars) parsed: ";
    report += DoubleToString((double)outTotalBars, 0);
    report += "\n";
    report += "Parse/filter rejects: ";
    report += DoubleToString((double)outParseErrors, 0);
    report += "\n";
    report += "Header rows skipped: ";
    report += DoubleToString((double)skippedHeader, 0);
    report += "\n";

    report += "\n--- REGIME_PROXY (derived from ADX / vol_ratio; not ENUM_REGIME) ---\n";
    for(int i = 0; i < REGIME_PROXY_COUNT; i++) {
        const ENUM_REGIME_PROXY rp = (ENUM_REGIME_PROXY)i;
        report += RegimeProxy_Name(rp);
        report += " | bars=";
        report += IntegerToString((int)reg.bars[i]);
        report += " | meanADX=";
        report += DoubleToString(reg.adx[i].Mean(), 2);
        report += " | meanVolRatio=";
        report += DoubleToString(reg.volRatio[i].Mean(), 4);
        report += " | meanQuality=";
        report += DoubleToString(reg.quality[i].Mean(), 2);
        report += " | meanAgreement%=";
        report += DoubleToString(reg.agreement[i].Mean(), 2);
        report += " | riskHaltBars=";
        report += IntegerToString((int)reg.riskHaltBars[i]);
        report += "\n";
    }

    report += "\n--- SESSION (session_code) ---\n";
    for(int s = 0; s < SESSION_ANALYTICS_BUCKETS; s++) {
        if(ses.bars[s] == 0)
            continue;
        report += SessionAnalytics_BucketLabel(s);
        report += " | bars=";
        report += IntegerToString((int)ses.bars[s]);
        report += " | meanQuality=";
        report += DoubleToString(ses.quality[s].Mean(), 2);
        report += " | meanAgreement%=";
        report += DoubleToString(ses.agreement[s].Mean(), 2);
        report += "\n";
    }

    report += "\n--- QUALITY BINS ---\n";
    for(int q = 0; q < QUALITY_BIN_COUNT; q++) {
        if(qual.bars[q] == 0)
            continue;
        report += QualityAnalytics_BinName(q);
        report += " | bars=";
        report += IntegerToString((int)qual.bars[q]);
        report += " | meanConsensusStr=";
        report += DoubleToString(qual.consensusStrength[q].Mean(), 4);
        report += " | meanAgreement%=";
        report += DoubleToString(qual.agreement[q].Mean(), 2);
        report += " | riskHaltBars=";
        report += IntegerToString((int)qual.riskHaltBars[q]);
        report += "\n";
    }

    report += "\n--- STRATEGY × REGIME_PROXY (descriptive; not P/L) ---\n";
    report += "Columns: slot | regime | bars | active% | meanStr@active | signal==consensus%\n";
    for(int r = 0; r < REGIME_PROXY_COUNT; r++) {
        for(int c = 0; c < TELEMETRY_STRATEGY_SLOTS; c++) {
            const StrategySlotRegimeStats z = fit.cell[r][c];
            if(z.bars < 1)
                continue;
            const double ap = (100.0 * (double)z.activeBars / (double)z.bars);
            const double mp = (z.activeBars > 0
                                ? (100.0 * (double)z.signalMatchesConsensus / (double)z.activeBars)
                                : 0.0);
            report += StrategyFitness_SlotName(c);
            report += " | ";
            report += RegimeProxy_Name((ENUM_REGIME_PROXY)r);
            report += " | ";
            report += IntegerToString((int)z.bars);
            report += " | ";
            report += DoubleToString(ap, 1);
            report += "% | ";
            report += DoubleToString(z.strengthWhenActive.Mean(), 4);
            report += " | ";
            report += DoubleToString(mp, 1);
            report += "%\n";
        }
    }

    report += "\n--- SHADOW INSIGHTS (observational only; no execution) ---\n";
    if(outTotalBars < 1) {
        report += "No telemetry rows ingested. Generate T2 CSV under Common Files, then re-run.\n";
        CsvTelemetry_ForensicResetBuiltinOncePrints();
        return;
    }
    const int mr = AnalyticsAggregator_MaxRegimeBars(reg);
    report += "Most bars fall under REGIME_PROXY=";
    report += RegimeProxy_Name((ENUM_REGIME_PROXY)mr);
    report += ".\n";
    report += "This report does not include profit factor or trade outcomes (Stream B deferred).\n";
    CsvTelemetry_ForensicResetBuiltinOncePrints();
}

#endif // __AURUM_ANALYTICS_AGGREGATOR_MQH__
