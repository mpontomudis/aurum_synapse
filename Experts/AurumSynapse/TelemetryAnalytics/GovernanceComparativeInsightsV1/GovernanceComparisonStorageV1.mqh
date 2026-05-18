//+------------------------------------------------------------------+
//| GovernanceComparisonStorageV1.mqh                             |
//| PHASE 20C — append-only CSV/JSONL baselines (MQL5\\Files)        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CMP_STORAGE_V1_MQH__
#define __AURUM_GOV_CMP_STORAGE_V1_MQH__

#include "GovernanceComparisonDatasetV1.mqh"
#include "../GovernanceRuntimeVisualObservabilityV1/GovernanceRuntimeVisualContractsV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionDatasetV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyToxicityAnalyticsV1.mqh"
#include "../GovernanceRuntimeVisualObservabilityV1/GovernanceRuntimeVisualDatasetV1.mqh"
#include "../GovernancePositionLineageIntelligenceV1/GovernancePositionLineageRegistryV1.mqh"
#include "../GovernancePositionLineageIntelligenceV1/GovernanceRecoveryChainAnalyticsV1.mqh"
#include "../GovernanceRuntimeVisualObservabilityV1/GovernanceBacktestInputSnapshotV1.mqh"
#include "../GovernanceEcologyEngineV1/GovernanceEcologyExportV1.mqh"

inline void GovCmpStoreV1_EnsureDirs(void)
{
   FolderCreate("AurumSynapse");
   FolderCreate("AurumSynapse\\TelemetryAnalytics");
   FolderCreate("AurumSynapse\\TelemetryAnalytics\\Baselines");
}

inline string GovCmpStoreV1_RegimePfCompact(const SGovStratAttribSummaryV1 &sum)
{
   string o = "";
   for(int r = 0; r < GOV_SATTR_REGIME_COUNT_V1; r++) {
      if(r > 0)
         o += ";";
      o += "R" + IntegerToString(r) + ":" + DoubleToString((double)sum.bd.regime.by_reg[r].pf_milli / 1000.0, 3);
   }
   return o;
}

inline string GovCmpStoreV1_VolPfCompact(const SGovStratAttribSummaryV1 &sum)
{
   string o = "";
   for(int v = 0; v < GOV_SATTR_VOL_COUNT_V1; v++) {
      if(v > 0)
         o += ";";
      o += "V" + IntegerToString(v) + ":" + DoubleToString((double)sum.bd.vol.by_vol[v].pf_milli / 1000.0, 3);
   }
   return o;
}

inline void GovCmpStoreV1_FillCurrent(const string run_ts,
                                     const string sym,
                                     const ENUM_TIMEFRAMES tf,
                                     SGovStratAttribSummaryV1 &sum,
                                     const SGovVisualExecSummaryV1 &ex,
                                     const SGovLineageRegistryStoreV1 &lin,
                                     const SGovRecoveryStoreV1 &rec,
                                     SGovCmpRunRecordV1 &out)
{
   GovCmpDsV1_Init(out);
   out.valid = 1;
   out.run_ts = run_ts;
   out.sym = sym;
   out.tf = EnumToString(tf);
   out.git = g_gov_dossier_git_commit_v1;
   out.build_no = g_gov_dossier_build_number_v1;
   out.deposit_cents = 0;
   if(MQLInfoInteger(MQL_TESTER) != 0)
      out.deposit_cents = (long)MathRound(TesterStatistics(STAT_INITIAL_DEPOSIT) * 100.0);
   else
      out.deposit_cents = (long)MathRound(AccountInfoDouble(ACCOUNT_BALANCE) * 100.0);
   out.leverage = (int)AccountInfoInteger(ACCOUNT_LEVERAGE);
   int bits = 0;
   for(int i = 0; i < 8 && i < GOV_SATTR_STRAT_COUNT_V1; i++) {
      if(g_gov_dossier_strat_en_v1[i])
         bits |= (1 << i);
   }
   out.strat_bits = bits;
   out.pf = ex.profit_factor;
   out.dd_bal_pct = ex.balance_dd_rel_pct;
   out.dd_eq_pct = ex.equity_dd_rel_pct;
   out.winrate_x1000 = (ex.total_trades > 0) ? (int)((1000L * (long)ex.profit_trades) / (long)ex.total_trades) : 0;
   int mt = 0;
   for(int z = 0; z < GOV_SATTR_STRAT_COUNT_V1; z++) {
      GovStratToxV1_Score(z, sum, sum.tox[z]);
      mt = MathMax(mt, sum.tox[z].score_0_1000);
   }
   out.max_tox = mt;
   out.trades = ex.total_trades;
   out.lineage_roots = lin.tel.total_roots;
   out.lineage_children = lin.tel.total_children;
   int casc = 0;
   for(int k = 0; k < GOV_LINEAGE_MAX_RECOVERY_V1; k++) {
      if(rec.chains[k].root_lineage_id == 0)
         continue;
      if(rec.chains[k].generation_depth >= 2)
         casc++;
   }
   out.recovery_cascades = casc;
   out.regime_pf_compact = GovCmpStoreV1_RegimePfCompact(sum);
   out.vol_pf_compact = GovCmpStoreV1_VolPfCompact(sum);
   GovEcoExpV1_FillCmpRecord(out);
}

inline string GovCmpStoreV1_CsvHeader(void)
{
   return "run_ts,sym,tf,git,build,dep_cents,lev,sbits,pf,ddb,dde,wr1k,maxtox,trades,lroots,lchild,casc,rpf,vpf,eco_div,eco_ent,eco_bal,eco_dom_slot,eco_dom_frac1k\n";
}

