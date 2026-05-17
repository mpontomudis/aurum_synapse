//+------------------------------------------------------------------+
//| GovernanceExportSchemaRegistryV1.mqh                             |
//| Canonical export block identifiers (LF-stable).                    |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EXPORT_SCHEMA_V1_MQH__
#define __AURUM_GOV_EXPORT_SCHEMA_V1_MQH__

#include "GovernanceExportFederationContractsV1.mqh"

#define GOV_EXP_BLK_STRATEGY_V1       "===STRATEGY_BREAKDOWN==="
#define GOV_EXP_BLK_REGIME_V1        "===REGIME_BREAKDOWN==="
#define GOV_EXP_BLK_SESSION_V1       "===SESSION_BREAKDOWN==="
#define GOV_EXP_BLK_VOL_V1           "===VOLATILITY_BREAKDOWN==="
#define GOV_EXP_BLK_TOX_V1           "===TOXICITY_BREAKDOWN==="
#define GOV_EXP_BLK_ECO_V1           "===ECOLOGY_BREAKDOWN==="
#define GOV_EXP_BLK_COMPAT_V1        "===COMPATIBILITY_BREAKDOWN==="
#define GOV_EXP_BLK_RESILIENCE_V1    "===RESILIENCE_BREAKDOWN==="
#define GOV_EXP_BLK_EVOLUTION_V1     "===EVOLUTION_BREAKDOWN==="
#define GOV_EXP_BLK_ENDURANCE_V1     "===ENDURANCE_BREAKDOWN==="
#define GOV_EXP_BLK_CSV_V1           "===CSV==="

inline bool GovExportSchemaV1_IsValid(const string &name)
{
   if(name == GOV_EXP_BLK_STRATEGY_V1)
      return true;
   if(name == GOV_EXP_BLK_REGIME_V1)
      return true;
   if(name == GOV_EXP_BLK_SESSION_V1)
      return true;
   if(name == GOV_EXP_BLK_VOL_V1)
      return true;
   if(name == GOV_EXP_BLK_TOX_V1)
      return true;
   if(name == GOV_EXP_BLK_ECO_V1)
      return true;
   if(name == GOV_EXP_BLK_COMPAT_V1)
      return true;
   if(name == GOV_EXP_BLK_RESILIENCE_V1)
      return true;
   if(name == GOV_EXP_BLK_EVOLUTION_V1)
      return true;
   if(name == GOV_EXP_BLK_ENDURANCE_V1)
      return true;
   if(name == GOV_EXP_BLK_CSV_V1)
      return true;
   return false;
}

inline int GovExportSchemaV1_Version(void)
{
   return GOV_EXPORT_ABI_VER_V1;
}

#endif // __AURUM_GOV_EXPORT_SCHEMA_V1_MQH__
