//+------------------------------------------------------------------+
//| GovernanceExportFederationCoreV1.mqh                             |
//| Centralized deterministic export buffer (LF-only).               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EXPORT_FED_CORE_V1_MQH__
#define __AURUM_GOV_EXPORT_FED_CORE_V1_MQH__

#include "GovernanceExportFederationContractsV1.mqh"
#include "GovernanceExportDeterministicWriterV1.mqh"

struct SGovExportFedStateV1
{
   SGovDetWriterV1 w;
   int magic;
};

inline void GovExportFedV1_Reset(SGovExportFedStateV1 &st)
{
   GovDetWriterV1_Reset(st.w);
   st.magic = GOV_EXPORT_MAGIC_V1;
}

inline void GovExportFedV1_Build(SGovExportFedStateV1 &st)
{
   GovExportFedV1_Reset(st);
}

inline void GovExportFedV1_Append(SGovExportFedStateV1 &st, const string line)
{
   GovDetWriterV1_WriteLine(st.w, line);
}

inline void GovExportFedV1_Finalize(SGovExportFedStateV1 &st, string &out)
{
   out = st.w.buf;
}

#endif // __AURUM_GOV_EXPORT_FED_CORE_V1_MQH__
