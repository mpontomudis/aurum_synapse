//+------------------------------------------------------------------+
//| GovernanceStrategyAttributionDatasetV1.mqh                       |
//| GOVERNANCE_STRATEGY_ATTRIBUTION_INTELLIGENCE_V1 — dataset POD    |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRAT_ATTR_DS_V1_MQH__
#define __AURUM_GOV_STRAT_ATTR_DS_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

#define GOV_SATTR_STRAT_COUNT_V1   8
#define GOV_SATTR_REGIME_COUNT_V1  6
#define GOV_SATTR_SESSION_COUNT_V1 4
#define GOV_SATTR_VOL_COUNT_V1     4

// Strategy axis (aligns with StrategyManager order in EA harness docs)
enum ENUM_GOV_STRAT_CODE_V1
{
   GOV_STRAT_TF = 0,
   GOV_STRAT_BO = 1,
   GOV_STRAT_MR = 2,
   GOV_STRAT_SD = 3,
   GOV_STRAT_SM = 4,
   GOV_STRAT_PA = 5,
   GOV_STRAT_GR = 6,
   GOV_STRAT_MS = 7
};

enum ENUM_GOV_STRAT_REGIME_V1
{
   GOV_REGIME_TREND = 0,
   GOV_REGIME_CHOP = 1,
   GOV_REGIME_EXPANSION = 2,
   GOV_REGIME_COMPRESSION = 3,
   GOV_REGIME_SWEEP = 4,
   GOV_REGIME_TOXIC = 5
};

enum ENUM_GOV_STRAT_SESSION_V1
{
   GOV_SATTR_SESS_ASIA = 0,
   GOV_SATTR_SESS_LONDON = 1,
   GOV_SATTR_SESS_NY = 2,
   GOV_SATTR_SESS_OVERLAP = 3
};

enum ENUM_GOV_STRAT_VOL_V1
{
   GOV_SATTR_VOL_LOW = 0,
   GOV_SATTR_VOL_MED = 1,
   GOV_SATTR_VOL_HIGH = 2,
   GOV_SATTR_VOL_EXTREME = 3
};

struct SGovStratAttribTradeV1
{
   int strat;
   int regime;
   int session;
   int vol;
   long profit_cents;
   int hold_bars;
   int stopout;
   int tail_loss;
};

struct SGovStratAttribStatsV1
{
   int trades;
   int wins;
   int losses;
   long gross_win_cents;
   long gross_loss_cents;
   int pf_milli;
   int expectancy_micro;
   int avg_hold_bars_x100;
   int avg_continuation_x100;
   int max_dd_contrib_cents;
   int stopout_count;
   int tail_loss_count;
};

struct SGovStratAttribRegimeStatsV1
{
   SGovStratAttribStatsV1 by_reg[GOV_SATTR_REGIME_COUNT_V1];
};

struct SGovStratAttribSessionStatsV1
{
   SGovStratAttribStatsV1 by_sess[GOV_SATTR_SESSION_COUNT_V1];
};

struct SGovStratAttribVolatilityStatsV1
{
   SGovStratAttribStatsV1 by_vol[GOV_SATTR_VOL_COUNT_V1];
};

struct SGovStratAttribExecutionStatsV1
{
   int quality_score_x1000;
   int slip_proxy_ticks;
   int reentry_count;
};

struct SGovStratAttribBreakdownV1
{
   SGovStratAttribStatsV1 by_strat[GOV_SATTR_STRAT_COUNT_V1];
   SGovStratAttribRegimeStatsV1 regime;
   SGovStratAttribSessionStatsV1 session;
   SGovStratAttribVolatilityStatsV1 vol;
   SGovStratAttribExecutionStatsV1 exec;
};

struct SGovStratAttribComparisonV1
{
   int d_trades[GOV_SATTR_STRAT_COUNT_V1];
   int d_pf_milli[GOV_SATTR_STRAT_COUNT_V1];
   long d_profit_cents[GOV_SATTR_STRAT_COUNT_V1];
};

struct SGovStratAttribToxicityV1
{
   int score_0_1000;
   int catastrophic_cluster;
   int pf_collapse;
   int vol_toxicity;
   int regime_mismatch;
   int stopout_rate_x1000;
   int loss_persist;
};

