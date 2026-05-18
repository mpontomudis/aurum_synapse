//+------------------------------------------------------------------+
//| RiskLockIntelligenceIntegrationV1.mqh                          |
//| PHASE 23.6 — EA-facing surface                                   |
//+------------------------------------------------------------------+
#ifndef __AURUM_RLI_INT_V1_MQH__
#define __AURUM_RLI_INT_V1_MQH__

#include "../../Core/Structures.mqh"
#include "RiskLockIntelligenceHtmlV1.mqh"

inline void GovRliIntV1_ModuleInit(void)
{
   GovRliDsV1_Init(g_gov_rli_v1);
}

inline void GovRliIntV1_Configure(const bool en)
{
   g_gov_rli_v1.enabled = en;
   if(!en)
      GovRliDsV1_Init(g_gov_rli_v1);
}

inline void GovRliIntV1_OnBarPostCanTrade(const datetime ts,
                                       const ulong bar_idx,
                                       const bool can_trade,
                                       const int deny_detail,
                                       const int halt_reason_enum,
                                       const int consec_losses,
                                       const double eq_dd,
                                       const double balance,
                                       const double equity,
                                       const double spread_pts,
                                       const double atr_ratio,
                                       const int regime_slot,
                                       const int max_spread_pts,
                                       const bool grid_on,
                                       const bool in_tester)
{
   GovRliEngV1_OnBarPostCanTrade(g_gov_rli_v1, ts, bar_idx, can_trade, deny_detail, halt_reason_enum, eq_dd, balance, equity,
                              spread_pts, atr_ratio, regime_slot, g_gov_rli_v1.ecology_suppress_prev_bar,
                              consec_losses, max_spread_pts, grid_on, in_tester);
}

inline void GovRliIntV1_OnExecutionOpened(const ulong bar_idx)
{
   GovRliEngV1_OnExecutionOpened(g_gov_rli_v1, bar_idx);
}

inline void GovRliIntV1_OnBarEnd(const int eco_suppress_this_bar)
{
   GovRliEngV1_OnBarEndStoreEco(g_gov_rli_v1, eco_suppress_this_bar);
}

inline void GovRliIntV1_FlushPersistence(void)
{
   GovRliPersistV1_WriteAll(g_gov_rli_v1);
}

inline void GovRliIntV1_AppendDossierSection25(string &html)
{
   GovRliHtmlV1_AppendSection25(html, g_gov_rli_v1);
}

#endif // __AURUM_RLI_INT_V1_MQH__
