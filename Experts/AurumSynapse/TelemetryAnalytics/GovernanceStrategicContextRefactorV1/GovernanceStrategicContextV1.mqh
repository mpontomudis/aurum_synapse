//+------------------------------------------------------------------+
//| GovernanceStrategicContextV1.mqh                                |
//| Federated governance context POD (deterministic, replay-safe).  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRATEGIC_CTX_V1_MQH__
#define __AURUM_GOV_STRATEGIC_CTX_V1_MQH__

#include "GovernanceStrategicContextContractsV1.mqh"
#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceDatasetV1.mqh"
#include "../GovernanceEvolutionIntelligenceV1/GovernanceEvolutionDatasetV1.mqh"
#include "../GovernanceStrategicIntelligenceV1/GovernanceStrategicDatasetV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionDatasetV1.mqh"

struct SGovStrategicContextV1
{
   int api_magic;
   int api_version;
   int sattr_trade_n;
   SGovStratAttribTradeV1 sattr_trade[GOV_CTX_SATTR_TRADE_CAP_V1];

   SGovResilienceProfileV1 resilience;
   SGovEvolutionSummaryV1 evolution;
   SGovStrategicEnduranceV1 endurance;
   SGovStrategicBudgetV1 budget;
   SGovStrategicContainmentV1 containment;
   SGovStratAttribSummaryV1 attribution;
   SGovStratAttribComparisonV1 ecology;
   SGovStratAttribToxicityV1 toxicity;
   SGovStratAttribBreakdownV1 compatibility;
};

inline void GovStrategicCtxV1_InitEcologyCmp(SGovStratAttribComparisonV1 &c)
{
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      c.d_trades[i] = 0;
      c.d_pf_milli[i] = 0;
      c.d_profit_cents[i] = 0;
   }
}

inline void GovStrategicCtxV1_Reset(SGovStrategicContextV1 &ctx)
{
   ctx.api_magic = GOV_CTX_API_MAGIC_V1;
   ctx.api_version = GOV_CTX_API_V1;
   ctx.sattr_trade_n = 0;
   for(int i = 0; i < GOV_CTX_SATTR_TRADE_CAP_V1; i++)
      GovStrAttrDsV1_InitTrade(ctx.sattr_trade[i]);
   GovResilDsV1_InitProfile(ctx.resilience);
   GovEvoDsV1_InitSummary(ctx.evolution);
   GovStratDsV1_InitEnd(ctx.endurance);
   GovStratDsV1_InitBud(ctx.budget);
   GovStratDsV1_InitCtn(ctx.containment);
   GovStrAttrDsV1_InitSummary(ctx.attribution);
   GovStrategicCtxV1_InitEcologyCmp(ctx.ecology);
   GovStrAttrDsV1_InitToxicity(ctx.toxicity);
   GovStrAttrDsV1_InitBreakdown(ctx.compatibility);
}

inline void GovStrategicCtxV1_Clone(const SGovStrategicContextV1 &src, SGovStrategicContextV1 &dst)
{
   dst = src;
}

inline bool GovStrategicCtxV1_Validate(const SGovStrategicContextV1 &ctx)
{
   if(ctx.api_magic != GOV_CTX_API_MAGIC_V1)
      return false;
   if(ctx.api_version != GOV_CTX_API_V1)
      return false;
   if(ctx.sattr_trade_n < 0 || ctx.sattr_trade_n > GOV_CTX_SATTR_TRADE_CAP_V1)
      return false;
   if(ctx.resilience.summary.replay_epoch_count < 0)
      return false;
   return true;
}

inline bool GovStrategicCtxV1_SetAttribTrades(SGovStrategicContextV1 &ctx, SGovStratAttribTradeV1 &src[], const int n)
{
   if(n < 0 || n > GOV_CTX_SATTR_TRADE_CAP_V1)
      return false;
   ctx.sattr_trade_n = n;
   for(int i = 0; i < n; i++)
      ctx.sattr_trade[i] = src[i];
   return true;
}

#endif // __AURUM_GOV_STRATEGIC_CTX_V1_MQH__
