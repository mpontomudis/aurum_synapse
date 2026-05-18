//+------------------------------------------------------------------+
//| GovernanceRecoveryContinuationIntegrationV1.mqh                |
//| PHASE 24 — EA / dossier surface                                   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RCI_INT_V1_MQH__
#define __AURUM_GOV_RCI_INT_V1_MQH__

#include "GovernanceRecoveryContinuationRendererV1.mqh"

inline void GovRciIntV1_ModuleInit(void)
{
   GovRciDsV1_Init(g_gov_rci_v1);
}

inline void GovRciIntV1_Configure(const bool en)
{
   g_gov_rci_v1.enabled = en;
   if(!en)
      GovRciDsV1_Init(g_gov_rci_v1);
}

inline void GovRciIntV1_OnBar(const ulong bar_seq,
                               const double eq_dd,
                               const bool can_trade)
{
   GovRciEngV1_OnBar(g_gov_rci_v1, g_gov_rli_v1, g_gov_rf_v1, g_gov_ecology_v1, g_gov_ats_v1, bar_seq, eq_dd, can_trade);
}

inline void GovRciIntV1_FlushPersistence(void)
{
   GovRciRenderV1_WriteAllCsv(g_gov_rci_v1);
}

inline void GovRciIntV1_AppendDossierSections2730(string &html)
{
   GovRciRenderV1_AppendDossierSections2730(html, g_gov_rci_v1);
}

#endif // __AURUM_GOV_RCI_INT_V1_MQH__
