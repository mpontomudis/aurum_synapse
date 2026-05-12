//+------------------------------------------------------------------+
//|                                          TelemetryRingBuffer.mqh |
//|                    Aurum Synapse — T1 passive memory-only buffer |
//| Fixed capacity, overwrite oldest — no ArrayResize, no heap grow. |
//+------------------------------------------------------------------+
#ifndef __AURUM_TELEMETRY_RING_BUFFER_MQH__
#define __AURUM_TELEMETRY_RING_BUFFER_MQH__

#include "TelemetryTypes.mqh"

#define TELEMETRY_T1_RING_CAPACITY  256

//--- File-local static storage (single translation unit per include site)
static TelemetryBarRow g_telemetryT1Ring[TELEMETRY_T1_RING_CAPACITY];
static int             g_telemetryT1RingWrite = 0;
static long            g_telemetryT1PushCount = 0;

//+------------------------------------------------------------------+
//| Push one row (struct copy). Oldest entries overwritten at wrap. |
//+------------------------------------------------------------------+
void TelemetryRingBuffer_PushCopy(const TelemetryBarRow &row) {
    g_telemetryT1Ring[g_telemetryT1RingWrite] = row;
    g_telemetryT1RingWrite++;
    if(g_telemetryT1RingWrite >= TELEMETRY_T1_RING_CAPACITY)
        g_telemetryT1RingWrite = 0;
    g_telemetryT1PushCount++;
}

//+------------------------------------------------------------------+
//| Read-only peek for tests / diagnostics (no mutation).            |
//+------------------------------------------------------------------+
int TelemetryRingBuffer_Capacity(void) {
    return TELEMETRY_T1_RING_CAPACITY;
}

int TelemetryRingBuffer_WriteCursor(void) {
    return g_telemetryT1RingWrite;
}

//+------------------------------------------------------------------+
//| Copy newest row into out (MQL5: no struct-pointer return type).   |
//+------------------------------------------------------------------+
bool TelemetryRingBuffer_PeekLatestWritten(TelemetryBarRow &out) {
    if(g_telemetryT1PushCount <= 0)
        return false;
    const int idx = (int)((g_telemetryT1PushCount - 1) % TELEMETRY_T1_RING_CAPACITY);
    out = g_telemetryT1Ring[idx];
    return true;
}

#endif // __AURUM_TELEMETRY_RING_BUFFER_MQH__
