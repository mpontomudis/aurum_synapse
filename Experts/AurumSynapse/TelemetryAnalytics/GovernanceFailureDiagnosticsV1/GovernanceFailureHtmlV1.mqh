//+------------------------------------------------------------------+
//| GovernanceFailureHtmlV1.mqh                                   |
//| PHASE 20C — failure diagnostics HTML                             |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_FAILURE_HTML_V1_MQH__
#define __AURUM_GOV_FAILURE_HTML_V1_MQH__

#include "GovernanceFailureClassifierV1.mqh"
#include "GovernanceFailureExportV1.mqh"
#include "../GovernanceRuntimeVisualObservabilityV1/GovernanceRuntimeVisualHtmlWriterV1.mqh"

inline string GovFailureHtmlV1_SevClass(const int sev)
{
   if(sev >= GOV_FAIL_SEV_CRITICAL_V1)
      return "sev-crit";
   if(sev == GOV_FAIL_SEV_HIGH_V1)
      return "sev-high";
   if(sev == GOV_FAIL_SEV_WARNING_V1)
      return "sev-warn";
   return "sev-info";
}

inline string GovFailureHtmlV1_SevLabel(const int sev)
{
   if(sev >= GOV_FAIL_SEV_CRITICAL_V1)
      return "CRITICAL";
   if(sev == GOV_FAIL_SEV_HIGH_V1)
      return "HIGH";
   if(sev == GOV_FAIL_SEV_WARNING_V1)
      return "WARNING";
   return "INFO";
}

inline void GovFailureHtmlV1_AppendSection(const string sym,
                                          const SGovRuntimeTaggingModuleV1 &mod,
                                          const SGovLineageRegistryStoreV1 &lin,
                                          const SGovRecoveryStoreV1 &rec,
                                          SGovStratAttribSummaryV1 &sum,
                                          const SGovVisualExecSummaryV1 &ex,
                                          string &html)
{
   SGovFailureEventListV1 lst;
   GovFailureClsV1_Build(sym, mod, lin, rec, sum, ex, lst);
   const ulong h = GovFailureExpV1_Hash(lst);

   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-fail\"><h2>18. Failure diagnostics</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"mono\" style=\"margin-bottom:10px;color:#8b949e;\">failure_digest=" + IntegerToString((long)h) + "</div>\n");

   if(lst.n <= 0) {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<details open><summary class=\"sev-info\">INFO — No automated governance hazards tripped</summary>\n");
      GovRuntimeVisualHtmlW1_AppendLf(html, "<p>Classifier thresholds found no spread, margin, lineage cascade, or attribution faults for this export snapshot.</p></details>\n");
   } else {
      GovRuntimeVisualHtmlW1_AppendLf(html, "<div class=\"fail-grid\">\n");
      for(int i = 0; i < lst.n; i++) {
         const string sc = GovFailureHtmlV1_SevClass(lst.ev[i].severity);
         const string sl = GovFailureHtmlV1_SevLabel(lst.ev[i].severity);
         GovRuntimeVisualHtmlW1_AppendLf(html, "<details class=\"fail-card " + sc + "\"><summary><span class=\"badge tox-high\">" + sl + "</span> " +
                                           GovRuntimeVisualHtmlW1_Escape(lst.ev[i].title) + "</summary>\n");
         GovRuntimeVisualHtmlW1_AppendLf(html, "<p><b>Code</b> <span class=\"mono\">K" + IntegerToString(lst.ev[i].kind) + "</span></p>\n");
         if(StringLen(lst.ev[i].symbol) > 0)
            GovRuntimeVisualHtmlW1_AppendLf(html, "<p><b>Symbol</b> " + GovRuntimeVisualHtmlW1_Escape(lst.ev[i].symbol) + "</p>\n");
         if(lst.ev[i].metric_i != 0 || lst.ev[i].metric_d != 0.0)
            GovRuntimeVisualHtmlW1_AppendLf(html, "<p><b>Metric</b> i=" + IntegerToString(lst.ev[i].metric_i) + " d=" + DoubleToString(lst.ev[i].metric_d, 4) + "</p>\n");
         GovRuntimeVisualHtmlW1_AppendLf(html, "<p>" + GovRuntimeVisualHtmlW1_Escape(lst.ev[i].detail) + "</p>\n");
         GovRuntimeVisualHtmlW1_AppendLf(html, "</details>\n");
      }
      GovRuntimeVisualHtmlW1_AppendLf(html, "</div>\n");
   }
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");
}

#endif // __AURUM_GOV_FAILURE_HTML_V1_MQH__
