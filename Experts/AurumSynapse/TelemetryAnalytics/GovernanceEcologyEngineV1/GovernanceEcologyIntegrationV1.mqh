//+------------------------------------------------------------------+
//| GovernanceEcologyIntegrationV1.mqh                              |
//| PHASE 23 — EA-facing integration surface                         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECOLOGY_INTEGRATION_V1_MQH__
#define __AURUM_GOV_ECOLOGY_INTEGRATION_V1_MQH__

#include "../../Core/Structures.mqh"
#include "../GovernanceRegimeEngineV1/GovernanceRegimeDatasetV1.mqh"
#include "GovernanceEcologyEngineV1.mqh"
#include "GovernanceEcologyPersistenceV1.mqh"

inline void GovEcolIntV1_ModuleInit(void)
{
   GovEcoDsV1_Init(g_gov_ecology_v1);
}

inline void GovEcolIntV1_Configure(const bool en)
{
   g_gov_ecology_v1.enabled = en;
   if(!en)
      GovEcoDsV1_Init(g_gov_ecology_v1);
}

inline void GovEcolIntV1_OnBarSignals(const datetime ts, const MarketState &ms, SignalResult &signals[])
{
   if(!g_gov_ecology_v1.enabled)
      return;
   GovEcoEngV1_OnBarSignals(g_gov_ecology_v1, ts, g_gov_regime_store_v1.current_regime, ms.regime, (int)ms.session, ms.atrRatio, signals);
}

inline void GovEcolIntV1_FlushPersistence(void)
{
   GovEcoPersistV1_WriteAllIfEnabled();
}

#endif // __AURUM_GOV_ECOLOGY_INTEGRATION_V1_MQH__
