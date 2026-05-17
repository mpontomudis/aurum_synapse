//+------------------------------------------------------------------+
//| GovernanceFailureExportV1.mqh                                 |
//| PHASE 20C — deterministic serialization for replay hashes        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_FAILURE_EXPORT_V1_MQH__
#define __AURUM_GOV_FAILURE_EXPORT_V1_MQH__

#include "GovernanceFailureDatasetV1.mqh"
#include "../GovernanceRuntimeObservabilityExportV1/GovernanceRuntimeObservabilityReplayV1.mqh"

inline string GovFailureExpV1_Flatten(const SGovFailureEventListV1 &l)
{
   string s = "FAIL_V1|n=" + IntegerToString(l.n);
   for(int i = 0; i < l.n; i++) {
      s += "|" + IntegerToString(l.ev[i].kind) + ":" + IntegerToString(l.ev[i].severity) + ":" + l.ev[i].title;
   }
   return s;
}

inline ulong GovFailureExpV1_Hash(const SGovFailureEventListV1 &l)
{
   return GovRuntimeObsReplayV1_Hash64(GovFailureExpV1_Flatten(l));
}

#endif // __AURUM_GOV_FAILURE_EXPORT_V1_MQH__
