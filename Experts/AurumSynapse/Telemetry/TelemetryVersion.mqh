//+------------------------------------------------------------------+
//|                                              TelemetryVersion.mqh |
//|                    Aurum Synapse — T0 Telemetry Schema Foundation |
//| Schema identity only (no runtime I/O).                            |
//+------------------------------------------------------------------+
#ifndef __AURUM_TELEMETRY_VERSION_MQH__
#define __AURUM_TELEMETRY_VERSION_MQH__

//--- Canonical schema id (CSV column 1 + documentation contract)
#define TELEMETRY_SCHEMA_ID_ASCII     "AS_TELEMETRY_V1"
#define TELEMETRY_SCHEMA_MAJOR        1
#define TELEMETRY_SCHEMA_MINOR        0

//--- Philosophy (see Telemetry/TelemetrySchema.md):
// - Bump MAJOR for breaking column reorder / semantic change.
// - Bump MINOR for additive trailing columns (parsers ignore unknown tail).
// - Runtime writers (T1+) must emit TELEMETRY_SCHEMA_ID_ASCII as first field.

#endif // __AURUM_TELEMETRY_VERSION_MQH__
