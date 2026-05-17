//+------------------------------------------------------------------+
//| GovernanceStrategyAttributionEngineV1.mqh                        |
//| Deterministic aggregation — long / int only (no floats).         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRAT_ATTR_ENG_V1_MQH__
#define __AURUM_GOV_STRAT_ATTR_ENG_V1_MQH__

#include "GovernanceStrategyTradeTaggerV1.mqh"

inline long GovStratAttrV1_SatAdd64(const long a, const long b)
{
   if(b > 0 && a > 9223372036854775807L - b)
      return 9223372036854775807L;
   if(b < 0 && a < (-9223372036854775807L - 1L) - b)
      return (-9223372036854775807L - 1L);
   return a + b;
}

inline void GovStratAttrV1_AccOne(SGovStratAttribStatsV1 &st, const SGovStratAttribTradeV1 &tr)
{
   st.trades = GovSaturatingAdd32(st.trades, 1);
   if(tr.profit_cents > 0) {
      st.wins = GovSaturatingAdd32(st.wins, 1);
      st.gross_win_cents = GovStratAttrV1_SatAdd64(st.gross_win_cents, tr.profit_cents);
   } else if(tr.profit_cents < 0) {
      st.losses = GovSaturatingAdd32(st.losses, 1);
      st.gross_loss_cents = GovStratAttrV1_SatAdd64(st.gross_loss_cents, -tr.profit_cents);
   }
   if(tr.stopout != 0)
      st.stopout_count = GovSaturatingAdd32(st.stopout_count, 1);
   if(tr.tail_loss != 0)
      st.tail_loss_count = GovSaturatingAdd32(st.tail_loss_count, 1);
   st.avg_hold_bars_x100 = GovSaturatingAdd32(st.avg_hold_bars_x100, GovSaturatingMul32(tr.hold_bars, 100));
   if(tr.profit_cents < 0) {
      const int dd = GovSaturateLongToInt32(-tr.profit_cents);
      if(dd > st.max_dd_contrib_cents)
         st.max_dd_contrib_cents = dd;
   }
}

inline void GovStratAttrV1_AccTrade(SGovStratAttribSummaryV1 &sum, const SGovStratAttribTradeV1 &tr)
{
   const int si = GovClampInt32(tr.strat, 0, GOV_SATTR_STRAT_COUNT_V1 - 1);
   const int ri = GovClampInt32(tr.regime, 0, GOV_SATTR_REGIME_COUNT_V1 - 1);
   const int vi = GovClampInt32(tr.vol, 0, GOV_SATTR_VOL_COUNT_V1 - 1);
   const int ti = GovClampInt32(tr.session, 0, GOV_SATTR_SESSION_COUNT_V1 - 1);
   GovStratAttrV1_AccOne(sum.bd.by_strat[si], tr);
   GovStratAttrV1_AccOne(sum.bd.regime.by_reg[ri], tr);
   GovStratAttrV1_AccOne(sum.bd.session.by_sess[ti], tr);
   GovStratAttrV1_AccOne(sum.bd.vol.by_vol[vi], tr);
   sum.cross_strat_regime_cents[si][ri] = GovStratAttrV1_SatAdd64(sum.cross_strat_regime_cents[si][ri], tr.profit_cents);
   sum.cross_strat_vol_cents[si][vi] = GovStratAttrV1_SatAdd64(sum.cross_strat_vol_cents[si][vi], tr.profit_cents);
   sum.trade_count_input = GovSaturatingAdd32(sum.trade_count_input, 1);
}

inline void GovStratAttrV1_FinalizeStats(SGovStratAttribStatsV1 &st)
{
   if(st.trades <= 0) {
      GovStrAttrDsV1_InitStats(st);
      return;
   }
   const long gw = st.gross_win_cents;
   const long gl = st.gross_loss_cents;
   if(gl <= 0)
      st.pf_milli = (gw > 0) ? 1000000 : 0;
   else {
      const long pm = (gw * 1000L) / gl;
      st.pf_milli = GovSaturateLongToInt32(pm);
      if(st.pf_milli < 0)
         st.pf_milli = 0;
      if(st.pf_milli > 10000000)
         st.pf_milli = 10000000;
   }
   const long net = gw - gl;
   st.expectancy_micro = (int)GovFloorDivSigned64(net * 1000000L, (long)st.trades);
   st.avg_hold_bars_x100 = GovClampInt32((int)GovFloorDivSigned64((long)st.avg_hold_bars_x100, (long)st.trades), -1000000000, 1000000000);
   st.avg_continuation_x100 = st.avg_hold_bars_x100;
}

