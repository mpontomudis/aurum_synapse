//+------------------------------------------------------------------+
//| GovernanceRegimeCalibrationV1.mqh                                |
//| PHASE 22A — deterministic regime-aware governance scaling         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REGIME_CALIBRATION_V1_MQH__
#define __AURUM_GOV_REGIME_CALIBRATION_V1_MQH__

#include "GovernanceRegimeDatasetV1.mqh"

inline int GovRegCalibV1_EffectiveMinConsensus(const int base_min, const EAurumMarketRegime r)
{
   const int b = (base_min < 1) ? 1 : ((base_min > 8) ? 8 : base_min);
   if(r == AURUM_REGIME_LOW_VOL || r == AURUM_REGIME_VOLATILITY_COMPRESSION || r == AURUM_REGIME_ACCUMULATION) {
      const int t = b - 1;
      return (t < 1) ? 1 : t;
   }
   if(r == AURUM_REGIME_TRENDING || r == AURUM_REGIME_HIGH_VOL || r == AURUM_REGIME_BREAKOUT ||
      r == AURUM_REGIME_VOLATILITY_EXPANSION) {
      const int t = b + 1;
      return (t > 8) ? 8 : t;
   }
   return b;
}

inline int GovRegCalibV1_EffectiveMinQuality(const int base_q, const EAurumMarketRegime r)
{
   const int b = (base_q < 30) ? 30 : ((base_q > 90) ? 90 : base_q);
   if(r == AURUM_REGIME_LOW_VOL || r == AURUM_REGIME_VOLATILITY_COMPRESSION || r == AURUM_REGIME_ACCUMULATION) {
      const int t = b - 5;
      return (t < 30) ? 30 : t;
   }
   if(r == AURUM_REGIME_TRENDING || r == AURUM_REGIME_HIGH_VOL || r == AURUM_REGIME_BREAKOUT ||
      r == AURUM_REGIME_VOLATILITY_EXPANSION) {
      const int t = b + 3;
      return (t > 90) ? 90 : t;
   }
   return b;
}

#endif // __AURUM_GOV_REGIME_CALIBRATION_V1_MQH__
