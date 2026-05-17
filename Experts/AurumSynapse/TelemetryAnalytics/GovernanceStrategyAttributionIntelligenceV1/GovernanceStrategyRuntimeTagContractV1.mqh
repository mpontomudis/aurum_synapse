//+------------------------------------------------------------------+
//| GovernanceStrategyRuntimeTagContractV1.mqh                       |
//| Minimal POD for optional hot-path tagging (no heavy analytics).  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRAT_RTC_V1_MQH__
#define __AURUM_GOV_STRAT_RTC_V1_MQH__

struct SGovStratRuntimeTagV1
{
   int strategy_id;
   int regime_id;
   int vol_state;
   int session_id;
};

inline void GovStratRtcV1_Init(SGovStratRuntimeTagV1 &t)
{
   t.strategy_id = 0;
   t.regime_id = 0;
   t.vol_state = 0;
   t.session_id = 0;
}

#endif // __AURUM_GOV_STRAT_RTC_V1_MQH__
