//+------------------------------------------------------------------+
//| GovernanceRegimeSuppressionV1.mqh                                |
//| PHASE 22 — starvation / diversity collapse diagnostics            |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REGIME_SUPPRESSION_V1_MQH__
#define __AURUM_GOV_REGIME_SUPPRESSION_V1_MQH__

#include "GovernanceRegimeDatasetV1.mqh"

inline void GovRegimeSupV1_Evaluate(SGovRegimeRuntimeStoreV1 &s)
{
   if(s.total_bars < 200) {
      s.diversity_collapse = false;
      return;
   }
   ulong mx = 0;
   for(int r = 0; r < GOV_REGIME_AURUM_SLOT_COUNT_V1; r++) {
      if(s.regime_hist[r] > mx)
         mx = s.regime_hist[r];
   }
   const double dom = (double)mx / (double)MathMax(1UL, s.total_bars);
   if(dom >= 0.90 || s.frozen_streak_max > 5000) {
      s.diversity_collapse = true;
      s.diversity_collapse_hits++;
   } else {
      s.diversity_collapse = false;
   }
}

#endif // __AURUM_GOV_REGIME_SUPPRESSION_V1_MQH__
