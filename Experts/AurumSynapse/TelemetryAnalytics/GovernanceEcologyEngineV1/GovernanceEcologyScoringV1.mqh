//+------------------------------------------------------------------+
//| GovernanceEcologyScoringV1.mqh                                  |
//| PHASE 23 — ecology health / diversity / entropy                  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECOLOGY_SCORING_V1_MQH__
#define __AURUM_GOV_ECOLOGY_SCORING_V1_MQH__

#include "GovernanceEcologyDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

inline void GovEcoScoreV1_UpdateStratScores(SGovEcologyStratSliceV1 &z,
                                             const int aligned,
                                             const int mismatch_spike,
                                             const int dom_pick)
{
   if(aligned != 0) {
      z.compatibility_score_permille = GovClampInt32(z.compatibility_score_permille + 18, 0, 1000);
      z.confidence_score_permille = GovClampInt32(z.confidence_score_permille + 12, 0, 1000);
      z.regime_alignment_hits++;
   } else if(mismatch_spike != 0) {
      z.compatibility_score_permille = GovClampInt32(z.compatibility_score_permille - 14, 0, 1000);
      z.toxicity_score_permille = GovClampInt32(z.toxicity_score_permille + 22, 0, 1000);
      z.regime_mismatch_hits++;
   } else {
      z.toxicity_score_permille = GovClampInt32(z.toxicity_score_permille - 4, 0, 1000);
   }

   if(dom_pick != 0) {
      z.dominance_pick_bars++;
      z.participation_score_permille = GovClampInt32(z.participation_score_permille + 10, 0, 1000);
   } else if(z.part_state == GOV_ECO_ST_ACTIVE || z.part_state == GOV_ECO_ST_PASSIVE) {
      z.participation_score_permille = GovClampInt32(z.participation_score_permille - 2, 0, 1000);
   }

   z.survivability_score_permille = GovClampInt32((z.compatibility_score_permille * 6 + (1000 - z.toxicity_score_permille) * 4) / 10, 0, 1000);

   z.ecology_health_pm = GovClampInt32((z.survivability_score_permille * 5 + (1000 - z.toxicity_score_permille) * 3 + z.compatibility_score_permille * 2) / 10, 0, 1000);
   z.ecology_pressure_pm = GovClampInt32((z.toxicity_score_permille * 7 + (1000 - z.compatibility_score_permille) * 3) / 10, 0, 1000);
   z.ecology_stability_pm = GovClampInt32((z.confidence_score_permille + z.compatibility_score_permille) / 2, 0, 1000);
   const long dpick = (long)z.dominance_pick_bars;
   z.ecology_dependency_pm = GovClampInt32((int)((z.participation_score_permille * 4L + dpick * 2L) / 6L), 0, 1000);
   z.ecology_recovery_pm = GovClampInt32((z.survivability_score_permille + (1000 - z.toxicity_score_permille)) / 2, 0, 1000);
}

inline void GovEcoScoreV1_RecomputeDiversity(SGovEcologyStoreV1 &st)
{
   ulong tot = 0;
   for(int i = 0; i < GOV_ECO_STRAT_COUNT_V1; i++)
      tot += st.s[i].dominance_pick_bars;
   if(tot < 10UL) {
      st.ecology_diversity_score_pm = 500;
      st.ecology_entropy_score_pm = 500;
      st.ecology_balance_score_pm = 500;
      st.monoculture_warn = 0;
      return;
   }
   double ent = 0.0;
   double maxp = 0.0;
   for(int j = 0; j < GOV_ECO_STRAT_COUNT_V1; j++) {
      const double p = (double)st.s[j].dominance_pick_bars / (double)tot;
      if(p > maxp)
         maxp = p;
      if(p > 1e-12)
         ent -= p * MathLog(p);
   }
   const double hmax = MathLog((double)GOV_ECO_STRAT_COUNT_V1);
   const int ent_pm = (hmax > 1e-12) ? (int)MathRound(1000.0 * ent / hmax) : 0;
   const int div_pm = GovClampInt32((int)MathRound(1000.0 * (1.0 - maxp)), 0, 1000);
   const int bal_pm = GovClampInt32((ent_pm + div_pm) / 2, 0, 1000);
   st.ecology_entropy_score_pm = GovClampInt32(ent_pm, 0, 1000);
   st.ecology_diversity_score_pm = GovClampInt32(div_pm, 0, 1000);
   st.ecology_balance_score_pm = GovClampInt32(bal_pm, 0, 1000);
   st.monoculture_warn = (maxp >= 0.88) ? 1 : 0;
}

#endif // __AURUM_GOV_ECOLOGY_SCORING_V1_MQH__
