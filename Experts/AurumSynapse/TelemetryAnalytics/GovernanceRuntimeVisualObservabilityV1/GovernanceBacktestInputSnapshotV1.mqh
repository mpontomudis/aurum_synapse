//+------------------------------------------------------------------+
//| GovernanceBacktestInputSnapshotV1.mqh                          |
//| PHASE 20B — reproducibility: KV snapshot (filled by EA/tests)  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_BACKTEST_INP_SNAP_V1_MQH__
#define __AURUM_GOV_BACKTEST_INP_SNAP_V1_MQH__

#include "GovernanceRuntimeVisualHtmlWriterV1.mqh"

string g_gov_backtest_input_kv_v1 = "";

#define GOV_DOSSIER_STRAT_N_V1 8

bool g_gov_dossier_strat_en_v1[GOV_DOSSIER_STRAT_N_V1];

struct SGovDossierRiskCfgV1
{
   double max_risk_per_trade;
   double max_daily_loss_pct;
   double max_equity_dd_pct;
   int    max_consecutive_losses;
   int    max_open_positions;
};

SGovDossierRiskCfgV1 g_gov_dossier_risk_v1;

string g_gov_dossier_git_commit_v1 = "";
int    g_gov_dossier_build_number_v1 = 0;
string g_gov_dossier_compare_baseline_kv_v1 = "";

inline void GovBacktestInpSnapV1_Reset(void)
{
   g_gov_backtest_input_kv_v1 = "";
   for(int i = 0; i < GOV_DOSSIER_STRAT_N_V1; i++)
      g_gov_dossier_strat_en_v1[i] = true;
   g_gov_dossier_risk_v1.max_risk_per_trade = 0;
   g_gov_dossier_risk_v1.max_daily_loss_pct = 0;
   g_gov_dossier_risk_v1.max_equity_dd_pct = 0;
   g_gov_dossier_risk_v1.max_consecutive_losses = 0;
   g_gov_dossier_risk_v1.max_open_positions = 0;
   g_gov_dossier_git_commit_v1 = "";
   g_gov_dossier_build_number_v1 = 0;
   g_gov_dossier_compare_baseline_kv_v1 = "";
}

inline void GovBacktestInpSnapV1_AppendSection(string &html)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-inp\"><h2>2. Input snapshot</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p style=\"color:#8b949e;font-size:0.85rem;\">LF-separated key=value lines captured at export (Strategy Tester inputs / EA inputs).</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<input class=\"inp-filter\" id=\"inpFilter\" type=\"search\" placeholder=\"Filter parameters...\" oninput=\"govFilterRows('inpFilter','tblInp')\"/>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div style=\"max-height:420px;overflow:auto;border:1px solid #30363d;border-radius:8px;\">\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table id=\"tblInp\"><thead><tr><th>Key</th><th>Value</th></tr></thead><tbody>\n");
   if(StringLen(g_gov_backtest_input_kv_v1) <= 0) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td colspan=\"2\"><i>(empty — harness or unset)</i></td></tr>\n");
   } else {
      string lines[];
      const int n = StringSplit(g_gov_backtest_input_kv_v1, '\n', lines);
      for(int i = 0; i < n; i++) {
         if(StringLen(lines[i]) <= 0)
            continue;
         const int eq = StringFind(lines[i], "=");
         if(eq < 0) {
            GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td colspan=\"2\" class=\"mono\">" + GovRuntimeVisualHtmlW1_Escape(lines[i]) + "</td></tr>\n");
            continue;
         }
         const string k = StringSubstr(lines[i], 0, eq);
         const string v = StringSubstr(lines[i], eq + 1, StringLen(lines[i]) - eq - 1);
         GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td class=\"mono\">" + GovRuntimeVisualHtmlW1_Escape(k) + "</td><td class=\"mono\">" +
                                            GovRuntimeVisualHtmlW1_Escape(v) + "</td></tr>\n");
      }
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table></div></section>\n");
}

#endif // __AURUM_GOV_BACKTEST_INP_SNAP_V1_MQH__
