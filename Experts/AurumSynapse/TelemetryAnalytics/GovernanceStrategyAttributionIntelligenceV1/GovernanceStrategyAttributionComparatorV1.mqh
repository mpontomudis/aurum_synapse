//+------------------------------------------------------------------+
//| GovernanceStrategyAttributionComparatorV1.mqh                    |
//| Diff two finalized summaries.                                    |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRAT_ATTR_CMP_V1_MQH__
#define __AURUM_GOV_STRAT_ATTR_CMP_V1_MQH__

#include "GovernanceStrategyAttributionEngineV1.mqh"

inline void GovStratCmpV1_Init(SGovStratAttribComparisonV1 &c)
{
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      c.d_trades[i] = 0;
      c.d_pf_milli[i] = 0;
      c.d_profit_cents[i] = 0;
   }
}

inline void GovStratCmpV1_Diff(const SGovStratAttribSummaryV1 &a, const SGovStratAttribSummaryV1 &b, SGovStratAttribComparisonV1 &out)
{
   GovStratCmpV1_Init(out);
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      const SGovStratAttribStatsV1 sa = a.bd.by_strat[i];
      const SGovStratAttribStatsV1 sb = b.bd.by_strat[i];
      out.d_trades[i] = GovSaturatingAdd32(sb.trades, -sa.trades);
      out.d_pf_milli[i] = GovSaturatingAdd32(sb.pf_milli, -sa.pf_milli);
      const long na = sa.gross_win_cents - sa.gross_loss_cents;
      const long nb = sb.gross_win_cents - sb.gross_loss_cents;
      out.d_profit_cents[i] = GovStratAttrV1_SatAdd64(nb, -na);
   }
}

inline string GovStratCmpV1_Report(const SGovStratAttribComparisonV1 &c)
{
   string o = "===STRATEGY_ATTRIB_DIFF===\n";
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      o += IntegerToString(i) + ",d_trades=" + IntegerToString(c.d_trades[i]) + ",d_pf_milli=" + IntegerToString(c.d_pf_milli[i]) + ",d_net_cents=" + IntegerToString((int)c.d_profit_cents[i]) + "\n";
   }
   return o;
}

#endif // __AURUM_GOV_STRAT_ATTR_CMP_V1_MQH__
