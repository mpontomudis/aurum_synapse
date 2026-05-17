//+------------------------------------------------------------------+
//| GovernanceStrategyAttributionSandboxV1.mqh                       |
//| Isolated copy of trades / summary (no production replay touch).  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRAT_SBX_V1_MQH__
#define __AURUM_GOV_STRAT_SBX_V1_MQH__

#include "GovernanceStrategyAttributionDatasetV1.mqh"

inline void GovStratSbxV1_CloneTrade(const SGovStratAttribTradeV1 &src, SGovStratAttribTradeV1 &dst)
{
   dst.strat = src.strat;
   dst.regime = src.regime;
   dst.session = src.session;
   dst.vol = src.vol;
   dst.profit_cents = src.profit_cents;
   dst.hold_bars = src.hold_bars;
   dst.stopout = src.stopout;
   dst.tail_loss = src.tail_loss;
}

inline void GovStratSbxV1_CloneSummary(const SGovStratAttribSummaryV1 &src, SGovStratAttribSummaryV1 &dst)
{
   dst = src;
}

inline bool GovStratSbxV1_CloneTrades(SGovStratAttribTradeV1 &src[], const int n_src, SGovStratAttribTradeV1 &dst[], int &out_n)
{
   out_n = 0;
   if(n_src < 0)
      return false;
   if(ArrayResize(dst, n_src) == -1)
      return false;
   for(int i = 0; i < n_src; i++)
      GovStratSbxV1_CloneTrade(src[i], dst[i]);
   out_n = n_src;
   return true;
}

#endif // __AURUM_GOV_STRAT_SBX_V1_MQH__
