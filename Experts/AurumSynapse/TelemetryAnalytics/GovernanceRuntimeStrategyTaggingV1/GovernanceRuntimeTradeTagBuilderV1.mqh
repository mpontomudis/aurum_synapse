//+------------------------------------------------------------------+
//| GovernanceRuntimeTradeTagBuilderV1.mqh                           |
//| Deterministic tag strings — delegates to frozen vocabulary.      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_TRADE_TAG_BUILD_V1_MQH__
#define __AURUM_GOV_RUNTIME_TRADE_TAG_BUILD_V1_MQH__

#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyTradeTaggerV1.mqh"
#include "GovernanceRuntimeStrategyTagDatasetV1.mqh"

inline string GovRunTagV1_StrategyCode(const int strategy_id)
{
   return GovStratTagV1_StrategyCode(strategy_id);
}

inline string GovRunTagV1_RegimeCode(const int regime_id)
{
   return GovStratTagV1_RegimeCode(regime_id);
}

inline string GovRunTagV1_VolCode(const int volatility_id)
{
   return GovStratTagV1_VolCode(volatility_id);
}

inline string GovRunTagV1_SessionCode(const int session_id)
{
   return GovStratTagV1_SessionCode(session_id);
}

//+------------------------------------------------------------------+
//| Fixed order: STRAT|REGIME|VOL|SESSION                              |
//+------------------------------------------------------------------+
inline void GovRunTagV1_Build(const int strategy_id,
                              const int regime_id,
                              const int volatility_id,
                              const int session_id,
                              string &out_tag)
{
   GovStratTagV1_BuildTag(strategy_id, regime_id, volatility_id, session_id, out_tag);
   const int mx = GOV_RTAG_TAG_MAX_LEN_V1;
   if(StringLen(out_tag) > mx)
      out_tag = StringSubstr(out_tag, 0, mx);
}

#endif // __AURUM_GOV_RUNTIME_TRADE_TAG_BUILD_V1_MQH__
