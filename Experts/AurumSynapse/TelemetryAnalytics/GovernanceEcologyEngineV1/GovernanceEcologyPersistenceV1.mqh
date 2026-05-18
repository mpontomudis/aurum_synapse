//+------------------------------------------------------------------+
//| GovernanceEcologyPersistenceV1.mqh                              |
//| PHASE 23 — CSV exports under MQL5/Files/AurumSynapse/.../Ecology/ |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECOLOGY_PERSISTENCE_V1_MQH__
#define __AURUM_GOV_ECOLOGY_PERSISTENCE_V1_MQH__

#include "GovernanceEcologyDatasetV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionExportV1.mqh"

#define GOV_ECOLOGY_FILES_DIR_V1   "AurumSynapse\\TelemetryAnalytics\\Ecology\\"

inline bool GovEcoPersistV1_EnsureDir(void)
{
   FolderCreate("AurumSynapse");
   FolderCreate("AurumSynapse\\TelemetryAnalytics");
   return FolderCreate(GOV_ECOLOGY_FILES_DIR_V1);
}

inline bool GovEcoPersistV1_WriteSummary(const SGovEcologyStoreV1 &st)
{
   GovEcoPersistV1_EnsureDir();
   const string path = GOV_ECOLOGY_FILES_DIR_V1 + "ecology_summary.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "strat", "state", "compat", "surv", "tox", "part", "conf", "health", "pressure", "stab", "align", "mismatch", "dom_picks");
   for(int i = 0; i < GOV_ECO_STRAT_COUNT_V1; i++) {
      const SGovEcologyStratSliceV1 z = st.s[i];
      FileWrite(h, GovStratExpV1_StratLabel(i), IntegerToString(z.part_state), IntegerToString(z.compatibility_score_permille),
                IntegerToString(z.survivability_score_permille), IntegerToString(z.toxicity_score_permille),
                IntegerToString(z.participation_score_permille), IntegerToString(z.confidence_score_permille),
                IntegerToString(z.ecology_health_pm), IntegerToString(z.ecology_pressure_pm), IntegerToString(z.ecology_stability_pm),
                IntegerToString((long)z.regime_alignment_hits), IntegerToString((long)z.regime_mismatch_hits),
                IntegerToString((long)z.dominance_pick_bars));
   }
   FileWrite(h, "__aggregate__", IntegerToString(st.ecology_diversity_score_pm), IntegerToString(st.ecology_entropy_score_pm),
             IntegerToString(st.ecology_balance_score_pm), IntegerToString(st.monoculture_warn), "", "", "", "", "", "");
   FileClose(h);
   return true;
}

inline bool GovEcoPersistV1_WriteRegimeMatrix(const SGovEcologyStoreV1 &st)
{
   GovEcoPersistV1_EnsureDir();
   const string path = GOV_ECOLOGY_FILES_DIR_V1 + "strategy_regime_matrix.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "strat", "sess0", "sess1", "sess2", "sess3", "vol0", "vol1", "vol2", "vol3");
   for(int i = 0; i < GOV_ECO_STRAT_COUNT_V1; i++) {
      FileWrite(h, GovStratExpV1_StratLabel(i),
                IntegerToString((long)st.strat_bars_by_sess[i][0]), IntegerToString((long)st.strat_bars_by_sess[i][1]),
                IntegerToString((long)st.strat_bars_by_sess[i][2]), IntegerToString((long)st.strat_bars_by_sess[i][3]),
                IntegerToString((long)st.strat_bars_by_vol[i][0]), IntegerToString((long)st.strat_bars_by_vol[i][1]),
                IntegerToString((long)st.strat_bars_by_vol[i][2]), IntegerToString((long)st.strat_bars_by_vol[i][3]));
   }
   FileClose(h);
   return true;
}

