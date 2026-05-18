//+------------------------------------------------------------------+
//| GovernanceRegimeMonthlyAnalyticsV1.mqh                          |
//| PHASE 22 — calendar month buckets (1..12)                        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REGIME_MONTHLY_ANALYTICS_V1_MQH__
#define __AURUM_GOV_REGIME_MONTHLY_ANALYTICS_V1_MQH__

#include "GovernanceRegimeDatasetV1.mqh"

inline int GovRegimeMoV1_MonthIdx(const datetime ts)
{
   MqlDateTime dt;
   TimeToStruct(ts, dt);
   const int m = dt.mon;
   if(m < 1 || m > 12)
      return 0;
   return m - 1;
}

inline void GovRegimeMoV1_OnBar(SGovRegimeRuntimeStoreV1 &s, const datetime ts, const int reg_slot)
{
   const int mi = GovRegimeMoV1_MonthIdx(ts);
   if(reg_slot >= 0 && reg_slot < GOV_REGIME_AURUM_SLOT_COUNT_V1)
      s.month_regime_hits[mi][reg_slot]++;
}

inline void GovRegimeMoV1_OnSignal(SGovRegimeRuntimeStoreV1 &s, const datetime ts)
{
   const int mi = GovRegimeMoV1_MonthIdx(ts);
   s.month_signals[mi]++;
}

inline void GovRegimeMoV1_OnTradeClose(SGovRegimeRuntimeStoreV1 &s, const datetime ts, const long profit_cents)
{
   const int mi = GovRegimeMoV1_MonthIdx(ts);
   s.month_trades[mi]++;
   s.month_net_cents[mi] += profit_cents;
}

inline int GovRegimeMoV1_DominantRegimeSlot(const SGovRegimeRuntimeStoreV1 &s, const int month_idx)
{
   int best = 0;
   ulong mx = 0;
   for(int r = 0; r < GOV_REGIME_AURUM_SLOT_COUNT_V1; r++) {
      if(s.month_regime_hits[month_idx][r] > mx) {
         mx = s.month_regime_hits[month_idx][r];
         best = r;
      }
   }
   return best;
}

#endif // __AURUM_GOV_REGIME_MONTHLY_ANALYTICS_V1_MQH__
