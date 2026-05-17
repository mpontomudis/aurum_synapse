//+------------------------------------------------------------------+
//| GovernanceRuntimeObservabilityJournalV1.mqh                      |
//| Chunk-safe Print — cold path only                                |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_OBS_JOURNAL_V1_MQH__
#define __AURUM_GOV_RUNTIME_OBS_JOURNAL_V1_MQH__

#include "GovernanceRuntimeObservabilityTelemetryV1.mqh"
#include "GovernanceRuntimeObservabilityContractsV1.mqh"

inline void GovRuntimeObsJournalV1_Print(const string text)
{
   const int n = StringLen(text);
   if(n <= 0)
      return;
   for(int pos = 0; pos < n; pos += GOV_RUNTIME_OBS_JOURNAL_CHUNK_V1) {
      const int take = MathMin(GOV_RUNTIME_OBS_JOURNAL_CHUNK_V1, n - pos);
      Print(StringSubstr(text, pos, take));
      g_gov_runtime_obs_tel_v1.journal_prints = GovSaturatingAdd32(g_gov_runtime_obs_tel_v1.journal_prints, 1);
      g_gov_runtime_obs_tel_v1.journal_chunks = GovSaturatingAdd32(g_gov_runtime_obs_tel_v1.journal_chunks, 1);
   }
}

#endif // __AURUM_GOV_RUNTIME_OBS_JOURNAL_V1_MQH__