inline void GovStratAttrV1_FinalizeExecBlock(SGovStratAttribSummaryV1 &sum)
{
   int tw = 0;
   int tt = 0;
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      tw = GovSaturatingAdd32(tw, sum.bd.by_strat[i].wins);
      tt = GovSaturatingAdd32(tt, sum.bd.by_strat[i].trades);
   }
   if(tt <= 0) {
      sum.bd.exec.quality_score_x1000 = 0;
      return;
   }
   sum.bd.exec.quality_score_x1000 = GovClampInt32((int)GovFloorDivSigned64((long)tw * 1000L, (long)tt), 0, 1000);
   sum.bd.exec.slip_proxy_ticks = 0;
   sum.bd.exec.reentry_count = 0;
}

inline void GovStratAttrV1_Finalize(SGovStratAttribSummaryV1 &sum)
{
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++)
      GovStratAttrV1_FinalizeStats(sum.bd.by_strat[i]);
   for(int r = 0; r < GOV_SATTR_REGIME_COUNT_V1; r++)
      GovStratAttrV1_FinalizeStats(sum.bd.regime.by_reg[r]);
   for(int v = 0; v < GOV_SATTR_VOL_COUNT_V1; v++)
      GovStratAttrV1_FinalizeStats(sum.bd.vol.by_vol[v]);
   for(int s = 0; s < GOV_SATTR_SESSION_COUNT_V1; s++)
      GovStratAttrV1_FinalizeStats(sum.bd.session.by_sess[s]);
   GovStratAttrV1_FinalizeExecBlock(sum);
}

inline void GovStratAttrV1_AccProfit(SGovStratAttribStatsV1 &st, const long profit_cents)
{
   SGovStratAttribTradeV1 tmp;
   GovStrAttrDsV1_InitTrade(tmp);
   tmp.profit_cents = profit_cents;
   GovStratAttrV1_AccOne(st, tmp);
}

inline void GovStratAttrV1_AccRegime(SGovStratAttribSummaryV1 &sum, const int regime, const SGovStratAttribTradeV1 &tr)
{
   const int ri = GovClampInt32(regime, 0, GOV_SATTR_REGIME_COUNT_V1 - 1);
   GovStratAttrV1_AccOne(sum.bd.regime.by_reg[ri], tr);
   const int si = GovClampInt32(tr.strat, 0, GOV_SATTR_STRAT_COUNT_V1 - 1);
   sum.cross_strat_regime_cents[si][ri] = GovStratAttrV1_SatAdd64(sum.cross_strat_regime_cents[si][ri], tr.profit_cents);
}

inline void GovStratAttrV1_AccSession(SGovStratAttribSummaryV1 &sum, const int sess, const SGovStratAttribTradeV1 &tr)
{
   const int ti = GovClampInt32(sess, 0, GOV_SATTR_SESSION_COUNT_V1 - 1);
   GovStratAttrV1_AccOne(sum.bd.session.by_sess[ti], tr);
}

inline void GovStratAttrV1_AccVol(SGovStratAttribSummaryV1 &sum, const int vol, const SGovStratAttribTradeV1 &tr)
{
   const int vi = GovClampInt32(vol, 0, GOV_SATTR_VOL_COUNT_V1 - 1);
   GovStratAttrV1_AccOne(sum.bd.vol.by_vol[vi], tr);
   const int si = GovClampInt32(tr.strat, 0, GOV_SATTR_STRAT_COUNT_V1 - 1);
   sum.cross_strat_vol_cents[si][vi] = GovStratAttrV1_SatAdd64(sum.cross_strat_vol_cents[si][vi], tr.profit_cents);
}

#endif // __AURUM_GOV_STRAT_ATTR_ENG_V1_MQH__
