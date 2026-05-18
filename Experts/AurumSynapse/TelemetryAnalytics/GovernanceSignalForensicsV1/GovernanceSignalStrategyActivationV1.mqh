//+------------------------------------------------------------------+
//| GovernanceSignalStrategyActivationV1.mqh                         |
//| PHASE 21 — strategy participation rates (integer permille)        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SIG_STRAT_ACTIVATION_V1_MQH__
#define __AURUM_GOV_SIG_STRAT_ACTIVATION_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

inline int GovSigStratActV1_AcceptPermille(const ulong sig_events, const ulong acc_events)
{
   if(sig_events == 0)
      return 0;
   return (int)GovClampInt32((int)(1000ULL * acc_events / sig_events), 0, 1000);
}

#endif // __AURUM_GOV_SIG_STRAT_ACTIVATION_V1_MQH__
