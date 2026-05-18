//+------------------------------------------------------------------+
//| GovernanceRegimeExportV1.mqh                                    |
//| PHASE 22 — CSV sidecar block for dossier / reports               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REGIME_EXPORT_V1_MQH__
#define __AURUM_GOV_REGIME_EXPORT_V1_MQH__

#include "GovernanceRegimeDatasetV1.mqh"

inline void GovRegimeExpV1_AppendCsvSummary(const SGovRegimeRuntimeStoreV1 &s, string &dst)
{
   dst += "regime_abi=" + IntegerToString((int)GOV_REGIME_ABI_VER_V1) + "\n";
   dst += "total_bars," + IntegerToString((long)s.total_bars) + "\n";
   dst += "transitions," + IntegerToString((long)s.transitions_total) + "\n";
   for(int r = 0; r < GOV_REGIME_AURUM_SLOT_COUNT_V1; r++)
      dst += "reg_hist_" + IntegerToString(r) + "," + IntegerToString((long)s.regime_hist[r]) + "\n";
}

#endif // __AURUM_GOV_REGIME_EXPORT_V1_MQH__
