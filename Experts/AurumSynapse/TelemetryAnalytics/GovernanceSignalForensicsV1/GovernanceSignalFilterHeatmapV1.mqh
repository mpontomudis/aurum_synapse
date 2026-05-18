//+------------------------------------------------------------------+
//| GovernanceSignalFilterHeatmapV1.mqh                             |
//| PHASE 21 — suppression matrix accessors (fixed grid)              |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SIG_FILTER_HEATMAP_V1_MQH__
#define __AURUM_GOV_SIG_FILTER_HEATMAP_V1_MQH__

#include "GovernanceSignalForensicsTelemetryV1.mqh"

inline ulong GovSigHeatmapV1_CellStratRej(const SGovSignalForensicsTelemetryV1 &t, const int strat, const int rej)
{
   const int s0 = GovClampInt32(strat, 0, GOV_SIG_FORENSICS_STRATEGY_SLOTS_V1 - 1);
   const int r0 = GovClampInt32(rej, 0, GOV_SIG_REJECT_REASON_COUNT_V1 - 1);
   return t.heat_strat_rej[s0][r0];
}

inline ulong GovSigHeatmapV1_CellRegRej(const SGovSignalForensicsTelemetryV1 &t, const int reg, const int rej)
{
   const int rg = GovClampInt32(reg, 0, GOV_SIG_FORENSICS_REGIME_SLOTS_V1 - 1);
   const int r0 = GovClampInt32(rej, 0, GOV_SIG_REJECT_REASON_COUNT_V1 - 1);
   return t.heat_reg_rej[rg][r0];
}

inline ulong GovSigHeatmapV1_CellMonthRej(const SGovSignalForensicsTelemetryV1 &t, const int month0_11, const int rej)
{
   const int m0 = GovClampInt32(month0_11, 0, GOV_SIG_FORENSICS_MONTH_BUCKETS_V1 - 1);
   const int r0 = GovClampInt32(rej, 0, GOV_SIG_REJECT_REASON_COUNT_V1 - 1);
   return t.heat_month_rej[m0][r0];
}

#endif // __AURUM_GOV_SIG_FILTER_HEATMAP_V1_MQH__
