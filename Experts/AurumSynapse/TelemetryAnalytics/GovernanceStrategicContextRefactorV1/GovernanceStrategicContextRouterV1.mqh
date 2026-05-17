//+------------------------------------------------------------------+
//| GovernanceStrategicContextRouterV1.mqh                           |
//| Central routing for context injection (no live pipeline includes).|
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRATEGIC_CTX_ROUTER_V1_MQH__
#define __AURUM_GOV_STRATEGIC_CTX_ROUTER_V1_MQH__

#include "GovernanceStrategicContextV1.mqh"

inline void GovCtxRouterV1_Build(SGovStrategicContextV1 &ctx)
{
   GovStrategicCtxV1_Reset(ctx);
}

inline bool GovCtxRouterV1_Link(SGovStrategicContextV1 &ctx, const SGovResilienceProfileV1 &rp)
{
   ctx.resilience = rp;
   return true;
}

inline bool GovCtxRouterV1_Inject(SGovStrategicContextV1 &ctx, SGovStratAttribTradeV1 &tr[], const int n)
{
   return GovStrategicCtxV1_SetAttribTrades(ctx, tr, n);
}

inline bool GovCtxRouterV1_Resolve(SGovStrategicContextV1 &ctx, string &err)
{
   err = "";
   if(!GovStrategicCtxV1_Validate(ctx)) {
      err = "GOV_CTX_ROUTER_VALIDATE_FAIL";
      return false;
   }
   return true;
}

#endif // __AURUM_GOV_STRATEGIC_CTX_ROUTER_V1_MQH__
