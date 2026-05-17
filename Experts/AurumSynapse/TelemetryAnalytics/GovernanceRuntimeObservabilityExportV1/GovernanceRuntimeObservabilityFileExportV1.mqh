//+------------------------------------------------------------------+
//| GovernanceRuntimeObservabilityFileExportV1.mqh                   |
//| Optional UTF-8 text file — LF, single write                      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_OBS_FILE_V1_MQH__
#define __AURUM_GOV_RUNTIME_OBS_FILE_V1_MQH__

#include "GovernanceRuntimeObservabilityTelemetryV1.mqh"

inline bool GovRuntimeObsFileV1_WriteUtf8Lf(const string rel_path, const string utf8_text)
{
   if(StringLen(rel_path) <= 0)
      return false;
   const int h = FileOpen(rel_path, FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE) {
      g_gov_runtime_obs_tel_v1.file_failures = GovSaturatingAdd32(g_gov_runtime_obs_tel_v1.file_failures, 1);
      return false;
   }
   const bool ok = (FileWriteString(h, utf8_text) > 0);
   FileClose(h);
   if(ok)
      g_gov_runtime_obs_tel_v1.file_writes = GovSaturatingAdd32(g_gov_runtime_obs_tel_v1.file_writes, 1);
   else
      g_gov_runtime_obs_tel_v1.file_failures = GovSaturatingAdd32(g_gov_runtime_obs_tel_v1.file_failures, 1);
   return ok;
}

#endif // __AURUM_GOV_RUNTIME_OBS_FILE_V1_MQH__
