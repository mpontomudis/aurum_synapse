//+------------------------------------------------------------------+
//| GovernanceRuntimeStrategyClassifierV1.mqh                        |
//| Deterministic classification — existing context only (no AI).    |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_STRAT_CLASS_V1_MQH__
#define __AURUM_GOV_RUNTIME_STRAT_CLASS_V1_MQH__

#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionDatasetV1.mqh"
#include "../GovernanceStrategyVocabularyV1.mqh"
#include "../../Core/Constants.mqh"

enum ENUM_GOV_RTAG_EXECUTION_TYPE_V1
{
   GOV_RTAG_EXEC_MARKET = 0,
   GOV_RTAG_EXEC_LIMIT = 1,
   GOV_RTAG_EXEC_STOP = 2,
   GOV_RTAG_EXEC_STOP_LIMIT = 3,
   GOV_RTAG_EXEC_UNKNOWN = 9
};

//+------------------------------------------------------------------+
//| Strategy axis — StrategyManager index 0..7 → ENUM_GOV_STRATEGY_ID|
//+------------------------------------------------------------------+
inline ENUM_GOV_STRATEGY_ID GovRunTagV1_ClassifyStrategyId(const int strategy_index_0_7)
{
   return (ENUM_GOV_STRATEGY_ID)GovClampInt32(strategy_index_0_7, 0, GOV_SATTR_STRAT_COUNT_V1 - 1);
}

inline int GovRunTagV1_ClassifyStrategy(const int strategy_index_0_7)
{
   return (int)GovRunTagV1_ClassifyStrategyId(strategy_index_0_7);
}

//+------------------------------------------------------------------+
inline int GovRunTagV1_ClassifyRegime(const ENUM_REGIME regime)
{
   switch(regime) {
   case REGIME_TRENDING:
      return (int)GOV_REGIME_TREND;
   case REGIME_RANGING:
      return (int)GOV_REGIME_CHOP;
   case REGIME_VOLATILE:
      return (int)GOV_REGIME_EXPANSION;
   case REGIME_CALM:
      return (int)GOV_REGIME_COMPRESSION;
   default:
      return (int)GOV_REGIME_COMPRESSION;
   }
}

//+------------------------------------------------------------------+
inline int GovRunTagV1_ClassifySession(const ENUM_SESSION session)
{
   switch(session) {
   case SESSION_ASIAN:
      return (int)GOV_SATTR_SESS_ASIA;
   case SESSION_LONDON:
      return (int)GOV_SATTR_SESS_LONDON;
   case SESSION_NEWYORK:
      return (int)GOV_SATTR_SESS_NY;
   case SESSION_OVERLAP:
   default:
      return (int)GOV_SATTR_SESS_OVERLAP;
   }
}

//+------------------------------------------------------------------+
//| ATR ratio buckets — thresholds frozen (deterministic, replay).   |
//+------------------------------------------------------------------+
inline int GovRunTagV1_ClassifyVolatility(const double atr_ratio)
{
   if(!MathIsValidNumber(atr_ratio))
      return (int)GOV_SATTR_VOL_MED;
   if(atr_ratio < 0.85)
      return (int)GOV_SATTR_VOL_LOW;
   if(atr_ratio < 1.15)
      return (int)GOV_SATTR_VOL_MED;
   if(atr_ratio < 1.75)
      return (int)GOV_SATTR_VOL_HIGH;
   return (int)GOV_SATTR_VOL_EXTREME;
}

//+------------------------------------------------------------------+
//| Execution channel — EA uses market CTrade only → MARKET.         |
//+------------------------------------------------------------------+
inline int GovRunTagV1_ClassifyExecution(const bool is_pending_limit_order)
{
   if(is_pending_limit_order)
      return (int)GOV_RTAG_EXEC_LIMIT;
   return (int)GOV_RTAG_EXEC_MARKET;
}

#endif // __AURUM_GOV_RUNTIME_STRAT_CLASS_V1_MQH__
