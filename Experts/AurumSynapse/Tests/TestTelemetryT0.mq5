//+------------------------------------------------------------------+
//|                                          TestTelemetryT0.mq5     |
//|                    Compile-smoke: T0 telemetry schema (no EA)  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "1.00"
#property description "T0 — verify Telemetry/ headers compile + manager no-op"

#include "../Telemetry/AurumTelemetry.mqh"

//+------------------------------------------------------------------+
int OnInit() {
    CTelemetryManager mgr;
    if(!mgr.Init()) {
        Print("[TestTelemetryT0] Init unexpected failure");
        return INIT_FAILED;
    }
    TelemetryBarRow row;
    mgr.PrepareEmptyBarRow(row);
    Print("[TestTelemetryT0] schema=", row.schema_id, " state=", (int)mgr.GetState());
    mgr.Deinit();
    Print("[TestTelemetryT0] PASS");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnTick() {
    // no-op — smoke is OnInit-only
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
}