inline bool GovEcoPersistV1_WriteToxicity(const SGovEcologyStoreV1 &st)
{
   GovEcoPersistV1_EnsureDir();
   const string path = GOV_ECOLOGY_FILES_DIR_V1 + "ecology_toxicity.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "strat", "tox_pm", "pressure_pm", "fail_cycles", "recovery_cycles");
   for(int i = 0; i < GOV_ECO_STRAT_COUNT_V1; i++) {
      FileWrite(h, GovStratExpV1_StratLabel(i), IntegerToString(st.s[i].toxicity_score_permille),
                IntegerToString(st.s[i].ecology_pressure_pm), IntegerToString((long)st.s[i].failure_cycles),
                IntegerToString((long)st.s[i].recovery_cycles));
   }
   FileClose(h);
   return true;
}

inline bool GovEcoPersistV1_WriteSurvivability(const SGovEcologyStoreV1 &st)
{
   GovEcoPersistV1_EnsureDir();
   const string path = GOV_ECOLOGY_FILES_DIR_V1 + "ecology_survivability.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "strat", "surv_pm", "recovery_pm", "health_pm", "participation_bars", "suppression_bars");
   for(int i = 0; i < GOV_ECO_STRAT_COUNT_V1; i++) {
      FileWrite(h, GovStratExpV1_StratLabel(i), IntegerToString(st.s[i].survivability_score_permille),
                IntegerToString(st.s[i].ecology_recovery_pm), IntegerToString(st.s[i].ecology_health_pm),
                IntegerToString((long)st.s[i].bars_participation), IntegerToString((long)st.s[i].bars_suppression));
   }
   FileClose(h);
   return true;
}

inline bool GovEcoPersistV1_WriteDominance(const SGovEcologyStoreV1 &st)
{
   GovEcoPersistV1_EnsureDir();
   const string path = GOV_ECOLOGY_FILES_DIR_V1 + "ecology_dominance.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "strat", "dominance_pick_bars", "throttled_bars", "dominant_role_bars");
   for(int i = 0; i < GOV_ECO_STRAT_COUNT_V1; i++) {
      FileWrite(h, GovStratExpV1_StratLabel(i), IntegerToString((long)st.s[i].dominance_pick_bars),
                IntegerToString((long)st.s[i].bars_throttled), IntegerToString((long)st.s[i].bars_dominant));
   }
   FileClose(h);
   return true;
}

inline bool GovEcoPersistV1_WriteCooccurUpper(const SGovEcologyStoreV1 &st)
{
   GovEcoPersistV1_EnsureDir();
   const string path = GOV_ECOLOGY_FILES_DIR_V1 + "ecology_cooccurrence.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "row", "c0", "c1", "c2", "c3", "c4", "c5", "c6", "c7");
   for(int r = 0; r < GOV_ECO_STRAT_COUNT_V1; r++) {
      FileWrite(h, GovStratExpV1_StratLabel(r),
                IntegerToString((long)st.cooccur[r][0]), IntegerToString((long)st.cooccur[r][1]),
                IntegerToString((long)st.cooccur[r][2]), IntegerToString((long)st.cooccur[r][3]),
                IntegerToString((long)st.cooccur[r][4]), IntegerToString((long)st.cooccur[r][5]),
                IntegerToString((long)st.cooccur[r][6]), IntegerToString((long)st.cooccur[r][7]));
   }
   FileClose(h);
   return true;
}

inline void GovEcoPersistV1_WriteAllIfEnabled(void)
{
   if(!g_gov_ecology_v1.enabled)
      return;
   GovEcoPersistV1_WriteSummary(g_gov_ecology_v1);
   GovEcoPersistV1_WriteRegimeMatrix(g_gov_ecology_v1);
   GovEcoPersistV1_WriteToxicity(g_gov_ecology_v1);
   GovEcoPersistV1_WriteSurvivability(g_gov_ecology_v1);
   GovEcoPersistV1_WriteDominance(g_gov_ecology_v1);
   GovEcoPersistV1_WriteCooccurUpper(g_gov_ecology_v1);
}

#endif // __AURUM_GOV_ECOLOGY_PERSISTENCE_V1_MQH__
