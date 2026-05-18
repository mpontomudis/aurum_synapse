//+------------------------------------------------------------------+
//| GovernanceMobilityIntegrationV1.mqh                            |
//| PHASE 24A — EA / dossier surface                                  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_GMB_INT_V1_MQH__
#define __AURUM_GOV_GMB_INT_V1_MQH__

#include "GovernanceMobilityRendererV1.mqh"

inline void GovGmbIntV1_ModuleInit(void)
{
   GovGmbDsV1_Init(g_gov_gmb_v1);
}

inline void GovGmbIntV1_Configure(const bool en)
{
   g_gov_gmb_v1.enabled = en;
   if(!en)
      GovGmbDsV1_Init(g_gov_gmb_v1);
}

inline void GovGmbIntV1_OnBar(const bool can_trade)
{
   GovGmbEngV1_OnBar(g_gov_gmb_v1, g_gov_rci_v1, g_gov_ats_v1, g_gov_rli_v1, g_gov_rf_v1, g_gov_ecology_v1, can_trade);
}

inline void GovGmbIntV1_FlushPersistence(void)
{
   GovGmbRenderV1_WriteAllCsv(g_gov_gmb_v1);
}

inline void GovGmbIntV1_AppendDossierSections3139(string &html)
{
   GovGmbRenderV1_AppendDossierSections3139(html, g_gov_gmb_v1, g_gov_ecology_v1);
}

#endif // __AURUM_GOV_GMB_INT_V1_MQH__
