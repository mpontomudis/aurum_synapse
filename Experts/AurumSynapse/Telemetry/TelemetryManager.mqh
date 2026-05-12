//+------------------------------------------------------------------+
//|                                             TelemetryManager.mqh |
//|                    Aurum Synapse — T0 Telemetry Schema Foundation |
//| NO-OP placeholder: no I/O, no hooks into execution path (T0).     |
//+------------------------------------------------------------------+
#ifndef __AURUM_TELEMETRY_MANAGER_MQH__
#define __AURUM_TELEMETRY_MANAGER_MQH__

#include "TelemetryTypes.mqh"
#include "TelemetryEnums.mqh"

//+------------------------------------------------------------------+
//| CTelemetryManager — structural shell only (T0)                   |
//| T1+ may add collectors/writers; failures must never affect trading.|
//+------------------------------------------------------------------+
class CTelemetryManager {
private:
    ENUM_TELEMETRY_MANAGER_STATE m_state;

public:
    CTelemetryManager(void) : m_state(TELEMETRY_MGR_UNINITIALIZED) {}

    //--- Always succeeds at T0; future: return false on fatal config only (still non-throwing)
    bool Init(void) {
        m_state = TELEMETRY_MGR_READY;
        return true;
    }

    void Deinit(void) {
        m_state = TELEMETRY_MGR_UNINITIALIZED;
    }

    void Disable(void) {
        m_state = TELEMETRY_MGR_DISABLED;
    }

    ENUM_TELEMETRY_MANAGER_STATE GetState(void) {
        return m_state;
    }

    //--- Extension point: zero one row bundle (for tests / future collector)
    void PrepareEmptyBarRow(TelemetryBarRow &row) {
        Telemetry_BarRow_Init(row);
    }

    //--- Reserved for T1+ (must remain no-op at T0 build)
    void OnNewBarPlaceholder(void) {
        // intentional no-op
    }
};

#endif // __AURUM_TELEMETRY_MANAGER_MQH__