inline string GovCmpStoreV1_CsvLine(const SGovCmpRunRecordV1 &r)
{
   return r.run_ts + "," + r.sym + "," + r.tf + "," + r.git + "," + IntegerToString(r.build_no) + "," + IntegerToString((int)r.deposit_cents) + "," +
          IntegerToString(r.leverage) + "," + IntegerToString(r.strat_bits) + "," + DoubleToString(r.pf, 6) + "," + DoubleToString(r.dd_bal_pct, 4) + "," +
          DoubleToString(r.dd_eq_pct, 4) + "," + IntegerToString(r.winrate_x1000) + "," + IntegerToString(r.max_tox) + "," + IntegerToString(r.trades) + "," +
          IntegerToString(r.lineage_roots) + "," + IntegerToString(r.lineage_children) + "," + IntegerToString(r.recovery_cascades) + "," + r.regime_pf_compact + "," +
          r.vol_pf_compact + "," + IntegerToString(r.eco_diversity_pm) + "," + IntegerToString(r.eco_entropy_pm) + "," + IntegerToString(r.eco_balance_pm) + "," +
          IntegerToString(r.eco_dom_slot) + "," + IntegerToString(r.eco_dom_frac_x1000) + "\n";
}

inline bool GovCmpStoreV1_ParseLine(const string line, SGovCmpRunRecordV1 &r)
{
   GovCmpDsV1_Init(r);
   string p[];
   const int n = StringSplit(line, ',', p);
   if(n < 19)
      return false;
   r.run_ts = p[0];
   r.sym = p[1];
   r.tf = p[2];
   r.git = p[3];
   r.build_no = (int)StringToInteger(p[4]);
   r.deposit_cents = (long)StringToInteger(p[5]);
   r.leverage = (int)StringToInteger(p[6]);
   r.strat_bits = (int)StringToInteger(p[7]);
   r.pf = StringToDouble(p[8]);
   r.dd_bal_pct = StringToDouble(p[9]);
   r.dd_eq_pct = StringToDouble(p[10]);
   r.winrate_x1000 = (int)StringToInteger(p[11]);
   r.max_tox = (int)StringToInteger(p[12]);
   r.trades = (int)StringToInteger(p[13]);
   r.lineage_roots = (int)StringToInteger(p[14]);
   r.lineage_children = (int)StringToInteger(p[15]);
   r.recovery_cascades = (int)StringToInteger(p[16]);
   r.regime_pf_compact = p[17];
   if(n > 18)
      r.vol_pf_compact = p[18];
   if(n >= 24) {
      r.eco_diversity_pm = (int)StringToInteger(p[19]);
      r.eco_entropy_pm = (int)StringToInteger(p[20]);
      r.eco_balance_pm = (int)StringToInteger(p[21]);
      r.eco_dom_slot = (int)StringToInteger(p[22]);
      r.eco_dom_frac_x1000 = (int)StringToInteger(p[23]);
   }
   r.valid = 1;
   return true;
}

inline bool GovCmpStoreV1_ReadLatest(SGovCmpRunRecordV1 &r)
{
   GovCmpDsV1_Init(r);
   GovCmpStoreV1_EnsureDirs();
   const string path = GOV_VISUAL_BASELINE_CSV_V1;
   const int h = FileOpen(path, FILE_READ | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   string last = "";
   while(!FileIsEnding(h)) {
      string ln = FileReadString(h);
      StringTrimLeft(ln);
      StringTrimRight(ln);
      if(StringLen(ln) > 0)
         last = ln;
   }
   FileClose(h);
   if(StringLen(last) <= 0)
      return false;
   if(StringFind(last, "run_ts,") == 0)
      return false;
   return GovCmpStoreV1_ParseLine(last, r);
}

inline bool GovCmpStoreV1_Append(const SGovCmpRunRecordV1 &r)
{
   GovCmpStoreV1_EnsureDirs();
   const string path = GOV_VISUAL_BASELINE_CSV_V1;
   bool need_header = true;
   const int h0 = FileOpen(path, FILE_READ | FILE_TXT | FILE_ANSI);
   if(h0 != INVALID_HANDLE) {
      if(FileSize(h0) > 10)
         need_header = false;
      FileClose(h0);
   }
   const int h = FileOpen(path, FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileSeek(h, 0, SEEK_END);
   if(need_header)
      FileWriteString(h, GovCmpStoreV1_CsvHeader());
   FileWriteString(h, GovCmpStoreV1_CsvLine(r));
   FileClose(h);

   const string jpath = GOV_VISUAL_BASELINE_JSONL_V1;
   const int hj = FileOpen(jpath, FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(hj != INVALID_HANDLE) {
      FileSeek(hj, 0, SEEK_END);
      string j = "{\"run_ts\":\"" + r.run_ts + "\",\"sym\":\"" + r.sym + "\",\"tf\":\"" + r.tf + "\",\"pf\":" + DoubleToString(r.pf, 6) + ",\"dd_bal\":" +
                 DoubleToString(r.dd_bal_pct, 4) + ",\"max_tox\":" + IntegerToString(r.max_tox) + ",\"trades\":" + IntegerToString(r.trades) +
                 ",\"eco_div\":" + IntegerToString(r.eco_diversity_pm) + ",\"eco_ent\":" + IntegerToString(r.eco_entropy_pm) + ",\"eco_bal\":" +
                 IntegerToString(r.eco_balance_pm) + ",\"eco_dom_slot\":" + IntegerToString(r.eco_dom_slot) + ",\"eco_dom_frac1k\":" +
                 IntegerToString(r.eco_dom_frac_x1000) + "}\n";
      FileWriteString(hj, j);
      FileClose(hj);
   }
   return true;
}

#endif // __AURUM_GOV_CMP_STORAGE_V1_MQH__
