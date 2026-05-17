//+------------------------------------------------------------------+
//| GovernanceRuntimeVisualIntegrationV1.mqh                       |
//| Cold-path HTML export (OnTester / OnDeinit — caller-driven)      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_VISUAL_INT_V1_MQH__
#define __AURUM_GOV_RUNTIME_VISUAL_INT_V1_MQH__

#include "../GovernanceRuntimeStrategyTaggingV1/GovernanceRuntimeStrategyTaggingModuleV1.mqh"
#include "../GovernancePositionLineageIntelligenceV1/GovernancePositionLineageRegistryV1.mqh"
#include "../GovernanceRuntimeStrategyTaggingV1/GovernanceRuntimeStrategyTaggingSummaryV1.mqh"
#include "GovernanceRuntimeVisualDatasetV1.mqh"
#include "GovernanceRuntimeVisualDashboardBuilderV1.mqh"
#include "GovernanceRuntimeVisualExportV1.mqh"

inline void GovRuntimeVisualIntV1_ModuleInit(void)
{
   GovRuntimeVisualTelV1_Init(g_gov_runtime_visual_tel_v1);
   g_gov_runtime_visual_last_html_path_v1 = "";
}

inline bool GovRuntimeVisualIntV1_ExportGovernanceReportV1(const string sym, const bool write_sidecars)
{
   GovRuntimeVisualExpV1_EnsureReportFolders();

   SGovStratAttribSummaryV1 sum;
   GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);

   SGovVisualExecSummaryV1 ex;
   GovRuntimeVisualDsV1_FromTester(ex);

   string html = "";
   GovRuntimeVisualDashV1_BuildHtml(sym, g_gov_rtag_module_v1, g_gov_lineage_reg_v1, sum, ex, html);

   MqlDateTime dm;
   TimeToStruct(TimeCurrent(), dm);
   const string ts = StringFormat("%04d%02d%02d_%02d%02d%02d", dm.year, dm.mon, dm.day, dm.hour, dm.min, dm.sec);
   const string base = GOV_VISUAL_REPORT_PREFIX_V1 + ts;
   const string dir = GOV_VISUAL_REPORT_DIR_V1;
   const string rel_html = dir + base + GOV_VISUAL_HTML_EXT_V1;

   if(!GovRuntimeVisualExpV1_WriteUtf8Lf(rel_html, html))
      return false;

   g_gov_runtime_visual_last_html_path_v1 = rel_html;

   if(write_sidecars) {
      GovRuntimeVisualExpV1_WriteUtf8Lf(dir + base + GOV_VISUAL_CSS_EXT_V1, GovRuntimeVisualCssV1_Embedded());
      GovRuntimeVisualExpV1_WriteUtf8Lf(dir + base + GOV_VISUAL_JS_EXT_V1, GovRuntimeVisualJsV1_Embedded());
      string j = "{";
      j += "\"abi\":" + IntegerToString((int)GOV_VISUAL_ABI_VER_V1);
      j += ",\"magic\":" + IntegerToString((int)GOV_VISUAL_MAGIC_V1);
      j += ",\"sym\":\"" + sym + "\"";
      j += ",\"total_trades\":" + IntegerToString(ex.total_trades);
      j += ",\"net_profit\":" + DoubleToString(ex.net_profit, 2);
      j += ",\"report_file\":\"" + base + GOV_VISUAL_HTML_EXT_V1 + "\"";
      j += "}\n";
      GovRuntimeVisualExpV1_WriteUtf8Lf(dir + base + GOV_VISUAL_JSON_EXT_V1, j);
   }
   return true;
}

#endif // __AURUM_GOV_RUNTIME_VISUAL_INT_V1_MQH__
