//+------------------------------------------------------------------+
//| GovernanceSignalConsensusForensicsV1.mqh                       |
//| PHASE 21 — consensus collapse diagnostics (integer-only)          |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SIG_CONSENSUS_FORENSICS_V1_MQH__
#define __AURUM_GOV_SIG_CONSENSUS_FORENSICS_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

inline int GovSigConsensusV1_PassPermille(const ulong pass, const ulong fail)
{
   const ulong tot = pass + fail;
   if(tot == 0)
      return 0;
   return (int)GovClampInt32((int)(1000ULL * pass / tot), 0, 1000);
}

inline int GovSigConsensusV1_AgreeingAvgPermille(const ulong agree_sum, const ulong samples)
{
   if(samples == 0)
      return 0;
   return (int)GovClampInt32((int)(1000ULL * agree_sum / samples), 0, 8000);
}

#endif // __AURUM_GOV_SIG_CONSENSUS_FORENSICS_V1_MQH__
