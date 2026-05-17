//+------------------------------------------------------------------+
//| GovernanceStrategicCompileStabilityV1.mqh                        |
//| Compile-time / init-order safety helpers.                        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRATEGIC_COMPILESTAB_V1_MQH__
#define __AURUM_GOV_STRATEGIC_COMPILESTAB_V1_MQH__

#include "GovernanceStrategicContextV1.mqh"

inline bool GovCompileV1_Ensure(const bool cond)
{
   return cond;
}

inline bool GovCompileV1_CheckCtx(const SGovStrategicContextV1 &ctx)
{
   return GovStrategicCtxV1_Validate(ctx);
}

inline void GovCompileV1_SafeInit(SGovStrategicContextV1 &ctx)
{
   GovStrategicCtxV1_Reset(ctx);
}

inline bool GovCompileV1_ValidateContracts(const int api_ver)
{
   return (api_ver == GOV_CTX_API_V1);
}

#endif // __AURUM_GOV_STRATEGIC_COMPILESTAB_V1_MQH__
