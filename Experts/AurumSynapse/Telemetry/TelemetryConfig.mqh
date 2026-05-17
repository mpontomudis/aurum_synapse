//+------------------------------------------------------------------+
//|                                              TelemetryConfig.mqh |
//|                    Aurum Synapse — T2 shadow persistence config  |
//| Compile: #define AURUM_TELEMETRY_T2 only with AURUM_TELEMETRY_T1 (else missing-include guard). |
//+------------------------------------------------------------------+
#ifndef __AURUM_TELEMETRY_CONFIG_MQH__
#define __AURUM_TELEMETRY_CONFIG_MQH__

//--- T2 requires T1: MQL5 has no compile-time error directive; fail compile via missing include if misconfigured.
#ifdef AURUM_TELEMETRY_T2
#ifndef AURUM_TELEMETRY_T1
#include <__AURUM_TELEMETRY_T2_REQUIRES_AURUM_TELEMETRY_T1__.mqh>
#endif
#endif

//--- Storage: FILE_COMMON relative folder (under Terminal Common\Files)
#define TELEMETRY_T2_REL_FOLDER          "AurumSynapse\\telemetry\\"
#define TELEMETRY_T2_FILE_PREFIX         "AS_TELEMETRY_V1_"

//--- Timer / drain (cold path only)
#define TELEMETRY_T2_TIMER_MS            500
#define TELEMETRY_T2_DRAIN_MAX_ROWS      32

//--- Rotation
#define TELEMETRY_T2_MAX_SEGMENT_BYTES   (50 * 1024 * 1024)

//--- Fixed queue (drop oldest when full)
#define TELEMETRY_T2_QUEUE_CAPACITY      1024

//--- Reusable CSV line buffer (grow once in Init, not per tick)
#define TELEMETRY_T2_LINE_BUFFER_CHARS   16384

#endif // __AURUM_TELEMETRY_CONFIG_MQH__
