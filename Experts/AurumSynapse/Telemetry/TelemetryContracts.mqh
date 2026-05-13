//+------------------------------------------------------------------+
//|                                            TelemetryContracts.mqh |
//|                    Aurum Synapse — T0 Telemetry Schema Foundation |
//| Constants + serialization contract (documentation for T1+ writers)|
//+------------------------------------------------------------------+
#ifndef __AURUM_TELEMETRY_CONTRACTS_MQH__
#define __AURUM_TELEMETRY_CONTRACTS_MQH__

#include "TelemetryVersion.mqh"

//--- Capacity (aligned with ENUM_STRATEGY_INDEX count in Constants.mqh)
#define TELEMETRY_STRATEGY_SLOTS       8

//--- Sentinel for “not populated / placeholder” (T0; writers T1+ may override)
#define TELEMETRY_NULL_DOUBLE          (-1.0e100)
#define TELEMETRY_NULL_INT             (-2147483647)

//+------------------------------------------------------------------+
//| CSV / flat serialization contract (T1+ implementation — NOT T0)    |
//|                                                                   |
//| 1) First column MUST be schema id literal: AS_TELEMETRY_V1        |
//| 2) Second column: bar_time (datetime as Unix UTC seconds, int)   |
//|       OR TimeToString(..., TIME_DATE|TIME_SECONDS) — pick ONE   |
//|       at T1 lock; T0 documents both options — default int UTC.   |
//| 3) Field order: see TelemetrySchema.md “Bar row column order”.    |
//| 4) ENUM values: serialize as int (see Constants.mqh originals).   |
//| 5) Missing / placeholder: use TELEMETRY_NULL_* at T1+ discretion. |
//| 6) No embedded commas in unquoted strings; prefer numeric columns. |
//| 7) Header row optional at T1; if present, first data row still has  |
//|    schema id in col 1 for self-describing fragments.              |
//+------------------------------------------------------------------+
// Full canonical header string: see **TelemetrySchema.md** (Bar row).
// Full column contract (indices, nulls, analytics semantics): **Telemetry/TELEMETRY_CONTRACT.md**.

#endif // __AURUM_TELEMETRY_CONTRACTS_MQH__
