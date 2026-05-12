//+------------------------------------------------------------------+
//|                                               TelemetryEnums.mqh |
//|                    Aurum Synapse — T0 Telemetry Schema Foundation |
//| Telemetry-local enumerations only (no trading logic).             |
//+------------------------------------------------------------------+
#ifndef __AURUM_TELEMETRY_ENUMS_MQH__
#define __AURUM_TELEMETRY_ENUMS_MQH__

//+------------------------------------------------------------------+
//| Lifecycle / safety state (TelemetryManager — T0 noop placeholder) |
//+------------------------------------------------------------------+
enum ENUM_TELEMETRY_MANAGER_STATE {
    TELEMETRY_MGR_UNINITIALIZED = 0,
    TELEMETRY_MGR_READY        = 1,   // structurally ready; T0 still performs no I/O
    TELEMETRY_MGR_DISABLED     = 2    // soft-off after failure (future T1+)
};

//+------------------------------------------------------------------+
//| Row kind for future multi-stream files (contract only at T0)      |
//+------------------------------------------------------------------+
enum ENUM_TELEMETRY_ROW_KIND {
    TELEMETRY_ROW_KIND_BAR   = 0,
    TELEMETRY_ROW_KIND_TRADE = 1
};

#endif // __AURUM_TELEMETRY_ENUMS_MQH__
