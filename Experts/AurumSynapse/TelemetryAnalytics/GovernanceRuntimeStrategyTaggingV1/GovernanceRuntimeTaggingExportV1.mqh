//+------------------------------------------------------------------+
//| GovernanceRuntimeTaggingExportV1.mqh                             |
//| Runtime attribution text blocks (LF, deterministic order).      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_TAG_EXP_V1_MQH__
#define __AURUM_GOV_RUNTIME_TAG_EXP_V1_MQH__

#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyTradeTaggerV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionDatasetV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionEngineV1.mqh"
#include "GovernanceRuntimeAttributionBridgeV1.mqh"

#define GOV_RTAG_BLK_STRATEGY   "===RUNTIME_STRATEGY_BREAKDOWN==="
#define GOV_RTAG_BLK_REGIME     "===RUNTIME_REGIME_BREAKDOWN==="
#define GOV_RTAG_BLK_SESSION    "===RUNTIME_SESSION_BREAKDOWN==="
#define GOV_RTAG_BLK_VOL        "===RUNTIME_VOL_BREAKDOWN==="

//+------------------------------------------------------------------+
inline bool GovRunTagExpV1_AppendRuntimeBlocks(const SGovStratAttribSummaryV1 &sum, string &dst)
{
   dst += GOV_RTAG_BLK_STRATEGY + "\n";
   for(int s = 0; s < GOV_SATTR_STRAT_COUNT_V1; s++) {
      const SGovStratAttribStatsV1 st = sum.bd.by_strat[s];
      dst += GovStratTagV1_StrategyCode(s) + "\n";
      dst += "Trades=" + IntegerToString(st.trades) + "\n";
      dst += "PF=" + DoubleToString((double)st.pf_milli / 1000.0, 3) + "\n";
   }
   dst += GOV_RTAG_BLK_REGIME + "\n";
   for(int r = 0; r < GOV_SATTR_REGIME_COUNT_V1; r++) {
      const SGovStratAttribStatsV1 st = sum.bd.regime.by_reg[r];
      dst += GovStratTagV1_RegimeCode(r) + "\n";
      dst += "Trades=" + IntegerToString(st.trades) + "\n";
      dst += "PF=" + DoubleToString((double)st.pf_milli / 1000.0, 3) + "\n";
   }
   dst += GOV_RTAG_BLK_SESSION + "\n";
   for(int i = 0; i < GOV_SATTR_SESSION_COUNT_V1; i++) {
      const SGovStratAttribStatsV1 st = sum.bd.session.by_sess[i];
      dst += GovStratTagV1_SessionCode(i) + "\n";
      dst += "Trades=" + IntegerToString(st.trades) + "\n";
      dst += "PF=" + DoubleToString((double)st.pf_milli / 1000.0, 3) + "\n";
   }
   dst += GOV_RTAG_BLK_VOL + "\n";
   for(int v = 0; v < GOV_SATTR_VOL_COUNT_V1; v++) {
      const SGovStratAttribStatsV1 st = sum.bd.vol.by_vol[v];
      dst += GovStratTagV1_VolCode(v) + "\n";
      dst += "Trades=" + IntegerToString(st.trades) + "\n";
      dst += "PF=" + DoubleToString((double)st.pf_milli / 1000.0, 3) + "\n";
   }
   return true;
}

//+------------------------------------------------------------------+
inline bool GovRunAttrV1_Export(const SGovRunAttrBridgeStoreV1 &br, string &dst)
{
   SGovStratAttribSummaryV1 sum;
   GovStrAttrDsV1_InitSummary(sum);
   const int kmax = MathMin(br.total, GOV_RTAG_BRIDGE_CAP_V1);
   for(int i = 0; i < kmax; i++) {
      const int idx = GovRunAttrBridgeV1_FlattenIndex(br, i);
      GovStratAttrV1_AccTrade(sum, br.tr[idx]);
   }
   GovStratAttrV1_Finalize(sum);
   return GovRunTagExpV1_AppendRuntimeBlocks(sum, dst);
}

#endif // __AURUM_GOV_RUNTIME_TAG_EXP_V1_MQH__
