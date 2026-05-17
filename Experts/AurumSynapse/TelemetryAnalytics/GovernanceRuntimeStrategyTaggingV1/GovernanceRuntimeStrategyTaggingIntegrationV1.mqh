//+------------------------------------------------------------------+
//| GovernanceRuntimeStrategyTaggingIntegrationV1.mqh                  |
//| Lightweight runtime hooks — O(n) registry scan, no replay I/O. |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_STRAT_TAG_INT_V1_MQH__
#define __AURUM_GOV_RUNTIME_STRAT_TAG_INT_V1_MQH__

#include "../../Core/Structures.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "GovernanceRuntimeStrategyClassifierV1.mqh"
#include "GovernanceRuntimeTradeTagBuilderV1.mqh"
#include "GovernanceRuntimeAttributionBridgeV1.mqh"
#include "GovernanceRuntimeTaggingExportV1.mqh"
#include "GovernanceRuntimeStrategyTaggingModuleV1.mqh"
#include "GovernanceRuntimeStrategyTaggingSummaryV1.mqh"

SGovRuntimeTaggingModuleV1 g_gov_rtag_module_v1;

//+------------------------------------------------------------------+
inline void GovRunTagIntV1_ModuleInit(void)
{
   GovRunTagRegV1_Init(g_gov_rtag_module_v1.reg);
   GovRunAttrBridgeV1_Init(g_gov_rtag_module_v1.bridge);
   GovRunTagTelV1_Init(g_gov_rtag_module_v1.tel);
   GovLineageLiveV1_ModuleInit();
}

