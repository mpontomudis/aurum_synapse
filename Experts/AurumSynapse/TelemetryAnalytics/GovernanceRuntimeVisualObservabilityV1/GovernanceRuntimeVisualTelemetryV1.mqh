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

// PHASE 20D — wall-clock capture for dossier metadata (no TesterStartTime / TesterStopTime; not in MQL5 API).
struct SGovBacktestRuntimeV1
{
   datetime started_at;
   datetime finished_at;
   uint     runtime_seconds;
};

SGovBacktestRuntimeV1 g_gov_visual_runtime_v1;

inline void GovBacktestRuntimeV1_Reset(SGovBacktestRuntimeV1 &r)
{
   r.started_at = 0;
   r.finished_at = 0;
   r.runtime_seconds = 0;
}

inline void GovBacktestRuntimeV1_OnModuleInit(SGovBacktestRuntimeV1 &r)
{
   GovBacktestRuntimeV1_Reset(r);
   r.started_at = TimeCurrent();
}

inline void GovBacktestRuntimeV1_MarkFinished(SGovBacktestRuntimeV1 &r)
{
   r.finished_at = TimeCurrent();
   if(r.started_at > 0 && r.finished_at >= r.started_at)
      r.runtime_seconds = (uint)(r.finished_at - r.started_at);
   else
      r.runtime_seconds = 0;
}

inline void GovRuntimeVisualTelV1_Init(SGovRuntimeVisualTelemetryV1 &t)
{
   t.html_exports_ok = 0;
   t.html_exports_fail = 0;
   t.bytes_written_sat = 0;
}

#endif // __AURUM_GOV_RUNTIME_VISUAL_TEL_V1_MQH__
