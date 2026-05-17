//+------------------------------------------------------------------+
//| GovernanceRuntimeObservabilityIntegrationV1.mqh                   |
//| Cold-path emit: OnDeinit / OnTester hooks (caller-driven)        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_OBS_INT_V1_MQH__
#define __AURUM_GOV_RUNTIME_OBS_INT_V1_MQH__

#include "GovernanceRuntimeObservabilityDatasetV1.mqh"
#include "GovernanceRuntimeObservabilityTelemetryV1.mqh"
#include "GovernanceRuntimeObservabilityJournalV1.mqh"
#include "GovernanceRuntimeObservabilityFileExportV1.mqh"
#include "GovernanceRuntimeObservabilityReplayV1.mqh"
#include "GovernanceRuntimeObservabilityBuilderV1.mqh"
#include "../GovernancePositionLineageIntelligenceV1/GovernancePositionLineageLiveIntegrationV1.mqh"

struct SGovRuntimeObsCfgV1
{
   bool     enable_journal;
   bool     enable_file;
   string   file_rel_path;
   int      export_flags;
};

SGovRuntimeObsCfgV1 g_gov_runtime_obs_cfg_v1;

inline void GovRuntimeObsIntV1_Configure(const bool enable_journal,
                                        const bool enable_file,
                                        const string file_rel_path,
                                        const int export_flags)
{
   g_gov_runtime_obs_cfg_v1.enable_journal = enable_journal;
   g_gov_runtime_obs_cfg_v1.enable_file = enable_file;
   g_gov_runtime_obs_cfg_v1.file_rel_path = file_rel_path;
   g_gov_runtime_obs_cfg_v1.export_flags = export_flags;
}

inline void GovRuntimeObsIntV1_ModuleInit(void)
{
   GovRuntimeObsV1_ModuleInit();
   GovRuntimeObsTelV1_Init(g_gov_runtime_obs_tel_v1);
   GovRuntimeObsIntV1_Configure(false, false, "", GOV_RUNTIME_OBS_FLAG_INCLUDE_RAW);
}

inline void GovRuntimeObsIntV1_EmitEndOfRun(const string sym, const int reason_tag)
{
   g_gov_runtime_obs_report_v1.meta.reason_tag = reason_tag;
   string blob = "";
   const int fl = g_gov_runtime_obs_cfg_v1.export_flags | GOV_RUNTIME_OBS_FLAG_INCLUDE_RAW;
   if(!GovRuntimeObsBldV1_BuildFull(sym, g_gov_rtag_module_v1, g_gov_lineage_reg_v1, fl, blob))
      return;
   const ulong h = GovRuntimeObsReplayV1_Hash64(blob);
   blob += "=== RUNTIME_OBS_REPLAY_HASH ===\n";
   blob += IntegerToString((long)h);
   blob += "\n";
   if(g_gov_runtime_obs_cfg_v1.enable_journal)
      GovRuntimeObsJournalV1_Print(blob);
   if(g_gov_runtime_obs_cfg_v1.enable_file && StringLen(g_gov_runtime_obs_cfg_v1.file_rel_path) > 0)
      GovRuntimeObsFileV1_WriteUtf8Lf(g_gov_runtime_obs_cfg_v1.file_rel_path, blob);
}

#endif // __AURUM_GOV_RUNTIME_OBS_INT_V1_MQH__
