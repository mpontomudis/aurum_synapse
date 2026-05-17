//+------------------------------------------------------------------+
//| GovernanceStrategyAttributionExportV1.mqh                        |
//| Federated LF-only export (strategy ATTRIBUTION axis).          |
//| NOTE: include guard distinct from GovernanceStrategicExportV1.   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRAT_ATTR_EXP_V1_MQH__
#define __AURUM_GOV_STRAT_ATTR_EXP_V1_MQH__

#include "GovernanceStrategyTradeTaggerV1.mqh"
#include "../GovernanceExportFederationV1/GovernanceExportFederationContractsV1.mqh"
#include "../GovernanceExportFederationV1/GovernanceExportSchemaRegistryV1.mqh"
#include "../GovernanceStrategicContextRefactorV1/GovernanceStrategicContextV1.mqh"

inline string GovStratExpV1_StratLabel(const int strat)
{
   switch(GovClampInt32(strat, 0, 7)) {
   case GOV_STRAT_TF: return "TrendFollowing";
   case GOV_STRAT_BO: return "Breakout";
   case GOV_STRAT_MR: return "MeanReversion";
   case GOV_STRAT_SD: return "StructuralDrift";
   case GOV_STRAT_SM: return "SessionMomentum";
   case GOV_STRAT_PA: return "PriceAction";
   case GOV_STRAT_GR: return "GridRecovery";
   default: return "MetaStack";
   }
}

inline string GovStratExpV1_CsvHeader(void)
{
   return "strat,trades,wins,losses,pf_milli,expectancy_micro,net_cents,stopout_x1000,tail_x1000";
}

inline string GovStratExpV1_CsvRow(const int strat, const SGovStratAttribStatsV1 &st)
{
   const long net = st.gross_win_cents - st.gross_loss_cents;
   const int so = (st.trades > 0) ? (int)GovFloorDivSigned64((long)st.stopout_count * 1000L, (long)st.trades) : 0;
   const int tl = (st.trades > 0) ? (int)GovFloorDivSigned64((long)st.tail_loss_count * 1000L, (long)st.trades) : 0;
   return IntegerToString(strat) + "," + IntegerToString(st.trades) + "," + IntegerToString(st.wins) + "," + IntegerToString(st.losses) + "," +
          IntegerToString(st.pf_milli) + "," + IntegerToString(st.expectancy_micro) + "," + IntegerToString((int)net) + "," + IntegerToString(so) + "," + IntegerToString(tl);
}

inline string GovStratExpV1_ReportCompat(const SGovStratAttribSummaryV1 &sum)
{
   string o = "";
   o += GOV_EXP_BLK_COMPAT_V1 + "\n";
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      o += GovStratExpV1_StratLabel(i);
      for(int r = 0; r < GOV_SATTR_REGIME_COUNT_V1; r++)
         o += ",R" + IntegerToString(r) + "=" + IntegerToString(sum.compat_regime[i][r]);
      for(int v = 0; v < GOV_SATTR_VOL_COUNT_V1; v++)
         o += ",V" + IntegerToString(v) + "=" + IntegerToString(sum.compat_vol[i][v]);
      o += "\n";
   }
   return o;
}

inline string GovStratExpV1_Report(const SGovStratAttribSummaryV1 &sum)
{
   string o = "";
   o += GOV_EXP_BLK_STRATEGY_V1 + "\n";
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      const SGovStratAttribStatsV1 st = sum.bd.by_strat[i];
      const long net = st.gross_win_cents - st.gross_loss_cents;
      const int wr_x1000 = (st.trades > 0) ? (int)GovFloorDivSigned64((long)st.wins * 1000L, (long)st.trades) : 0;
      o += GovStratExpV1_StratLabel(i) + "\n";
      o += "- Trades: " + IntegerToString(st.trades) + "\n";
      o += "- Winrate_x1000: " + IntegerToString(wr_x1000) + "\n";
      o += "- PF_milli: " + IntegerToString(st.pf_milli) + "\n";
      o += "- Profit_cents: " + IntegerToString((int)net) + "\n";
   }
   o += GOV_EXP_BLK_REGIME_V1 + "\n";
   for(int r = 0; r < GOV_SATTR_REGIME_COUNT_V1; r++) {
      const SGovStratAttribStatsV1 st = sum.bd.regime.by_reg[r];
      const long net = st.gross_win_cents - st.gross_loss_cents;
      o += GovStratTagV1_RegimeCode(r) + ",trades=" + IntegerToString(st.trades) + ",net_cents=" + IntegerToString((int)net) + "\n";
   }
   o += GOV_EXP_BLK_VOL_V1 + "\n";
   for(int v = 0; v < GOV_SATTR_VOL_COUNT_V1; v++) {
      const SGovStratAttribStatsV1 st = sum.bd.vol.by_vol[v];
      const long net = st.gross_win_cents - st.gross_loss_cents;
      o += GovStratTagV1_VolCode(v) + ",trades=" + IntegerToString(st.trades) + ",net_cents=" + IntegerToString((int)net) + "\n";
   }
   o += GOV_EXP_BLK_SESSION_V1 + "\n";
   for(int s = 0; s < GOV_SATTR_SESSION_COUNT_V1; s++) {
      const SGovStratAttribStatsV1 st = sum.bd.session.by_sess[s];
      const long net = st.gross_win_cents - st.gross_loss_cents;
      o += GovStratTagV1_SessionCode(s) + ",trades=" + IntegerToString(st.trades) + ",net_cents=" + IntegerToString((int)net) + "\n";
   }
   o += GOV_EXP_BLK_TOX_V1 + "\n";
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      const SGovStratAttribToxicityV1 t = sum.tox[i];
      o += GovStratExpV1_StratLabel(i) + ",score=" + IntegerToString(t.score_0_1000) + ",mismatch=" + IntegerToString(t.regime_mismatch) + "\n";
   }
   o += GOV_EXP_BLK_ECO_V1 + "\n";
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++)
      o += GovStratExpV1_StratLabel(i) + ",eco_role=" + IntegerToString(sum.ecology_role[i]) + "\n";
   o += GovStratExpV1_ReportCompat(sum);
   return o;
}

inline void GovStratExpV1_Csv(const SGovStratAttribSummaryV1 &sum, string &out_csv)
{
   out_csv = GovStratExpV1_CsvHeader() + "\n";
   for(int i = 0; i < GOV_SATTR_STRAT_COUNT_V1; i++)
      out_csv += GovStratExpV1_CsvRow(i, sum.bd.by_strat[i]) + "\n";
}

inline bool GovStratExpV1_Bundle(const SGovStrategicContextV1 &ctx, const SGovStratAttribSummaryV1 &sum, string &out_bundle)
{
   if(!GovExportContractsV1_ValidateVersion())
      return false;
   if(!GovStrategicCtxV1_Validate(ctx))
      return false;
   if(GovExportSchemaV1_Version() != GOV_EXPORT_ABI_VER_V1)
      return false;
   string csv = "";
   GovStratExpV1_Csv(sum, csv);
   out_bundle = GovStratExpV1_Report(sum) + GOV_EXP_BLK_CSV_V1 + "\n" + csv;
   return true;
}

inline bool GovStratExpV1_Bundle(const SGovStratAttribSummaryV1 &sum, string &out_bundle)
{
   SGovStrategicContextV1 ctx;
   GovStrategicCtxV1_Reset(ctx);
   return GovStratExpV1_Bundle(ctx, sum, out_bundle);
}

#endif // __AURUM_GOV_STRAT_ATTR_EXP_V1_MQH__
