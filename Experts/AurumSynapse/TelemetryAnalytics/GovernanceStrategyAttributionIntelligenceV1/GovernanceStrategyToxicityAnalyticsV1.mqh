//+------------------------------------------------------------------+
//| GovernanceStrategyToxicityAnalyticsV1.mqh                        |
//| Integer toxicity scoring (0–1000).                               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRAT_TOX_V1_MQH__
#define __AURUM_GOV_STRAT_TOX_V1_MQH__

#include "GovernanceStrategyAttributionEngineV1.mqh"

inline int GovStratToxV1_RegimeMismatch(const int strat, const SGovStratAttribSummaryV1 &sum)
{
   const int si = GovClampInt32(strat, 0, GOV_SATTR_STRAT_COUNT_V1 - 1);
   long trend = sum.cross_strat_regime_cents[si][GOV_REGIME_TREND];
   long chop = sum.cross_strat_regime_cents[si][GOV_REGIME_CHOP];
   long tox = sum.cross_strat_regime_cents[si][GOV_REGIME_TOXIC];
   int m = 0;
   if(trend < 0 && chop > 0)
      m = GovSaturatingAdd32(m, 120);
   if(trend < 0 && tox > 0)
      m = GovSaturatingAdd32(m, 180);
   if(tox < 0 && trend > 0)
      m = GovSaturatingAdd32(m, 80);
   return GovClampInt32(m, 0, 1000);
}

inline void GovStratToxV1_Score(const int strat, const SGovStratAttribSummaryV1 &sum, SGovStratAttribToxicityV1 &out)
{
   GovStrAttrDsV1_InitToxicity(out);
   const int si = GovClampInt32(strat, 0, GOV_SATTR_STRAT_COUNT_V1 - 1);
   const SGovStratAttribStatsV1 st = sum.bd.by_strat[si];
   if(st.trades <= 0)
      return;
   int s = 0;
   if(st.pf_milli < 800)
      s = GovSaturatingAdd32(s, 160);
   if(st.pf_milli < 500)
      s = GovSaturatingAdd32(s, 160);
   if(st.pf_milli < 300)
      s = GovSaturatingAdd32(s, 120);
   const int loss_rate_x1000 = (int)GovFloorDivSigned64((long)st.losses * 1000L, (long)st.trades);
   out.loss_persist = GovClampInt32(loss_rate_x1000, 0, 1000);
   if(loss_rate_x1000 > 550)
      s = GovSaturatingAdd32(s, 140);
   out.stopout_rate_x1000 = GovClampInt32((int)GovFloorDivSigned64((long)st.stopout_count * 1000L, (long)st.trades), 0, 1000);
   if(out.stopout_rate_x1000 > 180)
      s = GovSaturatingAdd32(s, 120);
   const int tail_x1000 = (int)GovFloorDivSigned64((long)st.tail_loss_count * 1000L, (long)st.trades);
   if(tail_x1000 > 120)
      s = GovSaturatingAdd32(s, 100);
   if(st.gross_loss_cents > st.gross_win_cents && st.gross_loss_cents > 0) {
      s = GovSaturatingAdd32(s, 140);
      out.pf_collapse = 1;
   }
   const long net = st.gross_win_cents - st.gross_loss_cents;
   if(net < -10000000L) {
      s = GovSaturatingAdd32(s, 100);
      out.catastrophic_cluster = 1;
   }
   out.regime_mismatch = GovStratToxV1_RegimeMismatch(si, sum);
   s = GovSaturatingAdd32(s, GovClampInt32(out.regime_mismatch / 4, 0, 250));
   const SGovStratAttribStatsV1 vh = sum.bd.vol.by_vol[GOV_SATTR_VOL_HIGH];
   const SGovStratAttribStatsV1 vx = sum.bd.vol.by_vol[GOV_SATTR_VOL_EXTREME];
   int vloss = GovSaturatingAdd32(vh.losses, vx.losses);
   int vtr = GovSaturatingAdd32(vh.trades, vx.trades);
   if(vtr > 0) {
      const int vr = (int)GovFloorDivSigned64((long)vloss * 1000L, (long)vtr);
      out.vol_toxicity = GovClampInt32(vr, 0, 1000);
      if(vr > 620)
         s = GovSaturatingAdd32(s, 90);
   }
   out.score_0_1000 = GovClampInt32(s, 0, 1000);
}

inline bool GovStratToxV1_IsToxic(const SGovStratAttribToxicityV1 &t)
{
   return (t.score_0_1000 >= 700);
}

#endif // __AURUM_GOV_STRAT_TOX_V1_MQH__
