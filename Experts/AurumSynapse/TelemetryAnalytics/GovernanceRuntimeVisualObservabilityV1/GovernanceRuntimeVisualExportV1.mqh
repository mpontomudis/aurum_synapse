//+------------------------------------------------------------------+
//| GovernanceRuntimeVisualExportV1.mqh                             |
//| Cold-path UTF-8 (LF) file writes under MQL5\\Files               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_VISUAL_EXPORT_V1_MQH__
#define __AURUM_GOV_RUNTIME_VISUAL_EXPORT_V1_MQH__

#include "GovernanceRuntimeVisualContractsV1.mqh"
#include "GovernanceRuntimeVisualTelemetryV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

inline void GovRuntimeVisualExpV1_EnsureReportFolders(void)
{
   if(!FolderCreate("AurumSynapse")) {
      /* exists or error — non-fatal */
   }
   if(!FolderCreate("AurumSynapse\\TelemetryAnalytics")) {
      /* non-fatal */
   }
   if(!FolderCreate("AurumSynapse\\TelemetryAnalytics\\Reports")) {
      /* non-fatal */
   }
}

inline bool GovRuntimeVisualExpV1_WriteUtf8Lf(const string rel_path, const string utf8_text)
{
   if(StringLen(rel_path) <= 0) {
      g_gov_runtime_visual_tel_v1.html_exports_fail = GovSaturatingAdd32(g_gov_runtime_visual_tel_v1.html_exports_fail, 1);
      return false;
   }
   const int h = FileOpen(rel_path, FILE_WRITE | FILE_BIN);
   if(h == INVALID_HANDLE) {
      g_gov_runtime_visual_tel_v1.html_exports_fail = GovSaturatingAdd32(g_gov_runtime_visual_tel_v1.html_exports_fail, 1);
      return false;
   }
   uchar buf[];
   const int slen = StringLen(utf8_text);
   const int n = (slen <= 0) ? 0 : StringToCharArray(utf8_text, buf, 0, slen, CP_UTF8);
   bool ok = true;
   if(slen > 0 && n <= 0) {
      ok = false;
   } else if(n > 0) {
      const uint w = FileWriteArray(h, buf, 0, (uint)n);
      ok = (w == (uint)n);
   }
   FileClose(h);
   if(!ok) {
      g_gov_runtime_visual_tel_v1.html_exports_fail = GovSaturatingAdd32(g_gov_runtime_visual_tel_v1.html_exports_fail, 1);
      return false;
   }
   g_gov_runtime_visual_tel_v1.html_exports_ok = GovSaturatingAdd32(g_gov_runtime_visual_tel_v1.html_exports_ok, 1);
   g_gov_runtime_visual_tel_v1.bytes_written_sat = GovSaturatingAdd32(g_gov_runtime_visual_tel_v1.bytes_written_sat, slen);
   return true;
}

#endif // __AURUM_GOV_RUNTIME_VISUAL_EXPORT_V1_MQH__
