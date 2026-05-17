//+------------------------------------------------------------------+
//| GovernanceStrategyAttributionLiveIntegrationV1.mqh             |
//| Strategy ATTRIBUTION offline pipeline (ctx + overloads).        |
//| NOTE: distinct include guard from strategic live integration.     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRAT_ATTR_LIVEINT_V1_MQH__
#define __AURUM_GOV_STRAT_ATTR_LIVEINT_V1_MQH__

#include "../GovernanceStrategicContextRefactorV1/GovernanceStrategicContextV1.mqh"
#include "GovernanceStrategyEcologyV1.mqh"
#include "GovernanceStrategyCompatibilityMatrixV1.mqh"
#include "GovernanceStrategyAttributionExportV1.mqh"
#include "GovernanceStrategyAttributionComparatorV1.mqh"
#include "GovernanceStrategyAttributionSandboxV1.mqh"

inline bool GovStratAggV1_BuildSummary(const SGovStrategicContextV1 &ctx, const SGovStratAttribTradeV1 &trades[], SGovStratAttribSummaryV1 &sum)
{
   if(!GovStrategicCtxV1_Validate(ctx))
      return false;
   GovStrAttrDsV1_InitSummary(sum);
   const int dynN = ArraySize(trades);
   int useN = dynN;
   if(dynN <= 0)
      useN = ctx.sattr_trade_n;
   if(useN < 0)
      return false;
   for(int i = 0; i < useN; i++) {
      if(dynN > 0)
         GovStratAttrV1_AccTrade(sum, trades[i]);
      else
         GovStratAttrV1_AccTrade(sum, ctx.sattr_trade[i]);
   }
   GovStratAttrV1_Finalize(sum);
   GovStratCmpMxV1_Build(sum);
   GovStratEcoV1_Build(sum);
   for(int k = 0; k < GOV_SATTR_STRAT_COUNT_V1; k++)
      GovStratToxV1_Score(k, sum, sum.tox[k]);
   return true;
}

inline bool GovStratAggV1_BuildSummary(SGovStratAttribTradeV1 &trades[], const int n_tr, SGovStratAttribSummaryV1 &out, string &err)
{
   err = "";
   SGovStrategicContextV1 ctx;
   GovStrategicCtxV1_Reset(ctx);
   if(!GovStrategicCtxV1_SetAttribTrades(ctx, trades, n_tr)) {
      err = "GOV_CTX_SATTR_TRADE_OVERFLOW";
      return false;
   }
   SGovStratAttribTradeV1 z[];
   ArrayResize(z, 0);
   return GovStratAggV1_BuildSummary(ctx, z, out);
}

inline bool GovStratLiveV1_Run(const SGovStrategicContextV1 &ctx, const string &replay, SGovStratAttribSummaryV1 &sum)
{
   GovStrAttrDsV1_InitSummary(sum);
   if(!GovStrategicCtxV1_Validate(ctx))
      return false;
   if(StringLen(replay) > 0)
      return false;
   SGovStratAttribTradeV1 z[];
   ArrayResize(z, 0);
   return GovStratAggV1_BuildSummary(ctx, z, sum);
}

inline bool GovStratLiveV1_Run(const string &replay_text, SGovStratAttribTradeV1 &trades[], const int n_tr, SGovStratAttribSummaryV1 &out_sum, string &out_bundle, string &err)
{
   err = "";
   out_bundle = "";
   GovStrAttrDsV1_InitSummary(out_sum);
   if(StringLen(replay_text) > 0) {
      err = "GOV_STRAT_LIVE_REPLAY_PARSE_V1_NOT_IMPL";
      return false;
   }
   SGovStratAttribTradeV1 sbx[];
   int n2 = 0;
   if(!GovStratSbxV1_CloneTrades(trades, n_tr, sbx, n2)) {
      err = "GOV_STRAT_LIVE_SBX_CLONE_FAIL";
      return false;
   }
   SGovStrategicContextV1 ctx;
   GovStrategicCtxV1_Reset(ctx);
   if(!GovStrategicCtxV1_SetAttribTrades(ctx, sbx, n2)) {
      err = "GOV_CTX_SATTR_TRADE_OVERFLOW";
      return false;
   }
   if(!GovStratLiveV1_Run(ctx, replay_text, out_sum)) {
      err = "GOV_STRAT_ATTR_LIVE_RUN_FAIL";
      return false;
   }
   if(!GovStratExpV1_Bundle(out_sum, out_bundle)) {
      err = "GOV_STRAT_ATTR_EXP_BUNDLE_FAIL";
      return false;
   }
   return true;
}

#endif // __AURUM_GOV_STRAT_ATTR_LIVEINT_V1_MQH__
