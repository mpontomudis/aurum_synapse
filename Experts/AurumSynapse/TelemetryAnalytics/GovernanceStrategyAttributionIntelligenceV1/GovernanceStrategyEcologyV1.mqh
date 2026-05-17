//+------------------------------------------------------------------+
//| GovernanceStrategyEcologyV1.mqh                                  |
//| Strategy ecosystem roles (integer codes).                        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRAT_ECO_V1_MQH__
#define __AURUM_GOV_STRAT_ECO_V1_MQH__

#include "GovernanceStrategyToxicityAnalyticsV1.mqh"

#define GOV_SATTR_ECO_UNK_V1      0
#define GOV_SATTR_ECO_ALPHA_V1    1
#define GOV_SATTR_ECO_STAB_V1     2
#define GOV_SATTR_ECO_TOX_V1      3
#define GOV_SATTR_ECO_VOLAMP_V1   4
#define GOV_SATTR_ECO_CONT_V1     5
#define GOV_SATTR_ECO_SPAM_V1     6

inline long GovStratEcoV1_NetCents(const SGovStratAttribStatsV1 &st)
{
   return GovStratAttrV1_SatAdd64(st.gross_win_cents, -st.gross_loss_cents);
}

inline int GovStratEcoV1_Classify(const int strat, const SGovStratAttribSummaryV1 &sum)
{
   const int si = GovClampInt32(strat, 0, GOV_SATTR_STRAT_COUNT_V1 - 1);
   const SGovStratAttribStatsV1 st = sum.bd.by_strat[si];
   SGovStratAttribToxicityV1 tx;
   GovStratToxV1_Score(si, sum, tx);
   if(GovStratToxV1_IsToxic(tx))
      return GOV_SATTR_ECO_TOX_V1;
   if(st.trades >= 40 && st.pf_milli < 900 && st.expectancy_micro < 0)
      return GOV_SATTR_ECO_SPAM_V1;
   const long net = GovStratEcoV1_NetCents(st);
   if(net > 0 && st.pf_milli >= 1100 && st.expectancy_micro > 0)
      return GOV_SATTR_ECO_ALPHA_V1;
   if(st.avg_continuation_x100 > 150 && net >= 0)
      return GOV_SATTR_ECO_CONT_V1;
   if(st.trades > 0) {
      const int hi = GovSaturatingAdd32(sum.bd.vol.by_vol[GOV_SATTR_VOL_HIGH].trades, sum.bd.vol.by_vol[GOV_SATTR_VOL_EXTREME].trades);
      if(hi > GovSaturatingMul32(st.trades, 2) / 3 && st.losses * 2 > st.wins)
         return GOV_SATTR_ECO_VOLAMP_V1;
   }
   if(st.pf_milli >= 950 && net >= 0 && st.trades >= 5)
      return GOV_SATTR_ECO_STAB_V1;
   if(net > 0)
      return GOV_SATTR_ECO_ALPHA_V1;
   return GOV_SATTR_ECO_UNK_V1;
}

inline void GovStratEcoV1_Build(SGovStratAttribSummaryV1 &sum)
{
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++)
      sum.ecology_role[i] = GovStratEcoV1_Classify(i, sum);
}

inline int GovStratEcoV1_PrimaryAlpha(const SGovStratAttribSummaryV1 &sum)
{
   int best = -1;
   long best_net = (-9223372036854775807L - 1L);
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      const long n = GovStratEcoV1_NetCents(sum.bd.by_strat[i]);
      if(sum.bd.by_strat[i].trades <= 0)
         continue;
      if(n > best_net) {
         best_net = n;
         best = i;
      }
   }
   return best;
}

inline int GovStratEcoV1_StabilityEngine(const SGovStratAttribSummaryV1 &sum)
{
   int best = -1;
   int best_pf = -1;
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      const SGovStratAttribStatsV1 st = sum.bd.by_strat[i];
      if(st.trades < 5)
         continue;
      if(st.expectancy_micro < 0)
         continue;
      if(st.pf_milli > best_pf) {
         best_pf = st.pf_milli;
         best = i;
      }
   }
   return best;
}

#endif // __AURUM_GOV_STRAT_ECO_V1_MQH__