struct SGovStratAttribSummaryV1
{
   SGovStratAttribBreakdownV1 bd;
   SGovStratAttribToxicityV1 tox[GOV_SATTR_STRAT_COUNT_V1];
   int ecology_role[GOV_SATTR_STRAT_COUNT_V1];
   int compat_regime[GOV_SATTR_STRAT_COUNT_V1][GOV_SATTR_REGIME_COUNT_V1];
   int compat_vol[GOV_SATTR_STRAT_COUNT_V1][GOV_SATTR_VOL_COUNT_V1];
   int trade_count_input;
   long cross_strat_regime_cents[GOV_SATTR_STRAT_COUNT_V1][GOV_SATTR_REGIME_COUNT_V1];
   long cross_strat_vol_cents[GOV_SATTR_STRAT_COUNT_V1][GOV_SATTR_VOL_COUNT_V1];
};

inline void GovStrAttrDsV1_InitStats(SGovStratAttribStatsV1 &s)
{
   s.trades = 0;
   s.wins = 0;
   s.losses = 0;
   s.gross_win_cents = 0;
   s.gross_loss_cents = 0;
   s.pf_milli = 0;
   s.expectancy_micro = 0;
   s.avg_hold_bars_x100 = 0;
   s.avg_continuation_x100 = 0;
   s.max_dd_contrib_cents = 0;
   s.stopout_count = 0;
   s.tail_loss_count = 0;
}

inline void GovStrAttrDsV1_InitTrade(SGovStratAttribTradeV1 &t)
{
   t.strat = 0;
   t.regime = 0;
   t.session = 0;
   t.vol = 0;
   t.profit_cents = 0;
   t.hold_bars = 0;
   t.stopout = 0;
   t.tail_loss = 0;
}

inline void GovStrAttrDsV1_InitBreakdown(SGovStratAttribBreakdownV1 &b)
{
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++)
      GovStrAttrDsV1_InitStats(b.by_strat[i]);
   for(int r = 0; r < GOV_SATTR_REGIME_COUNT_V1; r++)
      GovStrAttrDsV1_InitStats(b.regime.by_reg[r]);
   for(int s = 0; s < GOV_SATTR_SESSION_COUNT_V1; s++)
      GovStrAttrDsV1_InitStats(b.session.by_sess[s]);
   for(int v = 0; v < GOV_SATTR_VOL_COUNT_V1; v++)
      GovStrAttrDsV1_InitStats(b.vol.by_vol[v]);
   b.exec.quality_score_x1000 = 0;
   b.exec.slip_proxy_ticks = 0;
   b.exec.reentry_count = 0;
}

inline void GovStrAttrDsV1_InitToxicity(SGovStratAttribToxicityV1 &t)
{
   t.score_0_1000 = 0;
   t.catastrophic_cluster = 0;
   t.pf_collapse = 0;
   t.vol_toxicity = 0;
   t.regime_mismatch = 0;
   t.stopout_rate_x1000 = 0;
   t.loss_persist = 0;
}

inline void GovStrAttrDsV1_InitSummary(SGovStratAttribSummaryV1 &sum)
{
   GovStrAttrDsV1_InitBreakdown(sum.bd);
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      GovStrAttrDsV1_InitToxicity(sum.tox[i]);
      sum.ecology_role[i] = 0;
      for(int r = 0; r < GOV_SATTR_REGIME_COUNT_V1; r++)
         sum.compat_regime[i][r] = 0;
      for(int v = 0; v < GOV_SATTR_VOL_COUNT_V1; v++)
         sum.compat_vol[i][v] = 0;
   }
   sum.trade_count_input = 0;
   for(int a = 0; a < GOV_SATTR_STRAT_COUNT_V1; a++) {
      for(int b = 0; b < GOV_SATTR_REGIME_COUNT_V1; b++)
         sum.cross_strat_regime_cents[a][b] = 0;
      for(int c = 0; c < GOV_SATTR_VOL_COUNT_V1; c++)
         sum.cross_strat_vol_cents[a][c] = 0;
   }
}

#endif // __AURUM_GOV_STRAT_ATTR_DS_V1_MQH__
