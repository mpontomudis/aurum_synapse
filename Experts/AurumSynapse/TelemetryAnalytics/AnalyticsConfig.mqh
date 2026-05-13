//+------------------------------------------------------------------+
//|                                            AnalyticsConfig.mqh   |
//|     Phase 3A — shadow CSV analytics (no EA / no telemetry write) |
//+------------------------------------------------------------------+
#ifndef __AURUM_ANALYTICS_CONFIG_MQH__
#define __AURUM_ANALYTICS_CONFIG_MQH__

//--- Phase S — version lock (bump on intentional Stream A / parser contract change)
#define ANALYTICS_ENGINE_VERSION         "3A-S1"
#define ANALYTICS_STREAM_A_REPORT_VERSION "3A-R1"

//--- Mirror T2 storage root (do not include TelemetryConfig.mqh — T2 ifdef guard).
#define ANALYTICS_TELEMETRY_FOLDER       "AurumSynapse\\telemetry\\"
#define ANALYTICS_TELEMETRY_FILE_GLOB    "AurumSynapse\\telemetry\\AS_TELEMETRY_V1_*.csv"

//--- Line reader safety cap (raw bytes → string; one physical CSV row).
#define ANALYTICS_MAX_LINE_CHARS         131072

//--- Logical column count = split(TelemetryWriter_CsvHeaderLine) — see TelemetryCsvV1_ExpectedColumns()

//--- Regime proxy thresholds (analytics labels only — not engine ENUM_REGIME)
#define ANALYTICS_PROXY_ADX_TREND        28.0
#define ANALYTICS_PROXY_ADX_RANGE        18.0
#define ANALYTICS_PROXY_VOL_HIGH         1.12
#define ANALYTICS_PROXY_VOL_LOW          0.88

#endif // __AURUM_ANALYTICS_CONFIG_MQH__
