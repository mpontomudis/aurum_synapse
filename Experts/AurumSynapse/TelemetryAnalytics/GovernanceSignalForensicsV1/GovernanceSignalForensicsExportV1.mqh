//+------------------------------------------------------------------+
//| GovernanceSignalForensicsExportV1.mqh                           |
//| PHASE 21 — LF-only CSV blocks (deterministic row order)          |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SIG_FORENSICS_EXPORT_V1_MQH__
#define __AURUM_GOV_SIG_FORENSICS_EXPORT_V1_MQH__

#include "GovernanceSignalForensicsTelemetryV1.mqh"
#include "GovernanceSignalRejectReasonV1.mqh"
#include "GovernanceSignalMonthlyAnalyticsV1.mqh"

inline void GovSigForensicsExportV1_AppendCsvBlock(const SGovSignalForensicsTelemetryV1 &t, string &dst)
{
   dst += "SIG_FORENSICS_V1\n";
   dst += "MONTH,created,passed,rejected\n";
   for(int m = 0; m < GOV_SIG_FORENSICS_MONTH_BUCKETS_V1; m++) {
      dst += GovSigMonthlyV1_AbbrFromIndex0_11(m) + "," + IntegerToString(t.month_created[m]) + "," +
             IntegerToString(t.month_passed[m]) + "," + IntegerToString(t.month_rejected[m]) + "\n";
   }
   dst += "REJECT_REASON,count\n";
   for(int j = 0; j < GOV_SIG_REJECT_REASON_COUNT_V1; j++) {
      dst += GovSigRejectV1_Label(j) + "," + IntegerToString(t.reject_by_reason[j]) + "\n";
   }
   dst += "STRAT,signals,accepted,rejected\n";
   for(int s = 0; s < GOV_SIG_FORENSICS_STRATEGY_SLOTS_V1; s++) {
      dst += IntegerToString(s) + "," + IntegerToString(t.strat_sig[s]) + "," + IntegerToString(t.strat_acc[s]) + "," +
             IntegerToString(t.strat_rej[s]) + "\n";
   }
   dst += "REGIME,signals,accepted\n";
   for(int r = 0; r < GOV_SIG_FORENSICS_REGIME_SLOTS_V1; r++) {
      dst += IntegerToString(r) + "," + IntegerToString(t.reg_sig[r]) + "," + IntegerToString(t.reg_acc[r]) + "\n";
   }
   dst += "CONSENSUS,attempts,pass,fail,agree_sum,samples\n";
   dst += "0," + IntegerToString(t.consensus_attempts) + "," + IntegerToString(t.consensus_pass) + "," +
          IntegerToString(t.consensus_fail) + "," + IntegerToString(t.consensus_agree_sum) + "," +
          IntegerToString(t.consensus_agree_samples) + "\n";
}

#endif // __AURUM_GOV_SIG_FORENSICS_EXPORT_V1_MQH__