//+------------------------------------------------------------------+
inline bool GovRunTagIntV1_PositionIdFromOrderTicket(const string sym, const ulong order_ticket, ulong &pos_id)
{
   pos_id = 0;
   if(order_ticket == 0)
      return false;
   if(!HistorySelect(0, TimeCurrent()))
      return false;
   const int nd = HistoryDealsTotal();
   for(int i = nd - 1; i >= 0; i--) {
      const ulong d = HistoryDealGetTicket(i);
      if(d == 0)
         continue;
      if(HistoryDealGetString(d, DEAL_SYMBOL) != sym)
         continue;
      if((ulong)HistoryDealGetInteger(d, DEAL_ORDER) != order_ticket)
         continue;
      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(d, DEAL_ENTRY) != DEAL_ENTRY_IN)
         continue;
      pos_id = (ulong)HistoryDealGetInteger(d, DEAL_POSITION_ID);
      if(pos_id != 0)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Deterministic contributor: max(strength×weight), tie → min idx. |
//+------------------------------------------------------------------+
inline int GovRunTagIntV1_SelectPrimaryStrategyIndex(const ENUM_SIGNAL consensus, const SignalResult &sig[])
{
   if(consensus == SIGNAL_NONE)
      return -1;
   int best_i = -1;
   double best_sc = -1.0;
   for(int i = 0; i < 8; i++) {
      if(sig[i].signal != consensus)
         continue;
      double sc = sig[i].strength * sig[i].weight;
      if(!MathIsValidNumber(sc))
         sc = 0.0;
      if(best_i < 0 || sc > best_sc + 1.0e-12 || (MathAbs(sc - best_sc) <= 1.0e-12 && i < best_i)) {
         best_sc = sc;
         best_i = i;
      }
   }
   return best_i;
}

//+------------------------------------------------------------------+
inline void GovRunTagIntV1_BuildIdentityCore(const int strategy_manager_index_0_7,
                                             const ENUM_REGIME mreg,
                                             const ENUM_SESSION msess,
                                             const double atr_ratio,
                                             const ulong order_ticket,
                                             const datetime open_ts,
                                             const double quality_score_0_100,
                                             SGovRuntimeTradeIdentityV1 &out)
{
   GovRunTagDsV1_InitIdentity(out);
   const int sid = GovClampInt32(strategy_manager_index_0_7, 0, 7);
   out.strategy_id = GovRunTagV1_ClassifyStrategy(sid);
   out.regime_id = GovRunTagV1_ClassifyRegime(mreg);
   out.session_id = GovRunTagV1_ClassifySession(msess);
   out.volatility_id = GovRunTagV1_ClassifyVolatility(atr_ratio);
   out.execution_type_id = GovRunTagV1_ClassifyExecution(false);
   const uint ulow = (uint)order_ticket;
   out.ticket_low32 = (int)ulow;
   out.open_time = (long)open_ts;
   const int qbp = (int)MathRound(quality_score_0_100 * 100.0);
   out.quality_score_bp = GovClampInt32(qbp, 0, 1000000);
   GovRunTagV1_Build(out.strategy_id, out.regime_id, out.volatility_id, out.session_id, out.tag);
}

//+------------------------------------------------------------------+
inline bool GovRunTagIntV1_Register(const ulong position_id, const SGovRuntimeTradeIdentityV1 &id)
{
   string err = "";
   return GovRunAttrV1_Register(g_gov_rtag_module_v1.reg, g_gov_rtag_module_v1.tel, position_id, id, err);
}

//+------------------------------------------------------------------+
inline bool GovRunTagIntV1_OnTradeOpen(const string sym,
                                      const ulong order_ticket,
                                      const ENUM_SIGNAL consensus,
                                      const SignalResult &sig[],
                                      const ENUM_REGIME mreg,
                                      const ENUM_SESSION msess,
                                      const double atr_ratio,
                                      const double quality_score_0_100)
{
   int prim = GovRunTagIntV1_SelectPrimaryStrategyIndex(consensus, sig);
   const bool unk = (prim < 0);
   if(unk) {
      prim = (int)STRATEGY_MOMENTUM_SCALP;
      g_gov_rtag_module_v1.tel.unknown_strategy = GovSaturatingAdd32(g_gov_rtag_module_v1.tel.unknown_strategy, 1);
   }
   ulong pos_id = 0;
   if(!GovRunTagIntV1_PositionIdFromOrderTicket(sym, order_ticket, pos_id)) {
      g_gov_rtag_module_v1.tel.tag_injection_fail = GovSaturatingAdd32(g_gov_rtag_module_v1.tel.tag_injection_fail, 1);
      return false;
   }
   SGovRuntimeTradeIdentityV1 id;
   GovRunTagIntV1_BuildIdentityCore(prim, mreg, msess, atr_ratio, order_ticket, TimeCurrent(), quality_score_0_100, id);
   string err = "";
   const bool ok = GovRunAttrV1_Register(g_gov_rtag_module_v1.reg, g_gov_rtag_module_v1.tel, pos_id, id, err);
   if(ok)
      GovLineageLiveV1_OnOpenFromOrder(sym, order_ticket, pos_id, prim, TimeCurrent());
   return ok;
}

//+------------------------------------------------------------------+
inline void GovRunTagIntV1_OnTradeClose(const string sym,
                                        const long magic_filter,
                                        const ulong deal_ticket)
{
   if(!HistoryDealSelect(deal_ticket))
      return;
   if(HistoryDealGetString(deal_ticket, DEAL_SYMBOL) != sym)
      return;
   if(HistoryDealGetInteger(deal_ticket, DEAL_MAGIC) != magic_filter)
      return;
   if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT)
      return;
   const ulong pos = (ulong)HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID);
   const double profit = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT)
                         + HistoryDealGetDouble(deal_ticket, DEAL_SWAP)
                         + HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION);
   const long profit_cents = (long)MathRound(profit * 100.0);
   const ENUM_DEAL_REASON rs = (ENUM_DEAL_REASON)HistoryDealGetInteger(deal_ticket, DEAL_REASON);
   const int stopout = (rs == DEAL_REASON_SL) ? 1 : 0;
   const datetime dts = (datetime)HistoryDealGetInteger(deal_ticket, DEAL_TIME);
   GovLineageLiveV1_OnDealOutProfit(pos, profit_cents, stopout, dts);
   string err = "";
   GovRunAttrV1_Commit(g_gov_rtag_module_v1.reg, g_gov_rtag_module_v1.bridge, g_gov_rtag_module_v1.tel, pos, profit_cents, 0, stopout, 0, err);
}

//+------------------------------------------------------------------+
inline void GovRunTagIntV1_BuildSummary(SGovStratAttribSummaryV1 &sum)
{
   GovRunTagIntV1_BuildSummaryFromBridge(g_gov_rtag_module_v1.bridge, sum);
}

//+------------------------------------------------------------------+
inline bool GovRunTagIntV1_ExportRuntime(string &dst)
{
   return GovRunAttrV1_Export(g_gov_rtag_module_v1.bridge, dst);
}

//+------------------------------------------------------------------+
//| Optional MT5-safe comment suffix (truncate total ≤ 31).          |
//+------------------------------------------------------------------+
inline string GovRunTagIntV1_FormatOrderComment(const string base_comment,
                                               const string tag,
                                               const bool append_tag)
{
   if(!append_tag || StringLen(tag) <= 0)
      return base_comment;
   const string sep = "|";
   const string merged = base_comment + sep + tag;
   const int mx = 31;
   if(StringLen(merged) <= mx)
      return merged;
   return StringSubstr(merged, 0, mx);
}

#endif // __AURUM_GOV_RUNTIME_STRAT_TAG_INT_V1_MQH__
