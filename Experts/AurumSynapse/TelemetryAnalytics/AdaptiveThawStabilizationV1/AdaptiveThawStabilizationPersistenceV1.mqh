//+------------------------------------------------------------------+
//| AdaptiveThawStabilizationPersistenceV1.mqh                     |
//| PHASE 23.7 — CSV exports (observe-only)                         |
//+------------------------------------------------------------------+
#ifndef __AURUM_ATS_PERSIST_V1_MQH__
#define __AURUM_ATS_PERSIST_V1_MQH__

#include "AdaptiveThawStabilizationEngineV1.mqh"

#define GOV_ATS_FILES_DIR_V1   "AurumSynapse\\TelemetryAnalytics\\AdaptiveThawStabilization\\"

inline bool GovAtsPersistV1_EnsureDir(void)
{
   FolderCreate("AurumSynapse");
   FolderCreate("AurumSynapse\\TelemetryAnalytics");
   return FolderCreate(GOV_ATS_FILES_DIR_V1);
}

inline bool GovAtsPersistV1_WriteAdaptiveThaw(SGovAtsStoreV1 &st)
{
   GovAtsPersistV1_EnsureDir();
   const int h = FileOpen(GOV_ATS_FILES_DIR_V1 + "adaptive_thaw.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "bars_observed", IntegerToString((long)st.bars_observed));
   FileWrite(h, "thaw_confidence_pm", DoubleToString(st.last_thaw_confidence_pm, 4));
   FileWrite(h, "thaw_stability_pm", DoubleToString(st.last_thaw_stability_pm, 4));
   FileWrite(h, "thaw_relapse_pm", DoubleToString(st.last_thaw_relapse_pm, 4));
   FileWrite(h, "thaw_state", IntegerToString(st.last_thaw_state));
   for(int i = 0; i < GOV_ATS_THAW_STATE_CT_V1; i++)
      FileWrite(h, "hist_thaw_" + IntegerToString(i), IntegerToString((long)st.thaw_state_hist[i]));
   FileClose(h);
   return true;
}

inline bool GovAtsPersistV1_WriteLockDecay(SGovAtsStoreV1 &st)
{
   GovAtsPersistV1_EnsureDir();
   const int h = FileOpen(GOV_ATS_FILES_DIR_V1 + "lock_decay.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "lock_age_bars_last", IntegerToString((long)st.lock_age_bars_last));
   FileWrite(h, "lock_decay_rate_pm", DoubleToString(st.last_lock_decay_rate_pm, 4));
   FileWrite(h, "decay_class", IntegerToString(st.last_decay_class));
   for(int j = 0; j < GOV_ATS_DECAY_CT_V1; j++)
      FileWrite(h, "hist_decay_" + IntegerToString(j), IntegerToString((long)st.decay_hist[j]));
   FileClose(h);
   return true;
}

inline bool GovAtsPersistV1_WriteFloatingNorm(SGovAtsStoreV1 &st)
{
   GovAtsPersistV1_EnsureDir();
   const int h = FileOpen(GOV_ATS_FILES_DIR_V1 + "floating_normalization.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "float_norm_pm", DoubleToString(st.last_float_norm_pm, 4));
   FileWrite(h, "float_recovery_vel_pm", DoubleToString(st.last_float_recovery_vel_pm, 4));
   FileWrite(h, "float_v2_class", IntegerToString(st.last_float_v2_class));
   for(int f = 0; f < GOV_ATS_FLOAT_V2_CT_V1; f++)
      FileWrite(h, "hist_float2_" + IntegerToString(f), IntegerToString((long)st.float_v2_hist[f]));
   FileClose(h);
   return true;
}

inline bool GovAtsPersistV1_WriteContextualDd(SGovAtsStoreV1 &st)
{
   GovAtsPersistV1_EnsureDir();
   const int h = FileOpen(GOV_ATS_FILES_DIR_V1 + "contextual_dd.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "dd_context_pm", DoubleToString(st.last_dd_context_pm, 4));
   FileWrite(h, "vol_adj_dd", DoubleToString(st.last_vol_adj_dd, 4));
   FileWrite(h, "spread_adj_dd", DoubleToString(st.last_spread_adj_dd, 4));
   FileClose(h);
   return true;
}

inline bool GovAtsPersistV1_WriteRecoveryMomentum(SGovAtsStoreV1 &st)
{
   GovAtsPersistV1_EnsureDir();
   const int h = FileOpen(GOV_ATS_FILES_DIR_V1 + "recovery_momentum.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "recovery_momentum_pm", DoubleToString(st.last_recovery_momentum_pm, 4));
   FileWrite(h, "recovery_state", IntegerToString(st.last_recovery_state));
   for(int r = 0; r < GOV_ATS_RECOVERY_CT_V1; r++)
      FileWrite(h, "hist_recovery_" + IntegerToString(r), IntegerToString((long)st.recovery_hist[r]));
   FileClose(h);
   return true;
}

inline bool GovAtsPersistV1_WriteParalysis(SGovAtsStoreV1 &st)
{
   GovAtsPersistV1_EnsureDir();
   const int h = FileOpen(GOV_ATS_FILES_DIR_V1 + "paralysis_detection.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "paralysis_index_pm", DoubleToString(st.last_paralysis_index_pm, 4));
   FileWrite(h, "defensive_overreaction_pm", DoubleToString(st.last_defensive_overreaction_pm, 4));
   FileWrite(h, "paralysis_state", IntegerToString(st.last_paralysis_state));
   for(int p = 0; p < GOV_ATS_PARALYSIS_CT_V1; p++)
      FileWrite(h, "hist_paralysis_" + IntegerToString(p), IntegerToString((long)st.paralysis_hist[p]));
   FileClose(h);
   return true;
}

inline bool GovAtsPersistV1_WriteExecContinuity(SGovAtsStoreV1 &st)
{
   GovAtsPersistV1_EnsureDir();
   const int h = FileOpen(GOV_ATS_FILES_DIR_V1 + "execution_continuity.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "exec_continuity_pm", DoubleToString(st.last_exec_continuity_pm, 4));
   FileWrite(h, "bars_since_exec_hint", IntegerToString((long)st.last_bars_since_exec_hint));
   FileClose(h);
   return true;
}

inline bool GovAtsPersistV1_WriteEcologyRecovery(SGovAtsStoreV1 &st)
{
   GovAtsPersistV1_EnsureDir();
   const int h = FileOpen(GOV_ATS_FILES_DIR_V1 + "ecology_recovery.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "ecology_recovery_pm", DoubleToString(st.last_ecology_recovery_pm, 4));
   FileWrite(h, "suppression_decay_pm", DoubleToString(st.last_suppression_decay_pm, 4));
   FileClose(h);
   return true;
}

inline bool GovAtsPersistV1_WriteNervousSystem(SGovAtsStoreV1 &st)
{
   GovAtsPersistV1_EnsureDir();
   const int h = FileOpen(GOV_ATS_FILES_DIR_V1 + "governance_nervous_system.csv", FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "metric", "value");
   FileWrite(h, "stress_accum_pm", DoubleToString(st.last_stress_accum_pm, 4));
   FileWrite(h, "stress_decay_pm", DoubleToString(st.last_stress_decay_pm, 4));
   FileWrite(h, "nervous_resilience_pm", DoubleToString(st.last_nervous_resilience_pm, 4));
   FileClose(h);
   return true;
}

inline bool GovAtsPersistV1_WriteAll(SGovAtsStoreV1 &st)
{
   if(!st.enabled)
      return true;
   bool ok = true;
   ok &= GovAtsPersistV1_WriteAdaptiveThaw(st);
   ok &= GovAtsPersistV1_WriteLockDecay(st);
   ok &= GovAtsPersistV1_WriteFloatingNorm(st);
   ok &= GovAtsPersistV1_WriteContextualDd(st);
   ok &= GovAtsPersistV1_WriteRecoveryMomentum(st);
   ok &= GovAtsPersistV1_WriteParalysis(st);
   ok &= GovAtsPersistV1_WriteExecContinuity(st);
   ok &= GovAtsPersistV1_WriteEcologyRecovery(st);
   ok &= GovAtsPersistV1_WriteNervousSystem(st);
   return ok;
}

#endif // __AURUM_ATS_PERSIST_V1_MQH__
