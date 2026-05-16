//+------------------------------------------------------------------+
//|                                      TestTelemetryIndex.mq5      |
//|     Compile harness for TelemetryIndex.mqh (Step 1A)             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property version   "1.00"
#property description "Phase 3B — TelemetryIndex compile / smoke (FILE_COMMON optional)"

#include "../TelemetryAnalytics/TelemetryIndex.mqh"

int OnInit() {
    CTelemetryIndex idx;
    idx.Clear();
    const string root = JoinValidation_CommonFixtureRoot() + "Case_001_BasicJoin\\telemetry.csv";
    if(FileIsExist(root, FILE_COMMON)) {
        if(!idx.LoadTelemetryCsv(root)) {
            Print("[TELEMETRY_INDEX_TEST] FAIL load Case_001");
            return INIT_FAILED;
        }
        string parts[];
        int elig = 0;
        if(!idx.FindNearestBackwardBar("XAUUSD", 5, 1735689725, parts, elig)) {
            Print("[TELEMETRY_INDEX_TEST] FAIL find backward");
            return INIT_FAILED;
        }
        Print("[TELEMETRY_INDEX_TEST] PASS rows=", IntegerToString(idx.RowCount()), " eligible=", IntegerToString(elig));
    } else {
        Print("[TELEMETRY_INDEX_TEST] SKIP fixture not in FILE_COMMON (compile-only OK)");
    }
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
}
