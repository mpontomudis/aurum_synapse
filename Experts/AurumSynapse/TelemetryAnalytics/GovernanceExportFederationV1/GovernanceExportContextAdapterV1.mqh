//+------------------------------------------------------------------+
//| GovernanceExportContextAdapterV1.mqh                            |
//| Map subsystem snapshots into SGovStrategicContextV1 export slots. |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EXPORT_CTXADAPT_V1_MQH__
#define __AURUM_GOV_EXPORT_CTXADAPT_V1_MQH__

#include "../GovernanceStrategicContextRefactorV1/GovernanceStrategicContextV1.mqh"
#include "../GovernanceStrategicIntelligenceV1/GovernanceStrategicDatasetV1.mqh"

inline void GovExportCtxV1_FromStrategic(SGovStrategicContextV1 &ctx, const SGovStrategicSummaryV1 &s)
{
   ctx.evolution.lineage_id = s.lineage_id;
}

inline void GovExportCtxV1_FromAttrib(SGovStrategicContextV1 &ctx, const SGovStratAttribSummaryV1 &sum)
{
   ctx.attribution = sum;
}

inline void GovExportCtxV1_FromToxicity(SGovStrategicContextV1 &ctx, const SGovStratAttribToxicityV1 &t)
{
   ctx.toxicity = t;
}

inline void GovExportCtxV1_FromEcology(SGovStrategicContextV1 &ctx, const SGovStratAttribComparisonV1 &c)
{
   ctx.ecology = c;
}

inline void GovExportCtxV1_FromCompatibility(SGovStrategicContextV1 &ctx, const SGovStratAttribBreakdownV1 &b)
{
   ctx.compatibility = b;
}

#endif // __AURUM_GOV_EXPORT_CTXADAPT_V1_MQH__
