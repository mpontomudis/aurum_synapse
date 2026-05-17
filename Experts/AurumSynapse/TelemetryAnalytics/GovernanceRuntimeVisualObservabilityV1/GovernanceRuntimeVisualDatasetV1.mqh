//+------------------------------------------------------------------+
//| GovernanceRuntimeVisualDatasetV1.mqh                            |
//| Executive summary + last export path (cold path)                 |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_VISUAL_DS_V1_MQH__
#define __AURUM_GOV_RUNTIME_VISUAL_DS_V1_MQH__

#include "GovernanceRuntimeVisualContractsV1.mqh"

struct SGovVisualExecSummaryV1
{
   double net_profit;
   double gross_profit;
   double gross_loss;
   double profit_factor;
   double recovery_factor;
   double balance_dd_rel_pct;
   double equity_dd_rel_pct;
   int    total_trades;
   int    profit_trades;
   int    loss_trades;
   int    long_trades;
   int    short_trades;
   int    valid;
};

string g_gov_runtime_visual_last_html_path_v1 = "";

inline void GovRuntimeVisualDsV1_InitExec(SGovVisualExecSummaryV1 &e)
{
   e.net_profit = 0;
   e.gross_profit = 0;
   e.gross_loss = 0;
   e.profit_factor = 0;
   e.recovery_factor = 0;
   e.balance_dd_rel_pct = 0;
   e.equity_dd_rel_pct = 0;
   e.total_trades = 0;
   e.profit_trades = 0;
   e.loss_trades = 0;
   e.long_trades = 0;
   e.short_trades = 0;
   e.valid = 0;
}

inline void GovRuntimeVisualDsV1_FromTester(SGovVisualExecSummaryV1 &e)
{
   GovRuntimeVisualDsV1_InitExec(e);
   if(MQLInfoInteger(MQL_TESTER) == 0)
      return;
   e.net_profit = TesterStatistics(STAT_PROFIT);
   e.gross_profit = TesterStatistics(STAT_GROSS_PROFIT);
   e.gross_loss = TesterStatistics(STAT_GROSS_LOSS);
   e.profit_factor = TesterStatistics(STAT_PROFIT_FACTOR);
   e.recovery_factor = TesterStatistics(STAT_RECOVERY_FACTOR);
   e.balance_dd_rel_pct = TesterStatistics(STAT_BALANCE_DDREL_PERCENT);
   e.equity_dd_rel_pct = TesterStatistics(STAT_EQUITY_DDREL_PERCENT);
   e.total_trades = (int)TesterStatistics(STAT_TRADES);
   e.profit_trades = (int)TesterStatistics(STAT_PROFIT_TRADES);
   e.loss_trades = (int)TesterStatistics(STAT_LOSS_TRADES);
   e.long_trades = (int)TesterStatistics(STAT_LONG_TRADES);
   e.short_trades = (int)TesterStatistics(STAT_SHORT_TRADES);
   e.valid = 1;
}

#endif // __AURUM_GOV_RUNTIME_VISUAL_DS_V1_MQH__
