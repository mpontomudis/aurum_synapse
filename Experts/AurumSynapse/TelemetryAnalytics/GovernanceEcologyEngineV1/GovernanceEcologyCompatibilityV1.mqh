//+------------------------------------------------------------------+
//| GovernanceEcologyCompatibilityV1.mqh                            |
//| PHASE 23 — strategy ↔ Aurum regime preference map               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECOLOGY_COMPATIBILITY_V1_MQH__
#define __AURUM_GOV_ECOLOGY_COMPATIBILITY_V1_MQH__

#include "../GovernanceRegimeEngineV1/GovernanceRegimeDatasetV1.mqh"

inline int GovEcoCompatV1_PreferredStratSlot(const EAurumMarketRegime reg)
{
   switch(reg) {
   case AURUM_REGIME_TRENDING:
      return 0;
   case AURUM_REGIME_RANGING:
   case AURUM_REGIME_MEAN_REVERSION:
   case AURUM_REGIME_ACCUMULATION:
   case AURUM_REGIME_VOLATILITY_COMPRESSION:
      return 2;
   case AURUM_REGIME_BREAKOUT:
   case AURUM_REGIME_DISTRIBUTION:
      return 1;
   case AURUM_REGIME_LIQUIDITY_SWEEP:
      return 4;
   case AURUM_REGIME_HIGH_VOL:
   case AURUM_REGIME_VOLATILITY_EXPANSION:
      return 7;
   case AURUM_REGIME_LOW_VOL:
      return 5;
   default:
      return -1;
   }
}

#endif // __AURUM_GOV_ECOLOGY_COMPATIBILITY_V1_MQH__
