//+------------------------------------------------------------------+
//| GovernanceComparisonReplayV1.mqh                               |
//| PHASE 20C — deterministic fingerprint for baseline rows          |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CMP_REPLAY_V1_MQH__
#define __AURUM_GOV_CMP_REPLAY_V1_MQH__

#include "GovernanceComparisonDatasetV1.mqh"
#include "../GovernanceRuntimeObservabilityExportV1/GovernanceRuntimeObservabilityReplayV1.mqh"

inline string GovCmpReplayV1_Flatten(const SGovCmpRunRecordV1 &r)
{
   if(r.valid == 0)
      return "CMP_NULL";
   return r.run_ts + "|" + r.sym + "|" + r.tf + "|" + r.git + "|" + IntegerToString(r.build_no) + "|" + IntegerToString(r.trades) + "|" + DoubleToString(r.pf, 6);
}

inline ulong GovCmpReplayV1_Hash(const SGovCmpRunRecordV1 &r)
{
   return GovRuntimeObsReplayV1_Hash64(GovCmpReplayV1_Flatten(r));
}

#endif // __AURUM_GOV_CMP_REPLAY_V1_MQH__
