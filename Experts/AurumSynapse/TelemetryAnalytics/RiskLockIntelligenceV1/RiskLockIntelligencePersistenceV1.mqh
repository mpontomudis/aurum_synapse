//+------------------------------------------------------------------+
//| RiskLockIntelligencePersistenceV1.mqh                          |
//| PHASE 23.6 — CSV exports (observe-only)                          |
//+------------------------------------------------------------------+
#ifndef __AURUM_RLI_PERSIST_V1_MQH__
#define __AURUM_RLI_PERSIST_V1_MQH__

#include "RiskLockIntelligenceEngineV1.mqh"

#define GOV_RLI_FILES_DIR_V1   "AurumSynapse\\TelemetryAnalytics\\RiskLockIntelligence\\"

inline bool GovRliPersistV1_EnsureDir(void)
{
   FolderCreate("AurumSynapse");
   FolderCreate("AurumSynapse\\TelemetryAnalytics");
   return FolderCreate(GOV_RLI_FILES_DIR_V1);
}

inline string GovRliPersistV1_OriginLabel(const int o)
{
   switch(o) {
   case GOV_RLI_ORIG_DD_SPIKE_V1: return "DD_SPIKE";
   case GOV_RLI_ORIG_FLOATING_PRESSURE_V1: return "FLOATING_PRESSURE";
   case GOV_RLI_ORIG_SPREAD_EXPANSION_V1: return "SPREAD_EXPANSION";
   case GOV_RLI_ORIG_EXEC_TOXICITY_V1: return "EXECUTION_TOXICITY";
   case GOV_RLI_ORIG_VOL_COLLAPSE_V1: return "VOLATILITY_COLLAPSE";
   case GOV_RLI_ORIG_ECOLOGY_CASCADE_V1: return "ECOLOGY_CASCADE";
   case GOV_RLI_ORIG_REGIME_INSTABILITY_V1: return "REGIME_INSTABILITY";
   case GOV_RLI_ORIG_RECOVERY_FAILURE_V1: return "RECOVERY_FAILURE";
   default: return "UNKNOWN";
   }
}

inline bool GovRliPersistV1_WriteLockOrigins(SGovRliStoreV1 &st)
{
   GovRliPersistV1_EnsureDir();
   const string path = GOV_RLI_FILES_DIR_V1 + "risk_lock_origins.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "origin", "count");
   for(int i = 0; i < 9; i++)
      FileWrite(h, GovRliPersistV1_OriginLabel(i), IntegerToString((long)st.lock_origin_hist[i]));
   FileWrite(h, "lock_events", IntegerToString((long)st.lock_events));
   FileWrite(h, "total_lock_bars", IntegerToString((long)st.total_lock_bars));
   FileWrite(h, "ring_count", IntegerToString(st.ring_count));
   FileWrite(h, "id", "t0", "t1", "bar0", "bar1", "origin", "dur_bars", "eq_dd0", "fp0", "deny0", "halt0");
   const int n = st.ring_count;
   for(int k = 0; k < n; k++) {
      const int idx = (st.ring_wi - 1 - k + GOV_RLI_RING_V1 * 2) % GOV_RLI_RING_V1;
      const SGovRliLockRecordV1 r = st.ring[idx];
      FileWrite(h, IntegerToString((long)r.id), TimeToString(r.t0, TIME_DATE | TIME_SECONDS), TimeToString(r.t1, TIME_DATE | TIME_SECONDS),
                IntegerToString((long)r.bar0), IntegerToString((long)r.bar1), GovRliPersistV1_OriginLabel(r.origin),
                IntegerToString((long)r.duration_bars), DoubleToString(r.eq_dd0, 4), DoubleToString(r.floating_pressure0, 4),
                IntegerToString(r.deny_detail0), IntegerToString(r.halt_reason0));
   }
   FileClose(h);
   return true;
}

inline bool GovRliPersistV1_WriteThaw(SGovRliStoreV1 &st)
{
   GovRliPersistV1_EnsureDir();
   const string path = GOV_RLI_FILES_DIR_V1 + "thaw_intelligence.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   const double avg_thaw = (st.thaw_successes > 0) ? ((double)st.thaw_duration_bars_sum / (double)st.thaw_successes) : 0.0;
   FileWrite(h, "metric", "value");
   FileWrite(h, "thaw_attempts", IntegerToString((long)st.thaw_attempts));
   FileWrite(h, "thaw_successes", IntegerToString((long)st.thaw_successes));
   FileWrite(h, "thaw_interruptions", IntegerToString((long)st.thaw_interruptions));
   FileWrite(h, "avg_thaw_duration_bars", DoubleToString(avg_thaw, 4));
   FileClose(h);
   return true;
}

