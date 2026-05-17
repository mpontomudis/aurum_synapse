//+------------------------------------------------------------------+
//| GovernanceExportDeterministicWriterV1.mqh                       |
//| LF-only deterministic string assembly.                          |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EXPORT_DETWRITER_V1_MQH__
#define __AURUM_GOV_EXPORT_DETWRITER_V1_MQH__

struct SGovDetWriterV1
{
   string buf;
};

inline void GovDetWriterV1_Reset(SGovDetWriterV1 &w)
{
   w.buf = "";
}

inline void GovDetWriterV1_Write(SGovDetWriterV1 &w, const string s)
{
   w.buf += s;
}

inline void GovDetWriterV1_WriteLine(SGovDetWriterV1 &w, const string line)
{
   w.buf += line + "\n";
}

inline void GovDetWriterV1_WriteKV(SGovDetWriterV1 &w, const string k, const string v)
{
   w.buf += k + "=" + v + "\n";
}

inline void GovDetWriterV1_WriteBlock(SGovDetWriterV1 &w, const string block_name, const string body)
{
   w.buf += block_name + "\n" + body;
}

#endif // __AURUM_GOV_EXPORT_DETWRITER_V1_MQH__
