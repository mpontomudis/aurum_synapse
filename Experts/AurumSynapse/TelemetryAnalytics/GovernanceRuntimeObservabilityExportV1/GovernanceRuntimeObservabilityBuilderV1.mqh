//+------------------------------------------------------------------+
//| GovernanceRuntimeObservabilityBuilderV1.mqh                      |
//| Assemble deterministic runtime report (cold path)                |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_OBS_BUILDER_V1_MQH__
#define __AURUM_GOV_RUNTIME_OBS_BUILDER_V1_MQH__

#include "../GovernanceRuntimeStrategyTaggingV1/GovernanceRuntimeStrategyTaggingModuleV1.mqh"
#include "../GovernanceRuntimeStrategyTaggingV1/GovernanceRuntimeStrategyTaggingSummaryV1.mqh"
#include "../GovernanceRuntimeStrategyTaggingV1/GovernanceRuntimeTaggingExportV1.mqh"
#include "../GovernancePositionLineageIntelligenceV1/GovernancePositionLineageExportV1.mqh"
#include "GovernanceRuntimeObservabilityFormatterV1.mqh"
#include "GovernanceRuntimeObservabilityTelemetryV1.mqh"

inline void GovRuntimeObsBldV1_AppendHeader(string &dst, const uint seq)
{
   GovRuntimeObsFmtV1_AppendLf(dst, "=== GOVERNANCE_RUNTIME_OBSERVABILITY_V1 ===\n");
   GovRuntimeObsFmtV1_AppendLf(dst, "magic=" + IntegerToString((int)GOV_RUNTIME_OBS_MAGIC_V1) + ",abi=" + IntegerToString((int)GOV_RUNTIME_OBS_ABI_VER_V1) + ",seq=" + IntegerToString((int)seq) + "\n");
   GovRuntimeObsFmtV1_AppendLf(dst, "ts=" + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "\n");
}

inline bool GovRuntimeObsBldV1_BuildFull(const string sym,
                                        const SGovRuntimeTaggingModuleV1 &mod,
                                        const SGovLineageRegistryStoreV1 &lin,
                                        const int flags,
                                        string &dst)
{
   dst = "";
   GovRuntimeObsBldV1_AppendHeader(dst, ++g_gov_runtime_obs_report_v1.meta.build_seq);
   g_gov_runtime_obs_report_v1.meta.build_ts = TimeCurrent();

   SGovStratAttribSummaryV1 sum;
   GovRunTagIntV1_BuildSummaryFromBridge(mod.bridge, sum);

   GovRuntimeObsFmtV1_AppendStrategyBreakdown(dst, sum);

   string strat_bundle = GovStratExpV1_Report(sum);
   GovRuntimeObsFmtV1_AppendLf(dst, "=== STRATEGY_ATTRIBUTION_BUNDLE ===\n" + strat_bundle);

   GovRuntimeObsFmtV1_AppendToxicity(dst, sum);
   GovRuntimeObsFmtV1_AppendEcology(dst, sum);

   GovRuntimeObsFmtV1_AppendLineageNarrative(dst, lin);
   if((flags & GOV_RUNTIME_OBS_FLAG_INCLUDE_RAW) != 0) {
      GovRuntimeObsFmtV1_AppendLf(dst, "=== POSITION_LINEAGE_RAW ===\n");
      GovRuntimeObsFmtV1_AppendLf(dst, GovLineageExpV1_Report(lin));
   }

   string rtag = "";
   if(GovRunAttrV1_Export(mod.bridge, rtag))
      GovRuntimeObsFmtV1_AppendLf(dst, "=== RUNTIME_STRATEGY_TAG_ATTRIBUTION ===\n" + rtag);
   else
      GovRuntimeObsFmtV1_AppendLf(dst, "=== RUNTIME_STRATEGY_TAG_ATTRIBUTION ===\nEXPORT_FAIL\n");

   GovRuntimeObsV1_RefreshAccountSnapshot(sym);
   GovRuntimeObsFmtV1_AppendCapital(dst, sym, g_gov_runtime_obs_report_v1.cap);

   g_gov_runtime_obs_tel_v1.exports_built = GovSaturatingAdd32(g_gov_runtime_obs_tel_v1.exports_built, 1);
   return true;
}

#endif // __AURUM_GOV_RUNTIME_OBS_BUILDER_V1_MQH__
