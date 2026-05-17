//+------------------------------------------------------------------+
//| GovernanceBacktestFailureDiagnosticsV1.mqh                       |
//| PHASE 20C — bridge to GovernanceFailureDiagnosticsV1             |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_BACKTEST_FAIL_V1_MQH__
#define __AURUM_GOV_BACKTEST_FAIL_V1_MQH__

#include "../GovernanceFailureDiagnosticsV1/GovernanceFailureDiagnosticsV1.mqh"

inline void GovBacktestFailV1_AppendSection(const string sym,
                                           const SGovRuntimeTaggingModuleV1 &mod,
                                           const SGovRecoveryStoreV1 &rec,
                                           SGovStratAttribSummaryV1 &sum,
                                           const SGovVisualExecSummaryV1 &ex,
                                           const SGovLineageRegistryStoreV1 &lin,
                                           string &html)
{
   GovFailureHtmlV1_AppendSection(sym, mod, lin, rec, sum, ex, html);
}

#endif // __AURUM_GOV_BACKTEST_FAIL_V1_MQH__
