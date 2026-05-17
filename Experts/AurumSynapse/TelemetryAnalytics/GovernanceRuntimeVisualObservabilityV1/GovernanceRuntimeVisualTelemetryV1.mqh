//+------------------------------------------------------------------+
//| GovernanceRuntimeVisualTelemetryV1.mqh                         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_VISUAL_TEL_V1_MQH__
#define __AURUM_GOV_RUNTIME_VISUAL_TEL_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

struct SGovRuntimeVisualTelemetryV1
{
   int html_exports_ok;
   int html_exports_fail;
   int bytes_written_sat;
};

SGovRuntimeVisualTelemetryV1 g_gov_runtime_visual_tel_v1;

inline void GovRuntimeVisualTelV1_Init(SGovRuntimeVisualTelemetryV1 &t)
{
   t.html_exports_ok = 0;
   t.html_exports_fail = 0;
   t.bytes_written_sat = 0;
}

#endif // __AURUM_GOV_RUNTIME_VISUAL_TEL_V1_MQH__
