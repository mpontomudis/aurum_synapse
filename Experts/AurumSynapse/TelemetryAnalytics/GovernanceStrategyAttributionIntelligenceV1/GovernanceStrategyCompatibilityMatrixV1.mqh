//+------------------------------------------------------------------+
//| GovernanceStrategyCompatibilityMatrixV1.mqh                      |
//| Regime / volatility fit scores per strategy (−1000…+1000).        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRAT_CMPMX_V1_MQH__
#define __AURUM_GOV_STRAT_CMPMX_V1_MQH__

#include "GovernanceStrategyAttributionDatasetV1.mqh"

inline int GovStratCmpMxV1_RegimeFit(const int strat, const int regime, const SGovStratAttribSummaryV1 &sum)
{
   const int si = GovClampInt32(strat, 0, GOV_SATTR_STRAT_COUNT_V1 - 1);
   const int ri = GovClampInt32(regime, 0, GOV_SATTR_REGIME_COUNT_V1 - 1);
   const long cell = sum.cross_strat_regime_cents[si][ri];
   int sc = 0;
   if(cell > 0)
      sc = GovSaturatingAdd32(sc, GovClampInt32((int)GovFloorDivSigned64(cell, 10000L), 0, 500));
   if(cell < 0)
      sc = GovSaturatingAdd32(sc, -GovClampInt32((int)GovFloorDivSigned64(-cell, 10000L), 0, 500));
   if(ri == GOV_REGIME_TREND && si == (int)GOV_STRAT_TF && cell >= 0)
      sc = GovSaturatingAdd32(sc, 200);
   if(ri == GOV_REGIME_CHOP && si == (int)GOV_STRAT_MR && cell >= 0)
      sc = GovSaturatingAdd32(sc, 200);
   if(ri == GOV_REGIME_EXPANSION && si == (int)GOV_STRAT_MR && cell < 0)
      sc = GovSaturatingAdd32(sc, -150);
   if(ri == GOV_REGIME_CHOP && si == (int)GOV_STRAT_TF && cell < 0)
      sc = GovSaturatingAdd32(sc, -150);
   return GovClampInt32(sc, -1000, 1000);
}

inline int GovStratCmpMxV1_VolFit(const int strat, const int vol, const SGovStratAttribSummaryV1 &sum)
{
   const int si = GovClampInt32(strat, 0, GOV_SATTR_STRAT_COUNT_V1 - 1);
   const int vi = GovClampInt32(vol, 0, GOV_SATTR_VOL_COUNT_V1 - 1);
   const long cell = sum.cross_strat_vol_cents[si][vi];
   int sc = 0;
   if(cell > 0)
      sc = GovSaturatingAdd32(sc, GovClampInt32((int)GovFloorDivSigned64(cell, 10000L), 0, 500));
   if(cell < 0)
      sc = GovSaturatingAdd32(sc, -GovClampInt32((int)GovFloorDivSigned64(-cell, 10000L), 0, 500));
   return GovClampInt32(sc, -1000, 1000);
}

inline void GovStratCmpMxV1_Build(SGovStratAttribSummaryV1 &sum)
{
   for(int s = 0; s < GOV_SATTR_STRAT_COUNT_V1; s++) {
      for(int r = 0; r < GOV_SATTR_REGIME_COUNT_V1; r++)
         sum.compat_regime[s][r] = GovStratCmpMxV1_RegimeFit(s, r, sum);
      for(int v = 0; v < GOV_SATTR_VOL_COUNT_V1; v++)
         sum.compat_vol[s][v] = GovStratCmpMxV1_VolFit(s, v, sum);
   }
}

#endif // __AURUM_GOV_STRAT_CMPMX_V1_MQH__
