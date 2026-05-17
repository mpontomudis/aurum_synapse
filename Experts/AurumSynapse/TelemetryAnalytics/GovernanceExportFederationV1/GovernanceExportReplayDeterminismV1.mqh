//+------------------------------------------------------------------+
//| GovernanceExportReplayDeterminismV1.mqh                          |
//| Deterministic string equality / hashing (no floats).              |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EXPORT_REPLAYDET_V1_MQH__
#define __AURUM_GOV_EXPORT_REPLAYDET_V1_MQH__

inline uint GovExportDetV1_Hash(const string &s)
{
   uint h = 2166136261U;
   const int n = StringLen(s);
   for(int i = 0; i < n; i++) {
      const ushort ch = StringGetCharacter(s, i);
      h ^= (uint)(ch & 0xFF);
      h *= 16777619U;
   }
   return h;
}

inline bool GovExportDetV1_Equals(const string &a, const string &b)
{
   return (a == b);
}

inline bool GovExportDetV1_Verify(const string &a, const string &b, string &err)
{
   err = "";
   if(!GovExportDetV1_Equals(a, b)) {
      err = "GOV_EXPORT_DET_MISMATCH";
      return false;
   }
   return true;
}

#endif // __AURUM_GOV_EXPORT_REPLAYDET_V1_MQH__
