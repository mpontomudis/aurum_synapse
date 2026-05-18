//+------------------------------------------------------------------+
//| GovernanceRestrictionForensicsIntegrationV1.mqh                 |
//| PHASE 23.5 — EA-facing surface (observe-only)                  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RF_INT_V1_MQH__
#define __AURUM_GOV_RF_INT_V1_MQH__

#include "../../Core/Structures.mqh"
#include "../GovernanceRegimeEngineV1/GovernanceRegimeDatasetV1.mqh"
#include "GovernanceRestrictionForensicsPersistenceV1.mqh"
#include "GovernanceRestrictionForensicsHtmlV1.mqh"

static int s_gov_rf_reg_slot_prev_v1 = -1;

inline void GovRfIntV1_ModuleInit(void)
{
   GovRfDsV1_Init(g_gov_rf_v1);
   s_gov_rf_reg_slot_prev_v1 = -1;
}

inline void GovRfIntV1_Configure(const bool en)
{
   g_gov_rf_v1.enabled = en;
   if(!en) {
      GovRfDsV1_Init(g_gov_rf_v1);
      s_gov_rf_reg_slot_prev_v1 = -1;
   }
}

inline void GovRfIntV1_OnNewBarOpened(void)
{
   GovRfEngV1_OnBarOpen(g_gov_rf_v1);
}

inline void GovRfIntV1_OnPipelineOpened(void)
{
   GovRfEngV1_OnPipelineOpen(g_gov_rf_v1);
}

inline void GovRfIntV1_OnRegimeSlotTick(const int regime_slot_now)
{
   GovRfEngV1_OnRegimeTick(g_gov_rf_v1, s_gov_rf_reg_slot_prev_v1, regime_slot_now);
   s_gov_rf_reg_slot_prev_v1 = regime_slot_now;
}

inline void GovRfIntV1_OnDdProbe(const double equity_dd_pct, const double balance, const double equity)
{
   GovRfEngV1_OnDdProbe(g_gov_rf_v1, equity_dd_pct, balance, equity);
}

inline void GovRfIntV1_OnRiskSample(const bool can_trade, const int deny_ct)
{
   GovRfEngV1_OnRiskSample(g_gov_rf_v1, can_trade, deny_ct);
}

inline void GovRfIntV1_OnEarlyReject(const datetime ts, const int stage, const ENUM_SIGNAL_REJECT_REASON rr, const int deny_ct, const int strat_slot)
{
   GovRfEngV1_OnReject(g_gov_rf_v1, ts, stage, (int)rr, deny_ct, strat_slot);
}

inline void GovRfIntV1_OnEcologyFootprint(const int pre_buy,
                                       const int pre_sell,
                                       const int post_buy,
                                       const int post_sell,
                                       const int suppress_clears,
                                       const int throttle_ev,
                                       SignalResult &signals[])
{
   GovRfEngV1_OnEcologyFootprint(g_gov_rf_v1, pre_buy, pre_sell, post_buy, post_sell, suppress_clears, throttle_ev, signals);
}

inline void GovRfIntV1_OnConsensusEval(const datetime ts,
                                    const int base_min,
                                    const int eff_min,
                                    const int buy_v,
                                    const int sell_v,
                                    const ENUM_SIGNAL consensus,
                                    const int ecology_suppress_clears)
{
   GovRfEngV1_OnConsensusEval(g_gov_rf_v1, ts, base_min, eff_min, buy_v, sell_v, consensus, ecology_suppress_clears);
}

inline void GovRfIntV1_OnPipelineReject(const datetime ts, const int stage, const ENUM_SIGNAL_REJECT_REASON rr, const int deny_ct, const int strat_slot)
{
   GovRfEngV1_OnReject(g_gov_rf_v1, ts, stage, (int)rr, deny_ct, strat_slot);
}

inline void GovRfIntV1_OnLostToRiskHalt(void)
{
   GovRfEngV1_OnLostToRiskHalt(g_gov_rf_v1);
}

inline void GovRfIntV1_OnTradeOpened(void)
{
   GovRfEngV1_OnTradeOpened(g_gov_rf_v1);
}

inline void GovRfIntV1_OnExecAllowedWaterfall(const datetime ts, const int strat_slot)
{
   if(!g_gov_rf_v1.enabled)
      return;
   GovRfEngV1_PushWaterfall(g_gov_rf_v1, ts, (int)GOV_RF_STAGE_EXEC_ALLOWED_V1, 0, (int)AS_CT_DENY_NONE, (int)GOV_RF_VETO_UNKNOWN_V1, strat_slot);
}

inline void GovRfIntV1_FlushPersistence(void)
{
   GovRfPersistV1_WriteAll(g_gov_rf_v1, g_gov_ecology_v1);
}

inline void GovRfIntV1_AppendDossierSection24(string &html)
{
   GovRfHtmlV1_AppendSection24(html, g_gov_rf_v1, g_gov_ecology_v1);
}

#endif // __AURUM_GOV_RF_INT_V1_MQH__
