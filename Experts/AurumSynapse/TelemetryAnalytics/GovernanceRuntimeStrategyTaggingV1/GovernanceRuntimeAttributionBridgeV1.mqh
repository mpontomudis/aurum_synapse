//+------------------------------------------------------------------+
//| GovernanceRuntimeAttributionBridgeV1.mqh                         |
//| Runtime identity → SGovStratAttribTradeV1 ring (bounded).      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_ATTR_BRIDGE_V1_MQH__
#define __AURUM_GOV_RUNTIME_ATTR_BRIDGE_V1_MQH__

#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionDatasetV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionEngineV1.mqh"
#include "GovernanceRuntimeTradeIdentityRegistryV1.mqh"
#include "GovernanceRuntimeTaggingTelemetryV1.mqh"

#define GOV_RTAG_BRIDGE_CAP_V1   512

struct SGovRunAttrBridgeStoreV1
{
   SGovStratAttribTradeV1 tr[GOV_RTAG_BRIDGE_CAP_V1];
   int                    widx;
   int                    total;
};

inline void GovRunAttrBridgeV1_Init(SGovRunAttrBridgeStoreV1 &b)
{
   b.widx = 0;
   b.total = 0;
   for(int i = 0; i < GOV_RTAG_BRIDGE_CAP_V1; i++)
      GovStrAttrDsV1_InitTrade(b.tr[i]);
}

//+------------------------------------------------------------------+
inline int GovRunAttrBridgeV1_FlattenIndex(const SGovRunAttrBridgeStoreV1 &b, const int i_0_based)
{
   if(b.total <= GOV_RTAG_BRIDGE_CAP_V1)
      return i_0_based;
   return (b.widx + i_0_based) % GOV_RTAG_BRIDGE_CAP_V1;
}

//+------------------------------------------------------------------+
//| Register — insert identity keyed by MT5 position id.              |
//+------------------------------------------------------------------+
inline bool GovRunAttrV1_Register(SGovRunTagRegistryStoreV1 &reg,
                                  SGovRunTagTelemetryStoreV1 &tel,
                                  const ulong position_id,
                                  const SGovRuntimeTradeIdentityV1 &id,
                                  string &err)
{
   err = "";
   int ovr = 0;
   if(!GovRunTagRegV1_Insert(reg, position_id, id, ovr)) {
      err = "GOV_RTAG_REG_FAIL";
      tel.tag_injection_fail = GovSaturatingAdd32(tel.tag_injection_fail, 1);
      return false;
   }
   if(ovr != 0)
      tel.registry_overflow = GovSaturatingAdd32(tel.registry_overflow, 1);
   return true;
}

//+------------------------------------------------------------------+
inline bool GovRunAttrV1_Commit(SGovRunTagRegistryStoreV1 &reg,
                                SGovRunAttrBridgeStoreV1 &bridge,
                                SGovRunTagTelemetryStoreV1 &tel,
                                const ulong position_id,
                                const long profit_cents,
                                const int hold_bars,
                                const int stopout,
                                const int tail_loss,
                                string &err)
{
   err = "";
   SGovRuntimeTradeIdentityV1 id;
   GovRunTagDsV1_InitIdentity(id);
   if(!GovRunTagRegV1_Find(reg, position_id, id)) {
      tel.orphan_close = GovSaturatingAdd32(tel.orphan_close, 1);
      err = "GOV_RTAG_ORPHAN_CLOSE";
      return false;
   }
   SGovStratAttribTradeV1 tr;
   GovStrAttrDsV1_InitTrade(tr);
   tr.strat = id.strategy_id;
   tr.regime = id.regime_id;
   tr.session = id.session_id;
   tr.vol = id.volatility_id;
   tr.profit_cents = profit_cents;
   tr.hold_bars = hold_bars;
   tr.stopout = stopout;
   tr.tail_loss = tail_loss;
   bridge.tr[bridge.widx] = tr;
   bridge.widx = (bridge.widx + 1) % GOV_RTAG_BRIDGE_CAP_V1;
   bridge.total = GovSaturatingAdd32(bridge.total, 1);
   tel.commits = GovSaturatingAdd32(tel.commits, 1);
   GovRunTagTelV1_OnCommittedTrade(tel, tr.strat, tr.regime, tr.vol, tr.session);
   GovRunTagRegV1_Remove(reg, position_id);
   return true;
}

//+------------------------------------------------------------------+
inline bool GovRunAttrV1_FindByTicket(const SGovRunTagRegistryStoreV1 &reg,
                                    const ulong position_id,
                                    SGovRuntimeTradeIdentityV1 &out_id)
{
   return GovRunTagRegV1_Find(reg, position_id, out_id);
}

#endif // __AURUM_GOV_RUNTIME_ATTR_BRIDGE_V1_MQH__
