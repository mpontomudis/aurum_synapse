//+------------------------------------------------------------------+
//| GovernanceRuntimeVisualContractsV1.mqh                          |
//| PHASE 20A — visual governance observability contracts              |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_VISUAL_CONTRACTS_V1_MQH__
#define __AURUM_GOV_RUNTIME_VISUAL_CONTRACTS_V1_MQH__

#define GOV_VISUAL_ABI_VER_V1           ((uint)1)
#define GOV_VISUAL_MAGIC_V1             ((uint)0x47565231) // 'GV1'
#define GOV_VISUAL_REPORT_DIR_V1        "AurumSynapse\\TelemetryAnalytics\\Reports\\"
#define GOV_VISUAL_REPORT_PREFIX_V1     "governance_report_"
#define GOV_VISUAL_HTML_EXT_V1         ".html"
#define GOV_VISUAL_CSS_EXT_V1          "_governance_report.css"
#define GOV_VISUAL_JS_EXT_V1           "_governance_report.js"
#define GOV_VISUAL_JSON_EXT_V1         "_governance_report.json"
#define GOV_DOSSIER_COMPARE_EXT_V1     "_governance_report_compare.html"

#define GOV_DOSSIER_SCHEMA_VER_V1      ((uint)2)

#define GOV_VISUAL_BASELINE_DIR_V1     "AurumSynapse\\TelemetryAnalytics\\Baselines\\"
#define GOV_VISUAL_BASELINE_CSV_V1    "AurumSynapse\\TelemetryAnalytics\\Baselines\\governance_run_index_v1.csv"
#define GOV_VISUAL_BASELINE_JSONL_V1  "AurumSynapse\\TelemetryAnalytics\\Baselines\\governance_run_index_v1.jsonl"

#endif // __AURUM_GOV_RUNTIME_VISUAL_CONTRACTS_V1_MQH__
