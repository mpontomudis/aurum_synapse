//+------------------------------------------------------------------+
//| GovernanceRuntimeObservabilityFormatterV1.mqh                    |
//| Human-readable blocks (LF, deterministic ordering)               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_OBS_FMT_V1_MQH__
#define __AURUM_GOV_RUNTIME_OBS_FMT_V1_MQH__

#include "GovernanceRuntimeObservabilityDatasetV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionDatasetV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionExportV1.mqh"
#include "../GovernancePositionLineageIntelligenceV1/GovernancePositionLineageDatasetV1.mqh"

#define GOV_ROBS_HDR_STRATEGY    "=== STRATEGY BREAKDOWN ==="
#define GOV_ROBS_HDR_LINEAGE     "=== POSITION LINEAGE ==="
#define GOV_ROBS_HDR_TOX         "=== TOXICITY BREAKDOWN ==="
#define GOV_ROBS_HDR_ECO         "=== ECOLOGY BREAKDOWN ==="
#define GOV_ROBS_HDR_CAPITAL     "=== CAPITAL DIAGNOSTICS ==="

inline void GovRuntimeObsFmtV1_AppendLf(string &dst, const string chunk)
{
   string c = chunk;
   StringReplace(c, "\r\n", "\n");
   StringReplace(c, "\r", "\n");
   dst += c;
}

inline string GovRuntimeObsFmtV1_CapitalResultLabel(const int code)
{
   switch(code) {
   case GOV_CAP_RES_NONE:
      return "NONE";
   case GOV_CAP_RES_OK:
      return "OK";
   case GOV_CAP_RES_LOT_INVALID:
      return "INVALID_LOT_CALC";
   case GOV_CAP_RES_LOT_COLLAPSE_MIN_VOLUME:
      return "LOT_COLLAPSE_MIN_VOLUME";
   case GOV_CAP_RES_INSUFFICIENT_MARGIN:
      return "INSUFFICIENT_MARGIN";
   case GOV_CAP_RES_FREE_MARGIN_LOW:
      return "FREE_MARGIN_LOW";
   case GOV_CAP_RES_ORDER_SEND_FAILED:
      return "ORDER_SEND_FAILED";
   case GOV_CAP_RES_INVALID_STOPS:
      return "INVALID_STOPS";
   case GOV_CAP_RES_RISK_HALT:
      return "RISK_HALT";
   case GOV_CAP_RES_MAX_POSITIONS:
      return "MAX_POSITIONS";
   default:
      return "OTHER";
   }
}

inline string GovRuntimeObsFmtV1_LotMicroToStr(const long micro)
{
   const double v = (double)micro / 100000000.0;
   return DoubleToString(v, 4);
}

inline void GovRuntimeObsFmtV1_AppendStrategyBreakdown(string &dst, const SGovStratAttribSummaryV1 &sum)
{
   GovRuntimeObsFmtV1_AppendLf(dst, GOV_ROBS_HDR_STRATEGY + "\n");
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      const SGovStratAttribStatsV1 st = sum.bd.by_strat[i];
      if(st.trades <= 0)
         continue;
      const long net = st.gross_win_cents - st.gross_loss_cents;
      GovRuntimeObsFmtV1_AppendLf(dst, GovStratExpV1_StratLabel(i) + "\n");
      GovRuntimeObsFmtV1_AppendLf(dst, "Trades: " + IntegerToString(st.trades) + "\n");
      GovRuntimeObsFmtV1_AppendLf(dst, "Profit: " + (net >= 0 ? "+" : "") + IntegerToString((int)net) + "\n");
      GovRuntimeObsFmtV1_AppendLf(dst, "PF: " + DoubleToString((double)st.pf_milli / 1000.0, 3) + "\n");
   }
}

inline void GovRuntimeObsFmtV1_AppendToxicity(string &dst, const SGovStratAttribSummaryV1 &sum)
{
   GovRuntimeObsFmtV1_AppendLf(dst, GOV_ROBS_HDR_TOX + "\n");
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      const SGovStratAttribToxicityV1 t = sum.tox[i];
      GovRuntimeObsFmtV1_AppendLf(dst, GovStratExpV1_StratLabel(i) + ",score=" + IntegerToString(t.score_0_1000) + ",mismatch=" + IntegerToString(t.regime_mismatch) + "\n");
   }
}

inline void GovRuntimeObsFmtV1_AppendEcology(string &dst, const SGovStratAttribSummaryV1 &sum)
{
   GovRuntimeObsFmtV1_AppendLf(dst, GOV_ROBS_HDR_ECO + "\n");
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++)
      GovRuntimeObsFmtV1_AppendLf(dst, GovStratExpV1_StratLabel(i) + ",eco_role=" + IntegerToString(sum.ecology_role[i]) + "\n");
}

