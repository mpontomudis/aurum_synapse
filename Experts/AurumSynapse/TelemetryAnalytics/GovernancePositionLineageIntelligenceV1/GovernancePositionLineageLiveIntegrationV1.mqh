//+------------------------------------------------------------------+
//| GovernancePositionLineageLiveIntegrationV1.mqh                   |
//| Bounded runtime hooks — fail-closed, no execution mutation.      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_POS_LINEAGE_LIVEINT_V1_MQH__
#define __AURUM_GOV_POS_LINEAGE_LIVEINT_V1_MQH__

#include "GovernanceRecoveryChainAnalyticsV1.mqh"
#include "GovernanceExecutionGenealogyEngineV1.mqh"
#include "GovernancePositionMutationEngineV1.mqh"

SGovLineageRegistryStoreV1 g_gov_lineage_reg_v1;
SGovRecoveryStoreV1       g_gov_lineage_rec_v1;

//+------------------------------------------------------------------+
inline long GovLineageLiveV1_SatAdd64(const long a, const long b)
{
   if(b > 0 && a > 9223372036854775807L - b)
      return 9223372036854775807L;
   if(b < 0 && a < (-9223372036854775807L - 1L) - b)
      return (-9223372036854775807L - 1L);
   return a + b;
}

//+------------------------------------------------------------------+
inline void GovLineageLiveV1_ModuleInit(void)
{
   GovLineageV1_Reset(g_gov_lineage_reg_v1);
   GovRecoveryStoreV1_Init(g_gov_lineage_rec_v1);
}

//+------------------------------------------------------------------+
inline bool GovLineageLiveV1_OnOpenFromOrder(const string sym,
                                            const ulong order_ticket,
                                            const ulong position_id,
                                            const int strategy_idx_0_7,
                                            const datetime ts)
{
   if(position_id == 0)
      return false;
   const int ix = GovLineageV1_RegisterRoot(g_gov_lineage_reg_v1, position_id, strategy_idx_0_7, ts);
   if(ix < 0)
      return false;
   long vol_milli = 0;
   if(order_ticket != 0 && HistorySelect(0, TimeCurrent())) {
      const int nd = HistoryDealsTotal();
      for(int i = nd - 1; i >= 0; i--) {
         const ulong d = HistoryDealGetTicket(i);
         if(d == 0)
            continue;
         if(HistoryDealGetString(d, DEAL_SYMBOL) != sym)
            continue;
         if((ulong)HistoryDealGetInteger(d, DEAL_ORDER) != order_ticket)
            continue;
         if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(d, DEAL_ENTRY) != DEAL_ENTRY_IN)
            continue;
         if((ulong)HistoryDealGetInteger(d, DEAL_POSITION_ID) != position_id)
            continue;
         vol_milli = (long)MathRound(HistoryDealGetDouble(d, DEAL_VOLUME) * 100000.0);
         break;
      }
   }
   if(vol_milli > 0)
      g_gov_lineage_reg_v1.nodes[ix].position_volume_milli = vol_milli;
   else
      g_gov_lineage_reg_v1.nodes[ix].position_volume_milli = 100000L;
   return true;
}

//+------------------------------------------------------------------+
inline void GovLineageLiveV1_OnDealOutProfit(const ulong position_id,
                                            const long profit_cents,
                                            const int stopout,
                                            const datetime ts)
{
   const int ex = GovLineageV1_FindByPosition(g_gov_lineage_reg_v1, position_id);
   if(ex < 0)
      return;
   if(profit_cents > 0)
      g_gov_lineage_reg_v1.nodes[ex].cumulative_profit_cents =
         GovLineageLiveV1_SatAdd64(g_gov_lineage_reg_v1.nodes[ex].cumulative_profit_cents, profit_cents);
   else if(profit_cents < 0)
      g_gov_lineage_reg_v1.nodes[ex].cumulative_loss_cents =
         GovLineageLiveV1_SatAdd64(g_gov_lineage_reg_v1.nodes[ex].cumulative_loss_cents, -profit_cents);
   if(stopout != 0 && profit_cents < 0) {
      g_gov_lineage_reg_v1.nodes[ex].recovery_depth =
         GovSaturatingAdd32(g_gov_lineage_reg_v1.nodes[ex].recovery_depth, 1);
      g_gov_lineage_reg_v1.nodes[ex].ancestry_flags |= (uint)GOV_ANC_RECOVERY;
      GovRecoveryV1_Register(g_gov_lineage_rec_v1,
                             g_gov_lineage_reg_v1.nodes[ex].root_lineage_id,
                             g_gov_lineage_reg_v1.nodes[ex].lineage_id,
                             g_gov_lineage_reg_v1.nodes[ex].recovery_depth);
      g_gov_lineage_reg_v1.tel.recoveries = GovSaturatingAdd32(g_gov_lineage_reg_v1.tel.recoveries, 1);
   }
   g_gov_lineage_reg_v1.nodes[ex].position_volume_milli = 0;
   GovLineageV1_Close(g_gov_lineage_reg_v1, position_id, ts);
}

//+------------------------------------------------------------------+
inline void GovLineageLiveV1_OnTradeTransaction(const MqlTradeTransaction &trans,
                                                const string sym,
                                                const long magic)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
      return;
   if(trans.deal == 0)
      return;
   if(!HistoryDealSelect(trans.deal))
      return;
   if(HistoryDealGetString(trans.deal, DEAL_SYMBOL) != sym)
      return;
   if(HistoryDealGetInteger(trans.deal, DEAL_MAGIC) != magic)
      return;
   const ulong pos = (ulong)HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID);
   const int ent = (int)HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
   const long deal_vol_milli = (long)MathRound(HistoryDealGetDouble(trans.deal, DEAL_VOLUME) * 100000.0);
   const datetime ts = (datetime)HistoryDealGetInteger(trans.deal, DEAL_TIME);
   const int ex = GovLineageV1_FindByPosition(g_gov_lineage_reg_v1, pos);
   if(ent == (int)DEAL_ENTRY_IN) {
      if(ex < 0)
         return;
      const long prev = g_gov_lineage_reg_v1.nodes[ex].position_volume_milli;
      long new_pos_vol = deal_vol_milli;
      if(PositionSelectByTicket(pos))
         new_pos_vol = (long)MathRound(PositionGetDouble(POSITION_VOLUME) * 100000.0);
      else if(prev > 0 && deal_vol_milli > 0)
         new_pos_vol = prev + deal_vol_milli;
      const int mt = GovMutationV1_Detect(ent, prev, new_pos_vol, 0, 0, 0);
      if(GovMutationV1_IsScaleIn(mt)) {
         g_gov_lineage_reg_v1.nodes[ex].scale_in_count = GovSaturatingAdd32(g_gov_lineage_reg_v1.nodes[ex].scale_in_count, 1);
         g_gov_lineage_reg_v1.tel.scale_ins = GovSaturatingAdd32(g_gov_lineage_reg_v1.tel.scale_ins, 1);
      }
      g_gov_lineage_reg_v1.nodes[ex].position_volume_milli = new_pos_vol;
      g_gov_lineage_reg_v1.nodes[ex].last_mutation_time = ts;
      g_gov_lineage_reg_v1.nodes[ex].lineage_state = (int)GOV_LINEAGE_ST_SCALED;
   }
}

#endif // __AURUM_GOV_POS_LINEAGE_LIVEINT_V1_MQH__
