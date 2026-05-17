//+------------------------------------------------------------------+
//| GovernanceRuntimeStrategyTagDatasetV1.mqh                        |
//| GOVERNANCE_RUNTIME_STRATEGY_TAGGING_V1 — runtime trade identity  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_STRAT_TAG_DS_V1_MQH__
#define __AURUM_GOV_RUNTIME_STRAT_TAG_DS_V1_MQH__

#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionDatasetV1.mqh"

#define GOV_RTAG_TAG_MAX_LEN_V1   31

//+------------------------------------------------------------------+
struct SGovRuntimeTradeIdentityV1
{
   int    strategy_id;
   int    regime_id;
   int    volatility_id;
   int    session_id;
   int    execution_type_id;
   int    ticket_low32;
   long   open_time;
   int    quality_score_bp;
   string tag;
};

//+------------------------------------------------------------------+
inline void GovRunTagDsV1_InitIdentity(SGovRuntimeTradeIdentityV1 &x)
{
   x.strategy_id = 0;
   x.regime_id = 0;
   x.volatility_id = 0;
   x.session_id = 0;
   x.execution_type_id = 0;
   x.ticket_low32 = 0;
   x.open_time = 0;
   x.quality_score_bp = 0;
   x.tag = "";
}

//+------------------------------------------------------------------+
inline void GovRunTagDsV1_ResetIdentity(SGovRuntimeTradeIdentityV1 &x)
{
   GovRunTagDsV1_InitIdentity(x);
}

//+------------------------------------------------------------------+
inline bool GovRunTagDsV1_ValidateIdentity(const SGovRuntimeTradeIdentityV1 &x)
{
   if(x.strategy_id < 0 || x.strategy_id >= GOV_SATTR_STRAT_COUNT_V1)
      return false;
   if(x.regime_id < 0 || x.regime_id >= GOV_SATTR_REGIME_COUNT_V1)
      return false;
   if(x.volatility_id < 0 || x.volatility_id >= GOV_SATTR_VOL_COUNT_V1)
      return false;
   if(x.session_id < 0 || x.session_id >= GOV_SATTR_SESSION_COUNT_V1)
      return false;
   if(x.execution_type_id < 0 || x.execution_type_id > 9)
      return false;
   if(StringLen(x.tag) > GOV_RTAG_TAG_MAX_LEN_V1)
      return false;
   return true;
}

#endif // __AURUM_GOV_RUNTIME_STRAT_TAG_DS_V1_MQH__
