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
#include "GovernanceBacktestDossierV1.mqh"
#include "GovernanceRuntimeVisualExportV1.mqh"
#include "GovernanceRuntimeVisualHtmlWriterV1.mqh"

inline void GovRuntimeVisualIntV1_ModuleInit(void)
{
   GovRuntimeVisualTelV1_Init(g_gov_runtime_visual_tel_v1);
   g_gov_runtime_visual_last_html_path_v1 = "";
   GovBacktestInpSnapV1_Reset();
   GovBacktestRuntimeV1_OnModuleInit(g_gov_visual_runtime_v1);
}

inline bool GovRuntimeVisualIntV1_ExportGovernanceReportV1(const string sym,
                                                         const ENUM_TIMEFRAMES tf,
                                                         const bool write_sidecars,
                                                         const bool write_compare)
{
   GovRuntimeVisualExpV1_EnsureReportFolders();

   SGovStratAttribSummaryV1 sum;
   GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);

   SGovVisualExecSummaryV1 ex;
   GovRuntimeVisualDsV1_FromTester(ex);

   SGovCmpRunRecordV1 cmp_base;
   GovCmpDsV1_Init(cmp_base);
   GovCmpStoreV1_ReadLatest(cmp_base);

   MqlDateTime dm;
   TimeToStruct(TimeCurrent(), dm);
   const string ts = StringFormat("%04d%02d%02d_%02d%02d%02d", dm.year, dm.mon, dm.day, dm.hour, dm.min, dm.sec);
   const string base = GOV_VISUAL_REPORT_PREFIX_V1 + ts;
   const string dir = GOV_VISUAL_REPORT_DIR_V1;
   const string rel_html = dir + base + GOV_VISUAL_HTML_EXT_V1;

   string html = "";
   GovBacktestDossierV1_BuildFullHtml(sym, tf, ts, g_gov_rtag_module_v1, g_gov_lineage_reg_v1, g_gov_lineage_rec_v1, sum, ex, cmp_base, html);

   if(!GovRuntimeVisualExpV1_WriteUtf8Lf(rel_html, html))
      return false;

   SGovCmpRunRecordV1 cmp_cur;
   GovCmpStoreV1_FillCurrent(ts, sym, tf, sum, ex, g_gov_lineage_reg_v1, g_gov_lineage_rec_v1, cmp_cur);
   GovCmpStoreV1_Append(cmp_cur);

   g_gov_runtime_visual_last_html_path_v1 = rel_html;

   if(write_sidecars) {
      GovRuntimeVisualExpV1_WriteUtf8Lf(dir + base + GOV_VISUAL_CSS_EXT_V1, GovRuntimeVisualCssV1_Embedded());
      GovRuntimeVisualExpV1_WriteUtf8Lf(dir + base + GOV_VISUAL_JS_EXT_V1, GovRuntimeVisualJsV1_Embedded());
      string j = "{";
      j += "\"abi\":" + IntegerToString((int)GOV_VISUAL_ABI_VER_V1);
      j += ",\"dossier_schema\":" + IntegerToString((int)GOV_DOSSIER_SCHEMA_VER_V1);
      j += ",\"magic\":" + IntegerToString((int)GOV_VISUAL_MAGIC_V1);
      j += ",\"sym\":\"" + sym + "\"";
      j += ",\"tf\":\"" + EnumToString(tf) + "\"";
      j += ",\"total_trades\":" + IntegerToString(ex.total_trades);
      j += ",\"net_profit\":" + DoubleToString(ex.net_profit, 2);
      j += ",\"report_file\":\"" + base + GOV_VISUAL_HTML_EXT_V1 + "\"";
      j += "}\n";
      GovRuntimeVisualExpV1_WriteUtf8Lf(dir + base + GOV_VISUAL_JSON_EXT_V1, j);
   }

   if(write_compare) {
      string cmp = "";
      GovRuntimeVisualHtmlW1_AppendLf(cmp, "<!DOCTYPE html>\n<html lang=\"en\"><head><meta charset=\"utf-8\"/><title>Governance compare</title></head><body>\n");
      GovRuntimeVisualHtmlW1_AppendLf(cmp, "<h1>governance_report_compare (stub)</h1>\n");
      GovRuntimeVisualHtmlW1_AppendLf(cmp, "<p>Primary: <code>" + GovRuntimeVisualHtmlW1_Escape(base + GOV_VISUAL_HTML_EXT_V1) + "</code></p>\n");
      GovRuntimeVisualHtmlW1_AppendLf(cmp, "<p>LF-only local file. Open two dossier HTML exports side-by-side for institutional diff review.</p>\n");
      GovRuntimeVisualHtmlW1_AppendLf(cmp, "</body></html>\n");
      GovRuntimeVisualExpV1_WriteUtf8Lf(dir + base + GOV_DOSSIER_COMPARE_EXT_V1, cmp);
   }
   return true;
}

#endif // __AURUM_GOV_RUNTIME_VISUAL_INT_V1_MQH__
