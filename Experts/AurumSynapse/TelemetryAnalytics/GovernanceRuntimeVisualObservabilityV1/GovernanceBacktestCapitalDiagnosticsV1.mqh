//+------------------------------------------------------------------+
//| GovernanceBacktestCapitalDiagnosticsV1.mqh                       |
//| PHASE 20B — capital collapse narrative (obs snapshot)            |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_BACKTEST_CAP_V1_MQH__
#define __AURUM_GOV_BACKTEST_CAP_V1_MQH__

#include "../GovernanceRuntimeObservabilityExportV1/GovernanceRuntimeObservabilityDatasetV1.mqh"
#include "GovernanceRuntimeVisualHtmlWriterV1.mqh"

inline string GovBacktestCapV1_Classify(const SGovRuntimeObsCapitalSnapV1 &cap)
{
   if(cap.result_code == (int)GOV_CAP_RES_LOT_COLLAPSE_MIN_VOLUME)
      return "COLLAPSE";
   if(cap.result_code == (int)GOV_CAP_RES_FREE_MARGIN_LOW)
      return "BORDERLINE";
   if(cap.margin_free_cent * 100L < cap.margin_req_cent * 120L && cap.margin_req_cent > 0)
      return "BORDERLINE";
   return "SAFE";
}

inline void GovBacktestCapV1_AppendSection(string &html)
{
   const SGovRuntimeObsCapitalSnapV1 c = g_gov_runtime_obs_report_v1.cap;
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-capx\"><h2>12. Capital diagnostics (dossier)</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p><b>Classification:</b> <code>" + GovRuntimeVisualHtmlW1_Escape(GovBacktestCapV1_Classify(c)) + "</code></p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<table><tbody>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>RequestedLot</td><td>" + GovRuntimeVisualHtmlW1_Escape(DoubleToString((double)c.requested_lot_micro / 100000000.0, 4)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>NormalizedLot</td><td>" + GovRuntimeVisualHtmlW1_Escape(DoubleToString((double)c.normalized_lot_micro / 100000000.0, 4)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>BrokerMinLot</td><td>" + GovRuntimeVisualHtmlW1_Escape(DoubleToString((double)c.broker_min_lot_micro / 100000000.0, 4)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>FreeMargin</td><td>" + GovRuntimeVisualHtmlW1_Escape(DoubleToString((double)c.margin_free_cent / 100.0, 2)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>MarginRequired</td><td>" + GovRuntimeVisualHtmlW1_Escape(DoubleToString((double)c.margin_req_cent / 100.0, 2)) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>LastBlockReason</td><td>" + GovRuntimeVisualHtmlW1_Escape(c.last_block_reason) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<tr><td>ResultCode</td><td>" + IntegerToString(c.result_code) + "</td></tr>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</tbody></table>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p style=\"color:#8b949e;font-size:0.85rem;\">Small accounts fail when normalized lot rounds to broker minimum violation or free margin cannot fund margin amplification during recovery cascades.</p>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");
}

#endif // __AURUM_GOV_BACKTEST_CAP_V1_MQH__
