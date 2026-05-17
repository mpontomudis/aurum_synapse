//+------------------------------------------------------------------+
//| GovernanceRuntimeObservabilityDatasetV1.mqh                     |
//| POD + last capital / block snapshot (cold path)                  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_OBS_DATASET_V1_MQH__
#define __AURUM_GOV_RUNTIME_OBS_DATASET_V1_MQH__

#include "GovernanceRuntimeObservabilityContractsV1.mqh"

struct SGovRuntimeObsReportMetaV1
{
   uint   magic;
   uint   abi_ver;
   uint   build_seq;
   datetime build_ts;
   int    reason_tag;
};

struct SGovRuntimeObsCapitalSnapV1
{
   datetime snap_ts;
   int      result_code;
   long     balance_cent;
   long     equity_cent;
   long     margin_free_cent;
   long     margin_req_cent;
   long     requested_lot_micro;
   long     normalized_lot_micro;
   long     broker_min_lot_micro;
   long     broker_max_lot_micro;
   long     lot_step_micro;
   int      stop_level_points;
   string   last_block_reason;
};

struct SGovRuntimeObsReportV1
{
   SGovRuntimeObsReportMetaV1 meta;
   SGovRuntimeObsCapitalSnapV1 cap;
};

SGovRuntimeObsReportV1 g_gov_runtime_obs_report_v1;

inline void GovRuntimeObsDsV1_InitMeta(SGovRuntimeObsReportMetaV1 &m)
{
   m.magic = GOV_RUNTIME_OBS_MAGIC_V1;
   m.abi_ver = GOV_RUNTIME_OBS_ABI_VER_V1;
   m.build_seq = 0;
   m.build_ts = 0;
   m.reason_tag = 0;
}

inline void GovRuntimeObsDsV1_InitCapital(SGovRuntimeObsCapitalSnapV1 &c)
{
   c.snap_ts = 0;
   c.result_code = (int)GOV_CAP_RES_NONE;
   c.balance_cent = 0;
   c.equity_cent = 0;
   c.margin_free_cent = 0;
   c.margin_req_cent = 0;
   c.requested_lot_micro = 0;
   c.normalized_lot_micro = 0;
   c.broker_min_lot_micro = 0;
   c.broker_max_lot_micro = 0;
   c.lot_step_micro = 0;
   c.stop_level_points = 0;
   c.last_block_reason = "";
}

inline void GovRuntimeObsDsV1_InitReport(SGovRuntimeObsReportV1 &r)
{
   GovRuntimeObsDsV1_InitMeta(r.meta);
   GovRuntimeObsDsV1_InitCapital(r.cap);
}

inline long GovRuntimeObsDsV1_LotToMicro(const double lot)
{
   if(!MathIsValidNumber(lot))
      return 0;
   return (long)MathRound(lot * 100000000.0);
}

inline void GovRuntimeObsV1_ModuleInit(void)
{
   GovRuntimeObsDsV1_InitReport(g_gov_runtime_obs_report_v1);
}

inline void GovRuntimeObsV1_FeedTradeBlocked(const string reason, const double requested_lot)
{
   g_gov_runtime_obs_report_v1.cap.snap_ts = TimeCurrent();
   g_gov_runtime_obs_report_v1.cap.last_block_reason = reason;
   g_gov_runtime_obs_report_v1.cap.requested_lot_micro = GovRuntimeObsDsV1_LotToMicro(requested_lot);
   g_gov_runtime_obs_report_v1.cap.result_code = (int)GOV_CAP_RES_OTHER;
   if(StringFind(reason, "FreeMargin") >= 0 || StringFind(reason, "Margin") >= 0)
      g_gov_runtime_obs_report_v1.cap.result_code = (int)GOV_CAP_RES_FREE_MARGIN_LOW;
   else if(StringFind(reason, "InvalidLot") >= 0 || StringFind(reason, "InvalidVolume") >= 0)
      g_gov_runtime_obs_report_v1.cap.result_code = (int)GOV_CAP_RES_LOT_COLLAPSE_MIN_VOLUME;
}

inline void GovRuntimeObsV1_FeedOrderContext(const int result_code,
                                            const double requested_lot,
                                            const double normalized_lot,
                                            const double margin_req)
{
   g_gov_runtime_obs_report_v1.cap.snap_ts = TimeCurrent();
   g_gov_runtime_obs_report_v1.cap.result_code = result_code;
   g_gov_runtime_obs_report_v1.cap.requested_lot_micro = GovRuntimeObsDsV1_LotToMicro(requested_lot);
   g_gov_runtime_obs_report_v1.cap.normalized_lot_micro = GovRuntimeObsDsV1_LotToMicro(normalized_lot);
   g_gov_runtime_obs_report_v1.cap.margin_req_cent = (long)MathRound(margin_req * 100.0);
}

inline void GovRuntimeObsV1_RefreshAccountSnapshot(const string sym)
{
   g_gov_runtime_obs_report_v1.cap.balance_cent = (long)MathRound(AccountInfoDouble(ACCOUNT_BALANCE) * 100.0);
   g_gov_runtime_obs_report_v1.cap.equity_cent = (long)MathRound(AccountInfoDouble(ACCOUNT_EQUITY) * 100.0);
   g_gov_runtime_obs_report_v1.cap.margin_free_cent = (long)MathRound(AccountInfoDouble(ACCOUNT_MARGIN_FREE) * 100.0);
   const double vmin = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   const double vmax = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   const double vstep = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   g_gov_runtime_obs_report_v1.cap.broker_min_lot_micro = GovRuntimeObsDsV1_LotToMicro(vmin);
   g_gov_runtime_obs_report_v1.cap.broker_max_lot_micro = GovRuntimeObsDsV1_LotToMicro(vmax);
   g_gov_runtime_obs_report_v1.cap.lot_step_micro = GovRuntimeObsDsV1_LotToMicro(vstep);
   g_gov_runtime_obs_report_v1.cap.stop_level_points = (int)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL);
}

#endif // __AURUM_GOV_RUNTIME_OBS_DATASET_V1_MQH__
