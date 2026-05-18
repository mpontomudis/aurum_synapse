//+------------------------------------------------------------------+
//| GovernanceEcologyTelemetryV1.mqh                                |
//| PHASE 23 — counters (per bar / co-occurrence / slices)            |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECOLOGY_TELEMETRY_V1_MQH__
#define __AURUM_GOV_ECOLOGY_TELEMETRY_V1_MQH__

#include "GovernanceEcologyDatasetV1.mqh"
#include "../../Core/Structures.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

inline int GovEcoTelV1_MonthIdx(const datetime ts)
{
   MqlDateTime dt;
   TimeToStruct(ts, dt);
   int m = dt.mon - 1;
   if(m < 0)
      m = 0;
   if(m > 11)
      m = 11;
   return m;
}

inline int GovEcoTelV1_VolBucket(const double atr_ratio)
{
   if(atr_ratio < 0.85)
      return 0;
   if(atr_ratio < 1.05)
      return 1;
   if(atr_ratio < 1.35)
      return 2;
   return 3;
}

inline void GovEcoTelV1_OnCooccurrencePreApply(SGovEcologyStoreV1 &st, const SignalResult &signals[])
{
   int act[GOV_ECO_STRAT_COUNT_V1];
   int nact = 0;
   for(int i = 0; i < GOV_ECO_STRAT_COUNT_V1; i++) {
      act[i] = (signals[i].signal != SIGNAL_NONE) ? 1 : 0;
      if(act[i] != 0)
         nact++;
   }
   for(int a = 0; a < GOV_ECO_STRAT_COUNT_V1; a++) {
      if(act[a] == 0)
         continue;
      for(int b = a; b < GOV_ECO_STRAT_COUNT_V1; b++) {
         if(act[b] == 0)
            continue;
         st.cooccur[a][b]++;
         if(b != a)
            st.cooccur[b][a]++;
      }
   }
}

inline void GovEcoTelV1_OnStratBarSlice(SGovEcologyStoreV1 &st,
                                        const int strat,
                                        const int session_id,
                                        const int vol_bucket,
                                        const int month_idx,
                                        const bool participating)
{
   const int si = GovClampInt32(strat, 0, GOV_ECO_STRAT_COUNT_V1 - 1);
   const int se = GovClampInt32(session_id, 0, GOV_ECO_SESSION_COUNT_V1 - 1);
   const int vb = GovClampInt32(vol_bucket, 0, GOV_ECO_VOL_BUCKET_V1 - 1);
   const int mi = GovClampInt32(month_idx, 0, GOV_ECO_MONTHS_V1 - 1);
   if(participating) {
      st.strat_bars_by_sess[si][se]++;
      st.strat_bars_by_vol[si][vb]++;
      st.s[si].month_participation_bars[mi]++;
   }
}

#endif // __AURUM_GOV_ECOLOGY_TELEMETRY_V1_MQH__
