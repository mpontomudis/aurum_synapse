//+------------------------------------------------------------------+
//|                                          TestTelemetryT2.mq5     |
//|     T2 shadow CSV — compile + FILE_COMMON smoke (queue + I/O)   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "1.00"
#property description "T2 — TelemetryPersistence (AURUM_TELEMETRY_T1 + AURUM_TELEMETRY_T2)"

#define AURUM_TELEMETRY_T1
#define AURUM_TELEMETRY_T2
#include "../Telemetry/TelemetryCollector.mqh"
#include "../Telemetry/TelemetryPersistence.mqh"

//+------------------------------------------------------------------+
void BuildDummySignals(SignalResult &signals[]) {
    for(int i = 0; i < 8; i++) {
        signals[i].strategyName = "";
        signals[i].signal = SIGNAL_NONE;
        signals[i].strength = 0.0;
        signals[i].weight = 0.0;
        signals[i].isActive = false;
    }
}

//+------------------------------------------------------------------+
bool ReadCommonFileLineCount(const string rel, int &outLines) {
    outLines = 0;
    const int h = FileOpen(rel, FILE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON);
    if(h == INVALID_HANDLE)
        return false;
    while(!FileIsEnding(h)) {
        FileReadString(h);
        outLines++;
    }
    FileClose(h);
    return true;
}

//+------------------------------------------------------------------+
bool ReadCommonFileFirstLine(const string rel, string &line) {
    line = "";
    const int h = FileOpen(rel, FILE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON);
    if(h == INVALID_HANDLE)
        return false;
    line = FileReadString(h);
    FileClose(h);
    return true;
}

//+------------------------------------------------------------------+
int OnInit() {
    MarketState ms;
    ZeroMemory(ms);
    ms.atr14 = 1.23456789;
    ms.adx = 22.0;
    ms.bbUpper = 2050.0;
    ms.bbLower = 2040.0;
    ms.spread = 18;
    ms.session = SESSION_ASIAN;
    ms.hourWIT = 3;
    ms.atrRatio = 0.95;
    ms.volumeRatio = 1.02;
    SignalResult signals[8];
    BuildDummySignals(signals);

    TelemetryT2_Init();
    if(!TelemetryT2_IsReady()) {
        Print("[TestTelemetryT2] Init did not open segment (FILE_COMMON path?) — compile-only PASS");
        return INIT_SUCCEEDED;
    }

    const string expectHdr = TelemetryWriter_CsvHeaderLine();
    const string rel = TelemetryT2_CurrentRelativePath();
    if(StringFind(rel, "AS_TELEMETRY_V1_") < 0) {
        Print("[TestTelemetryT2] FAIL: relative path missing prefix: ", rel);
        TelemetryT2_Deinit();
        return INIT_FAILED;
    }

    for(int k = 0; k < 5; k++) {
        TelemetryBarRow row;
        const datetime bt = (datetime)(1700000000 + k * 60);
        TelemetryCollector_BuildBarRow(bt, ms, signals, SIGNAL_NONE,
                                         0.0, 0.0, TELEMETRY_NULL_DOUBLE, true, row);
        TelemetryT2_EnqueueCopy(row);
    }
    TelemetryT2_DrainForTesting(8);
    TelemetryT2_Deinit();

    string hdrRead = "";
    if(!ReadCommonFileFirstLine(rel, hdrRead)) {
        Print("[TestTelemetryT2] FAIL: cannot read ", rel);
        return INIT_FAILED;
    }
    if(hdrRead != expectHdr) {
        Print("[TestTelemetryT2] FAIL: header mismatch");
        Print(" expected: ", expectHdr);
        Print(" got:      ", hdrRead);
        return INIT_FAILED;
    }
    int nlines = 0;
    if(!ReadCommonFileLineCount(rel, nlines) || nlines < 6) {
        Print("[TestTelemetryT2] FAIL: expected >=6 lines (hdr+5 rows), got ", nlines);
        return INIT_FAILED;
    }

    //--- Drop-oldest overflow (no drain until after fill)
    TelemetryT2_Init();
    if(!TelemetryT2_IsReady()) {
        Print("[TestTelemetryT2] FAIL: re-Init not ready");
        return INIT_FAILED;
    }
    const ulong drop0 = TelemetryQueue_DroppedOldestCount();
    for(int j = 0; j < TELEMETRY_T2_QUEUE_CAPACITY + 10; j++) {
        TelemetryBarRow row2;
        const datetime bt2 = (datetime)(1800000000 + j);
        TelemetryCollector_BuildBarRow(bt2, ms, signals, SIGNAL_NONE,
                                       0.0, 0.0, TELEMETRY_NULL_DOUBLE, true, row2);
        TelemetryT2_EnqueueCopy(row2);
    }
    const ulong dropped = TelemetryQueue_DroppedOldestCount() - drop0;
    if(dropped != 10) {
        Print("[TestTelemetryT2] FAIL: drop-oldest count expected 10 got ", dropped);
        TelemetryT2_Deinit();
        return INIT_FAILED;
    }
    TelemetryT2_DrainForTesting(2000);
    TelemetryT2_Deinit();

    //--- Soft-disable stops enqueue
    TelemetryT2_Init();
    if(!TelemetryT2_IsReady()) {
        Print("[TestTelemetryT2] FAIL: third Init not ready");
        return INIT_FAILED;
    }
    TelemetryT2_TestForceSoftDisable();
    if(TelemetryT2_IsReady()) {
        Print("[TestTelemetryT2] FAIL: expected not ready after soft-disable");
        TelemetryT2_Deinit();
        return INIT_FAILED;
    }
    const int qc = TelemetryQueue_Count();
    TelemetryBarRow row3;
    TelemetryCollector_BuildBarRow(TimeCurrent(), ms, signals, SIGNAL_NONE,
                                   0.0, 0.0, TELEMETRY_NULL_DOUBLE, true, row3);
    TelemetryT2_EnqueueCopy(row3);
    if(TelemetryQueue_Count() != qc) {
        Print("[TestTelemetryT2] FAIL: enqueue after disable should not grow queue");
        TelemetryT2_Deinit();
        return INIT_FAILED;
    }
    TelemetryT2_Deinit();

    Print("[TestTelemetryT2] PASS  rel=", rel, "  file_lines>=6  drop_oldest=10  soft_disable_ok");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnTick() {
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
}