inline void GovRuntimeObsFmtV1_AppendLineageNarrative(string &dst, const SGovLineageRegistryStoreV1 &reg)
{
   GovRuntimeObsFmtV1_AppendLf(dst, GOV_ROBS_HDR_LINEAGE + "\n");
   int roots = 0;
   for(int i = 0; i < GOV_LINEAGE_MAX_NODES_V1; i++) {
      if(reg.nodes[i].active == 0)
         continue;
      if(reg.nodes[i].parent_node_idx >= 0)
         continue;
      roots++;
      GovRuntimeObsFmtV1_AppendLf(dst, "ROOT_LINEAGE_" + IntegerToString((int)reg.nodes[i].lineage_id) + "\n");
      GovRuntimeObsFmtV1_AppendLf(dst, "Origin: " + GovStratExpV1_StratLabel(reg.nodes[i].originating_strategy) + "\n");
      GovRuntimeObsFmtV1_AppendLf(dst, "Children:\n");
      for(int j = 0; j < GOV_LINEAGE_MAX_NODES_V1; j++) {
         if(reg.nodes[j].active == 0)
            continue;
         if(reg.nodes[j].parent_node_idx != i)
            continue;
         GovRuntimeObsFmtV1_AppendLf(dst, "- " + GovStratExpV1_StratLabel(reg.nodes[j].current_owner_strategy) + " lineage_id=" + IntegerToString((int)reg.nodes[j].lineage_id) + "\n");
      }
      const long net = reg.nodes[i].cumulative_profit_cents - reg.nodes[i].cumulative_loss_cents;
      GovRuntimeObsFmtV1_AppendLf(dst, "Net: " + (net >= 0 ? "+" : "") + IntegerToString((int)net) + "\n");
      GovRuntimeObsFmtV1_AppendLf(dst, "Failure Cause: NONE\n");
   }
   if(roots == 0)
      GovRuntimeObsFmtV1_AppendLf(dst, "NONE\n");
}

inline void GovRuntimeObsFmtV1_AppendCapital(string &dst, const string sym, const SGovRuntimeObsCapitalSnapV1 &cap)
{
   GovRuntimeObsFmtV1_AppendLf(dst, GOV_ROBS_HDR_CAPITAL + "\n");
   GovRuntimeObsFmtV1_AppendLf(dst, "Balance: " + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + "\n");
   GovRuntimeObsFmtV1_AppendLf(dst, "Equity: " + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + "\n");
   GovRuntimeObsFmtV1_AppendLf(dst, "FreeMargin: " + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2) + "\n");
   GovRuntimeObsFmtV1_AppendLf(dst, "RequestedLot: " + GovRuntimeObsFmtV1_LotMicroToStr(cap.requested_lot_micro) + "\n");
   GovRuntimeObsFmtV1_AppendLf(dst, "NormalizedLot: " + GovRuntimeObsFmtV1_LotMicroToStr(cap.normalized_lot_micro) + "\n");
   GovRuntimeObsFmtV1_AppendLf(dst, "BrokerMinLot: " + GovRuntimeObsFmtV1_LotMicroToStr(cap.broker_min_lot_micro) + "\n");
   GovRuntimeObsFmtV1_AppendLf(dst, "BrokerMaxLot: " + GovRuntimeObsFmtV1_LotMicroToStr(cap.broker_max_lot_micro) + "\n");
   GovRuntimeObsFmtV1_AppendLf(dst, "LotStep: " + GovRuntimeObsFmtV1_LotMicroToStr(cap.lot_step_micro) + "\n");
   GovRuntimeObsFmtV1_AppendLf(dst, "StopLevelPoints: " + IntegerToString(cap.stop_level_points) + "\n");
   GovRuntimeObsFmtV1_AppendLf(dst, "MarginRequired: " + DoubleToString((double)cap.margin_req_cent / 100.0, 2) + "\n");
   GovRuntimeObsFmtV1_AppendLf(dst, "LastBlockReason: " + cap.last_block_reason + "\n");
   GovRuntimeObsFmtV1_AppendLf(dst, "Result:\n");
   GovRuntimeObsFmtV1_AppendLf(dst, GovRuntimeObsFmtV1_CapitalResultLabel(cap.result_code) + "\n");
}

#endif // __AURUM_GOV_RUNTIME_OBS_FMT_V1_MQH__
