//+------------------------------------------------------------------+
//| GovernanceExportFederationContractsV1.mqh                      |
//| Stable export federation ABI markers.                           |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EXPORT_FED_CONTRACTS_V1_MQH__
#define __AURUM_GOV_EXPORT_FED_CONTRACTS_V1_MQH__

#define GOV_EXPORT_ABI_VER_V1 1
#define GOV_EXPORT_MAGIC_V1   0x47584631

inline bool GovExportContractsV1_ValidateVersion(void)
{
   return (GOV_EXPORT_ABI_VER_V1 == 1);
}

inline bool GovExportContractsV1_ValidateMagic(const int magic)
{
   return (magic == GOV_EXPORT_MAGIC_V1);
}

#endif // __AURUM_GOV_EXPORT_FED_CONTRACTS_V1_MQH__
