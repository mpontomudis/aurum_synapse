//+------------------------------------------------------------------+
//| GovernanceEcologySuppressionV1.mqh                             |
//| PHASE 23 — participation state machine (governance-only)         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECOLOGY_SUPPRESSION_V1_MQH__
#define __AURUM_GOV_ECOLOGY_SUPPRESSION_V1_MQH__

#include "GovernanceEcologyDatasetV1.mqh"
#include "GovernanceEcologyCompatibilityV1.mqh"
#include "../GovernanceRegimeEngineV1/GovernanceRegimeDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "../../Core/Constants.mqh"

inline bool GovEcoSupV1_RegimeDisablesStrat(const EAurumMarketRegime reg, const int strat)
{
   if(strat == 2) {
      if(reg == AURUM_REGIME_VOLATILITY_EXPANSION || reg == AURUM_REGIME_HIGH_VOL || reg == AURUM_REGIME_BREAKOUT)
         return true;
   }
   if(strat == 1) {
      if(reg == AURUM_REGIME_LOW_VOL || reg == AURUM_REGIME_VOLATILITY_COMPRESSION)
         return true;
   }
   if(strat == 0) {
      if(reg == AURUM_REGIME_RANGING || reg == AURUM_REGIME_MEAN_REVERSION)
         return true;
   }
   if(strat == 7) {
      if(reg == AURUM_REGIME_LOW_VOL || reg == AURUM_REGIME_VOLATILITY_COMPRESSION)
         return true;
   }
   return false;
}

inline int GovEcoSupV1_ResolveState(const EAurumMarketRegime reg,
                                    const ENUM_REGIME legacy_reg,
                                    const SGovEcologyStratSliceV1 &z,
                                    const int strat,
                                    const int monoculture_warn)
{
   if(GovEcoSupV1_RegimeDisablesStrat(reg, strat))
      return GOV_ECO_ST_DISABLED_BY_REGIME;
   if(z.toxicity_score_permille >= 780)
      return GOV_ECO_ST_TOXIC;
   if(z.toxicity_score_permille >= 620 && z.compatibility_score_permille < 420)
      return GOV_ECO_ST_SUPPRESSED;
   if(legacy_reg == REGIME_RANGING && strat == 0 && z.regime_mismatch_hits > z.regime_alignment_hits + 40)
      return GOV_ECO_ST_SUPPRESSED;
   if(monoculture_warn != 0 && z.dominance_pick_bars > 200 && strat == GovEcoCompatV1_PreferredStratSlot(reg))
      return GOV_ECO_ST_THROTTLED;
   if(z.toxicity_score_permille >= 480)
      return GOV_ECO_ST_PASSIVE;
   if(z.dominance_pick_bars * 10 > (z.regime_alignment_hits + z.regime_mismatch_hits + 10) * 6)
      return GOV_ECO_ST_DOMINANT;
   if(z.toxicity_score_permille > 520 && z.compatibility_score_permille < 480)
      return GOV_ECO_ST_RECOVERING;
   return GOV_ECO_ST_ACTIVE;
}

#endif // __AURUM_GOV_ECOLOGY_SUPPRESSION_V1_MQH__
