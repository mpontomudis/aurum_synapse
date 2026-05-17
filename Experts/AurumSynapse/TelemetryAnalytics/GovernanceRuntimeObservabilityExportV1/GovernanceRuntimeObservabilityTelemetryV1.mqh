//+------------------------------------------------------------------+
//| GovernanceRuntimeObservabilityTelemetryV1.mqh                  |
//| Saturating counters — export / journal / truncation              |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_OBS_TEL_V1_MQH__
#define __AURUM_GOV_RUNTIME_OBS_TEL_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "GovernanceRuntimeObservabilityContractsV1.mqh"

struct SGovRuntimeObsTelemetryV1
{
   int exports_built;
   int journal_prints;
   int journal_chunks;
   int file_writes;
   int truncations;
   int journal_overflow;
   int file_failures;
};

SGovRuntimeObsTelemetryV1 g_gov_runtime_obs_tel_v1;

inline void GovRuntimeObsTelV1_Init(SGovRuntimeObsTelemetryV1 &t)
{
   t.exports_built = 0;
   t.journal_prints = 0;
   t.journal_chunks = 0;
   t.file_writes = 0;
   t.truncations = 0;
   t.journal_overflow = 0;
   t.file_failures = 0;
}

#endif // __AURUM_GOV_RUNTIME_OBS_TEL_V1_MQH__
