//+------------------------------------------------------------------+
//| GovernanceRegimeMonthlyAggregationV1.mqh                        |
//| PHASE 22A — continuous month buckets (calendar months 0..11)      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REGIME_MONTHLY_AGGREGATION_V1_MQH__
#define __AURUM_GOV_REGIME_MONTHLY_AGGREGATION_V1_MQH__

#include "GovernanceRegimeMonthlyAnalyticsV1.mqh"

inline void GovRegimeMoAgg22A_OnBar(SGovRegimeRuntimeStoreV1 &s, const datetime ts, const int conf_permille)
{
   const int mi = GovRegimeMoV1_MonthIdx(ts);
   if(mi < 0 || mi >= 12)
      return;
   s.month_bars[mi]++;
   if(conf_permille > 0)
      s.month_conf_pm_sum[mi] += (ulong)conf_permille;
}

inline int GovRegimeMoAgg22A_MonthsWithBars(const SGovRegimeRuntimeStoreV1 &s)
{
   int n = 0;
   for(int m = 0; m < 12; m++) {
      if(s.month_bars[m] > 0)
         n++;
   }
   return n;
}

inline int GovRegimeMoAgg22A_MonthsDominantUnknown(const SGovRegimeRuntimeStoreV1 &s)
{
   int n = 0;
   for(int m = 0; m < 12; m++) {
      if(s.month_bars[m] == 0)
         continue;
      const int dom = GovRegimeMoV1_DominantRegimeSlot(s, m);
      if(dom == 0)
         n++;
   }
   return n;
}

inline int GovRegimeMoAgg22A_ContinuityPermille(const SGovRegimeRuntimeStoreV1 &s)
{
   int pop = 0;
   for(int m = 0; m < 12; m++) {
      if(s.month_bars[m] > 0)
         pop++;
   }
   return (int)(1000L * (long)pop / 12L);
}

inline int GovRegimeMoAgg22A_AvgConfPermilleMonth(const SGovRegimeRuntimeStoreV1 &s, const int m)
{
   if(m < 0 || m >= 12)
      return 0;
   if(s.month_bars[m] == 0)
      return 0;
   return (int)(s.month_conf_pm_sum[m] / s.month_bars[m]);
}

#endif // __AURUM_GOV_REGIME_MONTHLY_AGGREGATION_V1_MQH__
