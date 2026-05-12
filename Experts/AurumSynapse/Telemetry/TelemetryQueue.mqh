//+------------------------------------------------------------------+
//|                                               TelemetryQueue.mqh |
//|                    T2 fixed queue — DROP OLDEST when full         |
//+------------------------------------------------------------------+
#ifndef __AURUM_TELEMETRY_QUEUE_MQH__
#define __AURUM_TELEMETRY_QUEUE_MQH__

#include "TelemetryTypes.mqh"
#include "TelemetryConfig.mqh"

static TelemetryBarRow g_t2Queue[TELEMETRY_T2_QUEUE_CAPACITY];
static int             g_t2Head = 0;
static int             g_t2Tail = 0;
static int             g_t2Count = 0;
static ulong           g_t2DroppedOldest = 0;

void TelemetryQueue_Reset(void) {
    g_t2Head = 0;
    g_t2Tail = 0;
    g_t2Count = 0;
    g_t2DroppedOldest = 0;
}

ulong TelemetryQueue_DroppedOldestCount(void) {
    return g_t2DroppedOldest;
}

int TelemetryQueue_Count(void) {
    return g_t2Count;
}

//+------------------------------------------------------------------+
//| Enqueue copy; if full, advance tail (drop oldest), then write.    |
//+------------------------------------------------------------------+
bool TelemetryQueue_EnqueueCopy(const TelemetryBarRow &row) {
    if(g_t2Count < TELEMETRY_T2_QUEUE_CAPACITY) {
        g_t2Queue[g_t2Head] = row;
        g_t2Head = (g_t2Head + 1) % TELEMETRY_T2_QUEUE_CAPACITY;
        g_t2Count++;
        return true;
    }
    g_t2Tail = (g_t2Tail + 1) % TELEMETRY_T2_QUEUE_CAPACITY;
    g_t2Queue[g_t2Head] = row;
    g_t2Head = (g_t2Head + 1) % TELEMETRY_T2_QUEUE_CAPACITY;
    g_t2DroppedOldest++;
    return true;
}

bool TelemetryQueue_TryDequeue(TelemetryBarRow &out) {
    if(g_t2Count <= 0)
        return false;
    out = g_t2Queue[g_t2Tail];
    g_t2Tail = (g_t2Tail + 1) % TELEMETRY_T2_QUEUE_CAPACITY;
    g_t2Count--;
    return true;
}

#endif // __AURUM_TELEMETRY_QUEUE_MQH__
