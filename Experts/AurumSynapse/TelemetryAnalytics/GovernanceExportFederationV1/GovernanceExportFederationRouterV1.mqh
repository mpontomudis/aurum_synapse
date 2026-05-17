//+------------------------------------------------------------------+
//| GovernanceExportFederationRouterV1.mqh                           |
//| Cross-phase export routing (deterministic, no live includes).     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EXPORT_FED_ROUTER_V1_MQH__
#define __AURUM_GOV_EXPORT_FED_ROUTER_V1_MQH__

#include "GovernanceExportFederationContractsV1.mqh"
#include "../GovernanceStrategicContextRefactorV1/GovernanceStrategicPhaseIsolationV1.mqh"

inline void GovExportRouterV1_Build(void)
{
}

inline bool GovExportRouterV1_Link(const int phase_id, string &err)
{
   err = "";
   if(phase_id < GOV_PHASE_21_FEDERATION_V1) {
      err = "GOV_EXPORT_ROUTER_PHASE_LOW";
      return false;
   }
   return true;
}

inline bool GovExportRouterV1_Resolve(const int export_abi, string &err)
{
   err = "";
   if(export_abi != GOV_EXPORT_ABI_VER_V1) {
      err = "GOV_EXPORT_ROUTER_ABI_MISMATCH";
      return false;
   }
   return true;
}

#endif // __AURUM_GOV_EXPORT_FED_ROUTER_V1_MQH__