inline bool GovRliPersistV1_WriteFloating(SGovRliStoreV1 &st)
{
   GovRliPersistV1_EnsureDir();
   const string path = GOV_RLI_FILES_DIR_V1 + "floating_pressure.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   const double avg_fp = (st.bars_observed > 0) ? (st.sum_floating_pressure / (double)st.bars_observed) : 0.0;
   FileWrite(h, "metric", "value");
   FileWrite(h, "avg_floating_pressure_pct", DoubleToString(avg_fp, 4));
   FileWrite(h, "float_stress_bars", IntegerToString((long)st.float_stress_bars));
   FileWrite(h, "float_recovery_edges", IntegerToString((long)st.float_recovery_bars));
   FileClose(h);
   return true;
}

inline bool GovRliPersistV1_WriteDdClass(SGovRliStoreV1 &st)
{
   GovRliPersistV1_EnsureDir();
   const string path = GOV_RLI_FILES_DIR_V1 + "dd_classification.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "dd_class", "bars");
   const string lab[8] = { "TRANSIENT", "VOLATILITY", "EXECUTION", "LIQUIDITY", "STRUCTURAL", "GRID", "TESTER_ARTIFACT", "RESERVED" };
   for(int i = 0; i < 8; i++)
      FileWrite(h, lab[i], IntegerToString((long)st.dd_class_hist[i]));
   FileClose(h);
   return true;
}

inline bool GovRliPersistV1_WriteLockPersistence(SGovRliStoreV1 &st)
{
   GovRliPersistV1_EnsureDir();
   const string path = GOV_RLI_FILES_DIR_V1 + "lock_persistence.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWrite(h, "persistence_bucket", "count");
   FileWrite(h, "HEALTHY", IntegerToString((long)st.persist_class_hist[0]));
   FileWrite(h, "DEFENSIVE", IntegerToString((long)st.persist_class_hist[1]));
   FileWrite(h, "OVEREXTENDED", IntegerToString((long)st.persist_class_hist[2]));
   FileWrite(h, "PARALYSIS", IntegerToString((long)st.persist_class_hist[3]));
   FileClose(h);
   return true;
}

inline bool GovRliPersistV1_WriteStarvation(SGovRliStoreV1 &st)
{
   GovRliPersistV1_EnsureDir();
   const string path = GOV_RLI_FILES_DIR_V1 + "starvation_correlation.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   const double ratio = (st.bars_observed > 0) ? ((double)st.bars_starvation_overlap / (double)st.bars_observed) : 0.0;
   FileWrite(h, "metric", "value");
   FileWrite(h, "bars_starvation_overlap", IntegerToString((long)st.bars_starvation_overlap));
   FileWrite(h, "starvation_lock_ratio", DoubleToString(ratio, 6));
   FileWrite(h, "max_starvation_bars", IntegerToString((long)st.max_starvation_bars));
   FileClose(h);
   return true;
}

inline bool GovRliPersistV1_WriteStress(SGovRliStoreV1 &st)
{
   GovRliPersistV1_EnsureDir();
   const string path = GOV_RLI_FILES_DIR_V1 + "governance_stress.csv";
   const int h = FileOpen(path, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   const double stress_pm = (st.bars_observed > 0) ? (1000.0 * (double)st.governance_stress_accum / (double)st.bars_observed) : 0.0;
   FileWrite(h, "metric", "value");
   FileWrite(h, "governance_stress_permille", DoubleToString(stress_pm, 4));
   FileWrite(h, "defensive_escalation_events", IntegerToString((long)st.defensive_escalation_events));
   FileClose(h);
   return true;
}

inline bool GovRliPersistV1_WriteAll(SGovRliStoreV1 &st)
{
   if(!st.enabled)
      return true;
   bool ok = true;
   ok &= GovRliPersistV1_WriteLockOrigins(st);
   ok &= GovRliPersistV1_WriteThaw(st);
   ok &= GovRliPersistV1_WriteFloating(st);
   ok &= GovRliPersistV1_WriteDdClass(st);
   ok &= GovRliPersistV1_WriteLockPersistence(st);
   ok &= GovRliPersistV1_WriteStarvation(st);
   ok &= GovRliPersistV1_WriteStress(st);
   return ok;
}

#endif // __AURUM_RLI_PERSIST_V1_MQH__
