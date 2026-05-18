//+------------------------------------------------------------------+
//| GovernanceRegimeIntegrationV1.mqh                               |
//| PHASE 22 — runtime hooks (deterministic, replay-safe)            |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REGIME_INTEGRATION_V1_MQH__
#define __AURUM_GOV_REGIME_INTEGRATION_V1_MQH__

#include "../../Core/Constants.mqh"
#include "../../Core/Structures.mqh"
#include "GovernanceRegimeDatasetV1.mqh"
#include "GovernanceRegimeEngineV1.mqh"
#include "GovernanceRegimeTelemetryV1.mqh"
#include "GovernanceRegimeTransitionV1.mqh"
#include "GovernanceRegimeMonthlyAnalyticsV1.mqh"
#include "GovernanceRegimeHeatmapV1.mqh"
#include "GovernanceRegimeDistributionV1.mqh"
#include "GovernanceRegimeSuppressionV1.mqh"
#include "GovernanceRegimePersistenceV1.mqh"
#include "GovernanceRegimeExportV1.mqh"

static double s_gov_regime_prev_comp_v1 = 0.0;

inline void GovRegimeIntV1_ModuleInit(void)
{
   GovRegimeDsV1_Init(g_gov_regime_store_v1);
   s_gov_regime_prev_comp_v1 = 0.0;
}

inline ENUM_REGIME GovRegimeIntV1_MapAurumToLegacy(const EAurumMarketRegime r)
{
   switch(r) {
   case AURUM_REGIME_TRENDING:
      return REGIME_TRENDING;
   case AURUM_REGIME_HIGH_VOL:
   case AURUM_REGIME_BREAKOUT:
   case AURUM_REGIME_DISTRIBUTION:
   case AURUM_REGIME_LIQUIDITY_SWEEP:
   case AURUM_REGIME_VOLATILITY_EXPANSION:
      return REGIME_VOLATILE;
   case AURUM_REGIME_LOW_VOL:
      return REGIME_CALM;
   case AURUM_REGIME_RANGING:
   case AURUM_REGIME_MEAN_REVERSION:
   case AURUM_REGIME_ACCUMULATION:
   case AURUM_REGIME_VOLATILITY_COMPRESSION:
      return REGIME_RANGING;
   default:
      return REGIME_RANGING;
   }
}

inline void GovRegimeIntV1_ApplyLegacyOverlay(MarketState &st)
{
   st.regime = GovRegimeIntV1_MapAurumToLegacy(g_gov_regime_store_v1.current_regime);
}

inline ulong GovRegimeIntV1_PositionIdFromOrderTicket(const string sym, const ulong order_ticket)
{
   if(!HistoryOrderSelect(order_ticket))
      return 0;
   if(HistoryOrderGetString(order_ticket, ORDER_SYMBOL) != sym)
      return 0;
   return (ulong)HistoryOrderGetInteger(order_ticket, ORDER_POSITION_ID);
}

inline void GovRegimeIntV1_RecordOpenOrder(const string sym, const ulong order_ticket)
{
   const ulong pos = GovRegimeIntV1_PositionIdFromOrderTicket(sym, order_ticket);
   if(pos == 0)
      return;
   const int h = (int)(pos % GOV_REGIME_POS_HASH_V1);
   g_gov_regime_store_v1.pos_hash_keys[h] = pos;
   g_gov_regime_store_v1.pos_hash_reg[h] = GovRegimeDsV1_RegimeSlot(g_gov_regime_store_v1.current_regime);
}

inline int GovRegimeIntV1_LookupRegimeForPosition(const ulong pos_id)
{
   const int h = (int)(pos_id % GOV_REGIME_POS_HASH_V1);
   if(g_gov_regime_store_v1.pos_hash_keys[h] == pos_id)
      return g_gov_regime_store_v1.pos_hash_reg[h];
   return GovRegimeDsV1_RegimeSlot(g_gov_regime_store_v1.current_regime);
}

inline void GovRegimeIntV1_OnAttributedTradeClose(const datetime dts,
                                                  const int strat_slot,
                                                  const ulong pos_id,
                                                  const long profit_cents)
{
   int s = strat_slot;
   if(s < 0 || s >= GOV_REGIME_STRAT_SLOTS_V1)
      s = 0;
   int rslot = GovRegimeIntV1_LookupRegimeForPosition(pos_id);
   if(rslot < 0 || rslot >= GOV_REGIME_AURUM_SLOT_COUNT_V1)
      rslot = 0;
   SGovRegimeStratCellV1 c = g_gov_regime_store_v1.strat_regime[s][rslot];
   c.trades++;
   if(profit_cents > 0)
      c.wins++;
   c.profit_cents += profit_cents;
   g_gov_regime_store_v1.strat_regime[s][rslot] = c;
   GovRegimeMoV1_OnTradeClose(g_gov_regime_store_v1, dts, profit_cents);
}

inline void GovRegimeIntV1_OnBar(const MarketState &st,
                                  const MqlRates &rates[],
                                  const int n_rates,
                                  const datetime bar_ts,
                                  const double spread_points,
                                  const bool append_csv)
{
   SGovRegimeFeaturesV1 feat;
   EAurumMarketRegime reg = AURUM_REGIME_UNKNOWN;
   double conf = 0.0;
   GovRegimeEngV1_Step(st, rates, n_rates, spread_points, s_gov_regime_prev_comp_v1, reg, conf, feat);
   s_gov_regime_prev_comp_v1 = feat.compression_density;

   const int slot = GovRegimeDsV1_RegimeSlot(reg);
   g_gov_regime_store_v1.valid = true;
   g_gov_regime_store_v1.prev_regime = g_gov_regime_store_v1.current_regime;
   g_gov_regime_store_v1.current_regime = reg;
   g_gov_regime_store_v1.last_bar_ts = bar_ts;
   g_gov_regime_store_v1.total_bars++;
   g_gov_regime_store_v1.regime_hist[slot]++;

   if(g_gov_regime_store_v1.prev_regime != reg && g_gov_regime_store_v1.total_bars > 1) {
      GovRegimeTrV1_OnChange(g_gov_regime_store_v1, bar_ts, GovRegimeDsV1_RegimeSlot(g_gov_regime_store_v1.prev_regime), slot, 0);
      g_gov_regime_store_v1.bars_since_change = 0;
   } else {
      g_gov_regime_store_v1.bars_since_change++;
      if((ulong)g_gov_regime_store_v1.bars_since_change > g_gov_regime_store_v1.frozen_streak_max)
         g_gov_regime_store_v1.frozen_streak_max = (ulong)g_gov_regime_store_v1.bars_since_change;
   }
   GovRegimeTrV1_PostBarTick(g_gov_regime_store_v1, 0);
   GovRegimeMoV1_OnBar(g_gov_regime_store_v1, bar_ts, slot);
   GovRegimeSupV1_Evaluate(g_gov_regime_store_v1);

   SGovRegimeTelemetryV1 row;
   GovRegimeTelV1_BuildRow(bar_ts, reg, st, feat, conf, row);
   GovRegimeTelV1_Push(g_gov_regime_store_v1, row);
   if(append_csv)
      GovRegimePersistV1_AppendRow(row);
}

inline void GovRegimeIntV1_OnPipelineSignal(const datetime ts)
{
   GovRegimeMoV1_OnSignal(g_gov_regime_store_v1, ts);
}

#endif
