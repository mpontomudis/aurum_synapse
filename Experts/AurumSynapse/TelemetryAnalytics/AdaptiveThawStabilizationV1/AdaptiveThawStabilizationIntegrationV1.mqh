//+------------------------------------------------------------------+
//| AdaptiveThawStabilizationIntegrationV1.mqh                    |
//| PHASE 23.7 — EA / dossier surface                                |
//+------------------------------------------------------------------+
#ifndef __AURUM_ATS_INT_V1_MQH__
#define __AURUM_ATS_INT_V1_MQH__

#include "AdaptiveThawStabilizationHtmlV1.mqh"
#include "AdaptiveThawStabilizationPersistenceV1.mqh"

inline void GovAtsIntV1_ModuleInit(void)
{
   GovAtsDsV1_Init(g_gov_ats_v1);
}

inline void GovAtsIntV1_Configure(const bool en)
{
   g_gov_ats_v1.enabled = en;
   if(!en)
      GovAtsDsV1_Init(g_gov_ats_v1);
}

inline void GovAtsIntV1_OnBar(const ulong bar_seq,
                             const double eq_dd,
                             const double balance,
                             const double equity,
                             const double spread_pts,
                             const double atr_ratio,
                             const bool can_trade)
{
   GovAtsEngV1_OnBar(g_gov_ats_v1, g_gov_rli_v1, g_gov_rf_v1, g_gov_ecology_v1,
                     bar_seq, eq_dd, balance, equity, spread_pts, atr_ratio, can_trade);
}

inline void GovAtsIntV1_FlushPersistence(void)
{
   GovAtsPersistV1_WriteAll(g_gov_ats_v1);
}

inline void GovAtsIntV1_AppendDossierSection26(string &html)
{
   GovAtsHtmlV1_AppendSection26(html, g_gov_ats_v1);
}

#endif // __AURUM_ATS_INT_V1_MQH__
