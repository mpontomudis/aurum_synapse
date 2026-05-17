//+------------------------------------------------------------------+
//| GovernanceComparisonScoringV1.mqh                              |
//| PHASE 20C — coarse stability score 0..1000                       |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CMP_SCORE_V1_MQH__
#define __AURUM_GOV_CMP_SCORE_V1_MQH__

#include "GovernanceComparisonDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

inline int GovCmpScoreV1_StabilityPoints(const SGovCmpRunRecordV1 &r)
{
   if(r.valid == 0)
      return 0;
   int s = 500;
   s += (int)MathRound(120.0 * MathMin(r.pf, 2.5));
   s -= (int)MathRound(4.0 * r.dd_bal_pct);
   s -= (int)MathRound(0.15 * (double)r.max_tox);
   s -= GovClampInt32(r.recovery_cascades * 15, 0, 400);
   return GovClampInt32(s, 0, 1000);
}

#endif // __AURUM_GOV_CMP_SCORE_V1_MQH__
