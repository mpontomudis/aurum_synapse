//+------------------------------------------------------------------+
//|                                          TestTelemetryT1.mq5     |
//|          Compile-smoke: T1 passive collector + ring (no EA)     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "1.00"
#property description "T1 — verify TelemetryCollector path compiles (AURUM_TELEMETRY_T1)"

#define AURUM_TELEMETRY_T1
#include "../Telemetry/TelemetryCollector.mqh"

//+------------------------------------------------------------------+
int OnInit() {
    MarketState ms;
    ZeroMemory(ms);
    SignalResult signals[8];
    for(int i = 0; i < 8; i++) {
        signals[i].strategyName = "";
        signals[i].signal = SIGNAL_NONE;
        signals[i].strength = 0.0;
        signals[i].weight = 0.0;
        signals[i].isActive = false;
    }
    TelemetryCollector_OnBarPassive(TimeCurrent(), ms, signals, SIGNAL_NONE,
                                      0.0, 0.0, TELEMETRY_NULL_DOUBLE, true);
    Print("[TestTelemetryT1] write_cursor=", TelemetryRingBuffer_WriteCursor(),
          " capacity=", TelemetryRingBuffer_Capacity(), " PASS");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnTick() {
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
}
