//+------------------------------------------------------------------+
//| GovernanceEcologyExportV1.mqh                                   |
//| PHASE 23 — comparative / baseline snapshot hooks                 |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECOLOGY_EXPORT_V1_MQH__
#define __AURUM_GOV_ECOLOGY_EXPORT_V1_MQH__

#include "GovernanceEcologyDatasetV1.mqh"
#include "../GovernanceComparativeInsightsV1/GovernanceComparisonDatasetV1.mqh"

inline void GovEcoExpV1_FillCmpRecord(SGovCmpRunRecordV1 &r)
{
   r.eco_diversity_pm = g_gov_ecology_v1.ecology_diversity_score_pm;
   r.eco_entropy_pm = g_gov_ecology_v1.ecology_entropy_score_pm;
   r.eco_balance_pm = g_gov_ecology_v1.ecology_balance_score_pm;
   int dom = 0;
   ulong best = 0;
   for(int i = 0; i < GOV_ECO_STRAT_COUNT_V1; i++) {
      if(g_gov_ecology_v1.s[i].dominance_pick_bars > best) {
         best = g_gov_ecology_v1.s[i].dominance_pick_bars;
         dom = i;
      }
   }
   r.eco_dom_slot = dom;
   ulong tot = 0;
   for(int j = 0; j < GOV_ECO_STRAT_COUNT_V1; j++)
      tot += g_gov_ecology_v1.s[j].dominance_pick_bars;
   r.eco_dom_frac_x1000 = (tot > 0UL) ? (int)MathMin(1000UL, (1000UL * best) / tot) : 0;
}

#endif // __AURUM_GOV_ECOLOGY_EXPORT_V1_MQH__
