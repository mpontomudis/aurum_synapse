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
    const long handle = FileFindFirst(ANALYTICS_TELEMETRY_FILE_GLOB, fn, FILE_COMMON);
    if(handle == INVALID_HANDLE)
        return;
    while(true) {
        const int n = ArraySize(paths);
        ArrayResize(paths, n + 1);
        paths[n] = AnalyticsAggregator_CommonRelPathFromFindName(fn);
        if(!FileFindNext(handle, fn))
            break;
    }
    FileFindClose(handle);
    AnalyticsAggregator_SortPaths(paths);
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
    const int fh = FileOpen(relPath, FILE_READ | FILE_BIN | FILE_ANSI | FILE_COMMON);
    if(fh == INVALID_HANDLE) {
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
            parseErrors++;
            continue;
        }
        if(CsvTelemetry_IsHeaderRow(parts)) {
            skippedHeader++;
            continue;
        }
        TelemetryCsvRow row;
        if(!CsvTelemetry_ParseDataRow(parts, row)) {
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
    report += "Telemetry schema: ";
    report += TELEMETRY_SCHEMA_VERSION;
    report += " (";
    report += TELEMETRY_SCHEMA_ID_ASCII;
    report += ")  Analytics engine: ";
    report += ANALYTICS_ENGINE_VERSION;
    report += "  Report format: ";
    report += ANALYTICS_STREAM_A_REPORT_VERSION;
    report += "\n";
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

    const string journalStatus = (outParseErrors > 0 ? "FAIL" : "PASS");
    Print("[Analytics] ", TELEMETRY_SCHEMA_ID_ASCII, " files=", IntegerToString(nfiles),
          " rows=", IntegerToString(outTotalBars), " rejects=", IntegerToString(outParseErrors),
          " ", journalStatus);

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
        return;
    }
    const int mr = AnalyticsAggregator_MaxRegimeBars(reg);
    report += "Most bars fall under REGIME_PROXY=";
    report += RegimeProxy_Name((ENUM_REGIME_PROXY)mr);
    report += ".\n";
    report += "This report does not include profit factor or trade outcomes (Stream B deferred).\n";
}

#endif // __AURUM_ANALYTICS_AGGREGATOR_MQH__
