//+------------------------------------------------------------------+
//| GovernanceRuntimeVisualLineageGraphV1.mqh                         |
//| HTML tree + lifecycle classification (deterministic)               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_VISUAL_LIN_V1_MQH__
#define __AURUM_GOV_RUNTIME_VISUAL_LIN_V1_MQH__

#include "../GovernancePositionLineageIntelligenceV1/GovernancePositionLineageDatasetV1.mqh"
#include "../GovernancePositionLineageIntelligenceV1/GovernancePositionLineageRegistryV1.mqh"
#include "../GovernancePositionLineageIntelligenceV1/GovernancePositionLineageHtmlExportV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionExportV1.mqh"
#include "GovernanceRuntimeVisualHtmlWriterV1.mqh"

inline string GovRuntimeVisualLinV1_Classify(const SGovLineageNodeV1 &n)
{
   return GovLineageHtmlW1_LifecycleClass(n);
}

inline void GovRuntimeVisualLinV1_Build(const SGovLineageRegistryStoreV1 &reg, string &html)
{
   GovLineageHtmlV1_AppendForest(reg, html);
}

#endif // __AURUM_GOV_RUNTIME_VISUAL_LIN_V1_MQH__
