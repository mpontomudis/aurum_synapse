//+------------------------------------------------------------------+
//| GovernanceRegimeHeatmapV1.mqh                                   |
//| PHASE 22 — strategy × regime exposure (trade counts)              |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REGIME_HEATMAP_V1_MQH__
#define __AURUM_GOV_REGIME_HEATMAP_V1_MQH__

#include "GovernanceRegimeDatasetV1.mqh"

inline ulong GovRegimeHeatV1_CellIntensity(const SGovRegimeStratCellV1 &c)
{
   return (ulong)MathMax(0, c.trades);
}

#endif // __AURUM_GOV_REGIME_HEATMAP_V1_MQH__
