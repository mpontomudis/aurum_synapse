//+------------------------------------------------------------------+
//| GovernanceRuntimeVisualReplayV1.mqh                             |
//| Deterministic fingerprint for HTML payload                       |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_VISUAL_REPLAY_V1_MQH__
#define __AURUM_GOV_RUNTIME_VISUAL_REPLAY_V1_MQH__

inline ulong GovRuntimeVisualReplayV1_Hash64(const string s)
{
   ulong h = 5381;
   const int n = StringLen(s);
   for(int i = 0; i < n; i++)
      h = ((h << 5) + h) + (ulong)StringGetCharacter(s, i);
   return h;
}

inline ulong GovRuntimeVisualReplayV1_Hash64Alt(const string s)
{
   ulong h = 0;
   const int n = StringLen(s);
   for(int i = 0; i < n; i++) {
      h ^= (ulong)StringGetCharacter(s, i);
      h = (h << 13) | (h >> 51);
   }
   return h;
}

#endif // __AURUM_GOV_RUNTIME_VISUAL_REPLAY_V1_MQH__
