//+------------------------------------------------------------------+
//|                                      TestTelemetryAnalytics.mq5  |
//|     Phase 3A — scan AS_TELEMETRY_V1_*.csv (FILE_COMMON) + report |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "1.00"
#property description "Phase 3A shadow analytics — no EA, no execution hooks"

#include "../TelemetryAnalytics/AnalyticsAggregator.mqh"

//+------------------------------------------------------------------+
int OnInit() {
    string report = "";
    ulong totalBars = 0;
    ulong parseErrors = 0;
    AnalyticsAggregator_Run(report, totalBars, parseErrors);
    Print(report);
    Print("[TestTelemetryAnalytics] done rows=", totalBars, " rejects=", parseErrors);
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnTick() {
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
}
