//+------------------------------------------------------------------+
//| GovernanceStrategyVocabularyV1.mqh                              |
//| PHASE 20F — single user-facing strategy names (Inputs panel)      |
//| Underlying numeric values MUST match ENUM_GOV_STRAT_CODE_V1      |
//| (StrategyManager / attribution axis index 0..7).                 |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRATEGY_VOCABULARY_V1_MQH__
#define __AURUM_GOV_STRATEGY_VOCABULARY_V1_MQH__

#include "GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionDatasetV1.mqh"

// User-facing IDs: same integer line as GOV_STRAT_TF..GOV_STRAT_MS.
enum ENUM_GOV_STRATEGY_ID
{
   GOV_STRAT_TRENDFOLLOWING = 0,
   GOV_STRAT_BREAKOUT = 1,
   GOV_STRAT_MEANREVERSION = 2,
   GOV_STRAT_SUPPLYDEMAND = 3,
   GOV_STRAT_MOMENTUMSCALP = 4,
   GOV_STRAT_PRICEACTION = 5,
   GOV_STRAT_GRIDRECOVERY = 6,
   GOV_STRAT_SMARTMONEY = 7
};

inline string GovStrategyV1_Name(const ENUM_GOV_STRATEGY_ID id)
{
   switch(id) {
   case GOV_STRAT_TRENDFOLLOWING:
      return "TrendFollowing";
   case GOV_STRAT_BREAKOUT:
      return "Breakout";
   case GOV_STRAT_MEANREVERSION:
      return "MeanReversion";
   case GOV_STRAT_SUPPLYDEMAND:
      return "SupplyDemand";
   case GOV_STRAT_MOMENTUMSCALP:
      return "MomentumScalp";
   case GOV_STRAT_PRICEACTION:
      return "PriceAction";
   case GOV_STRAT_GRIDRECOVERY:
      return "GridRecovery";
   case GOV_STRAT_SMARTMONEY:
      return "SmartMoney";
   default:
      return "UnknownStrategy";
   }
}

inline string GovStrategyV1_NameFromAxisIndex(const int strat_0_7)
{
   const int i = GovClampInt32(strat_0_7, 0, GOV_SATTR_STRAT_COUNT_V1 - 1);
   return GovStrategyV1_Name((ENUM_GOV_STRATEGY_ID)i);
}

// Baseline / legacy dossier strings (pre–PHASE 20F codenames) → Inputs-panel names.
inline string GovStrategyV1_NormalizeLegacyLabel(const string s)
{
   if(s == "StructuralDrift")
      return GovStrategyV1_Name(GOV_STRAT_SUPPLYDEMAND);
   if(s == "SessionMomentum")
      return GovStrategyV1_Name(GOV_STRAT_MOMENTUMSCALP);
   if(s == "MetaStack")
      return GovStrategyV1_Name(GOV_STRAT_SMARTMONEY);
   return s;
}

#endif // __AURUM_GOV_STRATEGY_VOCABULARY_V1_MQH__
