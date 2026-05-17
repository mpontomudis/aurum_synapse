//+------------------------------------------------------------------+
//| GovernanceRuntimeObservabilityReplayV1.mqh                      |
//| Deterministic hash / equality for export blob                      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_OBS_REPLAY_V1_MQH__
#define __AURUM_GOV_RUNTIME_OBS_REPLAY_V1_MQH__

inline ulong GovRuntimeObsReplayV1_Hash64(const string s)
{
   ulong h = 5381;
   const int n = StringLen(s);
   for(int i = 0; i < n; i++) {
      h = ((h << 5) + h) + (ulong)StringGetCharacter(s, i);
   }
   return h;
}

inline bool GovRuntimeObsReplayV1_Equals(const string a, const string b)
{
   return (a == b);
}

#endif // __AURUM_GOV_RUNTIME_OBS_REPLAY_V1_MQH__
