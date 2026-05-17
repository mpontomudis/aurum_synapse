//+------------------------------------------------------------------+
//| GovernanceExportFederationTelemetryV1.mqh                        |
//| Lightweight export health counters (integer-only).                |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EXPORT_FED_TELEM_V1_MQH__
#define __AURUM_GOV_EXPORT_FED_TELEM_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

struct SGovExportFedTelemV1
{
   int bundle_calls;
   int bundle_fail;
   int compat_redirects;
   int schema_mismatch;
   int abi_violation;
};

inline void GovExportTelemV1_Reset(SGovExportFedTelemV1 &t)
{
   t.bundle_calls = 0;
   t.bundle_fail = 0;
   t.compat_redirects = 0;
   t.schema_mismatch = 0;
   t.abi_violation = 0;
}

inline void GovExportTelemV1_OnBundleOk(SGovExportFedTelemV1 &t)
{
   t.bundle_calls = GovSaturatingAdd32(t.bundle_calls, 1);
}

inline void GovExportTelemV1_OnBundleFail(SGovExportFedTelemV1 &t)
{
   t.bundle_fail = GovSaturatingAdd32(t.bundle_fail, 1);
}

#endif // __AURUM_GOV_EXPORT_FED_TELEM_V1_MQH__
