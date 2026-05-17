//+------------------------------------------------------------------+
//| GovernanceBacktestComparativeInsightsV1.mqh                     |
//| PHASE 20C — bridge to GovernanceComparativeInsightsV1            |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_BACKTEST_CMP_V1_MQH__
#define __AURUM_GOV_BACKTEST_CMP_V1_MQH__

#include "../GovernanceComparativeInsightsV1/GovernanceComparativeInsightsV1.mqh"

inline void GovBacktestCmpV1_AppendSection(const string current_kv,
                                          const SGovCmpRunRecordV1 &baseline,
                                          const SGovCmpRunRecordV1 &current,
                                          string &html)
{
   GovCmpHtmlV1_AppendSection(current_kv, baseline, current, html);
}

#endif // __AURUM_GOV_BACKTEST_CMP_V1_MQH__
